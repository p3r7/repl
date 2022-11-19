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

local function current_prompt_insert(str)
  prompts[current_repl].text = string.sub(prompts[current_repl].text, 1, prompts[current_repl].cursor) .. str .. string.sub(prompts[current_repl].text, prompts[current_repl].cursor+1, string.len(prompts[current_repl].text))
  prompts[current_repl].cursor = prompts[current_repl].cursor + string.len(str)
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
  if keyboard.ctrl() then
    if char == "l" then
      clear_repl_output(current_repl_out_buff())
    elseif char == "a" then
      prompts[current_repl].cursor = 0
    elseif char == "e" then
      prompts[current_repl].cursor = string.len(prompts[current_repl].text)
    elseif char == "k" then
      prompts[current_repl].kill = string.sub(prompts[current_repl].text, prompts[current_repl].cursor+1, string.len(prompts[current_repl].text))
      prompts[current_repl].text = string.sub(prompts[current_repl].text, 1, prompts[current_repl].cursor)
    elseif char == "w" then
      prompts[current_repl].kill = string.sub(prompts[current_repl].text, 1, prompts[current_repl].cursor)
      prompts[current_repl].text = string.sub(prompts[current_repl].text, prompts[current_repl].cursor+1, string.len(prompts[current_repl].text))
      prompts[current_repl].cursor = 0
    elseif char == "y" then
      current_prompt_insert(prompts[current_repl].kill)
    end
    return
  end

  current_prompt_insert(char)
end

function keyboard.code(code, value)
  if code == 'BACKSPACE' and value > 0 then
    prompts[current_repl].text = string.sub(prompts[current_repl].text, 1, -2)
    prompts[current_repl].cursor = math.max(0, prompts[current_repl].cursor - 1)
  elseif code == 'ENTER' and value > 0 then
    prompts[current_repl].submit_fn(prompts[current_repl].text)
    prompts[current_repl].text = ""
    prompts[current_repl].cursor = 0
  elseif code == 'LEFT' and value > 0 then
    prompts[current_repl].cursor = math.max(0, prompts[current_repl].cursor - 1)
  elseif code == 'RIGHT' and value > 0 then
    prompts[current_repl].cursor = math.min(string.len(prompts[current_repl].text), prompts[current_repl].cursor + 1)
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
  -- local t_x = 15
  screen.level(15)
  screen.move(t_x, y)
  screen.text(text)

  local c_x = t_x + real_text_extends(string.sub(text, 1, cursor))
  local c_h = 8
  local text_upperline_h = 6 -- this depend on font...
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
