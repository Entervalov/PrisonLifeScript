--========================================================--
-- SERVICES
--========================================================--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

--========================================================--
-- WINDUI
--========================================================--

local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
))()

--========================================================--
-- SETTINGS
--========================================================--

local Settings = {
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
-- VERSION & UPDATER
--========================================================--

local SCRIPT_VERSION = "0.0.3"
local VERSION_URL = "https://raw.githubusercontent.com/Entervalov/PrisonLifeScript/refs/heads/main/_version.json"
local SCRIPT_URL = "https://raw.githubusercontent.com/Entervalov/PrisonLifeScript/refs/heads/main/PF.lua"

local HttpService = game:GetService("HttpService")
local isUpdating = false

--========================================================--
-- MODULES LOADER
--========================================================--

local Mod = "https://raw.githubusercontent.com/Entervalov/PrisonLifeScript/refs/heads/main/modules.lua"

local function loadModules()

    if Mod and not Mod:find("username/repository") then
        local ok, res = pcall(function()
            return loadstring(game:HttpGet(Mod))()
        end)
        if ok and type(res) == "table" then
            print("[Nightfall Loader] Modules loaded from GitHub")
            return res
        end
        warn("[Nightfall Loader] GitHub load failed: " .. tostring(res))
    end

    if typeof(loadfile) == "function" then
        local ok, fn = pcall(loadfile, "modules.lua")
        if ok and type(fn) == "function" then
            local okCall, res = pcall(fn)
            if okCall and type(res) == "table" then
                print("[Nightfall Loader] Modules loaded locally via loadfile(modules.lua).")
                return res
            end
        end
    end

    if typeof(readfile) == "function" and typeof(isfile) == "function" and isfile("modules.lua") then
        local ok, res = pcall(function()
            return loadstring(readfile("modules.lua"))()
        end)
        if ok and type(res) == "table" then
            print("[Nightfall Loader] Modules loaded locally via readfile(modules.lua).")
            return res
        end
    end

    if _G.PF_Modules and type(_G.PF_Modules) == "table" then
        print("[Nightfall Loader] Using pre-existing _G.PF_Modules.")
        return _G.PF_Modules
    end

    error("[Nightfall Loader] Could not load modules! Configure Mod or place modules.lua in executor workspace.")
end

local Modules = loadModules()

local TargetKiller       = Modules.TargetKiller
local AutoWeapon         = Modules.AutoWeapon
local QuickRespawn       = Modules.QuickRespawn
local CombatBridge       = Modules.CombatBridge
local TaseBypass         = Modules.TaseBypass
local AntiFling          = Modules.AntiFling
local AutoCriminal       = Modules.AutoCriminal
local FEInvisible        = Modules.FEInvisible
local AntiInvis          = Modules.AntiInvis
local CustomWeapon       = Modules.CustomWeapon
local DamageNumbers      = Modules.DamageNumbers
local setUnderground     = Modules.setUnderground
local startUnderground   = Modules.startUnderground
local stopUnderground    = Modules.stopUnderground
local createESP          = Modules.createESP
local removeESP          = Modules.removeESP
local updateESP          = Modules.updateESP
local createHitbox       = Modules.createHitbox
local removeHitbox       = Modules.removeHitbox
local updateHitboxes     = Modules.updateHitboxes
local teleportToGiver    = Modules.teleportToGiver
local updateFullbright   = Modules.updateFullbright
local disableFullbright  = Modules.disableFullbright
local refreshAllTools    = Modules.refreshAllTools
local setWalkSpeed       = Modules.setWalkSpeed
local setJumpPower       = Modules.setJumpPower
local setGravity         = Modules.setGravity
local updateSprint       = Modules.updateSprint
local updateJump         = Modules.updateJump
local ESPObjects         = Modules.ESPObjects or {}
local HitboxObjects      = Modules.HitboxObjects or {}
local isAlive            = Modules.isAlive
local getCharacter       = Modules.getCharacter

local function getFNFAL() return Modules.getFNFAL and Modules.getFNFAL() or (Modules.AutoWeapon and Modules.AutoWeapon.GiveWeapon("FNFAL")) end
local function getAK47() return Modules.getAK47 and Modules.getAK47() or (Modules.AutoWeapon and Modules.AutoWeapon.GiveWeapon("AK-47")) end
local function getShotgun() return Modules.getShotgun and Modules.getShotgun() or (Modules.AutoWeapon and Modules.AutoWeapon.GiveWeapon("Remington 870")) end
local function getMP5() return Modules.getMP5 and Modules.getMP5() or (Modules.AutoWeapon and Modules.AutoWeapon.GiveWeapon("MP5")) end
local function getSniper() return Modules.getSniper and Modules.getSniper() or (Modules.AutoWeapon and Modules.AutoWeapon.GiveWeapon("Sniper")) end
local function getM4A1() return Modules.getM4A1 and Modules.getM4A1() or (Modules.AutoWeapon and Modules.AutoWeapon.GiveWeapon("M4A1")) end

--========================================================--
-- KILLFEED NOTIFICATIONS
--========================================================--

local KillfeedNotify = true

local KillfeedFolder = ReplicatedStorage:WaitForChild("Killfeed", 10)

if KillfeedFolder and KillfeedFolder:IsA("Folder") then

    KillfeedFolder.ChildAdded:Connect(function(child)

        if not KillfeedNotify then return end

        local text = child.Name
        if not text or #text < 5 or text == "#" then return end

        local icon = "skull"
        local tcolor = child:FindFirstChild("TColor")
        if tcolor and tcolor:IsA("Color3Value") then
            local c = tcolor.Value
            if c.R > c.B then
                icon = "sword"      
            elseif c.B > c.R then
                icon = "shield"     
            end
        end

        WindUI:Notify({
            Title = "Killing",
            Content = text,
            Icon = icon,
            Image = nil,
            Duration = 5,
            Buttons = {
                {
                    Title = "OK",
                    Callback = function()
                    end
                }
            }
        })
    end)
end

--========================================================--
-- UPDATER LOGIC
--========================================================--

local function parseVersion(vStr)
    local parts = {}
    for num in tostring(vStr):gmatch("%d+") do
        table.insert(parts, tonumber(num) or 0)
    end
    return parts
end

local function isNewerVersion(remoteVer, localVer)
    local r = parseVersion(remoteVer)
    local l = parseVersion(localVer)
    for i = 1, math.max(#r, #l) do
        local rv = r[i] or 0
        local lv = l[i] or 0
        if rv > lv then return true end
        if rv < lv then return false end
    end
    return false
end

local unloadAllFeatures = nil

local function performUpdate(newVer, targetUrl)
    if isUpdating then return end
    isUpdating = true

    WindUI:Notify({
        Title = "Update!",
        Content = "Disabling all functions and loading the v" .. tostring(newVer) .. "...",
        Icon = "download",
        Duration = 4
    })

    if unloadAllFeatures then
        pcall(unloadAllFeatures)
    end

    task.wait(0.5)

    pcall(function()
        if Window and Window.Destroy then
            Window:Destroy()
        end
    end)

    task.wait(0.5)

    local url = targetUrl or SCRIPT_URL
    local ok, res = pcall(function()
        return game:HttpGet(url .. "?t=" .. tostring(os.time()))
    end)

    if ok and res and #res > 0 then
        local runOk, runErr = pcall(function()
            loadstring(res)()
        end)
        if not runOk then
            warn("[Nightfall Updater] Execution failed: " .. tostring(runErr))
            WindUI:Notify({
                Title = "Launch Err..",
                Content = "The new version could not be launched: " .. tostring(runErr),
                Icon = "triangle-alert",
                Duration = 6
            })
            isUpdating = false
        end
    else
        warn("[Nightfall Updater] Download failed: " .. tostring(res))
        WindUI:Notify({
            Title = "Loading error",
            Content = "The update could not be downloaded (maybe ur wifi is crazzyyy??)",
            Icon = "triangle-alert",
            Duration = 6
        })
        isUpdating = false
    end
end

local function checkUpdate(silent)
    local ok, raw = pcall(function()
        return game:HttpGet(VERSION_URL .. "?t=" .. tostring(os.time()))
    end)

    if not ok or not raw or #raw == 0 then
        if not silent then
            WindUI:Notify({
                Title = "Update check",
                Content = "The update could not be checked",
                Icon = "triangle-alert",
                Duration = 4
            })
        end
        return false
    end

    local data = nil
    pcall(function()
        data = HttpService:JSONDecode(raw)
    end)

    if not data or not data.version then
        if not silent then
            WindUI:Notify({
                Title = "Update check",
                Content = "Invalid file format _version.json.",
                Icon = "triangle-alert",
                Duration = 4
            })
        end
        return false
    end

    local remoteVer = tostring(data.version)
    if isNewerVersion(remoteVer, SCRIPT_VERSION) then
        local changelog = data.changelog and ("\nWhat’s new: " .. tostring(data.changelog)) or ""
        WindUI:Notify({
            Title = "An update is available!",
            Content = "A new version has been found. v" .. remoteVer .. " (current v" .. SCRIPT_VERSION .. ")" .. changelog,
            Icon = "sparkles",
            Duration = 15,
            Buttons = {
                {
                    Title = "Update now",
                    Callback = function()
                        performUpdate(remoteVer, data.scriptUrl)
                    end
                },
                {
                    Title = "Maybe, Later",
                    Callback = function() end
                }
            }
        })
        return true, remoteVer
    else
        if not silent then
            WindUI:Notify({
                Title = "Updates",
                Content = "You have the latest version installed (v" .. SCRIPT_VERSION .. ")!",
                Icon = "sparkles",
                Duration = 4
            })
        end
        return false, remoteVer
    end
end

--========================================================--
-- WINDUI WINDOW
--========================================================--

local Window =
    WindUI:CreateWindow({
        Title = "Nightfall  |  v" .. SCRIPT_VERSION,
        Icon = "moon",
        Author = "Entervalov & deflise (thanks u bro)",
        Folder = "Nightfall",
        Size = UDim2.fromOffset(580, 460),
        Transparent = true,
        Theme = "Dark",
        SideBarWidth = 170,
        HasOutline = true
    })

--========================================================--
-- TABS
--========================================================--

local MainTab =
    Window:Tab({
        Title = "Main",
        Icon = "solar:home-2-bold"
    })

local PlayerTab =
    Window:Tab({
        Title = "Player",
        Icon = "skull"
    })

local MovementTab =
    Window:Tab({
        Title = "Movement",
        Icon = "move"
    })

local CombatTab =
    Window:Tab({
        Title = "Combat",
        Icon = "crosshair"
    })

local VisualsTab =
    Window:Tab({
        Title = "Visual",
        Icon = "eye"
    })

local WorldTab =
    Window:Tab({
        Title = "World",
        Icon = "globe"
    })

local SettingsTab =
    Window:Tab({
        Title = "Settings",
        Icon = "settings"
    })

--========================================================--
-- MAIN
--========================================================--

MainTab:Section({
    Title = "Information"
})

MainTab:Paragraph({
    Title = "Nightfall",
    Desc = "Version: " .. SCRIPT_VERSION .. "\nAuthor: Entervalov & deflise\nStatus: Working"
})

MainTab:Section({
    Title = "Auto Updater"
})

MainTab:Button({
    Title = "Check for updates",
    Desc = "Check new updates on github",
    Callback = function()
        checkUpdate(false)
    end,
})

MainTab:Button({
    Title = "Reload Script",
    Desc = "Disable all features and reload script from GitHub",
    Callback = function()
        performUpdate(SCRIPT_VERSION)
    end,
})

--========================================================--
-- PLAYER
--========================================================--

PlayerTab:Section({
    Title = "Movement"
})

PlayerTab:Toggle({
    Title = "Anti-Jump",
    Desc = "Disables the jump limit",
    Value = false,
    Callback = function(State)
        Settings.AntiJump = State
        updateJump()
    end,
})

PlayerTab:Toggle({
    Title = "AutoSprint",
    Desc = "Autosprint",
    Value = false,

    Callback = function(State)

        Settings.AutoSprint = State

        updateSprint()
    end
})

PlayerTab:Slider({
    Title = "Walk Speed",
    Value = { Min = 16, Max = 150, Default = 16 },
    Callback = function(Value)
        Settings.DefaultSpeed = Value
        Settings.SprintSpeed = Value + 8
    end
})

PlayerTab:Slider({
    Title = "Jump Power",
    Value = { Min = 50, Max = 300, Default = 50 },
    Callback = function(Value)
        Settings.JumpPower = Value
    end
})

PlayerTab:Slider({
    Title = "Gravity",
    Value = { Min = 0, Max = 300, Default = 196.2 },
    Callback = function(Value)
        Settings.Gravity = Value
    end
})

--========================================================--
-- MOVEMENT
--========================================================--

MovementTab:Section({
    Title = "Underground function"
})

MovementTab:Toggle({
    Title = "Underground",
    Desc = "It saves the startup point and returns to it when turned off",
    Value = false,

    Callback = function(State)

        setUnderground(State)
    end
})

MovementTab:Keybind({
    Title = "Undergrounder (Set key)",
    Desc = "Press to assign the on/off key for the undergrounder",
    Value = Enum.KeyCode.V,
    Callback = function()
        local Character, Humanoid = getCharacter()
        if not Character or not Humanoid then return end

        local newState = not Settings.Underground
        setUnderground(newState)

    end,
})

MovementTab:Slider({
    Title = "Depth",
    Desc = "It makes you an undergrounder btw",
    Value = {
        Min = 2,
        Max = 30,
        Default = 8
    },

    Callback = function(Value)

        Settings.UndergroundDepth =
            tonumber(Value) or 8
    end
})

MovementTab:Slider({
    Title = "Speed",
    Desc = "Running speed underground",
    Value = {
        Min = 16,
        Max = 150,
        Default = 20
    },

    Callback = function(Value)

        Settings.UndergroundSpeed =
            tonumber(Value) or 20

        if Settings.Underground then
            updateSprint()
        end
    end
})

MovementTab:Section({
    Title = "Automatics"
})

MovementTab:Toggle({
    Title = "Quick Respawn",
    Desc = "Automatically respawns after death and returns to the checkpoint",
    Value = false,
    Callback = function(State)
        QuickRespawn.Set(State)
    end,
})

MovementTab:Toggle({
    Title = "Auto Criminal",
    Desc = "Automatically becomes a criminal",
    Value = false,
    Callback = function(State)
        AutoCriminal.Set(State)
    end,
})

--========================================================--
-- COMBAT
--========================================================--

CombatTab:Section({
    Title = "Hitbox Visualizer"
})

CombatTab:Toggle({
    Title = "Hitbox",
    Desc = "Increases the player’s head size so that it’s easier to deal critical damage ",
    Value = false,
    Callback = function(State)
        Settings.Hitbox = State
        if State then
            for _, Player in ipairs(Players:GetPlayers()) do
                if Player ~= LocalPlayer and isAlive(Player) then
                    createHitbox(Player)
                end
            end
        else
            for Player in pairs(HitboxObjects) do
                removeHitbox(Player)
            end
        end
    end,
})

CombatTab:Section({ 
    Title = "Anti-Shit func" 
})

CombatTab:Toggle({
    Title = "Anti-Fling",
    Desc = "It prevents you from flying off the map and stops the AC from kicking you. Fucking FFling!",
    Value = false,
    Callback = function(State)
        AntiFling.Set(State)
    end,
})

CombatTab:Toggle({
    Title = "Anti-Invis",
    Desc = "It tries to make invisible players visible so they can be killed.",
    Value = false,
    Callback = function(State)
        AntiInvis.Set(State)
    end,
})

CombatTab:Section({
    Title = "Rage"
})

CombatTab:Toggle({
    Title = "Rapid Fire",
    Desc = "Rapid Fire function",
    Value = false,
    Callback = function(State)
        Settings.RapidFire = State

        if State then
            refreshAllTools()
        else
        	
        end
    end
})

CombatTab:Slider({
    Title = "Fire Rate",
    Desc = "Changes the weapon's fire rate",
    Value = { 
        Min = 0.01, Max = 0.5, Default = 0.05 
        },
    Callback = function(Value)
        Settings.FireRate = tonumber(Value) or 0.05

        if Settings.RapidFire then
            refreshAllTools()
        end
    end
})

CombatTab:Toggle({
    Title = "Tase Bypass",
    Desc = "Bypass Taser",
    Value = false,
    Callback = function(State)
        TaseBypass.Set(State)
    end,
})

CombatTab:Toggle({
    Title = "Invisible",
    Desc = "Invisibility",
    Value = false,
    Callback = function(State)
        FEInvisible.Set(State)
    end,
})

CombatTab:Section({ 
    Title = "Target Killer" 
})

local tkPlayerList = {}
for _, p in ipairs(game.Players:GetPlayers()) do
    if p ~= LocalPlayer then
        table.insert(tkPlayerList, p.Name)
    end
end

local tkDropdown = CombatTab:Dropdown({
    Title = "Target Player",
    Desc = "Choose the player's name you want to kill",
    Values = tkPlayerList,
    Value = nil,
    Callback = function(Value)
        TargetKiller.SetTarget(Value)
    end,
})

local tkToggle = CombatTab:Toggle({
    Title = "Auto Kill Target",
    Desc = "Teleport above and shoot at the selected player",
    Value = false,
    Callback = function(State)
        if State then
            local currentTarget = TargetKiller.GetTarget()
            if not currentTarget then
                WindUI:Notify({ 
                    Title = "Error", Content = "First, choose a player", Icon = "triangle-alert", Duration = 3 
                })
                tkToggle:Set(false)
                return
            end
        end
        TargetKiller.Set(State)
    end,
})

local function refreshTkDropdown()
    local newList = {}
    for _, p in ipairs(game.Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(newList, p.Name) end
    end
    pcall(function() tkDropdown:Refresh(newList) end)
end

game.Players.PlayerAdded:Connect(function(p)
    if p ~= LocalPlayer then
        task.defer(refreshTkDropdown)
    end
end)

game.Players.PlayerRemoving:Connect(function(p)
    if p ~= LocalPlayer then
        if TargetKiller and TargetKiller.GetTargetName and TargetKiller.GetTargetName() == p.Name then
            TargetKiller.SetTarget(nil)
            if tkToggle then pcall(function() tkToggle:Set(false) end) end
        end
        task.defer(refreshTkDropdown)
    end
end)

--========================================================--
-- VISUALS
--========================================================--

VisualsTab:Section({
    Title = "XRAY"
})

VisualsTab:Toggle({
    Title = "ESP",
    Desc = "Shows players through walls",
    Value = false,

    Callback = function(State)

        Settings.ESP = State

        if not State then

            for Player in pairs(ESPObjects) do
                removeESP(Player)
            end
        end
    end
})

VisualsTab:Toggle({
    Title = "Team Colors",
    Desc = "The ESP color depends on the command",
    Value = true,

    Callback = function(State)

        Settings.TeamColors =
            State
    end
})

VisualsTab:Toggle({
    Title = "Highlight",
    Desc = "Player highlighting",
    Value = true,

    Callback = function(State)

        Settings.Highlight =
            State

        if Settings.ESP then

            for Player in ipairs(Players:GetPlayers()) do

                if Player ~= LocalPlayer then
                    createESP(Player)
                end
            end
        end
    end
})

VisualsTab:Section({ 
    Title = "Custom Weapon" 
})

VisualsTab:Toggle({
    Title = "Custom Weapon Visual",
    Desc = "Replaces the weapon model with a custom one",
    Value = false,
    Callback = function(State)
        CustomWeapon.Set(State)
    end,
})

VisualsTab:Section({ 
    Title = "Damage Visible" 
})

VisualsTab:Toggle({
    Title = "Damage Visible",
    Desc = "Shows the damage dealt to the player",
    Value = false,
    Callback = function(State)
        DamageNumbers.Set(State)
    end,
})

--========================================================--
-- WORLD
--========================================================--

WorldTab:Section({
    Title = "World"
})

WorldTab:Toggle({
    Title = "Fullbright",
    Desc = "It removes darkness, fog, and shadows",
    Value = false,

    Callback = function(State)

        Settings.Fullbright =
            State

        updateFullbright()
    end
})

WorldTab:Section({ 
    Title = "Weapon Teleports" 
})

WorldTab:Toggle({
    Title = "Auto Weapon",
    Desc = "Automatically restores your owned weapons upon death or when out of ammo",
    Value = false,
    Callback = function(State)
        AutoWeapon.Set(State)
    end,
})

WorldTab:Button({
    Title = "⚡ Refill Current Weapons",
    Desc = "Restocks ammo for the weapons currently or previously in your inventory",
    Callback = function()
        if AutoWeapon and AutoWeapon.RestockOwned then
            AutoWeapon.RestockOwned()
            WindUI:Notify({ 
			Title = "Weapons", 
			Content = "Refilled ammo for owned weapons!", 
			Icon = "swords", Duration = 3 
			})
        end
    end,
})

WorldTab:Button({
    Title = "🔫 FNFAL",
    Desc = "Take FNFAL",
    Callback = function()
        teleportToGiver(getFNFAL)
    end
})

WorldTab:Button({
    Title = "🔫 AK-47",
    Desc = "Take AK-47",
    Callback = function()
        teleportToGiver(getAK47)
    end
})

WorldTab:Button({
    Title = "🔫 Shotgun",
    Desc = "Take Shotgun",
    Callback = function()
        teleportToGiver(getShotgun)
    end
})

WorldTab:Button({
    Title = "🔫 MP5",
    Desc = "Take MP5",
    Callback = function()
        teleportToGiver(getMP5)
    end
})

WorldTab:Button({
    Title = "🔫 Sniper",
    Desc = "Take Sniper (if u have gamepass)",
    Callback = function()
        teleportToGiver(getSniper)
    end
})

WorldTab:Button({
    Title = "🔫 M4A1",
    Desc = "Take M4A1 (if u have gamepass)",
    Callback = function()
        teleportToGiver(getM4A1)
    end
})

--========================================================--
-- SETTINGS
--========================================================--

SettingsTab:Section({ 
    Title = "Killfeed" 
})

SettingsTab:Toggle({
    Title = "Killfeed Notifications",
    Desc = "Shows notifications about who killed whom",
    Value = true,
    Callback = function(State)
        KillfeedNotify = State
    end
})

SettingsTab:Section({
    Title = "Etc"
})

unloadAllFeatures = function()
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

    if TrackerGui then
        TrackerGui:Destroy()
    end

    if CharacterTrackConnection then
        CharacterTrackConnection:Disconnect()
        CharacterTrackConnection = nil
    end

    if DeathConnection then
        DeathConnection:Disconnect()
        DeathConnection = nil
    end

    if UndergroundConnection then
        UndergroundConnection:Disconnect()
        UndergroundConnection = nil
    end

    UndergroundSavedCFrame = nil

    if Modules and Modules.UnloadAll then
        Modules.UnloadAll()
    end
    print("[Nightfall] All functions unloaded.")
end

SettingsTab:Button({
    Title = "Unload Nightfall",
    Callback = function()
        unloadAllFeatures()
    end
})

pcall(function()
    if Window.SelectTab then
        Window:SelectTab(1)
    elseif MainTab and MainTab.Select then
        MainTab:Select()
    end
end)

--========================================================--
-- INITIALIZATION
--========================================================--

task.spawn(function()
    task.wait(0.2)
    pcall(function()
        if Window.SelectTab then
            Window:SelectTab(1)
        elseif MainTab and MainTab.Select then
            MainTab:Select()
        end
    end)

    task.wait(0.8)

    updateFullbright()
    updateJump()
    updateSprint()

    if Settings.ESP then
        updateESP()
    end

    if Settings.Hitbox then
        updateHitboxes()
    end

    task.spawn(function()
        task.wait(2)
        checkUpdate(true)
        while true do
            task.wait(300)
            checkUpdate(true)
        end
    end)

end)

print("[Nightfall] Loaded.")