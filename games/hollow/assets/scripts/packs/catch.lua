-- catch.lua — "FRUIT CATCH": drag a basket along the bottom to catch fruit
-- falling from the top. Miss a fruit and you lose a life; 3 misses and it's over.
-- Registers the global factory make_catch (main.lua builds the menu from PACKS).
-- Talks to the host ONLY through the `game` bridge + shared GAME_KIT helpers.

function make_catch()
  local K = GAME_KIT
  local clamp, inr = K.clamp, K.in_rect
  local T = K.tracker()

  local FRUITS = { "gberry", "food", "gdaisy", "gmush", "gem" }
  local BASKET_W, BASKET_H = 120, 60
  local FRUIT_SIZE = 52
  local SPAWN_EVERY = 0.8
  local BASE_SPEED = 220     -- px/s at score 0
  local SPEED_PER_SCORE = 8  -- extra fall speed per point
  local BASKET_Y_MARGIN = 90 -- basket centre above the bottom edge

  local back, playing, built = nil, true, false
  local score, lives = 0, 3
  local basket = nil          -- sprite id of the basket
  local basket_x, basket_y = 0, 0
  local fruits = {}           -- { id, x, y, speed } falling fruit
  local spawn_timer = 0
  local screen_hw, screen_hh = 0, 0

  local function hud()
    game.set_text(string.format("SCORE %d   LIVES %d", score, lives))
  end

  local function fall_speed()
    return BASE_SPEED + score * SPEED_PER_SCORE
  end

  -- Spawn a fruit at the given x near the top (clamped inside the play field).
  local function spawn_fruit_at(x)
    local hw = screen_hw > 0 and screen_hw or 300
    local hh = screen_hh > 0 and screen_hh or 400
    local half = FRUIT_SIZE * 0.5
    x = clamp(x, -hw + half, hw - half)
    local y = hh - half - 8
    local tex = FRUITS[math.random(1, #FRUITS)]
    local id = game.spawn_sprite(x, y, FRUIT_SIZE, FRUIT_SIZE, tex)
    fruits[#fruits + 1] = { id = id, x = x, y = y, speed = fall_speed() }
  end

  local function clear_fruits()
    for _, f in ipairs(fruits) do game.despawn(f.id) end
    fruits = {}
  end

  local function game_over()
    playing = false
    game.set_text(string.format("GAME OVER\nSCORE %d\nTap to restart", score))
    game.play_sound("hit"); game.haptic("heavy"); game.shake(0.4)
  end

  local function build(hw, hh)
    screen_hw, screen_hh = hw, hh
    basket_x = 0
    basket_y = -hh + BASKET_Y_MARGIN
    basket = T.sprite(basket_x, basket_y, BASKET_W, BASKET_H, "paddle")
    game.set_color(basket, 0.85, 0.55, 0.30, 1) -- warm woven-basket tint
    back = K.make_back(T, hw, hh)
    score, lives, playing = 0, 3, true
    spawn_timer = 0
    clear_fruits()
    hud()
    built = true
    DEBUG = {
      game = "catch", back = back, basket = basket,
      score = function() return score end,
      lives = function() return lives end,
      alive = function() return playing end,
      spawn_fruit_at = function(x) spawn_fruit_at(x or 0) end,
      fruit_count = function() return #fruits end,
    }
  end

  local function restart()
    clear_fruits(); T.clear(); built = false
    build(game.bounds())
  end

  return {
    enter = function() built = false end,
    leave = function() clear_fruits(); T.clear(); built = false end,
    tap = function(x, y)
      if back and inr(back, x, y) then K.switch("menu"); return end
      if not playing then restart(); return end
    end,
    update = function(dt, hw, hh)
      if not built then build(hw, hh) end
      screen_hw, screen_hh = hw, hh
      if dt > 1 / 30 then dt = 1 / 30 end -- cap dt so a hitch never teleports things
      if not playing then return end

      -- Move basket toward pointer (when held) or via keyboard; clamp to screen.
      local half = BASKET_W * 0.5
      local px, _, down = game.pointer()
      if down and px ~= nil then
        -- ease toward the finger so drags feel smooth but responsive
        basket_x = basket_x + (px - basket_x) * math.min(1, dt * 18)
      end
      local dir = 0
      if game.key("left") then dir = dir - 1 end
      if game.key("right") then dir = dir + 1 end
      if dir ~= 0 then basket_x = basket_x + dir * 520 * dt end
      basket_x = clamp(basket_x, -hw + half, hw - half)
      basket_y = -hh + BASKET_Y_MARGIN
      game.move_to(basket, basket_x, basket_y)

      -- Spawn fruit on a timer.
      spawn_timer = spawn_timer + dt
      if spawn_timer >= SPAWN_EVERY then
        spawn_timer = spawn_timer - SPAWN_EVERY
        spawn_fruit_at(math.random(-hw + FRUIT_SIZE, hw - FRUIT_SIZE))
      end

      -- Advance fruit; catch on overlap, miss below the bottom edge.
      local catch_rect = { x = basket_x, y = basket_y,
                           w = BASKET_W + FRUIT_SIZE * 0.5, h = BASKET_H + FRUIT_SIZE }
      local kept = {}
      for _, f in ipairs(fruits) do
        f.y = f.y - f.speed * dt
        local removed = false
        if inr(catch_rect, f.x, f.y) then
          score = score + 1
          game.despawn(f.id)
          game.play_sound("hit"); game.haptic("light"); game.shake(0.12)
          hud()
          removed = true
        elseif f.y < -hh - FRUIT_SIZE then
          lives = lives - 1
          game.despawn(f.id)
          game.play_sound("wall"); game.haptic("medium")
          hud()
          removed = true
          if lives <= 0 then
            -- drop the remaining fruit and end the round
            for _, g in ipairs(kept) do game.despawn(g.id) end
            fruits = {}
            game_over()
            return
          end
        end
        if not removed then
          game.move_to(f.id, f.x, f.y)
          kept[#kept + 1] = f
        end
      end
      fruits = kept
    end,
  }
end

-- Self-register this game pack (see main.lua: the menu builds from PACKS).
PACKS = PACKS or {}
PACKS["catch"] = { slot = 20, key = "catch", label = "Fruit Catch", short = "Catch", icon = "gberry", color = { 0.85, 0.45, 0.35 }, tier = "ai", make = make_catch }
