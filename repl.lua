-- repl

local UI = require "ui"

local repl_osc = include('lib/repl_osc')
local fifo = include('lib/fifo')


-- ------------------------------------------------------------------------
-- CLOCKS

local redraw_clock = nil


-- ------------------------------------------------------------------------
-- STATE

local page_list = {'MAIDEN', 'SC'}
local pages = UI.Pages.new(1, #page_list)
local current_repl = 'MAIDEN'

local maiden_repl_prompt = ""
local sc_repl_prompt = ""


-- ------------------------------------------------------------------------
-- REPL OUTPUTS

local log_buffer_length = 50

local maiden_output = fifo():setempty(function() return nil end)
local sc_output = fifo():setempty(function() return nil end)

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

-- TODO: cursor position

function keyboard.char(char)
  if char == "l" and keyboard.ctrl() then
    if current_repl == 'MAIDEN' then
      clear_repl_output(maiden_output)
    elseif current_repl == 'SC' then
      clear_repl_output(sc_output)
    end
    return
  end

  if current_repl == 'MAIDEN' then
    maiden_repl_prompt = maiden_repl_prompt .. char
  elseif current_repl == 'SC' then
    sc_repl_prompt = sc_repl_prompt .. char
  end
end

function keyboard.code(code, value)
  if code == 'BACKSPACE' and value > 0 then
    if current_repl == 'MAIDEN' then
      maiden_repl_prompt = string.sub(maiden_repl_prompt, 1, -2)
    elseif current_repl == 'SC' then
      sc_repl_prompt = string.sub(sc_repl_prompt, 1, -2)
    end
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

function redraw()
  screen.clear()

  pages:redraw()

  -- logs
  screen.level(10)
  if current_repl == 'MAIDEN' then
    draw_repl_logs(maiden_output)
  elseif current_repl == 'SC' then
    draw_repl_logs(sc_output)
  end

  -- prompt
  screen.level(8)
  screen.move(0, 60)
  screen.text(">> ")
  screen.level(15)
  screen.move(15, 60)
  if current_repl == 'MAIDEN' then
    screen.text(maiden_repl_prompt)
  elseif current_repl == 'SC' then
    screen.text(sc_repl_prompt)
  end

  screen.update()
end


-- ------------------------------------------------------------------------
-- LIFECYCLE

function init()

  print('-----> starting WS to OSC gw')
  repl_osc.start()

  print('-----> registering cb functions')
  repl_osc.register_receive(maiden_output_cb, sc_output_cb)

  print('redraw')
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
