-- Hopper Script PRO (Final Fixed) - Server-by-server scanner y GUI
-- Versión corregida: agrega showNotification, corrige orden de creación de controles,
-- activa el botón STOP al iniciar exploración y mejora manejo de errores.
-- Usa: copiar el contenido o ejecutar desde raw.githubusercontent con loadstring(game:HttpGet(url))()

if not (game and game.GetService) then return end
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
if not player then error("Este script debe ejecutarse en un LocalScript o en un entorno con LocalPlayer.") end
local playerGui = player:WaitForChild("PlayerGui")

-- CONFIG
local PLACE_ID = game.PlaceId
local MIN_GENERATION_DEFAULT = 50 * 1000000 -- 50M por defecto
local MIN_GENERATION = MIN_GENERATION_DEFAULT
local SCAN_WAIT = 4 -- segundos tras teleport antes de escanear
local MAX_SERVERS_TO_TRY = 200
local teleportRetryCount = 3
local teleportRetryDelay = 1.2
local throttleHttpSeconds = 1.0
local lastHttp = 0

-- helpers
local function addCorner(parent, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = parent end
local function formatNumber(n) n = tonumber(n) or 0; if n>=1e9 then return string.format("$%.1fB", n/1e9) elseif n>=1e6 then return string.format("$%.1fM", n/1e6) elseif n>=1e3 then return string.format("$%.1fK", n/1e3) else return "$"..tostring(math.floor(n)) end end

local function safeHttpGet(url)
    local now = tick()
    if now - lastHttp < throttleHttpSeconds then task.wait(throttleHttpSeconds - (now - lastHttp)) end
    lastHttp = tick()
    local ok, body = pcall(function() return game:HttpGet(url) end)
    if not ok then return nil, "httpfail" end
    local decodeOk, data = pcall(function() return HttpService:JSONDecode(body) end)
    if not decodeOk then return nil, "decodefail" end
    return data, nil
end

-- showNotification (faltaba en tu script original)
local function showNotification(text, color)
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(0, 420, 0, 84)
    notif.Position = UDim2.new(1, -440, 0, 24)
    notif.BackgroundColor3 = color or Color3.fromRGB(50,200,100)
    notif.ZIndex = 999
    notif.Parent = screenGui or playerGui
    addCorner(notif, 10)

    local notifText = Instance.new("TextLabel")
    notifText.Size = UDim2.new(1, -20, 1, -20)
    notifText.Position = UDim2.new(0, 10, 0, 10)
    notifText.BackgroundTransparency = 1
    notifText.Font = Enum.Font.GothamBold
    notifText.TextSize = 14
    notifText.TextColor3 = Color3.fromRGB(255,255,255)
    notifText.TextWrapped = true
    notifText.Text = tostring(text)
    notifText.Parent = notif

    task.spawn(function()
        task.wait(4)
        if notif and notif.Parent then notif:Destroy() end
    end)
end

-- GUI minimal (Hopper Pro style) - creado/ reemplazado
local existing = playerGui:FindFirstChild("HopperScannerGui")
if existing then existing:Destroy() end

local screenGui = Instance.new("ScreenGui"); screenGui.Name = "HopperScannerGui"; screenGui.ResetOnSpawn = false; screenGui.Parent = playerGui
local main = Instance.new("Frame"); main.Size = UDim2.new(0,520,0,620); main.Position = UDim2.new(0.5,-260,0.5,-310); main.BackgroundColor3 = Color3.fromRGB(25,35,50); main.Parent = screenGui; addCorner(main, 12)
local top = Instance.new("Frame"); top.Size = UDim2.new(1,0,0,54); top.Position = UDim2.new(0,0,0,0); top.BackgroundColor3 = Color3.fromRGB(35,45,65); top.Parent = main; addCorner(top, 12)
local title = Instance.new("TextLabel"); title.Size = UDim2.new(1,-120,1,0); title.Position = UDim2.new(0,16,0,0); title.BackgroundTransparency = 1; title.Font = Enum.Font.GothamBold; title.TextSize = 18; title.TextColor3 = Color3.fromRGB(255,255,255); title.TextXAlignment = Enum.TextXAlignment.Left; title.Text = "🤖 HOPPER - Server Scanner"; title.Parent = top
local closeBtn = Instance.new("TextButton"); closeBtn.Size = UDim2.new(0,40,0,40); closeBtn.Position = UDim2.new(1,-52,0,7); closeBtn.BackgroundColor3 = Color3.fromRGB(220,50,50); closeBtn.Text = "✕"; closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 18; closeBtn.Parent = top; addCorner(closeBtn, 8)

local statusPanel = Instance.new("Frame"); statusPanel.Size = UDim2.new(1,-32,0,110); statusPanel.Position = UDim2.new(0,16,0,64); statusPanel.BackgroundColor3 = Color3.fromRGB(30,40,55); statusPanel.Parent = main; addCorner(statusPanel,8)
local statusText = Instance.new("TextLabel"); statusText.Size = UDim2.new(1,-20,1,-20); statusText.Position = UDim2.new(0,10,0,10); statusText.BackgroundTransparency = 1; statusText.Font = Enum.Font.Gotham; statusText.TextSize = 13; statusText.TextColor3 = Color3.fromRGB(200,200,200); statusText.TextWrapped = true; statusText.TextYAlignment = Enum.TextYAlignment.Top; statusText.Text = "✅ Listo. Elige filtro y presiona INICIAR EXPLORACIÓN"; statusText.Parent = statusPanel

local filterPanel = Instance.new("Frame"); filterPanel.Size = UDim2.new(1,-32,0,92); filterPanel.Position = UDim2.new(0,16,0,184); filterPanel.BackgroundColor3 = Color3.fromRGB(30,40,55); filterPanel.Parent = main; addCorner(filterPanel,8)
local filterLabel = Instance.new("TextLabel"); filterLabel.Size = UDim2.new(1,-20,0,24); filterLabel.Position = UDim2.new(0,10,0,6); filterLabel.BackgroundTransparency=1; filterLabel.Font=Enum.Font.GothamBold; filterLabel.Text="⚙️ FILTROS"; filterLabel.TextSize=14; filterLabel.TextColor3=Color3.fromRGB(255,255,255); filterLabel.Parent = filterPanel

-- rangeLabel created before minButtons (fix)
local rangeLabel = Instance.new("TextLabel"); rangeLabel.Size = UDim2.new(1,-20,0,20); rangeLabel.Position = UDim2.new(0,10,0,64); rangeLabel.BackgroundTransparency=1; rangeLabel.Font=Enum.Font.Gotham; rangeLabel.TextSize=12; rangeLabel.TextColor3=Color3.fromRGB(200,200,200); rangeLabel.TextXAlignment=Enum.TextXAlignment.Left; rangeLabel.Parent=filterPanel

-- Minimum selection buttons (multilevel)
local mins = {["10M"]=10*1e6, ["50M"]=50*1e6, ["100M"]=100*1e6, ["500M"]=500*1e6, ["1B"]=1e9}
local chosenMinKey = "50M"
local minButtons = {}
local function updateRangeLabel(lbl)
    lbl.Text = "🔎 Mínimo: "..chosenMinKey.." ("..formatNumber(MIN_GENERATION)..")"
end

local x = 10
for key,val in pairs(mins) do
    local b = Instance.new("TextButton"); b.Size = UDim2.new(0,80,0,28); b.Position = UDim2.new(0,x,0,36); b.Text=key; b.Font=Enum.Font.GothamBold; b.TextSize=12; b.Parent=filterPanel; addCorner(b,6)
    b.MouseButton1Click:Connect(function()
        MIN_GENERATION = val; chosenMinKey = key; updateRangeLabel(rangeLabel)
        for kk,btn in pairs(minButtons) do btn.BackgroundColor3 = (kk==key) and Color3.fromRGB(50,200,100) or Color3.fromRGB(100,100,100) end
    end)
    minButtons[key] = b
    x = x + 86
end
-- style default
for kk,btn in pairs(minButtons) do btn.BackgroundColor3 = (kk=="50M") and Color3.fromRGB(50,200,100) or Color3.fromRGB(100,100,100) end
updateRangeLabel(rangeLabel)

-- Buttons
local scanBtn = Instance.new("TextButton"); scanBtn.Size = UDim2.new(1,-32,0,46); scanBtn.Position = UDim2.new(0,16,0,288); scanBtn.BackgroundColor3 = Color3.fromRGB(50,150,250); scanBtn.Font = Enum.Font.GothamBold; scanBtn.TextSize=15; scanBtn.TextColor3 = Color3.fromRGB(255,255,255); scanBtn.Text = "🔍 ESCANEAR SERVIDOR ACTUAL"; scanBtn.Parent = main; addCorner(scanBtn,8)
local exploreBtn = Instance.new("TextButton"); exploreBtn.Size = UDim2.new(1,-32,0,46); exploreBtn.Position = UDim2.new(0,16,0,344); exploreBtn.BackgroundColor3 = Color3.fromRGB(50,200,100); exploreBtn.Font = Enum.Font.GothamBold; exploreBtn.TextSize=15; exploreBtn.TextColor3 = Color3.fromRGB(255,255,255); exploreBtn.Text = "🚀 INICIAR EXPLORACIÓN (Server-by-server)"; exploreBtn.Parent = main; addCorner(exploreBtn,8)
local stopBtn = Instance.new("TextButton"); stopBtn.Size = UDim2.new(1,-32,0,46); stopBtn.Position = UDim2.new(0,16,0,344); stopBtn.BackgroundColor3 = Color3.fromRGB(220,50,50); stopBtn.Font = Enum.Font.GothamBold; stopBtn.TextSize=15; stopBtn.TextColor3 = Color3.fromRGB(255,255,255); stopBtn.Text = "⏹ DETENER EXPLORACIÓN"; stopBtn.Visible=false; stopBtn.Parent=main; addCorner(stopBtn,8)

-- results frame
local results = Instance.new("ScrollingFrame"); results.Size = UDim2.new(1,-32,0,210); results.Position = UDim2.new(0,16,0,404); results.BackgroundColor3 = Color3.fromRGB(30,40,55); results.ScrollBarThickness=6; results.Parent=main; addCorner(results,8)
results.CanvasSize = UDim2.new(0,0,0,0)

-- storage for found servers in the current session (only local to this server instance)
local foundServers = {} -- { {serverId=..., generation=..., name=..., players=...} }

local function clearResultsUI()
    for _,c in ipairs(results:GetChildren()) do if c:IsA("Frame") or c:IsA("TextLabel") or c:IsA("TextButton") then c:Destroy() end end
    results.CanvasSize = UDim2.new(0,0,0,0)
end

local function addResultToUI(entry)
    -- entry: {serverId, generation, genText, name, players}
    local idx = #foundServers
    local i = idx
    local frame = Instance.new("Frame"); frame.Size = UDim2.new(1,-12,0,70); frame.Position = UDim2.new(0,6,0,i*75); frame.BackgroundColor3 = Color3.fromRGB(40,50,70); frame.Parent = results; addCorner(frame,8)
    local nameL = Instance.new("TextLabel"); nameL.Size=UDim2.new(1,-220,0,20); nameL.Position=UDim2.new(0,10,0,8); nameL.BackgroundTransparency=1; nameL.Font=Enum.Font.GothamBold; nameL.TextSize=13; nameL.TextColor3=Color3.fromRGB(255,255,255); nameL.Text=entry.name or "Brainrot"; nameL.Parent=frame
    local genL = Instance.new("TextLabel"); genL.Size=UDim2.new(1,-220,0,18); genL.Position=UDim2.new(0,10,0,30); genL.BackgroundTransparency=1; genL.Font=Enum.Font.Gotham; genL.TextSize=12; genL.TextColor3=Color3.fromRGB(100,255,100); genL.Text="💰 "..formatNumber(entry.generation).."/s"; genL.Parent=frame
    local playersL = Instance.new("TextLabel"); playersL.Size=UDim2.new(1,-220,0,16); playersL.Position=UDim2.new(0,10,0,50); playersL.BackgroundTransparency=1; playersL.Font=Enum.Font.Gotham; playersL.TextSize=11; playersL.TextColor3=Color3.fromRGB(150,180,255); playersL.Text="👥 "..(entry.players or "0/??"); playersL.Parent=frame
    local joinBtn = Instance.new("TextButton"); joinBtn.Size=UDim2.new(0,92,0,50); joinBtn.Position=UDim2.new(1,-106,0,10); joinBtn.BackgroundColor3=Color3.fromRGB(50,150,250); joinBtn.Font=Enum.Font.GothamBold; joinBtn.TextSize=14; joinBtn.Text="ENTRAR"; joinBtn.Parent=frame; addCorner(joinBtn,8)
    joinBtn.MouseButton1Click:Connect(function()
        joinBtn.Text = "⏳"
        joinBtn.BackgroundColor3 = Color3.fromRGB(100,100,100)
        -- teleport to selected server
        local tries = 0; local success = false
        while tries < teleportRetryCount and not success do
            tries = tries + 1
            local ok,err = pcall(function() TeleportService:TeleportToPlaceInstance(PLACE_ID, tostring(entry.serverId), player) end)
            if ok then success = true; break end
            warn("Teleport fallo intento "..tries..": "..tostring(err))
            task.wait(teleportRetryDelay)
        end
        if not success then
            joinBtn.Text = "ENTRAR"; joinBtn.BackgroundColor3 = Color3.fromRGB(50,150,250)
            showNotification("❌ Falló el teleport a ese servidor", Color3.fromRGB(220,50,50))
        end
    end)
    table.insert(foundServers, entry)
    -- update canvas size
    local canvasHeight = (#foundServers)*75
    results.CanvasSize = UDim2.new(0,0,0,canvasHeight)
end

-- scanning function for current server
local function scanCurrentServerForBrainrots()
    statusText.Text = "🔍 Escaneando este servidor... Buscando textos 'SECRET' y generación"
    local found = {}
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BillboardGui") then
            local hasSecret = false; local genText = nil; local nameText = nil
            for _,c in ipairs(obj:GetDescendants()) do
                if c:IsA("TextLabel") and type(c.Text) == "string" then
                    local txt = c.Text
                    local u = txt:upper()
                    if u:find("SECRET") then hasSecret = true end
                    -- Accept forms like "$4M/s" or "4M/s" or "4M/s 💎"
                    local m = txt:match("(%$?[%d%.]+[KMB]*/s)")
                    if not m then m = txt:match("(%$?[%d%.]+[KMB]+/s)") end
                    if m then genText = m end
                    if (not txt:find("%$")) and (not u:find("SECRET")) and (not txt:find("/s")) and txt:len()>2 and txt:len()<40 then nameText = txt end
                end
            end
            if hasSecret and genText then
                local num = tonumber((genText:match("([%d%.]+)")))
                local generation = 0
                if num then
                    if genText:find("B/s") then generation = num * 1e9
                    elseif genText:find("M/s") then generation = num * 1e6
                    elseif genText:find("K/s") then generation = num * 1e3 end
                end
                if generation >= MIN_GENERATION then
                    local playersCount = #Players:GetPlayers()
                    table.insert(found, { serverId = tostring(game.JobId or "local"), generation = generation, genText = genText, name = nameText or "Brainrot SECRET", players = tostring(playersCount).."/"..tostring(Players.MaxPlayers or 16) })
                end
            end
        end
    end
    return found
end

-- fetch servers pages
local function fetchServersPage(cursor)
    local url = ("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Desc&limit=100"):format(tostring(PLACE_ID))
    if cursor and cursor ~= "" then url = url .. "&cursor=" .. tostring(cursor) end
    local data, err = safeHttpGet(url)
    if not data then return nil, err end
    return data, nil
end

local function getServersList(limit)
    limit = limit or MAX_SERVERS_TO_TRY
    local servers = {}
    local cursor = nil
    local total = 0
    repeat
        local data,err = fetchServersPage(cursor)
        if not data then break end
        if type(data.data) == "table" then
            for _,s in ipairs(data.data) do
                if s and s.id and tostring(s.id) ~= tostring(game.JobId) then
                    if (s.playing or 0) >= 1 then -- al menos 1 player (tweakable)
                        table.insert(servers, s)
                        total = total + 1
                        if total >= limit then break end
                    end
                end
            end
        end
        cursor = data.nextPageCursor
        if not cursor or cursor == "" then break end
    until total >= limit
    return servers
end

-- main exploration: teleport server-by-server until find at least one brainrot in a server
local function startServerByServerExplore()
    if _G.HopperExploring then return end
    _G.HopperExploring = true
    exploreBtn.Visible = false
    stopBtn.Visible = true

    statusText.Text = "🌐 Obteniendo lista de servidores..."
    task.wait(0.4)
    local servers = getServersList(MAX_SERVERS_TO_TRY)
    if not servers or #servers == 0 then statusText.Text = "❌ No se obtuvieron servidores públicos."; _G.HopperExploring = false; exploreBtn.Visible = true; stopBtn.Visible = false; return end
    statusText.Text = "🔁 Iniciando teleport secuencial (buscando ≥ "..formatNumber(MIN_GENERATION).."/s)"
    -- iterate servers in random order to avoid patterns
    local order = {}
    for i=1,#servers do order[i] = servers[i] end
    for i = #order, 2, -1 do local j = math.random(1,i); order[i],order[j] = order[j],order[i] end

    -- Before starting, scan current server too
    local localFound = scanCurrentServerForBrainrots()
    if #localFound > 0 then
        for _,f in ipairs(localFound) do addResultToUI(f) end
        statusText.Text = "🎉 Encontrado en este servidor! Revisa lista abajo."
        showNotification("🎉 Encontrado en este servidor: "..formatNumber(localFound[1].generation).."/s", Color3.fromRGB(50,200,100))
        _G.HopperExploring = false
        exploreBtn.Visible = true; stopBtn.Visible = false
        return
    end

    -- iterate servers
    for idx,s in ipairs(order) do
        if not _G.HopperExploring then break end
        statusText.Text = "🔁 Teleportando a servidor "..tostring(idx).."/"..tostring(math.min(#order, MAX_SERVERS_TO_TRY))
        local ok = false
        -- try teleport with retries
        for attempt=1,teleportRetryCount do
            local success,err = pcall(function() TeleportService:TeleportToPlaceInstance(PLACE_ID, tostring(s.id), player) end)
            if success then ok = true; break end
            warn("Teleport intento "..tostring(attempt).." fallo: "..tostring(err))
            task.wait(teleportRetryDelay)
        end
        if not ok then
            warn("No se pudo teleportar al server "..tostring(s.id)..", siguiente...")
            task.wait(0.4)
            continue
        end
        -- after successful teleport, execution will move to the new server instance and this script will run from top.
        return
    end

    -- if loop finished and no teleport succeeded
    _G.HopperExploring = false
    exploreBtn.Visible = true; stopBtn.Visible = false
    statusText.Text = "🔍 Exploración finalizada (no se encontraron brainrots o no se pudo teleportar)."
end

-- post-teleport handler: when a new server loads and _G.HopperExploring == true, scan this server and notify if found
if _G.HopperExploring then
    statusText.Text = "⏳ Entrando por exploración... esperando "..tostring(SCAN_WAIT).."s y luego escaneando."
    task.wait(SCAN_WAIT)
    local found = scanCurrentServerForBrainrots()
    if found and #found > 0 then
        for _,f in ipairs(found) do addResultToUI(f) end
        statusText.Text = "🎉 ¡Brainrot detectado en este servidor! Revisa la lista para entrar."
        showNotification("🎉 Encontrado: "..formatNumber(found[1].generation) .. "/s en este servidor.", Color3.fromRGB(50,200,100))
        _G.HopperExploring = false
        exploreBtn.Visible = true; stopBtn.Visible = false
    else
        statusText.Text = "🔎 No encontrado en este servidor. Pulsa INICIAR EXPLORACIÓN para continuar."
        _G.HopperExploring = false
        exploreBtn.Visible = true; stopBtn.Visible = false
    end
end

-- UI connections
closeBtn.MouseButton1Click:Connect(function() if screenGui and screenGui.Parent then screenGui:Destroy() end; _G.HopperExploring = false end)

scanBtn.MouseButton1Click:Connect(function()
    scanBtn.Text = "⏳ ESCANEANDO..."; scanBtn.BackgroundColor3 = Color3.fromRGB(100,100,100)
    task.spawn(function()
        local found = scanCurrentServerForBrainrots()
        if found and #found > 0 then
            for _,f in ipairs(found) do addResultToUI(f) end
            statusText.Text = "🎉 Brainrot(s) detectado(s) en este servidor."
            showNotification("🎉 Encontrado: "..formatNumber(found[1].generation).."/s", Color3.fromRGB(50,200,100))
        else
            statusText.Text = "🔎 No se detectaron Brainrots en este servidor."
            showNotification("🔎 No se detectaron Brainrots en este servidor.", Color3.fromRGB(200,200,50))
        end
        scanBtn.Text = "🔍 ESCANEAR SERVIDOR ACTUAL"; scanBtn.BackgroundColor3 = Color3.fromRGB(50,150,250)
    end)
end)

exploreBtn.MouseButton1Click:Connect(function()
    -- begin server-by-server exploration
    exploreBtn.Visible = false; stopBtn.Visible = true
    task.spawn(startServerByServerExplore)
end)

stopBtn.MouseButton1Click:Connect(function()
    _G.HopperExploring = false
    statusText.Text = "⏸ Exploración detenida por el usuario."
    exploreBtn.Visible = true; stopBtn.Visible = false
end)

-- init UI state
statusText.Text = "✅ Listo. Selecciona mínimo y usa ESCANEAR o INICIAR EXPLORACIÓN (server-by-server)."
