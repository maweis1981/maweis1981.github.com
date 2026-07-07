-- roguelike.lua — a small arena survivors-like ("roguelike"), game #4.
--
-- Loaded from its OWN file (see EXTRA_SCRIPTS in src/script.rs); registers the
-- global make_roguelike that main.lua adds to the menu. Uses GAME_KIT + `game`.
--
-- Loop: steer with a FLOATING JOYSTICK (touch anywhere; drag to move) or WASD to
-- dodge enemies that chase you; you auto-fire at the nearest one. Hits flash +
-- knock back enemies with a tiny hitstop; kills pop into particles and drop XP
-- gems that magnetise to you. Collect XP to level up and pick 1 of 3 upgrades.
-- Enemies come in variants and ramp up over time. Lose all HP -> game over.
--
-- Interaction/feel follows twin-stick-roguelite conventions (Vampire Survivors /
-- Brotato): move-only one-thumb control, auto-aim/fire, and juice on every hit.

function make_roguelike()
  local K = GAME_KIT
  local clamp, inr = K.clamp, K.in_rect

  local PSIZE, BSIZE, GSIZE = 26, 12, 16
  local BASE_MOVE, BULLET_SPEED, BASE_ESPEED = 330, 480, 60
  local JOY_RANGE, MAGNET_R, MAGNET_SPEED = 90, 145, 340
  local MAX_ENEMIES, MAX_DT, CONTACT_CD = 60, 1 / 30, 0.7
  local FLASH_T, HITSTOP, KNOCK = 0.12, 0.05, 16

  -- Enemy variants: {tint, size, hp mult, speed mult, xp}. Distinct colours read
  -- at a glance (white grunt, orange darter, violet brute).
  local ETYPES = {
    { tint = { 1.0, 1.0, 1.0 }, size = 24, hp = 0, spd = 1.0, xp = 1 },
    { tint = { 1.0, 0.66, 0.42 }, size = 20, hp = 0, spd = 1.55, xp = 1 },
    { tint = { 0.68, 0.58, 1.0 }, size = 34, hp = 3, spd = 0.62, xp = 3 },
  }

  local T = K.tracker()
  local player, back, joy_base, joy_knob
  local px, py, hp, max_hp = 0, 0, 5, 5
  local move_speed, damage, fire_int, nbullets = BASE_MOVE, 1, 0.6, 1
  local enemies, bullets, gems, fx = {}, {}, {}, {}
  local fire_t, spawn_t, elapsed, hurt_cd = 0, 0, 0, 0
  local xp, xp_need, level, kills = 0, 4, 1, 0
  local playing, leveling, built = true, false, false
  local choices, choice_ids, joy = {}, {}, nil
  local HW, HH = 0, 0

  local UPGRADES = {
    { label = "+1 Damage", apply = function() damage = damage + 1 end },
    { label = "+Fire Rate", apply = function() fire_int = math.max(0.09, fire_int * 0.82) end },
    { label = "+Move Speed", apply = function() move_speed = move_speed + 55 end },
    { label = "Heal +2", apply = function() hp = math.min(max_hp, hp + 2) end },
    { label = "+2 Max HP", apply = function() max_hp = max_hp + 2; hp = hp + 2 end },
    { label = "+1 Bullet", apply = function() nbullets = nbullets + 1 end },
  }

  local function hud()
    game.set_text(string.format("HP %d/%d   LV %d   KILL %d", hp, max_hp, level, kills))
  end

  ------------------------------------------------------------------ juice fx
  local function particle(x, y, col, n, spread)
    for i = 1, n do
      local a = (i / n) * 6.28
      local id = game.spawn_sprite(x, y, GSIZE, GSIZE, "sparkle")
      game.set_color(id, col[1], col[2], col[3], 1)
      fx[#fx + 1] = { id = id, x = x, y = y, vx = math.cos(a) * spread, vy = math.sin(a) * spread,
        life = 0.4, ttl = 0.4, size = GSIZE, r = col[1], g = col[2], b = col[3], part = true }
    end
  end
  local function dmg_number(x, y, n)
    fx[#fx + 1] = { id = game.spawn_text(x, y, 22, 1, 0.95, 0.5, 1, tostring(n)),
      x = x, y = y, vx = 0, vy = 70, life = 0.5 }
  end
  local function update_fx(dt)
    local keep = {}
    for _, e in ipairs(fx) do
      e.life = e.life - dt
      if e.life <= 0 then game.despawn(e.id) else
        e.x = e.x + e.vx * dt; e.y = e.y + e.vy * dt
        game.move_to(e.id, e.x, e.y)
        if e.part then
          e.size = e.size * (1 - dt * 1.5); game.set_size(e.id, e.size, e.size)
          game.set_color(e.id, e.r, e.g, e.b, e.life / e.ttl)
        end
        keep[#keep + 1] = e
      end
    end
    fx = keep
  end

  local function despawn_all(list) for _, e in ipairs(list) do game.despawn(e.id) end end
  local function clear_choices() for _, id in ipairs(choice_ids) do game.despawn(id) end; choice_ids = {} end
  local function cleanup()
    despawn_all(enemies); despawn_all(bullets); despawn_all(gems); despawn_all(fx); clear_choices()
    enemies, bullets, gems, fx = {}, {}, {}, {}
    T.clear()
  end

  local function game_over()
    playing = false
    game.set_text(string.format("GAME OVER\nLV %d   KILL %d\nTap to restart", level, kills))
    game.play_sound("hit"); game.haptic("heavy"); game.shake(0.6); game.log("lose")
  end

  local function start_levelup()
    leveling = true
    local pool = {}
    for i = 1, #UPGRADES do pool[i] = UPGRADES[i] end
    choices = {}
    for i = 1, 3 do choices[i] = table.remove(pool, math.random(1, #pool)) end
    clear_choices()
    local tw, th = math.min(2 * HW - 80, 420), 84
    game.set_text(string.format("LEVEL UP  (LV %d) — choose:", level))
    for i, up in ipairs(choices) do
      local ty = (th + 20) - (i - 1) * (th + 18)
      choice_ids[#choice_ids + 1] = game.spawn(0, ty, tw, th, 0.28, 0.30, 0.42, 0.96)
      choice_ids[#choice_ids + 1] = game.spawn_text(0, ty, 30, 1, 1, 1, 1, up.label)
      up.rect = { x = 0, y = ty, w = tw, h = th }
    end
    game.play_sound("score"); game.haptic("success")
  end

  local function gain_xp(amount)
    xp = xp + amount
    if xp >= xp_need then
      xp = xp - xp_need; level = level + 1; xp_need = xp_need + 3; start_levelup()
    end
  end

  local function spawn_enemy()
    if #enemies >= MAX_ENEMIES then return end
    local ex, ey, edge = 0, 0, math.random(1, 4)
    if edge == 1 then ex, ey = -HW - 20, (math.random() * 2 - 1) * HH
    elseif edge == 2 then ex, ey = HW + 20, (math.random() * 2 - 1) * HH
    elseif edge == 3 then ex, ey = (math.random() * 2 - 1) * HW, HH + 20
    else ex, ey = (math.random() * 2 - 1) * HW, -HH - 20 end
    -- introduce tougher variants as the run goes on
    local roll = math.random()
    local ti = 1
    if elapsed > 60 and roll < 0.22 then ti = 3 elseif elapsed > 25 and roll < 0.4 then ti = 2 end
    local et = ETYPES[ti]
    local id = game.spawn_sprite(ex, ey, et.size, et.size, "enemy")
    game.set_color(id, et.tint[1], et.tint[2], et.tint[3], 1)
    enemies[#enemies + 1] = { id = id, x = ex, y = ey, size = et.size, tint = et.tint, spd = et.spd,
      xp = et.xp, hp = 1 + et.hp + math.floor(elapsed / 25), flash = 0, freeze = 0 }
  end

  local function nearest_enemy()
    local best, bd
    for _, e in ipairs(enemies) do
      local d = (e.x - px) ^ 2 + (e.y - py) ^ 2
      if not bd or d < bd then bd, best = d, e end
    end
    return best
  end

  local function fire()
    local tgt = nearest_enemy()
    if not tgt then return end
    local ang = math.atan(tgt.y - py, tgt.x - px)
    for i = 1, nbullets do
      local a = ang + (i - (nbullets + 1) / 2) * 0.18
      local id = game.spawn_sprite(px, py, BSIZE, BSIZE, "orb")
      game.set_color(id, 1.0, 0.9, 0.3, 1)
      bullets[#bullets + 1] = { id = id, x = px, y = py,
        vx = math.cos(a) * BULLET_SPEED, vy = math.sin(a) * BULLET_SPEED, life = 1.6 }
    end
    particle(px, py, { 1.0, 0.92, 0.5 }, 3, 60)   -- muzzle flash
    game.play_sound("wall")
  end

  local function build(hw, hh)
    HW, HH = hw, hh
    enemies, bullets, gems, fx = {}, {}, {}, {}
    px, py, hp, max_hp = 0, 0, 5, 5
    move_speed, damage, fire_int, nbullets = BASE_MOVE, 1, 0.6, 1
    fire_t, spawn_t, elapsed, hurt_cd = 0, 0, 0, 0
    xp, xp_need, level, kills = 0, 4, 1, 0
    playing, leveling, joy = true, false, nil
    joy_base = game.spawn_sprite(0, -9999, 120, 120, "orb"); game.set_color(joy_base, 1, 1, 1, 0)
    joy_knob = game.spawn_sprite(0, -9999, 54, 54, "orb"); game.set_color(joy_knob, 1, 1, 1, 0)
    player = T.sprite(0, 0, PSIZE, PSIZE, "hero")
    back = K.make_back(T, hw, hh)
    hud(); built = true
    DEBUG = {
      game = "roguelike", back = back, player = player,
      hp = function() return hp end, level = function() return level end,
      kills = function() return kills end, enemies = function() return #enemies end,
      alive = function() return playing end, leveling = function() return leveling end,
      choices = function() return choices end,
    }
  end

  local function move_player(dt)
    local dpx, dpy, down = game.pointer()
    local lx, ly = HW - PSIZE * 0.5, HH - PSIZE * 0.5
    local vx, vy = 0, 0
    if down and dpx ~= nil and dpy ~= nil then
      if not joy then joy = { ax = dpx, ay = dpy } end     -- floating stick: anchor where the thumb lands
      local ddx, ddy = dpx - joy.ax, dpy - joy.ay
      local d = math.sqrt(ddx * ddx + ddy * ddy)
      if d > 1 then
        local m = math.min(d, JOY_RANGE) / JOY_RANGE
        vx, vy = ddx / d * move_speed * m, ddy / d * move_speed * m
      end
      local cl = math.min(d, JOY_RANGE)
      game.move_to(joy_base, joy.ax, joy.ay); game.set_color(joy_base, 0.85, 0.92, 1.0, 0.16)
      game.move_to(joy_knob, joy.ax + (d > 0 and ddx / d * cl or 0), joy.ay + (d > 0 and ddy / d * cl or 0))
      game.set_color(joy_knob, 0.8, 0.9, 1.0, 0.5)
    else
      joy = nil
      game.set_color(joy_base, 1, 1, 1, 0); game.set_color(joy_knob, 1, 1, 1, 0)
      if game.key("left") or game.key("a") then vx = vx - move_speed end
      if game.key("right") or game.key("d") then vx = vx + move_speed end
      if game.key("up") or game.key("w") then vy = vy + move_speed end
      if game.key("down") or game.key("s") then vy = vy - move_speed end
    end
    px = clamp(px + vx * dt, -lx, lx); py = clamp(py + vy * dt, -ly, ly)
  end

  return {
    enter = function() built = false end,
    leave = function() cleanup(); if joy_base then game.despawn(joy_base) end
      if joy_knob then game.despawn(joy_knob) end; built = false end,
    tap = function(x, y)
      if back and inr(back, x, y) then K.switch("menu"); return end
      if leveling then
        for _, up in ipairs(choices) do
          if up.rect and inr(up.rect, x, y) then
            up.apply(); clear_choices(); leveling = false; hud(); return
          end
        end
        return
      end
      if not playing then cleanup(); build(HW, HH) end
    end,
    update = function(dt, hw, hh)
      HW, HH = hw, hh
      if not built then build(hw, hh) end
      if not playing or leveling then return end
      dt = math.min(dt, MAX_DT)
      elapsed = elapsed + dt
      hurt_cd = math.max(0, hurt_cd - dt)
      move_player(dt)

      local spawn_int = math.max(0.35, 1.3 - elapsed * 0.02)
      spawn_t = spawn_t + dt
      while spawn_t >= spawn_int do spawn_t = spawn_t - spawn_int; spawn_enemy() end

      local espeed = BASE_ESPEED + elapsed * 1.4
      for _, e in ipairs(enemies) do
        e.flash = math.max(0, e.flash - dt)
        e.freeze = math.max(0, e.freeze - dt)
        if e.freeze <= 0 then
          local dx, dy = px - e.x, py - e.y
          local d = math.sqrt(dx * dx + dy * dy) + 1e-6
          e.x = e.x + dx / d * espeed * e.spd * dt; e.y = e.y + dy / d * espeed * e.spd * dt
        end
        game.move_to(e.id, e.x, e.y)
        if e.flash > 0 then game.set_color(e.id, 1, 1, 1, 1)
        else game.set_color(e.id, e.tint[1], e.tint[2], e.tint[3], 1) end
        local d = math.sqrt((px - e.x) ^ 2 + (py - e.y) ^ 2)
        if hurt_cd <= 0 and d < (PSIZE + e.size) * 0.5 then
          hp = hp - 1; hurt_cd = CONTACT_CD
          game.play_sound("hit"); game.haptic("heavy"); game.shake(0.22)
          if hp <= 0 then game_over(); return end
          hud()
        end
      end

      fire_t = fire_t + dt
      while fire_t >= fire_int do fire_t = fire_t - fire_int; fire() end

      for bi = #bullets, 1, -1 do
        local b = bullets[bi]
        b.x = b.x + b.vx * dt; b.y = b.y + b.vy * dt; b.life = b.life - dt
        local hit = false
        for ei = #enemies, 1, -1 do
          local e = enemies[ei]
          if math.abs(b.x - e.x) < (e.size + BSIZE) * 0.5 and math.abs(b.y - e.y) < (e.size + BSIZE) * 0.5 then
            e.hp = e.hp - damage; hit = true
            e.flash = FLASH_T; e.freeze = HITSTOP
            local bl = math.sqrt(b.vx * b.vx + b.vy * b.vy) + 1e-6
            e.x = e.x + b.vx / bl * KNOCK; e.y = e.y + b.vy / bl * KNOCK
            dmg_number(e.x, e.y + e.size * 0.5, damage)
            if e.hp <= 0 then
              particle(e.x, e.y, e.tint, 6, 130)
              gems[#gems + 1] = { id = game.spawn_sprite(e.x, e.y, GSIZE, GSIZE, "gem"), x = e.x, y = e.y, xp = e.xp }
              game.despawn(e.id); table.remove(enemies, ei)
              kills = kills + 1; game.play_sound("hit"); game.shake(0.08 + 0.02 * e.size / 24); hud()
            end
            break
          end
        end
        if hit or b.life <= 0 or b.x < -HW - 30 or b.x > HW + 30 or b.y < -HH - 30 or b.y > HH + 30 then
          game.despawn(b.id); table.remove(bullets, bi)
        else
          game.move_to(b.id, b.x, b.y)
        end
      end

      for gi = #gems, 1, -1 do
        local g = gems[gi]
        local dx, dy = px - g.x, py - g.y
        local d = math.sqrt(dx * dx + dy * dy) + 1e-6
        if d < MAGNET_R then g.x = g.x + dx / d * MAGNET_SPEED * dt; g.y = g.y + dy / d * MAGNET_SPEED * dt end
        if d < (PSIZE + GSIZE) * 0.5 then
          game.despawn(g.id); table.remove(gems, gi)
          game.play_sound("wall"); gain_xp(g.xp)
          if leveling then game.move_to(player, px, py); update_fx(dt); return end
        else
          game.move_to(g.id, g.x, g.y)
        end
      end

      local flash = hurt_cd > 0 and (0.5 + 0.5 * math.cos(hurt_cd * 30)) or 0
      game.set_color(player, 1, 1 - flash * 0.6, 1 - flash * 0.6, 1)
      game.move_to(player, px, py)
      update_fx(dt)
    end,
  }
end

-- Self-register this game pack (see main.lua: menu builds from PACKS).
PACKS = PACKS or {}
PACKS["roguelike"] = { slot = 4, key = "roguelike", label = "Roguelike", short = "Rogue", icon = "hero", color = { 0.72, 0.4, 0.9 }, tier = "preset", make = make_roguelike }
