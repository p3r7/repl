

local version = _VERSION:match("%d+%.%d+")
local local_module_path = norns.state.path .. "/lib/lua_modules/share/lua/" .. version .. "/"
if not string.find(package.path, local_module_path.."?.lua") then
  package.path = local_module_path.."?.lua" .. ";" .. package.path
end
if not string.find(package.path, local_module_path.."?/init.lua") then
  package.path = local_module_path.."?/init.lua" .. ";" .. package.path
end
if not string.find(package.cpath, local_module_path.."?.so") then
  package.cpath = local_module_path.."?.so" .. ";" .. package.cpath
end

local websocket = require "http.websocket"

local last_message = "NOTHING"

local logfile = nil
local logfilepath = "/tmp/repl_log"

local function printl(message)
  if logfile ~= nil then
    logfile:write(message .. "\n")
    logfile:flush()
  end
end

local ws_client = nil

function init()

  logfile = io.open(logfilepath, "a")
  io.output(logfile)

  ws_client = websocket.new_from_uri('ws://norns:5555', {'bus.sp.nanomsg.org'})
  assert(ws_client:connect())

  assert(ws_client:send("print('hello')\n"))

  local message,opcode = ws_client:receive()
  if message then
    printl(message)
  else
    printl('connection closed')
  end


  local counter = 0
  while counter < 100 do
    data = ws_client:receive(1)
    if data ~= nil then
      printl(data)
    end
    counter = counter + 1
  end

  -- ws_receive_clock = clock.run(ws_receive)

  redraw_clock = clock.run(
    function()
      local step_s = 1 / 10
      while true do
        clock.sleep(step_s)
        redraw()
      end
  end)

  printl("INIT DONE!!!!!!!!!!")
end

function ws_receive()
  while true do
    data = ws_client:receive(1)
    if data ~= nil then
      last_message = data
    end
  end

end



function cleanup()
  logfile:close()
  local ok = ws_client:close()
end


-- keyboard.code = function(c, v)
--   if keyboard.codes[c] == 'ENTER' and v == 0 then
--     -- TODO: send
--   end
-- end

-- keyboard.char = function(a)
-- end

function redraw()
  screen.clear()
  screen.move(128/2, 64/2)
  screen.text(last_message)
  screen.update()
end
