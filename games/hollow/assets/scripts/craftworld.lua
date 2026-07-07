-- craftworld.lua — "Craft World", phase 1 of the player-created-world sandbox.
--
-- Registers the global factory make_craft (menu builds from PACKS). A grid
-- world you shape yourself: talk to the villager (option dialogue) for a
-- starter kit, gather wood/stone/flowers from nodes at the top (they recharge),
-- pick a block from the palette at the bottom, then tap grid cells to place it
-- (the eraser refunds). The whole layout + inventory persists via game.save,
-- so your world is still there next launch. Uses GAME_KIT + the `game` bridge;
-- all art is existing assets/textures (villager/tree/rock/flower + decor_*).

function make_craft()
  local K = GAME_KIT
  local inr = K.in_rect
  local T = K.tracker()

  local CELL, PAL_H, TOP_RESERVE = 42, 120, 310
  local NODE_CD, GIFT_CD = 8, 45          -- seconds: node regrow / villager gift
  -- Placeable blocks. cost keys are inventory resources; the eraser (last
  -- palette slot) removes a block and refunds its full cost.
  local BLOCKS = {
    { key = "PATH", tex = "decor_path", cost = { stone = 1 } },
    { key = "FENCE", tex = "decor_fence", cost = { wood = 1 } },
    { key = "LAMP", tex = "decor_lamp", cost = { wood = 1, stone = 1 } },
    { key = "FLOWERS", tex = "decor_flowerbed", cost = { flower = 1 } },
    { key = "BENCH", tex = "decor_bench", cost = { wood = 2 } },
  }
  local KITS = {
    { label = "BUILDER  (wood + stone)", grant = { wood = 8, stone = 6 } },
    { label = "GARDENER  (flowers)", grant = { flower = 6, wood = 4 } },
    { label = "EXPLORER  (a bit of all)", grant = { wood = 4, stone = 4, flower = 3 } },
  }
  local RES = { "wood", "stone", "flower" }

  local built, HW, HH = false, 0, 0
  local inv = { wood = 0, stone = 0, flower = 0 }
  local met, gift_t = false, 0
  local cols, rows, gx0, gy0 = 0, 0, 0, 0
  local grid, placed_n = {}, 0            -- grid["c,r"] = { kind, id }
  local sel_i = 1                          -- 1..#BLOCKS = block, #BLOCKS+1 = eraser
  local nodes, npc, npc_r, b_back = {}, nil, nil, nil
  local palette, pal_bg, retint = {}, {}, nil
  local dlg = { open = false, ids = {}, opts = {} }

  local function cell_key(c, r) return c .. "," .. r end
  local function cell_xy(c, r) return gx0 + (c + 0.5) * CELL, gy0 + (r + 0.5) * CELL end

  local function cost_str(cost)
    local p = {}
    if cost.wood then p[#p + 1] = cost.wood .. "W" end
    if cost.stone then p[#p + 1] = cost.stone .. "S" end
    if cost.flower then p[#p + 1] = cost.flower .. "F" end
    return table.concat(p, "+")
  end
  local function hud()
    local tool = sel_i > #BLOCKS and "ERASE"
      or string.format("%s (%s)", BLOCKS[sel_i].key, cost_str(BLOCKS[sel_i].cost))
    game.set_text(string.format("WOOD %d   STONE %d   FLOWER %d   BLOCKS %d\nTOOL: %s",
      inv.wood, inv.stone, inv.flower, placed_n, tool))
  end

  -- Persistence: the world is a "c,r,kind;..." string, the inventory "w,s,f".
  local function save_world()
    local parts = {}
    for k, cell in pairs(grid) do parts[#parts + 1] = k .. "," .. cell.kind end
    table.sort(parts)                      -- deterministic saves (pairs order isn't)
    game.save("craft.world", table.concat(parts, ";"))
  end
  local function save_inv()
    game.save("craft.inv", string.format("%d,%d,%d", inv.wood, inv.stone, inv.flower))
  end

  local function can_afford(cost)
    for k, v in pairs(cost) do if (inv[k] or 0) < v then return false end end
    return true
  end
  local function pay(cost, sign)
    for k, v in pairs(cost) do inv[k] = inv[k] + sign * v end
    save_inv()
  end

  local function place(c, r, kind, silent)
    local x, y = cell_xy(c, r)
    local b = BLOCKS[kind]
    local id = game.spawn_sprite(x, y, CELL - 4, CELL - 4, b.tex)
    grid[cell_key(c, r)] = { kind = kind, id = id }
    placed_n = placed_n + 1
    if not silent then
      game.play_sound("hit"); game.haptic("light"); game.emit("dust", x, y)
      save_world(); hud()
    end
  end
  local function erase(c, r)
    local cell = grid[cell_key(c, r)]
    if not cell then return end
    pay(BLOCKS[cell.kind].cost, 1)         -- full refund
    game.despawn(cell.id)
    grid[cell_key(c, r)] = nil
    placed_n = placed_n - 1
    game.play_sound("wall"); game.haptic("light")
    save_world(); hud()
  end

  local function close_dialog()
    for _, id in ipairs(dlg.ids) do game.despawn(id) end
    dlg.ids, dlg.opts, dlg.open = {}, {}, false
  end
  -- Modal option dialogue: a dark panel + one button per option. Buttons carry
  -- an `act` closure; the tap handler runs it (acts close the dialogue).
  local function open_dialog(line, options)
    close_dialog()
    dlg.open = true
    local pw = math.min(2 * HW - 56, 400)
    local ph = 130 + #options * 74
    local py = 40
    local ids = dlg.ids
    ids[#ids + 1] = game.spawn(0, py, pw, ph, 0.08, 0.10, 0.16, 0.96)
    ids[#ids + 1] = game.spawn_sprite(0, py + ph * 0.5 - 8, 60, 56, "villager")
    ids[#ids + 1] = game.spawn_text(0, py + ph * 0.5 - 66, 21, 1, 1, 1, 1, line)
    for i, opt in ipairs(options) do
      local oy = py + ph * 0.5 - 128 - (i - 1) * 74
      local r = { x = 0, y = oy, w = pw - 48, h = 60, label = opt.label, act = opt.act }
      ids[#ids + 1] = game.spawn(r.x, r.y, r.w, r.h, 0.24, 0.34, 0.52, 1)
      ids[#ids + 1] = game.spawn_text(r.x, r.y, 20, 1, 1, 1, 1, opt.label)
      dlg.opts[#dlg.opts + 1] = r
    end
  end

  local function talk()
    if not met then
      local opts = {}
      for _, kit in ipairs(KITS) do
        opts[#opts + 1] = { label = kit.label, act = function()
          pay(kit.grant, 1)
          met = true; game.save("craft.met", true)
          game.play_sound("score"); game.haptic("success"); game.emit("confetti", 0, 40)
          close_dialog(); hud()
        end }
      end
      open_dialog("Welcome to your world!\nWhat kind of creator are you?", opts)
      return
    end
    local line
    if placed_n == 0 then line = "Try the palette below --\nplace your first block!"
    elseif placed_n < 8 then line = "Nice start! Trees give wood,\nrocks give stone."
    else line = "Your world is growing!\nKeep building." end
    open_dialog(line, {
      { label = "GIFT", act = function()
        if gift_t <= 0 then
          local r = RES[math.random(#RES)]
          inv[r] = inv[r] + 2; save_inv(); gift_t = GIFT_CD
          game.play_sound("score"); game.haptic("success")
          if npc_r then game.emit("spark", npc_r.x, npc_r.y) end
        else
          game.play_sound("wall")
        end
        close_dialog(); hud()
      end },
      { label = "BYE", act = function() close_dialog() end },
    })
  end

  local function load_state()
    local s = game.load("craft.inv")
    if type(s) == "string" then
      local w, st, f = s:match("^(%-?%d+),(%-?%d+),(%-?%d+)$")
      if w then inv.wood, inv.stone, inv.flower = tonumber(w), tonumber(st), tonumber(f) end
    end
    met = game.load("craft.met") == true
    local world = game.load("craft.world")
    if type(world) == "string" then
      for c, r, k in world:gmatch("(%-?%d+),(%-?%d+),(%d+)") do
        c, r, k = tonumber(c), tonumber(r), tonumber(k)
        if c >= 0 and c < cols and r >= 0 and r < rows and BLOCKS[k]
           and not grid[cell_key(c, r)] then
          place(c, r, k, true)
        end
      end
    end
  end

  local function build(hw, hh)
    HW, HH = hw, hh
    inv = { wood = 0, stone = 0, flower = 0 }
    grid, placed_n, sel_i, gift_t = {}, 0, 1, 0

    -- Grid area between the node row (top) and the palette bar (bottom).
    cols = math.max(4, math.floor((2 * hw - 12) / CELL))
    rows = math.max(4, math.floor((2 * hh - PAL_H - TOP_RESERVE) / CELL))
    local gw, gh = cols * CELL, rows * CELL
    local gyc = (PAL_H - TOP_RESERVE) * 0.5
    gx0, gy0 = -gw * 0.5, gyc - gh * 0.5
    T.spawn(0, gyc, gw, gh, 0.42, 0.66, 0.38, 1)                 -- grass ground
    for c = 0, cols do T.spawn(gx0 + c * CELL, gyc, 2, gh, 1, 1, 1, 0.07) end
    for r = 0, rows do T.spawn(0, gy0 + r * CELL, gw, 2, 1, 1, 1, 0.07) end

    b_back = K.make_back(T, hw, hh)
    npc_r = { x = hw - 84, y = hh - 152, w = 96, h = 84 }        -- mirrors the back sign
    npc = T.sprite(npc_r.x, npc_r.y, 60, 56, "villager")

    -- Gather nodes: tap to collect, then they recharge for NODE_CD seconds.
    local ny = hh - 252
    nodes = {
      { x = -hw * 0.65, y = ny, w = 72, h = 80, res = "wood", id = T.sprite(-hw * 0.65, ny, 58, 74, "tree"), cd = 0 },
      { x = 0, y = ny, w = 68, h = 60, res = "stone", id = T.sprite(0, ny, 52, 40, "rock"), cd = 0 },
      { x = hw * 0.65, y = ny, w = 60, h = 60, res = "flower", id = T.sprite(hw * 0.65, ny, 38, 38, "flower"), cd = 0 },
    }

    -- Palette bar: one slot per block + the eraser, on tintable rtile chips.
    palette, pal_bg = {}, {}
    local n = #BLOCKS + 1
    local sw = math.min(64, (2 * hw - 24) / n - 8)
    local px0 = -(n - 1) * (sw + 8) * 0.5
    for i = 1, n do
      local x, y = px0 + (i - 1) * (sw + 8), -hh + 62
      pal_bg[i] = T.sprite(x, y, sw, sw, "rtile")
      T.sprite(x, y, sw * 0.66, sw * 0.66, i <= #BLOCKS and BLOCKS[i].tex or "icon_trash")
      palette[i] = { x = x, y = y, w = sw, h = sw, key = i <= #BLOCKS and BLOCKS[i].key or "ERASE" }
    end
    retint = function()
      for i = 1, n do
        if i == sel_i then game.set_color(pal_bg[i], 1.0, 0.85, 0.4, 1)
        else game.set_color(pal_bg[i], 0.55, 0.6, 0.7, 1) end
      end
    end
    retint()
    load_state()
    hud(); built = true
    if not met then talk() end             -- first visit: the villager greets you

    DEBUG = {
      game = "craft", back = b_back, npc = npc_r, palette = palette, nodes = nodes,
      cols = cols, rows = rows,
      cellrect = function(c, r) local x, y = cell_xy(c, r); return { x = x, y = y, w = CELL, h = CELL } end,
      get = function(c, r) local cell = grid[cell_key(c, r)]; return cell and cell.kind or 0 end,
      inv = function() return inv end,
      placed = function() return placed_n end,
      sel = function() return sel_i end,
      met = function() return met end,
      gift = function() return gift_t end,
      dialog = function() return dlg.open end,
      options = function() return dlg.opts end,
    }
  end

  return {
    enter = function() built = false end,
    leave = function()
      close_dialog()
      for _, cell in pairs(grid) do game.despawn(cell.id) end
      grid, placed_n = {}, 0
      T.clear(); built = false
    end,
    tap = function(x, y)
      if not built then return end
      if inr(b_back, x, y) then close_dialog(); K.switch("menu"); return end
      if dlg.open then
        for _, o in ipairs(dlg.opts) do
          if inr(o, x, y) then game.haptic("light"); o.act(); return end
        end
        return                              -- modal: swallow taps outside options
      end
      for i, p in ipairs(palette) do
        if inr(p, x, y) then
          sel_i = i; retint(); game.play_sound("wall"); game.haptic("light"); hud(); return
        end
      end
      if inr(npc_r, x, y) then game.play_sound("hit"); game.haptic("light"); talk(); return end
      for _, nd in ipairs(nodes) do
        if inr(nd, x, y) then
          if nd.cd <= 0 then
            inv[nd.res] = inv[nd.res] + 1; save_inv(); nd.cd = NODE_CD
            game.set_color(nd.id, 0.5, 0.5, 0.5, 1)
            game.play_sound("hit"); game.haptic("light"); game.emit("spark", nd.x, nd.y); hud()
          else
            game.play_sound("wall")
          end
          return
        end
      end
      local c = math.floor((x - gx0) / CELL)
      local r = math.floor((y - gy0) / CELL)
      if c < 0 or c >= cols or r < 0 or r >= rows then return end
      if sel_i > #BLOCKS then erase(c, r); return end
      if grid[cell_key(c, r)] then game.play_sound("wall"); return end
      local b = BLOCKS[sel_i]
      if not can_afford(b.cost) then game.play_sound("wall"); game.shake(0.03); return end
      pay(b.cost, -1)
      place(c, r, sel_i)
    end,
    update = function(dt, hw, hh)
      if not built then build(hw, hh) end
      dt = math.min(dt, 1 / 30)
      if gift_t > 0 then gift_t = math.max(0, gift_t - dt) end
      for _, nd in ipairs(nodes) do
        if nd.cd > 0 then
          nd.cd = nd.cd - dt
          if nd.cd <= 0 then nd.cd = 0; game.set_color(nd.id, 1, 1, 1, 1) end
        end
      end
    end,
  }
end

-- Self-register this game pack (see main.lua: menu builds from PACKS).
PACKS = PACKS or {}
PACKS["craft"] = { slot = 10, key = "craft", label = "Craft World", short = "Craft", icon = "tree", color = { 0.55, 0.44, 0.30 }, tier = "curated", make = make_craft }
