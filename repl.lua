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

local prompts = {
  MAIDEN={
    text = "",
    cursor = 0,
    submit_fn = repl_osc.send_maiden,
  },
  SC ={
    text = "",
    cursor = 0,
    submit_fn = repl_osc.send_sc,
  },
}


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

  prompts[current_repl].text = prompts[current_repl].text .. char
  prompts[current_repl].cursor = prompts[current_repl].cursor + 1
end

function keyboard.code(code, value)
  if code == 'BACKSPACE' and value > 0 then
    prompts[current_repl].text = string.sub(prompts[current_repl].text, 1, -2)
    prompts[current_repl].cursor = math.max(0, prompts[current_repl].cursor - 1)
  elseif code == 'ENTER' and value > 0 then
    prompts[current_repl].submit_fn(prompts[current_repl].text)
    prompts[current_repl].text = ""
    prompts[current_repl].cursor = 0
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
  draw_repl_prompt(prompts[current_repl].text, prompts[current_repl].cursor)

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
