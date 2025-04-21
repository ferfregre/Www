--[[
   Roblox GUI меню с возможностью перетаскивания, изменения размера, сворачивания, вкладками,
   обводкой вокруг персонажей, функцией мега-прыжка, слежения за игроком, самоубийства,
   телепортации на спавн, убийства выбранного игрока и изменения Skybox.
]]

-- Сервисы
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Константы
local MENU_WIDTH = 300
local MENU_HEIGHT = 250
local COLLAPSED_HEIGHT = 30
local DEFAULT_JUMP_POWER = 50
local MEGA_JUMP_HEIGHT = 100

-- Переменные
local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()[1]
local humanoid = character:WaitForChild("Humanoid")
local playerGui = localPlayer:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MyMenu"
screenGui.Parent = playerGui

-- Функция для безопасного изменения значения свойства
local function setValue(object, property, value)
    pcall(function()
        object[property] = value
    end)
end

-- Функция для безопасного вызова метода
local function safeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        warn("Error calling function: ", result)
    end
    return success, result
end

-- MENU FRAME
local frame = Instance.new("Frame")
frame.Name = "MenuFrame"
frame.Size = UDim2.new(0, MENU_WIDTH, 0, MENU_HEIGHT)
frame.Position = UDim2.new(0.5, -MENU_WIDTH / 2, 0.5, -MENU_HEIGHT / 2)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.BackgroundColor3 = Color3.new(0.8, 0.8, 0.8)
frame.BorderSizePixel = 0
frame.Parent = screenGui
frame.Draggable = true

-- Сворачивание
local isCollapsed = false
local originalSize = frame.Size

local collapseButton = Instance.new("TextButton")
collapseButton.Name = "CollapseButton"
collapseButton.Size = UDim2.new(0, 30, 0, 20)
collapseButton.Position = UDim2.new(0, 5, 0, 5)
collapseButton.AnchorPoint = Vector2.new(0, 0)
collapseButton.BackgroundColor3 = Color3.new(0.7, 0.7, 0.7)
collapseButton.TextColor3 = Color3.new(0, 0, 0)
collapseButton.Text = "-"
collapseButton.Font = Enum.Font.SourceSansBold
collapseButton.TextScaled = true
collapseButton.Parent = frame

collapseButton.MouseButton1Click:Connect(function()
    isCollapsed = not isCollapsed
    if isCollapsed then
        originalSize = frame.Size
        setValue(frame, "Size", UDim2.new(0, MENU_WIDTH, 0, COLLAPSED_HEIGHT))
        setValue(collapseButton, "Text", "+")
    else
        setValue(frame, "Size", originalSize)
        setValue(collapseButton, "Text", "-")
    end
end)

-- Заголовок
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -30, 0, 30)
titleLabel.Position = UDim2.new(0, 30, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.new(0, 0, 0)
titleLabel.Text = "Меню"
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextScaled = true
titleLabel.Parent = frame

-- Resize handle
local resizeHandle = Instance.new("Frame")
resizeHandle.Name = "ResizeHandle"
resizeHandle.Size = UDim2.new(0, 15, 0, 15)
resizeHandle.Position = UDim2.new(1, -15, 1, -15)
resizeHandle.AnchorPoint = Vector2.new(1, 1)
resizeHandle.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)
resizeHandle.BorderSizePixel = 0
resizeHandle.Parent = frame

local isResizing = false
local initialMousePos = nil
local initialFrameSize = nil

resizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isResizing = true
        initialMousePos = input.Position
        initialFrameSize = Vector2.new(frame.Size.X.Offset, frame.Size.Y.Offset)
    end
end)

resizeHandle.InputEnded:Connect(function()
    isResizing = false
    initialMousePos = nil
    initialFrameSize = nil
end)

RunService.RenderStepped:Connect(function()
    if isResizing then
        local mouse = localPlayer:GetMouse()
        local delta = mouse.X - initialMousePos.X
        local deltaY = mouse.Y - initialMousePos.Y
        local newSizeX = math.max(100, initialFrameSize.X + delta)
        local newSizeY = math.max(75, initialFrameSize.Y + deltaY)

        frame.Size = UDim2.new(0, newSizeX, 0, newSizeY)
        originalSize = frame.Size
    end
end)

-- Создаем TextButton (кнопка закрытия)
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 80, 0, 25)
closeButton.Position = UDim2.new(0.5, -40, 0.9, 0)
closeButton.AnchorPoint = Vector2.new(0.5, 0)
closeButton.BackgroundColor3 = Color3.new(0.7, 0.7, 0.7)
closeButton.TextColor3 = Color3.new(0, 0, 0)
closeButton.Text = "Закрыть"
closeButton.Font = Enum.Font.SourceSans
closeButton.TextScaled = true
closeButton.Parent = frame

closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Создание вкладок
local tabs = {
    ["Combat"] = {},
    ["Movement"] = {},
    ["Other"] = {}
}

local currentTab = "Combat"

local function createTabButton(tabName)
    local button = Instance.new("TextButton")
    button.Name = tabName .. "TabButton"
    button.Size = UDim2.new(0, 80, 0, 25)
    button.Position = UDim2.new(0, 5 + ((#tabs - 1) * 85), 0, 35)
    button.AnchorPoint = Vector2.new(0, 0)
    button.BackgroundColor3 = Color3.new(0.7, 0.7, 0.7)
    button.TextColor3 = Color3.new(0, 0, 0)
    button.Text = tabName
    button.Font = Enum.Font.SourceSans
    button.TextScaled = true
    button.Parent = frame

    button.MouseButton1Click:Connect(function()
        currentTab = tabName
        for tabName, tabData in pairs(tabs) do
            tabData.contents.Visible = (tabName == currentTab)
        end
    end)
end

local function createTabContents(tabName)
    local contents = Instance.new("Frame")
    contents.Name = tabName .. "TabContents"
    contents.Size = UDim2.new(1, -10, 0.7, -40)
    contents.Position = UDim2.new(0, 5, 0, 70)
    contents.AnchorPoint = Vector2.new(0, 0)
    contents.BackgroundColor3 = Color3.new(0.9, 0.9, 0.9)
    contents.BorderSizePixel = 0
    contents.Visible = (tabName == currentTab)
    contents.Parent = frame

    return contents
end

for tabName, _ in pairs(tabs) do
    createTabButton(tabName)
    tabs[tabName].contents = createTabContents(tabName)
end

-- Hitbox logic
local hitboxesEnabled = false
local characterOutlines = {}

local function createOutline(part)
    local outline = Instance.new("Highlight")
    setValue(outline, "Parent", part)
    setValue(outline, "FillColor", Color3.new(1, 0, 0))
    setValue(outline, "OutlineColor", Color3.new(1, 0, 0))
    setValue(outline, "FillTransparency", 0.5)
    setValue(outline, "OutlineTransparency", 0)
    return outline
end

local function toggleHitboxes()
    hitboxesEnabled = not hitboxesEnabled

    for _, character in ipairs(workspace:GetChildren()) do
        if character:IsA("Model") and character:FindFirstChild("Humanoid") and character ~= localPlayer.Character then
            if hitboxesEnabled then
                if not characterOutlines[character] then
                    characterOutlines[character] = createOutline(character)
                end
            elseif characterOutlines[character] then
                characterOutlines[character]:Destroy()
                characterOutlines[character] = nil
            end
        end
    end
end

-- UI Button for hitbox toggle
local hitboxToggle = Instance.new("TextButton")
hitboxToggle.Name = "HitboxToggle"
hitboxToggle.Size = UDim2.new(0, 120, 0, 25)
hitboxToggle.Position = UDim2.new(0.5, -60, 0.3, 0)
hitboxToggle.AnchorPoint = Vector2.new(0.5, 0.5)
hitboxToggle.BackgroundColor3 = Color3.new(0.7, 0.7, 0.7)
hitboxToggle.TextColor3 = Color3.new(0, 0, 0)
hitboxToggle.Text = "Включить Обводку"
hitboxToggle.Font = Enum.Font.SourceSans
hitboxToggle.TextScaled = true
hitboxToggle.Parent = tabs["Combat"].contents

hitboxToggle.MouseButton1Click:Connect(function()
    toggleHitboxes()
    if hitboxesEnabled then
        setValue(hitboxToggle, "Text", "Выключить Обводку")
    else
        setValue(hitboxToggle, "Text", "Включить Обводку")
    end
end)

-- Mega Jump
local megaJumpEnabled = false
local megaJumpToggle = Instance.new("TextButton")
megaJumpToggle.Name = "MegaJumpToggle"
megaJumpToggle.Size = UDim2.new(0, 120, 0, 25)
megaJumpToggle.Position = UDim2.new(0.5, 60, 0.3, 0)
megaJumpToggle.AnchorPoint = Vector2.new(0.5, 0.5)
megaJumpToggle.BackgroundColor3 = Color3.new(0.7, 0.7, 0.7)
megaJumpToggle.TextColor3 = Color3.new(0, 0, 0)
megaJumpToggle.Text = "Включить Мега Прыжок"
megaJumpToggle.Font = Enum.Font.SourceSans
megaJumpToggle.TextScaled = true
megaJumpToggle.Parent = tabs["Movement"].contents

local function toggleMegaJump()
    megaJumpEnabled = not megaJumpEnabled
    if megaJumpEnabled then
        setValue(megaJumpToggle, "Text", "Выключить Мега Прыжок")
        setValue(humanoid, "JumpPower", MEGA_JUMP_HEIGHT)
    else
        setValue(megaJumpToggle, "Text", "Включить Мега Прыжок")
        setValue(humanoid, "JumpPower", DEFAULT_JUMP_POWER)
    end
end

megaJumpToggle.MouseButton1Click:Connect(toggleMegaJump)

-- Keybind function (Mega Jump)
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
 if not gameProcessedEvent then
        if input.KeyCode == Enum.KeyCode.Space and megaJumpEnabled then
            safeCall(humanoid.ChangeState, humanoid, Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- Follow player
local followPlayerToggle = Instance.new("TextButton")
followPlayerToggle.Name = "FollowPlayerToggle"
followPlayerToggle.Size = UDim2.new(0, 120, 0, 25)
followPlayerToggle.Position = UDim2.new(0.5, -60, 0.3, 0)
followPlayerToggle.AnchorPoint = Vector2.new(0.5, 0.5)
followPlayerToggle.BackgroundColor3 = Color3.new(0.7, 0.7, 0.7)
followPlayerToggle.TextColor3 = Color3.new(0, 0, 0)
followPlayerToggle.Text = "Следить"
followPlayerToggle.Font = Enum.Font.SourceSans
followPlayerToggle.TextScaled = true
followPlayerToggle.Parent = tabs["Movement"].contents

local followingPlayer = nil
local followLoop = nil

local function startFollowingPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        warn("Invalid target player or character")
        followingPlayer = nil
        return
    end

    followLoop = RunService.RenderStepped:Connect(function()
        if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            stopFollowingPlayer()
            return
        end

        local targetPos = targetPlayer.Character.HumanoidRootPart.Position
        safeCall(character:SetPrimaryPartCFrame, character, CFrame.new(targetPos + Vector3.new(0, 5, 0)))
    end)
end

local function stopFollowingPlayer()
    if followLoop then
        followLoop:Disconnect()
        followLoop = nil
        followingPlayer = nil
    end
end

local function showPlayerList()
    local playerListFrame = Instance.new("Frame")
    playerListFrame.Name = "PlayerListFrame"
    playerListFrame.Size = UDim2.new(0, 150, 0, 200)
    playerListFrame.Position = UDim2.new(0.5, -75, 0.5, -100)
    playerListFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    playerListFrame.BackgroundColor3 = Color3.new(0.9, 0.9, 0.9)
    playerListFrame.BorderSizePixel = 1
    playerListFrame.Parent = screenGui
    playerListFrame.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 20, 0, 20)
    closeButton.Position = UDim2.new(1, -25, 0, 5)
    closeButton.AnchorPoint = Vector2.new(0, 0)
    closeButton.Text = "X"
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.TextScaled = true
    closeButton.Parent = playerListFrame

    closeButton.MouseButton1Click:Connect(function()
        playerListFrame:Destroy()
    end)

    -- Scroll Frame
    local scrollingFrame = Instance.new("ScrollingFrame")
    scrollingFrame.Size = UDim2.new(1, -10, 1, -30)
    scrollingFrame.Position = UDim2.new(0, 5, 0, 30)
    scrollingFrame.AnchorPoint = Vector2.new(0, 0)
    scrollingFrame.BackgroundTransparency = 1
    scrollingFrame.BorderSizePixel = 0
    scrollingFrame.ScrollBarThickness = 5
    scrollingFrame.Parent = playerListFrame

    -- Populate the list
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= localPlayer then
            local playerButton = Instance.new("TextButton")
            playerButton.Size = UDim2.new(1, 0, 0, 25)
            playerButton.Text = plr.Name
            playerButton.BackgroundColor3 = Color3.new(0.8, 0.8, 0.8)
            playerButton.TextColor3 = Color3.new(0, 0, 0)
            playerButton.Font = Enum.Font.SourceSans
            playerButton.TextScaled = true
            playerButton.Parent = scrollingFrame

            playerButton.MouseButton1Click:Connect(function()
                stopFollowingPlayer()
                followingPlayer = plr
                startFollowingPlayer(plr)
                playerListFrame:Destroy()
                setValue(followPlayerToggle, "Text", "Остановить слежение")
            end)
        end
    end
end

followPlayerToggle.MouseButton1Click:Connect(function()
    if followingPlayer then
        stopFollowingPlayer()
        setValue(followPlayerToggle, "Text", "Следить")
    else
        showPlayerList()
    end
end)

-- Kill self
local killSelfButton = Instance.new("TextButton")
killSelfButton.Name = "KillSelfButton"
killSelfButton.Size = UDim2.new(0, 120, 0, 25)
killSelfButton.Position = UDim2.new(0.5, -60, 0.6, 0)
killSelfButton.AnchorPoint = Vector2.new(0.5, 0.5)
killSelfButton.BackgroundColor3 = Color3.new(0.7, 0.7, 0.7)
killSelfButton.TextColor3 \
        setValue(collapseButton, "Text", "+")
    else
        setValue(frame, "Size", originalSize)
        setValue(collapseButton, "Text", "-")
    end
end)

-- Заголовок
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -30, 0, 30)
titleLabel.Position = UDim2.new(0, 30, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.new(0, 0, 0)
titleLabel.Text = "Меню"
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextScaled = true
titleLabel.Parent = frame

-- Resize handle
local resizeHandle = Instance.new("Frame")
resizeHandle.Name = "ResizeHandle"
resizeHandle.Size = UDim2.new(0, 15, 0, 15)
resizeHandle.Position = UDim2.new(1, -15, 1, -15)
resizeHandle.AnchorPoint = Vector2.new(1, 1)
resizeHandle.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)
resizeHandle.BorderSizePixel = 0
resizeHandle.Parent = frame

local isResizing = false
local initialMousePos = nil
local initialFrameSize = nil

resizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isResizing = true
        initialMousePos = input.Position
        initialFrameSize = Vector2.new(frame.Size.X.Offset, frame.Size.Y.Offset)
    end
end)

resizeHandle.InputEnded:Connect(function()
    isResizing = false
    initialMousePos = nil
    initialFrameSize = nil
end)

RunService.RenderStepped:Connect(function()
    if isResizing then
        local mouse = localPlayer:GetMouse()
        local delta = mouse.X - initialMousePos.X
        local deltaY = mouse.Y - initialMousePos.Y
        local newSizeX = math.max(100, initialFrameSize.X + delta)
        local newSizeY = math.max(75, initialFrameSize.Y + deltaY)

        frame.Size = UDim2.new(0, newSizeX, 0, newSizeY)
        originalSize = frame.Size
    end
end)

-- Создаем TextButton (кнопка закрытия)
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 80, 0, 25)
closeButton.Position = UDim2.new(0.5, -40, 0.9, 0)
closeButton.AnchorPoint = Vector2.new(0.5, 0)
closeButton.BackgroundColor3 = Color3.new(0.7, 0.7, 0.7)
closeButton.TextColor3 = Color3.new(0, 0, 0)
closeButton.Text = "Закрыть"
closeButton.Font = Enum.Font.SourceSans
closeButton.TextScaled = true
closeButton.Parent = frame

closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Создание вкладок
local tabs = {
    ["Combat"] = {},
    ["Movement"] = {},
    ["Other"] = {}
}

local currentTab = "Combat"

local function createTabButton(tabName)
    local button = Instance.new("TextButton")
    button.Name = tabName .. "TabButton"
    button.Size = UDim2.new(0, 80, 0, 25)
    button.Position = UDim2.new(0, 5 + ((#tabs - 1) * 85), 0, 35)
    button.AnchorPoint = Vector2.new(0, 0)
    button.BackgroundColor3 = Color3.new(0.7, 0.7, 0.7)
    button.TextColor3 = Color3.new(0, 0, 0)
    button.Text = tabName
    button.Font = Enum.Font.SourceSans
    button.TextScaled = true
    button.Parent = frame

    button.MouseButton1Click:Connect(function()
        currentTab = tabName
        for tabName, tabData in pairs(tabs) do
            tabData.contents.Visible = (tabName == currentTab)
        end
    end)
end

local function createTabContents(tabName)
    local contents = Instance.new("Frame")
    contents.Name = tabName .. "TabContents"
    contents.Size = UDim2.new(1, -10, 0.7, -40)
    contents.Position = UDim2.new(0, 5, 0, 70)
    contents.AnchorPoint = Vector2.new(0, 0)
    contents.BackgroundColor3 = Color3.new(0.9, 0.9, 0.9)
    contents.BorderSizePixel = 0
    contents.Visible = (tabName == currentTab)
    contents.Parent = frame

    re
turn contents
end

for tabName, _ in pairs(tabs) do
    createTabButton(tabName)
    tabs[tabName].contents = createTabContents(tabName)
end

-- Hitbox logic
local hitboxesEnabled = false
local characterOutlines = {}

local function createOutline(part)
    local outline = Instance.new("Highlight")
    setValue(outline, "Parent", part)
    setValue(outline, "FillColor", Color3.new(1, 0, 0))
    setValue(outline, "OutlineColor", Color3.new(1, 0, 0))
    setValue(outline, "FillTransparency", 0.5)
    setValue(outline, "OutlineTransparency", 0)
    return outline
end

local function toggleHitboxes()
    hitboxesEnabled = not hitboxesEnabled

    for _, character in ipairs(workspace:GetChildren()) do
        if character:IsA("Model") and character:FindFirstChild("Humanoid") and character ~= localPlayer.Character then
            if hitboxesEnabled then
                if not characterOutlines[character] then
                    characterOutlines[character] = createOutline(character)
                end
            elseif characterOutlines[character] then
                characterOutlines[character]:Destroy()
                characterOutlines[character] = nil
            end
        end
    end
end

-- UI Button for hitbox toggle
local hitboxToggle = Instance.new("TextButton")
hitboxToggle.Name = "HitboxToggle"
hitboxToggle.Size = UDim2.new(0, 120, 0, 25)
hitboxToggle.Position = UDim2.new(0.5, -60, 0.3, 0)
hitboxToggle.AnchorPoint = Vector2.new(0.5, 0.5)
hitboxToggle.BackgroundColor3 = Color3.new(0.7, 0.7, 0.7)
hitboxToggle.TextColor3 = Color3.new(0, 0, 0)
hitboxToggle.Text = "Включить Обводку"
hitboxToggle.Font = Enum.Font.SourceSans
hitboxToggle.TextScaled = true
hitboxToggle.Parent = tabs["Combat"].contents

hitboxToggle.MouseButton1Click:Connect(function()
    toggleHitboxes()
    if hitboxesEnabled then
        setValue(hitboxToggle, "Text", "Выключить Обводку")
    else
        setValue(hitboxToggle, "Text", "Включить Обводку")
    end
end)

-- Mega Jump
local megaJumpEnabled = false
local megaJumpToggle = Instance.new("TextButton")
megaJumpToggle.Name = "MegaJumpToggle"
megaJumpToggle.Size = UDim2.new(0, 120, 0, 25)
megaJumpToggle.Position = UDim2.new(0.5, 60, 0.3, 0)
megaJumpToggle.AnchorPoint = Vector2.new(0.5, 0.5)
megaJumpToggle.BackgroundColor3 = Color3.new(0.7, 0.7, 0.7)
megaJumpToggle.TextColor3 = Color3.new(0, 0, 0)
megaJumpToggle.Text = "Включить Мега Прыжок"
megaJumpToggle.Font = Enum.Font.SourceSans
megaJumpToggle.TextScaled = true
megaJumpToggle.Parent = tabs["Movement"].contents

local function toggleMegaJump()
    megaJumpEnabled = not megaJumpEnabled
    if megaJumpEnabled then
        setValue(megaJumpToggle, "Text", "Выключить Мега Прыжок")
        setValue(humanoid, "JumpPower", MEGA_JUMP_HEIGHT)
    else
        setValue(megaJumpToggle, "Text", "Включить Мега Прыжок")
        setValue(humanoid, "JumpPower", DEFAULT_JUMP_POWER)
    end
end

megaJumpToggle.MouseButton1Click:Connect(toggleMegaJump)

-- Keybind function (Mega Jump)
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
 if not gameProcessedEvent then
        if input.KeyCode == Enum.KeyCode.Space and megaJumpEnabled then
            safeCall(humanoid.ChangeState, humanoid, Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- Follow player
local followPlayerToggle = Instance.new("TextButton")
followPlayerToggle.Name = "FollowPlayerToggle"
followPlayerToggle.Size = UDim2.new(0, 120, 0, 25)
followPlayerToggle.Position = UDim2.new(0.5, -60, 0.3, 0)
followPlayerToggle.AnchorPoint = Vector2.new(0.5, 0.5)
followPlayerToggle.BackgroundColor3 = Color3.new(0.7, 0.7, 0.7)
followPlayerToggle.TextColor3 = Color3.new(0, 0, 0)
followPlayerToggle.Text = "Следить"
followPlayerToggle.Font = Enum.Font.SourceSans
followPlayerToggle.TextScaled = true
followPlayerToggle.Parent = tabs["Movement"].contents

local followingPlayer = nil
local followLoop = nil

local function startFollowingPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        warn("Invalid target player or character")
        followingPlayer = nil
        return
    end

    followLoop = RunService.RenderStepped:Connect(function()
        if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            stopFollowingPlayer()
            return
        end

        local targetPos = targetPlayer.Character.HumanoidRootPart.Position
        safeCall(character:SetPrimaryPartCFrame, character, CFrame.new(targetPos + Vector3.new(0, 5, 0)))
    end)
end

local function stopFollowingPlayer()
    if followLoop then
        followLoop:Disconnect()
        followLoop = nil
        followingPlayer = nil
    end
end

local function showPlayerList()
    local playerListFrame = Instance.new("Frame")
    playerListFrame.Name = "PlayerListFrame"
    playerListFrame.Size = UDim2.new(0, 150, 0, 200)
    playerListFrame.Position = UDim2.new(0.5, -75, 0.5, -100)
    playerListFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    playerListFrame.BackgroundColor3 = Color3.new(0.9, 0.9, 0.9)
    playerListFrame.BorderSizePixel = 1
    playerListFrame.Parent = screenGui
    playerListFrame.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 20, 0, 20)
    closeButton.Position = UDim2.new(1, -25, 0, 5)
    closeButton.AnchorPoint = Vector2.new(0, 0)
    closeButton.Text = "X"
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.TextScaled = true
    closeButton.Parent = playerListFrame

    closeButton.MouseButton1Click:Connect(function()
        playerListFrame:Destroy()
    end)

    -- Scroll Frame
    local scrollingFrame = Instance.new("ScrollingFrame")
    scrollingFrame.Size = UDim2.new(1, -10, 1, -30)
    scrollingFrame.Position = UDim2.new(0, 5, 0, 30)
    scrollingFrame.AnchorPoint = Vector2.new(0, 0)
    scrollingFrame.BackgroundTransparency = 1
    scrollingFrame.BorderSizePixel = 0
    scrollingFrame.ScrollBarThickness = 5
    scrollingFrame.Parent = playerListFrame

    -- Populate the list
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= localPlayer then
            local playerButton = Instance.new("TextButton")
            playerButton.Size = UDim2.new(1, 0, 0, 25)
            playerButton.Text = plr.Name
            playerButton.BackgroundColor3 = Color3.new(0.8, 0.8, 0.8)
            playerButton.TextColor3 = Color3.new(0, 0, 0)
            playerButton.Font = Enum.Font.SourceSans
            playerButton.TextScaled = true
            playerButton.Parent = scrollingFrame

            playerButton.MouseButton1Click:Connect(function()
                stopFollowingPlayer()
                followingPlayer = plr
                startFollowingPlayer(plr)
                playerListFrame:Destroy()
                setValue(followPlayerToggle, "Text", "Остановить слежение")
            end)
        end
    end
end

followPlayerToggle.MouseButton1Click:Connect(function()
    if followingPlayer then
        stopFollowingPlayer()
        setValue(followPlayerToggle, "Text", "Следить")
    else
        showPlayerList()
    end
end)

-- Kill self
local killSelfButton = Instance.new("TextButton")
killSelfButton.Name = "KillSelfButton"
killSelfButton.Size = UDim2.new(0, 120, 0, 25)
killSelfButton.Position = UDim2.new(0.5, -60, 0.6, 0)
killSelfButton.AnchorPoint = Vector2.new(0.5, 0.5)
killSelfButton.BackgroundColor3 = Color3.new(0.7, 0.7, 0.7)
killSelfButton.TextColor3 = Color3.new(0, 0, 0)
killSelfButton.Text = "Убить себя"
killSelfButton.Font = Enum.Font.SourceSans
killSelfButton.TextScaled = true
killSelfButton.Parent = tabs["Other"].contents

killSelfButton.MouseButton1Click:Connect(function()
    safeCall(humanoid.TakeDamage, humanoid, humanoid.Health)
end)

-- Teleport to Spawn
local teleportToSpawnButton = Instance.new("TextButton")
teleportToSpawnButton.Name = "TeleportToSpawnButton"
teleportToSpawnButton.Size = UDim2.new(0, 120, 0, 25)
teleportToSpawnButton.Position = UDim2.new(0.5, 60, 0.6, 0)
teleportToSpawnButton.AnchorPoint = Vector2.new(0.5, 0.5)
teleportToSpawnButton.BackgroundColor3 = Color3.new(0.7, 0.7, 0.7)
teleportToSpawnButton.TextColor3 = Color3.new(0, 0, 0)
teleportToSpawnButton.Text = "Телепорт на спавн"
teleportToSpawnButton.Font = Enum.Font.SourceSans
teleportToSpawnButton.TextScaled = true
teleportToSpawnButton.Parent = tabs["Other"].contents

teleportToSpawnButton.MouseButton1Click:Connect(function()
    if localPlayer and localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
        safeCall(localPlayer.Character:MoveTo,localPlayer.Character, game.Workspace.SpawnLocation.Position)
    end
end)

-- Kill Selected Player
local killSelectedPlayerButton = Instance.new("TextButton")
killSelectedPlayerButton.Name = "KillSelectedPlayerButton"
killSelectedPlayerButton.Size = UDim2.new(0, 120, 0, 25)
killSelectedPlayerButton.Position = UDim2.new(0.5, 0, 0.3, 0)
killSelectedPlayerButton.AnchorPoint = Vector2.new(0.5, 0.5)
killSelectedPlayerButton.BackgroundColor3 = Color3.new(0.7, 0.7, 0.7)
killSelectedPlayerButton.TextColor3 = Color3.new(0, 0, 0)
killSelectedPlayerButton.Text = "Убить игрока"
killSelectedPlayerButton.Font = Enum.Font.SourceSans
killSelectedPlayerButton.TextScaled = true
killSelectedPlayerButton.Parent = tabs["Combat"].contents

local targetPlayer = nil
local playerListFrame = nil

killSelectedPlayerButton.MouseButton1Click:Connect(function()
    if targetPlayer then
        if targetPlayer.Character then
            local targetHumanoid = targetPlayer.Character:FindFirstChild("Humanoid")
            if targetHumanoid then
                safeCall(targetHumanoid.TakeDamage, targetHumanoid, targetHumanoid.Health)
            end
        end
    else
        warn("No player selected to kill!")
    end
end)

function showPlayerListForKilling()
    playerListFrame = Instance.new("Frame")
    playerListFrame.Name = "PlayerListFrame"
    playerListFrame.Size = UDim2.new(0, 150, 0, 200)
    playerListFrame.Position = UDim2.new(0.5, -75, 0.5, -100)
    playerListFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    playerListFrame.BackgroundColor3 = Color3.new(0.9, 0.9, 0.9)
    playerListFrame.BorderSizePixel = 1
    playerListFrame.Parent = screenGui
    playerListFrame.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 20, 0, 20)
    closeButton.Position = UDim2.new(1, -25, 0, 5)
    closeButton.AnchorPoint = Vector2.new(0, 0)
    closeButton.Text = "X"
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.TextScaled = true
    closeButton.Parent = playerListFrame

    closeButton.MouseButton1Click:Connect(function()
        playerListFrame:Destroy()
    end)

    -- Scroll Frame
    local scrollingFrame = Instance.new("ScrollingFrame")
    scrollingFrame.Size = UDim2.new(1, -10, 1, -30)
    scrollingFrame.Position = UDim2.new(0, 5, 0, 30)
    scrollingFrame.AnchorPoint = Vector2.new(0, 0)
    scrollingFrame.BackgroundTransparency = 1
    scrollingFrame.BorderSizePixel = 0
    scrollingFrame.ScrollBarThickness = 5
    scrollingFrame.Parent = playerListFrame

    -- Populate the list
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= localPlayer then
            local playerButton = Instance.new("TextButton")
            playerButton.Size = UDim2.new(1, 0, 0, 25)
            playerButton.Text = plr.Name
            playerButton.BackgroundColor3 = Color3.new(0.8, 0.8, 0.8)
            playerButton.TextColor3 = Color3.new(0, 0, 0)
            playerButton.Font = Enum.Font.SourceSans
            playerButton.TextScaled = true
            playerButton.Parent = scrollingFrame

            playerButton.MouseButton1Click:Connect(function()
                targetPlayer = plr
                killSelectedPlayerButton.Text = "Убить "..plr.Name
                playerListFrame:Destroy()
            end)
        end
    end
end

killSelectedPlayerButton.MouseButton1Click:Connect(function()
  showPlayerListForKilling()
end)

-- Skybox Change
local skyboxChangeButton = Instance.new("TextButton")
skyboxChangeButton.Name = "SkyboxChangeButton"
skyboxChangeButton.Size = UDim2.new(0, 120, 0, 25)
skyboxChangeButton.Position = UDim2.new(0.5, 0, 0.6, 0)
skyboxChangeButton.AnchorPoint = Vector2.new(0.5, 0.5)
skyboxChangeButton.BackgroundColor3 = Color3.new(0.7, 0.7, 0.7)
skyboxChangeButton.TextColor3 = Color3.new(0, 0, 0)
skyboxChangeButton.Text = "Сменить Skybox"
skyboxChangeButton.Font = Enum.Font.SourceSans
skyboxChangeButton.TextScaled = true
skyboxChangeButton.Parent = tabs["Other"].contents

local skyboxImageIds = { -- Random Skybox Images
    "rbxassetid://11377490418",
    "rbxassetid://11377487420",
    "rbxassetid://11377485675",
    "rbxassetid://11377489193"
}

skyboxChangeButton.MouseButton1Click:Connect(function()
    local skybox = game.Lighting:FindFirstChildOfClass("Sky")
    if not skybox then
        skybox = Instance.new("Sky")
        skybox.Parent = game.Lighting
    end

    local randomImageId = skyboxImageIds[math.random(1, #skyboxImageIds)]

    setValue(skybox, "SkyboxFront", randomImageId)
    setValue(skybox, "SkyboxBack", randomImageId)
    setValue(skybox, "SkyboxLeft", randomImageId)
    setValue(skybox, "SkyboxRight", randomImageId)
    setValue(skybox, "SkyboxTop", randomImageId)
    setValue(skybox, "SkyboxBottom", randomImageId)
end)

-- Initial setup
local function onCharacterAdded(character)
    if character == localPlayer.Character then return end

    if hitboxesEnabled then
        characterOutlines[character] = createOutline(character)
    end
end

--Listen for Player Removing
Players.PlayerRemoving:Connect(function(player)
    if player.Character then
        if characterOutlines[player.Character] then
            characterOutlines[player.Character]:Destroy()
            characterOutlines[player.Character] = nil
        end
    end
end)

-- Event Handlers
workspace.ChildAdded:Connect(function(object)
    if object:IsA("Model") and object:FindFirstChild("Humanoid") then
        onCharacterAdded(object)
    end
end)

-- Initial Scan
for _, character in ipairs(workspace:GetChildren()) do
    if character:IsA("Model") and character:FindFirstChild("Humanoid") then
        onCharacterAdded(character)
    end
end

print("Меню Roblox GUI создано!")