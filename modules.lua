local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Teams = game:GetService("Teams")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local Settings = _G.Settings or {
    AntiJump = true,
    AutoSprint = false,
    Underground = false,
    UndergroundDepth = 8,
    UndergroundSpeed = 20,
    QuickRespawn = false,
    ESP = false,
    TeamColors = true,
    Highlight = true,
    HighlightColor = Color3.fromRGB(255, 70, 70),
    HighlightTransparency = 0.5,
    FireRateMultiplier = 1.0,
    Fullbright = false,
    TargetTeam = false,
    RapidFire = false,
    FireRate = 0.05,
    Hitbox = false,
    HitboxSize = 6,
    DefaultSpeed = 16,
    SprintSpeed = 24,
    JumpPower = 50,
    Gravity = 196.2,
}
_G.Settings = Settings

--========================================================--
-- STATE
--========================================================--

local UndergroundConnection = nil
local UndergroundSavedCFrame = nil

local CharacterConnection = nil
local DeathConnection = nil
local CharacterTrackConnection = nil

local LastAliveCFrame = nil
local LastDeathCFrame = nil

local ESPObjects = {}
local HitboxObjects = {}

local OriginalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    GlobalShadows = Lighting.GlobalShadows,
    ExposureCompensation = Lighting.ExposureCompensation,
}

--========================================================--
-- CHARACTER
--========================================================--

local function getCharacter()
    local Character = LocalPlayer.Character

    if not Character then
        return nil, nil, nil
    end

    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    local Root = Character:FindFirstChild("HumanoidRootPart")

    return Character, Humanoid, Root
end

--========================================================--
-- ESP
--========================================================--

local function removeESP(Player)

    local Object = ESPObjects[Player]

    if Object then

        if Object.Highlight then
            Object.Highlight:Destroy()
        end

        if Object.Billboard then
            Object.Billboard:Destroy()
        end

        ESPObjects[Player] = nil
    end
end

local function getPlayerColor(Player)

    if Settings.TeamColors
        and Player.Team
        and Player.Team.TeamColor then

        return Player.Team.TeamColor.Color
    end

    return Settings.HighlightColor
end

local function createESP(Player)

    if Player == LocalPlayer then
        return
    end

    removeESP(Player)

    local Character = Player.Character

    if not Character then
        return
    end

    local Root =
        Character:FindFirstChild("HumanoidRootPart")

    if not Root then
        return
    end

    local HighlightObject = nil

    if Settings.Highlight then

        HighlightObject =
            Instance.new("Highlight")

        HighlightObject.Name =
            "NightfallHighlight"

        HighlightObject.Adornee =
            Character

        HighlightObject.DepthMode =
            Enum.HighlightDepthMode.AlwaysOnTop

        HighlightObject.FillTransparency =
            Settings.HighlightTransparency

        HighlightObject.OutlineTransparency = 0

        HighlightObject.FillColor =
            getPlayerColor(Player)

        HighlightObject.OutlineColor =
            getPlayerColor(Player)

        HighlightObject.Parent =
            Character
    end

    local Billboard =
        Instance.new("BillboardGui")

    Billboard.Name =
        "NightfallESP"

    Billboard.Adornee =
        Root

    Billboard.Size =
        UDim2.fromOffset(220, 55)

    Billboard.StudsOffset =
        Vector3.new(0, 3.2, 0)

    Billboard.AlwaysOnTop = true

    Billboard.Active = true

    local Label =
        Instance.new("TextButton")

    Label.BackgroundTransparency = 1
    Label.Size = UDim2.fromScale(1, 1)

    Label.Font =
        Enum.Font.GothamSemibold

    Label.TextSize = 13
    Label.TextStrokeTransparency = 0.5

    Label.TextColor3 =
        getPlayerColor(Player)

    Label.Text = Player.DisplayName

    Label.AutoButtonColor = false
    Label.Active = true
    Label.Selectable = false

    Label.Parent = Billboard
    Label:SetAttribute("NF_Owner", Player.UserId)
    Billboard.Parent = Root

    ESPObjects[Player] = {
        Highlight = HighlightObject,
        Billboard = Billboard,
        Label = Label
    }
end

local function updateESP()

    for _, Player in ipairs(Players:GetPlayers()) do

        if Player ~= LocalPlayer then

            if Settings.ESP then

                if not ESPObjects[Player]
                    and Player.Character then

                    createESP(Player)
                end

                local Object =
                    ESPObjects[Player]

                if Object
                    and Object.Label then

                    local Character =
                        Player.Character

                    local Humanoid =
                        Character
                        and Character:FindFirstChildOfClass(
                            "Humanoid"
                        )

                    local Root =
                        Character
                        and Character:FindFirstChild(
                            "HumanoidRootPart"
                        )

                    local _, _, MyRoot =
                        getCharacter()

                    local DistanceText = ""

                    if Root and MyRoot then

                        local Distance =
                            math.floor(
                                (
                                    Root.Position
                                    - MyRoot.Position
                                ).Magnitude
                            )

                        DistanceText =
                            " [" .. Distance .. "m]"
                    end

                    local HealthText = ""

                    if Humanoid then

                        HealthText =
                            " | "
                            .. math.floor(
                                Humanoid.Health
                            )
                            .. " HP"
                    end

                    Object.Label.Text =
                        Player.DisplayName
                        .. DistanceText
                        .. HealthText

                    Object.Label.TextColor3 =
                        getPlayerColor(Player)
                end

            else
                removeESP(Player)
            end
        end
    end
end

--========================================================--
-- CLICK HOTKEY TP
--========================================================--

local ESP_CLICK_RADIUS = 60
local ESP_CLICK_COOLDOWN = 0.3
local _lastTeleportTime = 0

local TP_MODIFIER_KEY = Enum.KeyCode.Q

local _tpKeyHeld = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.Keyboard
       and input.KeyCode == TP_MODIFIER_KEY then
        _tpKeyHeld = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.Keyboard
       and input.KeyCode == TP_MODIFIER_KEY then
        _tpKeyHeld = false
    end
end)

local function teleportToRoot(targetRoot)
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot or not targetRoot then return end

    local targetLook = targetRoot.CFrame.LookVector
    local newPos = targetRoot.Position - targetLook * 3

    myRoot.CFrame = CFrame.new(newPos, targetRoot.Position)
    myRoot.AssemblyLinearVelocity = Vector3.zero
    myRoot.AssemblyAngularVelocity = Vector3.zero
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)

    if gameProcessed then return end

    if not _tpKeyHeld then return end

    local isClick = input.UserInputType == Enum.UserInputType.MouseButton1
                 or input.UserInputType == Enum.UserInputType.Touch
    if not isClick then return end

    if os.clock() - _lastTeleportTime < ESP_CLICK_COOLDOWN then return end

    local clickPos
    if input.UserInputType == Enum.UserInputType.Touch then
        clickPos = Vector2.new(input.Position.X, input.Position.Y)
    else
        clickPos = Vector2.new(
            UserInputService:GetMouseLocation().X,
            UserInputService:GetMouseLocation().Y
        )
    end

    local cam = workspace.CurrentCamera
    if not cam then return end

    local bestPlayer = nil
    local bestDist = ESP_CLICK_RADIUS

    for player, object in pairs(ESPObjects) do
        local billboard = object.Billboard
        if billboard and billboard.Adornee and billboard.Parent then

            local worldPos = billboard.Adornee.Position + billboard.StudsOffset
            local screenPos, onScreen = cam:WorldToViewportPoint(worldPos)

            if onScreen then
                local d = (Vector2.new(screenPos.X, screenPos.Y) - clickPos).Magnitude

                if d < bestDist then
                    bestDist = d
                    bestPlayer = player
                end
            end
        end
    end

    if not bestPlayer then return end

    local targetChar = bestPlayer.Character
    local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end

    _lastTeleportTime = os.clock()
    teleportToRoot(targetRoot)
end)

--========================================================--
-- CUSTOM WEAPON VISUAL
--========================================================--

local CustomWeapon = (function()
    local state = {
        Enabled = false,
        Saved   = {},
        Applied = {},
    }

    local CUSTOM_MESHES = {
        ["AK-47"]         = "rbxassetid://96327891060480",
        ["M4A1"]          = "rbxassetid://96327891060480",
        ["M9"]            = "rbxassetid://96327891060480",
        ["MP5"]           = "rbxassetid://96327891060480",
        ["Taser"]         = "rbxassetid://96327891060480",
        ["Remington 870"] = "rbxassetid://96327891060480",
        ["Revolver"]      = "rbxassetid://96327891060480",
    }

    local CUSTOM_TEXTURES = {
        ["AK-47"]         = "rbxassetid://128702198330575",
        ["M4A1"]          = "rbxassetid://128702198330575",
        ["M9"]            = "rbxassetid://128702198330575",
        ["MP5"]           = "rbxassetid://128702198330575",
        ["Taser"]         = "rbxassetid://128702198330575",
        ["Remington 870"] = "rbxassetid://128702198330575",
        ["Revolver"]      = "rbxassetid://128702198330575",
    }

    local function findOriginalVisuals(tool)
        local list = {}
        for _, d in ipairs(tool:GetDescendants()) do
            if d:IsA("MeshPart") and d.Name ~= "NF_CustomWeapon" then
                table.insert(list, d)
            end
        end
        return list
    end

    local function createCustomMeshPart(original, meshId, textureId)
        local custom = Instance.new("MeshPart")
        custom.Name         = "NF_CustomWeapon"
        custom.MeshId       = meshId
        custom.TextureID    = textureId or original.TextureID or ""
        custom.Size         = original.Size
        custom.Anchored     = false
        custom.CanCollide   = false
        custom.CanQuery     = false
        custom.CanTouch     = false
        custom.Massless     = true
        custom.Transparency = 0
        custom.CFrame       = original.CFrame
        custom.Parent       = original.Parent

        local weld = Instance.new("WeldConstraint")
        weld.Part0 = custom
        weld.Part1 = original
        weld.Parent = custom

        return custom
    end

    local function apply(tool)
        if not tool or not tool:IsA("Tool") then return end
        local meshId = CUSTOM_MESHES[tool.Name]
        if not meshId then return end

        if state.Applied[tool] then return end

        local originals = findOriginalVisuals(tool)
        if #originals == 0 then return end

        local textureId = CUSTOM_TEXTURES[tool.Name]
        state.Saved[tool] = {}

        for _, orig in ipairs(originals) do
            state.Saved[tool][orig] = orig.Transparency
            orig.Transparency = 1

            pcall(function()
                createCustomMeshPart(orig, meshId, textureId)
            end)
        end

        state.Applied[tool] = true
    end

    local function remove(tool)
        if not state.Applied[tool] then return end

        for _, d in ipairs(tool:GetDescendants()) do
            if d.Name == "NF_CustomWeapon" then
                pcall(function() d:Destroy() end)
            end
        end

        local saved = state.Saved[tool]
        if saved then
            for orig, val in pairs(saved) do
                if orig and orig.Parent then
                    pcall(function() orig.Transparency = val end)
                end
            end
        end

        state.Applied[tool] = nil
        state.Saved[tool]   = nil
    end

    local function hookTool(tool)
        if not tool:IsA("Tool") then return end

        tool.Equipped:Connect(function()
            if state.Enabled then apply(tool) end
        end)

        tool.Unequipped:Connect(function()
            remove(tool)
        end)

        if state.Enabled then apply(tool) end
    end

    local function hookCharacter(char)
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("Tool") then hookTool(child) end
        end

        char.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                task.wait(0.2)
                hookTool(child)
            end
        end)

        char.ChildRemoved:Connect(function(child)
            if child:IsA("Tool") then remove(child) end
        end)
    end

    local function enable()
        if state.Enabled then return end
        state.Enabled = true

        local char = LocalPlayer.Character
        if char then hookCharacter(char) end

        LocalPlayer.CharacterAdded:Connect(function(c)
            if state.Enabled then hookCharacter(c) end
        end)
    end

    local function disable()
        if not state.Enabled then return end
        state.Enabled = false

        for tool in pairs(state.Applied) do
            remove(tool)
        end
        state.Applied = {}
        state.Saved   = {}
    end

    return {
        Set = function(v) if v then enable() else disable() end return state.Enabled end,
        Get = function() return state.Enabled end,
        SetMeshes = function(tbl)
            table.clear(CUSTOM_MESHES)
            for k, v in pairs(tbl) do CUSTOM_MESHES[k] = v end
        end,
        SetTextures = function(tbl)
            table.clear(CUSTOM_TEXTURES)
            for k, v in pairs(tbl) do CUSTOM_TEXTURES[k] = v end
        end,
    }
end)()





--========================================================--
-- HITBOX
--========================================================--

local HitboxObjects = HitboxObjects or {}

local function removeHitbox(Player)
    local data = HitboxObjects[Player]
    if not data then return end

    local head = data.Head
    if head and head.Parent and data.OriginalSize then
        pcall(function()
            head.Size = data.OriginalSize
        end)
    end

    HitboxObjects[Player] = nil
end

local function isAlive(Player)
    local Character = Player.Character
    if not Character then return false end
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    return Humanoid ~= nil and Humanoid.Health > 0
end

local function createHitbox(Player)
    removeHitbox(Player)

    local Character = Player.Character
    if not Character then return end

    local Head = Character:FindFirstChild("Head")
    if not Head then
        task.spawn(function()
            Head = Character:WaitForChild("Head", 5)
            if not Head then return end
            if not Settings.Hitbox then return end
            if not isAlive(Player) then return end
            if HitboxObjects[Player] then return end

            local s = Settings.HitboxSize or 6
            local original = Head.Size

            pcall(function() Head.Size = Vector3.new(s, s, s) end)

            HitboxObjects[Player] = {
                Head = Head,
                OriginalSize = original,
                Player = Player,
            }
        end)
        return
    end

    local s = Settings.HitboxSize or 6
    local original = Head.Size

    pcall(function()
        Head.Size = Vector3.new(s, s, s)
    end)

    HitboxObjects[Player] = {
        Head = Head,
        OriginalSize = original,
        Player = Player,
    }
end

local _hbQueue = {}
local _hbRunning = false

local function processQueue()
    if _hbRunning then return end
    _hbRunning = true

    task.spawn(function()
        while #_hbQueue > 0 do
            local job = table.remove(_hbQueue, 1)
            if job
                and job.Player
                and job.Player.Parent
                and Settings.Hitbox
                and isAlive(job.Player) then
                createHitbox(job.Player)
            end
            task.wait(0.15)
        end
        _hbRunning = false
    end)
end

local function queueHitbox(Player)
    for _, job in ipairs(_hbQueue) do
        if job.Player == Player then return end
    end
    table.insert(_hbQueue, { Player = Player })
    processQueue()
end

local function updateHitboxes()
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            if Settings.Hitbox and isAlive(Player) then
                local data = HitboxObjects[Player]
                if not data
                    or not data.Head
                    or not data.Head.Parent
                    or data.Head ~= Player.Character:FindFirstChild("Head") then
                    queueHitbox(Player)
                end
            else
                removeHitbox(Player)
            end
        end
    end
end

local HitboxVisualObjects = HitboxVisualObjects or {}

local function removeHitboxVisual(Player)
    local part = HitboxVisualObjects[Player]
    if not part then return end
    if part.Parent then
        pcall(function() part:Destroy() end)
    end
    HitboxVisualObjects[Player] = nil
end

local function createHitboxVisual(Player)
    removeHitboxVisual(Player)

    local Character = Player.Character
    if not Character then return end

    local Head = Character:FindFirstChild("Head")
    if not Head then return end

    local s = Settings.HitboxSize or 6

    local Part = Instance.new("Part")
    Part.Name         = "NightfallHitboxVisual"
    Part.Size         = Vector3.new(s, s, s)
    Part.Transparency = 0.7
    Part.Material     = Enum.Material.ForceField
    Part.Color        = Settings.HitboxVisualColor or Color3.fromRGB(255, 0, 0)
    Part.CastShadow   = false
    Part.CanCollide   = false
    Part.CanTouch     = false
    Part.CanQuery     = false
    Part.Massless     = true
    Part.Anchored     = false
    Part.CFrame       = Head.CFrame
    Part.Parent       = Head

    local Weld = Instance.new("WeldConstraint")
    Weld.Part0 = Part
    Weld.Part1 = Head
    Weld.Parent = Part

    HitboxVisualObjects[Player] = Part
end

local function updateHitboxVisuals()
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            if Settings.Hitbox and Settings.HitboxVisual and isAlive(Player) then
                local part = HitboxVisualObjects[Player]
                local needRecreate = false

                if not part or not part.Parent then
                    needRecreate = true
                elseif part.Size.X ~= (Settings.HitboxSize or 6) then
                    needRecreate = true
                end

                if needRecreate then
                    createHitboxVisual(Player)
                end
            else
                removeHitboxVisual(Player)
            end
        end
    end
end

--========================================================--
-- DAMAGE VISUAL NUMBER's
--========================================================--

local DamageNumbers = (function()
    local state = {
        Enabled = false,
        Conn    = nil,
        LastHP  = {},
        Pool    = {},
    }

    local function spawnNumber(worldPosition, amount)
        local bb = Instance.new("BillboardGui")
        bb.Name             = "NF_DamageNumber"
        bb.Size             = UDim2.fromOffset(120, 50)
        bb.StudsOffset      = Vector3.new(0, 0, 0)
        bb.AlwaysOnTop      = true
        bb.LightInfluence   = 0
        bb.MaxDistance      = 300
        bb.Adornee          = nil
        bb.Parent           = Workspace.CurrentCamera
        bb.Enabled          = true

        local anchor = Instance.new("Part")
        anchor.Name           = "NF_DamageAnchor"
        anchor.Size           = Vector3.new(0.1, 0.1, 0.1)
        anchor.Transparency   = 1
        anchor.CanCollide     = false
        anchor.CanQuery       = false
        anchor.CanTouch       = false
        anchor.Anchored       = true
        anchor.Massless       = true
        anchor.CFrame         = CFrame.new(worldPosition)
        anchor.Parent         = Workspace.CurrentCamera

        bb.Adornee = anchor

        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Size                   = UDim2.fromScale(1, 1)
        label.Font                   = Enum.Font.GothamBold
        label.TextScaled             = true
        label.TextColor3             = Color3.fromRGB(255, 60, 60)
        label.TextStrokeTransparency = 0
        label.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
        label.Text                   = "-" .. tostring(amount)
        label.Parent                 = bb

        task.spawn(function()
            local startTime = os.clock()
            local duration  = 1.0
            local startPos  = worldPosition
            local riseY     = 4

            while os.clock() - startTime < duration do
                local t = (os.clock() - startTime) / duration

                if anchor and anchor.Parent then
                    anchor.CFrame = CFrame.new(
                        startPos + Vector3.new(0, riseY * t, 0)
                    )
                end

                if label then
                    label.TextTransparency = t
                    label.TextStrokeTransparency = t
                end

                task.wait(0.03)
            end

            if bb and bb.Parent then bb:Destroy() end
            if anchor and anchor.Parent then anchor:Destroy() end
        end)
    end

    local function hookPlayer(Player)
        local char = Player.Character
        if not char then return end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end

        state.LastHP[Player] = hum.Health

        local conn
        conn = hum.HealthChanged:Connect(function(newHealth)
            if not state.Enabled then return end

            local oldHealth = state.LastHP[Player] or newHealth
            state.LastHP[Player] = newHealth

            local delta = oldHealth - newHealth
            if delta > 0 then

                local head = char:FindFirstChild("Head")
                local root = char:FindFirstChild("HumanoidRootPart")
                local pos

                if head then
                    pos = head.Position + Vector3.new(0, 2, 0)
                elseif root then
                    pos = root.Position + Vector3.new(0, 2, 0)
                else
                    pos = Vector3.new(0, 0, 0)
                end

                spawnNumber(pos, math.floor(delta + 0.5))
            end
        end)

        state.Conn = state.Conn
    end


    local function setupPlayer(Player)
        if Player == LocalPlayer then return end

        if Player.Character then
            hookPlayer(Player)
        end

        Player.CharacterAdded:Connect(function()
            task.wait(0.3)
            if state.Enabled then
                hookPlayer(Player)
            end
        end)
    end

    local function enable()
        if state.Enabled then return end
        state.Enabled = true
        state.LastHP  = {}

        for _, Player in ipairs(Players:GetPlayers()) do
            setupPlayer(Player)
        end
    end

    local function disable()
        if not state.Enabled then return end
        state.Enabled = false
        state.LastHP  = {}

        for _, obj in ipairs(Workspace.CurrentCamera:GetChildren()) do
            if obj.Name == "NF_DamageNumber"
                or obj.Name == "NF_DamageAnchor" then
                obj:Destroy()
            end
        end
    end

    Players.PlayerAdded:Connect(function(Player)
        if state.Enabled then
            setupPlayer(Player)
        end
    end)

    return {
        Set = function(v)
            if v then enable() else disable() end
            return state.Enabled
        end,
        Get = function() return state.Enabled end,
    }
end)()

--========================================================--
-- FULLBRIGHT
--========================================================--

local FullbrightConn = nil

local function applyFullbright()
    Lighting.Brightness = 0.5
    Lighting.ClockTime = 7
    Lighting.FogStart = 500
    Lighting.FogEnd = 10000
    Lighting.Ambient = Color3.fromRGB(80, 80, 80)
    Lighting.OutdoorAmbient = Color3.fromRGB(90, 90, 90)
    Lighting.GlobalShadows = true
    Lighting.ExposureCompensation = 0
    
    for _, Object in ipairs(Lighting:GetChildren()) do
        if Object:IsA("Atmosphere") then
            pcall(function()
                Object.Density = 0
                Object.Haze = 0
                Object.Glare = 0
            end)
        end
    end
end

local function restoreLighting()

    Lighting.Brightness = OriginalLighting.Brightness
    Lighting.ClockTime = OriginalLighting.ClockTime
    Lighting.FogStart = OriginalLighting.FogStart
    Lighting.FogEnd = OriginalLighting.FogEnd
    Lighting.Ambient = OriginalLighting.Ambient
    Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
    Lighting.GlobalShadows = OriginalLighting.GlobalShadows
    Lighting.ExposureCompensation = OriginalLighting.ExposureCompensation
end

local function enableFullbright()
    if FullbrightConn then return end

    applyFullbright()

    FullbrightConn = RunService.Heartbeat:Connect(function()
        if Settings.Fullbright then
            applyFullbright()
        end
    end)
end

local function disableFullbright()
    if FullbrightConn then
        FullbrightConn:Disconnect()
        FullbrightConn = nil
    end
    restoreLighting()
end

local function updateFullbright()
    if Settings.Fullbright then
        enableFullbright()
    else
        disableFullbright()
    end
end

--========================================================--
-- Teleport Giver
--========================================================--

local function teleportToGiver(giverPath)
    local char = LocalPlayer.Character
    if not char then return end

    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("ForceField") then
            WindUI:Notify({ 
                Title = "World", 
                Content = "You can't teleport with a shield", 
                Duration = 3 
            })
            return
        end
    end

    local giver = nil
    pcall(function() giver = giverPath() end)
    if not giver or not giver:IsA("BasePart") then
        WindUI:Notify({ 
            Title = "World", 
            Content = "TouchGiver not found", 
            Duration = 3 
        })
        return
    end

    local savedCF = root.CFrame
    local giverCF = giver.CFrame

    local offset = Vector3.new(0, 3, 2)
    root.CFrame = giverCF + offset

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bv.Velocity = -offset.Unit * 50
    bv.Parent = root

    task.wait(0.2)

    bv:Destroy()

    root.CFrame = savedCF

    pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)

end

local function getFNFAL()
    local obj = workspace:GetChildren()[71]
    return obj and obj:FindFirstChild("TouchGiver")
end

local function getAK47()
    local obj = workspace:GetChildren()[207]
    return obj and obj:FindFirstChild("TouchGiver") and obj.TouchGiver:FindFirstChild("TouchGiver")
end

local function getShotgun()
    local obj = workspace:GetChildren()[182]
    return obj and obj:FindFirstChild("TouchGiver")
end

local function getMP5()
    local obj = workspace:GetChildren()[186]
    return obj and obj:FindFirstChild("TouchGiver")
end

local function getSniper()
    local obj = workspace:GetChildren()[236]
    return obj and obj:FindFirstChild("TouchGiver")
end

local function getM4A1()
    local obj = workspace:FindFirstChild("TouchGiver")
    return obj and obj:FindFirstChild("TouchGiver")
end

--========================================================--
-- Fixed RAPID FIRE 
--========================================================--

local function patchTool(tool)
    if not tool or not tool:IsA("Tool") then return end
    if tool:GetAttribute("ToolType") ~= "Gun" then return end
    if not Settings.RapidFire then return end

    local newRate = tonumber(Settings.FireRate) or 0.05
    if newRate < 0.01 then newRate = 0.01 end

    pcall(function()
        tool:SetAttribute("FireRate", nil)
    end)

    task.defer(function()
        pcall(function()
            tool:SetAttribute("FireRate", newRate)
        end)
    end)
end

local function hookTool(tool)
    if not tool:IsA("Tool") then return end

    if Settings.RapidFire then
        patchTool(tool)
    end

    tool.Equipped:Connect(function()
        if Settings.RapidFire then
            patchTool(tool)

            task.delay(0.1, function()
                if Settings.RapidFire then
                    patchTool(tool)
                end
            end)
        end
    end)
end

local function hookCharacter(char)
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") then
            hookTool(child)
        end
    end

    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            task.wait(0.2)
            hookTool(child)
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.2)
    hookCharacter(char)
end)

if LocalPlayer.Character then
    hookCharacter(LocalPlayer.Character)
end

local function refreshAllTools()
    if not LocalPlayer.Character then return end
    for _, child in ipairs(LocalPlayer.Character:GetChildren()) do
        if child:IsA("Tool") then
            patchTool(child)
        end
    end
end

--========================================================--
-- AUTO CRIMINAL
--========================================================--

local AutoCriminal = (function()
    local state = {
        Enabled   = false,
        Conn      = nil,
        LastCF    = nil,
        Teleporting = false,
    }

    local CRIMINAL_COLOR = Color3.fromRGB(218, 133, 65)
    local POLICE_COLOR   = Color3.fromRGB(13, 105, 172)

    local CRIMINAL_SPAWN_CFRAME = CFrame.new(
        -948.203491, 99.2255402, 2094.7876,
        0, 0, -1,
        0, 1, 0,
        1, 0, 0
    )

    local function getIndicatorColor()
        local ti = workspace:FindFirstChild("TeamIndicators")
        if not ti then return nil end

        local lp = ti:FindFirstChild("LocalPlayer")
        if lp then
            local frame = lp:FindFirstChild("Frame")
            if frame and frame:IsA("GuiObject") then
                return frame.BackgroundColor3
            end
        end

        local byName = ti:FindFirstChild(LocalPlayer.Name)
        if byName then
            local frame = byName:FindFirstChild("Frame")
            if frame and frame:IsA("GuiObject") then
                return frame.BackgroundColor3
            end
        end

        for _, v in ipairs(ti:GetChildren()) do
            if v:IsA("Folder") or v:IsA("Model") then
                if v.Name == LocalPlayer.Name then
                    local frame = v:FindFirstChild("Frame")
                    if frame and frame:IsA("GuiObject") then
                        return frame.BackgroundColor3
                    end
                end
            end
        end

        return nil
    end

    local function colorMatches(c, target, tolerance)
        tolerance = tolerance or 0.02
        return math.abs(c.R - target.R) < tolerance
           and math.abs(c.G - target.G) < tolerance
           and math.abs(c.B - target.B) < tolerance
    end

    local function teleportToSpawn()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        state.LastCF = root.CFrame

        root.CFrame = CRIMINAL_SPAWN_CFRAME
        root.AssemblyLinearVelocity  = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero

        task.delay(0.4, function()
            local char2 = LocalPlayer.Character
            local root2 = char2 and char2:FindFirstChild("HumanoidRootPart")
            if root2 and state.LastCF then
                root2.CFrame = state.LastCF
                root2.AssemblyLinearVelocity  = Vector3.zero
                root2.AssemblyAngularVelocity = Vector3.zero
            end
            state.Teleporting = false
        end)
    end

    local function tick()
        if not state.Enabled then return end
        if state.Teleporting then return end

        local color = getIndicatorColor()
        if not color then return end

        if colorMatches(color, POLICE_COLOR) then
            return
        end

        if colorMatches(color, CRIMINAL_COLOR) then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then return end

            local dist = (root.Position - CRIMINAL_SPAWN_CFRAME.Position).Magnitude
            if dist < 5 then return end

            state.Teleporting = true
            teleportToSpawn()
        end
    end

    local function enable()
        if state.Enabled then return end
        state.Enabled = true

        if state.Conn then state.Conn:Disconnect() end
        state.Conn = task.spawn(function()
            while state.Enabled do
                pcall(tick)
                task.wait(0.42)
            end
        end)
    end

    local function disable()
        state.Enabled = false
        if state.Conn then
            task.cancel(state.Conn)
            state.Conn = nil
        end
        state.Teleporting = false
    end

    return {
        Set = function(v) if v then enable() else disable() end return state.Enabled end,
        Get = function() return state.Enabled end,
    }
end)()

--========================================================--
-- ANTI-FLING + BLOCK CAR SEATS OPTIMIZED
--========================================================--

local AntiFling = (function()
    local state = {
        Enabled   = false,
        MaxSpeed  = 50,
        Conn1     = nil,
        Conn2     = nil,
        Conn3     = nil,
        CarParts  = {},
        PlayerParts = {},
    }

    local function registerCar(model)
        if not model:IsA("Model") then return end
        for _, v in ipairs(model:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
                state.CarParts[v] = true
            end
        end
    end

    local function registerPlayer(player)
        if not player.Character then return end
        for _, v in ipairs(player.Character:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
                state.PlayerParts[v] = true
            end
        end
    end

    local function clampVelocity()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local v = root.AssemblyLinearVelocity
        if v.Magnitude > state.MaxSpeed then
            root.AssemblyLinearVelocity  = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
    end

    local function enable()
        if state.Enabled then return end
        state.Enabled = true
        state.CarParts = {}
        state.PlayerParts = {}

        local carContainer = workspace:FindFirstChild("CarContainer")
        if carContainer then
            for _, v in ipairs(carContainer:GetChildren()) do
                registerCar(v)
            end
        end

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                registerPlayer(player)
            end
        end

        state.Conn1 = RunService.Heartbeat:Connect(clampVelocity)

        state.Conn3 = workspace.DescendantAdded:Connect(function(obj)
            if not state.Enabled then return end
            local parent = obj:FindFirstAncestorOfClass("Model")
            if parent and (parent.Name:lower():find("car") or parent:FindFirstAncestor("CarContainer")) then
                if obj:IsA("BasePart") then
                    obj.CanCollide = false
                    state.CarParts[obj] = true
                end
            end
        end)

        state.Conn2 = Players.PlayerAdded:Connect(function(player)
            if not state.Enabled then return end
            player.CharacterAdded:Connect(function()
                task.wait(0.5)
                if state.Enabled then registerPlayer(player) end
            end)
        end)

        task.spawn(function()
            while state.Enabled do
                task.wait(2)
                for part in pairs(state.CarParts) do
                    if not part.Parent then state.CarParts[part] = nil end
                end
                for part in pairs(state.PlayerParts) do
                    if not part.Parent then state.PlayerParts[part] = nil end
                end
            end
        end)
    end

    local function disable()
        if not state.Enabled then return end
        state.Enabled = false

        if state.Conn1 then state.Conn1:Disconnect(); state.Conn1 = nil end
        if state.Conn2 then state.Conn2:Disconnect(); state.Conn2 = nil end
        if state.Conn3 then state.Conn3:Disconnect(); state.Conn3 = nil end

        for part in pairs(state.CarParts) do
            if part and part.Parent then part.CanCollide = true end
        end
        for part in pairs(state.PlayerParts) do
            if part and part.Parent then part.CanCollide = true end
        end

        state.CarParts = {}
        state.PlayerParts = {}
    end

    return {
        Set = function(v) if v then enable() else disable() end return state.Enabled end,
        Get = function() return state.Enabled end,
    }
end)()

--========================================================--
-- UNDERGROUND
--========================================================--

local function startUnderground()
    if UndergroundConnection then
        UndergroundConnection:Disconnect()
        UndergroundConnection = nil
    end
    UndergroundSavedCFrame = nil

    local Character, Humanoid, Root = getCharacter()
    if not Root or not Humanoid then return end

    UndergroundSavedCFrame = Root.CFrame

    UndergroundConnection = RunService.RenderStepped:Connect(function()
        if not Settings.Underground then return end

        local Character2, Humanoid2, Root2 = getCharacter()
        if not Root2 or not Humanoid2 then return end
        if not UndergroundSavedCFrame then return end

        local Current = Root2.CFrame
        local Rotation = Current - Current.Position
        local NewY = UndergroundSavedCFrame.Position.Y - Settings.UndergroundDepth

        Root2.CFrame = CFrame.new(
            Current.Position.X,
            NewY,
            Current.Position.Z
        ) * Rotation

        Root2.AssemblyLinearVelocity = Vector3.new(
            Root2.AssemblyLinearVelocity.X,
            0,
            Root2.AssemblyLinearVelocity.Z
        )
        Root2.AssemblyAngularVelocity = Vector3.zero
    end)
end

local function stopUnderground()
    if UndergroundConnection then
        UndergroundConnection:Disconnect()
        UndergroundConnection = nil
    end

    local _, Humanoid, Root = getCharacter()

    if Root then
        local CurrentPos = Root.Position
        local NewY = CurrentPos.Y + Settings.UndergroundDepth + 4

        Root.CFrame = CFrame.new(
            CurrentPos.X,
            NewY,
            CurrentPos.Z
        ) * (Root.CFrame - Root.CFrame.Position)

        Root.AssemblyLinearVelocity = Vector3.zero
        Root.AssemblyAngularVelocity = Vector3.zero
    end

    if Humanoid then
        Humanoid.WalkSpeed = Settings.DefaultSpeed
    end

    UndergroundSavedCFrame = nil
end

local function setUnderground(State)
    Settings.Underground = State

    if State then
        startUnderground()
    else
        stopUnderground()
    end
end

LocalPlayer.CharacterAdded:Connect(function(Character)
    local Humanoid = Character:WaitForChild("Humanoid", 10)
    local Root = Character:WaitForChild("HumanoidRootPart", 10)
    if not Humanoid or not Root then return end

    task.wait(0.5)

    Humanoid.WalkSpeed = Settings.DefaultSpeed

    if Settings.Underground then
        if UndergroundConnection then
            UndergroundConnection:Disconnect()
            UndergroundConnection = nil
        end
        UndergroundSavedCFrame = nil
        startUnderground()
    else
        if UndergroundConnection then
            UndergroundConnection:Disconnect()
            UndergroundConnection = nil
        end
        UndergroundSavedCFrame = nil
    end
end)

--========================================================--
-- TASE BYPASS
--========================================================--

local TaseBypass = (function()
    local TASE_ANIMS = {
        ["rbxassetid://279227693"] = true,
        ["rbxassetid://279229192"] = true,
    }

    local DEFAULT_SPEED = 16
    local DEFAULT_JUMP  = 7.2

    local Enabled = false

    local humanoid  = nil
    local lastSpeed = DEFAULT_SPEED
    local lastJump  = DEFAULT_JUMP

    local eventConns    = {}
    local humanoidConns = {}
    local charAddedConn = nil

    local PlayerTased = nil
    do
        local GunRemotes = ReplicatedStorage:FindFirstChild("GunRemotes")
        if GunRemotes then
            PlayerTased = GunRemotes:FindFirstChild("PlayerTased")
        end
    end

    local function clearTable(t)
        for _, c in ipairs(t) do
            if c and type(c.Disconnect) == "function" then
                pcall(function() c:Disconnect() end)
            end
        end
        table.clear(t)
    end

    local function enableBackpack()
        if LocalPlayer:GetAttribute("BackpackEnabled") ~= true then
            LocalPlayer:SetAttribute("BackpackEnabled", true)
        end
    end

    local function setupCharacter(character)
        if not character or not Enabled then return end

        local hum = character:FindFirstChildOfClass("Humanoid")
            or character:WaitForChild("Humanoid", 5)
        if not hum then return end
        if not Enabled then return end

        humanoid = hum

        if hum.WalkSpeed > 0 then lastSpeed = hum.WalkSpeed end
        if hum.JumpHeight > 0 then lastJump  = hum.JumpHeight end

        clearTable(humanoidConns)

        humanoidConns[#humanoidConns + 1] =
            hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                if hum.WalkSpeed > 0 then lastSpeed = hum.WalkSpeed end
            end)

        humanoidConns[#humanoidConns + 1] =
            hum:GetPropertyChangedSignal("JumpHeight"):Connect(function()
                if hum.JumpHeight > 0 then lastJump = hum.JumpHeight end
            end)
    end

    local function fixTase()
        if not Enabled then return end
        local hum = humanoid
        if not hum or not hum.Parent or hum.Health <= 0 then return end

        if hum.WalkSpeed == 0 and hum.JumpHeight == 0 then
            hum.WalkSpeed  = lastSpeed
            hum.JumpHeight = lastJump
        end

        for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
            local anim = track.Animation
            if anim and TASE_ANIMS[anim.AnimationId] then
                track:Stop(0)
            end
        end

        enableBackpack()
    end

    local function enable()
        if Enabled then return end
        Enabled = true

        humanoid  = nil
        lastSpeed = DEFAULT_SPEED
        lastJump  = DEFAULT_JUMP
        clearTable(humanoidConns)

        if PlayerTased then
            eventConns[#eventConns + 1] = PlayerTased.OnClientEvent:Connect(function()
                task.defer(fixTase)
            end)
        end

        eventConns[#eventConns + 1] =
            LocalPlayer:GetAttributeChangedSignal("BackpackEnabled"):Connect(function()
                if Enabled and LocalPlayer:GetAttribute("BackpackEnabled") ~= true then
                    enableBackpack()
                end
            end)

        charAddedConn = LocalPlayer.CharacterAdded:Connect(function(c)
            humanoid = nil
            task.spawn(function()
                setupCharacter(c)
                enableBackpack()
            end)
        end)

        if LocalPlayer.Character then
            task.spawn(function()
                setupCharacter(LocalPlayer.Character)
                enableBackpack()
            end)
        end
    end

    local function disable()
        if not Enabled then return end
        Enabled = false

        clearTable(eventConns)
        clearTable(humanoidConns)

        if charAddedConn then
            charAddedConn:Disconnect()
            charAddedConn = nil
        end

        humanoid = nil
    end

    return {
        Set = function(v)
            if v == true then enable() else disable() end
            return Enabled
        end,
        Get = function() return Enabled end,
    }
end)()

--========================================================--
-- FE INVISIBLE
--========================================================--

local TweenService = game:GetService("TweenService")

local FEInvisible = (function()
    local state = {
        Enabled       = false,
        AnimTrack     = nil,
        HeartbeatConn = nil,
        Highlight     = nil,
        Saved         = {},
        RenderKey     = "FEInvisibleRenderStep",
    }

    local function getCharacter()
        return LocalPlayer.Character
    end

    local function isAlive()
        local char = getCharacter()
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        return hum ~= nil and hum.Health > 0
    end

    local function getOffsets(char)
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not hum or not root then return nil end
        local isR15 = (hum.RigType == Enum.HumanoidRigType.R15)
        local offsetY = hum.HipHeight + root.Size.Y / 2 - 1
        return isR15, offsetY
    end

    local function tweenTransparency(inst, target)
        TweenService:Create(
            inst,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Transparency = target }
        ):Play()
    end

    local function applyGhostTransparency()
        local char = getCharacter()
        if not char then return end
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("BasePart") or d:IsA("Decal") or d:IsA("Texture") then
                state.Saved[d] = state.Saved[d] or d.Transparency
                tweenTransparency(d, 0.99)
            end
        end
    end

    local function restoreTransparency()
        for inst, val in pairs(state.Saved) do
            if inst and inst.Parent then
                tweenTransparency(inst, val)
            end
        end
        state.Saved = {}
    end

    local function createGhostHighlight()
        local char = getCharacter()
        if not char or state.Highlight then return end

        local h = Instance.new("Highlight")
        h.Name = "FEInvisibleGhostOutline"
        h.FillTransparency = 1
        h.OutlineColor = Color3.fromRGB(255, 255, 255)
        h.OutlineTransparency = 1
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Adornee = char
        h.Parent = char

        TweenService:Create(
            h,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { OutlineTransparency = 0.1 }
        ):Play()

        state.Highlight = h
    end

    local function removeGhostHighlight()
        if not state.Highlight then return end
        local h = state.Highlight
        state.Highlight = nil

        TweenService:Create(
            h,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { OutlineTransparency = 1 }
        ):Play()

        task.delay(0.35, function()
            pcall(function() h:Destroy() end)
        end)
    end

    local function playInvisAnimation()
        if not isAlive() then return end

        local char = getCharacter()
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return end

        local isR15 = (hum.RigType == Enum.HumanoidRigType.R15)
        local animId = isR15 and "18665825805" or "215384594"

        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://" .. animId

        local animator = hum:FindFirstChildOfClass("Animator")
        if not animator then
            animator = Instance.new("Animator")
            animator.Parent = hum
        end

        state.AnimTrack = animator:LoadAnimation(anim)
        state.AnimTrack.Priority = Enum.AnimationPriority.Action4
        state.AnimTrack:Play(0, 0.001, 0)
        anim:Destroy()

        task.delay(0, function()
            if state.AnimTrack then
                state.AnimTrack.TimePosition = isR15 and 1.95 or 0.4
            end
        end)
    end

    local function cleanup()
        if state.HeartbeatConn then
            state.HeartbeatConn:Disconnect()
            state.HeartbeatConn = nil
        end

        pcall(function()
            RunService:UnbindFromRenderStep(state.RenderKey)
        end)

        if state.AnimTrack then
            pcall(function() state.AnimTrack:Stop(0) end)
            pcall(function() state.AnimTrack:Destroy() end)
            state.AnimTrack = nil
        end

        state.Saved = {}
        removeGhostHighlight()
    end

    local function enable()
        if state.Enabled or not isAlive() then return end
        state.Enabled = true

        applyGhostTransparency()
        createGhostHighlight()
        playInvisAnimation()

        pcall(function()
            RunService:UnbindFromRenderStep(state.RenderKey)
        end)

        RunService:BindToRenderStep(
            state.RenderKey,
            Enum.RenderPriority.Camera.Value - 1,
            function()
                if not state.Enabled or not isAlive() then return end

                local char = getCharacter()
                local isR15, offsetY = getOffsets(char)
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if not root or not offsetY then return end

                root.CFrame = root.CFrame
                    * CFrame.new(0, offsetY, 0)
                    * CFrame.Angles(math.rad(isR15 and -180 or -90), 0, 0)

                if state.AnimTrack then
                    state.AnimTrack:AdjustWeight(0.001)
                end
            end
        )

        state.HeartbeatConn = RunService.Heartbeat:Connect(function()
            if not state.Enabled or not isAlive() then return end

            local char = getCharacter()
            local isR15, offsetY = getOffsets(char)
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root or not offsetY then return end

            root.CFrame = root.CFrame
                * CFrame.new(0, -offsetY, 0)
                * CFrame.Angles(math.rad(isR15 and 180 or 90), 0, 0)

            if state.AnimTrack then
                state.AnimTrack:AdjustWeight(100)
            end
        end)
    end

    local function disable()
        if not state.Enabled then return end
        state.Enabled = false

        restoreTransparency()
        cleanup()
    end

    LocalPlayer.CharacterAdded:Connect(function()
        if not state.Enabled then return end
        state.Enabled = false
        cleanup()
        task.wait(0.2)
        enable()
    end)

    return {
        Set = function(v)
            if v then enable() else disable() end
            return state.Enabled
        end,
        Get = function() return state.Enabled end,
    }
end)()

--========================================================--
-- ANTI-INVIS
--========================================================--

local AntiInvis = (function()
    local state = {
        Enabled = false,
        Conn    = nil,
        Markers = {},
    }

    local FE_ANIM_IDS = {
        ["rbxassetid://18665825805"] = true,
        ["rbxassetid://215384594"]   = true,
        ["18665825805"] = true,
        ["215384594"]   = true,
    }

    local function removeMarker(Player)
        local m = state.Markers[Player]
        if m then
            if m.Gui and m.Gui.Parent then m.Gui:Destroy() end
            if m.Part and m.Part.Parent then m.Part:Destroy() end
            state.Markers[Player] = nil
        end
    end

    local function createMarker(Player)
        removeMarker(Player)

        local char = Player.Character
        if not char then return end

        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local markerPart = Instance.new("Part")
        markerPart.Name = "AntiInvisAnchor"
        markerPart.Size = Vector3.new(0.1, 0.1, 0.1)
        markerPart.Transparency = 1
        markerPart.CanCollide = false
        markerPart.Anchored = true

        markerPart.Position = Vector3.new(root.Position.X, 3, root.Position.Z)
        markerPart.Parent = workspace

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "AntiInvisMarker"
        billboard.Size = UDim2.fromOffset(200, 50)
        billboard.Adornee = markerPart
        billboard.StudsOffset = Vector3.new(0, 1.5, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = markerPart

        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.Text = "↓ " .. Player.DisplayName .. " ↓"
        label.TextColor3 = Color3.fromRGB(255, 0, 0)
        label.TextStrokeTransparency = 0
        label.TextScaled = true
        label.Font = Enum.Font.GothamBold
        label.Parent = billboard

        state.Markers[Player] = { Gui = billboard, Part = markerPart }
    end

    local function isInvisible(Player)
        local char = Player.Character
        if not char then return false end

        local bodyParts = { "Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso" }
        for _, partName in ipairs(bodyParts) do
            local part = char:FindFirstChild(partName)
            if part and part.Transparency > 0.8 then
                return true
            end
        end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            local animator = hum:FindFirstChildOfClass("Animator")
            if animator then
                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                    local anim = track.Animation
                    if anim and FE_ANIM_IDS[anim.AnimationId] and track.WeightCurrent > 0.1 then
                        return true
                    end
                end
            end
        end

        local root = char:FindFirstChild("HumanoidRootPart")
        if root and root.Position.Y < -20 then
            return true
        end

        return false
    end

    local function update()
        for _, Player in ipairs(Players:GetPlayers()) do
            if Player ~= LocalPlayer then
                if Player.Character and isInvisible(Player) then
                    if not state.Markers[Player] or not state.Markers[Player].Gui.Parent then
                        createMarker(Player)
                    else
                        local root = Player.Character:FindFirstChild("HumanoidRootPart")
                        local markerData = state.Markers[Player]
                        if root and markerData and markerData.Part then

                            markerData.Part.Position = Vector3.new(root.Position.X, 3, root.Position.Z)
                        end
                    end
                else
                    removeMarker(Player)
                end
            end
        end
    end

    local function enable()
        if state.Enabled then return end
        state.Enabled = true

        if state.Conn then state.Conn:Disconnect() end
        state.Conn = RunService.Heartbeat:Connect(update)
    end

    local function disable()
        if not state.Enabled then return end
        state.Enabled = false

        if state.Conn then
            state.Conn:Disconnect()
            state.Conn = nil
        end

        for Player in pairs(state.Markers) do
            removeMarker(Player)
        end
    end

    return {
        Set = function(v) if v then enable() else disable() end return state.Enabled end,
        Get = function() return state.Enabled end,
    }
end)()

--========================================================--
-- AUTO SPRINT
--========================================================--

local SprintState = {
    ShiftHeld = false,
}

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.Keyboard
       and (input.KeyCode == Enum.KeyCode.LeftShift
         or input.KeyCode == Enum.KeyCode.RightShift) then
        SprintState.ShiftHeld = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard
       and (input.KeyCode == Enum.KeyCode.LeftShift
         or input.KeyCode == Enum.KeyCode.RightShift) then
        SprintState.ShiftHeld = false
    end
end)

local function updateSprint()
    local Character = LocalPlayer.Character
    if not Character then return end
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not Humanoid then return end

    if Humanoid.Health <= 0 then return end

    if Settings.Underground then
        if Humanoid.WalkSpeed ~= Settings.UndergroundSpeed then
            Humanoid.WalkSpeed = Settings.UndergroundSpeed
        end
        return
    end

    if SprintState.ShiftHeld then
        if Humanoid.WalkSpeed ~= 24 then
            Humanoid.WalkSpeed = 24
        end
        return
    end

    if Settings.AutoSprint then
        if Humanoid.WalkSpeed ~= 24 then
            Humanoid.WalkSpeed = 24
        end
    else
        if Humanoid.WalkSpeed ~= 16 then
            Humanoid.WalkSpeed = 16
        end
    end
end

RunService.Heartbeat:Connect(function()
    updateSprint()
end)

--========================================================--
-- BYPASS ANTIJUMP
--========================================================--

local function updateJump()
    local StarterPlayer = game:GetService("StarterPlayer")
    local StarterScripts = StarterPlayer:FindFirstChild("StarterCharacterScripts")
    if not StarterScripts then return end

    local shouldDisable = Settings.AntiJump

    local starterAntiJump = StarterScripts:FindFirstChild("AntiJump")
    if starterAntiJump then
        starterAntiJump.Disabled = shouldDisable
    end

    local char = LocalPlayer.Character
    if char then
        local activeAntiJump = char:FindFirstChild("AntiJump")
        if activeAntiJump then
            activeAntiJump.Disabled = shouldDisable
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.1)
    local activeAntiJump = char:FindFirstChild("AntiJump")
    if activeAntiJump then
        activeAntiJump.Disabled = Settings.AntiJump
    end
end)


local CombatBridge = {
    IsRespawning = false,
    IsRestocking = false,
    LastAliveCF = nil,
    LastTeamName = "Guards",
}

_G.IsRespawning = false
local function setRespawningState(val)
    CombatBridge.IsRespawning = val
    _G.IsRespawning = val
end

-- =========================================================================
-- AutoWeapon
-- =========================================================================
local AutoWeapon = (function()
    local state = {
        Enabled = false,
        LastWeaponName = nil,
        SavedWeapons = {},
        HeartbeatConn = nil,
        IsDead = false,
        GiverCache = {},
    }

    local WEAPON_ALIASES = {
        ["m4a1"] = {"m4a1", "m4"},
        ["ak47"] = {"ak47", "ak-47", "ak"},
        ["shotgun"] = {"remington870", "remington 870", "remington", "shotgun"},
        ["mp5"] = {"mp5"},
        ["sniper"] = {"sniper", "awp"},
        ["fnfal"] = {"fnfal", "fal"},
        ["m9"] = {"m9", "pistol"}
    }

    local function normalizeName(name)
        return string.lower(tostring(name)):gsub("[%s%-_]", "")
    end

    local function updateSavedWeapons()
        local char = LocalPlayer.Character
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        local found = {}

        local function check(item)
            if item and item:IsA("Tool") then
                local key = normalizeName(item.Name)
                for aliasKey, aliases in pairs(WEAPON_ALIASES) do
                    for _, a in ipairs(aliases) do
                        if key:find(a, 1, true) then
                            found[item.Name] = true
                            break
                        end
                    end
                end
                if item:GetAttribute("ToolType") == "Gun" then
                    found[item.Name] = true
                end
            end
        end

        if char then
            for _, item in ipairs(char:GetChildren()) do check(item) end
        end
        if backpack then
            for _, item in ipairs(backpack:GetChildren()) do check(item) end
        end

        local count = 0
        for _ in pairs(found) do count = count + 1 end
        if count > 0 then
            state.SavedWeapons = found
        end
    end

    local function findTouchPart(inst)
        if not inst then return nil end
        if inst:IsA("BasePart") then return inst end
        local touch = inst:FindFirstChild("ITEMPICKUP") 
            or inst:FindFirstChild("TouchGiver") 
            or inst:FindFirstChildWhichIsA("TouchTransmitter", true)
        if touch then
            if touch:IsA("BasePart") then return touch end
            if touch.Parent and touch.Parent:IsA("BasePart") then return touch.Parent end
        end
        return inst:FindFirstChildWhichIsA("BasePart", true)
    end

    local function scanForGiver(weaponKey)
        local aliases = WEAPON_ALIASES[weaponKey] or { weaponKey }

        local prisonItems = Workspace:FindFirstChild("Prison_ITEMS")
        local giverFolder = prisonItems and prisonItems:FindFirstChild("giver")
        if giverFolder then
            for _, child in ipairs(giverFolder:GetChildren()) do
                local cleanName = normalizeName(child.Name)
                for _, alias in ipairs(aliases) do
                    if cleanName:find(alias, 1, true) then
                        local part = findTouchPart(child)
                        if part then return part end
                    end
                end
            end
        end

        for _, obj in ipairs(Workspace:GetChildren()) do
            local cleanName = normalizeName(obj.Name)
            for _, alias in ipairs(aliases) do
                if cleanName:find(alias, 1, true) then
                    local part = findTouchPart(obj)
                    if part then return part end
                end
            end
        end

        for _, desc in ipairs(Workspace:GetDescendants()) do
            if desc.Name == "TouchGiver" or desc.Name == "ITEMPICKUP" then
                local parentName = desc.Parent and normalizeName(desc.Parent.Name) or ""
                for _, alias in ipairs(aliases) do
                    if parentName:find(alias, 1, true) then
                        local part = findTouchPart(desc)
                        if part then return part end
                    end
                end
            end
        end

        local legacyMap = { fnfal = 71, ak47 = 207, shotgun = 184, mp5 = 188, sniper = 236 }
        local legacyIdx = legacyMap[weaponKey]
        if legacyIdx then
            local children = Workspace:GetChildren()
            local obj = children[legacyIdx]
            if obj then
                local part = findTouchPart(obj)
                if part then return part end
            end
        end

        return nil
    end

    local function getGiverByWeaponName(weaponName)
        local key = normalizeName(weaponName)
        for canonical, aliases in pairs(WEAPON_ALIASES) do
            for _, alias in ipairs(aliases) do
                if key:find(alias, 1, true) then
                    key = canonical
                    break
                end
            end
        end

        if state.GiverCache[key] and state.GiverCache[key].Parent then
            return state.GiverCache[key]
        end

        local giver = scanForGiver(key)
        if giver then
            state.GiverCache[key] = giver
        end
        return giver
    end

    local function getWeaponTool(weaponName)
        local key = normalizeName(weaponName)
        local char = LocalPlayer.Character
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if char then
            for _, c in ipairs(char:GetChildren()) do
                if c:IsA("Tool") and normalizeName(c.Name):find(key, 1, true) then return c end
            end
        end
        if backpack then
            for _, c in ipairs(backpack:GetChildren()) do
                if c:IsA("Tool") and normalizeName(c.Name):find(key, 1, true) then return c end
            end
        end
        return nil
    end

    local function hasSpecificWeapon(weaponName)
        return getWeaponTool(weaponName) ~= nil
    end

    local function getGunAmmoCount(gun)
        if not gun then return 0 end
        local attr = gun:GetAttribute("CurrentAmmo") or gun:GetAttribute("Local_CurrentAmmo")
        if attr then return tonumber(attr) or 0 end
        local val = gun:FindFirstChild("CurrentAmmo") or gun:FindFirstChild("Ammo")
        if val and val:IsA("ValueBase") then return tonumber(val.Value) or 0 end
        return 30
    end

    local function activateGiver(giverPart)
        if not giverPart then return false end
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return false end

        if typeof(firetouchinterest) == "function" then
            pcall(function()
                firetouchinterest(root, giverPart, 0)
                task.wait(0.04)
                firetouchinterest(root, giverPart, 1)
            end)
        end

        local savedCF = root.CFrame
        local savedVel = root.AssemblyLinearVelocity
        local targetCF = giverPart:IsA("BasePart") and giverPart.CFrame or giverPart:GetPivot()

        root.CFrame = targetCF + Vector3.new(0, 1.5, 0)
        root.AssemblyLinearVelocity = Vector3.zero
        task.wait(0.16)
        root.CFrame = savedCF
        root.AssemblyLinearVelocity = savedVel
        return true
    end

    local function giveWeapon(weaponName, force)
        if not weaponName then return end
        local existing = getWeaponTool(weaponName)

        if existing and not force then
            if getGunAmmoCount(existing) > 5 then return end
        end

        if existing then
            pcall(function() existing:Destroy() end)
            task.wait(0.05)
        end

        local giver = getGiverByWeaponName(weaponName)
        if not giver then return end

        activateGiver(giver)

        task.wait(0.06)
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        local char = LocalPlayer.Character
        if backpack and char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            local key = normalizeName(weaponName)
            for _, item in ipairs(backpack:GetChildren()) do
                if item:IsA("Tool") and normalizeName(item.Name):find(key, 1, true) then
                    if hum then hum:EquipTool(item) end
                    break
                end
            end
        end
    end

    local function restockWeapon(weaponName)
        if not weaponName or CombatBridge.IsRespawning then return end
        giveWeapon(weaponName, true)
    end

    local function restockOwnedWeapons()
        if CombatBridge.IsRestocking or CombatBridge.IsRespawning then return end
        CombatBridge.IsRestocking = true

        local toRefill = {}
        local char = LocalPlayer.Character
        local backpack = LocalPlayer:FindFirstChild("Backpack")

        local function checkItem(item)
            if item and item:IsA("Tool") then
                local ammo = getGunAmmoCount(item)
                if ammo <= 10 then
                    toRefill[item.Name] = true
                end
            end
        end

        if char then
            for _, item in ipairs(char:GetChildren()) do checkItem(item) end
        end
        if backpack then
            for _, item in ipairs(backpack:GetChildren()) do checkItem(item) end
        end

        local carriedCount = 0
        if char and char:FindFirstChildOfClass("Tool") then carriedCount = carriedCount + 1 end
        if backpack and #backpack:GetChildren() > 0 then carriedCount = carriedCount + #backpack:GetChildren() end

        if carriedCount == 0 and state.SavedWeapons then
            for gunName, _ in pairs(state.SavedWeapons) do
                toRefill[gunName] = true
            end
        end

        for gunName, _ in pairs(toRefill) do
            giveWeapon(gunName, true)
            task.wait(0.08)
        end

        CombatBridge.IsRestocking = false
    end

    local function giveFullArsenal()
        if CombatBridge.IsRestocking or CombatBridge.IsRespawning then return end
        CombatBridge.IsRestocking = true
        local guns = {"M4A1", "AK-47", "Remington 870", "MP5"}
        for _, gunName in ipairs(guns) do
            giveWeapon(gunName, false)
            task.wait(0.08)
        end
        CombatBridge.IsRestocking = false
    end

    local function enable()
        if state.Enabled then return end
        state.Enabled = true
        state.IsDead = false

        if state.HeartbeatConn then state.HeartbeatConn:Disconnect() end
        state.HeartbeatConn = RunService.Heartbeat:Connect(function()
            if not state.Enabled then return end
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            if hum and hum.Health > 0 then
                updateSavedWeapons()
            elseif hum and hum.Health <= 0 and not state.IsDead then
                state.IsDead = true
                updateSavedWeapons()
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then state.LastWeaponName = tool.Name end

                task.spawn(function()
                    local timeout = os.clock() + 10
                    while os.clock() < timeout do
                        if CombatBridge.IsRespawning then
                            task.wait(0.1)
                            continue
                        end

                        local c = LocalPlayer.Character
                        local h = c and c:FindFirstChildOfClass("Humanoid")
                        if c and h and h.Health > 0 then
                            task.wait(0.15)
                            restockOwnedWeapons()
                            state.IsDead = false
                            break
                        end
                        task.wait(0.1)
                    end
                end)
            end
        end)
    end

    local function disable()
        if not state.Enabled then return end
        state.Enabled = false
        if state.HeartbeatConn then state.HeartbeatConn:Disconnect(); state.HeartbeatConn = nil end
    end

    return {
        Set = function(v) if v then enable() else disable() end return state.Enabled end,
        Get = function() return state.Enabled end,
        GiveWeapon = giveWeapon,
        RestockWeapon = restockWeapon,
        RestockOwned = restockOwnedWeapons,
        RestockAll = restockOwnedWeapons,
        GetArsenal = giveFullArsenal,
        HasWeapon = hasSpecificWeapon,
        GetSavedWeapons = function() return state.SavedWeapons end,
        SetLastWeapon = function(name) state.LastWeaponName = name end,
    }
end)()

-- =========================================================================
-- QuickRespawn
-- =========================================================================
local QuickRespawn = (function()
    local state = {
        Enabled = false,
        Busy = false,
        HeartbeatConn = nil,
        DiedConn = nil,
        CharAddedConn = nil,
    }

    local function fixUI()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            local cam = Workspace.CurrentCamera
            if cam then
                cam.CameraType = Enum.CameraType.Custom
                cam.CameraSubject = hum
            end
        end

        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local home = playerGui and playerGui:FindFirstChild("Home")
        if home then
            home.Enabled = true
            local intro = home:FindFirstChild("IntroFrame")
            if intro then intro.Visible = false end
        end

        if LocalPlayer:GetAttribute("BackpackEnabled") ~= true then
            LocalPlayer:SetAttribute("BackpackEnabled", true)
        end
    end

    local function changeTeam(teamName)
        local team = Teams:FindFirstChild(teamName)
        if not team then return false end
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local req = remotes and remotes:FindFirstChild("RequestTeamChange")
        if not req then return false end
        local ok = pcall(function()
            req:InvokeServer(team, 1)
        end)
        return ok
    end

    local function waitForTeam(targetTeamName, timeout)
        local start = os.clock()
        while os.clock() - start < timeout do
            if LocalPlayer.Team and LocalPlayer.Team.Name == targetTeamName then return true end
            task.wait(0.05)
        end
        return false
    end

    local function doRespawn()
        if state.Busy then return end
        state.Busy = true
        setRespawningState(true)

        local savedCF = CombatBridge.LastAliveCF
        local oldTeam = CombatBridge.LastTeamName or "Guards"
        if oldTeam == "Criminals" or oldTeam == "Neutral" then
            oldTeam = "Inmates"
        end

        local resetSafety = task.delay(6, function()
            if state.Busy then
                state.Busy = false
                setRespawningState(false)
                fixUI()
            end
        end)

        task.spawn(function()
            local success = false
            local attempts = 0

            while attempts < 3 and not success do
                attempts = attempts + 1
                changeTeam("Neutral")
                waitForTeam("Neutral", 1.0)
                task.wait(0.75)

                changeTeam(oldTeam)
                waitForTeam(oldTeam, 1.0)

                if LocalPlayer.Team and LocalPlayer.Team.Name == oldTeam then
                    success = true
                else
                    task.wait(0.3)
                end
            end

            local newChar, newRoot = nil, nil
            local expire = os.clock() + 4
            while os.clock() < expire do
                local c = LocalPlayer.Character
                local r = c and c:FindFirstChild("HumanoidRootPart")
                local h = c and c:FindFirstChildOfClass("Humanoid")
                if r and h and h.Health > 0 then
                    newChar, newRoot = c, r
                    break
                end
                task.wait(0.05)
            end

            if newRoot and savedCF then
                newRoot.CFrame = savedCF
                newRoot.AssemblyLinearVelocity = Vector3.zero
                newRoot.Anchored = true
                task.wait(0.08)
                newRoot.Anchored = false
                newRoot.CFrame = savedCF
            end

            fixUI()

            if AutoWeapon and AutoWeapon.Get and AutoWeapon.Get() then
                task.spawn(AutoWeapon.RestockOwned)
            end

            if resetSafety then task.cancel(resetSafety) end
            state.Busy = false
            setRespawningState(false)
        end)
    end

    local function hookCharacter(char)
        if state.DiedConn then state.DiedConn:Disconnect(); state.DiedConn = nil end
        if state.HeartbeatConn then state.HeartbeatConn:Disconnect(); state.HeartbeatConn = nil end

        local hum = char:WaitForChild("Humanoid", 5)
        local root = char:WaitForChild("HumanoidRootPart", 5)
        if not hum or not root then return end

        state.HeartbeatConn = RunService.Heartbeat:Connect(function()
            if not state.Enabled or state.Busy or CombatBridge.IsRespawning then return end
            if hum.Health > 0 and root.Parent then
                CombatBridge.LastAliveCF = root.CFrame
                if LocalPlayer.Team and LocalPlayer.Team.Name ~= "Neutral" then
                    CombatBridge.LastTeamName = LocalPlayer.Team.Name
                end
            elseif hum.Health <= 0 and not state.Busy and state.Enabled then
                task.spawn(doRespawn)
            end
        end)

        state.DiedConn = hum.Died:Connect(function()
            if not state.Enabled or state.Busy then return end
            task.delay(0.05, doRespawn)
        end)
    end

    local function enable()
        if state.Enabled then return end
        state.Enabled = true
        local char = LocalPlayer.Character
        if char then hookCharacter(char) end

        if state.CharAddedConn then state.CharAddedConn:Disconnect() end
        state.CharAddedConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
            if not state.Enabled then return end
            task.wait(0.1)
            fixUI()
            hookCharacter(newChar)
        end)
    end

    local function disable()
        if not state.Enabled then return end
        state.Enabled = false
        if state.DiedConn then state.DiedConn:Disconnect(); state.DiedConn = nil end
        if state.HeartbeatConn then state.HeartbeatConn:Disconnect(); state.HeartbeatConn = nil end
        if state.CharAddedConn then state.CharAddedConn:Disconnect(); state.CharAddedConn = nil end
    end

    return {
        Set = function(v) if v then enable() else disable() end return state.Enabled end,
        Get = function() return state.Enabled end,
        RespawnNow = doRespawn,
    }
end)()

-- =========================================================================
-- TargetKiller
-- =========================================================================
local TargetKiller = (function()
    local state = {
        Enabled = false,
        TargetPlayer = nil,
        TargetName = nil,
        SavedReturnCFrame = nil,
        LoopConn = nil,
        Busy = false,
        LastAttack = 0,
        BaseCooldown = 0.05,
        InstantKill = true,
        BulletsPerShot = 8,
        PositionMode = "Above",
        KillAll = false,
        Noclip = true,
    }

    local WeaponPriority = {
        ["M4A1"] = 1,
        ["AK-47"] = 2, ["AK47"] = 2,
        ["MP5"] = 3,
        ["Remington 870"] = 4, ["Shotgun"] = 4,
        ["FNFAL"] = 5, ["FAL"] = 5,
        ["Sniper"] = 6,
        ["M9"] = 7
    }

    local function getExternalSettings()
        local ext = _G.Settings or (getgenv and getgenv().Settings)
        if ext and ext.RapidFire then
            return true, tonumber(ext.FireRate) or 0.01
        end
        return false, 0
    end

    local function getShootEvent()
        local GunRemotes = ReplicatedStorage:FindFirstChild("GunRemotes")
        return GunRemotes and GunRemotes:FindFirstChild("ShootEvent")
    end

    local function getGunTracers()
        local ok, mod = pcall(function()
            return require(ReplicatedStorage.SharedModules.GunTracers)
        end)
        if ok then return mod end
        return nil
    end

    local function getGunAmmo(gun)
        if not gun then return 0 end
        local attr = gun:GetAttribute("Local_CurrentAmmo") or gun:GetAttribute("CurrentAmmo")
        if attr ~= nil then return tonumber(attr) or 0 end
        local ammoVal = gun:FindFirstChild("Ammo") or gun:FindFirstChild("CurrentAmmo")
        if ammoVal and ammoVal:IsA("ValueBase") then return tonumber(ammoVal.Value) or 0 end
        return 30
    end

    local function resolveTarget()
        if state.TargetPlayer and state.TargetPlayer.Parent == Players then
            return state.TargetPlayer
        end
        if state.TargetName and state.TargetName ~= "" then
            local found = Players:FindFirstChild(state.TargetName)
            if found then
                state.TargetPlayer = found
                return found
            end
        end
        return nil
    end

    local function equipBestGun()
        local char = LocalPlayer.Character
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if not char or not backpack then return nil end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return nil end

        local bestGun, bestPriority = nil, math.huge

        local function evaluate(item)
            if item:IsA("Tool") and (item:GetAttribute("ToolType") == "Gun" or WeaponPriority[item.Name]) then
                local ammo = getGunAmmo(item)
                if ammo > 0 then
                    local p = WeaponPriority[item.Name] or 99
                    if p < bestPriority then
                        bestPriority = p
                        bestGun = item
                    end
                end
            end
        end

        local currentTool = char:FindFirstChildOfClass("Tool")
        if currentTool and (currentTool:GetAttribute("ToolType") == "Gun" or WeaponPriority[currentTool.Name]) then
            local ammo = getGunAmmo(currentTool)
            if ammo > 0 then
                bestGun = currentTool
                bestPriority = WeaponPriority[currentTool.Name] or 99
            end
        end

        for _, item in ipairs(backpack:GetChildren()) do
            evaluate(item)
        end

        if bestGun then
            if bestGun.Parent == backpack then
                hum:EquipTool(bestGun)
            end
            return bestGun
        end

        if AutoWeapon and AutoWeapon.Get and AutoWeapon.Get() then
            task.spawn(AutoWeapon.RestockOwned)
        end

        return nil
    end

    local function resetPosition()
        if state.SavedReturnCFrame and LocalPlayer.Character then
            local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                root.AssemblyLinearVelocity = Vector3.zero
                root.CFrame = state.SavedReturnCFrame
            end
        end
        state.SavedReturnCFrame = nil
    end

    local function applyNoclip(char)
        if not state.Noclip or not char then return end
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end

    local function calculateTargetCFrame(tChar, tRoot, tHead)
        local targetHeadPos = tHead.Position
        local targetRootCF = tRoot.CFrame

        if state.PositionMode == "Above" then
            local desiredPos = targetHeadPos + Vector3.new(0, 3.2, 0) - targetRootCF.LookVector * 0.4
            return CFrame.lookAt(desiredPos, targetHeadPos)
        elseif state.PositionMode == "Behind" then
            local backOffset = -targetRootCF.LookVector * 3.2 + Vector3.new(0, 1.2, 0)
            local desiredPos = targetRootCF.Position + backOffset
            return CFrame.lookAt(desiredPos, targetHeadPos)
        elseif state.PositionMode == "Orbit" then
            local angle = os.clock() * 8
            local orbitOffset = Vector3.new(math.cos(angle) * 3.5, 2.5, math.sin(angle) * 3.5)
            local desiredPos = targetHeadPos + orbitOffset
            return CFrame.lookAt(desiredPos, targetHeadPos)
        end

        local defaultPos = targetHeadPos + Vector3.new(0, 3.2, 0) - targetRootCF.LookVector * 0.4
        return CFrame.lookAt(defaultPos, targetHeadPos)
    end

    local function findNextEnemy()
        local bestPlayer = nil
        local bestDist = math.huge
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local pHum = plr.Character:FindFirstChildOfClass("Humanoid")
                local pRoot = plr.Character:FindFirstChild("HumanoidRootPart")
                local pHead = plr.Character:FindFirstChild("Head")

                if pHum and pHum.Health > 0 and pRoot and pHead then
                    local isEnemy = true
                    if LocalPlayer.Team and plr.Team and LocalPlayer.Team == plr.Team then
                        isEnemy = false
                    end
                    if plr.Character:FindFirstChildOfClass("ForceField") then
                        isEnemy = false
                    end

                    if isEnemy then
                        local dist = myRoot and (pRoot.Position - myRoot.Position).Magnitude or 0
                        if dist < bestDist then
                            bestDist = dist
                            bestPlayer = plr
                        end
                    end
                end
            end
        end
        return bestPlayer
    end

    local function mainLoop()
        if not state.Enabled or CombatBridge.IsRespawning or CombatBridge.IsRestocking then
            return
        end

        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not char or not root or not hum or hum.Health <= 0 then
            return
        end

        if state.KillAll then
            local currentTarget = resolveTarget()
            if not currentTarget 
                or not currentTarget.Character 
                or not currentTarget.Character:FindFirstChildOfClass("Humanoid")
                or currentTarget.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then
                local nextPlr = findNextEnemy()
                if nextPlr then
                    state.TargetPlayer = nextPlr
                    state.TargetName = nextPlr.Name
                else
                    state.TargetPlayer = nil
                end
            end
        end

        local tPlayer = resolveTarget()
        if not tPlayer then return end

        local tChar = tPlayer.Character
        local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")
        local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
        local tHead = tChar and tChar:FindFirstChild("Head")

        if not tChar or not tHum or tHum.Health <= 0 or not tRoot or not tHead then
            if not state.KillAll then
                resetPosition()
            else
                state.TargetPlayer = nil
                state.TargetName = nil
            end
            return
        end

        local hasShield = tChar:FindFirstChildOfClass("ForceField") ~= nil
        if hasShield then
            resetPosition()
            return
        end

        if not state.SavedReturnCFrame then
            state.SavedReturnCFrame = root.CFrame
        end

        applyNoclip(char)
        root.AssemblyLinearVelocity = Vector3.zero
        root.CFrame = calculateTargetCFrame(tChar, tRoot, tHead)

        local rfEnabled, rfRate = getExternalSettings()
        local currentCooldown = rfEnabled and math.max(rfRate, 0.01) or state.BaseCooldown

        if not state.Busy and (os.clock() - state.LastAttack >= currentCooldown) then
            state.Busy = true
            local gun = equipBestGun()

            if gun and gun.Parent == char then
                local shootEvent = getShootEvent()
                local headPart = char:FindFirstChild("Head")
                if shootEvent and headPart then
                    local payload = { { headPart.Position, tHead.Position, tHead } }

                    local burstCount = state.InstantKill and (state.BulletsPerShot or 8) or 1
                    local currAmmo = getGunAmmo(gun)
                    local newAmmo = math.max(currAmmo - burstCount, 0)
                    gun:SetAttribute("Local_CurrentAmmo", newAmmo)

                    for i = 1, burstCount do
                        pcall(function() shootEvent:FireServer(payload) end)
                    end

                    local GunTracers = getGunTracers()
                    if GunTracers and GunTracers.createBullet then
                        local muzzle = gun:FindFirstChild("Muzzle")
                        local muzzlePos = muzzle and muzzle.Position or headPart.Position
                        pcall(function() GunTracers.createBullet(muzzlePos, tHead.Position) end)
                    end

                    if newAmmo <= 0 then
                        if AutoWeapon and AutoWeapon.Get and AutoWeapon.Get() then
                            task.spawn(function()
                                if AutoWeapon.RestockWeapon then
                                    AutoWeapon.RestockWeapon(gun.Name)
                                else
                                    AutoWeapon.RestockOwned()
                                end
                            end)
                        end
                    end
                end
            end

            state.LastAttack = os.clock()
            state.Busy = false
        end
    end

    local function enable()
        if state.Enabled then return end
        state.Enabled = true
        state.SavedReturnCFrame = nil
        state.Busy = false
        state.LastAttack = 0

        if state.LoopConn then state.LoopConn:Disconnect() end
        state.LoopConn = RunService.RenderStepped:Connect(function()
            if not state.Enabled then return end
            pcall(mainLoop)
        end)
    end

    local function disable()
        if not state.Enabled then return end
        state.Enabled = false
        if state.LoopConn then state.LoopConn:Disconnect(); state.LoopConn = nil end
        resetPosition()
        state.Busy = false
    end

    local function setTarget(playerOrName)
        if typeof(playerOrName) == "string" then
            state.TargetName = playerOrName
            state.TargetPlayer = Players:FindFirstChild(playerOrName)
        elseif typeof(playerOrName) == "Instance" and playerOrName:IsA("Player") then
            state.TargetPlayer = playerOrName
            state.TargetName = playerOrName.Name
        elseif playerOrName == nil then
            state.TargetPlayer = nil
            state.TargetName = nil
            resetPosition()
        end
    end

    return {
        Set = function(v) if v then enable() else disable() end return state.Enabled end,
        Get = function() return state.Enabled end,
        SetTarget = setTarget,
        GetTarget = resolveTarget,
        GetTargetName = function() return state.TargetName end,
        SetCooldown = function(s) state.BaseCooldown = tonumber(s) or 0.05 end,
        SetMode = function(mode)
            if mode == "Above" or mode == "Behind" or mode == "Orbit" then
                state.PositionMode = mode
            end
        end,
        SetInstantKill = function(v) state.InstantKill = (v == true) end,
        SetKillAll = function(v) state.KillAll = (v == true) end,
    }
end)()


--========================================================--
-- MOVEMENT
--========================================================--

Settings.DefaultSpeed = 16
Settings.SprintSpeed = 24
Settings.JumpPower = 50
Settings.Gravity = 196.2

local function setWalkSpeed(speed)
    Settings.DefaultSpeed = speed
    Settings.SprintSpeed = speed + 8
end

local function setJumpPower(power)
    Settings.JumpPower = power
end

local function setGravity(gravity)
    Settings.Gravity = gravity
    workspace.Gravity = gravity
end

RunService.RenderStepped:Connect(function()
    if workspace.Gravity ~= Settings.Gravity then
        workspace.Gravity = Settings.Gravity
    end

    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    if hum.UseJumpPower then
        if hum.JumpPower ~= Settings.JumpPower then
            hum.JumpPower = Settings.JumpPower
        end
    else
        local targetHeight = Settings.JumpPower / 5
        if hum.JumpHeight ~= targetHeight then
            hum.JumpHeight = targetHeight
        end
    end

    local currentSpeed = Settings.DefaultSpeed
    if Settings.Underground then
        currentSpeed = Settings.UndergroundSpeed
    elseif Settings.AutoSprint or (SprintState and SprintState.ShiftHeld) then
        currentSpeed = Settings.SprintSpeed
    end

    if hum.WalkSpeed ~= currentSpeed then
        hum.WalkSpeed = currentSpeed
    end
end)

--========================================================--
-- PLAYER CONNECTIONS
--========================================================--

local function setupPlayer(Player)

    if Player == LocalPlayer then
        return
    end

    Player.CharacterAdded:Connect(function()

        task.wait(0.2)

        if Settings.ESP then
            createESP(Player)
        end

        if Settings.Hitbox then
            createHitbox(Player)
        end
    end)

    Player.CharacterRemoving:Connect(function()

        removeESP(Player)
        removeHitbox(Player)
    end)
end

for _, Player in ipairs(Players:GetPlayers()) do
    setupPlayer(Player)
end

Players.PlayerAdded:Connect(setupPlayer)

Players.PlayerRemoving:Connect(function(Player)

    removeESP(Player)
    removeHitbox(Player)
end)

--========================================================--
-- MAIN LOOP
--========================================================--

RunService.RenderStepped:Connect(function()

    if Settings.ESP then
        updateESP()
    end

    
    updateHitboxVisuals()
    updateHitboxes()

    if Settings.Underground then
        updateSprint()
    end
end)



-- =========================================================================
-- UNLOAD ALL MODULES HELPER
-- =========================================================================
local function unloadAllModules()
    Settings.ESP = false
    Settings.Hitbox = false
    Settings.RapidFire = false
    Settings.AntiJump = false
    Settings.AutoSprint = false

    if Settings.Underground then
        setUnderground(false)
    end

    pcall(function() FEInvisible.Set(false) end)
    pcall(function() if TaseBypass then TaseBypass.Set(false) end end)
    pcall(function() AutoCriminal.Set(false) end)
    pcall(function() DamageNumbers.Set(false) end)
    pcall(function() CustomWeapon.Set(false) end)
    pcall(function() TargetKiller.Set(false) end)
    pcall(function() AutoWeapon.Set(false) end)
    pcall(function() QuickRespawn.Set(false) end)
    pcall(function() AntiFling.Set(false) end)
    pcall(function() AntiInvis.Set(false) end)

    disableFullbright()

    pcall(function()
        local StarterScripts = game:GetService("StarterPlayer"):FindFirstChild("StarterCharacterScripts")
        if StarterScripts then
            local AntiJump = StarterScripts:FindFirstChild("AntiJump")
            if AntiJump then AntiJump.Disabled = false end
        end
        local char = LocalPlayer.Character
        if char then
            local activeAJ = char:FindFirstChild("AntiJump")
            if activeAJ then activeAJ.Disabled = false end
        end
    end)

    for Player in pairs(ESPObjects) do
        removeESP(Player)
    end

    for Player in pairs(HitboxObjects) do
        removeHitbox(Player)
    end

    if UndergroundConnection then
        UndergroundConnection:Disconnect()
        UndergroundConnection = nil
    end

    UndergroundSavedCFrame = nil
    print("[Nightfall Modules] All modules cleanly unloaded.")
end

-- =========================================================================
-- EXPORT MODULES TABLE
-- =========================================================================

local Modules = {

    CombatBridge = CombatBridge,
    TargetKiller = TargetKiller,
    AutoWeapon = AutoWeapon,
    QuickRespawn = QuickRespawn,

    TaseBypass = TaseBypass,
    AntiFling = AntiFling,
    AutoCriminal = AutoCriminal,
    FEInvisible = FEInvisible,
    AntiInvis = AntiInvis,

    Underground = {
        Start = startUnderground,
        Stop = stopUnderground,
        Set = setUnderground,
    },
    setUnderground = setUnderground,
    startUnderground = startUnderground,
    stopUnderground = stopUnderground,

    ESP = {
        Create = createESP,
        Remove = removeESP,
        Update = updateESP,
        Objects = ESPObjects,
    },
    createESP = createESP,
    removeESP = removeESP,
    updateESP = updateESP,
    ESPObjects = ESPObjects,

    Hitbox = {
        Create = createHitbox,
        Remove = removeHitbox,
        Update = updateHitboxes,
        Objects = HitboxObjects,
    },
    createHitbox = createHitbox,
    removeHitbox = removeHitbox,
    updateHitboxes = updateHitboxes,
    HitboxObjects = HitboxObjects,

    CustomWeapon = CustomWeapon,
    DamageNumbers = DamageNumbers,

    Fullbright = {
        Update = updateFullbright,
        Disable = disableFullbright,
        Apply = applyFullbright,
    },
    updateFullbright = updateFullbright,
    disableFullbright = disableFullbright,

    TeleportGiver = teleportToGiver,
    teleportToGiver = teleportToGiver,
    getFNFAL = getFNFAL,
    getAK47 = getAK47,
    getShotgun = getShotgun,
    getMP5 = getMP5,
    getSniper = getSniper,
    getM4A1 = getM4A1,

    refreshAllTools = refreshAllTools,
    setWalkSpeed = setWalkSpeed,
    setJumpPower = setJumpPower,
    setGravity = setGravity,
    updateSprint = updateSprint,
    updateJump = updateJump,
    getCharacter = getCharacter,
    isAlive = isAlive,

    UnloadAll = unloadAllModules,
}

_G.PF_Modules = Modules

return Modules
