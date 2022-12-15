-- repl
-- @eigen
--
--   <ok> (4)
--   >> print("hello world!")
--
--
-- ▼ instructions below ▼
--
-- - E3: switch between the 2 REPLs
-- - E2: scroll UP/DOWN
-- - K1 + E2: scroll LEFT/RIGHT
--
-- keyboard:
-- - Enter: submit prompt
-- - Alt + arrows: scroll
-- - Ctrl+A: begining of line
-- - Ctrl+E: end of line
-- - Ctrl+W: kill before (cut)
-- - Ctrl+K: kill after (cut)
-- - Ctrl+Y: yank (paste)
-- - Ctrl+L: clear


local UI = require "ui"

local repl_ui = include('lib/repl_ui')


-- ------------------------------------------------------------------------
-- STATE  - UI

local page_list = {'MAIDEN', 'SC'}
local pages = UI.Pages.new(1, #page_list)
local current_repl = 'MAIDEN'


-- ------------------------------------------------------------------------
-- CLOCKS

local redraw_clock = nil


-- ------------------------------------------------------------------------
-- IO - ENC

local shift = false

m.key = function(n, z)
  if n == 1  then
    if z == 1 then
      shift = true
    else
      shift = false
    end
  end
end

function enc(n, d)
  if n == 2 then
    if shift then
      repl_ui.output_scroll_horiz(current_repl, d)
    else
      repl_ui.output_scroll_vert(current_repl, d)
    end
  elseif n == 3 then
    pages:set_index_delta(d, false)
    current_repl = page_list[pages.index]
  end
end


-- ------------------------------------------------------------------------
-- IO - KBD - REPL PROMPTS

function keyboard.char(char)
  repl_ui.kbd_char(current_repl, char)
end

function keyboard.code(code, value)
  repl_ui.kbd_code(current_repl, code, value)
end


-- ------------------------------------------------------------------------
-- UI

function redraw()
  screen.clear()
  pages:redraw()
  repl_ui.redraw(current_repl)
  screen.update()
end


-- ------------------------------------------------------------------------
-- LIFECYCLE

function init()
  repl_ui.init()

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
  repl_ui.cleanup()
end
