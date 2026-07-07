-- shooter.lua — a retro arcade space shooter (Galaga/Invaders style).
--
-- Registers the global factory make_shooter (main.lua adds it to the menu).
-- Drag to move your ship; it auto-fires. Clear the glowing alien formation that
-- sways and descends and drops bombs. Lose all lives = game over. Its own file;
-- uses GAME_KIT + the `game` bridge. Art: ship/alien/shot textures.

function make_shooter()
  local K = GAME_KIT
  local clamp, inr = K.clamp, K.in_rect
  local T = K.tracker()

  local SHIP_W, ALIEN, BW, BH, BOMB = 42, 34, 10, 26, 14
  local COLS, ROWS = 5, 4
  local FIRE_INT, BOMB_INT = 0.36, 1.1
  local BULLET_SPEED, BOMB_SPEED = 560, 250
  local DRAG_SENS, SHIP_SPEED, MAX_DT = 2.6, 900, 1 / 30
  local START_LIVES, STARS = 3, 34
  local DROP = 22

  local back, ship
  local px, ship_y = 0, 0
  local aliens, bullets, bombs, stars = {}, {}, {}, {}
  local basex, basey = {}, {}
  local sx, sy = 70, 52
  local blockx, blocky, bdir = 0, 0, 1
  local fire_t, bomb_t, wave = 0, 0, 1
  local score, hi, lives, playing, built = 0, 0, START_LIVES, true, false
  local drag_prev, HW, HH = nil, 0, 0

  local function hud()
    game.set_text(string.format("SCORE %d    HI %d    LIVES %d", score, math.max(hi, score), lives))
  end

  local function alive_count()
    local n = 0
    for _, a in ipairs(aliens) do if a.alive then n = n + 1 end end
    return n
  end

  local function spawn_wave()
    for _, a in ipairs(aliens) do game.despawn(a.id) end
    aliens = {}
    sx = math.min((2 * HW - 60) / COLS, 74)
    local top = HH - 150
    for c = 1, COLS do basex[c] = (c - (COLS + 1) / 2) * sx end
    for r = 1, ROWS do basey[r] = top - (r - 1) * sy end
    for r = 1, ROWS do
      for c = 1, COLS do
        local id = game.spawn_sprite(basex[c], basey[r], ALIEN, ALIEN, "alien")
        aliens[#aliens + 1] = { id = id, c = c, r = r, alive = true }
      end
    end
    blockx, blocky, bdir = 0, 0, 1
  end

  local function reset()
    for _, b in ipairs(bullets) do game.despawn(b.id) end
    for _, b in ipairs(bombs) do game.despawn(b.id) end
    bullets, bombs = {}, {}
    px, ship_y = 0, -HH + 70
    score, lives, wave, playing = 0, START_LIVES, 1, true
    fire_t, bomb_t = 0, 0
    spawn_wave(); hud()
  end

  local function build(hw, hh)
    HW, HH = hw, hh
    T.spawn(0, 0, 2 * hw, 2 * hh, 0.02, 0.02, 0.06, 1)     -- deep-space backdrop
    stars = {}
    for i = 1, STARS do
      local b = 0.3 + (i % 7) / 10
      local id = T.spawn((i * 137 % 100 / 100 * 2 - 1) * hw, (i * 89 % 100 / 100 * 2 - 1) * hh,
        2 + i % 2, 2 + i % 2, b, b, b + 0.1, b)
      stars[i] = { id = id, x = 0, y = 0, sp = 20 + (i % 5) * 14, b = b }
      stars[i].x = (i * 137 % 1000 / 1000 * 2 - 1) * hw
      stars[i].y = (i * 271 % 1000 / 1000 * 2 - 1) * hh
    end
    ship = T.sprite(0, -hh + 70, SHIP_W, SHIP_W, "ship")
    back = K.make_back(T, hw, hh)
    reset(); built = true
    DEBUG = { game = "shooter", back = back, ship = ship,
      score = function() return score end, lives = function() return lives end,
      aliens = function() return alive_count() end, alive = function() return playing end }
  end

  local function move_ship(dt)
    local dpx, _, down = game.pointer()
    local lim = HW - SHIP_W * 0.5
    if down and dpx ~= nil then
      if drag_prev then px = clamp(px + clamp((dpx - drag_prev) * DRAG_SENS, -SHIP_SPEED * dt, SHIP_SPEED * dt), -lim, lim) end
      drag_prev = dpx
    else
      drag_prev = nil
      local v = 0
      if game.key("left") or game.key("a") then v = v - SHIP_SPEED end
      if game.key("right") or game.key("d") then v = v + SHIP_SPEED end
      px = clamp(px + v * dt, -lim, lim)
    end
  end

  local function alien_xy(a)
    return basex[a.c] + blockx, basey[a.r] - blocky
  end

  local function over()
    playing = false; hi = math.max(hi, score)
    game.set_text(string.format("GAME OVER\nSCORE %d   HI %d\nTap to restart", score, hi))
    game.play_sound("hit"); game.haptic("heavy"); game.shake(0.6); game.log("lose")
  end

  return {
    enter = function() built = false end,
    leave = function()
      for _, b in ipairs(bullets) do game.despawn(b.id) end
      for _, b in ipairs(bombs) do game.despawn(b.id) end
      for _, a in ipairs(aliens) do game.despawn(a.id) end
      bullets, bombs, aliens = {}, {}, {}
      T.clear(); built = false
    end,
    tap = function(x, y)
      if back and inr(back, x, y) then K.switch("menu"); return end
      if not playing then reset() end
    end,
    update = function(dt, hw, hh)
      HW, HH = hw, hh
      if not built then build(hw, hh) end
      dt = math.min(dt, MAX_DT)

      -- Starfield drifts down always (ambience), wrapping.
      for _, s in ipairs(stars) do
        s.y = s.y - s.sp * dt
        if s.y < -hh then s.y = hh; s.x = ((s.id * 53) % 1000 / 1000 * 2 - 1) * hw end
        game.move_to(s.id, s.x, s.y)
      end
      if not playing then return end

      move_ship(dt)
      ship_y = -hh + 70
      game.move_to(ship, px, ship_y)

      -- Alien block: sway + drop at edges.
      local speed = 42 + (COLS * ROWS - alive_count()) * 7 + (wave - 1) * 20
      blockx = blockx + bdir * speed * dt
      local minx, maxx, lowest = 1e9, -1e9, 1e9
      for _, a in ipairs(aliens) do
        if a.alive then
          local ax, ay = alien_xy(a)
          if ax < minx then minx = ax end
          if ax > maxx then maxx = ax end
          if ay < lowest then lowest = ay end
        end
      end
      if maxx > hw - ALIEN * 0.5 then bdir = -1; blocky = blocky + DROP end
      if minx < -hw + ALIEN * 0.5 then bdir = 1; blocky = blocky + DROP end
      for _, a in ipairs(aliens) do
        if a.alive then game.move_to(a.id, alien_xy(a)) end
      end
      if lowest <= ship_y + ALIEN then over(); return end

      -- Auto-fire.
      fire_t = fire_t + dt
      while fire_t >= FIRE_INT do
        fire_t = fire_t - FIRE_INT
        bullets[#bullets + 1] = { id = game.spawn_sprite(px, ship_y + 30, BW, BH, "shot"), x = px, y = ship_y + 30 }
        game.play_sound("wall")
      end

      -- Bombs from a random alive alien.
      bomb_t = bomb_t + dt
      if bomb_t >= BOMB_INT then
        bomb_t = bomb_t - BOMB_INT
        local pick = {}
        for _, a in ipairs(aliens) do if a.alive then pick[#pick + 1] = a end end
        if #pick > 0 then
          local a = pick[math.random(1, #pick)]
          local ax, ay = alien_xy(a)
          local id = game.spawn_sprite(ax, ay, BOMB, BOMB, "orb")
          game.set_color(id, 1.0, 0.4, 0.2, 1)
          bombs[#bombs + 1] = { id = id, x = ax, y = ay }
        end
      end

      -- Bullets up + hit aliens.
      for bi = #bullets, 1, -1 do
        local b = bullets[bi]
        b.y = b.y + BULLET_SPEED * dt
        local hit = false
        for _, a in ipairs(aliens) do
          if a.alive then
            local ax, ay = alien_xy(a)
            if math.abs(b.x - ax) < (ALIEN + BW) * 0.5 and math.abs(b.y - ay) < (ALIEN + BH) * 0.5 then
              a.alive = false; game.despawn(a.id); hit = true
              score = score + (ROWS - a.r + 1) * 10
              game.play_sound("hit"); game.haptic("light"); game.shake(0.08); hud()
              break
            end
          end
        end
        if hit or b.y > hh then game.despawn(b.id); table.remove(bullets, bi)
        else game.move_to(b.id, b.x, b.y) end
      end

      -- Bombs down + hit ship.
      for bi = #bombs, 1, -1 do
        local b = bombs[bi]
        b.y = b.y - BOMB_SPEED * dt
        if math.abs(b.x - px) < (SHIP_W + BOMB) * 0.45 and math.abs(b.y - ship_y) < (SHIP_W + BOMB) * 0.45 then
          game.despawn(b.id); table.remove(bombs, bi)
          lives = lives - 1; game.play_sound("hit"); game.haptic("heavy"); game.shake(0.3); hud()
          if lives <= 0 then over(); return end
        elseif b.y < -hh then game.despawn(b.id); table.remove(bombs, bi)
        else game.move_to(b.id, b.x, b.y) end
      end

      -- Wave cleared.
      if alive_count() == 0 then
        wave = wave + 1; score = score + 100
        game.play_sound("score"); game.haptic("success"); hud(); spawn_wave()
      end
    end,
  }
end

-- Self-register this game pack (see main.lua: menu builds from PACKS).
PACKS = PACKS or {}
PACKS["shooter"] = { slot = 6, key = "shooter", label = "Space Shooter", short = "Shooter", icon = "ship", color = { 0.25, 0.55, 0.75 }, tier = "curated", make = make_shooter }
