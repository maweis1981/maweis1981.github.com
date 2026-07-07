-- gallery.lua — "深夜画廊" (Midnight Gallery): a mild-horror mystery
-- visual-novel / interrogation pack.
--
-- FLOW
--   · Select screen: three witnesses stand side by side (a "Charlie's Angels"
--     trio pose). Tapping one lunges her forward with a shake + zoom punch,
--     then opens her interview.
--   · Interview: her portrait + a typewriter subtitle panel voices a line
--     (game.play_voice of a Floniks-TTS clip; voice channel cuts the previous line); the player picks a question;
--     probing the right thread surfaces a CLUE and shifts her portrait to a
--     tense / frightened expression; soft questions get deflected.
--   · Once all three are interviewed the "指认真凶" (accuse) button appears.
--     Accusing the culprit with >= 2 clues wins; otherwise a bad end.
--
-- All art is Floniks-generated (base portrait -> image_to_image expression
-- variants for consistency); the eerie gallery backdrop is an i2i of the clean
-- scene. Chinese text renders through assets/fonts/game.ttf — every glyph used
-- here is registered in tools/subset_font.py (re-run it after editing copy).
-- Talks to the host ONLY through `game` + GAME_KIT.

function make_gallery()
  local K = GAME_KIT
  local inr = K.in_rect
  local T = K.tracker()

  local scr_hw, scr_hh = 215, 466
  local screen = "select"     -- "select" | "talk" | "accuse" | "end"
  local built = false
  local back = nil

  -- Which witnesses have been interviewed, and clues surfaced.
  local done = { coach = false, ol = false, teacher = false }
  local clues = { light = false, coat = false, slip = false }
  local function clue_count()
    local n = 0
    for _, v in pairs(clues) do if v then n = n + 1 end end
    return n
  end

  -- Portrait image keys per expression.
  local SUS = {
    { key = "coach",   name = "林薇", role = "网球教练", accent = { 0.30, 0.70, 0.66 },
      img = { calm = "vg_coach", tense = "vg_coach_t", fear = "vg_coach_f" }, voice = "vo_coach" },
    { key = "ol",      name = "苏晴", role = "会计",     accent = { 0.90, 0.66, 0.30 },
      img = { calm = "vg_ol", tense = "vg_ol_t", fear = "vg_ol_f" }, voice = "vo_ol" },
    { key = "teacher", name = "陈墨", role = "美术史讲师", accent = { 0.82, 0.28, 0.30 },
      img = { calm = "vg_teacher", tense = "vg_teacher_t", fear = "vg_teacher_f" }, voice = "vo_teacher" },
  }
  local function sus_by_key(k) for _, s in ipairs(SUS) do if s.key == k then return s end end end

  ----------------------------------------------------------------------------
  -- The interview scripts. Each is a table of keyed nodes:
  --   node = { expr, text, choices = { { text, goto, clue, voice } } }
  -- A node with no choices and a `next` is tap-to-continue; a terminal node
  -- has dest = "done" (back to the select screen, witness marked interviewed).
  ----------------------------------------------------------------------------
  local SCRIPT = {
    coach = {
      start = { expr = "calm", voice = "vo_coach",
        text = "我叫林薇，附近球馆的教练。每晚都绕美术馆夜跑，昨晚也不例外。",
        choices = {
          { text = "昨晚几点经过这里？", dest = "time" },
          { text = "夜跑时有没有反常的地方？", dest = "odd" },
        } },
      time = { expr = "calm",
        text = "大概九点十分。我记得很清楚——讲堂的灯还亮着，停车场只剩一辆车。",
        choices = {
          { text = "只剩一辆车？谁的车？", dest = "car", clue = "light" },
          { text = "灯亮着很正常吧。", dest = "shrug" },
        } },
      car = { expr = "tense",
        text = "陈老师那辆深灰的旅行车。可她讲座九点就该散了，人却没走……我当时就觉得别扭。",
        choices = { { text = "（记下：九点十分讲堂仍亮，只有陈墨的车）", dest = "done" } } },
      shrug = { expr = "calm",
        text = "正常是正常。可我跑了三年，从没见过九点还亮着、还锁着门的讲堂。",
        choices = { { text = "谁的车留在场里？", dest = "car", clue = "light" } } },
      odd = { expr = "fear",
        text = "有。跑到侧墙时，我分明听见馆里传来一声闷响，像有人喊了半句就没了声。我起鸡皮疙瘩，加速就走了。",
        choices = {
          { text = "几点听见的？", dest = "time" },
          { text = "是人的声音吗？", dest = "voice2" },
        } },
      voice2 = { expr = "fear",
        text = "是人的。老周……就是那个保安，嗓门我熟。可那一声太短了，短得不像话。",
        choices = { { text = "先记下这一声，再问几点。", dest = "time" } } },
    },

    ol = {
      start = { expr = "calm", voice = "vo_ol",
        text = "我是隔壁写字楼的会计，苏晴。赶月末的账，一个人加班到很晚。",
        choices = {
          { text = "昨晚有没有注意到美术馆这边？", dest = "see" },
          { text = "停电的时候你在做什么？", dest = "power" },
        } },
      power = { expr = "tense",
        text = "九点十四分，整条街忽然黑了一下。我记得分秒，因为屏幕上的表格没保存……那一下我心都凉了。",
        choices = {
          { text = "停电的瞬间你看见了什么？", dest = "figure", clue = "coat" },
          { text = "只是普通跳闸吧。", dest = "calmdown" },
        } },
      see = { expr = "calm",
        text = "注意到了。应急灯亮起来那几秒，我往窗外瞟了一眼卸货门那边。",
        choices = { { text = "看见了什么？", dest = "figure", clue = "coat" } } },
      figure = { expr = "fear",
        text = "一个穿长大衣的人影，正弯腰往门里拖一样长条的东西，用布裹着。动作很急。等应急灯稳住，人和东西都没了。",
        choices = {
          { text = "看清是男是女了吗？", dest = "who" },
          { text = "（记下：九点十四停电，长大衣人影拖走长条物）", dest = "done" },
        } },
      who = { expr = "fear",
        text = "没看清脸。但那身长大衣……不是保安的制服，是很讲究的料子。裹着的东西，跟一幅画一样长。",
        choices = { { text = "（记下：长大衣人影拖走画一样长的东西）", dest = "done", clue = "coat" } } },
      calmdown = { expr = "tense",
        text = "跳闸不会只黑一下又亮。而且偏偏就那一下，卸货门那边有动静。你真该去看看那扇门。",
        choices = { { text = "那扇门那边有什么？", dest = "figure", clue = "coat" } } },
    },

    teacher = {
      start = { expr = "calm", voice = "vo_teacher",
        text = "陈墨，美术史讲师。昨晚在这儿做《凝视者》的导览讲座。一幅好画，可惜了。",
        choices = {
          { text = "讲座几点结束，您几点离开？", dest = "leave" },
          { text = "您怎么评价那幅画的价值？", dest = "value" },
        } },
      value = { expr = "calm",
        text = "无价。它的目光会跟着看画的人走——站哪儿它都在盯着你。懂行的人，会为这样一幅画做很多事。",
        choices = { { text = "包括把它取走？", dest = "leave" } } },
      leave = { expr = "tense",
        text = "讲座九点整结束。我收拾了讲义，九点前后就走了，没多留。",
        choices = {
          { text = "有人看见您的车九点十分还在场里。", dest = "press1" },
          { text = "好的，那您没听见什么动静？", dest = "trap" },
        } },
      trap = { expr = "tense",
        text = "动静？……也就老周喊那一声吧。之后监控就全花了，黑灯瞎火的，谁也说不清。",
        choices = {
          { text = "您九点就走了，怎么会听见九点十四之后的那声喊？", dest = "gotcha", clue = "slip" },
          { text = "监控是自己坏的？", dest = "press1" },
        } },
      press1 = { expr = "tense",
        text = "……也许我多待了几分钟。整理东西而已，这也值得盘问？",
        choices = {
          { text = "整理到九点十四，正好停电、正好画没了？", dest = "trap" },
          { text = "那停电时您在哪儿？", dest = "gotcha", clue = "slip" },
        } },
      gotcha = { expr = "fear",
        text = "……我、我是说，是我后来听人转述的。别拿话套我。这画丢了，跟我没有半点关系。",
        choices = { { text = "（记下：陈墨说漏了只有在场才听得见的那声喊）", dest = "done" } } },
    },
  }

  ----------------------------------------------------------------------------
  -- Entity bookkeeping
  ----------------------------------------------------------------------------
  local ents = {}                         -- transient ids for the current screen
  local function wipe()
    for _, id in ipairs(ents) do game.despawn(id) end
    ents = {}
  end
  local function add(id) ents[#ents + 1] = id; return id end
  local function spr(x, y, w, h, name) return add(game.spawn_sprite(x, y, w, h, name)) end
  local function rect(x, y, w, h, r, g, b, a) return add(game.spawn(x, y, w, h, r, g, b, a)) end
  local function card(x, y, w, h, r, g, b, a)
    local id = add(game.spawn_sprite(x, y, w, h, "rcard")); game.set_color(id, r, g, b, a); return id
  end
  local function txt(x, y, s, r, g, b, a, str) return add(game.spawn_text(x, y, s, r, g, b, a, str)) end

  -- talk-scene state
  local cur = nil                         -- current suspect table
  local node = nil                        -- current node table
  local portrait_id, panel_name_id, panel_txt_id = nil, nil, nil
  local shown, full = 0, ""               -- typewriter progress / target
  local typing = false
  local choice_btns = {}                  -- { rect, goto, clue }
  local lunge = nil                       -- { id, x0, t } select-screen tap animation

  local DEBUG_last_clue = nil
  local voice_plays = 0

  ----------------------------------------------------------------------------
  -- Select screen
  ----------------------------------------------------------------------------
  local sel_btns = {}
  local accuse_btn = nil

  local function build_select()
    game.stop_voice()
    wipe(); sel_btns = {}; accuse_btn = nil
    spr(0, 0, scr_hw * 2 + 4, scr_hh * 2 + 4, "vg_gallery")
    rect(0, 0, scr_hw * 2 + 4, scr_hh * 2 + 4, 0.04, 0.05, 0.09, 0.45) -- darken
    back = K.make_back(T, scr_hw, scr_hh)
    txt(0, scr_hh - 120, 30, 0.93, 0.90, 0.86, 1, "深夜画廊")
    txt(0, scr_hh - 158, 15, 0.80, 0.30, 0.30, 1, "名画《凝视者》失窃 · 天亮前问清三人")

    local xs = { -scr_hw * 0.60, 0, scr_hw * 0.60 }
    local ys = { -30, -8, -30 }            -- centre one steps forward (trio pose)
    for i, s in ipairs(SUS) do
      local x, y = xs[i], ys[i]
      local pid = spr(x, y, 210, 315, s.img.calm)
      if done[s.key] then game.set_color(pid, 0.45, 0.48, 0.55, 1) end -- greyed once done
      card(x, y - 182, 150, 42, s.accent[1], s.accent[2], s.accent[3], 0.92)
      txt(x, y - 176, 17, 1, 1, 1, 1, s.name .. "·" .. s.role)
      if done[s.key] then txt(x, y + 150, 14, 0.75, 0.95, 0.75, 1, "已问询") end
      sel_btns[#sel_btns + 1] = { rect = { x = x, y = y, w = 210, h = 315 }, key = s.key, pid = pid, x0 = x }
    end

    local all = done.coach and done.ol and done.teacher
    if all then
      accuse_btn = { x = 0, y = -scr_hh + 96, w = 300, h = 70 }
      card(accuse_btn.x, accuse_btn.y, accuse_btn.w, accuse_btn.h, 0.82, 0.20, 0.22, 0.96)
      txt(accuse_btn.x, accuse_btn.y, 22, 1, 1, 1, 1, "指认真凶")
    else
      txt(0, -scr_hh + 96, 15, 0.85, 0.85, 0.90, 1, "点击一位证人开始问询")
    end
    screen = "select"
  end

  ----------------------------------------------------------------------------
  -- Talk screen
  ----------------------------------------------------------------------------
  local function set_line(n)
    node = n
    full = n.text or ""
    shown = 0
    typing = true
    if portrait_id then game.set_sprite_image(portrait_id, cur.img[n.expr or "calm"]) end
    if n.voice then game.play_voice(n.voice); voice_plays = voice_plays + 1 end
    if n.expr == "fear" then game.shake(0.18); game.haptic("medium")
    elseif n.expr == "tense" then game.haptic("light") end
    -- clear old choice buttons; they reappear when typing completes
    for _, b in ipairs(choice_btns) do
      if b.card then game.despawn(b.card) end
      if b.tid then game.despawn(b.tid) end
    end
    choice_btns = {}
  end

  local function build_talk(s)
    wipe()
    cur = s
    spr(0, 40, scr_hw * 2 + 4, scr_hh * 2 + 4, "vg_gallery_dark")
    rect(0, 0, scr_hw * 2 + 4, scr_hh * 2 + 4, 0.03, 0.04, 0.08, 0.5)
    back = K.make_back(T, scr_hw, scr_hh)
    portrait_id = spr(0, 96, 300, 450, s.img.calm)
    -- name plate + text panel
    card(0, -scr_hh + 150, scr_hw * 2 - 24, 168, 0.07, 0.08, 0.13, 0.94)
    card(-scr_hw + 92, -scr_hh + 238, 150, 40, s.accent[1], s.accent[2], s.accent[3], 0.95)
    panel_name_id = txt(-scr_hw + 92, -scr_hh + 238, 18, 1, 1, 1, 1, s.name)
    panel_txt_id = txt(0, -scr_hh + 150, 15, 0.95, 0.94, 0.90, 1, "")
    screen = "talk"
    set_line(SCRIPT[s.key].start)
  end

  local function reflow_text()
    if panel_txt_id then game.despawn(panel_txt_id) end
    -- word-wrap the revealed prefix to ~15 CJK chars/line
    local sub = gv_prefix(full, shown)
    panel_txt_id = txt(0, -scr_hh + 150, 15, 0.95, 0.94, 0.90, 1, gv_wrap(sub, 15))
    ents[#ents + 1] = panel_txt_id
  end

  local function show_choices()
    for _, b in ipairs(choice_btns) do
      if b.card then game.despawn(b.card) end
      if b.tid then game.despawn(b.tid) end
    end
    choice_btns = {}
    local list = node.choices
    if not list then return end
    local n = #list
    local y0 = -scr_hh + 300
    for i, ch in ipairs(list) do
      local y = y0 + (n - i) * 52
      local r = { x = 0, y = y, w = scr_hw * 2 - 40, h = 46 }
      local cid = add(game.spawn_sprite(r.x, r.y, r.w, r.h, "rpill"))
      game.set_color(cid, 0.16, 0.18, 0.26, 0.96)
      local tid = add(game.spawn_text(r.x, r.y, 14, 0.95, 0.95, 1.0, 1, ch.text))
      choice_btns[#choice_btns + 1] = { rect = r, dest = ch.dest, clue = ch.clue, card = cid, tid = tid }
    end
  end

  local function advance_choice(ch)
    if ch.clue and clues[ch.clue] == false then
      clues[ch.clue] = true
      DEBUG_last_clue = ch.clue
      game.play_sound("score"); game.haptic("success")
    end
    if ch.dest == "done" then
      done[cur.key] = true
      build_select()
      return
    end
    local nxt = SCRIPT[cur.key][ch.dest]
    if nxt then set_line(nxt) end
  end

  ----------------------------------------------------------------------------
  -- Accuse + endings
  ----------------------------------------------------------------------------
  local acc_btns = {}
  local function build_accuse()
    game.stop_voice()
    wipe(); acc_btns = {}
    spr(0, 0, scr_hw * 2 + 4, scr_hh * 2 + 4, "vg_gallery_dark")
    rect(0, 0, scr_hw * 2 + 4, scr_hh * 2 + 4, 0.03, 0.03, 0.06, 0.6)
    back = K.make_back(T, scr_hw, scr_hh)
    txt(0, scr_hh - 150, 24, 0.95, 0.92, 0.88, 1, "凶手是谁？")
    txt(0, scr_hh - 186, 14, 0.80, 0.82, 0.88, 1, "线索：" .. clue_count() .. " / 3")
    for i, s in ipairs(SUS) do
      local y = scr_hh - 300 - (i - 1) * 190
      spr(-scr_hw + 130, y, 150, 168, s.img.calm)
      local r = { x = 40, y = y, w = scr_hw * 2 - 220, h = 150 }
      card(r.x, r.y, r.w, r.h, 0.10, 0.11, 0.17, 0.95)
      txt(r.x, r.y + 20, 18, 1, 1, 1, 1, s.name .. "·" .. s.role)
      txt(r.x, r.y - 22, 13, 0.80, 0.82, 0.90, 1, "指认这一位")
      acc_btns[#acc_btns + 1] = { rect = r, key = s.key }
    end
    screen = "accuse"
  end

  local function build_end(win)
    game.stop_voice()
    wipe()
    spr(0, 0, scr_hw * 2 + 4, scr_hh * 2 + 4, "vg_gallery_dark")
    rect(0, 0, scr_hw * 2 + 4, scr_hh * 2 + 4, 0.02, 0.02, 0.05, 0.72)
    back = K.make_back(T, scr_hw, scr_hh)
    if win then
      spr(0, 150, 300, 336, "vg_teacher_f")
      txt(0, -60, 26, 0.55, 0.95, 0.60, 1, "真相大白")
      txt(0, -120, 15, 0.92, 0.92, 0.95, 1,
        gv_wrap("陈墨用讲座做掩护，九点十四制造停电、取走《凝视者》，" ..
             "撞见的保安被她锁进地下室。她说漏的那声喊，出卖了她。", 16))
    else
      spr(0, 150, 300, 336, "vg_gallery_dark")
      txt(0, -60, 26, 0.95, 0.35, 0.32, 1, "指认错误")
      txt(0, -120, 15, 0.92, 0.90, 0.92, 1,
        gv_wrap("天亮了，真凶带着《凝视者》消失在城里。墙上的挂钩空着，" ..
             "像一只睁着的眼睛。再看一遍线索，也许还有机会。", 16))
    end
    txt(0, -scr_hh + 120, 15, 0.85, 0.88, 0.95, 1, "点击返回")
    screen = "end"
  end

  ----------------------------------------------------------------------------
  -- DEBUG surface for the headless tests
  ----------------------------------------------------------------------------
  local function expose()
    DEBUG = {
      game = "gallery", back = back,
      scene = function() return screen end,
      current = function() return cur and cur.key or nil end,
      node_text = function() return full end,
      clue_count = clue_count,
      has_clue = function(k) return clues[k] == true end,
      last_clue = function() return DEBUG_last_clue end,
      voice_plays = function() return voice_plays end,
      done = function(k) return done[k] end,
      typing = function() return typing end,
      select_btn = function(k) for _, b in ipairs(sel_btns) do if b.key == k then return b.rect end end end,
      choices = function() return choice_btns end,
      accuse_btn = function() return accuse_btn end,
      accuse_of = function(k) for _, b in ipairs(acc_btns) do if b.key == k then return b.rect end end end,
    }
  end

  ----------------------------------------------------------------------------
  -- Scene lifecycle
  ----------------------------------------------------------------------------
  return {
    enter = function()
      built = false
      game.play_music("gallery")
    end,
    leave = function()
      game.stop_voice()
      game.play_music("music")
      wipe(); T.clear(); built = false
      screen = "select"
      done = { coach = false, ol = false, teacher = false }
      clues = { light = false, coat = false, slip = false }
    end,
    tap = function(x, y)
      if back and inr(back, x, y) then
        if screen == "talk" or screen == "accuse" or screen == "end" then
          build_select(); expose(); return
        end
        K.switch("menu"); return
      end
      if not built then return end

      if screen == "select" then
        if accuse_btn and inr(accuse_btn, x, y) then build_accuse(); expose(); return end
        for _, b in ipairs(sel_btns) do
          if inr(b.rect, x, y) then
            lunge = { id = b.pid, x0 = b.x0, t = 0, key = b.key }
            game.shake(0.35); game.zoom(0.6); game.haptic("medium")
            return
          end
        end
        return
      end

      if screen == "talk" then
        if typing then
          shown = gv_len(full)   -- reveal all
          typing = false
          reflow_text()
          show_choices()
          return
        end
        if node.choices then
          for _, b in ipairs(choice_btns) do
            if inr(b.rect, x, y) then advance_choice(b); expose(); return end
          end
        else
          local nxt = node.next and SCRIPT[cur.key][node.next]
          if nxt then set_line(nxt) else build_select(); expose() end
        end
        return
      end

      if screen == "accuse" then
        for _, b in ipairs(acc_btns) do
          if inr(b.rect, x, y) then
            local win = (b.key == "teacher") and clue_count() >= 2
            build_end(win); expose(); return
          end
        end
        return
      end

      if screen == "end" then build_select(); expose(); return end
    end,
    update = function(dt, hw, hh)
      scr_hw, scr_hh = hw, hh
      if dt > 1 / 30 then dt = 1 / 30 end
      if not built then build_select(); built = true; expose() end

      -- select-screen lunge: portrait darts forward (grows), then opens talk
      if lunge then
        lunge.t = lunge.t + dt
        local f = lunge.t / 0.28
        if f >= 1 then
          local s = sus_by_key(lunge.key)
          lunge = nil
          build_talk(s); expose()
        else
          local pop = math.sin(f * math.pi) * 26
          game.set_size(lunge.id, 210 + pop * 1.6, 315 + pop * 2.4)
        end
      end

      -- typewriter
      if screen == "talk" and typing then
        local target = gv_len(full)
        shown = shown + dt * 45          -- chars/sec
        if shown >= target then
          shown = target; typing = false
          reflow_text(); show_choices()
        else
          reflow_text()
        end
      end
    end,
  }
end

-- UTF-8 helpers, kept pure-string so the web VM (ottavino) needs no utf8 lib.
-- Split a string into an array of whole codepoints (each a 1-4 byte substring).
function gv_chars(s)
  local out, pos = {}, 1
  while pos <= #s do
    local c = string.byte(s, pos)
    local len = 1
    if c >= 240 then len = 4 elseif c >= 224 then len = 3 elseif c >= 194 then len = 2 end
    out[#out + 1] = string.sub(s, pos, pos + len - 1)
    pos = pos + len
  end
  return out
end

function gv_len(s) return #gv_chars(s) end

-- The first `count` codepoints of `s`, concatenated.
function gv_prefix(s, count)
  local ch = gv_chars(s)
  local k = math.min(#ch, math.floor(count))
  return table.concat(ch, "", 1, k)
end

-- Word-wrap by codepoint count (CJK: one glyph = one column). Honours any
-- explicit "\n" already in the text by resetting the column count.
function gv_wrap(s, per)
  local out, col = {}, 0
  for _, c in ipairs(gv_chars(s)) do
    if c == "\n" then
      out[#out + 1] = c; col = 0
    else
      out[#out + 1] = c; col = col + 1
      if col >= per then out[#out + 1] = "\n"; col = 0 end
    end
  end
  return table.concat(out)
end

-- Self-register this game pack (see main.lua: the menu builds from PACKS).
PACKS = PACKS or {}
PACKS["gallery"] = { slot = 22, key = "gallery", label = "Midnight Gallery", short = "Mystery", icon = "vg_teacher", color = { 0.55, 0.30, 0.55 }, tier = "ai", make = make_gallery }
