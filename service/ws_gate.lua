local skynet = require "skynet"
local socket = require "skynet.socket"
local websocket = require "http.websocket"
local httpd = require "http.httpd"
local urllib = require "http.url"
local sockethelper = require "http.sockethelper"
local cjson = require "cjson"

local game
local id2player = {}
local wss = {}

local ws_port = ...

skynet.start(function()
    local address = "0.0.0.0:" .. ws_port
    local protocol = "ws"
    skynet.error("Listening " .. address)
    local listen_id = socket.listen("0.0.0.0", ws_port)
    if not listen_id then
        skynet.error("Failed to create listening socket")
        return
    end
    local agent = skynet.newservice("agent", "agent")
    if not agent then
        skynet.error("Failed to create agent service")
        return
    end
    -- 启动监听套接字
    socket.start(listen_id, function(fd, addr)
        skynet.error(string.format("accept client socket_id: %d addr:%s", fd, addr))
        -- 将连接信息传递给代理服务
        skynet.send(agent, "lua", fd, protocol, addr)
    end)
    -- 创建游戏服务
    game = skynet.newservice("game")
end)
