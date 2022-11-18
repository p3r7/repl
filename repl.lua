

-- package.cpath = package.cpath .. ";" .. paths.code .. this_name .. "/lib/?.so"
-- package.cpath = package.cpath .. ";" .. norns.state.path .. "lib/luasocket/src/bin/?.so"
-- package.cpath = norns.state.path .. "lib/luasocket/src/bin/?.so" .. ";" .. package.cpath
-- socket = include("lib/luasocket/src/socket")
local socket = require("socket")

local copas = include('lib/copas/src/copas')

local websocket = include('lib/lua-websockets/src/websocket')

local last_message = "NOTHING"

local logfile = nil
local logfilepath = "/tmp/repl_log"

local function printl(message)
  if logfile ~= nil then
    logfile:write(message .. "\n")
    logfile:flush()
  end
end

local function loop (client)
  while client.state == "OPEN" do
    local message, opcode = client:receive()
    -- last_message = message
    -- redraw()
    printl("COPAS LOOP TICK")
    copas.sleep(5)
    -- local ok, err = client:send(json.encode(replymessage))
  end
end


function copas_init()

  printl("HELLO")

  local client = websocket.client.copas({timeout=1})
  local ok,err = client:connect('ws://norns.local:5555', 'bus.sp.nanomsg.org')

  printl("HELLO2")

  client:send("print('hello')\n")
  client:send("print('hello')\n")
  client:send("print('hello')\n")
  client:send("print('hello')\n")
  client:send("print('hello')\n")

  copas.addthread (function ()
      loop(client)
  end)
end

function init()
  logfile = io.open(logfilepath, "a")
  io.output(logfile)

  copas.addthread(copas_init)
  copas.loop()

  -- copas
  -- while not done do
  --   if co == nil then
  --     co = coroutine.create(cnnct)
  --   elseif coroutine.status(co) == "suspended" then
  --     coroutine.resume(co)
  --   elseif coroutine.status(co) == "dead" then
  --     done = true
  --   end
  -- end

  printl("INIT DONE!!!!!!!!!!")
end

redraw_clock = clock.run(
  function()
    local step_s = 1 / 10
    while true do
      clock.sleep(step_s)
      redraw()
    end
end)


function cleanup()
  logfile:close()
  local close_was_clean, close_code, close_reason = client:close(4001,'scipt_clear')
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
