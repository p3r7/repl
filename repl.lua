-- repl

local UI = require "ui"

local repl_osc = include('lib/repl_osc')
local fifo = include('lib/fifo')


-- ------------------------------------------------------------------------
-- CLOCKS

local redraw_clock = nil


-- ------------------------------------------------------------------------
-- STATE - UI

local page_list = {'MAIDEN', 'SC'}
local pages = UI.Pages.new(1, #page_list)
local current_repl = 'MAIDEN'


-- ------------------------------------------------------------------------
-- STATE - PROMPTS

-- TODO: store then in a table to prevent all those if/else shenanigans

-- local prompts = {
--   MAIDEN={
--     text = "",
--     cursor = 0,
--   },
--   SC ={
--     text = "",
--     cursor = 0,
--   },
-- }

local maiden_repl_prompt_cursor = 0
local maiden_repl_prompt = ""
local sc_repl_prompt_cursor = 0
local sc_repl_prompt = ""

local function current_prompt()
  if current_repl == 'MAIDEN' then
    return maiden_repl_prompt
  elseif current_repl == 'SC' then
    return sc_repl_prompt
  end
end

local function current_prompt_cursor()
  if current_repl == 'MAIDEN' then
    return maiden_repl_prompt_cursor
  elseif current_repl == 'SC' then
    return sc_repl_prompt_cursor
  end
end

local function add_char_to_current_prompt(char)
  if current_repl == 'MAIDEN' then
    maiden_repl_prompt = maiden_repl_prompt .. char
    maiden_repl_prompt_cursor = maiden_repl_prompt_cursor + 1
  elseif current_repl == 'SC' then
    sc_repl_prompt = sc_repl_prompt .. char
    sc_repl_prompt_cursor = sc_repl_prompt_cursor + 1
  end
end

local function remove_char_left_current_prompt()
  if current_repl == 'MAIDEN' then
    maiden_repl_prompt = string.sub(maiden_repl_prompt, 1, -2)
    maiden_repl_prompt_cursor = math.max(0, maiden_repl_prompt_cursor - 1)
  elseif current_repl == 'SC' then
    sc_repl_prompt = string.sub(sc_repl_prompt, 1, -2)
    sc_repl_prompt_cursor = math.max(0, sc_repl_prompt_cursor - 1)
  end
end

-- ------------------------------------------------------------------------
-- REPL OUTPUTS

local log_buffer_length = 50

  local maiden_output = fifo():setempty(function() return nil end)
  local sc_output = fifo():setempty(function() return nil end)

  local function current_repl_out_buff()
  if current_repl == 'MAIDEN' then
    return maiden_output
  elseif current_repl == 'SC' then
    return sc_output
  end
end

local function register_new_repl_output(output_buff, msg)
  for line in msg:gmatch("[^\n]+") do
    line = string.gsub(line, "\t", " ")
    output_buff:push(line)
  end
  while output_buff:length() > log_buffer_length do
    output_buff:pop()
  end
end

local function clear_repl_output(output_buff)
  local length = output_buff:length()
  for i=1,length do
    output_buff:pop()
  end
end

local function maiden_output_cb(msg)
  register_new_repl_output(maiden_output, msg)
end

local function sc_output_cb(msg)
  register_new_repl_output(sc_output, msg)
end


-- ------------------------------------------------------------------------
-- IO - ENC

function enc(n, d)
  if n == 1 then
    pages:set_index_delta(d,false)
    current_repl = page_list[pages.index]
  end
end


-- ------------------------------------------------------------------------
-- IO - KBD - REPL PROMPTS

function keyboard.char(char)
  if char == "l" and keyboard.ctrl() then
    clear_repl_output(current_repl_out_buff())
    return
  end

  add_char_to_current_prompt(char)
end

function keyboard.code(code, value)
  if code == 'BACKSPACE' and value > 0 then
    remove_char_left_current_prompt()
  elseif code == 'ENTER' and value > 0 then
    if current_repl == 'MAIDEN' then
      repl_osc.send_maiden(maiden_repl_prompt)
      maiden_repl_prompt = ""
    elseif current_repl == 'SC' then
      repl_osc.send_sc(sc_repl_prompt)
      sc_repl_prompt = ""
    end
  end
end


-- ------------------------------------------------------------------------
-- UI

-- NB: can't show more than this w/ the default font
local max_nb_lines_to_show=5

local function draw_repl_logs(repl_output)
  screen.level(10)
  local buff_len = repl_output:length()
  local nb_lines = math.min(buff_len, max_nb_lines_to_show)

  for i=1,(nb_lines+1) do
    local line = repl_output:peek(buff_len-nb_lines+i)
    if line ~= nil then
      screen.move(0, 10*i)
      screen.text(line)
    end
  end
end

local function draw_repl_prompt(text, cursor)
  screen.level(8)
  screen.move(0, 60)
  screen.text(">> ")
  screen.level(15)
  screen.move(15, 60)
  screen.text(text)
end

function redraw()
  screen.clear()

  pages:redraw()

  -- logs
  draw_repl_logs(current_repl_out_buff())

  -- prompt
  draw_repl_prompt(current_prompt(), current_prompt_cursor())

  screen.update()
end


-- ------------------------------------------------------------------------
-- LIFECYCLE

function init()
  repl_osc.start()
  repl_osc.register_receive(maiden_output_cb, sc_output_cb)

  redraw_clock = clock.run(
    function()
      local step_s = 1 / 10
      while true do
        clock.sleep(step_s)
        redraw()
      end
  end)
end

function cleanup()
  repl_osc.stop()
  if redraw_clock ~= nil then
    clock.cancel(redraw_clock)
  end
end
