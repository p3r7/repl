local repl_osc = {}


-- ------------------------------------------------------------------------
-- DEPS

-- if not string.find(package.cpath,"/home/we/dust/code/repl/lib/") then
--   package.cpath=package.cpath..";/home/we/dust/code/repl/lib/?.so"
-- end
-- local json=require("cjson")


-- ------------------------------------------------------------------------
-- CONF

local ws_osc_wrapper_bin = "repl-ws-osc-gw"
local ws_osc_wrapper_bin_path = "/home/we/dust/code/repl/repl-ws-osc-gw"
local osc_path_maiden = "/repl-gw-maiden"
local osc_path_sc = "/repl-gw-sc"
local gw_host = "localhost"
local gw_osc_port = 10666


-- ------------------------------------------------------------------------
-- CORE - OS

function os.capture(cmd,raw)
  local f=assert(io.popen(cmd,'r'))
  local s=assert(f:read('*a'))
  f:close()
  if raw then return s end
  s=string.gsub(s,'^%s+','')
  s=string.gsub(s,'%s+$','')
  s=string.gsub(s,'[\n\r]+',' ')
  return s
end


-- ------------------------------------------------------------------------
-- LIFECYCLE

function repl_osc.start()
  local pid=os.capture("pidof " .. ws_osc_wrapper_bin)
  if pid=="" then
    os.execute(ws_osc_wrapper_bin_path .. " &")
  end
end

function repl_osc.stop()
  os.execute("pkill -9 -f " .. ws_osc_wrapper_bin)
end


-- ------------------------------------------------------------------------
-- API

function repl_osc.register_receive(maiden_fn, sc_fn)
  local old_osc_in = osc.event
  osc.event=function(path, args, from)
    if old_osc_in ~= nil then
      old_osc_in(path, args, from)
    end
    if path == osc_path_maiden and maiden_fn ~= nil then
      local d = args[1]
      maiden_fn(d)
    elseif path == osc_path_sc and sc_fn ~= nil then
      local d = args[1]
      sc_fn(d)
    end
  end
end

function repl_osc.send_maiden(msg)
  osc.send({"localhost", gw_osc_port}, osc_path_maiden, {msg .. "\n"})
end

function repl_osc.send_sc(msg)
  osc.send({"localhost", gw_osc_port}, osc_path_sc, {msg .. "\n"})
end


-- ------------------------------------------------------------------------

return repl_osc
