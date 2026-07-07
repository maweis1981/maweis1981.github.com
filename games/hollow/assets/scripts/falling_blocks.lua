-- main.lua — "Tap the Falling Blocks"
--
-- Blocks fall from the top; tap one to score. Miss it (let it fall off the
-- bottom) and you lose a life. Three lives. Speed and spawn rate ramp up with
-- your score. Tap anywhere after Game Over to restart.
--
-- Host API (provided by Rust, see src/script.rs):
--   game.log(msg)
--   game.bounds() -> half_width, half_height   (world units, origin at center)
--   game.spawn(x, y, w, h, r, g, b) -> id
--   game.move_to(id, x, y)
--   game.despawn(id)
--   game.set_text(string)

local BLOCK = 76          -- block size in pixels
local START_LIVES = 3
local BASE_SPEED = 230    -- fall speed (px/s) at score 0
local BASE_INTERVAL = 0.9 -- seconds between spawns at score 0

local blocks = {}         -- id -> { x, y, vy }
local score, lives = 0, START_LIVES
local spawn_timer = 0
local playing = true

local function refresh_hud()
  if playing then
    game.set_text(string.format("Score: %d     Lives: %d", score, lives))
  else
    game.set_text(string.format("Game Over\nScore: %d\n\nTap to restart", score))
  end
end

local function clear_blocks()
  for id, _ in pairs(blocks) do
    game.despawn(id)
  end
  blocks = {}
end

local function reset()
  clear_blocks()
  score = 0
  lives = START_LIVES
  spawn_timer = 0
  playing = true
  refresh_hud()
end

function on_start()
  game.log("Tap the Falling Blocks — started")
  math.randomseed(1337)
  reset()
end

local function spawn_block(hw, hh)
  local margin = BLOCK * 0.5 + 6
  local x = (math.random() * 2 - 1) * (hw - margin)
  local y = hh + BLOCK
  -- warm, varied colors
  local r = 0.55 + math.random() * 0.45
  local g = 0.35 + math.random() * 0.40
  local b = 0.30 + math.random() * 0.45
  local id = game.spawn(x, y, BLOCK, BLOCK, r, g, b)
  blocks[id] = { x = x, y = y, vy = BASE_SPEED + score * 7 }
end

function on_update(dt)
  local hw, hh = game.bounds()
  if hw <= 0 then return end       -- window size not known yet
  if not playing then return end

  -- spawn cadence speeds up as the score grows
  local interval = math.max(0.32, BASE_INTERVAL - score * 0.012)
  spawn_timer = spawn_timer + dt
  if spawn_timer >= interval then
    spawn_timer = spawn_timer - interval
    spawn_block(hw, hh)
  end

  for id, blk in pairs(blocks) do
    blk.y = blk.y - blk.vy * dt
    game.move_to(id, blk.x, blk.y)
    if blk.y < -hh - BLOCK then
      game.despawn(id)
      blocks[id] = nil
      lives = lives - 1
      if lives <= 0 then
        playing = false
      end
      refresh_hud()
    end
  end
end

function on_tap(x, y)
  if not playing then
    reset()
    return
  end

  local half = BLOCK * 0.5
  for id, blk in pairs(blocks) do
    if math.abs(x - blk.x) <= half and math.abs(y - blk.y) <= half then
      game.despawn(id)
      blocks[id] = nil
      score = score + 1
      refresh_hud()
      return
    end
  end
end
