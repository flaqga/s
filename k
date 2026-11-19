local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local defaultMaxPlayers = 12
if type(Players.MaxPlayers) == "number" and Players.MaxPlayers > 0 then
    defaultMaxPlayers = Players.MaxPlayers
end

local visitedFile = "assist_astra_visited_servers.json"
local settingsFile = "assist_astra_settings.json"

local ACCENT = Color3.fromRGB(255, 139, 63)
local ACCENT_HOVER = Color3.fromRGB(255, 165, 105)
local BG_TOP = Color3.fromRGB(34, 26, 41)
local BG_BOTTOM = Color3.fromRGB(23, 17, 28)
local PANEL = Color3.fromRGB(43, 33, 51)
local PANEL_HOVER = Color3.fromRGB(55, 42, 65)
local FIELD = Color3.fromRGB(25, 19, 31)
local TEXT = Color3.fromRGB(245, 237, 223)
local MUTED = Color3.fromRGB(165, 151, 176)
local DANGER = Color3.fromRGB(232, 102, 88)
local SUCCESS = Color3.fromRGB(124, 202, 120)

local function readJson(path)
    if type(readfile) ~= "function" then return nil end
    local ok, data = pcall(readfile, path)
    if not ok or type(data) ~= "string" or data == "" then return nil end
    local dok, decoded = pcall(HttpService.JSONDecode, HttpService, data)
    if dok and type(decoded) == "table" then return decoded end
    return nil
end

local function writeJson(path, value)
    if type(writefile) ~= "function" then return end
    local ok, data = pcall(HttpService.JSONEncode, HttpService, value)
    if ok then pcall(writefile, path, data) end
end

local function quote(value)
    local escaped = value:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\r", "\\r")
    return '"' .. escaped .. '"'
end

local settings = {
    autoExecute = false,
    loader = "assist_astra.lua",
}

local saved = readJson(settingsFile)
local hasLoader = false
if saved then
    if type(saved.autoExecute) == "boolean" then settings.autoExecute = saved.autoExecute end
    if type(saved.loader) == "string" and saved.loader ~= "" then
        settings.loader = saved.loader
        hasLoader = true
    end
end

if not hasLoader and type(isfile) == "function"
    and type(debug) == "table" and type(debug.info) == "function" then
    local ok, source = pcall(debug.info, 1, "s")
    if ok and type(source) == "string" then
        local path = source:gsub("^[@=]", "")
        local fok, exists = pcall(isfile, path)
        if path ~= "" and fok and exists then
            settings.loader = path
        end
    end
end

local function normalizeId(id)
    if type(id) ~= "string" and type(id) ~= "number" then return nil end
    local text = tostring(id):gsub("^%s+", ""):gsub("%s+$", ""):lower()
    text = text:gsub("^{", ""):gsub("}$", "")
    if text == "" then return nil end
    return text
end

local visited = {}

local function markVisited(id)
    local key = normalizeId(id)
    if key then visited[key] = true end
    return key
end

local function saveVisited()
    local out = {}
    for id in pairs(visited) do
        out[id] = true
    end
    writeJson(visitedFile, out)
end

local function unmarkVisited(id)
    local key = normalizeId(id)
    if key then visited[key] = nil end
end

local function loadVisited()
    local data = readJson(visitedFile)
    if type(data) ~= "table" then return end
    for key, value in pairs(data) do
        if value == true or value == 1 then
            markVisited(key)
        end
    end
    for _, value in ipairs(data) do
        if type(value) == "string" then
            markVisited(value)
        end
    end
end

local function visitedCount()
    local count = 0
    for _ in pairs(visited) do
        count = count + 1
    end
    return count
end

if type(_G.AssistVisitedServers) == "table" then
    for id, value in pairs(_G.AssistVisitedServers) do
        if value == true or value == 1 then
            markVisited(id)
        elseif type(value) == "string" then
            markVisited(value)
        end
    end
end

loadVisited()
_G.AssistVisitedServers = visited

if type(game.JobId) == "string" and game.JobId ~= "" then
    markVisited(game.JobId)
end
saveVisited()

local function getQueueFunction()
    if type(queue_on_teleport) == "function" then return queue_on_teleport end
    if type(queueonteleport) == "function" then return queueonteleport end
    if type(syn) == "table" and type(syn.queue_on_teleport) == "function" then
        return syn.queue_on_teleport
    end
    if type(fluxus) == "table" and type(fluxus.queue_on_teleport) == "function" then
        return fluxus.queue_on_teleport
    end
    if type(getgenv) == "function" then
        local ok, env = pcall(getgenv)
        if ok and type(env) == "table" and type(env.queue_on_teleport) == "function" then
            return env.queue_on_teleport
        end
    end
    return nil
end

local function copyToClipboard(text)
    local fn
    if type(setclipboard) == "function" then
        fn = setclipboard
    elseif type(toclipboard) == "function" then
        fn = toclipboard
    elseif type(syn) == "table" and type(syn.setclipboard) == "function" then
        fn = syn.setclipboard
    elseif type(fluxus) == "table" and type(fluxus.setclipboard) == "function" then
        fn = fluxus.setclipboard
    elseif type(getgenv) == "function" then
        local ok, env = pcall(getgenv)
        if ok and type(env) == "table" then
            if type(env.setclipboard) == "function" then
                fn = env.setclipboard
            elseif type(env.toclipboard) == "function" then
                fn = env.toclipboard
            end
        end
    end
    if not fn then return false end
    return pcall(fn, text)
end

local getServers = ReplicatedStorage:WaitForChild("Chest")
    :WaitForChild("Remotes")
    :WaitForChild("Functions")
    :WaitForChild("GetServers")

local servers = {}
local serverCodes = {}
local serverGeneration = 0
local currentServerName
local currentServerCode
local currentServerCodeField
local currentServerRaw
local setStatus

local function readNumber(server, keys)
    for _, key in ipairs(keys) do
        local value = server[key]
        if type(value) == "number" then return value end
        if type(value) == "string" then
            local number = tonumber(value)
            if number then return number end
            local current = value:match("^(%d+)%s*/")
            if current then return tonumber(current) end
        end
    end
end

local nameFields = {"Name", "ServerName", "DisplayName", "Code", "ServerCode", "ShortCode", "Title"}

local function readServerName(server)
    for _, field in ipairs(nameFields) do
        local value = server[field]
        if type(value) == "string" then
            local text = value:gsub("^%s+", ""):gsub("%s+$", "")
            if text ~= "" and text ~= "Server Name" and not text:find("(Your Server)", 1, true) then
                return text, field
            end
        end
    end

    for field, value in pairs(server) do
        if type(value) == "string" and value:find("#%s*%d+") then
            local text = value:gsub("^%s+", ""):gsub("%s+$", "")
            if text ~= "" then return text, tostring(field) end
        end
    end
    return nil
end

local function applyServers(result)
    serverGeneration = serverGeneration + 1
    local parsed = {}
    local codes = {}
    local foundCurrentName
    local foundCurrentCode
    local foundCurrentField
    local foundCurrentRaw
    local currentKey = normalizeId(game.JobId)

    for key, server in pairs(result) do
        if type(server) == "table" and server.CreatedAt then
            local rawId = server.JobId
            if type(rawId) ~= "string" or rawId == "" then
                rawId = server.JobID or server.jobId or server.ServerId or server.ServerID
                    or server.Id or server.id or key
            end
            local id = tostring(rawId or "")
            local count = readNumber(server, {"PlayerCount", "Playing", "Players", "CurrentPlayers", "playerCount", "playing"})
            if not count and type(server.Players) == "table" then count = #server.Players end
            local maxPlayers = readNumber(server, {"MaxPlayers", "Capacity", "Max", "maxPlayers", "capacity"}) or defaultMaxPlayers
            if id ~= "" and count and count <= maxPlayers then
                local name, nameField = readServerName(server)
                local normalized = normalizeId(id)
                if name and normalized then codes[normalized] = name end
                if normalized and normalized == currentKey and name then
                    foundCurrentName = name
                    foundCurrentCode = name:match("#%s*(%d+)") or name
                    foundCurrentField = nameField
                    foundCurrentRaw = server
                end
                parsed[#parsed + 1] = {
                    id = id,
                    name = name,
                    placeId = tonumber(server.PlaceId) or game.PlaceId,
                    players = count,
                    maxPlayers = maxPlayers,
                }
            end
        end
    end

    servers = parsed
    serverCodes = codes

    if foundCurrentName then
        currentServerName = foundCurrentName
        currentServerCode = foundCurrentCode
        currentServerCodeField = foundCurrentField
        currentServerRaw = foundCurrentRaw
    end

    if setStatus then
        local fresh = 0
        for _, entry in ipairs(parsed) do
            local key = normalizeId(entry.id)
            if key and key ~= currentKey and not visited[key] then
                fresh = fresh + 1
            end
        end
        setStatus(string.format("серверов: %d · новых: %d", #parsed, fresh), MUTED)
    end
end

local oldInvoke
oldInvoke = hookfunction(getServers.InvokeServer, function(self, ...)
    local result = oldInvoke(self, ...)
    if type(result) == "table" then
        applyServers(result)
    end
    return result
end)

local playerGui = player:WaitForChild("PlayerGui")
local oldGui = playerGui:FindFirstChild("AssistPrivateGUI") or playerGui:FindFirstChild("SerpentTrackerGUI")
if oldGui then oldGui:Destroy() end

local screen = Instance.new("ScreenGui")
screen.Name = "AssistPrivateGUI"
screen.ResetOnSpawn = false
screen.DisplayOrder = 999
screen.Parent = playerGui

local WIDTH = 262
local BASE_HEIGHT = 108
local OPEN_HEIGHT = 238

local function corner(object, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = object
    return c
end

local function hover(button, normal, hovered)
    button.AutoButtonColor = false
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.12), {BackgroundColor3 = hovered}):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.12), {BackgroundColor3 = normal}):Play()
    end)
end

local frame = Instance.new("Frame")
frame.AnchorPoint = Vector2.new(0.5, 0)
frame.Position = UDim2.new(0.5, 0, 0.5, -54)
frame.Size = UDim2.fromOffset(WIDTH, BASE_HEIGHT)
frame.BackgroundColor3 = BG_BOTTOM
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.ClipsDescendants = true
frame.Parent = screen

local frameGradient = Instance.new("UIGradient")
frameGradient.Rotation = 90
frameGradient.Color = ColorSequence.new(BG_TOP, BG_BOTTOM)
frameGradient.Parent = frame

corner(frame, 8)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(68, 52, 80)
stroke.Thickness = 1
stroke.Transparency = 0.15
stroke.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.fromOffset(116, 24)
title.Position = UDim2.fromOffset(12, 6)
title.BackgroundTransparency = 1
title.RichText = true
title.Text = 'assist <font color="#FF8B3F">private</font>'
title.TextColor3 = TEXT
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 2
title.Parent = frame

local settingsButton = Instance.new("TextButton")
settingsButton.Size = UDim2.fromOffset(82, 24)
settingsButton.Position = UDim2.fromOffset(168, 6)
settingsButton.BackgroundColor3 = PANEL
settingsButton.BorderSizePixel = 0
settingsButton.Text = "настройки"
settingsButton.TextColor3 = TEXT
settingsButton.Font = Enum.Font.GothamMedium
settingsButton.TextSize = 11
settingsButton.ZIndex = 2
settingsButton.Parent = frame
corner(settingsButton, 5)
hover(settingsButton, PANEL, PANEL_HOVER)

local copyButton = Instance.new("TextButton")
copyButton.Size = UDim2.fromOffset(30, 24)
copyButton.Position = UDim2.fromOffset(132, 6)
copyButton.BackgroundColor3 = PANEL
copyButton.BorderSizePixel = 0
copyButton.Text = "код"
copyButton.TextColor3 = TEXT
copyButton.Font = Enum.Font.GothamMedium
copyButton.TextSize = 9
copyButton.ZIndex = 2
copyButton.Parent = frame
corner(copyButton, 5)
hover(copyButton, PANEL, PANEL_HOVER)

local function makeButton(text, position, size, color, hoverColor, textColor)
    local button = Instance.new("TextButton")
    button.Size = size
    button.Position = position
    button.BackgroundColor3 = color
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = textColor or TEXT
    button.Font = Enum.Font.GothamBold
    button.TextSize = 13
    button.ZIndex = 2
    button.Parent = frame
    corner(button, 6)
    hover(button, color, hoverColor)
    return button
end

local refreshButton = makeButton("обновить", UDim2.fromOffset(10, 40), UDim2.fromOffset(114, 34), PANEL, PANEL_HOVER)
local findButton = makeButton("найти сервер", UDim2.fromOffset(136, 40), UDim2.fromOffset(116, 34), ACCENT, ACCENT_HOVER, Color3.fromRGB(36, 27, 44))

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.fromOffset(238, 16)
statusLabel.Position = UDim2.fromOffset(12, 82)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "готов"
statusLabel.TextColor3 = MUTED
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.TextSize = 11
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextTruncate = Enum.TextTruncate.AtEnd
statusLabel.ZIndex = 2
statusLabel.Parent = frame

setStatus = function(message, color)
    statusLabel.Text = message
    statusLabel.TextColor3 = color or MUTED
end

local function findServerBrowser()
    local mainGui = playerGui:FindFirstChild("MainGui")
    local starter = mainGui and mainGui:FindFirstChild("StarterFrame")
    local browser = starter and starter:FindFirstChild("ServerBrowserFrame")
    if browser then return browser end

    for _, child in ipairs(playerGui:GetDescendants()) do
        if child.Name == "ServerBrowserFrame" then return child end
    end
    return nil
end

local function readCurrentServerFromUi()
    local browser = findServerBrowser()
    local main = browser and browser:FindFirstChild("MainFrame")
    if not main then return nil end

    for _, label in ipairs(main:GetDescendants()) do
        if label:IsA("TextLabel") and label.Name == "NameLabel" then
            local text = label.Text or ""
            if text:find("(Your Server)", 1, true) then
                local row = label.Parent
                local fullName = row and row.Name or ""
                if fullName:find("#%s*%d+") then
                    return fullName
                end

                local name = text:gsub("<[^>]*>", "")
                name = name:gsub("%s*%(Your Server%)%s*$", "")
                name = name:gsub("^%s+", ""):gsub("%s+$", "")

                local idLabel = row and row:FindFirstChild("IdLabel")
                local code = idLabel and tostring(idLabel.Text) or ""
                code = code:gsub("^%s+", ""):gsub("%s+$", "")

                if name ~= "" and name ~= "Server Name"
                    and code ~= "" and code ~= "#0000" then
                    return name .. " " .. code
                end
            end
        end
    end
    return nil
end

if not currentServerName then
    currentServerName = readCurrentServerFromUi()
end

local copyingCode = false
copyButton.MouseButton1Click:Connect(function()
    if copyingCode then return end
    copyingCode = true

    local code = currentServerName
    if not code then
        setStatus("получаю код сервера...", MUTED)
        pcall(function()
            getServers:InvokeServer()
        end)
        code = currentServerName
    end

    if not code then
        code = readCurrentServerFromUi()
        if code then currentServerName = code end
    end

    if not code then
        copyingCode = false
        setStatus("код сервера не найден — открой список серверов", DANGER)
        return
    end

    if copyToClipboard(code) then
        setStatus("код: " .. code, SUCCESS)
    else
        setStatus("буфер обмена недоступен", DANGER)
    end
    copyingCode = false
end)

local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(250, 122)
panel.Position = UDim2.fromOffset(6, 109)
panel.BackgroundColor3 = PANEL
panel.BorderSizePixel = 0
panel.ZIndex = 2
panel.Parent = frame
corner(panel, 6)

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(60, 46, 71)
panelStroke.Thickness = 1
panelStroke.Transparency = 0.35
panelStroke.Parent = panel

local autoLabel = Instance.new("TextLabel")
autoLabel.Size = UDim2.fromOffset(170, 16)
autoLabel.Position = UDim2.fromOffset(10, 5)
autoLabel.BackgroundTransparency = 1
autoLabel.Text = "авто execute"
autoLabel.TextColor3 = TEXT
autoLabel.Font = Enum.Font.GothamMedium
autoLabel.TextSize = 12
autoLabel.TextXAlignment = Enum.TextXAlignment.Left
autoLabel.ZIndex = 3
autoLabel.Parent = panel

local autoHint = Instance.new("TextLabel")
autoHint.Size = UDim2.fromOffset(180, 12)
autoHint.Position = UDim2.fromOffset(10, 20)
autoHint.BackgroundTransparency = 1
autoHint.Text = "запуск скрипта после телепорта"
autoHint.TextColor3 = MUTED
autoHint.Font = Enum.Font.GothamMedium
autoHint.TextSize = 9
autoHint.TextXAlignment = Enum.TextXAlignment.Left
autoHint.ZIndex = 3
autoHint.Parent = panel

local switch = Instance.new("TextButton")
switch.Size = UDim2.fromOffset(46, 22)
switch.Position = UDim2.fromOffset(194, 4)
switch.BackgroundColor3 = Color3.fromRGB(64, 53, 73)
switch.BorderSizePixel = 0
switch.AutoButtonColor = false
switch.Text = ""
switch.ZIndex = 3
switch.Parent = panel
corner(switch, 11)

local knob = Instance.new("Frame")
knob.Size = UDim2.fromOffset(16, 16)
knob.Position = UDim2.fromOffset(3, 3)
knob.BackgroundColor3 = Color3.fromRGB(190, 178, 198)
knob.BorderSizePixel = 0
knob.ZIndex = 4
knob.Parent = switch
corner(knob, 8)

local loaderLabel = Instance.new("TextLabel")
loaderLabel.Size = UDim2.fromOffset(230, 14)
loaderLabel.Position = UDim2.fromOffset(10, 35)
loaderLabel.BackgroundTransparency = 1
loaderLabel.Text = "скрипт (URL или путь к файлу)"
loaderLabel.TextColor3 = MUTED
loaderLabel.Font = Enum.Font.GothamMedium
loaderLabel.TextSize = 10
loaderLabel.TextXAlignment = Enum.TextXAlignment.Left
loaderLabel.ZIndex = 3
loaderLabel.Parent = panel

local loaderBox = Instance.new("TextBox")
loaderBox.Size = UDim2.fromOffset(230, 24)
loaderBox.Position = UDim2.fromOffset(10, 51)
loaderBox.BackgroundColor3 = FIELD
loaderBox.BorderSizePixel = 0
loaderBox.ClearTextOnFocus = false
loaderBox.Text = settings.loader
loaderBox.PlaceholderText = "assist_astra.lua или https://..."
loaderBox.PlaceholderColor3 = Color3.fromRGB(118, 105, 130)
loaderBox.TextColor3 = TEXT
loaderBox.Font = Enum.Font.GothamMedium
loaderBox.TextSize = 11
loaderBox.TextXAlignment = Enum.TextXAlignment.Left
loaderBox.ZIndex = 3
loaderBox.Parent = panel
corner(loaderBox, 5)

local boxPadding = Instance.new("UIPadding")
boxPadding.PaddingLeft = UDim.new(0, 8)
boxPadding.PaddingRight = UDim.new(0, 8)
boxPadding.Parent = loaderBox

local boxStroke = Instance.new("UIStroke")
boxStroke.Color = Color3.fromRGB(60, 46, 71)
boxStroke.Thickness = 1
boxStroke.Transparency = 0.2
boxStroke.Parent = loaderBox

local resetButton = Instance.new("TextButton")
resetButton.Size = UDim2.fromOffset(148, 28)
resetButton.Position = UDim2.fromOffset(10, 82)
resetButton.BackgroundColor3 = Color3.fromRGB(92, 45, 48)
resetButton.BorderSizePixel = 0
resetButton.Text = "сбросить посещённые"
resetButton.TextColor3 = Color3.fromRGB(255, 221, 215)
resetButton.Font = Enum.Font.GothamMedium
resetButton.TextSize = 11
resetButton.ZIndex = 3
resetButton.Parent = panel
corner(resetButton, 5)
hover(resetButton, Color3.fromRGB(92, 45, 48), Color3.fromRGB(112, 55, 58))

local copyScriptButton = Instance.new("TextButton")
copyScriptButton.Size = UDim2.fromOffset(74, 28)
copyScriptButton.Position = UDim2.fromOffset(166, 82)
copyScriptButton.BackgroundColor3 = Color3.fromRGB(52, 42, 62)
copyScriptButton.BorderSizePixel = 0
copyScriptButton.Text = "код скрипта"
copyScriptButton.TextColor3 = TEXT
copyScriptButton.Font = Enum.Font.GothamMedium
copyScriptButton.TextSize = 9
copyScriptButton.ZIndex = 3
copyScriptButton.Parent = panel
corner(copyScriptButton, 5)
hover(copyScriptButton, Color3.fromRGB(52, 42, 62), Color3.fromRGB(64, 52, 76))

local function renderToggle(animated)
    local on = settings.autoExecute
    local info = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local trackColor = on and ACCENT or Color3.fromRGB(64, 53, 73)
    local knobColor = on and Color3.fromRGB(255, 246, 234) or Color3.fromRGB(190, 178, 198)
    if animated then
        TweenService:Create(switch, info, {BackgroundColor3 = trackColor}):Play()
        TweenService:Create(knob, info, {
            Position = UDim2.fromOffset(on and 27 or 3, 3),
            BackgroundColor3 = knobColor,
        }):Play()
    else
        switch.BackgroundColor3 = trackColor
        knob.Position = UDim2.fromOffset(on and 27 or 3, 3)
        knob.BackgroundColor3 = knobColor
    end
end

local function setAutoExecute(value, silent)
    if value and not getQueueFunction() then
        settings.autoExecute = false
        writeJson(settingsFile, settings)
        renderToggle(true)
        if not silent then
            setStatus("executor не поддерживает queue_on_teleport", DANGER)
        end
        return
    end

    settings.autoExecute = value
    writeJson(settingsFile, settings)
    renderToggle(true)

    if not silent then
        if not value then
            setStatus("авто execute выключен", MUTED)
        elseif settings.loader == "" then
            setStatus("авто execute включён — укажи скрипт", ACCENT)
        else
            setStatus("авто execute включён", SUCCESS)
        end
    end
end

if settings.autoExecute and not getQueueFunction() then
    settings.autoExecute = false
    writeJson(settingsFile, settings)
end
renderToggle(false)

if settings.autoExecute then
    local suffix = " · посещённых: " .. visitedCount()
    if settings.loader == "" then
        setStatus("авто execute включён — укажи скрипт" .. suffix, ACCENT)
    else
        setStatus("авто execute включён" .. suffix, SUCCESS)
    end
else
    setStatus("готов · посещённых: " .. visitedCount(), MUTED)
end

local function commitLoader()
    local text = loaderBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
    settings.loader = text
    writeJson(settingsFile, settings)

    if text == "" then
        setStatus("скрипт не указан", DANGER)
        return
    end
    if not text:match("^https?://") and type(isfile) == "function" then
        local ok, exists = pcall(isfile, text)
        if ok and not exists then
            setStatus("файл не найден: " .. text, DANGER)
            return
        end
    end
    setStatus("скрипт сохранён", SUCCESS)
end

local settingsOpen = false
local function setSettingsOpen(open)
    settingsOpen = open
    settingsButton.Text = open and "свернуть" or "настройки"
    settingsButton.TextColor3 = open and ACCENT or TEXT
    TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(WIDTH, open and OPEN_HEIGHT or BASE_HEIGHT),
    }):Play()
end

settingsButton.MouseButton1Click:Connect(function()
    setSettingsOpen(not settingsOpen)
end)

switch.MouseButton1Click:Connect(function()
    setAutoExecute(not settings.autoExecute)
end)

loaderBox.FocusLost:Connect(commitLoader)

resetButton.MouseButton1Click:Connect(function()
    table.clear(visited)
    if type(delfile) == "function" then pcall(delfile, visitedFile) end
    saveVisited()
    setStatus("посещённые серверы сброшены · посещённых: " .. visitedCount(), SUCCESS)
end)

copyScriptButton.MouseButton1Click:Connect(function()
    local target = settings.loader
    if type(target) ~= "string" or target == "" then
        setStatus("сначала укажи скрипт в поле выше", DANGER)
        return
    end

    setStatus("читаю код скрипта...", MUTED)

    local ok, code
    if target:match("^https?://") then
        ok, code = pcall(function()
            return game:HttpGet(target)
        end)
    elseif type(readfile) == "function" then
        ok, code = pcall(readfile, target)
    else
        setStatus("readfile недоступен", DANGER)
        return
    end

    if not ok or type(code) ~= "string" or code == "" then
        setStatus("не удалось прочитать: " .. target, DANGER)
        return
    end

    if copyToClipboard(code) then
        setStatus("код скрипта скопирован (" .. #code .. " байт)", SUCCESS)
    else
        setStatus("буфер обмена недоступен", DANGER)
    end
end)

local function findNativeRefreshButton()
    local browser = findServerBrowser()
    if not browser then return nil end

    local best
    local bestScore = -1

    local main = browser:FindFirstChild("MainFrame")
    local direct = main and main:FindFirstChild("RefreshButton")
    if direct and direct:IsA("GuiButton") then
        best = direct
        bestScore = direct.Visible and 13 or 3
    end

    for _, object in ipairs(browser:GetDescendants()) do
        if object:IsA("GuiButton") then
            local lower = object.Name:lower()
            local text = object:IsA("TextButton") and object.Text:lower() or ""
            if lower:find("refresh", 1, true)
                or text:find("refresh", 1, true)
                or text:find("обнов", 1, true) then
                local blocked = false
                local parent = object.Parent
                while parent and parent ~= browser do
                    if parent.Name:lower():find("friend", 1, true) then
                        blocked = true
                        break
                    end
                    parent = parent.Parent
                end
                if not blocked and not lower:find("friend", 1, true) then
                    local score = 1
                    if object.Name == "RefreshButton" then
                        score = 3
                    elseif lower == "refresh" then
                        score = 2
                    end
                    if object.Visible then
                        score = score + 10
                    end
                    if score > bestScore then
                        best = object
                        bestScore = score
                    end
                end
            end
        end
    end
    return best
end

local fetchingServers = false

local function fetchServers()
    if fetchingServers then return false end
    fetchingServers = true

    local success = false
    local before = serverGeneration
    local nativeOk, nativeButton = pcall(findNativeRefreshButton)

    if nativeOk and nativeButton and type(firesignal) == "function" then
        if pcall(firesignal, nativeButton.MouseButton1Click) then
            for _ = 1, 15 do
                task.wait(0.2)
                if serverGeneration > before then
                    success = true
                    break
                end
            end
        end
    end

    if not success then
        local directBefore = serverGeneration
        local ok = pcall(function()
            getServers:InvokeServer()
        end)
        success = ok and serverGeneration > directBefore
    end

    fetchingServers = false
    return success
end

refreshButton.MouseButton1Click:Connect(function()
    if fetchingServers then return end
    setStatus("обновляю список...", MUTED)
    refreshButton.Text = "обновляю..."
    local ok = fetchServers()
    refreshButton.Text = "обновить"
    if ok then
        setStatus(string.format("обновлено · серверов: %d", #servers), SUCCESS)
    else
        setStatus("не удалось обновить список", DANGER)
    end
end)

local function chooseServer()
    local best
    local current = normalizeId(game.JobId)
    local candidates = 0
    local skippedVisited = 0

    for _, server in ipairs(servers) do
        local key = normalizeId(server.id)
        if key and key ~= current
            and server.players < server.maxPlayers then
            candidates = candidates + 1
            if visited[key] then
                skippedVisited = skippedVisited + 1
            elseif not best or server.players < best.players then
                best = server
            end
        end
    end

    return best, candidates, skippedVisited
end

local function serializeVisited()
    local parts = {}
    for id in pairs(visited) do
        parts[#parts + 1] = "[" .. quote(id) .. "]=true"
    end
    return "{" .. table.concat(parts, ",") .. "}"
end

local function buildLoaderCode()
    local target = settings.loader
    if type(target) ~= "string" or target == "" then
        return nil, "не указан скрипт для авто-запуска"
    end

    if target:match("^https?://") then
        return "loadstring(game:HttpGet(" .. quote(target) .. "))()"
    end

    if type(readfile) ~= "function" then
        return nil, "readfile недоступен"
    end
    if type(isfile) == "function" then
        local ok, exists = pcall(isfile, target)
        if ok and not exists then
            return nil, "файл не найден: " .. target
        end
    end
    return "loadstring(readfile(" .. quote(target) .. "))()"
end

local function buildBootstrap(includeScript)
    local lines = {
        "local __assistVisited = " .. serializeVisited(),
        "_G.AssistVisitedServers = __assistVisited",
        "if type(getgenv) == \"function\" then",
        "    local envOk, env = pcall(getgenv)",
        "    if envOk and type(env) == \"table\" then env.AssistVisitedServers = __assistVisited end",
        "end",
    }

    if includeScript then
        local loaderCode, err = buildLoaderCode()
        if not loaderCode then return nil, err end
        lines[#lines + 1] = "local Players = game:GetService(\"Players\")"
        lines[#lines + 1] = "repeat task.wait(0.2) until game:IsLoaded() and Players.LocalPlayer"
        lines[#lines + 1] = "task.wait(0.5)"
        lines[#lines + 1] = "local ok, err = pcall(function()"
        lines[#lines + 1] = "    " .. loaderCode
        lines[#lines + 1] = "end)"
        lines[#lines + 1] = "if not ok then warn(\"[assist auto] \" .. tostring(err)) end"
    end

    return table.concat(lines, "\n")
end

local finding = false
local pendingTargetKey

local function clearPending()
    if pendingTargetKey then
        unmarkVisited(pendingTargetKey)
        saveVisited()
        pendingTargetKey = nil
    end
end

findButton.MouseButton1Click:Connect(function()
    if finding or fetchingServers then return end

    if #servers == 0 then
        setStatus("получаю список серверов...", MUTED)
        if not fetchServers() then
            setStatus("не удалось получить список — попробуй ещё раз", DANGER)
            return
        end
    end

    local target, candidates, skippedVisited = chooseServer()
    if not target then
        if candidates > 0 and skippedVisited == candidates then
            setStatus("все подходящие серверы уже посещены", MUTED)
        else
            setStatus("нет подходящих серверов", DANGER)
        end
        return
    end

    pendingTargetKey = normalizeId(target.id)
    if pendingTargetKey then
        visited[pendingTargetKey] = true
        saveVisited()
    end

    local queueFn = getQueueFunction()
    if settings.autoExecute and not queueFn then
        clearPending()
        setStatus("executor не поддерживает авто-запуск", DANGER)
        return
    end

    if queueFn then
        local bootstrap, err = buildBootstrap(settings.autoExecute)
        if not bootstrap then
            clearPending()
            setStatus(err, DANGER)
            return
        end

        local ok, queueErr = pcall(queueFn, bootstrap)
        if not ok and settings.autoExecute then
            clearPending()
            setStatus("ошибка очереди: " .. tostring(queueErr), DANGER)
            return
        end
    end

    finding = true
    findButton.Text = "телепорт..."
    local targetLabel = target.name and target.name:match("#%s*%d+") or target.id:sub(1, 8)
    setStatus(string.format("телепорт: %d/%d · %s", target.players, target.maxPlayers, targetLabel), ACCENT)

    local ok = pcall(function()
        TeleportService:TeleportToPlaceInstance(target.placeId, target.id, player)
    end)

    if not ok then
        clearPending()
        finding = false
        findButton.Text = "найти сервер"
        setStatus("не удалось начать телепорт", DANGER)
        return
    end

    task.delay(5, function()
        finding = false
        findButton.Text = "найти сервер"
    end)
end)

TeleportService.TeleportInitFailed:Connect(function(_, _, message)
    if not finding then return end
    clearPending()
    finding = false
    findButton.Text = "найти сервер"
    setStatus("телепорт не удался: " .. tostring(message), DANGER)
end)
