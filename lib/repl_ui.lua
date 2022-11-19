local repl_ui = {}


-- ------------------------------------------------------------------------
-- DEPS

local UI = require "ui"

local repl_osc = require 'repl/lib/repl_osc'
local fifo = require 'repl/lib/fifo'


-- ------------------------------------------------------------------------
-- STATE - PROMPTS

local prompts = {
  MAIDEN={
    text = "",
    kill = "",
    cursor = 0,
    submit_fn = repl_osc.send_maiden,
  },
  SC ={
    text = "",
    kill = "",
    cursor = 0,
    submit_fn = repl_osc.send_sc,
  },
}

local function prompt_before_cursor(repl)
  return string.sub(prompts[repl].text, 1, prompts[repl].cursor)
end

local function prompt_after_cursor(repl)
  return string.sub(prompts[repl].text, prompts[repl].cursor+1)
end

local function prompt_insert(repl, str)
  prompts[repl].text = prompt_before_cursor(repl) .. str .. prompt_after_cursor(repl)
  prompts[repl].cursor = prompts[repl].cursor + string.len(str)
end


-- ------------------------------------------------------------------------
-- REPL OUTPUTS

local log_buffer_length = 50

local out_buffs = {
  MAIDEN = {
    buff = fifo():setempty(function() return nil end),
    offset = 0,
  },
  SC = {
    buff = fifo():setempty(function() return nil end),
    offset = 0,
  },
}

local function clear_repl_output(output_buff)
  local length = output_buff:length()
  for i=1,length do
    output_buff:pop()
  end
end

local function normalized_repl_output_line(line, output_buff)
  -- tabs
  line = string.gsub(line, "\t", " ")

  -- special case of maiden "<ok>" outputs -> dedup those
  if line == "<ok>" then
    local prev_line_id = output_buff:length()
    if prev_line_id > 0 then
      local prev_line = output_buff:peek(prev_line_id)
      if util.string_starts(prev_line, "<ok>") then
        local count = 1
        local prev_count = string.match(prev_line, '^<ok> * %((%d*)%)$')
        if prev_count ~= nil  then
          count = prev_count + 1
        end
        line = "<ok> " .. "(" .. math.floor(count) .. ")"
        output_buff.data[prev_line_id] = line
        line = nil
      end
    end
  end

  return line
end

local function register_new_repl_output(output_buff, msg)
  for line in msg:gmatch("[^\n]+") do

    line = normalized_repl_output_line(line, output_buff)

    if line ~= nil then
      output_buff:push(line)
    end
  end
  while output_buff:length() > log_buffer_length do
    output_buff:pop()
  end
end

local function maiden_output_cb(msg)
  register_new_repl_output(out_buffs['MAIDEN'].buff, msg)
end

local function sc_output_cb(msg)
  register_new_repl_output(out_buffs['SC'].buff, msg)
end


-- ------------------------------------------------------------------------
-- UI

-- NB: can't show more than this w/ the default font
local max_nb_lines_to_show=5

local function draw_repl_logs(repl_buff, offset)
  screen.level(10)
  local buff_len = repl_buff:length()
  local nb_lines = math.min(buff_len, max_nb_lines_to_show)

  for i=1,(nb_lines) do
    local line = repl_buff:peek(buff_len-nb_lines-offset+i)
    if line ~= nil then
      screen.move(0, 10*i)
      screen.text(line)
    end
  end
end

-- NB: screen.text_extents trims !!!
-- hackish way: replace " " by "T", which works for default font
local function real_text_extends(text)
  return screen.text_extents(text:gsub("% ", "T"))
end

local function draw_repl_prompt(text, cursor)
  local ps = ">> "
  local y = 60

  screen.level(8)
  screen.move(0, y)
  screen.text(ps)

  local t_x = real_text_extends(ps)
  screen.level(15)
  screen.move(t_x, y)
  screen.text(text)

  local c_x = t_x + real_text_extends(string.sub(text, 1, cursor))
  local c_h = 8
  local text_upperline_h = 6 -- this depends on font...
  if cursor < string.len(text) then
    local char = string.sub(text, cursor+1, cursor+1)
    local c_w = real_text_extends(char) + 2
    screen.level(8)
    screen.rect(c_x, y-text_upperline_h, c_w, c_h)
    screen.fill()
    screen.level(0)
    screen.move(c_x + 1, y)
    screen.text(char)
  else
    local c_w = 5
    screen.level(8)
    screen.rect(c_x, y-text_upperline_h, c_w, c_h)
    screen.fill()
  end

end


-- ------------------------------------------------------------------------
-- EXPOSED SCRIPT API

function repl_ui.init()
  repl_osc.start()
  repl_osc.register_receive(maiden_output_cb, sc_output_cb)
end

function repl_ui.cleanup()
  repl_osc.stop()
end

function repl_ui.redraw(repl)
  -- logs
  draw_repl_logs(out_buffs[repl].buff, out_buffs[repl].offset)

  -- prompt
  draw_repl_prompt(prompts[repl].text, prompts[repl].cursor)
end

function repl_ui.kbd_char(repl, char)
  if keyboard.ctrl() then
    if char == "l" then
      clear_repl_output(out_buffs[repl].buff)
      out_buffs[repl].offset = 0
    elseif char == "a" then
      prompts[repl].cursor = 0
    elseif char == "e" then
      prompts[repl].cursor = string.len(prompts[repl].text)
    elseif char == "k" then
      prompts[repl].kill = prompt_after_cursor(repl)
      prompts[repl].text = prompt_before_cursor(repl)
    elseif char == "w" then
      prompts[repl].kill = prompt_before_cursor(repl)
      prompts[repl].text = prompt_after_cursor(repl)
      prompts[repl].cursor = 0
    elseif char == "y" then
      prompt_insert(repl, prompts[repl].kill)
    end
    return
  end

  prompt_insert(repl, char)
end

function repl_ui.kbd_code(repl, code, value)
  if code == 'BACKSPACE' and value > 0 then
    local before_cursor = prompt_before_cursor(repl)
    local after_cursor = prompt_after_cursor(repl)
    prompts[repl].text = string.sub(before_cursor, 1, -2) .. after_cursor
    prompts[repl].cursor = math.max(0, prompts[repl].cursor - 1)
  elseif code == 'DELETE' and value > 0 then
    local before_cursor = prompt_before_cursor(repl)
    local after_cursor = prompt_after_cursor(repl)
    prompts[repl].text = before_cursor .. string.sub(after_cursor, 2)
  elseif code == 'ENTER' and value > 0 then
    prompts[repl].submit_fn(prompts[repl].text)
    prompts[repl].text = ""
    prompts[repl].cursor = 0
  elseif code == 'LEFT' and value > 0 then
    prompts[repl].cursor = math.max(0, prompts[repl].cursor - 1)
  elseif code == 'RIGHT' and value > 0 then
    prompts[repl].cursor = math.min(string.len(prompts[repl].text), prompts[repl].cursor + 1)
  elseif code == 'UP' and value > 0 then
    out_buffs[repl].offset = math.min(out_buffs[repl].buff:length(), out_buffs[repl].offset + 1)
  elseif code == 'DOWN' and value > 0 then
    out_buffs[repl].offset = math.max(0, out_buffs[repl].offset - 1)
  end
end



-- ------------------------------------------------------------------------

return repl_ui
