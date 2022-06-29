

-- package.cpath = package.cpath .. ";" .. paths.code .. this_name .. "/lib/?.so"
package.cpath = package.cpath .. ";" .. norns.state.path .. "/lib/luasocket/src/?.so"
socket = require 'socket'

local copas = include('lib/copas/src/copas')

local websocket = include('lib/lua-websockets/src/websocket')
local client = websocket.client.copas({timeout=2})


function init()
  while not done do
    if co == nil then
      co = coroutine.create(cnnct)
    elseif coroutine.status(co) == "suspended" then
      coroutine.resume(co)
    elseif coroutine.status(co) == "dead" then
      done = true
    end
  end
end


function cnnct()
  local ok,err = client:connect('ws://norns.local:5555', 'bus.sp.nanomsg.org')
  if not ok then
    print('could not connect',err)
    return
  end


  ok = client:send("print('hello')\n")
  ok = client:send("print('hello')\n")
  ok = client:send("print('hello')\n")
  ok = client:send("\n")

  -- local message,opcode = client:receive()
  -- if message then
  --   print('msg',message,opcode)
  -- else
  --   print('connection closed')
  -- end
end

-- keyboard.code = function(c, v)
--   if keyboard.codes[c] == 'ENTER' and v == 0 then
--     -- TODO: send
--   end
-- end

-- keyboard.char = function(a)
-- end

function redraw()
end
