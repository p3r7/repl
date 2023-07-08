local repl_ui = {}


-- ------------------------------------------------------------------------
-- DEPS

local repl_osc_gw = require 'repl/lib/repl_osc_gw'
local fifo = require 'repl/lib/fifo'


-- ------------------------------------------------------------------------
-- CONF

-- NB: can't show more than this w/ the default font
local max_nb_lines_to_show = 9
local lines_leading = 6


-- ------------------------------------------------------------------------
-- STATE - PROMPTS

prompts = {
  MAIDEN={
    text = "",
    kill = "",
    hist = {},
    offset = 0,
    cursor = 0,
    submit_fn = repl_osc_gw.send_maiden,
  },
  SC ={
    text = "",
    kill = "",
    hist = {},
    offset = 0,
    cursor = 0,
    submit_fn = repl_osc_gw.send_sc,
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
-- REPL INPUT HISTORY

function get_previous_input(repl)
  if #prompts[repl].hist == 0 then -- history is empty
    return prompts[repl].text
  end
  if prompts[repl].offset < #prompts[repl].hist then
    prompts[repl].offset = prompts[repl].offset + 1
  end
  local prev_input = prompts[repl].hist[#prompts[repl].hist - prompts[repl].offset + 1]
  return prev_input
end


function get_next_input(repl)
  -- FIXME: an Obi-Wan error somewhere, sometimes first "next" does not scroll the history
  if prompts[repl].offset > 0 and prompts[repl].offset <= #prompts[repl].hist then
    prompts[repl].offset = prompts[repl].offset - 1
    local next_input = prompts[repl].hist[#prompts[repl].hist - prompts[repl].offset]
    return next_input
  else
    -- return prompts[repl].text -- FIXME: return what the user was working on rather than blank.
    return ""
  end
end

-- ------------------------------------------------------------------------
-- REPL OUTPUTS

local log_buffer_length = 50

local out_buffs = {
  MAIDEN = {
    buff = fifo():setempty(function() return nil end),
    offset = {
      x = 0,
      y = 0,
    },
  },
  SC = {
    buff = fifo():setempty(function() return nil end),
    offset = {
      x = 0,
      y = 0,
    },
  },
}

local function clear_repl_output(output_buff)
  local length = output_buff:length()
  for i=1,length do
    output_buff:pop()
  end
end

local function offset_repl_output_up(out_buff, v)
  local nb_lines = out_buff.buff:length()
  if nb_lines <= max_nb_lines_to_show then
    return
  end
  if out_buff.offset.y == (nb_lines - max_nb_lines_to_show) then
    return
  end
  out_buff.offset.y = math.min(nb_lines, out_buff.offset.y + v)
end

local function offset_repl_output_down(out_buff, v)
  out_buff.offset.y = math.max(0, out_buff.offset.y - v)
end

local function offset_repl_output_vert(out_buff, v)
  if v == 0 then
    return
  end
  if v < 0 then
    offset_repl_output_down(out_buff, -v)
  else
    offset_repl_output_up(out_buff, v)
  end
end

function repl_ui.output_scroll_vert(repl, v)
  offset_repl_output_vert(out_buffs[repl], -math.floor(v))
end

local function offset_repl_output_horiz(out_buff, v)
  if v == 0 then
    return
  elseif v < 0 then
    v = -v
    out_buff.offset.x = math.max(0, out_buff.offset.x - v)
  else
    out_buff.offset.x = out_buff.offset.x + v
  end
end

function repl_ui.output_scroll_horiz(repl, v)
  offset_repl_output_horiz(out_buffs[repl], math.floor(v))
end

local function maybe_dedupped_repl_output_line(line, output_buff, search_line)
  if line == search_line then
    local prev_line_id = output_buff:length()
    if prev_line_id > 0 then
      local prev_line = output_buff:peek(prev_line_id)
      if util.string_starts(prev_line, search_line) then
        local count = 1
        local prev_count = string.match(prev_line, '^' .. search_line .. ' * %((%d*)%)$')
        if prev_count ~= nil  then
          count = prev_count + 1
        end
        line = search_line .. " (" .. math.floor(count) .. ")"
        output_buff.data[prev_line_id] = line
        return
      end
    end
  end

  return line
end

local function normalized_repl_output_line(line, output_buff)
  -- tabs
  line = string.gsub(line, "\t", " ")

  -- special case of common maiden outputs ("<ok>", "nil") -> dedup those
  line = maybe_dedupped_repl_output_line(line, output_buff, "<ok>")
  line = maybe_dedupped_repl_output_line(line, output_buff, "nil")

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

-- NB: screen.text_extents trims !!!
-- hackish way: replace " " by "T", which works for default font
local function real_text_extends(text)
  return screen.text_extents(text:gsub("% ", "T"))
end

local function draw_repl_logs(repl_buff, y_offset, x_offset)
  if x_offset == nil then
    x_offset = 0
  end

  local x = x_offset * real_text_extends(" ") * -1

  screen.level(10)
  local buff_len = repl_buff:length()
  local nb_lines = math.min(buff_len, max_nb_lines_to_show)

  for i=1,(nb_lines) do
    local line = repl_buff:peek(buff_len-nb_lines-y_offset+i)
    if line ~= nil then
      screen.move(x, lines_leading*i)
      screen.text(line)
    end
  end
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

function repl_ui.init(additional_cb)
  repl_osc_gw.start()
  repl_osc_gw.register_receive(maiden_output_cb, sc_output_cb, additional_cb)
end

function repl_ui.cleanup()
  repl_osc_gw.stop()
end

function repl_ui.redraw(repl)
  -- logs
  draw_repl_logs(out_buffs[repl].buff, out_buffs[repl].offset.y, out_buffs[repl].offset.x)

  -- prompt
  draw_repl_prompt(prompts[repl].text, prompts[repl].cursor)
end

function repl_ui.kbd_char(repl, char)
  if keyboard.ctrl() then
    if char == "l" then
      clear_repl_output(out_buffs[repl].buff)
      out_buffs[repl].offset.y = 0
    elseif char == "a" then
      prompts[repl].cursor = 0
    elseif char == "e" then
      prompts[repl].cursor = string.len(prompts[repl].text)
    elseif char == "b" then
      prompts[repl].cursor = math.max(0, prompts[repl].cursor - 1)
    elseif char == "f" then
      prompts[repl].cursor = math.min(string.len(prompts[repl].text), prompts[repl].cursor + 1)
    elseif char == "k" then
      prompts[repl].kill = prompt_after_cursor(repl)
      prompts[repl].text = prompt_before_cursor(repl)
    elseif char == "w" then
      prompts[repl].kill = prompt_before_cursor(repl)
      prompts[repl].text = prompt_after_cursor(repl)
      prompts[repl].cursor = 0
    elseif char == "y" then
      prompt_insert(repl, prompts[repl].kill)
    elseif char == "p" then
      prompts[repl].text = get_previous_input(repl)
      prompts[repl].cursor = string.len(prompts[repl].text)
    elseif char == "n" then
      prompts[repl].text = get_next_input(repl)
      prompts[repl].cursor = string.len(prompts[repl].text)
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
    -- FIXME: this clause is currently doing too much
    if prompts[repl].text ~= "" then
      table.insert(prompts[repl].hist, prompts[repl].text)
    end
    prompts[repl].offset = 0
    prompts[repl].submit_fn(prompts[repl].text)
    prompts[repl].text = ""
    prompts[repl].cursor = 0
  elseif code == 'LEFT' and value > 0 then
    if keyboard.alt() then
      out_buffs[repl].offset.x = math.max(0, out_buffs[repl].offset.x - 1)
    else
      prompts[repl].cursor = math.max(0, prompts[repl].cursor - 1)
    end
  elseif code == 'RIGHT' and value > 0 then
    if keyboard.alt() then
      out_buffs[repl].offset.x = out_buffs[repl].offset.x + 1
    else
      prompts[repl].cursor = math.min(string.len(prompts[repl].text), prompts[repl].cursor + 1)
    end
  elseif code == 'UP' and value > 0 then
    if keyboard.alt() then
      offset_repl_output_up(out_buffs[repl], 1)
    else
      prompts[repl].text = get_previous_input(repl)
      prompts[repl].cursor = string.len(prompts[repl].text)
    end
  elseif code == 'DOWN' and value > 0 then
    if keyboard.alt() then
      offset_repl_output_down(out_buffs[repl], 1)
    else
      prompts[repl].text = get_next_input(repl)
      prompts[repl].cursor = string.len(prompts[repl].text)
    end
  end
end



-- ------------------------------------------------------------------------

return repl_ui
