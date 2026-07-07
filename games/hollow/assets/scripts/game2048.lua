-- game2048.lua — a polished 2048 puzzle, loaded from its own file.
--
-- Registers the global factory make_2048 (main.lua adds it to the menu). Swipe
-- (or arrow keys) to slide all tiles; equal tiles merge and double. A new 2 (or
-- 4) appears after each move. Fill the board with no moves left = game over.
-- Uses GAME_KIT (shared helpers) + the `game` bridge.

function make_2048()
  local K = GAME_KIT
  local clamp, inr = K.clamp, K.in_rect
  local T = K.tracker()

  -- Classic 2048 tile colours (the white "tile" texture is tinted to these).
  local COLORS = {
    [2] = { 0.93, 0.89, 0.85 }, [4] = { 0.94, 0.88, 0.78 },
    [8] = { 0.95, 0.69, 0.47 }, [16] = { 0.96, 0.58, 0.39 },
    [32] = { 0.96, 0.49, 0.37 }, [64] = { 0.96, 0.37, 0.23 },
    [128] = { 0.93, 0.81, 0.45 }, [256] = { 0.93, 0.80, 0.38 },
    [512] = { 0.93, 0.78, 0.31 }, [1024] = { 0.93, 0.77, 0.25 },
    [2048] = { 0.94, 0.76, 0.18 },
  }
  local BG = { 0.17, 0.16, 0.15 }
  local EMPTY = { 0.24, 0.23, 0.21 }

  local back, board, score, playing, built = nil, {}, 0, true, false
  local board_size, gap, cell = 0, 14, 0
  local tile_ids = {}
  local prev_down, drag_start, moved_touch = false, nil, false
  local prev_keys = {}

  local function cell_xy(r, c)
    local half = board_size * 0.5
    return -half + gap + (c - 1) * (cell + gap) + cell * 0.5,
           half - gap - (r - 1) * (cell + gap) - cell * 0.5
  end
  local function hud() game.set_text(string.format("SCORE  %d", score)) end

  local function render()
    for _, id in ipairs(tile_ids) do game.despawn(id) end
    tile_ids = {}
    for r = 1, 4 do
      for c = 1, 4 do
        local v = board[r][c]
        if v > 0 then
          local x, y = cell_xy(r, c)
          local col = COLORS[v] or { 0.24, 0.22, 0.20 }
          local sid = game.spawn_sprite(x, y, cell, cell, "tile")
          game.set_color(sid, col[1], col[2], col[3], 1)
          tile_ids[#tile_ids + 1] = sid
          local dark = v <= 4
          local digits = #tostring(v)
          local size = cell * (digits <= 2 and 0.5 or (digits == 3 and 0.38 or 0.3))
          local tr, tg, tb = 1, 1, 1
          if dark then tr, tg, tb = 0.42, 0.39, 0.35 end
          tile_ids[#tile_ids + 1] = game.spawn_text(x, y, size, tr, tg, tb, 1, tostring(v))
        end
      end
    end
  end

  local function spawn_random()
    local empties = {}
    for r = 1, 4 do
      for c = 1, 4 do
        if board[r][c] == 0 then empties[#empties + 1] = { r, c } end
      end
    end
    if #empties == 0 then return end
    local e = empties[math.random(1, #empties)]
    board[e[1]][e[2]] = (math.random() < 0.9) and 2 or 4
  end

  local function can_move()
    for r = 1, 4 do
      for c = 1, 4 do
        if board[r][c] == 0 then return true end
        if c < 4 and board[r][c] == board[r][c + 1] then return true end
        if r < 4 and board[r][c] == board[r + 1][c] then return true end
      end
    end
    return false
  end

  -- Slide one 4-cell line toward index 1, merging equal neighbours once.
  local function slide(line)
    local packed = {}
    for _, v in ipairs(line) do if v ~= 0 then packed[#packed + 1] = v end end
    local res, i, merged = {}, 1, false
    while i <= #packed do
      if packed[i + 1] == packed[i] then
        res[#res + 1] = packed[i] * 2; score = score + packed[i] * 2
        i = i + 2; merged = true
      else
        res[#res + 1] = packed[i]; i = i + 1
      end
    end
    while #res < 4 do res[#res + 1] = 0 end
    return res, merged
  end

  local function game_over()
    playing = false
    game.set_text(string.format("GAME OVER\nSCORE %d\nTap to restart", score))
    game.play_sound("hit"); game.haptic("heavy"); game.shake(0.4); game.log("lose")
  end

  -- get(i,j)/set(i,j,v) map a line index i (1..4) and position j (1..4, from the
  -- slide origin) onto the board for the given direction.
  local function do_move(get, set)
    local moved, any_merge = false, false
    for i = 1, 4 do
      local line = {}
      for j = 1, 4 do line[j] = get(i, j) end
      local slid, merged = slide(line)
      any_merge = any_merge or merged
      for j = 1, 4 do
        if slid[j] ~= line[j] then moved = true end
        set(i, j, slid[j])
      end
    end
    return moved, any_merge
  end

  local function try_move(dir)
    if not playing then return end
    local moved, merged
    if dir == "left" then
      moved, merged = do_move(function(i, j) return board[i][j] end,
        function(i, j, v) board[i][j] = v end)
    elseif dir == "right" then
      moved, merged = do_move(function(i, j) return board[i][5 - j] end,
        function(i, j, v) board[i][5 - j] = v end)
    elseif dir == "up" then
      moved, merged = do_move(function(i, j) return board[j][i] end,
        function(i, j, v) board[j][i] = v end)
    elseif dir == "down" then
      moved, merged = do_move(function(i, j) return board[5 - j][i] end,
        function(i, j, v) board[5 - j][i] = v end)
    end
    if moved then
      spawn_random(); render(); hud()
      game.play_sound(merged and "score" or "hit")
      game.haptic("light")
      if merged then game.shake(0.06) end
      if not can_move() then game_over() end
    end
  end

  local function build(hw, hh)
    board_size = math.min(2 * hw - 44, 2 * hh * 0.62, 460)
    cell = (board_size - 5 * gap) / 4
    T.spawn(0, 0, board_size, board_size, BG[1], BG[2], BG[3], 1)
    for r = 1, 4 do
      for c = 1, 4 do
        local x, y = cell_xy(r, c)
        T.spawn(x, y, cell, cell, EMPTY[1], EMPTY[2], EMPTY[3], 1)
      end
    end
    back = K.make_back(T, hw, hh)
    board = {}
    for r = 1, 4 do board[r] = { 0, 0, 0, 0 } end
    score, playing = 0, true
    spawn_random(); spawn_random(); render(); hud()
    built = true
    DEBUG = {
      game = "game2048", back = back,
      score = function() return score end, alive = function() return playing end,
      board = function() return board end,
      move = function(d) try_move(d) end,
    }
  end

  return {
    enter = function() built = false end,
    leave = function()
      for _, id in ipairs(tile_ids) do game.despawn(id) end
      tile_ids = {}; T.clear(); built = false
    end,
    tap = function(x, y)
      if back and inr(back, x, y) then K.switch("menu"); return end
      if not playing then
        for _, id in ipairs(tile_ids) do game.despawn(id) end
        tile_ids = {}; T.clear(); build(game.bounds()); return
      end
    end,
    update = function(_, hw, hh)
      if not built then build(hw, hh) end
      if not playing then return end
      -- Swipe: one move per gesture once the drag passes a threshold.
      local px, py, down = game.pointer()
      if down and not prev_down then drag_start = { x = px or 0, y = py or 0 }; moved_touch = false end
      if down and not moved_touch and px ~= nil and drag_start then
        local dx, dy = px - drag_start.x, py - drag_start.y
        if math.abs(dx) > 28 or math.abs(dy) > 28 then
          if math.abs(dx) > math.abs(dy) then try_move(dx > 0 and "right" or "left")
          else try_move(dy > 0 and "up" or "down") end
          moved_touch = true
        end
      end
      prev_down = down
      -- Arrow keys: one move per key press (rising edge).
      for _, k in ipairs({ "up", "down", "left", "right" }) do
        local now = game.key(k)
        if now and not prev_keys[k] then try_move(k) end
        prev_keys[k] = now
      end
    end,
  }
end

-- Self-register this game pack (see main.lua: menu builds from PACKS).
PACKS = PACKS or {}
PACKS["game2048"] = { slot = 5, key = "game2048", label = "2048", short = "2048", icon = "gem", color = { 0.95, 0.68, 0.35 }, tier = "preset", make = make_2048 }
