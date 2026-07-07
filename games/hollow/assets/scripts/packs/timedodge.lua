-- timedodge.lua — "TIME DODGE": a SUPERHOT-style 2.5D meteor dodger.
--
-- Narrative skin ("Borrowed Time"): the world is frozen in a single instant;
-- you are the only thing that still moves, and the sparks of entropy hunt
-- anything that moves. Time flows only while you TOUCH (hold the screen /
-- mouse / a key); release and the world freezes. Every held second is stolen.
--
-- Three modes behind an in-scene select screen:
--   ENDLESS — survive converging entropy. Score = stolen (world-time) seconds;
--             new foe kinds wake at survival milestones; best persists.
--   TRIALS  — 10 "sealed moments": reach every time gate in sequence. The run
--             is timed in REAL seconds (freezing is safe but the clock keeps
--             counting), 1–3 stars by finish time, next level unlocks at 1
--             star. Stars/bests persist via game.save.
--   ABSORB  — osmos-style: eat rocks smaller than you (grow by their area,
--             green tint), bigger rocks chip you by 25% (red tint); below
--             MIN_MASS you fade away. Rock sizes track yours and the danger
--             share grows with every meal — growth is power, never safety.
--             The FIRST big hit of a run pauses the world with a "CANCEL THIS
--             HIT?" sponsor dialog: YES opens the sponsor link (game.open_url)
--             and waives the chip; NO takes the normal 25% chip.
--
-- Foe kinds — one colour + one motion signature each, readable with no text:
--   dart (red, straight aimed) · surge (yellow, accelerates) · seeker (purple,
--   curves toward you) · splitter (orange, bursts into 3 darts) · drifter
--   (ghost-white, IMMUNE to your freeze: it crawls on real time, so camping
--   forever stops working — Braid's "immune to the time rule" trick).
--
-- Registers make_timedodge (main.lua builds the menu from PACKS). Talks to the
-- host ONLY through the `game` bridge + shared GAME_KIT helpers.

function make_timedodge()
  local K = GAME_KIT
  local clamp = K.clamp
  local T = K.tracker()

  -- REAL-3D render path: when the host exposes game.rock3d (src/rock3d.rs),
  -- meteors + the player orb are true rotating 3D rock meshes with lighting;
  -- depth is REAL z movement instead of scale/brighten fakery. Everything
  -- else (HUD, menus, buttons, gate, trail) stays on the 2D layer. Test mocks
  -- don't define rock3d, so the 2D sprite path below remains fully exercised
  -- and is the fallback everywhere the 3D bridge is absent.
  local HAS3D = game.rock3d ~= nil
  local Z3D = -420                       -- world z at full depth (b.z = 1)

  local PLAYER, FOE, GATE = 26, 18, 34
  -- RELATIVE drag: the orb moves by the finger's DELTA (scaled), never to the
  -- finger's position — so you drag in the empty bottom of the screen and the
  -- finger NEVER covers the orb or the incoming foes. Keyboard drives it too.
  local DRAG_SENS, KEY_SPEED = 1.5, 460
  local PLAYER_MAX = 820                 -- hard speed cap: a pointer jump (mouse
                                         -- warp, finger lift+press) never
                                         -- teleports the orb — or cheeses trials
  local REF_SPEED = 300                  -- px/s that reads as "dashing" (trail fx)
  local TS_MIN = 0.06                    -- near-frozen world rate while released
  local TS_SMOOTH = 12                   -- timescale attack/release rate
  local SPEED0, SPEED_PER_S, SPEED_MAX = 320, 8, 500
  local SPAWN0, SPAWN_MIN, SPAWN_PER_S = 0.55, 0.26, 0.016
  local MAX_FOES, OFF = 40, 70           -- live cap / off-screen despawn margin
  local NEAR, HIT_R = 44, 19             -- near-miss ring / kill distance
  local MAX_DT, TRAIL_N = 1 / 30, 10
  local DRIFT_SPEED = 70                 -- drifter real-time crawl px/s
  -- 2.5D depth: meteors surface from the deep — they spawn far (z=1), drift
  -- slowly while small/dim, and accelerate to full size/speed as they reach
  -- the play plane. Only meteors near the plane (z <= PLANE_Z) can touch you.
  local Z_RATE, PLANE_Z = 1.2, 0.35
  -- ABSORB mode: eat rocks smaller than you (grow by their area), bigger rocks
  -- chip you down; below MIN_MASS you fade away. Rock sizes track yours, so
  -- something bigger always exists — growth is power, never safety.
  local MIN_MASS, MAX_MASS = 13, 120
  local EAT_GAIN, CHIP = 1.0, 0.75       -- area fraction kept / size kept on hit
  local SAFE_C, DANGER_C = { 0.35, 0.90, 0.50 }, { 1.0, 0.25, 0.20 }
  local FROZEN_C = { 0.55, 0.85, 1.0 }

  local KINDS = {
    dart     = { c = { 1.00, 0.30, 0.25 } },
    surge    = { c = { 1.00, 0.80, 0.25 }, accel = 1.0 },
    seeker   = { c = { 0.75, 0.40, 1.00 }, turn = 1.6 },
    splitter = { c = { 1.00, 0.55, 0.20 }, split_at = 1.1 },
    drifter  = { c = { 0.92, 0.95, 1.00 }, real = true },
  }
  -- Endless: foes wake at stolen-time milestones (doubles as the difficulty
  -- curve and the "something new every 10s" content pacing).
  local UNLOCKS = {
    { t = 0, k = "dart" }, { t = 10, k = "surge" }, { t = 20, k = "seeker" },
    { t = 30, k = "splitter" }, { t = 45, k = "drifter" },
  }
  -- Trials: seed fixes the gate layout + spawn pattern so a level is the same
  -- moment every attempt. Gates spawn far apart (cross-screen runs), a volley
  -- of foes opens every level, and spawns are dense — the pressure is real.
  -- s3/s2 = real-seconds star thresholds, calibrated against an expert-line
  -- autopilot (~1.7x / 2.8x its measured clear time), so 3 stars means
  -- decisive routing (see the verification sweep in PR #71).
  local LEVELS = {
    { seed = 101,  gates = 3, volley = 2, kinds = { "dart" },                                        speed = 240, every = 0.70, s3 = 6, s2 = 10 },
    { seed = 202,  gates = 3, volley = 2, kinds = { "dart" },                                        speed = 255, every = 0.62, s3 = 4, s2 = 7 },
    { seed = 303,  gates = 4, volley = 3, kinds = { "dart", "surge" },                               speed = 265, every = 0.58, s3 = 7, s2 = 11 },
    { seed = 404,  gates = 4, volley = 3, kinds = { "dart", "surge" },                               speed = 275, every = 0.52, s3 = 7, s2 = 11 },
    { seed = 505,  gates = 5, volley = 4, kinds = { "dart", "surge", "seeker" },                     speed = 285, every = 0.48, s3 = 9, s2 = 14 },
    { seed = 606,  gates = 5, volley = 4, kinds = { "dart", "surge", "seeker" },                     speed = 295, every = 0.44, s3 = 9, s2 = 14 },
    { seed = 707,  gates = 6, volley = 5, kinds = { "dart", "seeker", "splitter" },                  speed = 305, every = 0.40, s3 = 16, s2 = 25 },
    { seed = 808,  gates = 6, volley = 5, kinds = { "dart", "surge", "splitter" },                   speed = 315, every = 0.36, s3 = 19, s2 = 30 },
    { seed = 909,  gates = 7, volley = 4, kinds = { "dart", "dart", "seeker", "splitter", "drifter" }, speed = 320, every = 0.33, s3 = 20, s2 = 32 },
    { seed = 1010, gates = 8, volley = 6, kinds = { "dart", "surge", "seeker", "splitter", "drifter" }, speed = 335, every = 0.30, s3 = 39, s2 = 63 },
  }

  local mode, built = "select", false
  local SW, SH = 0, 0
  local back = nil
  local btn_endless, btn_trials, btn_absorb, lv_rects = nil, nil, nil, {}
  local S = nil                          -- the live run (endless or trial)
  local trail, tcur = {}, 0
  local player, gate_id = nil, nil

  local function new_lcg(seed)
    local s = seed
    return function() s = (1103515245 * s + 12345) % 2147483648; return s / 2147483648 end
  end
  local function rnd() return (S and S.rng) and S.rng() or math.random() end

  local function stars_of(i) return tonumber(game.load("td_lv" .. i .. "_stars")) or 0 end
  local function unlocked(i) return i == 1 or stars_of(i - 1) > 0 end
  local function star_str(n) return n >= 1 and string.rep("*", n) or "-" end

  -- ABSORB grows/shrinks the player: sprites resize, 3D rocks rescale.
  local function player_size(sz)
    if HAS3D then game.scale3d(player, sz) else game.set_size(player, sz, sz) end
  end

  local function clear_foes()
    if S then for _, b in ipairs(S.bullets) do game.despawn(b.id) end; S.bullets = {} end
  end

  -- ABSORB "cancel this hit" dialog (sponsor offer). Opens on the FIRST
  -- big-rock hit of a run: the run pauses dead (update_run returns while
  -- S.hit_dialog is set), the rock is already consumed, and the pending chip
  -- is applied only if the player answers NO. The dialog owns its own raw
  -- spawns (not T) because it is dismissed mid-run, not on scene teardown.
  local function close_hit_dialog()
    if not (S and S.hit_dialog) then return end
    for _, id in ipairs(S.hit_dialog.ids) do game.despawn(id) end
    S.hit_dialog = nil
    S.drag = nil                         -- re-anchor the drag: the finger may
  end                                    -- have moved while the world was paused
  local function open_hit_dialog(rock_size)
    local ids = {}
    local function rect(x, y, w, h, r, g, b, a)
      ids[#ids + 1] = game.spawn(x, y, w, h, r, g, b, a)
    end
    local function label(x, y, size, r, g, b, a, s)
      ids[#ids + 1] = game.spawn_text(x, y, size, r, g, b, a, s)
    end
    rect(0, 0, SW * 2, SH * 2, 0, 0, 0, 0.8)             -- dim the whole arena
    rect(0, 0, 360, 250, 0.10, 0.12, 0.18, 1)            -- panel
    label(0, 75, 26, 1, 1, 1, 1, "CANCEL THIS HIT?")
    label(0, 40, 14, 0.75, 0.85, 1.0, 1, "a sponsor will absorb it for you")
    local yes = { x = -85, y = -35, w = 140, h = 66 }
    local no = { x = 85, y = -35, w = 140, h = 66 }
    rect(yes.x, yes.y, yes.w, yes.h, 0.20, 0.62, 0.35, 1)
    label(yes.x, yes.y, 24, 1, 1, 1, 1, "YES")
    rect(no.x, no.y, no.w, no.h, 0.70, 0.25, 0.22, 1)
    label(no.x, no.y, 24, 1, 1, 1, 1, "NO")
    S.hit_dialog = { rock_size = rock_size, yes = yes, no = no, ids = ids }
    game.play_sound("wall"); game.haptic("heavy"); game.shake(0.3)
  end

  local function wipe()
    close_hit_dialog()
    clear_foes()
    if HAS3D and player then game.despawn(player) end  -- 3D player isn't in T
    T.clear(); gate_id, player = nil, nil; trail = {}
  end

  ------------------------------------------------------------------
  -- Screens: mode select / level grid
  ------------------------------------------------------------------
  local function set_debug(extra)
    local d = { game = "timedodge", back = back, mode = function() return mode end }
    for k, v in pairs(extra or {}) do d[k] = v end
    DEBUG = d
  end

  local function build_select(hw, hh)
    mode = "select"
    game.set_text("")
    T.text(0, 210, 44, 1, 1, 1, 1, "TIME DODGE")
    T.text(0, 150, 17, 0.75, 0.85, 1.0, 1, "Hold: time flows. Release: the world freezes.")
    T.text(0, 122, 17, 0.75, 0.85, 1.0, 1, "Every second you hold on is a second stolen back.")
    btn_endless = { x = 0, y = 10, w = 300, h = 86 }
    T.spawn(btn_endless.x, btn_endless.y, btn_endless.w, btn_endless.h, 0.75, 0.22, 0.20, 1)
    T.text(btn_endless.x, btn_endless.y + 12, 30, 1, 1, 1, 1, "ENDLESS")
    T.text(btn_endless.x, btn_endless.y - 22, 14, 1, 0.85, 0.8, 1, "steal as long as you can")
    btn_trials = { x = 0, y = -110, w = 300, h = 86 }
    T.spawn(btn_trials.x, btn_trials.y, btn_trials.w, btn_trials.h, 0.20, 0.55, 0.70, 1)
    T.text(btn_trials.x, btn_trials.y + 12, 30, 1, 1, 1, 1, "TRIALS")
    T.text(btn_trials.x, btn_trials.y - 22, 14, 0.8, 0.95, 1, 1, "ten sealed moments to break")
    btn_absorb = { x = 0, y = -230, w = 300, h = 86 }
    T.spawn(btn_absorb.x, btn_absorb.y, btn_absorb.w, btn_absorb.h, 0.45, 0.28, 0.70, 1)
    T.text(btn_absorb.x, btn_absorb.y + 12, 30, 1, 1, 1, 1, "ABSORB")
    T.text(btn_absorb.x, btn_absorb.y - 22, 14, 0.85, 0.8, 1, 1, "eat the small - fear the big")
    back = K.make_back(T, hw, hh)
    set_debug({ btn_endless = btn_endless, btn_trials = btn_trials, btn_absorb = btn_absorb })
  end

  local function build_levels(hw, hh)
    mode = "levels"
    game.set_text("")
    T.text(40, 270, 30, 1, 1, 1, 1, "SEALED MOMENTS")
    T.text(0, 220, 15, 0.75, 0.85, 1.0, 1, "release to freeze - the clock only forgives the dead")
    lv_rects = {}
    local cols, tw, th, gap = 5, 64, 76, 12
    for i = 1, #LEVELS do
      local col, row = (i - 1) % cols, math.floor((i - 1) / cols)
      local x = -(cols - 1) * (tw + gap) * 0.5 + col * (tw + gap)
      local y = 140 - row * (th + gap + 14)
      local open = unlocked(i)
      local r, g, b = 0.20, 0.55, 0.70
      if not open then r, g, b = 0.28, 0.30, 0.36 end
      T.spawn(x, y, tw, th, r, g, b, 1)
      T.text(x, y + 10, 26, 1, 1, 1, open and 1 or 0.45, tostring(i))
      T.text(x, y - 20, 15, 1, 0.9, 0.4, open and 1 or 0.35,
        open and star_str(stars_of(i)) or "?")
      lv_rects[i] = { x = x, y = y, w = tw, h = th }
    end
    back = K.make_back(T, hw, hh)
    set_debug({
      lv_btn = function(i) return lv_rects[i] end,
      stars_of = stars_of, unlocked = unlocked,
    })
  end

  ------------------------------------------------------------------
  -- The run (shared by both modes)
  ------------------------------------------------------------------
  local function place_gate()
    -- Farthest-point sampling: of 24 candidates keep the one farthest from
    -- both the player and the previous gate, so every gate is a cross-screen
    -- run through the hanging foes — never a lucky hop. (A hard minimum-
    -- distance rule can be unsatisfiable and its fallback drops gates at the
    -- player's feet; maximizing is always well-defined.)
    local best, bestscore = nil, -1
    for _ = 1, 24 do
      local x = (rnd() * 2 - 1) * (SW - 70)
      local y = -SH + 130 + rnd() * (2 * SH - 300)
      local dp = math.sqrt((x - S.px) ^ 2 + (y - S.py) ^ 2)
      local dg = S.gate and math.sqrt((x - S.gate.x) ^ 2 + (y - S.gate.y) ^ 2) or dp
      local score = math.min(dp, dg)
      if score > bestscore then bestscore, best = score, { x = x, y = y } end
    end
    S.gate = best
    game.move_to(gate_id, S.gate.x, S.gate.y)
  end

  local function build_run(hw, hh)
    mode = "run"
    for i = 1, TRAIL_N do
      trail[i] = { id = T.spawn(0, 0, PLAYER * 0.6, PLAYER * 0.6, 0.7, 0.9, 1.0, 0), a = 0 }
    end
    if HAS3D then
      -- The 3D player is NOT in T's list (T only wraps 2D spawners), so wipe()
      -- despawns it explicitly. Slightly blue-white so it reads as "you".
      player = game.rock3d(S.px, S.py, 0, PLAYER)
      game.color3d(player, 0.85, 0.92, 1.0)
    else
      player = T.sprite(S.px, S.py, PLAYER, PLAYER, "rockball")
    end
    if S.trial then
      gate_id = T.sprite(0, 0, GATE, GATE, "gem")
      place_gate()
    end
    back = K.make_back(T, hw, hh)
    set_debug({
      player = player,
      timescale = function() return S.ts end,
      score = function() return S.score end,
      elapsed = function() return S.elapsed end,
      alive = function() return S.playing end,
      done = function() return S.done end,
      trial = function() return S.trial end,
      bullet_count = function() return #S.bullets end,
      bullet_ids = function()
        local ids = {}; for i, b in ipairs(S.bullets) do ids[i] = b.id end; return ids
      end,
      gate = function() return S.gate end,
      size = function() return S.mass end,
      eaten = function() return S.eaten end,
      absorb = function() return S.absorb end,
      hit_dialog = function() return S.hit_dialog end,
      dialog_used = function() return S.dialog_used end,
    })
  end

  local function start_run(lv, absorb)
    wipe()
    S = { trial = lv, absorb = absorb, px = 0, py = 0, prot = 0, ts = TS_MIN,
          score = 0, elapsed = 0, playing = true, done = false, bullets = {},
          gate = nil, gate_i = 0, spawn_t = lv and -1.0 or -0.5, mark = 10,
          next_unlock = 2, ann = "", ann_t = 0,
          volley_due = lv and LEVELS[lv].volley or 0,
          mass = PLAYER, peak = PLAYER, eaten = 0,
          hit_dialog = nil, dialog_used = false }   -- a new run re-arms the offer
    if lv then S.rng = new_lcg(LEVELS[lv].seed) end
    build_run(SW, SH)
  end
  local function to_select() wipe(); S = nil; build_select(SW, SH) end
  local function to_levels() wipe(); S = nil; build_levels(SW, SH) end

  local function hud()
    if S.absorb then
      game.set_text(string.format("MASS %d   EATEN %d%s", math.floor(S.mass), S.eaten,
        S.ts < 0.15 and "  FROZEN" or ""))
      return
    end
    if S.trial then
      local lv = LEVELS[S.trial]
      game.set_text(string.format("MOMENT %d   GATE %d/%d   %.1fs%s",
        S.trial, S.gate_i, lv.gates, S.elapsed, S.ts < 0.15 and "  FROZEN" or ""))
    elseif S.ann_t > 0 then
      game.set_text(S.ann)
    else
      game.set_text(string.format("STOLEN %.1fs%s", S.score,
        S.ts < 0.15 and "  FROZEN" or ""))
    end
  end

  local function foe_speed()
    if S.trial then return LEVELS[S.trial].speed end
    return math.min(SPEED0 + S.score * SPEED_PER_S, SPEED_MAX)
  end
  local function spawn_gap()
    if S.absorb then return 0.5 end
    if S.trial then return LEVELS[S.trial].every end
    return math.max(SPAWN_MIN, SPAWN0 - S.score * SPAWN_PER_S)
  end
  local function pick_kind()
    if S.trial then
      local ks = LEVELS[S.trial].kinds
      return ks[math.floor(rnd() * #ks) + 1]
    end
    local ks, w = {}, {}
    for _, u in ipairs(UNLOCKS) do
      if S.score >= u.t then ks[#ks + 1] = u.k; w[#w + 1] = (u.k == "dart") and 3 or 1 end
    end
    local total = 0
    for _, v in ipairs(w) do total = total + v end
    local r = rnd() * total
    for i, v in ipairs(w) do r = r - v; if r <= 0 then return ks[i] end end
    return "dart"
  end

  local function spawn_foe(kind, x, y, vx, vy, z, size)
    if #S.bullets >= MAX_FOES then return end
    size = size or FOE
    local zz = z or 1
    local id
    if HAS3D then
      -- Real 3D rock at its true world size; depth is real z, so no size fake.
      id = game.rock3d(x, y, Z3D * zz, size)
    else
      id = game.spawn_sprite(x, y, size * 0.3, size * 0.3, "meteor")
    end
    S.bullets[#S.bullets + 1] = { id = id, kind = kind, x = x, y = y,
                                  vx = vx, vy = vy, age = 0, near = false,
                                  z = zz, rot = rnd() * 6.28,
                                  spin = (rnd() * 2 - 1) * 3.5, size = size }
  end
  local function spawn_edge()
    local kind = pick_kind()
    local side, x, y = math.floor(rnd() * 4) + 1, 0, 0
    if side == 1 then x, y = -SW - FOE, (rnd() * 2 - 1) * SH
    elseif side == 2 then x, y = SW + FOE, (rnd() * 2 - 1) * SH
    elseif side == 3 then x, y = (rnd() * 2 - 1) * SW, SH + FOE
    else x, y = (rnd() * 2 - 1) * SW, -SH - FOE end
    if S.absorb then                       -- wandering rocks sized around you:
      -- mostly edible at first; the danger share grows with every meal
      local lo = clamp(S.mass * 0.40, 10, 80)
      local hi = clamp(S.mass * math.min(1.1 + 0.06 * S.eaten, 1.7), 24, 160)
      local size = lo + rnd() * (hi - lo)
      local a = math.atan(S.py - y, S.px - x) + (rnd() * 1.2 - 0.6)
      local sp = 140 + rnd() * 120
      spawn_foe("dart", x, y, sp * math.cos(a), sp * math.sin(a), 1, size)
      return
    end
    local a = math.atan(S.py - y, S.px - x) + (rnd() * 0.5 - 0.25)
    local s = kind == "drifter" and DRIFT_SPEED or foe_speed()
    spawn_foe(kind, x, y, s * math.cos(a), s * math.sin(a))
  end

  local function die()
    S.playing = false
    clear_foes()
    game.play_sound("hit"); game.haptic("heavy"); game.shake(0.7); game.zoom(0.8)
    game.emit("spark", S.px, S.py)
    if S.absorb then
      local best = tonumber(game.load("td_absorb_best")) or 0
      if S.peak > best then best = S.peak; game.save("td_absorb_best", best) end
      game.set_text(string.format("YOU FADED AWAY\nPEAK MASS %d   EATEN %d   BEST %d\nTap to restart",
        math.floor(S.peak), S.eaten, math.floor(best)))
    elseif S.trial then
      game.set_text(string.format("THE FROZEN WORLD KEEPS YOU\nMOMENT %d   GATE %d/%d\nTap to retry",
        S.trial, S.gate_i, LEVELS[S.trial].gates))
    else
      local best = tonumber(game.load("timedodge_best")) or 0
      if S.score > best then best = S.score; game.save("timedodge_best", best) end
      game.set_text(string.format("TIME RECLAIMED YOU\nSTOLEN %.1fs   BEST %.1fs\nTap to restart",
        S.score, best))
    end
    game.log("lose")
  end

  -- The normal big-rock penalty (ABSORB): chip 25% off, with the full impact
  -- fx; below the minimum mass the run ends exactly like any other fade-out.
  -- Shared by the in-loop hit path and the dialog's NO button.
  local function apply_chip()
    S.mass = S.mass * CHIP
    game.play_sound("wall"); game.haptic("heavy"); game.shake(0.5); game.zoom(0.5)
    if S.mass < MIN_MASS then die(); return end
    player_size(S.mass)
    hud()
  end

  local function finish_trial()
    S.playing, S.done = false, true
    clear_foes()
    local lv, i = LEVELS[S.trial], S.trial
    local stars = (S.elapsed <= lv.s3 and 3) or (S.elapsed <= lv.s2 and 2) or 1
    if stars > stars_of(i) then game.save("td_lv" .. i .. "_stars", stars) end
    local best = tonumber(game.load("td_lv" .. i .. "_best")) or 1e9
    if S.elapsed < best then game.save("td_lv" .. i .. "_best", S.elapsed) end
    game.set_text(string.format("MOMENT SEALED!\nTIME %.1fs   %s\nTap to continue",
      S.elapsed, star_str(stars)))
    game.play_sound("score"); game.haptic("success"); game.shake(0.5)
    game.emit("confetti", S.px, S.py)
    game.log("clear")
  end

  local function update_run(dt)
    if S.hit_dialog then return end          -- sponsor dialog up: the world is
                                             -- halted solid (no movement, no
                                             -- spawns, no clocks) until answered
    if not S.playing then return end
    S.elapsed = S.elapsed + dt               -- trials: REAL clock, freeze included

    -- Player moves in REAL time, by the drag's relative delta (or WASD/arrows).
    local ox, oy = S.px, S.py
    local ptx, pty, down = game.pointer()
    if down and ptx ~= nil then
      if S.drag then
        S.px = S.px + (ptx - S.drag.x) * DRAG_SENS
        S.py = S.py + (pty - S.drag.y) * DRAG_SENS
      end
      S.drag = { x = ptx, y = pty }
    else
      S.drag = nil
    end
    local dx, dy = 0, 0
    if game.key("left") or game.key("a") then dx = dx - 1 end
    if game.key("right") or game.key("d") then dx = dx + 1 end
    if game.key("up") or game.key("w") then dy = dy + 1 end
    if game.key("down") or game.key("s") then dy = dy - 1 end
    if dx ~= 0 or dy ~= 0 then S.px, S.py = S.px + dx * KEY_SPEED * dt, S.py + dy * KEY_SPEED * dt end
    local mvx, mvy = S.px - ox, S.py - oy
    local mv = math.sqrt(mvx * mvx + mvy * mvy)
    if mv > PLAYER_MAX * dt then           -- speed cap (see PLAYER_MAX)
      S.px = ox + mvx / mv * PLAYER_MAX * dt
      S.py = oy + mvy / mv * PLAYER_MAX * dt
    end
    S.px = clamp(S.px, -SW + PLAYER * 0.5, SW - PLAYER * 0.5)
    S.py = clamp(S.py, -SH + PLAYER * 0.5, SH - PLAYER * 0.5)

    -- THE mechanic: time flows while you TOUCH (finger down / mouse held /
    -- a movement key). Lift off and the world freezes to a crawl — so the
    -- freeze is a deliberate release, and the finger can rest anywhere.
    local pspeed = math.sqrt((S.px - ox) ^ 2 + (S.py - oy) ^ 2) / dt
    local touching = down or dx ~= 0 or dy ~= 0
    local target = touching and 1 or TS_MIN
    S.ts = S.ts + (target - S.ts) * math.min(1, dt * TS_SMOOTH)
    local wdt = dt * S.ts                    -- world time: foes, spawns, stolen score

    if not S.trial and not S.absorb then
      S.score = S.score + wdt
      if S.score >= S.mark then             -- 10s survival milestones
        S.mark = S.mark + 10
        game.play_sound("score"); game.haptic("success"); game.shake(0.35)
      end
      local u = UNLOCKS[S.next_unlock]      -- a new foe kind wakes
      if u and S.score >= u.t then
        S.next_unlock = S.next_unlock + 1
        S.ann, S.ann_t = "A NEW HUNTER WAKES: " .. u.k:upper(), 2.5
        game.play_sound("wall"); game.shake(0.2)
      end
      if S.ann_t > 0 then S.ann_t = S.ann_t - dt end
    end

    if S.volley_due > 0 then                 -- trials open with foes in the air
      for _ = 1, S.volley_due do spawn_edge() end
      S.volley_due = 0
    end
    S.spawn_t = S.spawn_t + wdt
    if S.spawn_t >= spawn_gap() then S.spawn_t = 0; spawn_edge() end

    -- Trial gate: pulse it, capture on touch, finish after the last one.
    if S.trial and S.gate then
      game.set_color(gate_id, 0.5, 0.95, 1.0, 0.7 + 0.3 * math.sin(S.elapsed * 6))
      if math.sqrt((S.gate.x - S.px) ^ 2 + (S.gate.y - S.py) ^ 2) < (GATE + PLAYER) * 0.5 then
        S.gate_i = S.gate_i + 1
        game.play_sound("score"); game.haptic("light"); game.shake(0.25)
        game.emit("spark", S.gate.x, S.gate.y)
        if S.gate_i >= LEVELS[S.trial].gates then
          game.set_color(gate_id, 0, 0, 0, 0)
          finish_trial(); return
        end
        place_gate()
      end
    end

    -- Advance foes. Each kind = one motion signature; the drifter runs on REAL
    -- dt (immune to the freeze). Colour = kind colour pulled toward icy blue
    -- as time stops, so the freeze reads on every foe at once.
    local spawned, kept = {}, {}
    for _, b in ipairs(S.bullets) do
      local kd = KINDS[b.kind]
      local bdt = kd.real and dt or wdt
      if kd.accel then
        local m = math.min((1 + kd.accel * bdt), SPEED_MAX / math.max(1, math.sqrt(b.vx ^ 2 + b.vy ^ 2)))
        b.vx, b.vy = b.vx * m, b.vy * m
      end
      if kd.turn or kd.real then             -- seeker curves; drifter re-aims
        local want = math.atan(S.py - b.y, S.px - b.x)
        local cur = math.atan(b.vy, b.vx)
        local diff = (want - cur + math.pi) % (2 * math.pi) - math.pi
        local rate = kd.real and 3.0 or kd.turn
        cur = cur + clamp(diff, -rate * bdt, rate * bdt)
        local sp = math.sqrt(b.vx ^ 2 + b.vy ^ 2)
        b.vx, b.vy = sp * math.cos(cur), sp * math.sin(cur)
      end
      b.age = b.age + bdt
      local split = kd.split_at and b.age >= kd.split_at
      b.z = math.max(0, b.z - Z_RATE * bdt)
      local depth = 1 - b.z                  -- 0 = deep space, 1 = in the plane
      local drift = 0.5 + 0.5 * depth        -- far meteors drift (parallax)
      b.x, b.y = b.x + b.vx * bdt * drift, b.y + b.vy * bdt * drift
      b.rot = b.rot + b.spin * bdt
      local sc = b.size * (0.30 + 0.70 * depth * depth)
      if HAS3D then
        -- Real tumble on three axes; freezing wdt freezes it for free. No
        -- set_size: perspective handles apparent size, depth is real z.
        game.rot3d(b.id, b.rot * 0.7, b.rot, b.rot * 0.3)
      else
        game.set_rotation(b.id, b.rot)
        game.set_size(b.id, sc, sc)
      end

      local d = math.sqrt((b.x - S.px) ^ 2 + (b.y - S.py) ^ 2)
      local consumed = false
      if S.absorb then                       -- eat the small, fear the big
        -- (no collisions once the cancel-hit dialog opened this frame: the
        -- world is considered halted from that exact moment)
        if b.z <= PLANE_Z and d < (S.mass + sc) * 0.45 and not S.hit_dialog then
          consumed = true
          game.despawn(b.id)
          game.emit("spark", b.x, b.y)
          if b.size <= S.mass then           -- absorb: grow by its area
            S.mass = math.min(MAX_MASS, math.sqrt(S.mass ^ 2 + EAT_GAIN * b.size ^ 2))
            S.eaten = S.eaten + 1
            if S.mass > S.peak then S.peak = S.mass end
            game.play_sound("hit"); game.haptic("light"); game.shake(0.10)
          elseif not S.dialog_used then      -- FIRST big hit: a sponsor offers
            S.dialog_used = true             -- to cancel it (once per run). The
            open_hit_dialog(b.size)          -- rock is spent either way; the
                                             -- chip waits on the YES/NO answer.
          else                               -- chipped by a bigger rock
            apply_chip()
            if not S.playing then return end -- chipped below MIN_MASS: dead
          end
          player_size(S.mass)
          hud()
        end
      elseif b.z <= PLANE_Z then             -- only near-plane rocks can touch
        if d < HIT_R then die(); return end
        if d < NEAR and not b.near then      -- near miss: a graze of juice
          b.near = true
          game.play_sound("wall"); game.haptic("light"); game.shake(0.06); game.zoom(0.25)
        end
      end
      if consumed then
        -- rock was eaten or shattered: drop it without the offscreen check
        b.gone = true
      end

      if b.gone then
        -- already despawned by the absorb branch
      elseif split then
        game.despawn(b.id)
        local sp = math.sqrt(b.vx ^ 2 + b.vy ^ 2)
        local base = math.atan(b.vy, b.vx)
        for _, off in ipairs({ -0.55, 0, 0.55 }) do
          spawned[#spawned + 1] = { "dart", b.x, b.y,
            sp * math.cos(base + off), sp * math.sin(base + off), b.z }
        end
      elseif math.abs(b.x) > SW + OFF or math.abs(b.y) > SH + OFF then
        game.despawn(b.id)
      else
        -- kind tint (ABSORB: green = edible, red = bigger than you), dimmed
        -- with depth, then pulled toward icy blue capped at 55% when frozen
        local c, k = kd.c, (1 - S.ts) * 0.55
        if S.absorb then c = (b.size <= S.mass) and SAFE_C or DANGER_C end
        local br = 0.45 + 0.55 * depth
        local cr = (c[1] + (FROZEN_C[1] - c[1]) * k) * br
        local cg = (c[2] + (FROZEN_C[2] - c[2]) * k) * br
        local cb = (c[3] + (FROZEN_C[3] - c[3]) * k) * br
        if HAS3D then
          game.move3d(b.id, b.x, b.y, Z3D * b.z)
          game.color3d(b.id, cr, cg, cb)
        else
          game.move_to(b.id, b.x, b.y)
          game.set_color(b.id, cr, cg, cb, 1)
        end
        kept[#kept + 1] = b
      end
    end
    S.bullets = kept
    for _, sp in ipairs(spawned) do spawn_foe(sp[1], sp[2], sp[3], sp[4], sp[5], sp[6]) end

    -- Player trail (only while dashing) + frozen tint on the orb itself.
    if pspeed > REF_SPEED * 0.5 then
      tcur = (tcur % TRAIL_N) + 1
      trail[tcur].a = 0.4
      game.move_to(trail[tcur].id, S.px, S.py)
    end
    for i = 1, TRAIL_N do
      local t = trail[i]
      if t.a > 0.004 then t.a = t.a * 0.85; game.set_color(t.id, 0.7, 0.9, 1.0, t.a) end
    end
    if HAS3D then
      -- The player is the one thing that moves in frozen time, so its tumble
      -- runs on REAL dt, faster while dashing. White pulled icy as time stops.
      S.prot = S.prot + (0.6 + pspeed / REF_SPEED) * dt
      game.rot3d(player, S.prot * 0.5, S.prot, S.prot * 0.25)
      game.color3d(player, (1 - (1 - S.ts) * 0.3) * 0.88, 0.95, 1.0)
      game.move3d(player, S.px, S.py, 0)
    else
      game.set_color(player, 1 - (1 - S.ts) * 0.3, 1, 1, 1)
      game.move_to(player, S.px, S.py)
    end
    hud()
  end

  ------------------------------------------------------------------
  -- Scene contract
  ------------------------------------------------------------------
  return {
    enter = function() built = false; mode = "select" end,
    leave = function() wipe(); S = nil; built = false end,
    tap = function(x, y)
      if S and S.hit_dialog then             -- the dialog swallows every tap
        local hd = S.hit_dialog              -- (including BACK): only its two
        if K.in_rect(hd.yes, x, y) then      -- buttons do anything
          -- Sponsor absorbs the hit: no chip, the rock already shattered.
          close_hit_dialog()
          if game.open_url then game.open_url("https://google.com") end
          game.play_sound("score"); game.haptic("success")
        elseif K.in_rect(hd.no, x, y) then
          -- Decline: take the chip exactly as an ordinary big-rock hit.
          close_hit_dialog()
          apply_chip()
        end
        return
      end
      if back and K.in_rect(back, x, y) then
        if mode == "select" then K.switch("menu")
        elseif mode == "levels" then to_select()
        elseif S and S.trial then to_levels()
        else to_select() end
        return
      end
      if mode == "select" then
        if btn_endless and K.in_rect(btn_endless, x, y) then start_run(nil)
        elseif btn_trials and K.in_rect(btn_trials, x, y) then to_levels()
        elseif btn_absorb and K.in_rect(btn_absorb, x, y) then start_run(nil, true) end
      elseif mode == "levels" then
        for i, r in ipairs(lv_rects) do
          if K.in_rect(r, x, y) and unlocked(i) then start_run(i); return end
        end
      elseif S then
        if S.done then to_levels()
        elseif not S.playing then start_run(S.trial, S.absorb) end
      end
    end,
    update = function(dt, hw, hh)
      SW, SH = hw, hh
      if not built then built = true; build_select(hw, hh) end
      if dt > MAX_DT then dt = MAX_DT end   -- a hitch never teleports anything
      if mode == "run" and S then update_run(dt) end
    end,
  }
end

-- Self-register this game pack (see main.lua: the menu builds from PACKS).
PACKS = PACKS or {}
PACKS["timedodge"] = { slot = 11, key = "timedodge", label = "Time Dodge", short = "Dodge",
  icon = "icon_clock", color = { 0.30, 0.70, 0.85 }, tier = "curated", make = make_timedodge }
