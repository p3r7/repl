
local mod = require 'core/mods'
local state = require 'core/state'
local script = require 'core/script'
local UI = require "ui"

local repl_ui = require 'repl/lib/repl_ui'


-- -------------------------------------------------------------------------
-- MOD I/O

local m = {
  page_list = {'MAIDEN', 'SC'},
  pages = UI.Pages.new(1, 2),
  current_repl = 'MAIDEN',
}

m.init = function()
  -- (nothing to do)
end

m.deinit = function()
  -- (nothing to do)
end

m.key = function(n, z)
  -- (nothing to do)
end

m.enc = function(n, d)
  if n == 2 then
    m.pages:set_index_delta(d,false)
    m.current_repl = m.page_list[m.pages.index]
  end
  mod.menu.redraw()
end

m.redraw = function()
  screen.clear()
  m.pages:redraw()
  repl_ui.redraw(m.current_repl)
  screen.update()
end

m.keychar = function(char)
  repl_ui.kbd_char(m.current_repl, char)
  mod.menu.redraw()
end

m.keycode = function(code, value)
  repl_ui.kbd_code(m.current_repl, code, value)
  mod.menu.redraw()
end

mod.menu.register(mod.this_name, m)


-- -------------------------------------------------------------------------
-- LIFECYCLE BINDING

-- mod.hook.register("system_post_startup", "repl-sys-post-startup", function ()
--                     repl_ui.init()
-- end
--                   end
-- end)

mod.hook.register("script_pre_init", "repl-script-pre-init", function ()
                    if norns.state.shortname == 'repl' then
                      print("repl mod - not loading as launching companion script")
                      return
                    end
                    repl_ui.init(function(_unused)
                        if _menu.mode and _menu.page == "repl" then
                          mod.menu.redraw()
                        end
                    end)
end)

mod.hook.register("script_post_cleanup", "repl-script-post-cleanup", function ()
                    if norns.state.shortname == 'repl' then
                      print("repl mod - not cleaning as launched companion script")
                      return
                    end
                    repl_ui.cleanup()
end)
