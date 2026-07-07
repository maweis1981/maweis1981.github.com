-- main.lua — a mini-game collection.
--
-- A tiny scene router (menu + games) on top of the Rust `game` bridge. Each game
-- is a closure returning { enter, update, tap, leave }; the menu lists them and
-- switches scenes. Games clean up their own entities on leave and expose a
-- `DEBUG` table (key entities/state) so tools/test_pong.lua can drive them.
--
-- Games:
--   1. Grow the Paddle — Pong variant: hit green to grow, red to shrink; fill
--      the screen to win. (Relative drag control.)
--   2. Breakout        — the classic Bevy example, ported: clear all bricks.
--   3. Snake           — grid snake: eat food, avoid walls and yourself.
--
-- Host API: see src/script.rs (spawn/move_to/set_color/set_size/spawn_text/
-- despawn/set_text/shake/play_sound/play_music/haptic/pointer/key/bounds).

local function clamp(v, lo, hi)
  if v < lo then return lo elseif v > hi then return hi else return v end
end
local function sign(v) if v > 0 then return 1 elseif v < 0 then return -1 else return 0 end end
local function in_rect(r, x, y)
  return math.abs(x - r.x) <= r.w * 0.5 and math.abs(y - r.y) <= r.h * 0.5
end

-- Tracks the entities a scene spawns so it can despawn them all on leave.
local function tracker()
  local ids = {}
  return {
    spawn = function(...) local id = game.spawn(...); ids[#ids + 1] = id; return id end,
    sprite = function(...) local id = game.spawn_sprite(...); ids[#ids + 1] = id; return id end,
    text = function(...) local id = game.spawn_text(...); ids[#ids + 1] = id; return id end,
    clear = function() for _, id in ipairs(ids) do game.despawn(id) end; ids = {} end,
  }
end

-- A "< BACK" button that stops the game and returns to the menu. Pinned to the
-- top-LEFT, well below the top edge so the iPhone Dynamic Island / status bar
-- never covers it. Games hit-test the returned rect in their tap handler.
local function make_back(T, hw, hh)
  -- A sprite button (wooden "return to lobby" sign); the returned rect is the
  -- tap target games hit-test, so the event is effectively bound to the sprite.
  local r = { x = -hw + 84, y = hh - 152, w = 132, h = 76 }
  T.sprite(r.x, r.y, r.w, r.h, "btn_back")
  return r
end

local scenes = {}
local order = {}
local current = nil
local booted = false

-- Single-game builds (tools/export_web_games.sh) prepend `AUTOBOOT = "<key>"`
-- to this file: the router then boots straight into that game and any
-- "back to menu" becomes a re-enter of the same game — the menu never shows.
local function switch(key)
  if AUTOBOOT and key == "menu" then key = AUTOBOOT end
  if current and current.leave then current.leave() end
  current = scenes[key]
  if current and current.enter then current.enter() end
end

-- Helpers exposed to external game modules (loaded from their own .lua files,
-- e.g. scripts/roguelike.lua). They run before main.lua, so they only *use*
-- GAME_KIT at scene-build time, by which point this table exists.
GAME_KIT = {
  clamp = clamp,
  sign = sign,
  in_rect = in_rect,
  tracker = tracker,
  make_back = make_back,
  switch = function(k) switch(k) end,
}

-- App-wide settings, read by games. `hud` gates the on-screen HUD text (the
-- router blanks it every frame when off); Settings (in the menu) toggles it.
SETTINGS = SETTINGS or { hud = true }

-- ===================================================================
-- Game 1: Grow the Paddle
-- ===================================================================
local function make_grow()
  local T = tracker()
  local PADDLE_W, AI_H, BALL, MARGIN = 20, 120, 22, 46
  local PADDLE_SPEED, DRAG_SENS = 1800, 2.6   -- higher gain + cap: shorter finger travel
  local AI_SPEED, AI_DEADZONE = 430, 10
  local BALL_SPEED, BALL_MAX, SPEEDUP, MAX_ANGLE = 360, 720, 1.03, 0.87
  local MAX_DT, SERVE_DELAY, TRAIL_N = 1 / 30, 0.8, 12
  local H_START, H_MIN, GROW, SHRINK, GOOD_CHANCE = 90, 26, 34, 44, 0.58
  local BASE_L, BASE_R = { 0.55, 0.78, 1.0 }, { 1.0, 0.55, 0.30 }
  local GOOD_C, BAD_C = { 0.30, 0.95, 0.55 }, { 1.0, 0.32, 0.32 }

  local left, right, ball, back
  local ly, ry, lh = 0, 0, H_START
  local bx, by, bvx, bvy, ball_good = 0, 0, 0, 0, true
  local wait, pdir, playing, drag_prev = 0, -1, true, nil
  local l_flash, l_col, r_flash = 0, GOOD_C, 0
  local trail, tcur, built, HH, HW = {}, 0, false, 0, 0

  local function blend(a, b, t)
    return a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t, a[3] + (b[3] - a[3]) * t
  end
  local function hud() game.set_text(string.format("%d%%", math.floor(100 * lh / (2 * HH)))) end
  local function set_size()
    game.set_size(left, PADDLE_W, lh)
    local lim = math.max(0, HH - lh * 0.5); ly = clamp(ly, -lim, lim)
  end
  local function win() playing = false; game.set_text("YOU WIN!\nTap to restart")
    game.play_sound("score"); game.haptic("success"); game.shake(0.7); game.log("win") end
  local function lose() playing = false; game.set_text("GAME OVER\nTap to restart")
    game.play_sound("hit"); game.haptic("heavy"); game.shake(0.7); game.log("lose") end
  local function grow() lh = math.min(lh + GROW, 2 * HH); set_size()
    if lh >= 2 * HH then win() else hud() end end
  local function shrink() lh = lh - SHRINK
    if lh <= H_MIN then lh = H_MIN; set_size(); lose() else set_size(); hud() end end
  local function roll() ball_good = math.random() < GOOD_CHANCE
    local c = ball_good and GOOD_C or BAD_C; game.set_color(ball, c[1], c[2], c[3], 1) end
  local function serve(d) bx, by, bvx, bvy = 0, 0, 0, 0; wait, pdir = SERVE_DELAY, d; roll() end
  local function launch() bvx = BALL_SPEED * pdir; bvy = BALL_SPEED * (math.random() * 0.6 - 0.3) end
  local function rebound(py, fx, dir, hh)
    local off = clamp((by - py) / hh, -1, 1)
    local s = math.min(math.sqrt(bvx * bvx + bvy * bvy) * SPEEDUP, BALL_MAX)
    local a = off * MAX_ANGLE; bx = fx; bvx = dir * s * math.cos(a); bvy = s * math.sin(a)
  end
  local function build(hw, hh)
    local seg, gap = 22, 16; local st = seg + gap
    local n = math.floor((2 * hh) / st); local y = -(n - 1) * st * 0.5
    for _ = 1, n do T.spawn(0, y, 4, seg, 1, 1, 1, 0.14); y = y + st end
    for i = 1, TRAIL_N do
      trail[i] = { id = T.spawn(0, 0, BALL * 0.7, BALL * 0.7, 0.75, 0.85, 1.0, 0), a = 0 }
    end
    left = T.sprite(-hw + MARGIN, 0, PADDLE_W, H_START, "paddle")
    right = T.sprite(hw - MARGIN, 0, PADDLE_W, AI_H, "paddle")
    ball = T.sprite(0, 0, BALL, BALL, "orb")
    back = make_back(T, hw, hh)
    lh, ly, ry, playing = H_START, 0, 0, true
    hud(); serve(-1); built = true
    DEBUG = { game = "grow", ball = ball, left = left, right = right, back = back, get_lh = function() return lh end }
  end
  local function move_player(dt, limit)
    local _, py, down = game.pointer(); local mx = PADDLE_SPEED * dt
    if down and py ~= nil then
      if drag_prev ~= nil then ly = clamp(ly + clamp((py - drag_prev) * DRAG_SENS, -mx, mx), -limit, limit) end
      drag_prev = py
    else
      drag_prev = nil; local vy = 0
      if game.key("up") or game.key("w") then vy = vy + PADDLE_SPEED end
      if game.key("down") or game.key("s") then vy = vy - PADDLE_SPEED end
      ly = clamp(ly + vy * dt, -limit, limit)
    end
  end

  return {
    enter = function() built = false end,
    leave = function() T.clear(); built = false end,
    tap = function(x, y)
      if back and in_rect(back, x, y) then switch("menu"); return end
      if not playing then
        lh, ly, drag_prev = H_START, 0, nil; set_size(); playing = true; serve(-1); hud()
      end
    end,
    update = function(dt, hw, hh)
      HW, HH = hw, hh
      if not built then build(hw, hh) end
      if not playing then return end
      dt = math.min(dt, MAX_DT)
      local lx, rx = -hw + MARGIN, hw - MARGIN
      local plim = math.max(0, hh - lh * 0.5); local ailim = hh - AI_H * 0.5
      move_player(dt, plim)
      if not (wait > 0) and math.abs(by - ry) > AI_DEADZONE then
        ry = clamp(ry + clamp(by - ry, -AI_SPEED * dt, AI_SPEED * dt), -ailim, ailim)
      end
      if wait > 0 then wait = wait - dt; if wait <= 0 then launch() end
      else
        local ox = bx; bx = bx + bvx * dt; by = by + bvy * dt
        local top = hh - BALL * 0.5
        if by > top then by = top; bvy = -math.abs(bvy); game.play_sound("wall"); game.shake(0.04) end
        if by < -top then by = -top; bvy = math.abs(bvy); game.play_sound("wall"); game.shake(0.04) end
        local lhalf = lh * 0.5
        local lf = lx + PADDLE_W * 0.5 + BALL * 0.5
        local rf = rx - PADDLE_W * 0.5 - BALL * 0.5
        if bvx < 0 and ox >= lf and bx <= lf and math.abs(by - ly) <= lhalf + BALL * 0.5 then
          rebound(ly, lf, 1, lhalf)
          if ball_good then l_flash, l_col = 1, GOOD_C; game.play_sound("hit"); game.haptic("success"); game.shake(0.12); grow()
          else l_flash, l_col = 1, BAD_C; game.play_sound("hit"); game.haptic("heavy"); game.shake(0.28); shrink() end
        elseif bvx > 0 and ox <= rf and bx >= rf and math.abs(by - ry) <= AI_H * 0.5 + BALL * 0.5 then
          rebound(ry, rf, -1, AI_H * 0.5); r_flash = 1; game.play_sound("wall"); roll()
        end
        if playing and bx < -hw then
          if ball_good then game.play_sound("hit"); shrink() else game.play_sound("wall") end
          if playing then serve(-1) end
        elseif playing and bx > hw then serve(-1) end
      end
      if not (wait > 0) then
        tcur = (tcur % TRAIL_N) + 1; trail[tcur].a = 0.5; game.move_to(trail[tcur].id, bx, by)
      end
      for i = 1, TRAIL_N do local t = trail[i]
        if t.a > 0.001 then t.a = t.a * 0.86; game.set_color(t.id, 0.75, 0.85, 1.0, t.a) end
      end
      l_flash = math.max(0, l_flash - dt * 4); r_flash = math.max(0, r_flash - dt * 4)
      local lr, lg, lb = blend(BASE_L, l_col, l_flash)
      local rr, rg, rb = blend(BASE_R, { 1, 1, 1 }, r_flash)
      game.set_color(left, lr, lg, lb, 1); game.set_color(right, rr, rg, rb, 1)
      game.move_to(left, lx, ly); game.move_to(right, rx, ry); game.move_to(ball, bx, by)
    end,
  }
end

-- ===================================================================
-- Game 2: Breakout (Bevy example port)
-- ===================================================================
local function make_breakout()
  local T = tracker()
  local PADDLE_W, PADDLE_H, BALL = 130, 18, 16
  local SPEED, MAXV, DRAG_SENS, PADDLE_SPEED = 320, 560, 1.4, 900
  local ROWS, COLS, BRICK_H, GAP, SIDE = 6, 8, 26, 8, 26
  local MAX_DT, START_LIVES = 1 / 30, 3
  local ROW_C = {
    { 0.90, 0.30, 0.30 }, { 0.95, 0.55, 0.25 }, { 0.95, 0.85, 0.30 },
    { 0.35, 0.80, 0.40 }, { 0.35, 0.65, 0.95 }, { 0.65, 0.45, 0.90 },
  }
  local paddle, ball, back
  local px, bx, by, bvx, bvy = 0, 0, 0, 0, 0
  local bricks, alive_count = {}, 0
  local lives, playing, launched, drag_prev = START_LIVES, true, false, nil
  local built, HW, HH, py = false, 0, 0, 0

  local function hud()
    game.set_text(string.format("BRICKS %d   LIVES %d", alive_count, lives))
  end
  local function serve() bx, by = px, py + PADDLE_H * 0.5 + BALL; bvx, bvy = 0, 0; launched = false end
  local function build(hw, hh)
    HW, HH = hw, hh
    py = -hh + 70
    local area = 2 * hw - 2 * SIDE
    local bw = (area - (COLS - 1) * GAP) / COLS
    local top = hh - 130
    bricks, alive_count = {}, 0
    for r = 1, ROWS do
      for c = 1, COLS do
        local x = -hw + SIDE + bw * 0.5 + (c - 1) * (bw + GAP)
        local y = top - (r - 1) * (BRICK_H + GAP)
        local col = ROW_C[r]
        local id = T.sprite(x, y, bw, BRICK_H, "brick")
        game.set_color(id, col[1], col[2], col[3], 1)
        bricks[#bricks + 1] = { id = id, x = x, y = y, w = bw, h = BRICK_H, alive = true }
        alive_count = alive_count + 1
      end
    end
    paddle = T.sprite(0, py, PADDLE_W, PADDLE_H, "paddle")
    game.set_color(paddle, 0.85, 0.9, 1.0, 1)
    ball = T.sprite(0, 0, BALL, BALL, "orb")
    back = make_back(T, hw, hh)
    px, lives, playing = 0, START_LIVES, true
    serve(); hud(); built = true
    DEBUG = { game = "breakout", ball = ball, paddle = paddle, back = back,
      bricks = function() return alive_count end, alive = function() return playing end }
  end
  local function move_paddle(dt)
    local px0, _, down = game.pointer(); local lim = HW - PADDLE_W * 0.5; local mx = PADDLE_SPEED * dt
    if down and px0 ~= nil then
      if drag_prev ~= nil then px = clamp(px + clamp((px0 - drag_prev) * DRAG_SENS, -mx, mx), -lim, lim) end
      drag_prev = px0
    else
      drag_prev = nil; local vx = 0
      if game.key("left") or game.key("a") then vx = vx - PADDLE_SPEED end
      if game.key("right") or game.key("d") then vx = vx + PADDLE_SPEED end
      px = clamp(px + vx * dt, -lim, lim)
    end
  end

  return {
    enter = function() built = false end,
    leave = function() T.clear(); built = false end,
    tap = function(x, y)
      if back and in_rect(back, x, y) then switch("menu"); return end
      if not playing then T.clear(); build(HW, HH); return end   -- rebuild the round
      if not launched then launched = true
        bvx = SPEED * 0.35 * (math.random() < 0.5 and -1 or 1); bvy = SPEED
      end
    end,
    update = function(dt, hw, hh)
      HW, HH = hw, hh
      if not built then build(hw, hh) end
      if not playing then return end
      dt = math.min(dt, MAX_DT)
      move_paddle(dt)
      if not launched then bx, by = px, py + PADDLE_H * 0.5 + BALL
      else
        bx = bx + bvx * dt; by = by + bvy * dt
        if bx < -hw + BALL * 0.5 then bx = -hw + BALL * 0.5; bvx = math.abs(bvx); game.play_sound("wall") end
        if bx > hw - BALL * 0.5 then bx = hw - BALL * 0.5; bvx = -math.abs(bvx); game.play_sound("wall") end
        if by > hh - BALL * 0.5 then by = hh - BALL * 0.5; bvy = -math.abs(bvy); game.play_sound("wall") end
        -- paddle
        if bvy < 0 and math.abs(bx - px) <= (PADDLE_W + BALL) * 0.5
           and math.abs(by - py) <= (PADDLE_H + BALL) * 0.5 then
          by = py + (PADDLE_H + BALL) * 0.5
          local off = clamp((bx - px) / (PADDLE_W * 0.5), -1, 1)
          local a = off * 1.0
          local s = math.min(math.sqrt(bvx * bvx + bvy * bvy) * 1.02, MAXV)
          bvx = s * math.sin(a); bvy = s * math.cos(a)
          game.play_sound("hit"); game.haptic("light"); game.shake(0.06)
        end
        -- bricks (resolve one per frame)
        for _, b in ipairs(bricks) do
          if b.alive and math.abs(bx - b.x) <= (b.w + BALL) * 0.5
             and math.abs(by - b.y) <= (b.h + BALL) * 0.5 then
            local ox = (b.w + BALL) * 0.5 - math.abs(bx - b.x)
            local oy = (b.h + BALL) * 0.5 - math.abs(by - b.y)
            if ox < oy then bvx = -bvx else bvy = -bvy end
            b.alive = false; game.despawn(b.id); alive_count = alive_count - 1
            game.play_sound("hit"); game.haptic("light"); game.shake(0.08); hud()
            if alive_count <= 0 then
              playing = false; game.set_text("YOU WIN!\nTap to restart")
              game.play_sound("score"); game.haptic("success"); game.shake(0.6); game.log("win")
            end
            break
          end
        end
        if playing and by < -hh - BALL then
          lives = lives - 1; game.haptic("heavy"); game.shake(0.4)
          if lives <= 0 then
            playing = false; game.set_text("GAME OVER\nTap to restart"); game.play_sound("hit"); game.log("lose")
          else game.play_sound("wall"); serve(); hud() end
        end
      end
      game.move_to(paddle, px, py); game.move_to(ball, bx, by)
    end,
  }
end

-- ===================================================================
-- Game 3: Snake
-- ===================================================================
local function make_snake()
  local T = tracker()
  local CELL, TICK = 34, 0.13
  local back, food_id, head_id
  local cols, rows, ox, oy = 0, 0, 0, 0
  local snake, dir, ndir, grow_by = {}, { 1, 0 }, { 1, 0 }, 0
  local food = { c = 0, r = 0 }
  local segs = {}
  local acc, playing, drag_prev, built = 0, true, nil, false
  local HW, HH, score = 0, 0, 0

  local function cell_xy(c, r) return ox + (c + 0.5) * CELL, oy + (r + 0.5) * CELL end
  local function occupied(c, r)
    for _, s in ipairs(snake) do if s.c == c and s.r == r then return true end end
    return false
  end
  local function place_food()
    for _ = 1, 200 do
      local c, r = math.random(0, cols - 1), math.random(0, rows - 1)
      if not occupied(c, r) then food.c, food.r = c, r; break end
    end
    game.move_to(food_id, cell_xy(food.c, food.r))
  end
  local function hud() game.set_text(string.format("LEN %d", #snake)) end
  local function render()
    game.move_to(head_id, cell_xy(snake[1].c, snake[1].r))
    local need = #snake - 1                    -- body segments (all but the head)
    for i = 2, #snake do
      local bi = i - 1
      if not segs[bi] then segs[bi] = T.sprite(0, 0, CELL - 4, CELL - 4, "snakebody") end
      game.move_to(segs[bi], cell_xy(snake[i].c, snake[i].r))
      game.set_color(segs[bi], 1, 1, 1, 1)
    end
    for bi = need + 1, #segs do game.set_color(segs[bi], 1, 1, 1, 0) end  -- hide extras
  end
  local function die()
    playing = false; game.set_text(string.format("GAME OVER\nLEN %d\nTap to restart", #snake))
    game.play_sound("hit"); game.haptic("heavy"); game.shake(0.5); game.log("lose")
  end
  local function reset()
    snake = {}
    local cc, cr = math.floor(cols / 2), math.floor(rows / 2)
    for i = 0, 2 do snake[i + 1] = { c = cc - i, r = cr } end
    dir, ndir, grow_by, score, acc, playing = { 1, 0 }, { 1, 0 }, 0, 0, 0, true
    place_food(); render(); hud()
  end
  local function build(hw, hh)
    HW, HH = hw, hh
    cols = math.floor(2 * hw / CELL); rows = math.floor(2 * hh / CELL)
    ox = -cols * CELL * 0.5; oy = -rows * CELL * 0.5
    food_id = T.sprite(0, 0, CELL - 4, CELL - 4, "food")
    head_id = T.sprite(0, 0, CELL - 4, CELL - 4, "snakehead")
    back = make_back(T, hw, hh)
    reset(); built = true
    DEBUG = { game = "snake", len = function() return #snake end, back = back,
      alive = function() return playing end, head = function() return snake[1] end, food = food }
  end
  local function set_dir(dx, dy)
    if dx ~= 0 and dir[1] == 0 then ndir = { dx, 0 }
    elseif dy ~= 0 and dir[2] == 0 then ndir = { 0, dy } end
  end
  local function step()
    dir = ndir
    local h = snake[1]
    local nc, nr = h.c + dir[1], h.r + dir[2]
    if nc < 0 or nc >= cols or nr < 0 or nr >= rows then die(); return end
    for i = 1, #snake - 1 do if snake[i].c == nc and snake[i].r == nr then die(); return end end
    table.insert(snake, 1, { c = nc, r = nr })
    if nc == food.c and nr == food.r then
      score = score + 1; game.play_sound("hit"); game.haptic("light"); place_food()
    else
      table.remove(snake)
    end
    render(); hud()
  end

  return {
    enter = function() built = false end,
    leave = function() T.clear(); segs = {}; built = false end,
    tap = function(x, y)
      if back and in_rect(back, x, y) then switch("menu"); return end
      if not playing then reset() end
    end,
    update = function(dt, hw, hh)
      if not built then build(hw, hh) end
      if not playing then return end
      -- Direction: drag-swipe (dominant axis) or arrow keys.
      local dpx, dpy, down = game.pointer()
      if down and dpy ~= nil then
        if drag_prev then
          local ddx, ddy = (dpx or drag_prev.x) - drag_prev.x, dpy - drag_prev.y
          if math.abs(ddx) > 12 or math.abs(ddy) > 12 then
            if math.abs(ddx) > math.abs(ddy) then set_dir(sign(ddx), 0) else set_dir(0, sign(ddy)) end
            drag_prev = { x = dpx or drag_prev.x, y = dpy }
          end
        else drag_prev = { x = dpx or 0, y = dpy } end
      else drag_prev = nil end
      if game.key("left") or game.key("a") then set_dir(-1, 0) end
      if game.key("right") or game.key("d") then set_dir(1, 0) end
      if game.key("up") or game.key("w") then set_dir(0, 1) end
      if game.key("down") or game.key("s") then set_dir(0, -1) end
      acc = acc + math.min(dt, 0.1)
      while playing and acc >= TICK do acc = acc - TICK; step() end
    end,
  }
end

-- ===================================================================
-- Menu
-- ===================================================================
local function make_menu()
  local T = tracker()
  local tiles, built = {}, false
  return {
    enter = function() built = false; game.set_text(""); game.set_bg_theme(0) end,
    leave = function() T.clear(); tiles = {} end,
    update = function(_, hw, hh)
      if built then return end
      game.set_text("")
      T.text(0, hh - 92, 46, 1, 1, 1, 1, "MINI GAMES")
      T.text(0, hh - 140, 20, 0.7, 0.8, 1.0, 1, "Tap a game to play")

      -- Grid of game tiles + a Settings tile (icons make them scannable).
      local grid = {}
      for _, item in ipairs(order) do grid[#grid + 1] = item end
      grid[#grid + 1] = { key = "settings", short = "Settings", color = { 0.5, 0.55, 0.62 }, icon = nil }

      local cols, gap, side = 3, 18, 26
      local tw = math.min((2 * hw - 2 * side - (cols - 1) * gap) / cols, 150)
      local th = tw * 1.06
      local rows = math.ceil(#grid / cols)
      local top = (rows * th + (rows - 1) * gap) * 0.5 - th * 0.5   -- grid center at y=0
      tiles = {}
      for i, item in ipairs(grid) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local x = -(cols - 1) * (tw + gap) * 0.5 + col * (tw + gap)
        local y = top - row * (th + gap)
        local c = item.color
        T.spawn(x, y, tw, th, c[1], c[2], c[3], 1)
        if item.icon then T.sprite(x, y + th * 0.14, tw * 0.5, tw * 0.5, item.icon) end
        T.text(x, y - th * 0.34, 18, 1, 1, 1, 1, item.short or item.label)
        -- tier badge (top-left corner) so preset / curated / AI packs are distinct
        if item.tier == "curated" then
          T.text(x - tw * 0.36, y + th * 0.36, 18, 1, 0.9, 0.4, 1, "*")
        elseif item.tier == "ai" then
          T.text(x - tw * 0.32, y + th * 0.36, 13, 0.6, 0.9, 1.0, 1, "AI")
        end
        tiles[#tiles + 1] = { x = x, y = y, w = tw, h = th, key = item.key }
      end
      built = true
      DEBUG = { game = "menu", tiles = tiles }
    end,
    tap = function(x, y)
      for _, t in ipairs(tiles) do
        if in_rect(t, x, y) then
          game.play_sound("hit"); game.haptic("light"); switch(t.key); return
        end
      end
    end,
  }
end

-- Settings screen: toggle the HUD on/off (games read SETTINGS.hud).
local function make_settings()
  local T = tracker()
  local built, back, toggle = false, nil, nil
  local function label() return "HUD: " .. (SETTINGS.hud and "ON" or "OFF") end
  local function draw()
    T.clear()
    T.text(0, 260, 40, 1, 1, 1, 1, "SETTINGS")
    local c = SETTINGS.hud and { 0.30, 0.70, 0.45 } or { 0.55, 0.35, 0.35 }
    toggle = { x = 0, y = 80, w = 320, h = 92 }
    T.spawn(toggle.x, toggle.y, toggle.w, toggle.h, c[1], c[2], c[3], 1)
    T.text(toggle.x, toggle.y, 34, 1, 1, 1, 1, label())
    T.text(0, -20, 20, 0.75, 0.8, 0.9, 1, "Tap to toggle the on-screen HUD")
    back = make_back(T, HW_S, HH_S)
    DEBUG = { game = "settings", back = back, toggle = toggle,
      hud = function() return SETTINGS.hud end }
  end
  return {
    enter = function() built = false; game.set_text(""); game.set_bg_theme(0) end,
    leave = function() T.clear() end,
    update = function(_, hw, hh)
      HW_S, HH_S = hw, hh
      if not built then draw(); built = true end
    end,
    tap = function(x, y)
      if back and in_rect(back, x, y) then switch("menu"); return end
      if toggle and in_rect(toggle, x, y) then
        SETTINGS.hud = not SETTINGS.hud
        game.play_sound("hit"); game.haptic("light"); draw()
      end
    end,
  }
end

-- ===================================================================
-- Router lifecycle
-- ===================================================================
-- Data-driven, self-registering game packs. Any .lua loaded before main.lua can
-- append itself to the global PACKS (keyed by `key`, so a desktop hot-reload that
-- re-runs every script overwrites rather than duplicates). The three core games
-- below register the same way. The menu is then built purely from PACKS, sorted
-- by tier (preset -> curated -> ai) then slot — so publishing a new game is just
-- dropping a pack file, no edits here. This is the dynamic game-pack mechanism.
function on_start()
  game.log("Mini-game collection — started")
  game.play_music("music")
  scenes.menu = make_menu()
  scenes.settings = make_settings()

  PACKS = PACKS or {}
  PACKS.grow = { slot = 1, key = "grow", label = "Grow Paddle", short = "Grow", icon = "orb", color = { 0.30, 0.62, 1.0 }, tier = "preset", make = make_grow }
  PACKS.breakout = { slot = 2, key = "breakout", label = "Breakout", short = "Breakout", icon = "brick", color = { 1.0, 0.55, 0.25 }, tier = "preset", make = make_breakout }
  PACKS.snake = { slot = 3, key = "snake", label = "Snake", short = "Snake", icon = "snakehead", color = { 0.35, 0.82, 0.45 }, tier = "preset", make = make_snake }

  local prio = { preset = 1, curated = 2, ai = 3 }
  local list = {}
  for _, g in pairs(PACKS) do list[#list + 1] = g end
  table.sort(list, function(a, b)
    local pa, pb = prio[a.tier or "preset"] or 9, prio[b.tier or "preset"] or 9
    if pa ~= pb then return pa < pb end
    local sa, sb = a.slot or 99, b.slot or 99
    if sa ~= sb then return sa < sb end
    return (a.key or "") < (b.key or "")   -- stable order on slot ties

  end)
  order = {}
  for _, g in ipairs(list) do
    local ok, scene = pcall(g.make)          -- a bad AI pack can't crash the menu
    if ok and scene then
      scenes[g.key] = scene
      order[#order + 1] = g
    else
      game.log("pack '" .. tostring(g.key) .. "' failed to build; skipped")
    end
  end
  booted = false
end

function on_update(dt)
  local hw, hh = game.bounds()
  if hw <= 0 then return end
  if not booted then switch(AUTOBOOT or "menu"); booted = true end
  if current and current.update then current.update(dt, hw, hh) end
  if not SETTINGS.hud then game.set_text("") end   -- global HUD toggle (Settings)
end

function on_tap(x, y)
  if current and current.tap then current.tap(x, y) end
end
