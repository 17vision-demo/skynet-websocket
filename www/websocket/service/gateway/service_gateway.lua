local skynet = require 'skynet'
local console = require 'utils/console'

local Server = '.Server'

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
    local server = skynet.newservice('service/connect/websocket', ws, port)
    skynet.wait(Server)
    skynet.name(Server, server)
end

skynet.start(function()
    skynet.dispatch('lua', dispatch)

    start(table.unpack(params))
end)