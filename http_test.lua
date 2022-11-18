
-- ------------------------------------------------------------------------
-- DEPS

local script_path = "/home/we/dust/code/repl"

local version = _VERSION:match("%d+%.%d+")
local local_module_path = script_path .. "/lua_modules/share/lua/" .. version .. "/"
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


-- ------------------------------------------------------------------------
-- MAIN

local ws = websocket.new_from_uri('ws://norns.local:5555', {'bus.sp.nanomsg.org'})
ok = ws:connect()
if ok then
  print("hello")
end
  -- ws:connect()
  -- assert(ws:send("print('hello')\n"))
  -- local data = assert(ws:receive())
  -- assert(data == "hello")
  -- assert(ws:close())
