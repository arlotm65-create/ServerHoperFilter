-- Hopper PRO con Discord Webhook
-- Notifica servidores buenos directamente a Discord

print("🚀 HOPPER PRO + DISCORD WEBHOOK")

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ⚠️ CONFIGURA TU WEBHOOK AQUÍ ⚠️
local DISCORD_WEBHOOK = "https://discord.com/api/webhooks/TU_WEBHOOK_AQUI"
-- Para obtener tu webhook: Server Settings > Integrations > Webhooks > New Webhook > Copy Webhook URL

-- CONFIGURACIÓN
local PLACE_ID = game.PlaceId
local MIN_GENERATION = 10000000 -- 10M
local SCAN_TIME = 4
local isExploring = false
local goodBrainrots = {}
local serversChecked = 0
local webhookEnabled = true

print("Place ID:", PLACE_ID)

-- Funciones auxiliares
local function addCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
end

local function formatNumber(num)
    if num >= 1000000000 then
        return string.format("$%.1fB", num / 1000000000)
    elseif num >= 1000000 then
        return string.format("$%.1fM", num / 1000000)
    else
        return "$" .. tostring(num)
    end
end

-- ENVIAR A DISCORD (Versión compatible con más executors)
local function sendToDiscord(brainrotData)
    if not webhookEnabled or DISCORD_WEBHOOK == "https://discord.com/api/webhooks/TU_WEBHOOK_AQUI" then
        warn("⚠️ Webhook no configurado o desactivado")
        return false
    end
    
    local jobId = brainrotData.serverId
    local placeId = PLACE_ID
    
    -- Crear embed para Discord
    local embed = {
        title = "🎯 Sk Notify | Notify 10m+ plus",
        color = 15158332,
        fields = {
            {
                name = "**Brainrot:**",
                value = brainrotData.name,
                inline = false
            },
            {
                name = "**Money per sec:**",
                value = formatNumber(brainrotData.generation),
                inline = false
            },
            {
                name = "**JobId Mobile:**",
                value = jobId,
                inline = false
            },
            {
                name = "**JobId PC:**",
                value = jobId,
                inline = false
            },
            {
                name = "**Join Link:**",
                value = "[Clique aqui para entrar](https://www.roblox.com/games/start?placeId=" .. placeId .. "&launchData={\"server\":\"" .. jobId .. "\"})",
                inline = false
            },
            {
                name = "**Join Script PC:**",
                value = "```lua\ngame:GetService(\"TeleportService\"):TeleportToPlaceInstance(" .. placeId .. ", \"" .. jobId .. "\", game.Players.LocalPlayer)\n```",
                inline = false
            }
        },
        footer = {
            text = "Sk Notify | by Hopper PRO | " .. os.date("%H:%M") .. " (Horário de Brasília) | hoy a las " .. os.date("%H:%M")
        }
    }
    
    local data = {
        username = "Sk Notify",
        embeds = {embed}
    }
    
    local jsonData = HttpService:JSONEncode(data)
    
    -- Intentar múltiples métodos
    local success = false
    local methods = {
        function() -- Método 1: request
            return request({
                Url = DISCORD_WEBHOOK,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = jsonData
            })
        end,
        function() -- Método 2: syn.request
            return syn.request({
                Url = DISCORD_WEBHOOK,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = jsonData
            })
        end,
        function() -- Método 3: http_request
            return http_request({
                Url = DISCORD_WEBHOOK,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = jsonData
            })
        end,
        function() -- Método 4: http.request (para algunos executors móviles)
            if http and http.request then
                return http.request({
                    Url = DISCORD_WEBHOOK,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = jsonData
                })
            end
        end
    }
    
    for i, method in ipairs(methods) do
        local ok, result = pcall(method)
        if ok and result then
            print("✅ Enviado a Discord usando método", i)
            success = true
            break
        end
    end
    
    if not success then
        warn("❌ Ningún método HTTP funcionó. Tu executor puede no soportar webhooks.")
    end
    
    return success
end

-- GUI
local existing = playerGui:FindFirstChild("HopperGui")
if existing then existing:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HopperGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 999999
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 520, 0, 650)
mainFrame.Position = UDim2.new(0.5, -260, 0.5, -325)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 35, 50)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui
addCorner(mainFrame, 12)

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 50)
topBar.BackgroundColor3 = Color3.fromRGB(35, 45, 65)
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame
addCorner(topBar, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -100, 1, 0)
title.Position = UDim2.new(0, 15, 0, 0)
title.BackgroundTransparency = 1
title.Text = "🤖 HOPPER PRO - Discord Webhook"
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 40, 0, 40)
minimizeBtn.Position = UDim2.new(1, -90, 0, 5)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
minimizeBtn.Text = "—"
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 24
minimizeBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
minimizeBtn.Parent = topBar
addCorner(minimizeBtn, 8)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -45, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 20
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Parent = topBar
addCorner(closeBtn, 8)

local floatingCircle = Instance.new("Frame")
floatingCircle.Size = UDim2.new(0, 70, 0, 70)
floatingCircle.Position = UDim2.new(1, -90, 0.5, -35)
floatingCircle.BackgroundColor3 = Color3.fromRGB(50, 150, 250)
floatingCircle.BorderSizePixel = 0
floatingCircle.Active = true
floatingCircle.Draggable = true
floatingCircle.Visible = false
floatingCircle.Parent = screenGui
addCorner(floatingCircle, 35)

local circleBtn = Instance.new("TextButton")
circleBtn.Size = UDim2.new(1, 0, 1, 0)
circleBtn.BackgroundTransparency = 1
circleBtn.Text = "🤖"
circleBtn.Font = Enum.Font.GothamBold
circleBtn.TextSize = 32
circleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
circleBtn.Parent = floatingCircle

-- Panel Webhook
local webhookPanel = Instance.new("Frame")
webhookPanel.Size = UDim2.new(1, -30, 0, 130)
webhookPanel.Position = UDim2.new(0, 15, 0, 65)
webhookPanel.BackgroundColor3 = Color3.fromRGB(30, 40, 55)
webhookPanel.BorderSizePixel = 0
webhookPanel.Parent = mainFrame
addCorner(webhookPanel, 8)

local webhookLabel = Instance.new("TextLabel")
webhookLabel.Size = UDim2.new(1, -20, 0, 25)
webhookLabel.Position = UDim2.new(0, 10, 0, 5)
webhookLabel.BackgroundTransparency = 1
webhookLabel.Text = "🔗 WEBHOOK DE DISCORD"
webhookLabel.Font = Enum.Font.GothamBold
webhookLabel.TextSize = 14
webhookLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
webhookLabel.TextXAlignment = Enum.TextXAlignment.Left
webhookLabel.Parent = webhookPanel

local webhookInput = Instance.new("TextBox")
webhookInput.Size = UDim2.new(1, -20, 0, 35)
webhookInput.Position = UDim2.new(0, 10, 0, 35)
webhookInput.BackgroundColor3 = Color3.fromRGB(40, 50, 70)
webhookInput.BorderSizePixel = 0
webhookInput.Text = DISCORD_WEBHOOK
webhookInput.PlaceholderText = "https://discord.com/api/webhooks/..."
webhookInput.Font = Enum.Font.Gotham
webhookInput.TextSize = 11
webhookInput.TextColor3 = Color3.fromRGB(255, 255, 255)
webhookInput.TextXAlignment = Enum.TextXAlignment.Left
webhookInput.ClearTextOnFocus = false
webhookInput.Parent = webhookPanel
addCorner(webhookInput, 6)

local webhookToggle = Instance.new("TextButton")
webhookToggle.Size = UDim2.new(0, 100, 0, 30)
webhookToggle.Position = UDim2.new(0, 10, 0, 80)
webhookToggle.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
webhookToggle.Text = "✅ ACTIVADO"
webhookToggle.Font = Enum.Font.GothamBold
webhookToggle.TextSize = 12
webhookToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
webhookToggle.Parent = webhookPanel
addCorner(webhookToggle, 6)

local webhookTest = Instance.new("TextButton")
webhookTest.Size = UDim2.new(0, 120, 0, 30)
webhookTest.Position = UDim2.new(0, 120, 0, 80)
webhookTest.BackgroundColor3 = Color3.fromRGB(100, 150, 250)
webhookTest.Text = "🧪 PROBAR"
webhookTest.Font = Enum.Font.GothamBold
webhookTest.TextSize = 12
webhookTest.TextColor3 = Color3.fromRGB(255, 255, 255)
webhookTest.Parent = webhookPanel
addCorner(webhookTest, 6)

local webhookHelp = Instance.new("TextLabel")
webhookHelp.Size = UDim2.new(1, -20, 0, 20)
webhookHelp.Position = UDim2.new(0, 10, 0, 115)
webhookHelp.BackgroundTransparency = 1
webhookHelp.Text = "💡 Server Settings > Integrations > Webhooks > New Webhook"
webhookHelp.Font = Enum.Font.Gotham
webhookHelp.TextSize = 10
webhookHelp.TextColor3 = Color3.fromRGB(150, 150, 150)
webhookHelp.TextXAlignment = Enum.TextXAlignment.Left
webhookHelp.Parent = webhookPanel

local statusPanel = Instance.new("Frame")
statusPanel.Size = UDim2.new(1, -30, 0, 100)
statusPanel.Position = UDim2.new(0, 15, 0, 210)
statusPanel.BackgroundColor3 = Color3.fromRGB(30, 40, 55)
statusPanel.BorderSizePixel = 0
statusPanel.Parent = mainFrame
addCorner(statusPanel, 8)

local statusText = Instance.new("TextLabel")
statusText.Size = UDim2.new(1, -20, 1, -20)
statusText.Position = UDim2.new(0, 10, 0, 10)
statusText.BackgroundTransparency = 1
statusText.Text = "✅ GUI Cargado\n🎯 Busca: Brainrots de 10M/s+\n📊 Servidores revisados: 0\n💬 Discord: Listo para notificar"
statusText.Font = Enum.Font.Gotham
statusText.TextSize = 13
statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
statusText.TextWrapped = true
statusText.TextYAlignment = Enum.TextYAlignment.Top
statusText.Parent = statusPanel

local filterPanel = Instance.new("Frame")
filterPanel.Size = UDim2.new(1, -30, 0, 80)
filterPanel.Position = UDim2.new(0, 15, 0, 325)
filterPanel.BackgroundColor3 = Color3.fromRGB(30, 40, 55)
filterPanel.BorderSizePixel = 0
filterPanel.Parent = mainFrame
addCorner(filterPanel, 8)

local filterLabel = Instance.new("TextLabel")
filterLabel.Size = UDim2.new(1, -20, 0, 25)
filterLabel.Position = UDim2.new(0, 10, 0, 5)
filterLabel.BackgroundTransparency = 1
filterLabel.Text = "⚙️ FILTROS"
filterLabel.Font = Enum.Font.GothamBold
filterLabel.TextSize = 14
filterLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
filterLabel.TextXAlignment = Enum.TextXAlignment.Left
filterLabel.Parent = filterPanel

local sortLabel = Instance.new("TextLabel")
sortLabel.Size = UDim2.new(0.6, 0, 0, 20)
sortLabel.Position = UDim2.new(0, 10, 0, 35)
sortLabel.BackgroundTransparency = 1
sortLabel.Text = "📊 Ordenar por generación"
sortLabel.Font = Enum.Font.Gotham
sortLabel.TextSize = 12
sortLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
sortLabel.TextXAlignment = Enum.TextXAlignment.Left
sortLabel.Parent = filterPanel

local sortToggle = Instance.new("TextButton")
sortToggle.Size = UDim2.new(0, 50, 0, 25)
sortToggle.Position = UDim2.new(1, -60, 0, 32)
sortToggle.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
sortToggle.Text = "ON"
sortToggle.Font = Enum.Font.GothamBold
sortToggle.TextSize = 12
sortToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
sortToggle.Parent = filterPanel
addCorner(sortToggle, 6)
local sortEnabled = true

local notifLabel = Instance.new("TextLabel")
notifLabel.Size = UDim2.new(0.6, 0, 0, 20)
notifLabel.Position = UDim2.new(0, 10, 0, 58)
notifLabel.BackgroundTransparency = 1
notifLabel.Text = "🔔 Notificaciones locales"
notifLabel.Font = Enum.Font.Gotham
notifLabel.TextSize = 12
notifLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
notifLabel.TextXAlignment = Enum.TextXAlignment.Left
notifLabel.Parent = filterPanel

local notifToggle = Instance.new("TextButton")
notifToggle.Size = UDim2.new(0, 50, 0, 25)
notifToggle.Position = UDim2.new(1, -60, 0, 55)
notifToggle.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
notifToggle.Text = "ON"
notifToggle.Font = Enum.Font.GothamBold
notifToggle.TextSize = 12
notifToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
notifToggle.Parent = filterPanel
addCorner(notifToggle, 6)
local notifEnabled = true

local scanBtn = Instance.new("TextButton")
scanBtn.Size = UDim2.new(1, -30, 0, 45)
scanBtn.Position = UDim2.new(0, 15, 0, 420)
scanBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 250)
scanBtn.Text = "🔍 ESCANEAR SERVIDOR ACTUAL"
scanBtn.Font = Enum.Font.GothamBold
scanBtn.TextSize = 15
scanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
scanBtn.Parent = mainFrame
addCorner(scanBtn, 8)

local exploreBtn = Instance.new("TextButton")
exploreBtn.Size = UDim2.new(1, -30, 0, 45)
exploreBtn.Position = UDim2.new(0, 15, 0, 480)
exploreBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
exploreBtn.Text = "🚀 INICIAR EXPLORACIÓN AUTOMÁTICA"
exploreBtn.Font = Enum.Font.GothamBold
exploreBtn.TextSize = 15
exploreBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
exploreBtn.Parent = mainFrame
addCorner(exploreBtn, 8)

local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(1, -30, 0, 45)
stopBtn.Position = UDim2.new(0, 15, 0, 480)
stopBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
stopBtn.Text = "⏹ DETENER EXPLORACIÓN"
stopBtn.Font = Enum.Font.GothamBold
stopBtn.TextSize = 15
stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
stopBtn.Visible = false
stopBtn.Parent = mainFrame
addCorner(stopBtn, 8)

local resultsList = Instance.new("ScrollingFrame")
resultsList.Size = UDim2.new(1, -30, 0, 100)
resultsList.Position = UDim2.new(0, 15, 0, 535)
resultsList.BackgroundColor3 = Color3.fromRGB(30, 40, 55)
resultsList.BorderSizePixel = 0
resultsList.ScrollBarThickness = 6
resultsList.ScrollBarImageColor3 = Color3.fromRGB(50, 150, 250)
resultsList.CanvasSize = UDim2.new(0, 0, 0, 0)
resultsList.Parent = mainFrame
addCorner(resultsList, 8)

-- Notificación local
local function showNotification(message, color)
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(0, 380, 0, 90)
    notif.Position = UDim2.new(1, 0, 0, 20)
    notif.BackgroundColor3 = color or Color3.fromRGB(50, 200, 100)
    notif.BorderSizePixel = 0
    notif.ZIndex = 999
    notif.Parent = screenGui
    addCorner(notif, 12)
    
    local notifText = Instance.new("TextLabel")
    notifText.Size = UDim2.new(1, -20, 1, -20)
    notifText.Position = UDim2.new(0, 10, 0, 10)
    notifText.BackgroundTransparency = 1
    notifText.Text = message
    notifText.Font = Enum.Font.GothamBold
    notifText.TextSize = 15
    notifText.TextColor3 = Color3.fromRGB(255, 255, 255)
    notifText.TextWrapped = true
    notifText.ZIndex = 1000
    notifText.Parent = notif
    
    if notifEnabled then
        pcall(function()
            local sound = Instance.new("Sound")
            sound.SoundId = "rbxassetid://6895079853"
            sound.Volume = 0.7
            sound.Parent = notif
            sound:Play()
        end)
    end
    
    notif:TweenPosition(UDim2.new(1, -400, 0, 20), "Out", "Quad", 0.5, true)
    task.spawn(function()
        task.wait(6)
        notif:TweenPosition(UDim2.new(1, 0, 0, 20), "In", "Quad", 0.5, true)
        task.wait(0.5)
        notif:Destroy()
    end)
end

-- ESCANEO
local function scanServer()
    print("🔍 Escaneando:", game.JobId)
    local found = {}
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BillboardGui") then
            local hasSecret = false
            local genText = nil
            local nameText = nil
            
            for _, child in pairs(obj:GetDescendants()) do
                if child:IsA("TextLabel") then
                    local text = child.Text
                    if text:upper():find("SECRET") then
                        hasSecret = true
                    end
                    if text:match("%$[%d%.]+[KMB]/s") then
                        genText = text
                    end
                    if not text:find("%$") and not text:find("SECRET") and not text:find("/s") and #text > 2 and #text < 30 then
                        nameText = text
                    end
                end
            end
            
            if hasSecret and genText then
                local num = tonumber(genText:match("([%d%.]+)"))
                local gen = 0
                if num then
                    if genText:find("B/s") then
                        gen = num * 1000000000
                    elseif genText:find("M/s") then
                        gen = num * 1000000
                    elseif genText:find("K/s") then
                        gen = num * 1000
                    end
                end
                
                if gen >= MIN_GENERATION then
                    local brainrotData = {
                        name = nameText or "Pet",
                        generation = gen,
                        genText = genText,
                        serverId = game.JobId,
                        players = #Players:GetPlayers() .. "/" .. Players.MaxPlayers
                    }
                    table.insert(found, brainrotData)
                    print("✅ Encontrado:", nameText, "-", genText)
                    
                    -- Enviar a Discord
                    if webhookEnabled then
                        task.spawn(function()
                            local sent = sendToDiscord(brainrotData)
                            if sent then
                                print("📨 Enviado a Discord:", nameText)
                            end
                        end)
                    end
                end
            end
        end
    end
    
    if sortEnabled and #found > 0 then
        table.sort(found, function(a, b) return a.generation > b.generation end)
    end
    
    return found
end

-- ACTUALIZAR LISTA
local function updateResultsList()
    for _, child in pairs(resultsList:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    if #goodBrainrots == 0 then
        statusText.Text = string.format("❌ No se encontraron Brainrots\n📊 Servidores: %d\n💬 Discord: Esperando...", serversChecked)
        return
    end
    
    if sortEnabled then
        table.sort(goodBrainrots, function(a, b) return a.generation > b.generation end)
    end
    
    for i, brainrot in ipairs(goodBrainrots) do
        if i > 3 then break end -- Mostrar solo 3
        
        local entry = Instance.new("Frame")
        entry.Size = UDim2.new(1, -10, 0, 25)
        entry.Position = UDim2.new(0, 5, 0, (i - 1) * 30)
        entry.BackgroundColor3 = Color3.fromRGB(40, 50, 70)
        entry.BorderSizePixel = 0
        entry.Parent = resultsList
        addCorner(entry, 6)
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -10, 1, 0)
        label.Position = UDim2.new(0, 5, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = "💎 " .. brainrot.name .. " - " .. formatNumber(brainrot.generation) .. "/s"
        label.Font = Enum.Font.GothamBold
        label.TextSize = 11
        label.TextColor3 = Color3.fromRGB(100, 255, 100)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = entry
    end
    
    resultsList.CanvasSize = UDim2.new(0, 0, 0, math.min(#goodBrainrots, 3) * 30 + 5)
    statusText.Text = string.format("✅ %d Brainrots encontrados!\n📊 Servidores: %d\n💬 Discord: %d enviados", #goodBrainrots, serversChecked, #goodBrainrots)
end

-- EXPLORACIÓN
local function startAutoExplore()
    if isExploring then return end
    isExploring = true
    _G.HopperExploring = true
    exploreBtn.Visible = false
    stopBtn.Visible = true
    serversChecked = 0
    
    statusText.Text = "🔍 Escaneando servidor actual..."
    local current = scanServer()
    serversChecked = serversChecked + 1
    
    for _, br in ipairs(current) do
        table.insert(goodBrainrots, br)
    end
    
    if #current > 0 then
        updateResultsList()
        showNotification(string.format("🎉 %d Brainrot(s)!\n💬 Enviado a Discord", #current), Color3.fromRGB(50, 200, 100))
    end
    
    task.wait(2)
    statusText.Text = "🌐 Obteniendo servidores..."
    
    local ok, res = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. PLACE_ID .. "/servers/Public?sortOrder=Desc&limit=100"))
    end)
    
    if not ok or not res or not res.data then
        statusText.Text = "❌ Error HTTP"
        isExploring = false
        _G.HopperExploring = false
        exploreBtn.Visible = true
        stopBtn.Visible = false
        return
    end
    
    local servers = {}
    for _, srv in pairs(res.data) do
        if srv.id ~= game.JobId and srv.playing < srv.maxPlayers then
            table.insert(servers, srv)
        end
    end
    
    if #servers > 0 and isExploring then
        local random = servers[math.random(1, math.min(#servers, 10))]
        statusText.Text = "🚀 Teleportando..."
        task.wait(1)
        pcall(function()
            TeleportService:TeleportToPlaceInstance(PLACE_ID, random.id, player)
        end)
    end
end

-- POST-TELEPORT
if _G.HopperExploring then
    task.wait(SCAN_TIME)
    local res = scanServer()
    serversChecked = serversChecked + 1
    
    if #res > 0 then
        for _, br in ipairs(res) do
            table.insert(goodBrainrots, br)
        end
        updateResultsList()
        showNotification(string.format("🎉 %d Brainrot(s)!\n💬 Enviado a Discord", #res), Color3.fromRGB(50, 200, 100))
    end
    
    if isExploring then
        task.wait(2)
        startAutoExplore()
    end
end

-- BOTONES
webhookInput.FocusLost:Connect(function()
    DISCORD_WEBHOOK = webhookInput.Text
    print("Webhook actualizado")
end)

webhookToggle.MouseButton1Click:Connect(function()
    webhookEnabled = not webhookEnabled
    webhookToggle.Text = webhookEnabled and "✅ ACTIVADO" or "❌ DESACTIVADO"
    webhookToggle.BackgroundColor3 = webhookEnabled and Color3.fromRGB(50, 200, 100) or Color3.fromRGB(220, 50, 50)
    print("Webhook:", webhookEnabled and "activado" or "desactivado")
end)

webhookTest.MouseButton1Click:Connect(function()
    webhookTest.Text = "⏳ ENVIANDO..."
    webhookTest.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    
    local testData = {
        name = "Test Brainrot",
        generation = 24000000,
        serverId = game.JobId,
        players = #Players:GetPlayers() .. "/" .. Players.MaxPlayers
    }
    
    task.spawn(function()
        local sent = sendToDiscord(testData)
        task.wait(1)
        if sent then
            webhookTest.Text = "✅ ENVIADO"
            webhookTest.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
            showNotification("✅ Mensaje de prueba enviado a Discord!\nRevisa tu servidor", Color3.fromRGB(50, 200, 100))
        else
            webhookTest.Text = "❌ ERROR"
            webhookTest.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
            showNotification("❌ Error al enviar\nVerifica tu webhook URL", Color3.fromRGB(220, 50, 50))
        end
        task.wait(2)
        webhookTest.Text = "🧪 PROBAR"
        webhookTest.BackgroundColor3 = Color3.fromRGB(100, 150, 250)
    end)
end)

scanBtn.MouseButton1Click:Connect(function()
    scanBtn.Text = "⏳ ESCANEANDO..."
    scanBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    
    local res = scanServer()
    goodBrainrots = {}
    for _, br in ipairs(res) do
        table.insert(goodBrainrots, br)
    end
    updateResultsList()
    
    if #res > 0 then
        showNotification(string.format("✅ %d Brainrot(s)\n💬 Enviado a Discord", #res), Color3.fromRGB(50, 200, 100))
    else
        showNotification("🔍 No se encontraron Brainrots de 10M/s+", Color3.fromRGB(255, 150, 50))
    end
    
    scanBtn.Text = "🔍 ESCANEAR SERVIDOR ACTUAL"
    scanBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 250)
end)

exploreBtn.MouseButton1Click:Connect(function()
    if DISCORD_WEBHOOK == "https://discord.com/api/webhooks/TU_WEBHOOK_AQUI" then
        showNotification("⚠️ Configura tu Webhook primero!\n\nPega tu URL en el campo de arriba", Color3.fromRGB(255, 150, 50))
        return
    end
    startAutoExplore()
end)

stopBtn.MouseButton1Click:Connect(function()
    isExploring = false
    _G.HopperExploring = false
    stopBtn.Visible = false
    exploreBtn.Visible = true
    statusText.Text = string.format("⏹ Detenido\n📊 Servidores: %d\n💬 Discord: %d enviados", serversChecked, #goodBrainrots)
end)

sortToggle.MouseButton1Click:Connect(function()
    sortEnabled = not sortEnabled
    sortToggle.Text = sortEnabled and "ON" or "OFF"
    sortToggle.BackgroundColor3 = sortEnabled and Color3.fromRGB(50, 200, 100) or Color3.fromRGB(220, 50, 50)
    updateResultsList()
end)

notifToggle.MouseButton1Click:Connect(function()
    notifEnabled = not notifEnabled
    notifToggle.Text = notifEnabled and "ON" or "OFF"
    notifToggle.BackgroundColor3 = notifEnabled and Color3.fromRGB(50, 200, 100) or Color3.fromRGB(220, 50, 50)
end)

minimizeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    floatingCircle.Visible = true
end)

circleBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = true
    floatingCircle.Visible = false
end)

closeBtn.MouseButton1Click:Connect(function()
    isExploring = false
    _G.HopperExploring = false
    screenGui:Destroy()
end)

print("✅ Hopper PRO + Discord Webhook cargado!")
print("📝 INSTRUCCIONES:")
print("  1. Ve a tu servidor de Discord")
print("  2. Server Settings > Integrations > Webhooks")
print("  3. Click 'New Webhook'")
print("  4. Copia la 'Webhook URL'")
print("  5. Pégala en el campo del script")
print("  6. Click '🧪 PROBAR' para verificar")
print("  7. Inicia la exploración automática")
print("  8. Recibirás notificaciones en Discord cuando encuentre Brainrots!")
print("  9. Click en 'Clique aqui para entrar' en Discord para unirte")
