-- showcase.lua — "ENGINE SHOWCASE": every bridge capability as a playable
-- station, and every station has a BENCH mode that pressure-tests exactly that
-- capability (ramping load until the frame time degrades, then freezing a
-- score). Best scores persist via game.save — so the benchmark suite itself
-- exercises the persistence capability it demonstrates.
--
-- Stations (key → capability under test):
--   vault  game.save / game.load           persistent coin counter + score board
--   touch  game.touches                    multi-finger visualizer / follower swarm
--   atlas  game.spawn_sheet / set_frame    animated sprite-sheet wall
--   camera game.cam                        drone tour over a big world, follow+zoom
--   mixer  game.set_volume / stop_music    live 3-channel mixing desk
--   sparks game.emit                       fireworks / 512-cap stress
--   tiles  game.tilemap / set_tile         paintable map / full-map rewrite storm
--   robot  game.spawn_rig / play_anim / set_bone   rig stage / rig crowd
--   juice  game.track + shake/zoom/haptic  effects lab, every press tracked
--
-- Talks to the host ONLY through `game` + GAME_KIT (see tools/PACK_SPEC.md).

function make_showcase()
  local K = GAME_KIT
  local clamp, inr = K.clamp, K.in_rect
  local T = K.tracker()

  -- Entities the tracker can't make (sheets / tilemaps / rigs) are tracked
  -- here and despawned on every station switch and on leave.
  local extra = {}
  local function xkeep(id) extra[#extra + 1] = id; return id end
  local function clear_extra()
    for _, id in ipairs(extra) do game.despawn(id) end
    extra = {}
  end

  local HW, HH = 0, 0
  local back, built = nil, false
  local station = nil          -- nil = hub
  local hub_cards = {}         -- tap targets on the hub
  local buttons = {}           -- tap targets inside a station
  local time = 0
  local enter_station          -- forward-declared; defined after the stations

  -- math.random demands integers; screen half-extents can be fractional
  -- (e.g. 196.5 on a 393pt device), so floor every derived bound.
  local function rnd(a, b) return math.random(math.floor(a), math.floor(b)) end

  ----------------------------------------------------------------------------
  -- Benchmark harness (shared by all stations)
  --
  -- While ON, sample dt into a sliding window; every EPOCH seconds, if the
  -- average frame is still under BUDGET the load level ramps up one step, and
  -- the station's update reads `bench.level` to add load. The first epoch that
  -- blows the budget freezes the score at the last sustained level. LEVEL_CAP
  -- keeps headless runs (fixed dt) finite.
  ----------------------------------------------------------------------------
  -- The budget adapts to the device: the first epoch runs load-free and
  -- measures the resting frame time; the pass bar is 1.4x that (never
  -- stricter than 1/45s). A 120Hz phone and a software rasterizer both get a
  -- meaningful ramp instead of an instant fail or a free ride.
  local MIN_BUDGET, EPOCH, WINDOW, LEVEL_CAP = 1 / 45, 0.75, 45, 12
  local bench = { on = false, level = 0, timer = 0, dts = {}, score = nil, budget = nil }

  local function bench_reset()
    bench.on, bench.level, bench.timer, bench.dts, bench.score, bench.budget =
      false, 0, 0, {}, nil, nil
  end

  local function bench_best_key(k) return "sc_bench_" .. k end

  local function bench_tick(dt)
    if not bench.on or bench.score then return end
    bench.timer = bench.timer + dt
    bench.dts[#bench.dts + 1] = dt
    if #bench.dts > WINDOW then table.remove(bench.dts, 1) end
    if bench.timer < EPOCH then return end
    bench.timer = 0
    local sum = 0
    for _, d in ipairs(bench.dts) do sum = sum + d end
    local avg = sum / math.max(1, #bench.dts)
    if not bench.budget then -- first epoch: calibrate, don't judge
      bench.budget = math.max(MIN_BUDGET, avg * 1.4)
      return
    end
    if avg <= bench.budget and bench.level < LEVEL_CAP then
      bench.level = bench.level + 1
      game.play_sound("wall")
    else
      bench.score = bench.level
      local key = bench_best_key(station)
      local best = game.load(key)
      if type(best) ~= "number" or bench.score > best then
        game.save(key, bench.score)
        game.play_sound("score"); game.haptic("success")
      end
      game.track("bench_" .. station, bench.score)
    end
  end

  ----------------------------------------------------------------------------
  -- Small UI helpers
  ----------------------------------------------------------------------------
  local function button(x, y, w, h, label, tint, action)
    local id = T.sprite(x, y, w, h, "rcard")
    if tint then game.set_color(id, tint[1], tint[2], tint[3], 1) end
    T.text(x, y, 22, 1, 1, 1, 1, label)
    buttons[#buttons + 1] = { x = x, y = y, w = w, h = h, action = action }
  end

  local function hub_button(y_off)
    button(HW - 84, HH - 152, 120, 66, "HUB", { 0.45, 0.5, 0.62 }, function()
      enter_station(nil)
    end)
  end

  local function bench_button()
    button(HW - 84, HH - 236, 120, 60, "BENCH", { 0.85, 0.55, 0.25 }, function()
      if bench.on then bench_reset() else bench.on = true end
      game.play_sound("hit")
    end)
  end

  ----------------------------------------------------------------------------
  -- Stations
  ----------------------------------------------------------------------------
  local stations = {}
  local order = { "vault", "touch", "atlas", "camera", "mixer", "sparks", "tiles", "robot", "juice" }
  local NAMES = {
    vault = "VAULT", touch = "TOUCH", atlas = "ATLAS", camera = "CAMERA",
    mixer = "MIXER", sparks = "SPARKS", tiles = "TILES", robot = "ROBOT", juice = "JUICE",
  }
  local CARD_TINT = {
    vault = { 0.95, 0.8, 0.3 }, touch = { 0.4, 0.8, 1.0 }, atlas = { 1.0, 0.75, 0.35 },
    camera = { 0.55, 0.9, 0.6 }, mixer = { 0.8, 0.6, 1.0 }, sparks = { 1.0, 0.5, 0.45 },
    tiles = { 0.5, 0.85, 0.5 }, robot = { 1.0, 0.62, 0.3 }, juice = { 0.95, 0.55, 0.75 },
  }
  local ICONS = {
    vault = "icon_coin", touch = "icon_eye", atlas = "icon_clock", camera = "icon_find",
    mixer = "icon_bulb", sparks = "icon_bolt", tiles = "gleaf", robot = "hero", juice = "icon_heart",
  }

  -- ------------------------------------------------------------------ vault
  stations.vault = (function()
    local coins, ops, errs = 0, 0, 0
    return {
      hint = "tap the coin to bank it - it survives restarts",
      build = function()
        coins = game.load("sc_coins") or 0
        local visits = (game.load("sc_visits") or 0) + 1
        game.save("sc_visits", visits)
        T.text(0, HH - 320, 24, 1, 0.95, 0.6, 1, "PERSISTENT VAULT")
        T.text(0, HH - 352, 16, 0.8, 0.8, 0.9, 1, "visit #" .. visits .. " on this device")
        button(0, 40, 190, 190, "", nil, function()
          coins = coins + 1
          game.save("sc_coins", coins)
          game.play_sound("score"); game.haptic("light"); game.emit("spark", 0, 40)
        end)
        T.sprite(0, 40, 120, 120, "icon_coin")
        -- best-bench scoreboard, read back through the same save/load path
        local y = -160
        T.text(0, y + 44, 18, 0.9, 0.9, 1, 1, "BENCH BOARD (saved)")
        for _, k in ipairs(order) do
          local best = game.load(bench_best_key(k))
          if type(best) == "number" then
            T.text(0, y, 16, 0.75, 0.85, 0.95, 1, NAMES[k] .. "  Lv " .. math.floor(best))
            y = y - 24
          end
        end
      end,
      update = function(dt)
        if bench.on and not bench.score then
          -- pressure: save/load round-trips per frame, verified
          ops = 0
          local n = 4 + bench.level * 4
          for i = 1, n do
            local k = "sc_probe_" .. (i % 8)
            local v = math.floor(time * 1000) + i
            game.save(k, v)
            if game.load(k) ~= v then errs = errs + 1 end
            ops = ops + 2
          end
        end
        game.set_text(string.format("VAULT  coins %d%s", coins,
          bench.on and string.format("  |  BENCH Lv%d  %d ops/f  errs %d%s",
            bench.level, ops, errs, bench.score and ("  SCORE " .. bench.score) or "") or ""))
      end,
    }
  end)()

  -- ------------------------------------------------------------------ touch
  stations.touch = (function()
    local rings, swarm = {}, {}
    return {
      hint = "put fingers on the screen (mouse = one finger)",
      build = function()
        rings, swarm = {}, {}
        for i = 1, 8 do
          local id = T.sprite(0, -HH * 2, 90, 90, "orb")
          game.set_color(id, 0.3 + i * 0.08, 0.8, 1.0 - i * 0.07, 0.9)
          rings[i] = id
        end
        T.text(0, HH - 320, 24, 0.5, 0.85, 1, 1, "MULTI-TOUCH")
      end,
      update = function(dt)
        local touches = game.touches()
        for i = 1, 8 do
          local t = touches[i]
          if t then
            game.move_to(rings[i], t.x, t.y)
            game.set_size(rings[i], 90 + 14 * math.sin(time * 6 + i), 90 + 14 * math.sin(time * 6 + i))
          else
            game.move_to(rings[i], 0, -HH * 2) -- park offscreen
          end
        end
        if bench.on and not bench.score then
          local want = bench.level * 24
          while #swarm < want and #swarm < 320 do
            local id = T.sprite(0, 0, 14, 14, "sparkle")
            swarm[#swarm + 1] = { id = id, x = math.random(-200, 200), y = math.random(-300, 300) }
          end
          local px, py = game.pointer()
          local tx, ty = px or 0, py or 0
          for i, s in ipairs(swarm) do
            s.x = s.x + (tx - s.x) * math.min(1, dt * (2 + (i % 5)))
            s.y = s.y + (ty - s.y) * math.min(1, dt * (2 + (i % 7)))
            game.move_to(s.id, clamp(s.x, -HW, HW), clamp(s.y, -HH, HH))
          end
        end
        game.set_text(string.format("TOUCH  fingers %d%s", #touches,
          bench.on and string.format("  |  BENCH Lv%d  swarm %d%s", bench.level, #swarm,
            bench.score and ("  SCORE " .. bench.score) or "") or ""))
      end,
    }
  end)()

  -- ------------------------------------------------------------------ atlas
  stations.atlas = (function()
    local coins = {}
    local function add_coin(x, y, size, speed)
      -- coin_sheet.png: 6 frames of 160x160 in one row (Floniks pipeline)
      local id = xkeep(game.spawn_sheet(x, y, size, size, "coin_sheet", 160, 160, 6, 6))
      coins[#coins + 1] = { id = id, phase = math.random() * 6, speed = speed }
    end
    return {
      hint = "one texture, six frames - all spinning off one atlas",
      build = function()
        coins = {}
        add_coin(0, 90, 200, 10)
        for i = 1, 5 do add_coin(-180 + (i - 1) * 90, -90, 70, 6 + i * 2) end
        T.text(0, HH - 320, 24, 1, 0.8, 0.4, 1, "TEXTURE ATLAS")
      end,
      update = function(dt)
        if bench.on and not bench.score then
          local want = 6 + bench.level * 24
          while #coins < want and #coins < 300 do
            add_coin(rnd(-HW + 40, HW - 40), rnd(-HH + 200, HH - 260),
              34, 4 + math.random() * 12)
          end
        end
        for _, c in ipairs(coins) do
          game.set_frame(c.id, math.floor(time * c.speed + c.phase) % 6)
        end
        game.set_text(string.format("ATLAS  sprites %d  set_frame/f %d%s", #coins, #coins,
          bench.on and string.format("  |  BENCH Lv%d%s", bench.level,
            bench.score and ("  SCORE " .. bench.score) or "") or ""))
      end,
      teardown = function() coins = {} end,
    }
  end)()

  -- ----------------------------------------------------------------- camera
  stations.camera = (function()
    local drone, landmarks, follow = nil, {}, true
    local function add_landmark()
      local tex = ({ "tree", "rock", "flower", "gmush", "gem" })[math.random(1, 5)]
      local x, y = rnd(-HW * 2, HW * 2), rnd(-HH, HH)
      landmarks[#landmarks + 1] = T.sprite(x, y, 60, 60, tex)
    end
    return {
      hint = "tap: follow -> overview -> back to hub",
      build = function()
        landmarks, follow = {}, true
        for _ = 1, 30 do add_landmark() end
        drone = T.sprite(0, 0, 64, 64, "ship")
        T.text(0, HH - 320, 24, 0.6, 0.95, 0.65, 1, "CAMERA RIG")
      end,
      update = function(dt)
        local dx = math.sin(time * 0.5) * HW * 1.5
        local dy = math.cos(time * 0.8) * HH * 0.5
        game.move_to(drone, dx, dy)
        game.set_rotation(drone, math.sin(time * 0.9) * 0.4)
        if follow then
          game.cam(dx, dy, 1.0 + 0.25 * math.sin(time * 0.7))
        else
          game.cam(0, 0, 1.8) -- pull back for the overview
        end
        if bench.on and not bench.score then
          local want = 30 + bench.level * 40
          while #landmarks < want and #landmarks < 480 do add_landmark() end
        end
        game.set_text(string.format("CAMERA  %s  world sprites %d%s",
          follow and "FOLLOW" or "OVERVIEW", #landmarks + 1,
          bench.on and string.format("  |  BENCH Lv%d%s", bench.level,
            bench.score and ("  SCORE " .. bench.score) or "") or ""))
      end,
      -- While the camera roams, world-anchored buttons drift off-screen, so a
      -- plain tap cycles follow -> overview -> hub; nobody gets stranded.
      tap = function()
        if follow then
          follow = false
        else
          enter_station(nil)
        end
        game.play_sound("hit")
      end,
      teardown = function() game.cam(0, 0, 1) end,
    }
  end)()

  -- ------------------------------------------------------------------ mixer
  stations.mixer = (function()
    local CH = { "music", "sfx", "voice" }
    local vol = { music = 1, sfx = 1, voice = 1 }
    local knobs, track_w = {}, 300
    local sfx_names = { "hit", "wall", "score" }
    return {
      hint = "drag the knobs; buttons drive each channel",
      build = function()
        knobs = {}
        for i, ch in ipairs(CH) do
          local y = 120 - (i - 1) * 90
          T.text(-HW + 70, y, 18, 0.9, 0.9, 1, 1, ch:upper())
          local bar = T.sprite(30, y, track_w, 10, "rpill")
          game.set_color(bar, 0.35, 0.38, 0.5, 1)
          local knob = T.sprite(30 - track_w / 2 + vol[ch] * track_w, y, 40, 40, "orb")
          knobs[ch] = { id = knob, y = y }
        end
        button(-110, -140, 170, 62, "PLAY MUSIC", { 0.5, 0.7, 0.5 }, function()
          game.play_music("showcase")
        end)
        button(90, -140, 150, 62, "STOP", { 0.75, 0.45, 0.45 }, function()
          game.stop_music()
        end)
        button(-110, -220, 170, 62, "SFX BURST", { 0.5, 0.6, 0.8 }, function()
          game.play_sound(sfx_names[math.random(1, 3)])
        end)
        button(90, -220, 150, 62, "VOICE", { 0.7, 0.6, 0.9 }, function()
          game.play_voice("vo_coach")
        end)
        T.text(0, HH - 320, 24, 0.85, 0.65, 1, 1, "AUDIO MIXER")
      end,
      update = function(dt)
        local px, py, down = game.pointer()
        if down and px and px > 30 - track_w / 2 - 30 and px < 30 + track_w / 2 + 30 then
          for ch, k in pairs(knobs) do
            if math.abs((py or 9999) - k.y) < 34 then
              local v = clamp((px - (30 - track_w / 2)) / track_w, 0, 1)
              vol[ch] = v
              game.move_to(k.id, 30 - track_w / 2 + v * track_w, k.y)
              game.set_volume(ch, v)
            end
          end
        end
        if bench.on and not bench.score then
          for i = 1, math.min(3, bench.level) do game.play_sound(sfx_names[i]) end
          if bench.level >= 4 then game.set_volume("music", 0.5 + 0.5 * math.sin(time * 8)) end
        end
        game.set_text(string.format("MIXER  music %d%%  sfx %d%%  voice %d%%%s",
          vol.music * 100, vol.sfx * 100, vol.voice * 100,
          bench.on and string.format("  |  BENCH Lv%d%s", bench.level,
            bench.score and ("  SCORE " .. bench.score) or "") or ""))
      end,
      teardown = function()
        game.set_volume("music", 1); game.set_volume("sfx", 1); game.set_volume("voice", 1)
      end,
    }
  end)()

  -- ----------------------------------------------------------------- sparks
  stations.sparks = (function()
    local presets = { "spark", "dust", "confetti", "splash" }
    local auto, emitted = 0, 0
    return {
      hint = "tap anywhere - fireworks; BENCH storms the 512 cap",
      build = function()
        emitted = 0
        T.text(0, HH - 320, 24, 1, 0.55, 0.5, 1, "PARTICLES")
      end,
      update = function(dt)
        auto = auto + dt
        if auto > 0.5 then
          auto = 0
          game.emit(presets[math.random(1, 4)],
            rnd(-HW + 60, HW - 60), rnd(-HH + 200, HH - 240))
          emitted = emitted + 1
        end
        if bench.on and not bench.score then
          for i = 1, bench.level * 2 do
            game.emit("spark", rnd(-HW, HW), rnd(-HH, HH), 16)
            emitted = emitted + 1
          end
        end
        game.set_text(string.format("SPARKS  bursts %d  (global cap 512)%s", emitted,
          bench.on and string.format("  |  BENCH Lv%d  +%d bursts/f%s", bench.level,
            bench.level * 2, bench.score and ("  SCORE " .. bench.score) or "") or ""))
      end,
      tap = function(x, y)
        game.emit("confetti", x, y); game.haptic("light"); emitted = emitted + 1
      end,
    }
  end)()

  -- ------------------------------------------------------------------ tiles
  stations.tiles = (function()
    local map, cols, rows, ts = nil, 9, 11, 44
    local brush, BRUSHES = 1, { "GRASS", "DIRT", "WATER", "STONE" }
    local cells = {}
    local function paint_default()
      for ty = 0, rows - 1 do
        for tx = 0, cols - 1 do
          local edge = tx == 0 or ty == 0 or tx == cols - 1 or ty == rows - 1
          local idx = edge and 3 or ((tx + ty) % 2 == 0 and 0 or 1)
          game.set_tile(map, tx, ty, idx)
          cells[ty * cols + tx] = idx
        end
      end
    end
    local function make_map(c, r)
      if map then game.despawn(map) end
      cols, rows = c, r
      -- tileset.png: 4 tiles of 160x160 in one row (Floniks pipeline)
      map = xkeep(game.tilemap(0, -30, cols, rows, ts, ts, "tileset", 4, 4))
      cells = {}
      paint_default()
    end
    return {
      hint = "drag to paint; BRUSH cycles grass/dirt/water/stone",
      build = function()
        make_map(9, 11)
        button(-90, -HH + 130, 170, 62, "BRUSH", { 0.5, 0.7, 0.5 }, function()
          brush = brush % 4 + 1; game.play_sound("hit")
        end)
        button(100, -HH + 130, 150, 62, "RESET", { 0.7, 0.55, 0.45 }, function()
          paint_default(); game.play_sound("wall")
        end)
        T.text(0, HH - 320, 24, 0.55, 0.9, 0.55, 1, "TILEMAP")
      end,
      update = function(dt)
        local px, py, down = game.pointer()
        if down and px and not bench.on then
          -- world → cell (map centered at (0,-30))
          local lx = px - 0 + cols * ts * 0.5
          local ly = (-30 + rows * ts * 0.5) - py
          local tx, ty = math.floor(lx / ts), math.floor(ly / ts)
          if tx >= 0 and tx < cols and ty >= 0 and ty < rows then
            game.set_tile(map, tx, ty, brush - 1)
            cells[ty * cols + tx] = brush - 1
          end
        end
        if bench.on and not bench.score then
          local size = 8 + bench.level * 2
          if cols ~= size then make_map(size, size + 2) end
          -- full-map animated rewrite, every frame
          local phase = math.floor(time * 8)
          for ty = 0, rows - 1 do
            for tx = 0, cols - 1 do
              game.set_tile(map, tx, ty, (tx + ty + phase) % 4)
            end
          end
        end
        game.set_text(string.format("TILES  %dx%d  brush %s%s", cols, rows, BRUSHES[brush],
          bench.on and string.format("  |  BENCH Lv%d  %d set_tile/f%s", bench.level,
            cols * rows, bench.score and ("  SCORE " .. bench.score) or "") or ""))
      end,
      teardown = function() map = nil end,
    }
  end)()

  -- ------------------------------------------------------------------ robot
  stations.robot = (function()
    local star, crowd, clip = nil, {}, "idle"
    return {
      hint = "buttons switch clips; the head follows your pointer",
      build = function()
        crowd = {}
        star = xkeep(game.spawn_rig(0, -40, "robot", 1.0))
        game.play_anim(star, "idle")
        clip = "idle"
        button(-140, -HH + 130, 130, 62, "IDLE", { 0.5, 0.6, 0.75 }, function()
          clip = "idle"; game.play_anim(star, "idle")
        end)
        button(0, -HH + 130, 130, 62, "WAVE", { 0.55, 0.75, 0.55 }, function()
          clip = "wave"; game.play_anim(star, "wave")
        end)
        button(140, -HH + 130, 130, 62, "WALK", { 0.75, 0.6, 0.5 }, function()
          clip = "walk"; game.play_anim(star, "walk")
        end)
        T.text(0, HH - 320, 24, 1, 0.65, 0.35, 1, "SKELETAL RIG")
      end,
      update = function(dt)
        local px, py = game.pointer()
        if px then
          local ang = clamp(math.atan(px - 0, 240 - (py or 0)) * 0.5, -0.55, 0.55)
          game.set_bone(star, "head", ang, 0, 0)
        end
        if bench.on and not bench.score then
          local want = bench.level * 2
          while #crowd < want and #crowd < 24 do
            local id = xkeep(game.spawn_rig(
              rnd(-HW + 80, HW - 80), rnd(-HH + 240, HH - 320),
              "robot", 0.45))
            game.play_anim(id, "walk")
            crowd[#crowd + 1] = id
          end
        end
        game.set_text(string.format("ROBOT  clip %s  rigs %d%s", clip, 1 + #crowd,
          bench.on and string.format("  |  BENCH Lv%d%s", bench.level,
            bench.score and ("  SCORE " .. bench.score) or "") or ""))
      end,
      teardown = function() star, crowd = nil, {} end,
    }
  end)()

  -- ------------------------------------------------------------------ juice
  stations.juice = (function()
    local presses = 0
    return {
      hint = "every press fires the effect AND logs a game.track event",
      build = function()
        presses = 0
        local defs = {
          { "SHAKE", { 0.9, 0.5, 0.5 }, function() game.shake(0.6) end },
          { "ZOOM", { 0.5, 0.7, 0.9 }, function() game.zoom(0.9) end },
          { "HAPTIC", { 0.6, 0.85, 0.6 }, function() game.haptic("success") end },
          { "ALL IN", { 0.95, 0.75, 0.4 }, function()
            game.shake(0.8); game.zoom(1); game.haptic("heavy")
            game.emit("confetti", 0, 0); game.play_sound("score")
          end },
        }
        for i, d in ipairs(defs) do
          local row = math.floor((i - 1) / 2)
          local col = (i - 1) % 2
          button(-95 + col * 190, 40 - row * 90, 170, 70, d[1], d[2], function()
            d[3](); presses = presses + 1; game.track("juice_" .. d[1], presses)
          end)
        end
        T.text(0, HH - 320, 24, 0.95, 0.6, 0.8, 1, "JUICE LAB + ANALYTICS")
      end,
      update = function(dt)
        if bench.on and not bench.score then
          game.shake(0.12); game.zoom(0.25)
          for _ = 1, bench.level do game.emit("spark", math.random(-200, 200), 0, 12) end
          game.track("juice_bench", bench.level)
        end
        game.set_text(string.format("JUICE  tracked presses %d%s", presses,
          bench.on and string.format("  |  BENCH Lv%d%s", bench.level,
            bench.score and ("  SCORE " .. bench.score) or "") or ""))
      end,
    }
  end)()

  ----------------------------------------------------------------------------
  -- Hub + station switching
  ----------------------------------------------------------------------------
  local function build_hub()
    T.text(0, HH - 250, 34, 1, 1, 1, 1, "ENGINE SHOWCASE")
    T.text(0, HH - 292, 16, 0.8, 0.85, 0.95, 1, "9 capabilities - tap a card - BENCH scores persist")
    hub_cards = {}
    local cw, chh, gap = 148, 148, 22
    local x0, y0 = -(cw + gap), 120
    for i, k in ipairs(order) do
      local row = math.floor((i - 1) / 3)
      local col = (i - 1) % 3
      local x, y = x0 + col * (cw + gap), y0 - row * (chh + gap)
      local card = T.sprite(x, y, cw, chh, "rcard")
      local tint = CARD_TINT[k]
      game.set_color(card, tint[1], tint[2], tint[3], 1)
      T.sprite(x, y + 18, 64, 64, ICONS[k])
      T.text(x, y - 46, 18, 0.1, 0.12, 0.2, 1, NAMES[k])
      hub_cards[#hub_cards + 1] = { key = k, x = x, y = y, w = cw, h = chh }
    end
    game.set_text("ENGINE SHOWCASE  -  pick a station")
  end

  function enter_station(key) -- assigns the forward-declared local
    T.clear(); clear_extra(); buttons = {}
    if station and stations[station].teardown then stations[station].teardown() end
    bench_reset()
    game.cam(0, 0, 1)
    station = key
    back = K.make_back(T, HW, HH)
    if key then
      stations[key].build()
      hub_button(); bench_button()
      T.text(0, -HH + 200, 15, 0.85, 0.85, 0.95, 1, stations[key].hint)
      game.track("showcase_enter", 0)
    else
      build_hub()
    end
  end

  local function full_build()
    built = true
    enter_station(nil)
    game.play_music("showcase")
    DEBUG = {
      game = "showcase",
      back = back,
      station = function() return station end,
      enter_station = function(k) enter_station(k) end,
      bench_on = function() return bench.on end,
      bench_start = function() bench.on = true end,
      bench_level = function() return bench.level end,
      bench_score = function() return bench.score end,
      cards = function() return hub_cards end,
    }
  end

  return {
    enter = function() built = false end,
    leave = function()
      if station and stations[station].teardown then stations[station].teardown() end
      T.clear(); clear_extra(); buttons = {}
      station = nil
      bench_reset()
      game.cam(0, 0, 1)
      game.stop_voice()
      built = false
    end,
    tap = function(x, y)
      if not built then return end
      if back and inr(back, x, y) then K.switch("menu"); return end
      for _, b in ipairs(buttons) do
        if inr(b, x, y) then b.action(); return end
      end
      if not station then
        for _, c in ipairs(hub_cards) do
          if inr(c, x, y) then
            game.play_sound("hit"); game.haptic("light")
            enter_station(c.key)
            return
          end
        end
      elseif stations[station].tap then
        stations[station].tap(x, y)
      end
    end,
    update = function(dt, hw, hh)
      HW, HH = hw, hh
      if not built then full_build() end
      time = time + dt
      if station then
        stations[station].update(dt)
        bench_tick(dt)
      end
    end,
  }
end

PACKS = PACKS or {}
PACKS["showcase"] = {
  slot = 1, key = "showcase", label = "Engine Showcase", short = "Showcase",
  icon = "icon_bolt", color = { 0.35, 0.75, 0.95 }, tier = "ai", make = make_showcase,
}
