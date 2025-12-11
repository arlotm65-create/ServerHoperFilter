-- Hopper PRO - Versión Final Corregida
print("🚀 HOPPER PRO - Versión Final")

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- WEBHOOK HARDCODEADO
local DISCORD_WEBHOOK = "https://discord.com/api/webhooks/1448334967502536718/-xERrcgHR51GwldLAOywL32vvff7nKA69DmIiW-4MuR4shBsZ0AHwyMFNnbYK85-2sD6"

-- CONFIGURACIÓN
local PLACE_ID = game.PlaceId
local MIN_GENERATION = 10000000 -- 10M
local SCAN_TIME = 5
local isExploring = false
local goodBrainrots = {}
local serversChecked = 0
local webhookEnabled = true

print("Place ID:", PLACE_ID)
print("Webhook configurado ✅")

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

-- ENVIAR A DISCORD
local function sendToDiscord(brainrotData)
    if not webhookEnabled then return false end
    
    local embed = {
        title = "🎯 Sk Notify | Notify 10m+ plus",
        color = 15158332,
        fields = {
            {name = "**Brainrot:**", value = brainrotData.name, inline = false},
            {name = "**Money per sec:**", value = formatNumber(brainrotData.generation), inline = false},
            {name = "**JobId Mobile:**", value = brainrotData.serverId, inline = false},
            {name = "**JobId PC:**", value = brainrotData.serverId, inline = false},
            {name = "**Join Script PC:**", value = "```lua\ngame:GetService(\"TeleportService\"):TeleportToPlaceInstance(" .. PLACE_ID .. ", \"" .. brainrotData.serverId .. "\", game.Players.LocalPlayer)\n```", inline = false}
        },
        footer = {text = "Sk Notify | by Hopper PRO | " .. os.date("%H:%M")}
    }
    
    local data = {username = "Sk Notify", embeds = {embed}}
    
    local success = pcall(function()
        local jsonData = HttpService:JSONEncode(data)
        if request then
            request({Url = DISCORD_WEBHOOK, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = jsonData})
        elseif syn and syn.request then
            syn.request({Url = DISCORD_WEBHOOK, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = jsonData})
        elseif http_request then
            http_request({Url = DISCORD_WEBHOOK, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = jsonData})
        end
    end)
    
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
mainFrame.Size = UDim2.new(0, 480, 0, 520)
mainFrame.Position = UDim2.new(0.5, -240, 0.5, -260)
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
title.Text = "🤖 HOPPER PRO - Final"
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

local statusPanel = Instance.new("Frame")
statusPanel.Size = UDim2.new(1, -30, 0, 100)
statusPanel.Position = UDim2.new(0, 15, 0, 65)
statusPanel.BackgroundColor3 = Color3.fromRGB(30, 40, 55)
statusPanel.BorderSizePixel = 0
statusPanel.Parent = mainFrame
addCorner(statusPanel, 8)

local statusText = Instance.new("TextLabel")
statusText.Size = UDim2.new(1, -20, 1, -20)
statusText.Position = UDim2.new(0, 10, 0, 10)
statusText.BackgroundTransparency = 1
statusText.Text = "✅ GUI Cargado\n🎯 Busca: Brainrots de 10M/s+\n📊 Servidores: 0 | 💬 Webhook: ✅"
statusText.Font = Enum.Font.Gotham
statusText.TextSize = 13
statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
statusText.TextWrapped = true
statusText.TextYAlignment = Enum.TextYAlignment.Top
statusText.Parent = statusPanel

local webhookToggle = Instance.new("TextButton")
webhookToggle.Size = UDim2.new(1, -30, 0, 40)
webhookToggle.Position = UDim2.new(0, 15, 0, 180)
webhookToggle.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
webhookToggle.Text = "✅ WEBHOOK ACTIVADO"
webhookToggle.Font = Enum.Font.GothamBold
webhookToggle.TextSize = 14
webhookToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
webhookToggle.Parent = mainFrame
addCorner(webhookToggle, 8)

local scanBtn = Instance.new("TextButton")
scanBtn.Size = UDim2.new(1, -30, 0, 50)
scanBtn.Position = UDim2.new(0, 15, 0, 235)
scanBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 250)
scanBtn.Text = "🔍 ESCANEAR SERVIDOR ACTUAL"
scanBtn.Font = Enum.Font.GothamBold
scanBtn.TextSize = 15
scanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
scanBtn.Parent = mainFrame
addCorner(scanBtn, 8)

local hopBtn = Instance.new("TextButton")
hopBtn.Size = UDim2.new(1, -30, 0, 50)
hopBtn.Position = UDim2.new(0, 15, 0, 300)
hopBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 50)
hopBtn.Text = "🔄 SALTAR A OTRO SERVIDOR"
hopBtn.Font = Enum.Font.GothamBold
hopBtn.TextSize = 15
hopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
hopBtn.Parent = mainFrame
addCorner(hopBtn, 8)

local autoBtn = Instance.new("TextButton")
autoBtn.Size = UDim2.new(1, -30, 0, 50)
autoBtn.Position = UDim2.new(0, 15, 0, 365)
autoBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
autoBtn.Text = "🤖 MODO AUTO"
autoBtn.Font = Enum.Font.GothamBold
autoBtn.TextSize = 15
autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
autoBtn.Parent = mainFrame
addCorner(autoBtn, 8)

local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(1, -30, 0, 50)
stopBtn.Position = UDim2.new(0, 15, 0, 365)
stopBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
stopBtn.Text = "⏹ DETENER"
stopBtn.Font = Enum.Font.GothamBold
stopBtn.TextSize = 15
stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
stopBtn.Visible = false
stopBtn.Parent = mainFrame
addCorner(stopBtn, 8)

local resultsList = Instance.new("ScrollingFrame")
resultsList.Size = UDim2.new(1, -30, 0, 90)
resultsList.Position = UDim2.new(0, 15, 0, 430)
resultsList.BackgroundColor3 = Color3.fromRGB(30, 40, 55)
resultsList.BorderSizePixel = 0
resultsList.ScrollBarThickness = 6
resultsList.ScrollBarImageColor3 = Color3.fromRGB(50, 150, 250)
resultsList.CanvasSize = UDim2.new(0, 0, 0, 0)
resultsList.Parent = mainFrame
addCorner(resultsList, 8)

-- Notificación
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
    
    notif:TweenPosition(UDim2.new(1, -400, 0, 20), "Out", "Quad", 0.5, true)
    task.spawn(function()
        task.wait(5)
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
                    if text:upper():find("SECRET") then hasSecret = true end
                    if text:match("%$[%d%.]+[KMB]/s") then genText = text end
                    if not text:find("%$") and not text:find("SECRET") and not text:find("/s") and #text > 2 and #text < 30 then
                        nameText = text
                    end
                end
            end
            
            if hasSecret and genText then
                local num = tonumber(genText:match("([%d%.]+)"))
                local gen = 0
                if num then
                    if genText:find("B/s") then gen = num * 1000000000
                    elseif genText:find("M/s") then gen = num * 1000000
                    elseif genText:find("K/s") then gen = num * 1000 end
                end
                
                if gen >= MIN_GENERATION then
                    local brainrotData = {
                        name = nameText or "Pet",
                        generation = gen,
                        serverId = game.JobId,
                        players = #Players:GetPlayers() .. "/" .. Players.MaxPlayers
                    }
                    table.insert(found, brainrotData)
                    print("✅ Encontrado:", nameText, "-", formatNumber(gen) .. "/s")
                    
                    if webhookEnabled then
                        task.spawn(function() sendToDiscord(brainrotData) end)
                    end
                end
            end
        end
    end
    
    return found
end

-- Actualizar lista
local function updateResultsList()
    for _, child in pairs(resultsList:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    if #goodBrainrots == 0 then
        statusText.Text = string.format("❌ Sin Brainrots\n📊 Servidores: %d\n💬 Webhook: ✅", serversChecked)
        return
    end
    
    for i, br in ipairs(goodBrainrots) do
        if i > 3 then break end
        
        local entry = Instance.new("Frame")
        entry.Size = UDim2.new(1, -10, 0, 25)
        entry.Position = UDim2.new(0, 5, 0, (i - 1) * 28)
        entry.BackgroundColor3 = Color3.fromRGB(40, 50, 70)
        entry.BorderSizePixel = 0
        entry.Parent = resultsList
        addCorner(entry, 6)
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -10, 1, 0)
        label.Position = UDim2.new(0, 5, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = "💎 " .. br.name .. " - " .. formatNumber(br.generation) .. "/s"
        label.Font = Enum.Font.GothamBold
        label.TextSize = 11
        label.TextColor3 = Color3.fromRGB(100, 255, 100)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = entry
    end
    
    resultsList.CanvasSize = UDim2.new(0, 0, 0, math.min(#goodBrainrots, 3) * 28 + 5)
    statusText.Text = string.format("✅ %d Brainrots!\n📊 Servidores: %d\n💬 Webhook: %d enviados", #goodBrainrots, serversChecked, #goodBrainrots)
end

-- SERVER HOP mejorado
local function serverHop()
    print("🔄 Saltando a servidor aleatorio...")
    statusText.Text = "🔄 Saltando...\n⏳ Espera..."
    
    task.spawn(function()
        TeleportService:Teleport(PLACE_ID, player)
    end)
end

-- MODO AUTO
local function startAutoMode()
    isExploring = true
    _G.HopperAuto = true
    autoBtn.Visible = false
    stopBtn.Visible = true
    
    print("🤖 Modo auto activado")
    statusText.Text = "🔍 Escaneando..."
    
    local found = scanServer()
    serversChecked = serversChecked + 1
    
    for _, br in ipairs(found) do
        table.insert(goodBrainrots, br)
    end
    
    if #found > 0 then
        updateResultsList()
        showNotification(string.format("🎉 %d Brainrot(s)!\n💬 Enviado", #found), Color3.fromRGB(50, 200, 100))
    end
    
    task.wait(3)
    
    if isExploring then
        statusText.Text = "🔄 Saltando a otro servidor..."
        task.wait(1)
        serverHop()
    end
end

-- Al cargar
if _G.HopperAuto then
    task.wait(SCAN_TIME)
    print("🔍 Nuevo servidor, escaneando")
    
    local found = scanServer()
    serversChecked = serversChecked + 1
    
    if #found > 0 then
        for _, br in ipairs(found) do
            table.insert(goodBrainrots, br)
        end
        updateResultsList()
        showNotification(string.format("🎉 %d Brainrot(s)!\n💬 Enviado", #found), Color3.fromRGB(50, 200, 100))
    end
    
    if isExploring then
        task.wait(2)
        startAutoMode()
    end
end

-- BOTONES
webhookToggle.MouseButton1Click:Connect(function()
    webhookEnabled = not webhookEnabled
    webhookToggle.Text = webhookEnabled and "✅ WEBHOOK ACTIVADO" or "❌ WEBHOOK DESACTIVADO"
    webhookToggle.BackgroundColor3 = webhookEnabled and Color3.fromRGB(50, 200, 100) or Color3.fromRGB(220, 50, 50)
end)

scanBtn.MouseButton1Click:Connect(function()
    scanBtn.Text = "⏳..."
    scanBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    
    local found = scanServer()
    goodBrainrots = {}
    for _, br in ipairs(found) do table.insert(goodBrainrots, br) end
    updateResultsList()
    
    if #found > 0 then
        showNotification(string.format("✅ %d Brainrot(s)\n💬 Enviado", #found), Color3.fromRGB(50, 200, 100))
    else
        showNotification("🔍 No hay Brainrots de 10M/s+", Color3.fromRGB(255, 150, 50))
    end
    
    scanBtn.Text = "🔍 ESCANEAR SERVIDOR ACTUAL"
    scanBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 250)
end)

hopBtn.MouseButton1Click:Connect(function()
    serverHop()
end)

autoBtn.MouseButton1Click:Connect(function()
    startAutoMode()
end)

stopBtn.MouseButton1Click:Connect(function()
    isExploring = false
    _G.HopperAuto = false
    stopBtn.Visible = false
    autoBtn.Visible = true
    statusText.Text = string.format("⏹ Detenido\n📊 Servidores: %d", serversChecked)
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
    _G.HopperAuto = false
    screenGui:Destroy()
end)

print("✅ Hopper PRO Final cargado!")
print("💬 Webhook configurado automáticamente")
print("🎮 Usa MODO AUTO para explorar automáticamente")
