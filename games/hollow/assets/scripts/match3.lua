-- match3.lua — "Garden Match", a swipe match-3 (game #8).
--
-- Story: an enchanted garden is overgrown with vines. Match 3+ blooms in a line
-- to clear them; matches of 4 forge a Rocket (clears a row/column), matches of 5
-- a Radiant Bloom (clears every bloom of one kind). Restore the garden across a
-- handful of Adventure levels (score / collect / clear-the-vines objectives), or
-- relax in Endless. Registers the global factory make_match3 (main.lua's menu).
--
-- Design follows modern match-3 conventions: level-based + move-limited, special
-- pieces, and feedback on every action (select glow, invalid bounce, clear burst,
-- floating score, combo escalation, idle bob + anticipation hint, win/lose).
--
-- Board logic is a stepped state machine (swap -> clear -> fall -> cascade) driven
-- from update(); pieces lerp toward their target cell so falls/swaps animate.
-- DEBUG exposes the grid/score/moves + start()/swap() so test_pong.lua can drive it.

local progress = progress_match3 or { unlocked = 1, stars = {} }
progress_match3 = progress
local best_endless = best_endless or 0

function make_match3()
  local K = GAME_KIT
  local clamp, inr = K.clamp, K.in_rect
  local T = K.tracker()

  local COLS, ROWS, NTYPES = 7, 8, 6
  local SIDE, TOP_PAD, BOT_PAD, GAP = 16, 236, 60, 6
  local SWAP_T, CLEAR_T, LERP, MAX_DT = 0.12, 0.16, 18, 1 / 30
  local HINT_T = 4.0
  local TEX = { "gberry", "gdaisy", "gbell", "gleaf", "gviola", "gmush" }
  local NAME = { "BERRY", "DAISY", "BELL", "CLOVER", "VIOLET", "SHROOM" }
  local PAL = {
    { 0.92, 0.25, 0.28 }, { 0.97, 0.82, 0.24 }, { 0.42, 0.55, 0.95 },
    { 0.40, 0.80, 0.36 }, { 0.68, 0.42, 0.86 }, { 0.96, 0.55, 0.25 },
  }
  -- Adventure levels: obj = score | collect | jelly ("vines" in the fiction).
  local LEVELS = {
    { obj = "score", target = 700, moves = 18 },
    { obj = "score", target = 1600, moves = 20 },
    { obj = "collect", ctype = 1, count = 16, moves = 22 },
    { obj = "collect", ctype = 3, count = 14, moves = 20 },
    { obj = "jelly", jelly = 12, moves = 22 },
    { obj = "jelly", jelly = 20, moves = 26 },
    { obj = "collect", ctype = 6, count = 18, moves = 22 },
    { obj = "score", target = 4000, moves = 24 },
  }

  -- layout
  local cell, psize, board_left, board_top, HW, HH = 0, 0, 0, 0, 0, 0
  -- board + machine
  local cells, jelly, jelly_ov = {}, {}, {}
  local st, timer, combo, clock = "idle", 0, 0, 0
  local swap_cells, next_seeds, pending = nil, nil, nil
  -- meta
  local screen, mode, level_idx, level_def = nil, "adventure", 1, nil
  local score, moves, collected, jelly_left, over, won = 0, 0, 0, 0, false, false
  local idle_timer = 0
  -- input + fx
  local press, sel, bounce, glow, fx, ov = nil, nil, nil, nil, {}, {}
  local buttons, back, bg_img = {}, nil, nil
  local hud_ids, hud_on, amb = {}, nil, {}
  local BG = { "bg_meadow", "bg_glade", "bg_dusk" }
  local function level_bg(i) return (i <= 3) and BG[1] or (i <= 6) and BG[2] or BG[3] end

  ------------------------------------------------------------------ helpers
  local function center(c, r) return board_left + (c - 0.5) * cell, board_top - (r - 0.5) * cell end
  local function set_target(p, c, r) p.tx, p.ty = center(c, r) end
  local function to_cell(x, y)
    local c = math.floor((x - board_left) / cell) + 1
    local r = math.floor((board_top - y) / cell) + 1
    if c >= 1 and c <= COLS and r >= 1 and r <= ROWS then return c, r end
  end
  -- Render a numeric string ('0'-'9', '/', 'x', ' ') as art number sprites,
  -- monospaced and centered at (cx,cy); the sprite ids are tracked in hud_ids.
  local NUMTEX = { ["/"] = "num_slash", ["x"] = "num_x" }
  local function draw_number(cx, cy, s, H)
    local sw, adv = H * 64 / 84, H * 0.54
    local x0 = cx - (adv * (#s - 1) + sw) / 2 + sw / 2
    for i = 1, #s do
      local ch = s:sub(i, i)
      if ch ~= " " then
        hud_ids[#hud_ids + 1] = game.spawn_sprite(x0 + (i - 1) * adv, cy, sw, H, NUMTEX[ch] or ("num_" .. ch))
      end
    end
  end

  ------------------------------------------------------------------ feedback fx
  local function popup(x, y, text, size)
    fx[#fx + 1] = { kind = "text", id = game.spawn_text(x, y, size or 26, 1, 1, 1, 1, text),
      x = x, y = y, vy = 90, life = 0.7 }
  end
  local function burst(x, y, col, n)
    for i = 1, (n or 3) do
      local a = (i / (n or 3)) * 6.28 + clock
      local id = game.spawn_sprite(x, y, psize * 0.5, psize * 0.5, "sparkle")
      game.set_color(id, col[1], col[2], col[3], 1)
      fx[#fx + 1] = { kind = "part", id = id, x = x, y = y,
        vx = math.cos(a) * 120, vy = math.sin(a) * 120 + 40, life = 0.45, ttl = 0.45,
        size = psize * 0.5, r = col[1], g = col[2], b = col[3] }
    end
  end
  local function update_fx(dt)
    local keep = {}
    for _, e in ipairs(fx) do
      e.life = e.life - dt
      if e.life <= 0 then game.despawn(e.id) else
        e.x = e.x + (e.vx or 0) * dt; e.y = e.y + (e.vy or 0) * dt
        game.move_to(e.id, e.x, e.y)
        if e.kind == "part" then
          e.vy = e.vy - 260 * dt; e.size = e.size * (1 - dt * 1.2)
          game.set_size(e.id, e.size, e.size)
          game.set_color(e.id, e.r, e.g, e.b, e.life / e.ttl)
        elseif e.kind == "beam" then
          game.set_color(e.id, e.r, e.g, e.b, (e.life / e.ttl) * 0.85)
        end
        keep[#keep + 1] = e
      end
    end
    fx = keep
  end
  -- A bright fading streak across a triggered rocket's row/column (or a burst
  -- for a colour bomb) so line-clears read clearly.
  local function beam_fx(f)
    local id, x, y, r, g, b = nil, 0, 0, 1.0, 0.9, 0.42
    if f.sp == "row" then
      local _, cy = center(1, f.r); x, y = 0, cy
      id = game.spawn(0, cy, COLS * cell, cell * 0.92, r, g, b, 0.85)
    elseif f.sp == "col" then
      x = (center(f.c, 1)); y = board_top - ROWS * cell * 0.5
      id = game.spawn(x, y, cell * 0.92, ROWS * cell, r, g, b, 0.85)
    else
      x, y = center(f.c, f.r); r, g, b = 1, 1, 1
      id = game.spawn_sprite(x, y, psize * 2.3, psize * 2.3, "sparkle"); game.set_color(id, 1, 1, 1, 0.9)
    end
    fx[#fx + 1] = { kind = "beam", id = id, x = x, y = y, life = 0.34, ttl = 0.34, r = r, g = g, b = b }
  end

  ------------------------------------------------------------------ pieces
  local function set_special(p, kind)
    if p.mark then game.despawn(p.mark); p.mark = nil end
    p.sp = kind
    if kind == "bomb" then p.payload = (p.t > 0) and p.t or p.payload; p.t = 0 end
    -- Rocket markers reuse the glowing sparkle, stretched along the clear
    -- direction and tinted warm gold; the colour bomb is a white radiant sparkle.
    if kind == "row" then
      p.mark = game.spawn_sprite(p.x, p.y, psize * 1.15, psize * 0.55, "sparkle")
      game.set_color(p.mark, 1.0, 0.85, 0.35, 0.9)
    elseif kind == "col" then
      p.mark = game.spawn_sprite(p.x, p.y, psize * 0.55, psize * 1.15, "sparkle")
      game.set_color(p.mark, 1.0, 0.85, 0.35, 0.9)
    elseif kind == "bomb" then
      p.mark = game.spawn_sprite(p.x, p.y, psize * 0.72, psize * 0.72, "sparkle")
    end
  end
  local function kill_piece(p)
    if p.mark then game.despawn(p.mark) end
    game.despawn(p.id)
  end
  local function new_piece(t, c, r, from_y)
    local cx, cy = center(c, r)
    local sy = from_y or cy
    return { t = t, id = game.spawn_sprite(cx, sy, psize, psize, TEX[t]),
      x = cx, y = sy, tx = cx, ty = cy, s = 1, clr = false, sp = nil,
      phase = (c * 0.7 + r * 1.3), pop = 0, ox = 0, oy = 0 }
  end

  ------------------------------------------------------------------ matching
  local function find_runs()
    local runs = {}
    for r = 1, ROWS do
      local c = 1
      while c <= COLS do
        local p = cells[r][c]; local t = p and p.t
        local c2 = c
        while t and t > 0 and c2 < COLS and cells[r][c2 + 1] and cells[r][c2 + 1].t == t do c2 = c2 + 1 end
        if t and t > 0 and c2 - c + 1 >= 3 then
          local cc = {}; for k = c, c2 do cc[#cc + 1] = { c = k, r = r } end
          runs[#runs + 1] = { cells = cc, len = c2 - c + 1, horiz = true }
        end
        c = c2 + 1
      end
    end
    for c = 1, COLS do
      local r = 1
      while r <= ROWS do
        local p = cells[r][c]; local t = p and p.t
        local r2 = r
        while t and t > 0 and r2 < ROWS and cells[r2 + 1][c] and cells[r2 + 1][c].t == t do r2 = r2 + 1 end
        if t and t > 0 and r2 - r + 1 >= 3 then
          local cc = {}; for k = r, r2 do cc[#cc + 1] = { c = c, r = k } end
          runs[#runs + 1] = { cells = cc, len = r2 - r + 1, horiz = false }
        end
        r = r2 + 1
      end
    end
    return runs
  end
  local function any_match() return #find_runs() > 0 end
  local function swap_makes_match(c1, r1, c2, r2)
    cells[r1][c1], cells[r2][c2] = cells[r2][c2], cells[r1][c1]
    local ok = any_match()
    cells[r1][c1], cells[r2][c2] = cells[r2][c2], cells[r1][c1]
    return ok
  end
  local function find_move()
    for r = 1, ROWS do for c = 1, COLS do
      if cells[r][c] and cells[r][c].sp then return c, r, c, r end     -- a special is always playable
      if c < COLS and swap_makes_match(c, r, c + 1, r) then return c, r, c + 1, r end
      if r < ROWS and swap_makes_match(c, r, c, r + 1) then return c, r, c, r + 1 end
    end end
  end
  local function has_valid_move() return find_move() ~= nil end

  ------------------------------------------------------------------ board build
  local function clear_board()
    for r = 1, ROWS do if cells[r] then
      for c = 1, COLS do if cells[r][c] then kill_piece(cells[r][c]); cells[r][c] = nil end end
    end end
    for r = 1, ROWS do if jelly_ov[r] then
      for c = 1, COLS do if jelly_ov[r][c] then game.despawn(jelly_ov[r][c]); jelly_ov[r][c] = nil end end
    end end
    for _, e in ipairs(fx) do game.despawn(e.id) end
    fx = {}
    if glow then game.despawn(glow); glow = nil end
    if pending then pending = nil end
  end
  local function fill_board()
    clear_board()
    cells = {}; for r = 1, ROWS do cells[r] = {} end
    for r = 1, ROWS do
      for c = 1, COLS do
        local t
        repeat
          t = math.random(1, NTYPES)
          local h2 = c >= 3 and cells[r][c - 1].t == t and cells[r][c - 2].t == t
          local v2 = r >= 3 and cells[r - 1][c].t == t and cells[r - 2][c].t == t
        until not (h2 or v2)
        cells[r][c] = new_piece(t, c, r)
      end
    end
    if not has_valid_move() then return fill_board() end
  end
  local function place_jelly(n)
    jelly = {}; jelly_ov = {}
    for r = 1, ROWS do jelly[r] = {}; jelly_ov[r] = {} end
    -- fill a centered block of n cells, row by row
    local placed = 0
    for r = 3, ROWS do
      for c = 1, COLS do
        if placed < n then
          jelly[r][c] = true; placed = placed + 1
          local cx, cy = center(c, r)
          local id = game.spawn(cx, cy, psize + GAP, psize + GAP, 0.30, 0.62, 0.35, 0.45)
          jelly_ov[r][c] = id
        end
      end
    end
    jelly_left = placed
  end

  ------------------------------------------------------------------ HUD
  local function clear_hud() for _, id in ipairs(hud_ids) do game.despawn(id) end; hud_ids = {} end
  -- In-world HUD banner (garden panel + sprite icons), honouring SETTINGS.hud.
  local function hud()
    clear_hud(); game.set_text("")
    hud_on = SETTINGS.hud
    if not SETTINGS.hud then return end
    local by = HH - 98
    local function add(id) hud_ids[#hud_ids + 1] = id; return id end
    -- (no HUD backing panel — the numbers/labels carry their own outline+shadow)
    if mode == "endless" then
      add(game.spawn_sprite(-HW + 58, by, 44, 44, "gdaisy"))
      draw_number(30, by + 8, tostring(score), 36)
      add(game.spawn_text(30, by - 28, 16, 1, 0.95, 0.6, 1, "BEST " .. best_endless))
      return
    end
    local L = level_def
    -- left: level number
    add(game.spawn_text(-HW + 54, by + 18, 22, 1, 1, 1, 1, "LV"))
    draw_number(-HW + 96, by, tostring(level_idx), 28)
    -- right: moves, clearly labelled and WITHOUT a game-piece icon (a clover icon
    -- here read like a "collect clovers" goal — that was the confusion)
    draw_number(HW - 58, by + 8, tostring(math.max(moves, 0)), 32)
    add(game.spawn_text(HW - 58, by - 28, 14, 0.85, 0.9, 0.95, 1, "MOVES"))
    -- centre: the actual objective, with a word so it's obviously the goal
    local lbl, icon, prog
    if L.obj == "score" then lbl, icon, prog = "SCORE", "gdaisy", score .. "/" .. L.target
    elseif L.obj == "collect" then lbl, icon, prog = "COLLECT", TEX[L.ctype], collected .. "/" .. L.count
    else lbl, icon, prog = "CLEAR VINES", "gleaf", tostring(jelly_left) end
    add(game.spawn_text(-8, by + 28, 15, 1.0, 1.0, 0.7, 1, lbl))
    add(game.spawn_sprite(-56, by - 8, 34, 34, icon))
    draw_number(8, by - 8, prog, 28)
  end

  ------------------------------------------------------------------ resolve / cascade
  local function trigger_expand(set)
    local trig = {}; for r = 1, ROWS do trig[r] = {} end
    local fired = {}
    local changed = true
    while changed do
      changed = false
      for r = 1, ROWS do for c = 1, COLS do
        local p = cells[r][c]
        if set[r][c] and p and p.sp and not trig[r][c] then
          trig[r][c] = true; changed = true
          fired[#fired + 1] = { sp = p.sp, c = c, r = r }
          if p.sp == "row" then for cc = 1, COLS do set[r][cc] = true end
          elseif p.sp == "col" then for rr = 1, ROWS do set[rr][c] = true end
          elseif p.sp == "bomb" then
            local tt = p.payload or 0
            for rr = 1, ROWS do for cc = 1, COLS do
              if cells[rr][cc] and cells[rr][cc].t == tt then set[rr][cc] = true end
            end end
          end
        end
      end end
    end
    return fired
  end

  local function begin_resolve(seeds)
    local runs = find_runs()
    local set = {}; for r = 1, ROWS do set[r] = {} end
    for _, run in ipairs(runs) do for _, cc in ipairs(run.cells) do set[cc.r][cc.c] = true end end
    if seeds then for _, cc in ipairs(seeds) do
      if cc.c >= 1 and cc.c <= COLS and cc.r >= 1 and cc.r <= ROWS then set[cc.r][cc.c] = true end
    end end
    local any = false
    for r = 1, ROWS do for c = 1, COLS do if set[r][c] then any = true end end end
    if not any then return false end

    combo = combo + 1
    -- forge specials from 4+/5+ runs (keep one cell; never overwrite an existing
    -- special so it triggers instead, prefer a swapped cell otherwise)
    local function is_sp(cc) local p = cells[cc.r][cc.c]; return p and p.sp end
    local creates = {}
    for _, run in ipairs(runs) do
      if run.len >= 4 then
        local keep
        if swap_cells then for _, cc in ipairs(run.cells) do
          if not is_sp(cc) and ((cc.c == swap_cells[1].c and cc.r == swap_cells[1].r)
            or (cc.c == swap_cells[2].c and cc.r == swap_cells[2].r)) then keep = cc; break end
        end end
        if not keep then for _, cc in ipairs(run.cells) do if not is_sp(cc) then keep = cc end end end
        keep = keep or run.cells[math.floor((#run.cells + 1) / 2)]
        creates[keep.r] = creates[keep.r] or {}
        creates[keep.r][keep.c] = (run.len >= 5) and "bomb" or (run.horiz and "row" or "col")
      end
    end
    local fired = trigger_expand(set)
    for _, f in ipairs(fired) do beam_fx(f) end
    if #fired > 0 then game.shake(0.25); game.haptic("heavy") end
    for r = 1, ROWS do if creates[r] then for c in pairs(creates[r]) do set[r][c] = nil end end end

    local cleared = {}
    for r = 1, ROWS do for c = 1, COLS do
      if set[r][c] and cells[r][c] then cleared[#cleared + 1] = { c = c, r = r } end
    end end
    if #cleared == 0 then
      -- nothing to remove but we may still be forging a special: commit that then fall
      pending = { cleared = {}, creates = creates }
      st, timer = "clear", CLEAR_T
      return true
    end

    local gained = #cleared * 10 * combo
    score = score + gained
    if mode == "endless" and score > best_endless then best_endless = score end
    if mode ~= "endless" and level_def.obj == "collect" then
      for _, cc in ipairs(cleared) do
        if cells[cc.r][cc.c].t == level_def.ctype then collected = collected + 1 end
      end
    end
    -- feedback
    local sx, sy = 0, 0
    for _, cc in ipairs(cleared) do local x, y = center(cc.c, cc.r); sx, sy = sx + x, sy + y end
    sx, sy = sx / #cleared, sy / #cleared
    popup(sx, sy, "+" .. gained, combo > 1 and 30 or 24)
    if combo >= 2 then popup(0, board_top + 34, "COMBO x" .. combo, 34) end
    game.play_sound(combo >= 3 and "score" or "hit")
    game.haptic(combo > 1 and "success" or "light")
    game.shake(math.min(0.55, 0.10 + 0.08 * combo + 0.02 * #cleared))
    for _, cc in ipairs(cleared) do cells[cc.r][cc.c].clr = true end

    pending = { cleared = cleared, creates = creates }
    st, timer = "clear", CLEAR_T
    return true
  end

  local function do_collapse()
    for _, cc in ipairs(pending.cleared) do
      local p = cells[cc.r][cc.c]
      if p then
        burst(p.x, p.y, PAL[p.t > 0 and p.t or 1], 3)
        kill_piece(p); cells[cc.r][cc.c] = nil
      end
      if jelly[cc.r] and jelly[cc.r][cc.c] then
        jelly[cc.r][cc.c] = false; jelly_left = jelly_left - 1
        if jelly_ov[cc.r][cc.c] then game.despawn(jelly_ov[cc.r][cc.c]); jelly_ov[cc.r][cc.c] = nil end
      end
    end
    for r = 1, ROWS do if pending.creates[r] then
      for c, kind in pairs(pending.creates[r]) do
        if cells[r][c] then set_special(cells[r][c], kind) end
      end
    end end
    pending = nil
    for c = 1, COLS do
      local stack = {}
      for r = ROWS, 1, -1 do if cells[r][c] then stack[#stack + 1] = cells[r][c] end; cells[r][c] = nil end
      for i, p in ipairs(stack) do local r = ROWS - (i - 1); cells[r][c] = p; set_target(p, c, r) end
      local need = ROWS - #stack
      for r = need, 1, -1 do
        cells[r][c] = new_piece(math.random(1, NTYPES), c, r, board_top + (need - r + 1) * cell)
      end
    end
    st = "fall"
  end

  local function settled()
    for r = 1, ROWS do for c = 1, COLS do
      local p = cells[r][c]
      if p and (p.x ~= p.tx or p.y ~= p.ty) then return false end
    end end
    return true
  end

  ------------------------------------------------------------------ win / lose
  local function clear_overlay() for _, id in ipairs(ov) do game.despawn(id) end; ov = {}; buttons = {} end
  local function panel(lines, opts)
    clear_overlay()
    ov[#ov + 1] = game.spawn(0, 40, math.min(2 * HW - 40, 420), 300, 0.08, 0.12, 0.10, 0.86)
    local y = 150
    for _, ln in ipairs(lines) do ov[#ov + 1] = game.spawn_text(0, y, ln[2], 1, 1, 1, 1, ln[1]); y = y - ln[3] end
    buttons = {}
    local n = #opts
    local bw = 150
    local x0 = -(n - 1) * (bw + 20) * 0.5
    for i, o in ipairs(opts) do
      local bx = x0 + (i - 1) * (bw + 20)
      ov[#ov + 1] = game.spawn(bx, -80, bw, 66, o.c[1], o.c[2], o.c[3], 1)
      ov[#ov + 1] = game.spawn_text(bx, -80, 26, 1, 1, 1, 1, o.label)
      buttons[#buttons + 1] = { x = bx, y = -80, w = bw, h = 66, act = o.act }
    end
  end
  local function celebrate()
    for i = 1, 26 do
      local x = (i / 26 - 0.5) * 2 * HW * 0.9
      burst(x, board_top - math.random(0, ROWS) * cell, PAL[math.random(1, NTYPES)], 2)
    end
  end

  local show_start, show_map, start_level, start_endless, set_debug_play  -- forward decls

  local function win()
    over, won = true, true
    game.play_sound("score"); game.haptic("success"); game.shake(0.7); game.log("win")
    celebrate()
    if mode == "endless" then
      panel({ { "GARDEN FULL!", 40, 52 }, { "SCORE " .. score, 28, 44 } },
        { { label = "AGAIN", c = { 0.3, 0.6, 0.4 }, act = "endless" }, { label = "MENU", c = { 0.5, 0.4, 0.4 }, act = "menu" } })
      return
    end
    local left = math.max(moves, 0)
    local stars = 1 + (left > 0 and 1 or 0) + (left >= level_def.moves * 0.3 and 1 or 0)
    progress.unlocked = math.max(progress.unlocked, math.min(level_idx + 1, #LEVELS))
    progress.stars[level_idx] = math.max(progress.stars[level_idx] or 0, stars)
    local starstr = string.rep("*", stars) .. string.rep(".", 3 - stars)
    local opts = { { label = "MAP", c = { 0.4, 0.5, 0.7 }, act = "map" } }
    if level_idx < #LEVELS then opts[#opts + 1] = { label = "NEXT", c = { 0.3, 0.65, 0.4 }, act = "next" } end
    panel({ { "LEVEL " .. level_idx .. " CLEAR", 36, 50 }, { starstr, 40, 46 }, { "SCORE " .. score, 24, 40 } }, opts)
  end
  local function lose()
    over = true
    game.play_sound("hit"); game.haptic("heavy"); game.shake(0.5); game.log("lose")
    panel({ { "OUT OF MOVES", 36, 52 }, { "SCORE " .. score, 26, 44 } },
      { { label = "MAP", c = { 0.4, 0.5, 0.7 }, act = "map" }, { label = "RETRY", c = { 0.65, 0.4, 0.4 }, act = "retry" } })
  end

  local function reshuffle() fill_board(); game.play_sound("wall"); game.shake(0.2); hud() end
  local function objective_met()
    if mode == "endless" then return false end
    local L = level_def
    if L.obj == "score" then return score >= L.target
    elseif L.obj == "collect" then return collected >= L.count
    elseif L.obj == "jelly" then return jelly_left <= 0 end
    return false
  end
  local function end_of_move()
    idle_timer = 0
    if over then return end
    if objective_met() then win()
    elseif mode ~= "endless" and moves <= 0 then lose()
    elseif not has_valid_move() then reshuffle() end
  end

  local function spend_move() if mode ~= "endless" then moves = moves - 1 end; hud() end

  local function begin_swap(c1, r1, c2, r2)
    if st ~= "idle" or over or screen ~= "play" then return end
    if math.abs(c1 - c2) + math.abs(r1 - r2) ~= 1 then return end
    local pa, pb = cells[r1][c1], cells[r2][c2]
    if not pa or not pb then return end
    local seeds = nil
    if pa.sp or pb.sp then
      seeds = {}
      local function line(kind, c, r)
        if kind == "row" then for cc = 1, COLS do seeds[#seeds + 1] = { c = cc, r = r } end
        elseif kind == "col" then for rr = 1, ROWS do seeds[#seeds + 1] = { c = c, r = rr } end end
      end
      local function allof(t) for rr = 1, ROWS do for cc = 1, COLS do
        if cells[rr][cc] and cells[rr][cc].t == t then seeds[#seeds + 1] = { c = cc, r = rr } end
      end end end
      if pa.sp == "bomb" and pb.sp == "bomb" then
        for rr = 1, ROWS do for cc = 1, COLS do seeds[#seeds + 1] = { c = cc, r = rr } end end
      elseif pa.sp == "bomb" then allof(pb.t); seeds[#seeds + 1] = { c = c1, r = r1 }; if pb.sp then line(pb.sp, c2, r2) end
      elseif pb.sp == "bomb" then allof(pa.t); seeds[#seeds + 1] = { c = c2, r = r2 }; if pa.sp then line(pa.sp, c1, r1) end
      else
        if pa.sp then line(pa.sp, c1, r1) end
        if pb.sp then line(pb.sp, c2, r2) end
        seeds[#seeds + 1] = { c = c1, r = r1 }; seeds[#seeds + 1] = { c = c2, r = r2 }
      end
      cells[r1][c1], cells[r2][c2] = pb, pa
      set_target(cells[r1][c1], c1, r1); set_target(cells[r2][c2], c2, r2)
    else
      cells[r1][c1], cells[r2][c2] = pb, pa
      if not any_match() then
        -- animate the swap, then bounce back so the illegal move reads clearly
        set_target(cells[r1][c1], c1, r1); set_target(cells[r2][c2], c2, r2)
        bounce = { c1 = c1, r1 = r1, c2 = c2, r2 = r2 }
        sel = nil
        game.play_sound("wall"); game.haptic("light")
        st, timer = "bounce", SWAP_T
        return
      end
      set_target(cells[r1][c1], c1, r1); set_target(cells[r2][c2], c2, r2)
    end
    swap_cells = { { c = c1, r = r1 }, { c = c2, r = r2 } }
    next_seeds = seeds
    spend_move(); combo = 0; idle_timer = 0
    game.play_sound("hit"); game.haptic("light")
    st, timer = "swap", SWAP_T
  end

  ------------------------------------------------------------------ screens
  local function set_bg_image(name)
    if bg_img then game.despawn(bg_img) end
    -- Overshoot the reported bounds so the backdrop covers the viewport with a
    -- little margin; the thin iOS safe-area strip is filled by a theme-matched
    -- window colour on the native side (see ios/Sources/haptics.m).
    bg_img = game.spawn_sprite(0, 0, 2 * HW + 120, 2 * HH + 360, name)
    game.set_color(bg_img, 1, 1, 1, 0.86)   -- slightly translucent so the aurora/motes show through
  end
  -- A "garden plot" board: a dark frame + a soft two-tone green checkerboard of
  -- planting cells (semi-transparent so the backdrop shows through).
  local function draw_board()
    local cy = board_top - ROWS * cell * 0.5
    T.spawn(0, cy, COLS * cell + 22, ROWS * cell + 22, 0.05, 0.09, 0.07, 0.6)
    for r = 1, ROWS do
      for c = 1, COLS do
        local cx, ccy = center(c, r)
        if (c + r) % 2 == 0 then T.spawn(cx, ccy, cell, cell, 0.24, 0.46, 0.29, 0.5)
        else T.spawn(cx, ccy, cell, cell, 0.17, 0.37, 0.23, 0.5) end
      end
    end
  end
  -- Ambient garden life: drifting petals + fluttering butterflies over the
  -- backdrop, on every Gem Match screen, so the garden feels alive.
  local function spawn_ambient()
    for _, a in ipairs(amb) do game.despawn(a.id) end; amb = {}
    for _ = 1, 7 do
      local id = game.spawn_sprite(0, 0, 22, 22, "petal"); game.set_color(id, 1, 1, 1, 0.7)
      amb[#amb + 1] = { id = id, kind = "petal", x = (math.random() * 2 - 1) * HW,
        y = (math.random() * 2 - 1) * HH, vx = -12 - math.random() * 12, vy = -22 - math.random() * 18,
        phase = math.random() * 6.28, amp = 8 + math.random() * 14 }
    end
    for i = 1, 2 do
      local id = game.spawn_sprite(0, 0, 40, 35, i == 1 and "butterfly1" or "butterfly2")
      amb[#amb + 1] = { id = id, kind = "fly", x = (math.random() * 2 - 1) * HW,
        y = HH * (0.2 + math.random() * 0.5), vx = (i == 1 and 1 or -1) * (34 + math.random() * 22),
        phase = math.random() * 6.28 }
    end
  end
  local function update_ambient(dt)
    for _, a in ipairs(amb) do
      if a.kind == "petal" then
        a.x = a.x + a.vx * dt; a.y = a.y + a.vy * dt
        if a.y < -HH - 24 then a.y = HH + 24; a.x = (math.random() * 2 - 1) * HW end
        if a.x < -HW - 24 then a.x = HW + 24 end
        game.move_to(a.id, a.x + math.sin(clock * 1.5 + a.phase) * a.amp, a.y)
      else
        a.x = a.x + a.vx * dt
        if a.x > HW + 44 then a.x = -HW - 44 elseif a.x < -HW - 44 then a.x = HW + 44 end
        game.move_to(a.id, a.x, a.y + math.sin(clock * 3 + a.phase) * 14)
      end
    end
  end
  -- Rebuild-time reset: clears entities AND the transient play state, so
  -- re-entering the scene (or switching screens) never inherits a stale
  -- over/st that would swallow the mode-select taps.
  local function reset_scene()
    clear_overlay(); clear_board(); clear_hud(); T.clear()
    for _, a in ipairs(amb) do game.despawn(a.id) end; amb = {}
    if bg_img then game.despawn(bg_img); bg_img = nil end
    over, won, st, hud_on = false, false, "idle", nil
    press, sel, bounce, pending, next_seeds, swap_cells, combo = nil, nil, nil, nil, nil, nil, 0
  end

  -- Full DEBUG surface while playing, so tests can drive the board directly.
  function set_debug_play()
    DEBUG = {
      game = "match3", screen = "play", back = back, cols = COLS, rows = ROWS,
      start = function(m, l) if m == "endless" then start_endless() else start_level(l or 1) end end,
      get = function(c, r) local p = cells[r] and cells[r][c]; return p and p.t or 0 end,
      special = function(c, r) local p = cells[r] and cells[r][c]; return p and p.sp or nil end,
      setcell = function(c, r, t)
        local p = cells[r][c]
        if p then p.t = t; p.sp = nil; if p.mark then game.despawn(p.mark); p.mark = nil end end
      end,
      setspecial = function(c, r, kind) local p = cells[r][c]; if p then set_special(p, kind) end end,
      score = function() return score end,
      moves = function() return moves end,
      collected = function() return collected end,
      jelly_left = function() return jelly_left end,
      busy = function() return st ~= "idle" end,
      over = function() return over end,
      won = function() return won end,
      mode = function() return mode end,
      swap = function(a, b, c, d) begin_swap(a, b, c, d) end,
      find_move = function() return find_move() end,
      center = function(c, r) return center(c, r) end,
      set_target_score = function(n) if level_def then level_def.target = n end; hud() end,
      set_moves = function(n) moves = n; hud() end,
    }
  end

  function start_level(idx)
    reset_scene()
    local L = LEVELS[idx]
    level_def = { obj = L.obj, target = L.target, ctype = L.ctype, count = L.count, jelly = L.jelly, moves = L.moves }
    mode, level_idx = "adventure", idx
    screen = "play"
    score, collected, over, won, combo, st = 0, 0, false, false, 0, "idle"
    moves = level_def.moves
    set_bg_image(level_bg(idx)); spawn_ambient()
    draw_board()
    fill_board()
    if level_def.obj == "jelly" then place_jelly(level_def.jelly) else jelly, jelly_ov, jelly_left = {}, {}, 0 end
    glow = game.spawn_sprite(0, -9999, cell, cell, "sparkle"); game.set_color(glow, 1, 1, 1, 0)
    back = K.make_back(T, HW, HH)
    hud(); set_debug_play()
  end
  function start_endless()
    reset_scene()
    mode, level_def = "endless", nil
    screen = "play"
    score, collected, over, won, combo, st = 0, 0, false, false, 0, "idle"
    moves, jelly, jelly_ov, jelly_left = 0, {}, {}, 0
    set_bg_image(BG[1]); spawn_ambient()
    draw_board()
    fill_board()
    glow = game.spawn_sprite(0, -9999, cell, cell, "sparkle"); game.set_color(glow, 1, 1, 1, 0)
    back = K.make_back(T, HW, HH)
    hud(); set_debug_play()
  end

  function show_map()
    reset_scene(); screen = "map"; game.set_text(""); set_bg_image(BG[1]); spawn_ambient()
    T.text(0, HH - 128, 40, 1, 1, 1, 1, "GARDEN MAP")

    -- Level nodes wind up a serpentine garden path from bottom to top.
    local n = #LEVELS
    local top_y, bot_y = HH - 220, -HH + 150
    local step = (top_y - bot_y) / (n - 1)
    local nodes = {}
    for i = 1, n do nodes[i] = { x = math.sin((i - 1) * 0.9) * HW * 0.46, y = bot_y + (i - 1) * step } end

    -- ambient garden decorations along the sides
    T.sprite(-HW * 0.72, bot_y + step * 0.4, 58, 74, "tree")
    T.sprite(HW * 0.74, bot_y + step * 1.6, 40, 40, "flower")
    T.sprite(-HW * 0.7, top_y - step * 0.5, 40, 40, "gmush")
    T.sprite(HW * 0.66, top_y - step * 1.4, 46, 36, "rock")
    T.sprite(HW * 0.7, bot_y + step * 0.2, 40, 40, "gviola")

    -- dotted path connecting the nodes (gold where already reachable)
    for i = 1, n - 1 do
      local a, b = nodes[i], nodes[i + 1]
      local dc = (i < progress.unlocked) and { 0.96, 0.86, 0.4 } or { 0.55, 0.58, 0.55 }
      for k = 1, 4 do
        local t = k / 5
        T.spawn(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t, 9, 9, dc[1], dc[2], dc[3], 0.9)
      end
    end

    buttons = {}
    for i = 1, n do
      local nd = nodes[i]
      local unlocked = i <= progress.unlocked
      local done = (progress.stars[i] or 0) > 0
      local ring = unlocked and { 0.34, 0.70, 0.42 } or { 0.30, 0.33, 0.36 }
      T.spawn(nd.x, nd.y, 76, 76, ring[1], ring[2], ring[3], 0.96)
      T.sprite(nd.x, nd.y + 4, 48, 48, unlocked and (done and "gdaisy" or "gleaf") or "rock")
      T.text(nd.x, nd.y - 6, 26, 1, 1, 1, 1, unlocked and tostring(i) or "-")
      if unlocked then
        local s = progress.stars[i] or 0
        T.text(nd.x, nd.y - 44, 16, 1, 0.9, 0.4, 1, string.rep("*", s) .. string.rep(".", 3 - s))
        buttons[#buttons + 1] = { x = nd.x, y = nd.y, w = 76, h = 76, act = "lvl" .. i }
      end
    end
    back = K.make_back(T, HW, HH)
    DEBUG.screen = "map"; DEBUG.back = back
  end

  function show_start()
    reset_scene(); screen = "start"; mode = "adventure"; game.set_text(""); set_bg_image(BG[1]); spawn_ambient()
    T.text(0, HH - 150, 46, 1, 1, 1, 1, "GARDEN MATCH")
    T.text(0, HH - 210, 20, 0.85, 0.95, 0.8, 1, "Match blooms to clear the vines")
    T.text(0, HH - 240, 18, 0.8, 0.9, 0.75, 1, "and restore the enchanted garden")
    buttons = {}
    local defs = { { "ADVENTURE", "adv", { 0.30, 0.62, 0.40 } }, { "ENDLESS", "end", { 0.36, 0.50, 0.66 } } }
    local y = 40
    for _, d in ipairs(defs) do
      T.spawn(0, y, 300, 84, d[3][1], d[3][2], d[3][3], 1)
      T.text(0, y, 32, 1, 1, 1, 1, d[1])
      buttons[#buttons + 1] = { x = 0, y = y, w = 300, h = 84, act = d[2] }
      y = y - 108
    end
    back = K.make_back(T, HW, HH)
    DEBUG.screen = "start"; DEBUG.back = back
  end

  ------------------------------------------------------------------ play update
  local function update_play(dt)
    if hud_on ~= SETTINGS.hud then hud() end   -- react to a live Settings toggle
    -- animate pieces
    local k = math.min(1, dt * LERP)
    local idle = (st == "idle" and not over)
    for r = 1, ROWS do
      for c = 1, COLS do
        local p = cells[r][c]
        if p then
          p.x = p.x + (p.tx - p.x) * k; p.y = p.y + (p.ty - p.y) * k
          if math.abs(p.tx - p.x) < 0.5 then p.x = p.tx end
          if math.abs(p.ty - p.y) < 0.5 then p.y = p.ty end
          p.ox = p.ox * (1 - math.min(1, dt * 12)); p.oy = p.oy * (1 - math.min(1, dt * 12))
          p.pop = math.max(0, p.pop - dt * 3)
          local bob = idle and math.sin(clock * 2.2 + p.phase) * 2.0 or 0
          local rx, ry = p.x + p.ox, p.y + p.oy + bob
          game.move_to(p.id, rx, ry)
          if p.mark then
            game.move_to(p.mark, rx, ry)
            if p.sp == "bomb" then
              local ms = psize * 0.72 * (1 + 0.16 * math.sin(clock * 6 + p.phase))
              game.set_size(p.mark, ms, ms)
            else
              game.set_color(p.mark, 1.0, 0.85, 0.35, 0.55 + 0.40 * math.abs(math.sin(clock * 5 + p.phase)))
            end
          end
          local ds = psize * p.s * (1 + 0.18 * p.pop)
          game.set_size(p.id, ds, ds)
        end
      end
    end
    -- clearing shrink
    if pending then for _, cc in ipairs(pending.cleared) do
      local p = cells[cc.r][cc.c]; if p then p.s = math.max(0, p.s - dt / CLEAR_T) end
    end end

    -- input: swipe
    if idle then
      local px, py, down = game.pointer()
      if down and px and py then
        if not press then
          local c, r = to_cell(px, py)
          if c then press = { c = c, r = r, x = px, y = py, done = false } end
        elseif not press.done then
          local dx, dy = px - press.x, py - press.y
          if math.abs(dx) > cell * 0.35 or math.abs(dy) > cell * 0.35 then
            local nc, nr = press.c, press.r
            if math.abs(dx) > math.abs(dy) then nc = press.c + (dx > 0 and 1 or -1)
            else nr = press.r + (dy > 0 and -1 or 1) end
            press.done = true; sel = nil
            if nc >= 1 and nc <= COLS and nr >= 1 and nr <= ROWS then begin_swap(press.c, press.r, nc, nr) end
          end
        end
      else press = nil end
    end
    -- highlight glow: the selected cell (tap) or the finger's cell (swipe)
    if glow then
      local hc = sel or (press and { c = press.c, r = press.r })
      if hc then
        local gx, gy = center(hc.c, hc.r); game.move_to(glow, gx, gy); game.set_size(glow, cell, cell)
        game.set_color(glow, 1, 1, 1, 0.35 + 0.25 * math.abs(math.sin(clock * 4)))
      else game.set_color(glow, 1, 1, 1, 0) end
    end

    -- state machine
    if st == "swap" then
      timer = timer - dt
      if timer <= 0 then
        local s = next_seeds; next_seeds = nil
        if not begin_resolve(s) then st = "idle"; end_of_move() end
        swap_cells = nil
      end
    elseif st == "clear" then
      timer = timer - dt; if timer <= 0 then do_collapse() end
    elseif st == "fall" then
      if settled() then if not begin_resolve(nil) then st = "idle"; end_of_move() end end
    elseif st == "bounce" then
      timer = timer - dt
      if timer <= 0 then
        local b = bounce
        cells[b.r1][b.c1], cells[b.r2][b.c2] = cells[b.r2][b.c2], cells[b.r1][b.c1]
        set_target(cells[b.r1][b.c1], b.c1, b.r1); set_target(cells[b.r2][b.c2], b.c2, b.r2)
        st, timer = "bounceback", SWAP_T
      end
    elseif st == "bounceback" then
      timer = timer - dt; if timer <= 0 then st = "idle"; bounce = nil end
    end

    -- anticipation hint after idle
    if idle then
      idle_timer = idle_timer + dt
      if idle_timer >= HINT_T then
        idle_timer = HINT_T - 1.2
        local c1, r1, c2, r2 = find_move()
        if c1 and cells[r1][c1] then cells[r1][c1].pop = 1; if cells[r2][c2] then cells[r2][c2].pop = 1 end end
      end
    end
  end

  ------------------------------------------------------------------ scene interface
  return {
    enter = function() screen = nil; game.set_bg_theme(1); game.play_music("garden")
      DEBUG = { game = "match3", start = function(m, l)
        if m == "endless" then start_endless() else start_level(l or 1) end
      end } end,
    leave = function() reset_scene(); screen = nil; game.play_music("music") end,
    tap = function(x, y)
      if back and inr(back, x, y) then
        if screen == "play" and mode == "adventure" then show_map()
        elseif screen == "play" then show_start()
        elseif screen == "map" then show_start()
        else K.switch("menu") end
        return
      end
      if over then
        for _, b in ipairs(buttons) do if inr(b, x, y) then
          local a = b.act
          if a == "menu" then K.switch("menu")
          elseif a == "map" then show_map()
          elseif a == "endless" then start_endless()
          elseif a == "retry" then start_level(level_idx)
          elseif a == "next" then start_level(math.min(level_idx + 1, #LEVELS)) end
          return
        end end
        return
      end
      if screen == "start" then
        for _, b in ipairs(buttons) do if inr(b, x, y) then
          if b.act == "adv" then show_map() elseif b.act == "end" then start_endless() end
          game.play_sound("hit"); game.haptic("light"); return
        end end
      elseif screen == "map" then
        for _, b in ipairs(buttons) do if inr(b, x, y) then
          local n = tonumber(b.act:match("lvl(%d+)")); if n then start_level(n) end
          game.play_sound("hit"); game.haptic("light"); return
        end end
      elseif screen == "play" and st == "idle" then
        -- tap-to-select: tap a bloom, then an adjacent one to swap (illegal
        -- swaps animate and bounce back). Complements swipe.
        local c, r = to_cell(x, y)
        if c then
          if sel and sel.c == c and sel.r == r then sel = nil
          elseif sel and math.abs(sel.c - c) + math.abs(sel.r - r) == 1 then
            local s = sel; sel = nil; begin_swap(s.c, s.r, c, r)
          else sel = { c = c, r = r }; game.play_sound("hit"); game.haptic("light") end
        end
      end
    end,
    update = function(dt, hw, hh)
      HW, HH = hw, hh
      clock = clock + dt
      if cell == 0 then
        local top_y, bot_y = hh - TOP_PAD, -hh + BOT_PAD
        cell = math.min((2 * hw - 2 * SIDE) / COLS, (top_y - bot_y) / ROWS)
        psize = cell - GAP
        local bh = ROWS * cell
        board_left = -COLS * cell * 0.5
        board_top = (top_y + bot_y) * 0.5 + bh * 0.5
      end
      if screen == nil then game.set_bg_theme(1); show_start() end
      dt = math.min(dt, MAX_DT)
      if screen == "play" then update_play(dt) end
      update_ambient(dt)
      update_fx(dt)
    end,
  }
end

-- Self-register this game pack (see main.lua: menu builds from PACKS).
PACKS = PACKS or {}
PACKS["match3"] = { slot = 8, key = "match3", label = "Gem Match", short = "Gem Match", icon = "gdaisy", color = { 0.55, 0.75, 0.42 }, tier = "curated", make = make_match3 }
