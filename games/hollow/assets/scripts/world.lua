-- world.lua — "Cozy Isle", an Animal-Crossing-like sandbox.
--
-- Registers the global factory make_world (main.lua adds it to the menu). Hold
-- to walk your villager around a grassy world; stand near a tree/rock/flower and
-- tap PICK to gather wood/stone/flowers; tap BUILD to pick a recipe, then PICK
-- (now "PLACE") to craft & drop a decoration — combine resources to build up the
-- world. Its own file; uses GAME_KIT + the `game` bridge. Art in assets/textures
-- (villager/tree/rock/flower + decor_* sprites) — AI-generated, swappable.

function make_world()
  local K = GAME_KIT
  local clamp, inr = K.clamp, K.in_rect
  local T = K.tracker()

  local VSPEED, GATHER = 230, 130   -- generous reach so PICK feels responsive
  local TREES = { { -0.7, 0.35 }, { 0.7, 0.42 }, { -0.85, -0.1 }, { 0.78, -0.28 }, { -0.1, 0.6 } }
  local ROCKS = { { -0.42, -0.42 }, { 0.55, 0.12 }, { -0.72, 0.62 } }
  local FLOWERS = { { -0.28, 0.1 }, { 0.28, -0.12 }, { 0.1, 0.36 }, { -0.55, -0.25 }, { 0.45, -0.45 }, { -0.15, -0.55 } }
  -- tex/pw/ph select the decoration sprite dropped when the recipe is placed.
  local RECIPES = {
    { name = "FENCE", w = 2, s = 0, f = 0, tex = "decor_fence", pw = 42, ph = 30 },
    { name = "LAMP", w = 1, s = 1, f = 0, tex = "decor_lamp", pw = 42, ph = 48 },
    { name = "PATH", w = 0, s = 2, f = 0, tex = "decor_path", pw = 42, ph = 30 },
    { name = "BENCH", w = 2, s = 1, f = 0, tex = "decor_bench", pw = 48, ph = 34 },
    { name = "FLOWERBED", w = 0, s = 0, f = 3, tex = "decor_flowerbed", pw = 44, ph = 30 },
  }

  local trees, rocks, flowers, placed = {}, {}, {}, {}
  local villager, vx, vy = nil, 0, 0
  local inv = { wood = 0, stone = 0, flower = 0 }
  local recipe_i, built, HW, HH = 0, false, 0, 0
  local b_back, b_build, b_act

  local function hud()
    local sel = "- gather -"
    if recipe_i > 0 then
      local r = RECIPES[recipe_i]
      local c = {}
      if r.w > 0 then c[#c + 1] = r.w .. "W" end
      if r.s > 0 then c[#c + 1] = r.s .. "S" end
      if r.f > 0 then c[#c + 1] = r.f .. "F" end
      sel = r.name .. " (" .. table.concat(c, "+") .. ")"
    end
    game.set_text(string.format("WOOD %d   STONE %d   FLOWER %d\nBUILD: %s", inv.wood, inv.stone, inv.flower, sel))
  end

  local function build_world(hw, hh)
    HW, HH = hw, hh
    T.spawn(0, 0, 2 * hw, 2 * hh, 0.44, 0.70, 0.40, 1)          -- grassy ground
    trees, rocks, flowers, placed = {}, {}, {}, {}
    for _, p in ipairs(FLOWERS) do
      local x, y = p[1] * hw, p[2] * hh
      flowers[#flowers + 1] = { id = T.sprite(x, y, 30, 30, "flower"), x = x, y = y }
    end
    for _, p in ipairs(ROCKS) do
      local x, y = p[1] * hw, p[2] * hh
      rocks[#rocks + 1] = { id = T.sprite(x, y, 46, 36, "rock"), x = x, y = y }
    end
    for _, p in ipairs(TREES) do
      local x, y = p[1] * hw, p[2] * hh
      trees[#trees + 1] = { id = T.sprite(x, y, 68, 88, "tree"), x = x, y = y }
    end
    villager = T.sprite(0, 0, 46, 42, "villager")
    b_back = K.make_back(T, hw, hh)
    b_build = { x = -hw + 96, y = -hh + 62, w = 168, h = 68 }
    b_act = { x = hw - 96, y = -hh + 62, w = 168, h = 68 }
    T.spawn(b_build.x, b_build.y, b_build.w, b_build.h, 0.30, 0.40, 0.62, 0.92)
    T.text(b_build.x, b_build.y, 28, 1, 1, 1, 1, "BUILD")
    T.spawn(b_act.x, b_act.y, b_act.w, b_act.h, 0.28, 0.58, 0.40, 0.92)
    T.text(b_act.x, b_act.y, 26, 1, 1, 1, 1, "PICK / PLACE")
    vx, vy, recipe_i = 0, 0, 0
    hud(); built = true
    DEBUG = {
      game = "world", back = b_back, villager = villager, b_build = b_build, b_act = b_act,
      inv = function() return inv end, recipe = function() return recipe_i end,
      placed = function() return #placed end, trees = trees, rocks = rocks, flowers = flowers,
    }
  end

  local function nearest(list)
    local best, bd
    for _, o in ipairs(list) do
      local d = (o.x - vx) ^ 2 + (o.y - vy) ^ 2
      if not bd or d < bd then bd, best = d, o end
    end
    return best, bd and math.sqrt(bd) or 1e9
  end

  local function do_action()
    if recipe_i > 0 then
      local r = RECIPES[recipe_i]
      if inv.wood >= r.w and inv.stone >= r.s and inv.flower >= r.f then
        inv.wood, inv.stone, inv.flower = inv.wood - r.w, inv.stone - r.s, inv.flower - r.f
        local px, py = vx, vy - 26
        local id = game.spawn_sprite(px, py, r.pw, r.ph, r.tex)
        placed[#placed + 1] = { id = id, x = px, y = py }
        game.play_sound("hit"); game.haptic("light"); game.shake(0.05); hud()
      else
        game.play_sound("wall")
      end
      return
    end
    -- gather: nearest interactable within range
    local t, td = nearest(trees)
    local rk, rd = nearest(rocks)
    local fl, fd = nearest(flowers)
    local best, kind = td, "tree"
    if rd < best then best, kind = rd, "rock" end
    if fd < best then best, kind = fd, "flower" end
    if best > GATHER then game.play_sound("wall"); return end
    if kind == "tree" then inv.wood = inv.wood + 1
    elseif kind == "rock" then inv.stone = inv.stone + 1
    else
      inv.flower = inv.flower + 1
      game.despawn(fl.id)
      for i, o in ipairs(flowers) do if o == fl then table.remove(flowers, i); break end end
    end
    game.play_sound("hit"); game.haptic("light"); game.shake(0.04); hud()
  end

  return {
    enter = function() built = false end,
    leave = function()
      for _, o in ipairs(placed) do game.despawn(o.id) end
      placed = {}; T.clear(); built = false
    end,
    tap = function(x, y)
      if not built then return end
      if inr(b_back, x, y) then K.switch("menu"); return end
      if inr(b_build, x, y) then
        recipe_i = (recipe_i + 1) % (#RECIPES + 1); game.play_sound("wall"); game.haptic("light"); hud(); return
      end
      if inr(b_act, x, y) then do_action(); return end
    end,
    update = function(dt, hw, hh)
      HW, HH = hw, hh
      if not built then build_world(hw, hh) end
      dt = math.min(dt, 1 / 30)
      -- Hold anywhere (not on a button) to walk toward the finger.
      local px, py, down = game.pointer()
      if down and px ~= nil and py ~= nil
         and not (inr(b_build, px, py) or inr(b_act, px, py) or inr(b_back, px, py)) then
        local dx, dy = px - vx, py - vy
        local d = math.sqrt(dx * dx + dy * dy)
        if d > 4 then
          local step = math.min(VSPEED * dt, d)
          vx = clamp(vx + dx / d * step, -hw + 24, hw - 24)
          vy = clamp(vy + dy / d * step, -hh + 24, hh - 24)
        end
      end
      game.move_to(villager, vx, vy)
    end,
  }
end

-- Self-register this game pack (see main.lua: menu builds from PACKS).
PACKS = PACKS or {}
PACKS["world"] = { slot = 7, key = "world", label = "Cozy Isle", short = "Cozy Isle", icon = "villager", color = { 0.45, 0.72, 0.42 }, tier = "curated", make = make_world }
