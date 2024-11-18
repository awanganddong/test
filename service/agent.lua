-- agent.lua
local skynet = require "skynet"
local websocket = require "http.websocket"
local cjson = require "cjson"
local CMD = {}
local handle = {}
local wss = {}
-- 处理用户消息
function CMD.handle_message(id, cmd, data)
    skynet.error(string.format("Agent received handle_message with params: id=%d, cmd=%s, data=%s", id, cmd, cjson.encode(data)))
    -- 根据命令类型进行处理
    if cmd == "enter" then
        -- 处理登录逻辑
        local response = { success = true, message = "Login successful" }
        return response
    elseif cmd == "chat" then
        -- 处理聊天逻辑
        local response = { success = true, message = "Message received: " .. data.message }
        return response
    else
        local response = { success = false, message = "Unknown command" }
        return response
    end
end

function CMD.send(fd, msg)
    local ws = wss[fd]
    if not ws then
        return
    end
    websocket.write(fd, cjson.encode(msg))
end

function handle.connect(id)
    print("ws connect from: " .. tostring(id))
end

function handle.handshake(id, header, url)
    local addr = websocket.addrinfo(id)
    print("ws handshake from: " .. tostring(id), "url", url, "addr:", addr)
    print("----header-----")
    for k, v in pairs(header) do
        print(k, v)
    end
    print("--------------")
    wss[id] = 1
end

function handle.message(id, msg, msg_type)
    assert(msg_type == "binary" or msg_type == "text")
    local data = cjson.decode(msg)
    local cmd = data.cmd
    local content = data.content
    -- 调用 CMD 中的命令处理函数
    local response = CMD.handle_message(id, cmd, content)
    -- 发送响应给客户端
    CMD.send(id, response)
end

function handle.ping(id)
    print("ws ping from: " .. tostring(id) .. "\n")
end

function handle.pong(id)
    print("ws pong from: " .. tostring(id))
end

function handle.close(id, code, reason)
    print("ws close from: " .. tostring(id), code, reason)
end

function handle.error(id)
    print("ws error from: " .. tostring(id))
end
-- 注册命令处理函数
skynet.start(function()
    --session：会话标识符。如果 session 不为 0，表示这是一个需要响应的消息
    --发送消息的服务的标识符
    --命令名称，表示消息的具体操作
    --可变参数列表，表示传递给命令的具体参数
    skynet.dispatch("lua", function(_, _, fd, protocol, addr)
        local ok, err = websocket.accept(fd, handle, protocol, addr)
        if not ok then
            skynet.error(string.format("accept client err: %s", err))
            return
        end
    end)
end)
