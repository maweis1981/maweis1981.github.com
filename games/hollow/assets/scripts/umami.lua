-- umami.lua — "Umami Cup" (game #9), a one-thumb pocket-sports duel.
--
-- P1 slice + P2 (characters & ultimates): pick a character, then duel a CPU on a
-- little table with a bouncing soy-dumpling ball and two torii goals. SLINGSHOT
-- control — press your dumpling, drag BACK to aim + charge, release to DASH
-- forward and strike. Land strikes to fill your ULTIMATE meter; when it's full,
-- tap the ULT button for your character's signature move. First to 3 wins.
--
-- Four characters, each a different feel:
--   Soba    — all-rounder;      ult "Rally Rush"  (homing power dash)
--   Chef    — heavy hitter;     ult "Fire Slam"   (homing dash + huge strike)
--   Ninja   — fast & fragile;   ult "Blink Strike"(teleport behind the ball)
--   Lantern — sturdy keeper;    ult "Guard Wall"  (seals your goal for a bit)
--
-- Ball + 2-body circle physics (same family as Pong/Breakout) — all in Lua.

function make_umami()
  local K = GAME_KIT
  local clamp, inr = K.clamp, K.in_rect
  local T = K.tracker()

  local WALL, TOPPAD, BOTPAD = 26, 150, 70
  local BR, GOAL_W = 18, 150
  local BALL_MAX, MAXPULL = 560, 150
  local MAX_DT, SERVE_DELAY, WIN_SCORE = 1 / 30, 0.8, 3
  local CPU_CD, CPU_REACH, ULT_GAIN, GUARD_T, KICK_T = 0.55, 260, 0.34, 3.0, 0.2

  -- Character roster: pr=radius, dash, kick=strike power, fric=agility, ult.
  local CHARS = {
    { key = "soba", name = "SOBA", note = "ALL-ROUND", icon = "u_soba", col = { 0.52, 0.74, 0.44 },
      pr = 28, dash = 660, kick = 1.0, fric = 3.4, ult = "rush" },
    { key = "chef", name = "CHEF", note = "POWER", icon = "u_chef", col = { 0.92, 0.52, 0.30 },
      pr = 33, dash = 560, kick = 1.45, fric = 3.0, ult = "slam" },
    { key = "ninja", name = "NINJA", note = "SPEED", icon = "u_ninja", col = { 0.52, 0.50, 0.72 },
      pr = 24, dash = 770, kick = 0.9, fric = 4.3, ult = "blink" },
    { key = "lantern", name = "LANTERN", note = "KEEPER", icon = "u_lantern", col = { 0.95, 0.80, 0.40 },
      pr = 37, dash = 470, kick = 1.1, fric = 2.5, ult = "guard" },
  }
  local function char_by_key(k) for _, c in ipairs(CHARS) do if c.key == k then return c end end return CHARS[1] end
  local ARENAS = { "arena_teahouse", "arena_beach", "arena_ramen", "arena_sushi" }
  local SPECS = { "spec_panda", "spec_cat", "spec_shiba", "spec_fox", "spec_tanuki" }
  local arena_i = 1

  local ball = { x = 0, y = 0, vx = 0, vy = 0, roll = 0 }
  local you = { x = 0, y = 0, vx = 0, vy = 0, energy = 0, ultk = 1, ultk_t = 0, guard_t = 0, strike_t = 0, anim = 0, kick_t = 0 }
  local cpu = { x = 0, y = 0, vx = 0, vy = 0, energy = 0, ultk = 1, ultk_t = 0, guard_t = 0, strike_t = 0, anim = 0, kick_t = 0 }
  local score_you, score_cpu = 0, 0
  local serve_t, cpu_t, over, screen, built = 0, 0, false, nil, false
  -- arena hazard state (set per court in start_match): bfric = ball friction,
  -- fric_mul = character-friction multiplier, htime = hazard clock.
  local htime, bfric, fric_mul = 0, 0.5, 1
  local charging, cpull = false, nil
  local band, traj, cards = {}, {}, {}
  local TRAJ_LEN = 340
  local back, ball_id, you_id, cpu_id, ult_btn, ult_txt, ebar, gbar_you, gbar_cpu, arena_btn
  local torii_top, torii_bot
  local HW, HH, FL, FR, FT, FB = 0, 0, 0, 0, 0, 0

  local function hud()
    game.set_text(string.format("YOU  %d  -  %d  CPU\nfirst to %d", score_you, score_cpu, WIN_SCORE))
  end

  local function serve(dir)
    -- gentle kickoff nudge toward a side so the ball is never a dead stalemate
    local d = dir or ((math.random() < 0.5) and -1 or 1)
    ball.x, ball.y, ball.vx, ball.vy = 0, 0, (math.random() * 2 - 1) * 90, d * 150
    you.x, you.y, you.vx, you.vy = 0, FB + 90, 0, 0
    cpu.x, cpu.y, cpu.vx, cpu.vy = 0, FT - 90, 0, 0
    serve_t = SERVE_DELAY
  end

  local function strike(on)                           -- on = the striker piece (you/cpu)
    if on.strike_t > 0 then return end                -- cooldown: no re-hit while in contact
    local dx, dy = ball.x - on.x, ball.y - on.y
    local d = math.sqrt(dx * dx + dy * dy)
    if d < BR + on.pr and d > 1e-4 then
      local nx, ny = dx / d, dy / d
      ball.x, ball.y = on.x + nx * (BR + on.pr), on.y + ny * (BR + on.pr)
      local cspd = math.sqrt(on.vx * on.vx + on.vy * on.vy)
      local kick = (200 + cspd * 0.75) * on.def.kick * (on.ultk or 1)
      ball.vx = ball.vx * 0.3 + nx * kick + on.vx * 0.4
      ball.vy = ball.vy * 0.3 + ny * kick + on.vy * 0.4
      on.ultk, on.ultk_t, on.strike_t, on.kick_t = 1, 0, 0.12, KICK_T
      on.energy = math.min(1, on.energy + ULT_GAIN)
      game.play_sound("hit"); game.haptic("light"); game.shake(0.12)
    end
  end

  local function fire_ult(p, is_you)
    if p.energy < 1 or over then return false end
    p.energy = 0
    local diry = is_you and 1 or -1                  -- attack direction (you go up)
    local u = p.def.ult
    if u == "guard" then
      p.guard_t = GUARD_T
      game.play_sound("score"); game.haptic("success"); game.shake(0.25)
    elseif u == "blink" then
      p.x = clamp(ball.x, FL + p.pr, FR - p.pr)
      p.y = ball.y - diry * (BR + p.pr + 4)
      p.y = is_you and clamp(p.y, FB + p.pr, 0) or clamp(p.y, 0, FT - p.pr)
      p.vx, p.vy = 0, diry * p.def.dash * 1.2
      p.ultk, p.ultk_t = 2.0, 0.7
      game.play_sound("hit"); game.haptic("heavy"); game.shake(0.35)
    else                                             -- rush / slam: homing power dash
      local ax, ay = ball.x - p.x, ball.y - p.y
      local m = math.sqrt(ax * ax + ay * ay) + 1e-6
      p.vx = p.vx + ax / m * p.def.dash * 1.5
      p.vy = p.vy + ay / m * p.def.dash * 1.5
      p.ultk, p.ultk_t = (u == "slam") and 3.0 or 2.0, 0.7
      game.play_sound("hit"); game.haptic("heavy"); game.shake(u == "slam" and 0.5 or 0.35)
    end
    return true
  end

  local function goal(who)
    if who == "you" then score_you = score_you + 1 else score_cpu = score_cpu + 1 end
    game.play_sound("score"); game.haptic("success"); game.shake(0.5); hud()
    if score_you >= WIN_SCORE then over = true; game.set_text("YOU WIN THE CUP!\nTap to play again"); game.log("win")
    elseif score_cpu >= WIN_SCORE then over = true; game.set_text("YOU LOSE\nTap to play again"); game.log("lose")
    else serve() end
  end

  local function integrate(o, dt)
    o.x = o.x + o.vx * dt; o.y = o.y + o.vy * dt
    local f = o.def.fric * fric_mul                    -- arena slipperiness
    o.vx = o.vx * (1 - f * dt); o.vy = o.vy * (1 - f * dt)
    if o.x < FL + o.pr then o.x = FL + o.pr; o.vx = math.abs(o.vx) * 0.5 end
    if o.x > FR - o.pr then o.x = FR - o.pr; o.vx = -math.abs(o.vx) * 0.5 end
    if o.ultk_t > 0 then o.ultk_t = o.ultk_t - dt; if o.ultk_t <= 0 then o.ultk = 1 end end
    if o.guard_t > 0 then o.guard_t = o.guard_t - dt end
    if o.strike_t > 0 then o.strike_t = o.strike_t - dt end
    if o.kick_t > 0 then o.kick_t = o.kick_t - dt end
  end

  -- Active opponent: always slide to line up with the ball; pursue and dash-strike
  -- when the ball is on the CPU's side or near centre, and fall back to guard the
  -- top goal when the ball is deep in the player's half. (Real-time, not turn-based.)
  local function move_cpu(dt)
    cpu_t = math.max(0, cpu_t - dt)
    local tx = clamp(ball.x, FL + cpu.pr, FR - cpu.pr)
    cpu.vx = cpu.vx + (tx - cpu.x) * 8 * dt          -- track the ball horizontally
    local attacking = ball.y > -80                    -- ball on CPU side or near centre
    local ty = attacking and clamp(ball.y - 16, 10, FT - cpu.pr)
                          or clamp(FT - 130, 40, FT - cpu.pr)   -- else guard the goal
    cpu.vy = cpu.vy + (ty - cpu.y) * 7 * dt
    if cpu.energy >= 1 and attacking then fire_ult(cpu, false) end
    -- dash into the ball (approach slightly from above so it knocks downward)
    if cpu_t <= 0 and attacking then
      local d = math.sqrt((ball.x - cpu.x) ^ 2 + (ball.y - cpu.y) ^ 2)
      if d < CPU_REACH then
        local ax, ay = ball.x - cpu.x, (ball.y - 22) - cpu.y
        local m = math.sqrt(ax * ax + ay * ay) + 1e-6
        cpu.vx = cpu.vx + ax / m * cpu.def.dash
        cpu.vy = cpu.vy + ay / m * cpu.def.dash
        cpu.kick_t = KICK_T                            -- kick/lunge pose
        cpu_t = CPU_CD
      end
    end
  end

  -- Positional collision: keep the ball from overlapping a character. Runs every
  -- frame, independent of the strike-impulse cooldown, so sprites never overlap.
  local function separate(c)
    local dx, dy = ball.x - c.x, ball.y - c.y
    local d = math.sqrt(dx * dx + dy * dy)
    local mind = BR + c.pr
    if d < mind then
      if d < 1e-4 then dx, dy, d = 0, 1, 1 end
      ball.x, ball.y = c.x + dx / d * mind, c.y + dy / d * mind
    end
  end

  -- Slingshot visuals: a stretched rubber band from the dumpling to the finger,
  -- PLUS a long forward trajectory preview drawn AHEAD of the dumpling (away from
  -- the finger) so power+direction stay visible while your thumb covers it.
  local function draw_sling(px, py)
    local ux, uy = you.x - px, you.y - py            -- pull-back vector
    local plen = math.sqrt(ux * ux + uy * uy)
    if plen < 4 then return end
    local dx, dy = ux / plen, uy / plen              -- dash direction (away from finger)
    local pw = math.min(plen, MAXPULL) / MAXPULL
    for i = 1, #band do
      local t = i / (#band + 1)
      game.move_to(band[i], you.x + (px - you.x) * t, you.y + (py - you.y) * t)
      game.set_color(band[i], 0.95, 0.42, 0.32, 0.85)
    end
    local L = 70 + pw * TRAJ_LEN
    for i = 1, #traj do
      local t = (i / #traj) * L
      game.move_to(traj[i], you.x + dx * (you.pr + t), you.y + dy * (you.pr + t))
      game.set_color(traj[i], 1, 0.9, 0.4, 0.9 - (i / #traj) * 0.5)
      local sz = (i == #traj) and 22 or 11
      game.set_size(traj[i], sz, sz)
    end
  end
  local function hide_sling()
    for i = 1, #band do game.set_color(band[i], 1, 1, 1, 0) end
    for i = 1, #traj do game.set_color(traj[i], 1, 1, 1, 0) end
  end

  ------------------------------------------------------------------ screens
  local function torii(cy)                            -- AI torii-gate sprite as the goal
    T.sprite(0, cy, GOAL_W + 30, 64, "u_torii")
  end

  local function start_match(you_key)
    T.clear(); screen = "play"
    you.def = char_by_key(you_key); you.pr = you.def.pr
    -- CPU picks a different character
    local ck = CHARS[1].key
    for _, c in ipairs(CHARS) do if c.key ~= you_key then ck = c.key; break end end
    cpu.def = char_by_key(ck); cpu.pr = cpu.def.pr
    you.energy, cpu.energy, you.ultk, cpu.ultk, you.guard_t, cpu.guard_t = 0, 0, 1, 1, 0, 0
    -- idle/standing uses walk-frame 2 (legs together) so the outfit matches the
    -- walk animation (both come from the same sprite sheet, not the older base art)
    you.tex, cpu.tex, you.ftime, cpu.ftime = you.def.icon .. "_w2", cpu.def.icon .. "_w2", 0, 0
    score_you, score_cpu, over = 0, 0, false
    -- per-arena hazard tuning (1 tea house calm, 2 beach waves, 3 ramen slippery,
    -- 4 sushi conveyor). Wave/conveyor forces are applied in the ball update.
    htime = 0
    if arena_i == 3 then bfric, fric_mul = 0.12, 0.55        -- ramen: slippery
    else bfric, fric_mul = 0.5, 1.0 end
    -- AI court backdrop (the chosen arena) — open court, gates are separate sprites.
    T.sprite(0, (FT + FB) / 2, (FR - FL + WALL) * 1.06, (FT - FB + WALL) * 1.06, ARENAS[arena_i])
    gbar_cpu = T.spawn(0, FT, GOAL_W, 14, 0.4, 0.7, 1.0, 0)
    gbar_you = T.spawn(0, FB, GOAL_W, 14, 0.4, 0.7, 1.0, 0)
    for i = 1, 5 do band[i] = T.spawn(0, -9999, 12, 12, 1, 1, 1, 0) end
    for i = 1, 12 do traj[i] = T.spawn(0, -9999, 11, 11, 1, 1, 1, 0) end
    you_id = T.sprite(0, 0, you.pr * 2.1, you.pr * 2.1, you.def.icon .. "_w2")
    cpu_id = T.sprite(0, 0, cpu.pr * 2.1, cpu.pr * 2.1, cpu.def.icon .. "_w2")
    ball_id = T.sprite(0, 0, BR * 2.3, BR * 2.3, "u_ball")   -- soy dumpling
    -- Torii gates as FOREGROUND sprites (spawned last = highest z) so a character
    -- walking onto the goal line passes BEHIND the gate — "into the doorway" — and
    -- the ball reads as going through the gate into the goal.
    torii_top = T.sprite(0, FT + 6, GOAL_W + 40, 84, "u_torii")
    torii_bot = T.sprite(0, FB - 6, GOAL_W + 40, 84, "u_torii")
    ebar = T.spawn(-HW + 60, FB - 34, 8, 20, 1, 0.85, 0.3, 1)     -- energy bar (grows)
    ult_btn = { x = HW - 74, y = FB - 24, w = 108, h = 64 }
    T.spawn(ult_btn.x, ult_btn.y, ult_btn.w, ult_btn.h, 0.3, 0.3, 0.35, 0.6)
    ult_txt = T.text(ult_btn.x, ult_btn.y, 24, 1, 1, 1, 0.5, "ULT")
    back = K.make_back(T, HW, HH)
    serve(); hud()
    DEBUG = {
      game = "umami", screen = "play", back = back,
      start = function(k) start_match(k or "soba") end,
      ball = function() return ball end, you = function() return you end, cpu = function() return cpu end,
      score = function() return { p = score_you, c = score_cpu } end,
      over = function() return over end, serving = function() return serve_t > 0 end,
      energy = function() return you.energy end, char = function() return you.def.key end,
      cpu_char = function() return cpu.def.key end,
      set_energy = function(e) you.energy = e end,
      fire_ult = function() return fire_ult(you, true) end,
      guard = function() return you.guard_t end,
      set_ball = function(x, y, vx, vy) ball.x, ball.y, ball.vx, ball.vy = x, y, vx, vy end,
      flick = function(dx, dy, p)
        local d = math.sqrt(dx * dx + dy * dy) + 1e-6
        you.vx = you.vx + dx / d * you.def.dash * clamp(p, 0, 1)
        you.vy = you.vy + dy / d * you.def.dash * clamp(p, 0, 1)
      end,
    }
  end

  local function show_select()
    T.clear(); screen = "select"; game.set_text("")
    T.text(0, HH - 150, 42, 1, 1, 1, 1, "PICK YOUR FIGHTER")
    cards = {}
    local bw, bh, gap = 150, 176, 24
    for i, c in ipairs(CHARS) do
      local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
      local x = (col - 0.5) * (bw + gap)
      local y = 40 - row * (bh + gap)
      T.spawn(x, y, bw, bh, c.col[1] * 0.6, c.col[2] * 0.6, c.col[3] * 0.6, 0.95)
      T.sprite(x, y + 34, 68, 68, c.icon .. "_w2")   -- same art as in-match
      T.text(x, y - 28, 26, 1, 1, 1, 1, c.name)
      T.text(x, y - 58, 16, 1, 0.95, 0.7, 1, c.note)
      cards[#cards + 1] = { x = x, y = y, w = bw, h = bh, key = c.key }
    end
    -- arena picker (tap to cycle through the four courts)
    local anames = { "TEA HOUSE", "BEACH", "RAMEN BOWL", "SUSHI BAR" }
    local ahints = { "calm & precise", "rolling waves", "slippery!", "conveyor drift" }
    arena_btn = { x = 0, y = -HH + 132, w = 300, h = 56 }
    T.spawn(arena_btn.x, arena_btn.y, arena_btn.w, arena_btn.h, 0.28, 0.34, 0.30, 0.9)
    T.text(arena_btn.x, arena_btn.y + 12, 22, 1, 1, 1, 1, "ARENA: " .. anames[arena_i])
    T.text(arena_btn.x, arena_btn.y - 16, 14, 1, 0.92, 0.5, 1, ahints[arena_i] .. "  (tap)")
    back = K.make_back(T, HW, HH)
    DEBUG.screen = "select"; DEBUG.back = back; DEBUG.arena = function() return arena_i end
    DEBUG.arena_btn = arena_btn
  end

  ------------------------------------------------------------------ scene
  return {
    enter = function() built = false; screen = nil; game.set_bg_theme(0)
      DEBUG = { game = "umami", start = function(k) start_match(k or "soba") end } end,
    leave = function() T.clear(); built = false end,
    tap = function(x, y)
      if back and inr(back, x, y) then
        if screen == "play" then show_select() else K.switch("menu") end
        return
      end
      if screen == "select" then
        if arena_btn and inr(arena_btn, x, y) then
          arena_i = (arena_i % #ARENAS) + 1
          game.play_sound("wall"); game.haptic("light"); show_select(); return
        end
        for _, c in ipairs(cards) do if inr(c, x, y) then
          game.play_sound("hit"); game.haptic("light"); start_match(c.key); return
        end end
      elseif screen == "play" then
        if over then show_select(); return end
        if ult_btn and inr(ult_btn, x, y) then fire_ult(you, true) end
      end
    end,
    update = function(dt, hw, hh)
      HW, HH = hw, hh
      FL, FR = -hw + WALL, hw - WALL
      FT, FB = hh - TOPPAD, -hh + BOTPAD
      if screen == nil then show_select() end
      if screen ~= "play" then return end
      if not over then
        dt = math.min(dt, MAX_DT)
        -- slingshot input
        local px, py, down = game.pointer()
        if down and px and py then
          if not charging and serve_t <= 0
            and (px - you.x) ^ 2 + (py - you.y) ^ 2 < (you.pr * 3.2) ^ 2 then charging = true end
          if charging then
            local ux, uy = you.x - px, you.y - py
            cpull = { x = ux, y = uy, len = math.sqrt(ux * ux + uy * uy) }
            draw_sling(px, py)
          end
        else
          if charging and cpull and cpull.len > 10 then
            local p = math.min(cpull.len, MAXPULL) / MAXPULL
            you.vx = you.vx + cpull.x / cpull.len * you.def.dash * p
            you.vy = you.vy + cpull.y / cpull.len * you.def.dash * p
            you.kick_t = KICK_T                       -- kick/lunge pose
            game.play_sound("wall"); game.haptic("medium")
          end
          charging = false; cpull = nil; hide_sling()
        end

        if serve_t > 0 then serve_t = serve_t - dt end
        move_cpu(dt)
        integrate(you, dt); integrate(cpu, dt)
        -- allow stepping onto the goal line (into the gate doorway); the
        -- foreground torii then occludes the upper body -> "into the door".
        you.y = clamp(you.y, FB, 0)
        cpu.y = clamp(cpu.y, 0, FT)
        if serve_t <= 0 then
          -- arena hazard forces on the ball
          htime = htime + dt
          if arena_i == 2 then ball.vx = ball.vx + math.sin(htime * 1.1) * 120 * dt   -- beach: rolling waves
          elseif arena_i == 4 then ball.vx = ball.vx + 75 * dt end                     -- sushi: conveyor drift
          ball.x = ball.x + ball.vx * dt; ball.y = ball.y + ball.vy * dt
          ball.vx = ball.vx * (1 - bfric * dt); ball.vy = ball.vy * (1 - bfric * dt)
          local sp = math.sqrt(ball.vx * ball.vx + ball.vy * ball.vy)
          if sp > BALL_MAX then ball.vx, ball.vy = ball.vx / sp * BALL_MAX, ball.vy / sp * BALL_MAX end
          if ball.x < FL + BR then ball.x = FL + BR; ball.vx = math.abs(ball.vx); game.play_sound("wall") end
          if ball.x > FR - BR then ball.x = FR - BR; ball.vx = -math.abs(ball.vx); game.play_sound("wall") end
          if ball.y > FT - BR then
            if math.abs(ball.x) < GOAL_W / 2 and cpu.guard_t <= 0 then goal("you")
            else ball.y = FT - BR; ball.vy = -math.abs(ball.vy); game.play_sound("wall") end
          elseif ball.y < FB + BR then
            if math.abs(ball.x) < GOAL_W / 2 and you.guard_t <= 0 then goal("cpu")
            else ball.y = FB + BR; ball.vy = math.abs(ball.vy); game.play_sound("wall") end
          end
          strike(you); strike(cpu)
        end
        -- Keep the ball off both characters every frame (even during the serve
        -- freeze, when characters move but the ball doesn't) so sprites never overlap.
        separate(you); separate(cpu)
      end

      -- render: ball rolls (spin ∝ speed, direction from horizontal travel)
      local bspd = math.sqrt(ball.vx * ball.vx + ball.vy * ball.vy)
      ball.roll = ball.roll + (ball.vx >= 0 and 1 or -1) * bspd * dt / BR
      game.set_rotation(ball_id, ball.roll)
      game.move_to(ball_id, ball.x, ball.y)
      -- characters: play the 4-frame WALK sprite sheet while moving (base sprite
      -- when idle); a kick adds a punch-scale + lean on top of the current frame.
      local function anim(c, id)
        local spd = math.sqrt(c.vx * c.vx + c.vy * c.vy)
        local bs = c.pr * 2.1
        c.ftime = c.ftime + dt * (6 + spd * 0.05)          -- faster walk -> faster cycle
        local want = c.def.icon .. "_w2"                   -- standing pose (same sheet)
        if spd > 25 then want = c.def.icon .. "_w" .. (math.floor(c.ftime) % 4 + 1) end
        if want ~= c.tex then c.tex = want; game.set_sprite_image(id, want) end
        local w, h, rot, boby = bs, bs, 0, 0
        if c.kick_t > 0 then
          local k = c.kick_t / KICK_T                      -- 1 -> 0
          w, h = bs * (1 + 0.28 * k), bs * (1 + 0.10 * k)  -- lunge/punch
          rot = 0.45 * k * (c.vx >= 0 and 1 or -1)         -- lean into the kick
        elseif spd > 25 then
          boby = math.abs(math.sin(c.ftime * 3.1)) * 3     -- gentle bob
          rot = 0.05 * math.sin(c.ftime * 3.1)
        end
        game.set_size(id, w, h); game.set_rotation(id, rot)
        game.move_to(id, c.x, c.y + boby)
      end
      anim(you, you_id); anim(cpu, cpu_id)
      game.set_size(ebar, 8, 6 + you.energy * 46); game.move_to(ebar, -HW + 60, FB - 34 + you.energy * 23)
      if ult_txt then game.set_color(ult_txt, 1, 1, 0.5, you.energy >= 1 and 1 or 0.45) end
      game.set_color(gbar_you, 0.4, 0.7, 1.0, you.guard_t > 0 and 0.8 or 0)
      game.set_color(gbar_cpu, 1.0, 0.5, 0.4, cpu.guard_t > 0 and 0.8 or 0)
    end,
  }
end

-- Self-register this game pack (see main.lua: menu builds from PACKS).
PACKS = PACKS or {}
PACKS["umami"] = { slot = 9, key = "umami", label = "Umami Cup", short = "Umami Cup", icon = "food", color = { 0.62, 0.30, 0.26 }, tier = "curated", make = make_umami }
