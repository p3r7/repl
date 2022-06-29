-- local frame = require'websocket.frame'
local frame = include('lib/lua-websockets/src/websocket/frame')

return {
  -- client = require'websocket.client',
  -- server = require'websocket.server',
  client = include('lib/lua-websockets/src/websocket/client'),
  -- server = include('lib/lua-websockets/src/websocket/server'),
  CONTINUATION = frame.CONTINUATION,
  TEXT = frame.TEXT,
  BINARY = frame.BINARY,
  CLOSE = frame.CLOSE,
  PING = frame.PING,
  PONG = frame.PONG
}
