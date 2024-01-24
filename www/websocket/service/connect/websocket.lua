local skynet = require "skynet"
local socket = require "skynet.socket"
local websocket = require "http.websocket"
local console = require 'utils/console'
local cmd = {}
local handler = {}
local clients = {}
local is_run = true

-- 接受 skynet.newservice 传递过来的参数
local params = { ... }

-- 通过 id 获取 client 信息
function cmd.getClientById(id)
    for _, client in pairs(clients) do
        if (client.fd == id) then
            return client
        end
    end
    return nil
end

-- 通过 connect code 获取 client 信息
function cmd.getClientByCode(code)
    if clients[code] == nil then return end

    return clients[code]
end

local function closeConnect(connect_code)
    if clients[connect_code] == nil then return end
    
    console.log(string.format('断开连接 addr:%s fd:%s', clients[connect_code]['addr'], clients[connect_code]['fd']))

    -- 清理退出相关逻辑（用户退出房间，用户退出系统）

    -- 清理 websocket
    local fd = clients[connect_code]['fd']
    clients[connect_code] = nil
    websocket.close(fd)
end

function handler.connect(id)
    console.log('ws connect from: ' .. tostring(id))

    local client = cmd.getClientById(id)
    if client ~= nil then
        closeConnect(client.connect_code)
    end
end

function handler.handshake(id, header, url)
    local addr = websocket.addrinfo(id)

    console.log(string.format('ws handshake from: %s  url: %s addr: %s', tostring(id), url, addr))
    
    -- console.log('------ header ------')
    -- for k, v in pairs(header) do
    --     console.log(string.format('%s %s', k, v))
    -- end
    -- console.log('------------')

    local client = {}
    client.connect_code = console.uuid()
    client.fd = id
    client.addr = addr
    client.time = os.time() + 12
    clients[client.connect_code] = client
end

function handler.message(id, msg, msg_type)
    assert(msg_type == 'binary' or msg_type == 'text')

    websocket.write(id, msg)

    -- 维持心跳时间(os.time 时间戳秒)
    local client = cmd.getClientById(id)
    if client ~= nil then
        client.time = os.time() + 12
    end
end

function handler.ping(id)
    console.log('ws ping from: ' .. tostring(id))
end

function handler.pong(id)
    console.log('ws pong from: ' .. tostring(id))
end

function handler.close(id, code, reason)
    console.log(string.format('ws close from: %s %s %s', tostring(id), code, reason))
end

function handler.error(id)
    console.log('ws error from: ' .. tostring(id))
end

local function websocketAccept(id, protocol, addr)
    local ok, err = websocket.accept(id, handler, protocol, addr)
    if not ok then
        console.log('dispatch error' .. err)
    end
end

-- 构建心跳
local function startHeartbeat()
    while true do
        -- 阻塞 10 秒
        skynet.sleep(1000)

        if not is_run then
            break
        end

        if next(clients) == nil then
            goto ContinueHeartbeat
        end

        local time = os.time()
        for connect_code, client in pairs(clients) do
            print(connect_code, client.fd)
            if client.time <= time then
                closeConnect(connect_code)
            end
        end

        ::ContinueHeartbeat::
    end
end

local function start(...)
    local protocol, port = ...
    local id = socket.listen('0.0.0.0', port)
    socket.start(id, function(id, addr)
        console.log(string.format('accept client socket_id: %s addr:%s', id , addr))
        websocketAccept(id, protocol, addr)
    end)

    -- 启动一个新的携程，来处理心跳
    skynet.fork(startHeartbeat)

    console.log(string.format('Listen weboscket protocol: %s port: %s', protocol, port))
end

skynet.start(function()
    start(table.unpack(params))
end)