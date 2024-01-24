local skynet = require 'skynet'
require 'skynet.manager'
local console = require 'utils/console'

-- 定义必须的表房间表 用户表 路由表
local room_list = {}
local user_list = {}
local cmd = {}

local serviceGatewayName = '.ServiceGateway'

-- 启动网关
function cmd.startGateway(session,address, type, args)
    local ServiceGateway = skynet.newservice('service/gateway/service_gateway', args)
    skynet.name(serviceGatewayName, ServiceGateway)
end

local function dispatch(session, address, type, args)
    local res = cmd[type](session, address, type, args)
    if res ~= nil then
        skynet.repack(res)
    end
end

local function start()
    skynet.dispatch('lua', dispatch)
end

skynet.start(start)