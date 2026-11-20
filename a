local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
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
    loader = "",
}

local saved = readJson(settingsFile)
if saved then
    if type(saved.autoExecute) == "boolean" then settings.autoExecute = saved.autoExecute end
    if type(saved.loader) == "string" and saved.loader ~= "" and saved.loader ~= "assist_astra.lua" then
        settings.loader = saved.loader
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
local failedServers = {}

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
            markVisited(id)
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

local function getHttpRequestFunction()
    if type(request) == "function" then return request end
    if type(http_request) == "function" then return http_request end
    if type(http) == "table" and type(http.request) == "function" then return http.request end
    if type(syn) == "table" and type(syn.request) == "function" then return syn.request end
    if type(fluxus) == "table" and type(fluxus.request) == "function" then return fluxus.request end
    if type(getgenv) == "function" then
        local ok, env = pcall(getgenv)
        if ok and type(env) == "table" then
            if type(env.request) == "function" then return env.request end
            if type(env.http_request) == "function" then return env.http_request end
        end
    end
    return nil
end

local function httpGetUrl(url)
    local reqFn = getHttpRequestFunction()
    if reqFn then
        local ok, res = pcall(reqFn, {
            Url = url,
            Method = "GET",
        })
        if ok and type(res) == "table" then
            local status = tonumber(res.StatusCode or res.Status) or 200
            if status >= 200 and status < 300 and type(res.Body) == "string" and res.Body ~= "" then
                return res.Body
            end
        end
    end

    local ok, body = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and type(body) == "string" and body ~= "" then
        return body
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
local publicServers = {}
local remoteServersCache = {}
local serverCodes = {}
local serverGeneration = 0
local currentServerName
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
local regionFields = {
    "Region", "region", "Country", "country", "CountryName", "countryName",
    "CountryCode", "countryCode", "Location", "location",
    "ServerRegion", "serverRegion", "Area", "area", "Zone", "zone", "Geo", "geo",
}

local usExact = {
    us = true, usa = true, ["united states"] = true, ["united states of america"] = true,
    ["u.s."] = true, ["u.s.a."] = true,
}

local usKeywords = {
    "united states", "ashburn", "virginia", "oregon", "boardman",
    "california", "san jose", "los angeles", "santa clara",
    "texas", "dallas", "florida", "miami", "new york", "newark",
    "new jersey", "secaucus", "illinois", "chicago", "georgia",
    "atlanta", "washington", "seattle", "ohio", "arizona", "utah",
}

local function isUnitedStatesRegion(region)
    if type(region) ~= "string" or region == "" then return false end
    local low = region:lower():gsub("^%s+", ""):gsub("%s+$", "")
    if usExact[low] then return true end
    if low:match("^us[%s%-_,]") or low:match("[%s%-_,]us$") or low:match("^usa[%s%-_,]") then
        return true
    end
    for _, kw in ipairs(usKeywords) do
        if low:find(kw, 1, true) then
            return true
        end
    end
    return false
end

local knownCountryHints = {
    "united states", "germany", "singapore", "japan", "brazil", "united kingdom",
    "france", "netherlands", "australia", "canada", "korea", "india", "poland",
    "russia", "finland", "sweden", "ireland", "spain", "italy", "hong kong",
    "taiwan", "indonesia", "philippines", "thailand", "vietnam", "malaysia",
}

local function readServerRegion(server)
    for _, field in ipairs(regionFields) do
        local value = server[field]
        if type(value) == "string" then
            local text = value:gsub("^%s+", ""):gsub("%s+$", "")
            if text ~= "" then
                return text
            end
        end
    end

    for field, value in pairs(server) do
        if type(value) == "string" then
            local low = value:lower():gsub("^%s+", ""):gsub("%s+$", "")
            if low ~= "" and not tostring(field):lower():find("job", 1, true) then
                if isUnitedStatesRegion(low) then
                    return value:gsub("^%s+", ""):gsub("%s+$", "")
                end
                for _, hint in ipairs(knownCountryHints) do
                    if low:find(hint, 1, true) then
                        return value:gsub("^%s+", ""):gsub("%s+$", "")
                    end
                end
            end
        end
    end

    return nil
end

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

local function isRestrictedServer(server)
    if server.Private == true
        or server.IsPrivate == true
        or server.Reserved == true
        or server.Locked == true
        or server.IsReserved == true then
        return true
    end
    if type(server.AccessCode) == "string" and server.AccessCode ~= "" then
        return true
    end
    if type(server.ServerType) == "string" and server.ServerType:lower():find("private", 1, true) then
        return true
    end
    return false
end

local serverRegionsByCode = {}
local hasKnownRegionData = false

local function rebuildServerList(remoteList)
    local byKey = {}
    local merged = {}
    local currentKey = normalizeId(game.JobId)
    hasKnownRegionData = false

    local function upsert(entry)
        local key = normalizeId(entry.id)
        if not key then return end

        local existing = byKey[key]
        if existing then
            if entry.name and not existing.name then existing.name = entry.name end
            if entry.region and not existing.region then
                existing.region = entry.region
                existing.isUS = entry.isUS
            end
            if entry.isUS then existing.isUS = true end
            if entry.restricted then existing.restricted = true end
            if entry.players and (not existing.players or entry.source == "roblox") then
                existing.players = entry.players
            end
            if entry.maxPlayers then existing.maxPlayers = entry.maxPlayers end
            if entry.placeId then existing.placeId = entry.placeId end
        else
            byKey[key] = entry
            merged[#merged + 1] = entry
        end
    end

    for _, entry in ipairs(remoteList) do
        upsert(entry)
    end
    for _, entry in ipairs(publicServers) do
        upsert(entry)
    end

    for _, entry in ipairs(merged) do
        if not entry.region and entry.name then
            local code = entry.name:match("#%s*(%d+)")
            local uiRegion = code and serverRegionsByCode[code]
            if uiRegion then
                entry.region = uiRegion
                entry.isUS = isUnitedStatesRegion(uiRegion)
            end
        end
        if entry.region then
            hasKnownRegionData = true
        end
    end

    table.sort(merged, function(a, b)
        return (a.players or 999) < (b.players or 999)
    end)

    servers = merged

    if setStatus then
        local fresh = 0
        for _, entry in ipairs(merged) do
            local key = normalizeId(entry.id)
            if key and key ~= currentKey and not entry.restricted and not entry.isUS
                and (not hasKnownRegionData or entry.region ~= nil)
                and not visited[key] and not failedServers[key] then
                fresh = fresh + 1
            end
        end
        setStatus(string.format("серверов: %d · новых: %d", #merged, fresh), MUTED)
    end
end

local function applyServers(result)
    serverGeneration = serverGeneration + 1
    local parsed = {}
    local codes = {}
    local foundCurrentName
    local currentKey = normalizeId(game.JobId)

    for key, server in pairs(result) do
        if type(server) == "table" then
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
                local name = readServerName(server)
                local region = readServerRegion(server)
                local normalized = normalizeId(id)
                if name and normalized then codes[normalized] = name end
                if normalized and normalized == currentKey and name then
                    foundCurrentName = name
                end
                parsed[#parsed + 1] = {
                    id = id,
                    name = name,
                    region = region,
                    isUS = isUnitedStatesRegion(region),
                    placeId = tonumber(server.PlaceId) or game.PlaceId,
                    players = count,
                    maxPlayers = maxPlayers,
                    restricted = isRestrictedServer(server),
                    source = "remote",
                }
            end
        end
    end

    remoteServersCache = parsed
    serverCodes = codes

    if foundCurrentName then
        currentServerName = foundCurrentName
    end

    rebuildServerList(remoteServersCache)
end

local function fetchRobloxPublicServers(maxPages)
    local hosts = {
        "https://games.roblox.com",
        "https://games.roproxy.com",
    }
    local collected = {}
    local currentKey = normalizeId(game.JobId)

    for _, host in ipairs(hosts) do
        local cursor = ""
        local anySuccess = false

        for _ = 1, (maxPages or 3) do
            local url = string.format(
                "%s/v1/games/%s/servers/Public?sortOrder=Asc&limit=100%s",
                host,
                tostring(game.PlaceId),
                cursor ~= "" and ("&cursor=" .. HttpService:UrlEncode(cursor)) or ""
            )

            local body = httpGetUrl(url)
            if not body then break end

            local dok, decoded = pcall(HttpService.JSONDecode, HttpService, body)
            if not dok or type(decoded) ~= "table" or type(decoded.data) ~= "table" then
                break
            end

            anySuccess = true
            local hasUnvisitedOnPage = false

            for _, s in ipairs(decoded.data) do
                if type(s) == "table" and type(s.id) == "string" and s.id ~= "" then
                    local playing = tonumber(s.playing) or 0
                    local maxP = tonumber(s.maxPlayers) or defaultMaxPlayers
                    if playing > 0 and playing < maxP then
                        local key = normalizeId(s.id)
                        if key and key ~= currentKey and not visited[key] and not failedServers[key] then
                            hasUnvisitedOnPage = true
                        end
                        collected[#collected + 1] = {
                            id = s.id,
                            name = key and serverCodes[key] or nil,
                            placeId = game.PlaceId,
                            players = playing,
                            maxPlayers = maxP,
                            restricted = false,
                            source = "roblox",
                        }
                    end
                end
            end

            local nextCursor = decoded.nextPageCursor
            if type(nextCursor) ~= "string" or nextCursor == "" or hasUnvisitedOnPage then
                break
            end
            cursor = nextCursor
        end

        if anySuccess then
            break
        end
    end

    if #collected > 0 then
        publicServers = collected
        rebuildServerList(remoteServersCache)
        return true
    end
    return false
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
local MAIN_OPEN_HEIGHT = 188
local HP_OPEN_HEIGHT = 243

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

local function playersSuffix()
    local count = #Players:GetPlayers()
    local maximum = Players.MaxPlayers
    if type(maximum) ~= "number" or maximum <= 0 then
        maximum = defaultMaxPlayers
    end
    return string.format(" %d/%d", count, maximum)
end

local copyingCode = false

local function copyCurrentCode()
    local code = currentServerName
    if not code then
        code = readCurrentServerFromUi()
        if code then currentServerName = code end
    end

    if not code then
        setStatus("получаю код сервера...", MUTED)
        local before = serverGeneration
        task.spawn(function()
            pcall(function()
                getServers:InvokeServer()
            end)
        end)

        for _ = 1, 12 do
            task.wait(0.15)
            code = currentServerName
            if code then break end
            if serverGeneration > before then
                code = currentServerName or readCurrentServerFromUi()
                if code then
                    currentServerName = code
                    break
                end
            end
        end

        if not code then
            code = readCurrentServerFromUi()
            if code then currentServerName = code end
        end
    end

    if not code then
        setStatus("код сервера не найден — открой список серверов", DANGER)
        return
    end

    local result = code .. playersSuffix()
    if copyToClipboard(result) then
        setStatus("код: " .. result, SUCCESS)
    else
        setStatus("буфер обмена недоступен", DANGER)
    end
end

copyButton.MouseButton1Click:Connect(function()
    if copyingCode then return end
    copyingCode = true
    local ok, err = pcall(copyCurrentCode)
    copyingCode = false
    if not ok then
        setStatus("ошибка копирования: " .. tostring(err), DANGER)
    end
end)

local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(250, 120)
panel.Position = UDim2.fromOffset(6, 40)
panel.BackgroundColor3 = PANEL
panel.BorderSizePixel = 0
panel.Visible = false
panel.ClipsDescendants = true
panel.ZIndex = 2
panel.Parent = frame
corner(panel, 6)

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(60, 46, 71)
panelStroke.Thickness = 1
panelStroke.Transparency = 0.35
panelStroke.Parent = panel

local settingsTab = "main"

local tabMain = Instance.new("TextButton")
tabMain.Size = UDim2.fromOffset(116, 24)
tabMain.Position = UDim2.fromOffset(8, 6)
tabMain.BackgroundColor3 = FIELD
tabMain.BorderSizePixel = 0
tabMain.Text = "настройки"
tabMain.TextColor3 = MUTED
tabMain.Font = Enum.Font.GothamBold
tabMain.TextSize = 10
tabMain.AutoButtonColor = false
tabMain.ZIndex = 5
tabMain.Parent = panel
corner(tabMain, 5)

local tabHp = Instance.new("TextButton")
tabHp.Size = UDim2.fromOffset(116, 24)
tabHp.Position = UDim2.fromOffset(126, 6)
tabHp.BackgroundColor3 = FIELD
tabHp.BorderSizePixel = 0
tabHp.Text = "hp"
tabHp.TextColor3 = MUTED
tabHp.Font = Enum.Font.GothamBold
tabHp.TextSize = 10
tabHp.AutoButtonColor = false
tabHp.ZIndex = 5
tabHp.Parent = panel
corner(tabHp, 5)

local mainPage = Instance.new("Frame")
mainPage.Size = UDim2.new(1, 0, 0, 90)
mainPage.Position = UDim2.fromOffset(0, 30)
mainPage.BackgroundTransparency = 1
mainPage.ZIndex = 3
mainPage.Parent = panel

local hpPage = Instance.new("Frame")
hpPage.Size = UDim2.new(1, 0, 0, 145)
hpPage.Position = UDim2.fromOffset(0, 30)
hpPage.BackgroundTransparency = 1
hpPage.Visible = false
hpPage.ZIndex = 3
hpPage.Parent = panel

local autoLabel = Instance.new("TextLabel")
autoLabel.Size = UDim2.fromOffset(170, 22)
autoLabel.Position = UDim2.fromOffset(10, 6)
autoLabel.BackgroundTransparency = 1
autoLabel.Text = "авто execute"
autoLabel.TextColor3 = TEXT
autoLabel.Font = Enum.Font.GothamMedium
autoLabel.TextSize = 12
autoLabel.TextXAlignment = Enum.TextXAlignment.Left
autoLabel.ZIndex = 3
autoLabel.Parent = mainPage

local switch = Instance.new("TextButton")
switch.Size = UDim2.fromOffset(46, 22)
switch.Position = UDim2.fromOffset(194, 6)
switch.BackgroundColor3 = Color3.fromRGB(64, 53, 73)
switch.BorderSizePixel = 0
switch.AutoButtonColor = false
switch.Text = ""
switch.ZIndex = 3
switch.Parent = mainPage
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
loaderLabel.Position = UDim2.fromOffset(10, 36)
loaderLabel.BackgroundTransparency = 1
loaderLabel.Text = "скрипт (URL или путь к файлу)"
loaderLabel.TextColor3 = MUTED
loaderLabel.Font = Enum.Font.GothamMedium
loaderLabel.TextSize = 10
loaderLabel.TextXAlignment = Enum.TextXAlignment.Left
loaderLabel.ZIndex = 3
loaderLabel.Parent = mainPage

local loaderBox = Instance.new("TextBox")
loaderBox.Size = UDim2.fromOffset(230, 26)
loaderBox.Position = UDim2.fromOffset(10, 53)
loaderBox.BackgroundColor3 = FIELD
loaderBox.BorderSizePixel = 0
loaderBox.ClipsDescendants = true
loaderBox.ClearTextOnFocus = false
loaderBox.Text = settings.loader
loaderBox.PlaceholderText = "https://... или путь к файлу"
loaderBox.PlaceholderColor3 = Color3.fromRGB(118, 105, 130)
loaderBox.TextColor3 = TEXT
loaderBox.Font = Enum.Font.GothamMedium
loaderBox.TextSize = 11
loaderBox.TextXAlignment = Enum.TextXAlignment.Left
loaderBox.ZIndex = 3
loaderBox.Parent = mainPage
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

local function makeStatusRow(nameText, yPos)
    local row = Instance.new("Frame")
    row.Size = UDim2.fromOffset(234, 20)
    row.Position = UDim2.fromOffset(8, yPos)
    row.BackgroundColor3 = FIELD
    row.BorderSizePixel = 0
    row.ZIndex = 4
    row.Parent = hpPage
    corner(row, 5)

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.fromOffset(104, 20)
    nameLbl.Position = UDim2.fromOffset(8, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = nameText
    nameLbl.TextColor3 = TEXT
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 11
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.ZIndex = 5
    nameLbl.Parent = row

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.fromOffset(114, 20)
    valLbl.Position = UDim2.fromOffset(112, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = "—"
    valLbl.TextColor3 = MUTED
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 11
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.TextTruncate = Enum.TextTruncate.AtEnd
    valLbl.ZIndex = 5
    valLbl.Parent = row

    return valLbl
end

local serpentRowVal = makeStatusRow("Serpent", 5)
local depthKingRowVal = makeStatusRow("Depth King", 28)
local tyrantRowVal = makeStatusRow("Abyssal Tyrant", 51)
local drakenfyrRowVal = makeStatusRow("Drakenfyr", 74)
local crabRowVal = makeStatusRow("Deepsea Crusher", 97)
local krakenRowVal = makeStatusRow("Chaos Kraken", 120)

local function formatNumber(value)
    local text = tostring(math.floor(value + 0.5))
    local formatted = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    if formatted:sub(1, 1) == "," then
        formatted = formatted:sub(2)
    end
    return formatted
end

local function formatDuration(seconds)
    local total = math.max(0, math.floor(seconds + 0.5))
    local hours = math.floor(total / 3600)
    local mins = math.floor((total % 3600) / 60)
    local secs = total % 60
    if hours > 0 then
        return string.format("%d:%02d:%02d", hours, mins, secs)
    end
    return string.format("%02d:%02d", mins, secs)
end

local function normalizeKey(str)
    return (tostring(str or ""):lower():gsub("[%s_%-]", ""))
end

local function getServerNow()
    local ok, now = pcall(function()
        return workspace:GetServerTimeNow()
    end)
    if ok and type(now) == "number" and now > 0 then
        return now
    end
    return os.time()
end

local healthAttrNames = {"Health", "HP", "CurrentHealth", "HealthValue"}
local maxHealthAttrNames = {"MaxHealth", "MaxHP", "HealthMax", "MaximumHealth"}

local function findHealthValuesInNode(node, deep)
    if not node then return nil end

    local humanoid = node:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.MaxHealth > 0 then
        return { kind = "humanoid", object = humanoid }
    end

    for _, name in ipairs(healthAttrNames) do
        if type(node:GetAttribute(name)) == "number" then
            local maxAttr
            for _, mName in ipairs(maxHealthAttrNames) do
                if type(node:GetAttribute(mName)) == "number" then
                    maxAttr = mName
                    break
                end
            end
            return { kind = "attr", object = node, attr = name, maxAttr = maxAttr }
        end
    end

    local hpObj, maxObj
    for _, name in ipairs(healthAttrNames) do
        local obj = node:FindFirstChild(name)
        if obj and (obj:IsA("NumberValue") or obj:IsA("IntValue") or obj:IsA("StringValue")) then
            hpObj = obj
            break
        end
    end
    if hpObj then
        for _, mName in ipairs(maxHealthAttrNames) do
            local obj = node:FindFirstChild(mName)
            if obj and (obj:IsA("NumberValue") or obj:IsA("IntValue") or obj:IsA("StringValue")) then
                maxObj = obj
                break
            end
        end
        return { kind = "value", hpObj = hpObj, maxObj = maxObj }
    end

    if deep then
        for _, object in ipairs(node:GetDescendants()) do
            if object:IsA("Humanoid") and object.MaxHealth > 0 then
                return { kind = "humanoid", object = object }
            end
        end
        for _, object in ipairs(node:GetDescendants()) do
            if object:IsA("NumberValue") or object:IsA("IntValue") then
                local low = object.Name:lower()
                for _, name in ipairs(healthAttrNames) do
                    if low == name:lower() then
                        local maxFound
                        if object.Parent then
                            for _, mName in ipairs(maxHealthAttrNames) do
                                local sibling = object.Parent:FindFirstChild(mName)
                                if sibling and (sibling:IsA("NumberValue") or sibling:IsA("IntValue")) then
                                    maxFound = sibling
                                    break
                                end
                            end
                        end
                        return { kind = "value", hpObj = object, maxObj = maxFound }
                    end
                end
            end
        end
    end

    return nil
end

local function readFromHealthSource(source)
    if not source then return nil end
    if source.kind == "humanoid" then
        local h = source.object
        if not h or not h.Parent then return nil end
        return h.Health, h.MaxHealth
    elseif source.kind == "attr" then
        local obj = source.object
        if not obj or not obj.Parent then return nil end
        local hp = obj:GetAttribute(source.attr)
        if type(hp) ~= "number" then return nil end
        local maxHp = source.maxAttr and obj:GetAttribute(source.maxAttr) or nil
        return hp, maxHp
    elseif source.kind == "value" then
        local hpObj = source.hpObj
        if not hpObj or not hpObj.Parent then return nil end
        local hp = hpObj:IsA("StringValue") and tonumber((hpObj.Value:gsub(",", ""))) or hpObj.Value
        local maxHp
        if source.maxObj and source.maxObj.Parent then
            maxHp = source.maxObj:IsA("StringValue") and tonumber((source.maxObj.Value:gsub(",", ""))) or source.maxObj.Value
        end
        return hp, maxHp
    end
    return nil
end

local function nameHasExcluded(normName, exclude)
    if not exclude then return false end
    for _, ex in ipairs(exclude) do
        if normName:find(ex, 1, true) then
            return true
        end
    end
    return false
end

local function matchesAliases(normName, aliases, exclude)
    if normName == "" or nameHasExcluded(normName, exclude) then return false end
    for _, alias in ipairs(aliases) do
        if normName == alias or normName:find(alias, 1, true) then
            return true
        end
    end
    return false
end

local function findBossHealthBarFrame(aliases, exclude)
    local mainGui = playerGui:FindFirstChild("MainGui")
    local starter = mainGui and mainGui:FindFirstChild("StarterFrame")
    local bar = starter and starter:FindFirstChild("BossesHealthBar")
    local frames = bar and bar:FindFirstChild("Frames")
    if not frames then return nil end

    for _, child in ipairs(frames:GetChildren()) do
        if matchesAliases(normalizeKey(child.Name), aliases, exclude) then
            return child
        end
        local hpFrame = child:FindFirstChild("HPFrame")
        local bossNameLbl = hpFrame and hpFrame:FindFirstChild("BossName")
        if bossNameLbl and bossNameLbl:IsA("TextLabel")
            and matchesAliases(normalizeKey(bossNameLbl.Text), aliases, exclude) then
            return child
        end
    end
    return nil
end

local function readHealthFromBossBar(frameNode)
    if not frameNode or not frameNode.Parent then return nil end
    local hpFrame = frameNode:FindFirstChild("HPFrame") or frameNode
    for _, obj in ipairs(hpFrame:GetDescendants()) do
        if obj:IsA("TextLabel") then
            local current, maximum = (obj.Text or ""):match("([%d,]+)%s*/%s*([%d,]+)")
            if current then
                local curNum = tonumber((current:gsub(",", "")))
                local maxNum = tonumber((maximum:gsub(",", "")))
                if curNum and maxNum and maxNum > 100 then
                    return curNum, maxNum
                end
            end
        end
    end
    return nil
end

local function findBossNodes(aliases, locNode, exclude)
    local monster = workspace:FindFirstChild("Monster")
    local boss = monster and monster:FindFirstChild("Boss")
    local containers = {}
    if boss then containers[#containers + 1] = boss end
    if monster then containers[#containers + 1] = monster end
    if locNode then containers[#containers + 1] = locNode end
    containers[#containers + 1] = workspace

    for _, container in ipairs(containers) do
        for _, child in ipairs(container:GetChildren()) do
            if (container ~= workspace or child:IsA("Model") or child:IsA("Folder"))
                and matchesAliases(normalizeKey(child.Name), aliases, exclude) then
                local model = child:FindFirstChild(child.Name .. "Model")
                    or child:FindFirstChild("Model")
                    or child
                return model, child, boss
            end
        end
    end
    return nil
end

local function parseTimerText(rawText, allowShortMinute)
    if type(rawText) ~= "string" then return nil end
    local text = rawText:gsub("<[^>]*>", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then return nil end

    local lower = text:lower()

    -- Игнорируем дистанцию ("250m", "120 m", "300 studs") и HP ("100/200")
    if lower:find("stud", 1, true) or lower:find("km", 1, true) then
        return nil
    end
    if text:match("^%[?%s*%d+[%.,]?%d*%s*[mMмМ]%s*%]?$") and not allowShortMinute then
        return nil
    end

    local hms = text:match("(%d+:%d%d:%d%d)")
    if hms then return hms, false end

    local ms = text:match("(%d+:%d%d)")
    if ms then return ms, false end

    local h = tonumber(text:match("(%d+)%s*[hHчЧ]")) or 0
    local m = tonumber(text:match("(%d+)%s*[mMмМ]")) or 0
    local s = tonumber(text:match("(%d+)%s*[sSсС]")) or 0

    local hasTimerWord = lower:find("spawn", 1, true)
        or lower:find("time", 1, true)
        or lower:find("cd", 1, true)
        or lower:find("wait", 1, true)
        or lower:find("left", 1, true)
        or lower:find("in ", 1, true)
        or lower:find("спавн", 1, true)
        or lower:find("остал", 1, true)
        or lower:find("через", 1, true)

    if (h > 0 and m > 0) or s > 0 or (h > 0 and (allowShortMinute or hasTimerWord)) or (m > 0 and (allowShortMinute or hasTimerWord)) then
        return formatDuration(h * 3600 + m * 60 + s), false
    end

    if lower:find("spawned", 1, true)
        or lower:find("alive", 1, true)
        or lower:find("ready", 1, true)
        or lower:find("заспавн", 1, true) then
        return "заспавнился", true
    end

    return nil
end

local timestampKeys = {
    "nextspawn", "spawnat", "respawnat", "endtime", "targettime", "expiretime",
}
local countdownKeys = {
    "timeleft", "remainingtime", "remaining", "countdown", "timer", "cooldownleft",
    "respawnleft", "waittime", "cd",
}
local startKeys = {"lastspawn", "killedat", "deathtime", "starttime", "despawntime"}
local durationKeys = {"interval", "respawntime", "spawndelay", "cooldown", "spawntime", "duration"}

local function nameMatchesAny(name, list)
    local lower = tostring(name or ""):lower()
    for _, key in ipairs(list) do
        if lower:find(key, 1, true) then
            return true
        end
    end
    return false
end

local function hasTimerHint(name)
    local lower = tostring(name or ""):lower()
    return lower:find("time", 1, true)
        or lower:find("spawn", 1, true)
        or lower:find("cd", 1, true)
        or lower:find("cool", 1, true)
        or lower:find("wait", 1, true)
        or lower:find("respawn", 1, true)
        or lower:find("count", 1, true)
end

local function evalTimestampOrSeconds(val, isTimestamp)
    if type(val) ~= "number" then return nil end
    if val > 1000000000 then
        local rem = val - getServerNow()
        if rem > 0 and rem <= 86400 then
            return formatDuration(rem), false
        end
        return nil
    end
    if not isTimestamp and val > 0 and val <= 86400 then
        return formatDuration(val), false
    end
    return nil
end

local function findTimerSourceInNode(node)
    if not node then return nil end

    if type(node:GetAttribute("Text")) == "string" then
        return { kind = "attrStr", node = node, attr = "Text", hinted = false }
    end

    local function checkNode(target)
        local okAttrs, attrs = pcall(function()
            return target:GetAttributes()
        end)
        if okAttrs and type(attrs) == "table" then
            if type(attrs.Text) == "string" then
                return { kind = "attrStr", node = target, attr = "Text", hinted = false }
            end

            local startAttr, durAttr
            for k, v in pairs(attrs) do
                if type(v) == "number" then
                    if nameMatchesAny(k, startKeys) then startAttr = k end
                    if nameMatchesAny(k, durationKeys) then durAttr = k end
                end
            end
            if startAttr and durAttr then
                return { kind = "attrPair", node = target, startAttr = startAttr, durAttr = durAttr }
            end

            for k, v in pairs(attrs) do
                if type(v) == "number" then
                    if nameMatchesAny(k, timestampKeys) then
                        return { kind = "attrNum", node = target, attr = k, isTimestamp = true }
                    elseif nameMatchesAny(k, countdownKeys) then
                        return { kind = "attrNum", node = target, attr = k, isTimestamp = false }
                    elseif nameMatchesAny(k, {"spawntime", "respawntime", "cooldown"}) and v > 1000000000 then
                        return { kind = "attrNum", node = target, attr = k, isTimestamp = true }
                    end
                elseif type(v) == "string" and hasTimerHint(k) then
                    if parseTimerText(v, true) then
                        return { kind = "attrStr", node = target, attr = k, hinted = true }
                    end
                end
            end
        end

        local startObj, durObj
        for _, child in ipairs(target:GetChildren()) do
            if child:IsA("NumberValue") or child:IsA("IntValue") then
                if nameMatchesAny(child.Name, startKeys) then startObj = child end
                if nameMatchesAny(child.Name, durationKeys) then durObj = child end
            end
        end
        if startObj and durObj then
            return { kind = "valuePair", startObj = startObj, durObj = durObj }
        end

        return nil
    end

    local direct = checkNode(node)
    if direct then return direct end

    for _, desc in ipairs(node:GetDescendants()) do
        local found = checkNode(desc)
        if found then return found end

        if desc:IsA("NumberValue") or desc:IsA("IntValue") then
            if nameMatchesAny(desc.Name, timestampKeys) then
                return { kind = "valueNum", obj = desc, isTimestamp = true }
            elseif nameMatchesAny(desc.Name, countdownKeys) then
                return { kind = "valueNum", obj = desc, isTimestamp = false }
            elseif nameMatchesAny(desc.Name, {"spawntime", "respawntime", "cooldown"}) and desc.Value > 1000000000 then
                return { kind = "valueNum", obj = desc, isTimestamp = true }
            end
        elseif desc:IsA("StringValue") then
            local hinted = hasTimerHint(desc.Name)
            if parseTimerText(desc.Value, hinted) then
                return { kind = "stringObj", obj = desc, hinted = hinted }
            end
        elseif desc:IsA("TextLabel") then
            local hinted = hasTimerHint(desc.Name)
                or (desc.Parent and hasTimerHint(desc.Parent.Name))
            if parseTimerText(desc.Text, hinted) then
                return { kind = "textLabel", obj = desc, hinted = hinted }
            end
        end
    end

    return nil
end

local function readFromTimerSource(src)
    if not src then return nil end

    if src.kind == "attrPair" then
        if not src.node or not src.node.Parent then return nil end
        local s = src.node:GetAttribute(src.startAttr)
        local d = src.node:GetAttribute(src.durAttr)
        if type(s) == "number" and type(d) == "number" and d > 0 then
            local rem = (s + d) - getServerNow()
            if rem > 0 and rem <= 86400 then
                return formatDuration(rem), false
            end
        end
    elseif src.kind == "attrNum" then
        if not src.node or not src.node.Parent then return nil end
        local v = src.node:GetAttribute(src.attr)
        return evalTimestampOrSeconds(v, src.isTimestamp)
    elseif src.kind == "attrStr" then
        if not src.node or not src.node.Parent then return nil end
        local v = src.node:GetAttribute(src.attr)
        return parseTimerText(v, src.hinted)
    elseif src.kind == "valuePair" then
        if not src.startObj or not src.startObj.Parent or not src.durObj or not src.durObj.Parent then return nil end
        local s = src.startObj.Value
        local d = src.durObj.Value
        if type(s) == "number" and type(d) == "number" and d > 0 then
            local rem = (s + d) - getServerNow()
            if rem > 0 and rem <= 86400 then
                return formatDuration(rem), false
            end
        end
    elseif src.kind == "valueNum" then
        if not src.obj or not src.obj.Parent then return nil end
        return evalTimestampOrSeconds(src.obj.Value, src.isTimestamp)
    elseif src.kind == "stringObj" then
        if not src.obj or not src.obj.Parent then return nil end
        return parseTimerText(src.obj.Value, src.hinted)
    elseif src.kind == "textLabel" then
        if not src.obj or not src.obj.Parent then return nil end
        return parseTimerText(src.obj.Text, src.hinted)
    end

    return nil
end

local bossConfigs = {
    { key = "serpent", label = serpentRowVal, aliases = {"serpent"}, exclude = {"serpentforger"}, hasHp = true, parents = {"Areas", "Island"}, locNames = {"SerpentLocation"}, checkWhirlpool = true },
    { key = "depthking", label = depthKingRowVal, aliases = {"depthking"}, hasHp = true, parents = {"Areas", "Island"}, locNames = {"DepthKingLocation"} },
    { key = "tyrant", label = tyrantRowVal, aliases = {"seadragon", "abyssaltyrant"}, hasHp = true, parents = {"Island", "Areas"}, locNames = {"SeaDragonLocation", "AbyssalTyrantLocation"} },
    { key = "drakenfyr", label = drakenfyrRowVal, aliases = {"thirdseadragon", "drakenfyr"}, hasHp = true, parents = {"Island", "Areas"}, locNames = {"ThirdSeaDragonLocation", "DrakenfyrLocation", "DragonLocation"} },
    { key = "crab", label = crabRowVal, aliases = {"thirdseaeldritchcrab", "eldritchcrab", "deepseacrusher"}, exclude = {"chaoscrab", "craberno"}, hasHp = true, parents = {"Island", "Areas"}, locNames = {"CrabLocation"} },
    { key = "kraken", label = krakenRowVal, aliases = {"chaoskraken", "furytentacle"}, exclude = {"galleon"}, hasHp = true, parents = {"Island", "Areas"}, locNames = {"KrakenLocation"} },
}

local function getLocationNode(cfg)
    if cfg.locNode and cfg.locNode.Parent then
        return cfg.locNode
    end
    for _, parentName in ipairs(cfg.parents) do
        local parent = workspace:FindFirstChild(parentName)
        if parent then
            for _, name in ipairs(cfg.locNames) do
                local node = parent:FindFirstChild(name)
                if node then
                    cfg.locNode = node
                    cfg.timerSource = nil
                    return node
                end
            end
        end
    end
    return nil
end

local function updateBossConfig(cfg, now)
    local locNode = getLocationNode(cfg)

    if cfg.hasHp then
        local hp, maxHp = readFromHealthSource(cfg.hpSource)
        if not hp then
            hp, maxHp = readHealthFromBossBar(cfg.barFrame)
        end

        if not hp and (now - (cfg.lastBossScan or 0)) >= 1.5 then
            cfg.lastBossScan = now
            local model, bossNode, bossFolder = findBossNodes(cfg.aliases, locNode, cfg.exclude)
            if model then
                cfg.modelRef = model
                cfg.hpSource = findHealthValuesInNode(model, true)
                    or findHealthValuesInNode(bossNode, false)
                    or findHealthValuesInNode(bossFolder, false)
                hp, maxHp = readFromHealthSource(cfg.hpSource)
            else
                cfg.modelRef = nil
                cfg.hpSource = nil
            end

            if not hp then
                cfg.barFrame = findBossHealthBarFrame(cfg.aliases, cfg.exclude)
                hp, maxHp = readHealthFromBossBar(cfg.barFrame)
            end
        end

        if hp then
            if maxHp and maxHp > 0 then
                cfg.label.Text = formatNumber(hp) .. "/" .. formatNumber(maxHp)
            else
                cfg.label.Text = formatNumber(hp)
            end
            cfg.label.TextColor3 = hp > 0 and SUCCESS or DANGER
            return
        end

        if (cfg.modelRef and cfg.modelRef.Parent) or (cfg.barFrame and cfg.barFrame.Parent) then
            cfg.label.Text = "жив"
            cfg.label.TextColor3 = SUCCESS
            return
        end
    end

    local timerText, isActive = readFromTimerSource(cfg.timerSource)
    if not timerText and locNode and (now - (cfg.lastTimerScan or 0)) >= 2.0 then
        cfg.lastTimerScan = now
        cfg.timerSource = findTimerSourceInNode(locNode)
        timerText, isActive = readFromTimerSource(cfg.timerSource)
    end

    if timerText then
        cfg.label.Text = timerText
        cfg.label.TextColor3 = isActive and SUCCESS or ACCENT
        return
    end

    if cfg.checkWhirlpool then
        local effects = workspace:FindFirstChild("Effects")
        local whirlpool = effects and effects:FindFirstChild("SerpentWhirlpool")
        if whirlpool then
            if not cfg.wpTimerSource or (now - (cfg.lastWpScan or 0)) >= 2.5 then
                cfg.lastWpScan = now
                cfg.wpTimerSource = findTimerSourceInNode(whirlpool)
            end
            local wpTimer, wpActive = readFromTimerSource(cfg.wpTimerSource)
            if wpTimer then
                cfg.label.Text = wpTimer
                cfg.label.TextColor3 = wpActive and SUCCESS or ACCENT
            else
                cfg.label.Text = "whirlpool"
                cfg.label.TextColor3 = ACCENT
            end
            return
        end
    end

    cfg.label.Text = "—"
    cfg.label.TextColor3 = MUTED
end

local function updateAllBosses()
    local now = os.clock()
    for _, cfg in ipairs(bossConfigs) do
        updateBossConfig(cfg, now)
    end
end

local settingsOpen = false

local function applyPanelLayout(animated)
    local targetHeight = BASE_HEIGHT
    local panelHeight = 120
    local statusY = 82

    if settingsOpen then
        if settingsTab == "hp" then
            targetHeight = HP_OPEN_HEIGHT
            panelHeight = 175
            statusY = 221
        else
            targetHeight = MAIN_OPEN_HEIGHT
            panelHeight = 120
            statusY = 166
        end
    end

    statusLabel.Position = UDim2.fromOffset(12, statusY)
    if animated then
        local info = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(panel, info, {Size = UDim2.fromOffset(250, panelHeight)}):Play()
        TweenService:Create(frame, info, {Size = UDim2.fromOffset(WIDTH, targetHeight)}):Play()
    else
        panel.Size = UDim2.fromOffset(250, panelHeight)
        frame.Size = UDim2.fromOffset(WIDTH, targetHeight)
    end
end

local function setSettingsTab(tab)
    settingsTab = tab
    local hp = tab == "hp"
    mainPage.Visible = not hp
    hpPage.Visible = hp

    tabMain.BackgroundColor3 = hp and FIELD or ACCENT
    tabMain.TextColor3 = hp and MUTED or Color3.fromRGB(36, 27, 44)
    tabHp.BackgroundColor3 = hp and ACCENT or FIELD
    tabHp.TextColor3 = hp and Color3.fromRGB(36, 27, 44) or MUTED

    if settingsOpen then
        applyPanelLayout(true)
    end
    if hp then updateAllBosses() end
end

setSettingsTab("main")

tabMain.MouseButton1Click:Connect(function()
    setSettingsTab("main")
end)

tabHp.MouseButton1Click:Connect(function()
    setSettingsTab("hp")
end)

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

local function setSettingsOpen(open)
    settingsOpen = open
    settingsButton.Text = open and "свернуть" or "настройки"
    settingsButton.TextColor3 = open and ACCENT or TEXT
    refreshButton.Visible = not open
    findButton.Visible = not open
    panel.Visible = open
    applyPanelLayout(true)
    if open and settingsTab == "hp" then
        updateAllBosses()
    end
end

settingsButton.MouseButton1Click:Connect(function()
    setSettingsOpen(not settingsOpen)
end)

task.spawn(function()
    while screen.Parent do
        if settingsOpen and settingsTab == "hp" then
            updateAllBosses()
        end
        task.wait(1)
    end
end)

switch.MouseButton1Click:Connect(function()
    setAutoExecute(not settings.autoExecute)
end)

loaderBox.FocusLost:Connect(commitLoader)

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

local function collectRegionsFromServerBrowserUi()
    local browser = findServerBrowser()
    local main = browser and browser:FindFirstChild("MainFrame")
    if not main then return end

    local updated = false
    for _, obj in ipairs(main:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Name == "IdLabel" then
            local row = obj.Parent
            local code = (obj.Text or ""):match("#?%s*(%d+)")
            if row and code then
                local regionText
                for _, child in ipairs(row:GetDescendants()) do
                    if child:IsA("TextLabel") and child ~= obj and child.Name ~= "NameLabel" then
                        local cname = child.Name:lower()
                        local txt = (child.Text or ""):gsub("<[^>]*>", ""):gsub("^%s+", ""):gsub("%s+$", "")
                        if txt ~= "" and (cname:find("region", 1, true) or cname:find("country", 1, true) or cname:find("loc", 1, true) or isUnitedStatesRegion(txt)) then
                            regionText = txt
                            break
                        end
                    end
                end
                if regionText and serverRegionsByCode[code] ~= regionText then
                    serverRegionsByCode[code] = regionText
                    updated = true
                end
            end
        end
    end

    if updated then
        rebuildServerList(remoteServersCache)
    end
end

local fetchingServers = false

local function fetchServers()
    if fetchingServers then return false end
    fetchingServers = true

    local success = false
    local before = serverGeneration
    local nativeOk, nativeButton = pcall(findNativeRefreshButton)

    if nativeOk and nativeButton and type(firesignal) == "function" then
        task.spawn(function()
            pcall(firesignal, nativeButton.MouseButton1Click)
        end)
        for _ = 1, 6 do
            task.wait(0.2)
            if serverGeneration > before then
                success = true
                break
            end
        end
    end

    if not success then
        before = serverGeneration
        task.spawn(function()
            pcall(function()
                getServers:InvokeServer()
            end)
        end)
        for _ = 1, 10 do
            task.wait(0.2)
            if serverGeneration > before then
                success = true
                break
            end
        end
    end

    if fetchRobloxPublicServers(3) then
        success = true
    end

    pcall(collectRegionsFromServerBrowserUi)

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
    pcall(collectRegionsFromServerBrowserUi)

    local bestKnownNonUS
    local bestUnknown
    local current = normalizeId(game.JobId)
    local candidates = 0
    local skippedVisited = 0
    local skippedUS = 0

    for _, server in ipairs(servers) do
        local key = normalizeId(server.id)
        if key and key ~= current
            and not server.restricted
            and server.players < server.maxPlayers then
            if server.isUS then
                skippedUS = skippedUS + 1
            else
                candidates = candidates + 1
                if visited[key] or failedServers[key] then
                    skippedVisited = skippedVisited + 1
                elseif server.region then
                    if not bestKnownNonUS or server.players < bestKnownNonUS.players then
                        bestKnownNonUS = server
                    end
                else
                    if not bestUnknown or server.players < bestUnknown.players then
                        bestUnknown = server
                    end
                end
            end
        end
    end

    local chosen = bestKnownNonUS
    if not chosen and not hasKnownRegionData then
        chosen = bestUnknown
    end

    return chosen, candidates, skippedVisited, skippedUS
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
        "_G.AssistVisitedServers = _G.AssistVisitedServers or {}",
        "for k, v in pairs(__assistVisited) do _G.AssistVisitedServers[k] = v end",
        "if type(getgenv) == \"function\" then",
        "    local envOk, env = pcall(getgenv)",
        "    if envOk and type(env) == \"table\" then env.AssistVisitedServers = _G.AssistVisitedServers end",
        "end",
    }

    if includeScript then
        local loaderCode, err = buildLoaderCode()
        if not loaderCode then return nil, err end
        lines[#lines + 1] = "if _G.__AssistAutoExecuted then return end"
        lines[#lines + 1] = "_G.__AssistAutoExecuted = true"
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

local MAX_TELEPORT_RETRIES = 15
local finding = false
local pendingTargetKey
local teleportAttemptId = 0
local currentRetryCount = 0

local function stopFinding(message, color)
    finding = false
    teleportAttemptId = teleportAttemptId + 1
    pendingTargetKey = nil
    findButton.Text = "найти сервер"
    if message then
        setStatus(message, color)
    end
end

local function attemptTeleport(retryCount)
    if not finding then return end
    currentRetryCount = retryCount

    local target, candidates, skippedVisited, skippedUS = chooseServer()
    if not target then
        if retryCount > 0 then
            stopFinding("подходящие серверы закончились", DANGER)
        elseif candidates > 0 and skippedVisited == candidates then
            stopFinding("все серверы вне US уже посещены", MUTED)
        elseif skippedUS and skippedUS > 0 then
            stopFinding("найдены только серверы United States", DANGER)
        else
            stopFinding("нет подходящих серверов", DANGER)
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
        if pendingTargetKey then
            unmarkVisited(pendingTargetKey)
            saveVisited()
        end
        stopFinding("executor не поддерживает авто-запуск", DANGER)
        return
    end

    if queueFn then
        local bootstrap, err = buildBootstrap(settings.autoExecute)
        if not bootstrap then
            if pendingTargetKey then
                unmarkVisited(pendingTargetKey)
                saveVisited()
            end
            stopFinding(err, DANGER)
            return
        end

        local ok, queueErr = pcall(queueFn, bootstrap)
        if not ok and settings.autoExecute then
            if pendingTargetKey then
                unmarkVisited(pendingTargetKey)
                saveVisited()
            end
            stopFinding("ошибка очереди: " .. tostring(queueErr), DANGER)
            return
        end
    end

    teleportAttemptId = teleportAttemptId + 1
    local thisAttempt = teleportAttemptId

    findButton.Text = "отмена"
    local targetLabel = target.name and target.name:match("#%s*%d+") or target.id:sub(1, 8)
    local regionLabel = target.region and (" · " .. target.region) or ""
    setStatus(string.format("телепорт: %d/%d · %s%s", target.players, target.maxPlayers, targetLabel, regionLabel), ACCENT)

    local ok = pcall(function()
        TeleportService:TeleportToPlaceInstance(target.placeId, target.id, player)
    end)

    if not ok then
        if pendingTargetKey then
            failedServers[pendingTargetKey] = true
            pendingTargetKey = nil
        end
        if retryCount < MAX_TELEPORT_RETRIES then
            setStatus("ошибка запуска — ищу другой...", ACCENT)
            task.wait(0.25)
            if finding and teleportAttemptId == thisAttempt then
                attemptTeleport(retryCount + 1)
            end
        else
            stopFinding("не удалось начать телепорт", DANGER)
        end
        return
    end

    task.delay(15, function()
        if finding and teleportAttemptId == thisAttempt then
            stopFinding("таймаут телепорта — попробуй снова", DANGER)
        end
    end)
end

findButton.MouseButton1Click:Connect(function()
    if fetchingServers then return end
    if finding then
        stopFinding("поиск отменён", MUTED)
        return
    end

    task.spawn(function()
        if #servers == 0 then
            setStatus("получаю список серверов...", MUTED)
            if not fetchServers() then
                setStatus("не удалось получить список — попробуй ещё раз", DANGER)
                return
            end
        elseif #publicServers == 0 then
            setStatus("ищу самые маленькие серверы...", MUTED)
            fetchRobloxPublicServers(3)
        end

        finding = true
        attemptTeleport(0)
    end)
end)

TeleportService.TeleportInitFailed:Connect(function(_, _, message)
    if not finding then return end

    pcall(function()
        GuiService:ClearError()
    end)

    if pendingTargetKey then
        failedServers[pendingTargetKey] = true
        visited[pendingTargetKey] = true
        saveVisited()
        pendingTargetKey = nil
    end

    if currentRetryCount < MAX_TELEPORT_RETRIES then
        local attemptAtFail = teleportAttemptId
        setStatus("сервер недоступен — ищу другой...", ACCENT)
        task.spawn(function()
            task.wait(0.35)
            if finding and teleportAttemptId == attemptAtFail then
                attemptTeleport(currentRetryCount + 1)
            end
        end)
    else
        stopFinding("телепорт не удался: " .. tostring(message), DANGER)
    end
end)
