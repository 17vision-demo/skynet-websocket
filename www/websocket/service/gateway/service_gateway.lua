local skynet = require 'skynet'
local console = require 'utils/console'

-- 路由
local cmd = {}

-- 接受 skynet.newservice 传递过来的参数
local params = { ... }

local function dispatch(session, address, type, args)
    local res = cmd[type](session,address, type, args)
    skynet.retpack(res)
end

local function start(...)
    local port = ...
    local ws = 'ws'
    skynet.newservice('service/connect/websocket', ws, port)
end

skynet.start(function()
    skynet.dispatch('lua', dispatch)

    start(table.unpack(params))
end)