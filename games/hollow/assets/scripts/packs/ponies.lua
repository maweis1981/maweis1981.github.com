-- ponies.lua — "小马拼图" (Pony Parade): a Queens / Star Battle logic puzzle,
-- UI and interaction modeled 1:1 on the reference gameplay video:
--   · tap an open cell to place a pony DIRECTLY (no manual X cycling)
--   · every placed pony AUTO-MARKS an X on each cell it excludes
--     (same row / column / colour region / any of the 8 neighbours)
--   · a wrong pony (not the unique solution) flashes red and costs a heart
--     (2 hearts per board); running out of hearts or time fails the level
--   · top bar: coins · energy · level title · hearts · streak; below it the
--     "remaining ponies" + countdown pills and the three-rule banner
--   · bottom bar: clear · find-pony tool · lightbulb hint · colourblind
--     mode toggle · coordinates toggle
-- Chinese labels render through assets/fonts/game.ttf, a Noto Sans subset
-- built by tools/subset_font.py — any NEW CJK string must be added there.
-- Puzzles are generated on the fly with a uniqueness-counting solver (capped
-- fallback so generation terminates under ANY math.random, incl. test LCG).
-- Registers make_ponies; talks to the host ONLY via `game` + GAME_KIT.

function make_ponies()
  local K = GAME_KIT
  local inr = K.in_rect
  local T = K.tracker()

  -- Region tints matched to the video's pastel look (index = region 1..10).
  local COLORS = {
    { 0.80, 0.85, 0.45 }, -- olive-lime
    { 0.95, 0.60, 0.70 }, -- pink
    { 0.45, 0.72, 0.95 }, -- blue
    { 0.62, 0.55, 0.90 }, -- violet
    { 0.72, 0.85, 0.95 }, -- pale sky
    { 0.95, 0.55, 0.45 }, -- coral red
    { 0.97, 0.72, 0.35 }, -- orange
    { 0.55, 0.85, 0.70 }, -- mint
    { 0.90, 0.80, 0.55 }, -- sand
    { 0.80, 0.65, 0.85 }, -- mauve
  }
  local START_N, MAX_N = 8, 10
  local HEARTS0 = 2
  local FLASH_T = 0.45

  -- session meta (persists across enter/leave; the closure lives for the run)
  local level, streak, coins, energy = 1, 0, 48, 98

  local back, built = nil, false
  local N = START_N
  local sol, reg = nil, nil       -- sol[r] = solution column; reg[r][c] = region id
  local state = nil               -- state[r][c]: 0 open, 1 auto-X, 2 pony
  local cells, xmarks, ponies = nil, nil, nil
  local hearts, placed = HEARTS0, 0
  local won, dead = false, false
  local time_left, time_shown = 0, -1
  local flash = {}                -- red mistake flashes / yellow hint flashes
  local anims = {}                -- pony pop-in tweens { id, t, dur, to }
  local ox, oy, cell = 0, 0, 0
  local board_panel = nil
  local scr_hw, scr_hh = 215, 466

  -- HUD entity ids (text redrawn in place via despawn+respawn)
  local ui = {}                   -- static pills/icons (in T)
  local dyn = {}                  -- dynamic texts: level, hearts, streak, left, time, badges
  local overlay = {}              -- win/fail overlay entities
  local find_charges, bulb_charges = 1, 1
  local cb_on, coord_on = false, false
  local cb_ids, coord_ids = {}, {}

  ----------------------------------------------------------------------------
  -- Puzzle generation (unchanged core: terminates under ANY math.random)
  ----------------------------------------------------------------------------
  local function gen_solution(n)
    local s, used = {}, {}
    local function bt(r)
      if r > n then return true end
      local colsl = {}
      for c = 1, n do
        if not used[c] and (r == 1 or math.abs(c - s[r - 1]) >= 2) then colsl[#colsl + 1] = c end
      end
      for i = #colsl, 2, -1 do local j = math.random(i); colsl[i], colsl[j] = colsl[j], colsl[i] end
      for _, c in ipairs(colsl) do
        s[r], used[c] = c, true
        if bt(r + 1) then return true end
        s[r], used[c] = nil, nil
      end
      return false
    end
    bt(1)
    return s
  end

  local DIRS = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
  local function gen_regions(n, s)
    local rg, mine = {}, {}
    for r = 1, n do rg[r] = {} end
    for k = 1, n do rg[k][s[k]] = k; mine[k] = { { k, s[k] } } end
    local remaining = n * n - n
    while remaining > 0 do
      local progressed = false
      for k = 1, n do
        if remaining == 0 then break end
        local opts = {}
        for _, cl in ipairs(mine[k]) do
          for _, d in ipairs(DIRS) do
            local rr, cc = cl[1] + d[1], cl[2] + d[2]
            if rr >= 1 and rr <= n and cc >= 1 and cc <= n and not rg[rr][cc] then
              opts[#opts + 1] = { rr, cc }
            end
          end
        end
        if #opts > 0 then
          local p = opts[math.random(#opts)]
          rg[p[1]][p[2]] = k
          mine[k][#mine[k] + 1] = p
          remaining = remaining - 1
          progressed = true
        end
      end
      if not progressed then break end
    end
    return rg
  end

  local function count_solutions(n, rg, limit)
    local usedc, usedreg, colof, count = {}, {}, {}, 0
    local function bt(r)
      if count >= limit then return end
      if r > n then count = count + 1; return end
      for c = 1, n do
        local k = rg[r][c]
        if not usedc[c] and not usedreg[k] and (r == 1 or math.abs(c - colof[r - 1]) >= 2) then
          usedc[c], usedreg[k], colof[r] = true, true, c
          bt(r + 1)
          usedc[c], usedreg[k], colof[r] = nil, nil, nil
        end
      end
    end
    bt(1)
    return count
  end

  -- Hill-climb a region layout toward uniqueness: reassign one boundary cell
  -- to a neighbouring region (never a pony's own seed cell), keep the change
  -- when it doesn't increase the solution count. Converges far faster than
  -- blind re-rolls at N >= 8, and every step keeps regions contiguous-safe by
  -- re-checking the donor region still connects through a flood fill.
  local function region_cells(rg, n, k)
    local out = {}
    for r = 1, n do for c = 1, n do if rg[r][c] == k then out[#out + 1] = { r, c } end end end
    return out
  end

  local function still_contiguous(rg, n, k)
    local cellsk = region_cells(rg, n, k)
    if #cellsk == 0 then return false end
    local seen, stack, found = {}, { cellsk[1] }, 0
    while #stack > 0 do
      local p = table.remove(stack)
      local r, c = p[1], p[2]
      local key = r * 100 + c
      if r >= 1 and r <= n and c >= 1 and c <= n and not seen[key] and rg[r][c] == k then
        seen[key] = true; found = found + 1
        stack[#stack + 1] = { r + 1, c }; stack[#stack + 1] = { r - 1, c }
        stack[#stack + 1] = { r, c + 1 }; stack[#stack + 1] = { r, c - 1 }
      end
    end
    return found == #cellsk
  end

  local function refine_to_unique(n, s, rg, steps)
    -- true (capped) count gives the climb a gradient; limit keeps it cheap
    local CAP = 400
    local best = count_solutions(n, rg, CAP)
    for _ = 1, steps do
      if best <= 1 then return rg, best end
      -- collect boundary cells (not pony seeds) that touch a different region
      local opts = {}
      for r = 1, n do
        for c = 1, n do
          if s[r] ~= c or rg[r][c] ~= r then -- never move a pony's seed cell
            for _, d in ipairs(DIRS) do
              local rr, cc = r + d[1], c + d[2]
              if rr >= 1 and rr <= n and cc >= 1 and cc <= n and rg[rr][cc] ~= rg[r][c] then
                opts[#opts + 1] = { r, c, rg[rr][cc] }
                break
              end
            end
          end
        end
      end
      if #opts == 0 then break end
      local pick = opts[math.random(#opts)]
      local r, c, to = pick[1], pick[2], pick[3]
      local from = rg[r][c]
      -- a pony's cell must stay in its own region
      if s[r] == c then goto continue end
      rg[r][c] = to
      if not still_contiguous(rg, n, from) or region_cells(rg, n, from)[1] == nil then
        rg[r][c] = from
      else
        -- early-out at best+1: we only care whether this is an improvement
        local cnt = count_solutions(n, rg, best + 1)
        if cnt < best or (cnt == best and math.random() < 0.25) then
          best = cnt
        else
          rg[r][c] = from
        end
      end
      ::continue::
    end
    return rg, best
  end

  local function gen_level(n)
    local fallback_s, fallback_rg = nil, nil
    for _ = 1, 12 do
      local s = gen_solution(n)
      for _ = 1, 4 do
        local rg = gen_regions(n, s)
        local refined, cnt = refine_to_unique(n, s, rg, 240)
        if cnt == 1 then return s, refined end
        fallback_s, fallback_rg = s, refined
      end
    end
    -- Capped fallback: still a valid, winnable board (may have siblings).
    return fallback_s or gen_solution(n), fallback_rg or gen_regions(n, fallback_s or gen_solution(n))
  end

  ----------------------------------------------------------------------------
  -- Board rendering
  ----------------------------------------------------------------------------
  local function cell_center(r, c)
    return ox + (c - 1) * cell, oy - (r - 1) * cell
  end

  local function tint(r, c)
    local col = COLORS[((reg[r][c] - 1) % #COLORS) + 1]
    game.set_color(cells[r][c], col[1], col[2], col[3], 1)
  end

  local function clear_overlay_at(r, c)
    if xmarks[r][c] then
      game.despawn(xmarks[r][c][1]); xmarks[r][c] = nil
    end
    if ponies[r][c] then game.despawn(ponies[r][c]); ponies[r][c] = nil end
  end

  local function draw_cell_state(r, c)
    clear_overlay_at(r, c)
    local x, y = cell_center(r, c)
    if state[r][c] == 1 then
      local m = game.spawn_sprite(x, y, cell * 0.62, cell * 0.62, "rxmark")
      game.set_color(m, 0.30, 0.32, 0.38, 0.92)
      xmarks[r][c] = { m }
    elseif state[r][c] == 2 then
      local id = game.spawn_sprite(x, y, cell * 0.30, cell * 0.30, "pony")
      ponies[r][c] = id
      anims[#anims + 1] = { id = id, t = 0, dur = 0.18, to = cell * 0.88 }
    end
  end

  -- Recompute every auto-X from the ponies on the board (video behaviour:
  -- placing marks exclusions immediately; removing un-marks what only that
  -- pony excluded). Full recompute keeps removal trivially correct.
  local function recompute_marks()
    for r = 1, N do
      for c = 1, N do
        if state[r][c] ~= 2 then
          local excluded = false
          for rr = 1, N do
            for cc = 1, N do
              if state[rr][cc] == 2 then
                if rr == r or cc == c or reg[rr][cc] == reg[r][c]
                  or (math.abs(rr - r) <= 1 and math.abs(cc - c) <= 1) then
                  excluded = true
                end
              end
            end
          end
          local want = excluded and 1 or 0
          if state[r][c] ~= want then
            state[r][c] = want
            draw_cell_state(r, c)
          end
        end
      end
    end
  end

  ----------------------------------------------------------------------------
  -- HUD (top bar, pills, rule banner, toolbar) — cloned from the video layout
  ----------------------------------------------------------------------------
  local function retext(key, x, y, size, r, g, b, a, s)
    if dyn[key] then game.despawn(dyn[key]) end
    dyn[key] = game.spawn_text(x, y, size, r, g, b, a, s)
  end

  local function hud_level() retext("level", 0, scr_hh - 114, 32, 0.16, 0.18, 0.30, 1, "第" .. level .. "关") end
  local function hud_streak() retext("streak", scr_hw - 72, scr_hh - 152, 17, 0.85, 0.15, 0.15, 1, "连胜：" .. streak) end
  local function hud_left() retext("left", -scr_hw + 120, scr_hh - 292, 16, 0.85, 0.15, 0.15, 1, "剩余：" .. (N - placed)) end
  local function hud_coins() retext("coins", -scr_hw + 92, scr_hh - 210, 16, 1, 1, 1, 1, tostring(coins)) end
  local function hud_time()
    local t = math.max(0, math.ceil(time_left))
    if t == time_shown then return end
    time_shown = t
    retext("time", scr_hw - 88, scr_hh - 292, 16, 0.85, 0.15, 0.15, 1, "剩余时间：" .. t)
  end
  local function hud_hearts()
    for i = 1, HEARTS0 do
      local id = dyn["heart" .. i]
      if id then
        if i <= hearts then game.set_color(id, 1, 1, 1, 1)
        else game.set_color(id, 0.25, 0.25, 0.28, 0.65) end
      end
    end
  end
  local function hud_badges()
    retext("findn", -70, -scr_hh + 62, 15, 1, 1, 1, 1, find_charges > 0 and tostring(find_charges) or "+")
    retext("bulbn", 70, -scr_hh + 62, 15, 1, 1, 1, 1, bulb_charges > 0 and tostring(bulb_charges) or "+")
  end

  local BTN = {}  -- tap rects for toolbar buttons

  local function pill(x, y, w, h, r, g, b, a)
    local id = T.sprite(x, y, w, h, "rpill")
    game.set_color(id, r, g, b, a)
    return id
  end

  local function card(x, y, w, h, r, g, b, a)
    local id = T.sprite(x, y, w, h, "rcard")
    game.set_color(id, r, g, b, a)
    return id
  end

  local function build_hud()
    -- pale board-room backdrop, spawned first so everything draws over it
    T.spawn(0, 0, scr_hw * 2 + 4, scr_hh * 2 + 4, 0.80, 0.85, 0.91, 1)
    back = K.make_back(T, scr_hw, scr_hh)

    -- title with a soft drop shadow (rounded bold subset font)
    T.text(2, scr_hh - 112, 32, 0.10, 0.12, 0.22, 0.25, "第" .. level .. "关")

    -- hearts pill (centered) + streak pill (right), same row as the back button
    pill(0, scr_hh - 152, 132, 40, 1, 1, 1, 0.95)
    dyn["heart1"] = game.spawn_sprite(-26, scr_hh - 152, 28, 28, "icon_heart")
    dyn["heart2"] = game.spawn_sprite(26, scr_hh - 152, 28, 28, "icon_heart")
    pill(scr_hw - 88, scr_hh - 152, 158, 38, 1, 1, 1, 0.95)
    T.sprite(scr_hw - 152, scr_hh - 152, 28, 28, "icon_trophy")

    -- coins + energy pills (left column, under the back button)
    pill(-scr_hw + 76, scr_hh - 210, 118, 32, 0.60, 0.64, 0.72, 0.9)
    T.sprite(-scr_hw + 34, scr_hh - 210, 26, 26, "icon_coin")
    pill(-scr_hw + 76, scr_hh - 246, 118, 32, 0.60, 0.64, 0.72, 0.9)
    T.sprite(-scr_hw + 34, scr_hh - 246, 26, 26, "icon_bolt")
    T.text(-scr_hw + 92, scr_hh - 246, 16, 1, 1, 1, 1, tostring(energy))

    -- remaining + countdown pills (dashed row in the reference)
    pill(-scr_hw + 106, scr_hh - 292, 194, 34, 1, 1, 1, 0.9)
    T.sprite(-scr_hw + 32, scr_hh - 292, 26, 26, "pony")
    pill(scr_hw - 106, scr_hh - 292, 200, 34, 1, 1, 1, 0.9)
    T.sprite(scr_hw - 192, scr_hh - 292, 24, 24, "icon_clock")

    -- three-rule banner
    pill(0, scr_hh - 338, scr_hw * 2 - 20, 58, 1, 1, 1, 0.95)
    T.text(-scr_hw * 0.62, scr_hh - 338, 13, 0.20, 0.22, 0.32, 1, "每种颜色1匹\n小马")
    T.spawn(-scr_hw * 0.30, scr_hh - 338, 2, 40, 0.86, 0.88, 0.91, 1)
    T.text(0, scr_hh - 338, 13, 0.20, 0.22, 0.32, 1, "每行每列均有且\n仅有1匹小马")
    T.spawn(scr_hw * 0.30, scr_hh - 338, 2, 40, 0.86, 0.88, 0.91, 1)
    T.text(scr_hw * 0.62, scr_hh - 338, 13, 0.20, 0.22, 0.32, 1, "小马不能相邻")

    -- bottom toolbar: clear · find tool · bulb tool · colourblind · coords
    local by = -scr_hh + 96
    BTN.clear = { x = -scr_hw + 46, y = by, w = 84, h = 76 }
    card(BTN.clear.x, BTN.clear.y, BTN.clear.w, BTN.clear.h, 0.62, 0.72, 0.84, 0.95)
    T.sprite(BTN.clear.x, BTN.clear.y + 12, 30, 30, "icon_trash")
    T.text(BTN.clear.x, BTN.clear.y - 22, 14, 1, 1, 1, 1, "清除")

    BTN.find = { x = -70, y = by, w = 96, h = 96 }
    card(BTN.find.x, BTN.find.y, BTN.find.w, BTN.find.h, 1, 1, 1, 0.97)
    T.sprite(BTN.find.x, BTN.find.y + 8, 62, 62, "icon_find")
    pill(BTN.find.x, -scr_hh + 62, 84, 22, 0.15, 0.35, 0.80, 1)

    BTN.bulb = { x = 70, y = by, w = 96, h = 96 }
    card(BTN.bulb.x, BTN.bulb.y, BTN.bulb.w, BTN.bulb.h, 1, 1, 1, 0.97)
    T.sprite(BTN.bulb.x, BTN.bulb.y + 8, 58, 58, "icon_bulb")
    pill(BTN.bulb.x, -scr_hh + 62, 84, 22, 0.15, 0.35, 0.80, 1)

    BTN.coord = { x = scr_hw - 44, y = by, w = 80, h = 76 }
    card(BTN.coord.x, BTN.coord.y, BTN.coord.w, BTN.coord.h, 0.62, 0.72, 0.84, 0.95)
    T.sprite(BTN.coord.x, BTN.coord.y + 12, 28, 28, "icon_pin")
    T.text(BTN.coord.x, BTN.coord.y - 22, 14, 1, 1, 1, 1, "坐标")

    BTN.cb = { x = scr_hw - 50, y = by + 110, w = 86, h = 78 }
    card(BTN.cb.x, BTN.cb.y, BTN.cb.w, BTN.cb.h, 0.94, 0.96, 0.99, 0.95)
    T.sprite(BTN.cb.x, BTN.cb.y + 14, 34, 34, "icon_eye")
    T.text(BTN.cb.x, BTN.cb.y - 22, 12, 0.85, 0.15, 0.15, 1, "色盲模式")

    hud_level(); hud_streak(); hud_coins(); hud_hearts(); hud_badges()
  end

  ----------------------------------------------------------------------------
  -- Overlays (win / fail), toggles
  ----------------------------------------------------------------------------
  local function clear_overlay()
    for _, id in ipairs(overlay) do game.despawn(id) end
    overlay = {}
  end

  local function show_overlay(title, subtitle, r, g, b)
    clear_overlay()
    overlay[#overlay + 1] = (function()
      local id = game.spawn_sprite(0, 0, scr_hw * 1.7, 170, "rcard")
      game.set_color(id, 1, 1, 1, 0.97)
      return id
    end)()
    overlay[#overlay + 1] = game.spawn_text(0, 26, 30, r, g, b, 1, title)
    overlay[#overlay + 1] = game.spawn_text(0, -30, 17, 0.35, 0.38, 0.48, 1, subtitle)
  end

  local function clear_toggles()
    for _, id in ipairs(cb_ids) do game.despawn(id) end
    for _, id in ipairs(coord_ids) do game.despawn(id) end
    cb_ids, coord_ids = {}, {}
  end

  local function redraw_cb()
    for _, id in ipairs(cb_ids) do game.despawn(id) end
    cb_ids = {}
    if not cb_on then return end
    for r = 1, N do
      for c = 1, N do
        local x, y = cell_center(r, c)
        cb_ids[#cb_ids + 1] = game.spawn_text(
          x + cell * 0.28, y + cell * 0.26, math.max(9, cell * 0.22),
          0.15, 0.17, 0.25, 0.85, tostring(reg[r][c]))
      end
    end
  end

  local function redraw_coords()
    for _, id in ipairs(coord_ids) do game.despawn(id) end
    coord_ids = {}
    if not coord_on then return end
    for r = 1, N do
      local _, y = cell_center(r, 1)
      coord_ids[#coord_ids + 1] = game.spawn_text(
        ox - cell * 0.85, y, math.max(10, cell * 0.26), 0.35, 0.38, 0.48, 1, tostring(r))
    end
    for c = 1, N do
      local x, _ = cell_center(1, c)
      coord_ids[#coord_ids + 1] = game.spawn_text(
        x, oy + cell * 0.85, math.max(10, cell * 0.26), 0.35, 0.38, 0.48, 1,
        string.char(64 + c))
    end
  end

  ----------------------------------------------------------------------------
  -- Level lifecycle
  ----------------------------------------------------------------------------
  local function clear_board_entities()
    if board_panel then game.despawn(board_panel); board_panel = nil end
    if not cells then return end
    for r = 1, N do
      for c = 1, N do
        clear_overlay_at(r, c)
        if cells[r][c] then game.despawn(cells[r][c]) end
      end
    end
    cells = nil
  end

  local function build_level(fresh)
    clear_board_entities(); clear_overlay(); clear_toggles()
    if fresh then sol, reg = gen_level(N) end
    state, cells, xmarks, ponies = {}, {}, {}, {}
    hearts, placed, won, dead, flash = HEARTS0, 0, false, false, {}
    time_left, time_shown = N * 10, -1
    anims = {}
    local board = math.min(2 * scr_hw * 0.875, 2 * scr_hh * 0.42)
    cell = board / N
    ox = -board / 2 + cell / 2
    oy = (scr_hh - 372) - cell / 2
    board_panel = game.spawn_sprite(0, oy - (N - 1) * cell / 2, board + 18, board + 18, "rcard")
    game.set_color(board_panel, 1, 1, 1, 0.92)
    for r = 1, N do
      state[r], cells[r], xmarks[r], ponies[r] = {}, {}, {}, {}
      for c = 1, N do
        state[r][c] = 0
        local x, y = cell_center(r, c)
        local col = COLORS[((reg[r][c] - 1) % #COLORS) + 1]
        cells[r][c] = game.spawn_sprite(x, y, cell - 4, cell - 4, "rtile")
        game.set_color(cells[r][c], col[1], col[2], col[3], 1)
      end
    end
    hud_level(); hud_hearts(); hud_left(); hud_time()
    redraw_cb(); redraw_coords()
  end

  local function win_level()
    won = true
    streak = streak + 1
    coins = coins + 20
    hud_streak(); hud_coins()
    show_overlay("恭喜过关！", "点击继续", 0.20, 0.65, 0.30)
    game.play_sound("score"); game.haptic("success"); game.shake(0.5); game.zoom(1.0)
  end

  local function fail_level(reason)
    dead = true
    streak = 0
    hud_streak()
    show_overlay("挑战失败", reason .. "·再试一次", 0.85, 0.20, 0.18)
    game.play_sound("hit"); game.haptic("heavy"); game.shake(0.4)
  end

  local function place_correct(r)
    local c = sol[r]
    state[r][c] = 2
    placed = placed + 1
    draw_cell_state(r, c)
    recompute_marks()
    hud_left()
    game.play_sound("hit"); game.haptic("medium"); game.shake(0.08); game.zoom(0.3)
    if placed == N then win_level() end
  end

  local function tap_cell(r, c)
    local s = state[r][c]
    if s == 2 then
      state[r][c] = 0
      placed = placed - 1
      draw_cell_state(r, c)
      recompute_marks()
      hud_left()
      game.play_sound("wall"); game.haptic("light")
    elseif s == 1 then
      game.shake(0.04)  -- excluded cell: nudge only, matches the video
    else
      if sol[r] == c then
        place_correct(r)
      else
        hearts = hearts - 1
        hud_hearts()
        flash[#flash + 1] = { r = r, c = c, t = FLASH_T, red = true }
        game.set_color(cells[r][c], 0.92, 0.20, 0.18, 1)
        game.play_sound("hit"); game.haptic("heavy"); game.shake(0.3); game.zoom(0.55)
        if hearts <= 0 then fail_level("爱心用完了") end
      end
    end
  end

  local function first_unsolved_row()
    for r = 1, N do if state[r][sol[r]] ~= 2 then return r end end
    return nil
  end

  ----------------------------------------------------------------------------
  -- Scene
  ----------------------------------------------------------------------------
  local function build(hw, hh)
    T.clear(); dyn = {}
    scr_hw, scr_hh = hw, hh
    build_hud()
    build_level(true)
    built = true
    DEBUG = {
      game = "ponies", back = back,
      n = function() return N end,
      level = function() return level end,
      hearts = function() return hearts end,
      placed = function() return placed end,
      won = function() return won end,
      dead = function() return dead end,
      streak = function() return streak end,
      coins = function() return coins end,
      time_left = function() return time_left end,
      find_charges = function() return find_charges end,
      bulb_charges = function() return bulb_charges end,
      cb_on = function() return cb_on end,
      coord_on = function() return coord_on end,
      state = function(r, c) return state[r][c] end,
      region = function(r, c) return reg[r][c] end,
      solution = function(r) return sol[r] end,
      cell_center = cell_center,
      btn = function(name) return BTN[name] end,
    }
  end

  return {
    enter = function()
      built = false
      game.play_music("ponies")   -- the Floniks-generated kawaii loop
    end,
    leave = function()
      game.play_music("music")    -- restore the collection's menu loop
      clear_board_entities(); clear_overlay(); clear_toggles()
      for _, id in pairs(dyn) do game.despawn(id) end
      dyn = {}
      T.clear()
      built = false
    end,
    tap = function(x, y)
      if back and inr(back, x, y) then K.switch("menu"); return end
      if not built then return end
      if dead then build_level(true); return end
      if won then
        level = level + 1
        N = math.min(START_N + math.floor((level - 1) / 2), MAX_N)
        build_level(true)
        return
      end
      if inr(BTN.clear, x, y) then
        if placed > 0 then
          for r = 1, N do
            for c = 1, N do
              if state[r][c] == 2 then state[r][c] = 0; draw_cell_state(r, c) end
            end
          end
          placed = 0
          recompute_marks(); hud_left()
          game.play_sound("wall"); game.haptic("light")
        end
        return
      end
      if inr(BTN.find, x, y) then
        if find_charges > 0 then
          local r = first_unsolved_row()
          if r then find_charges = find_charges - 1; hud_badges(); place_correct(r) end
        end
        return
      end
      if inr(BTN.bulb, x, y) then
        if bulb_charges > 0 then
          local r = first_unsolved_row()
          if r then
            bulb_charges = bulb_charges - 1; hud_badges()
            flash[#flash + 1] = { r = r, c = sol[r], t = 1.0 }
            game.set_color(cells[r][sol[r]], 1.0, 0.95, 0.35, 1)
            game.play_sound("wall"); game.haptic("light")
          end
        end
        return
      end
      if inr(BTN.cb, x, y) then cb_on = not cb_on; redraw_cb(); return end
      if inr(BTN.coord, x, y) then coord_on = not coord_on; redraw_coords(); return end
      local ccol = math.floor((x - (ox - cell / 2)) / cell) + 1
      local crow = math.floor(((oy + cell / 2) - y) / cell) + 1
      if crow >= 1 and crow <= N and ccol >= 1 and ccol <= N then
        tap_cell(crow, ccol)
      end
    end,
    update = function(dt, hw, hh)
      if not built then build(hw, hh) end
      if dt > 1 / 30 then dt = 1 / 30 end
      if not won and not dead then
        time_left = time_left - dt
        hud_time()
        if time_left <= 0 then fail_level("时间到了") end
      end
      if #anims > 0 then
        local keep = {}
        for _, a in ipairs(anims) do
          a.t = a.t + dt
          local f = math.min(1, a.t / a.dur)
          local sz
          if f < 0.7 then sz = a.to * (0.34 + 0.94 * (f / 0.7))
          else sz = a.to * (1.28 - 0.28 * ((f - 0.7) / 0.3)) end
          game.set_size(a.id, sz, sz)
          if f < 1 then keep[#keep + 1] = a end
        end
        anims = keep
      end
      if #flash > 0 then
        local keep = {}
        for _, f in ipairs(flash) do
          f.t = f.t - dt
          if f.t <= 0 then
            if state[f.r] and state[f.r][f.c] ~= nil then tint(f.r, f.c) end
          else
            keep[#keep + 1] = f
          end
        end
        flash = keep
      end
    end,
  }
end

-- Self-register this game pack (see main.lua: the menu builds from PACKS).
PACKS = PACKS or {}
PACKS["ponies"] = { slot = 21, key = "ponies", label = "Pony Parade", short = "Ponies", icon = "pony", color = { 0.72, 0.55, 0.85 }, tier = "ai", make = make_ponies }
