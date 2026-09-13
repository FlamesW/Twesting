Window:AddTabLabel('Main')

local Dashboard = Window:AddTab({
    Icon = "squares-grid-plus",
    Name = "Dashboard",
})

local Movement = Dashboard:AddSection({ Name = "Movement", Position = "left"  })
local Vision = Dashboard:AddSection({ Name = "Vision", Position = "right" })
local Victim = Dashboard:AddSection({ Name = "Victim", Position = "right" })
local Info = Dashboard:AddSection({ Name = "Statistics", Position = "right" })

Script:FlightConfig({ SpeedMax = 1500, SpeedControls = { Enabled = false } })

local FlightLabel = Movement:AddLabel("Universal Flight")

FlightLabel:ToolTip(
    "Controls:\n" ..
    "  W / A / S / D  |  Move\n" ..
    "  Space |  Up\n" ..
    "  Left Ctrl |  Down\n" ..
    "  Plus (+) / Minus (-) |  Adjust speed"
)

local DefSpeed = 70

FlightLabel:AddToggle({
    Default = false,
    Flag = "Flight",
    Callback = function(Value)
        Script:Flight(Value)
    end,
})
Script:SetFlightSpeed(DefSpeed)

FlightLabel:AddOption():AddLabel("Flight Speed"):AddSlider({
    Default = DefSpeed,
    Min = 10,
    Max = 1500,
    Rounding = 0,
    Size = 100,
    Flag = "Flight_Speed",
    Callback = function(Value)
        Script:SetFlightSpeed(Value)
    end,
})

Script:WhileLoop(0.001, function(self)
    local Slider = NeverLose.Flags["Flight_Speed"]
    if not Slider then return end

    local Step = 1.5
    local Speed = Slider:GetValue()

    if self:IsKeyPressed(Enum.KeyCode.Equals) or self:IsKeyPressed(Enum.KeyCode.KeypadPlus) then
        Slider:SetValue(math.min(Speed + Step, 1500))
    elseif self:IsKeyPressed(Enum.KeyCode.Minus) or self:IsKeyPressed(Enum.KeyCode.KeypadMinus) then
        Slider:SetValue(math.max(Speed - Step, 10))
    end
end, "Flight_Controls", false)


local SpeedLabel = Movement:AddLabel("Walkspeed")

SpeedLabel:AddToggle({
    Default = false,
    Flag = "Walkspeed_Bypass",
    Callback = function(Value)
        Script:BypassWS(Value, NeverLose.Flags["Walkspeed_Speed"]:GetValue())
    end,
})

local SpeedOptions = SpeedLabel:AddOption()

SpeedOptions:AddLabel("Speed"):AddSlider({
    Default = 7,
    Min = 1,
    Max = 25,
    Rounding = 0,
    Flag = "Walkspeed_Speed",
    Callback = function(Value)
        if Script.WSData and Script.WSData.Active then
            Script:SetBypassedWS(Value)
        end
    end,
})

local JumpLabel = Movement:AddLabel("JumpPower")

JumpLabel:AddToggle({
    Default = false,
    Flag = "Jump_Bypass",
    Callback = function(Value)
        Script:BypassJP(Value, NeverLose.Flags["Jump_Power"]:GetValue())
    end,
})

local JumpOptions = JumpLabel:AddOption()

JumpOptions:AddLabel("Power"):AddSlider({
    Default = 15,
    Min = 10,
    Max = 250,
    Rounding = 0,
    Flag = "Jump_Power",
    Callback = function(Value)
        if Script.JPData and Script.JPData.Active then
            Script:SetBypassedJP(Value)
        end
    end,
})

Movement:AddLabel("Noclip"):AddToggle({
    Default = false,
    Flag = "Noclip",
    Callback = function(Value)
        if Value then
            Script:WhileLoop(0.01, function(self)
                self:Noclip(0.5)
            end, "Noclip_Loop")
        else
            Script:ForceStop("Noclip_Loop")
            Script:StopClip()
        end
    end,
})

Movement:AddLabel("Infinite Jump"):AddToggle({
    Default = false,
    Flag = "Infinite_Jump",
    Callback = function(Value)
        Script:InfiniteJump(Value)
    end,
})

Movement:AddLabel("Touch Fling"):AddToggle({
    Default = false,
    Flag = "Touch_Fling",
    Callback = function(Value)
        Script:TouchFling(Value)
    end,
})

local Auto_Fling_Label = Movement:AddLabel("Autonomous Fling")

Auto_Fling_Label:AddToggle({
    Default = false, Flag = "Auto_Fling",
    Callback = function(Value)
        if Value then
            Script:WhileLoop(0.75, function(self)
                local Target = self:GetClosestPlayer(NeverLose.Flags["Auto_Fling_Range"]:GetValue())
                if Target then self:Fling(Target) end
            end, "Auto_Fling_Loop")
        else
            Script:ForceStop("Auto_Fling_Loop")
        end
    end,
})

Auto_Fling_Label:AddOption():AddLabel("Range"):AddSlider({
    Default = 15, Min = 5, Max = 70, Flag = "Auto_Fling_Range", Size = 100,
    Callback = function() end,
})

local Gravity_Label = Movement:AddLabel("Universal Gravity")

Gravity_Label:AddToggle({
    Default = false,
    Flag = "Movement_Gravity",
    Callback = function(Value)
        if Value then
            Script.OriginalGravity = workspace.Gravity
            Script:SetGravity(NeverLose.Flags["Movement_Gravity_Value"]:GetValue())
        else
            Script:SetGravity(Script.OriginalGravity or 196.2)
        end
    end,
})

Gravity_Label:AddOption():AddLabel("Gravity"):AddSlider({
    Default = 196,
    Min = 0,
    Max = 500,
    Rounding = 0,
    Size = 120,
    Flag = "Movement_Gravity_Value",
    Callback = function(Value)
        if NeverLose.Flags["Movement_Gravity"] and NeverLose.Flags["Movement_Gravity"]:GetValue() then
            Script:SetGravity(Value)
        end
    end,
})

Movement:AddLabel("TP Tool"):AddToggle({
    Default = false,
    Flag = "Movement_TPTool",
    Callback = function(Value)
        local LP = Script.LocalPlayer
        local Backpack = LP:FindFirstChild("Backpack")

        if Value then
            if not Backpack then
                return Logging.new("triangle-exclamation", "No backpack!", 3.5)
            end

            if Backpack:FindFirstChild("TP_Tool") or (LP.Character and LP.Character:FindFirstChild("TP_Tool")) then
                return Logging.new("triangle-exclamation", "Already have it!", 3.5)
            end

            local Tool = Instance.new("Tool")
            Tool.Name = "@TP_Tool"
            Tool.RequiresHandle = true
            Tool.CanBeDropped = false
            Tool.ToolTip = "Click to teleport to your mouse position"

            local Handle = Instance.new("Part")
            Handle.Name = "Handle"
            Handle.Size = Vector3.new(1, 1, 1)
            Handle.Transparency = 1
            Handle.CanCollide = false
            Handle.Massless = true
            Handle.Parent = Tool

            Tool.Activated:Connect(function()
                local Char = LP.Character
                if not Char then return end

                local Root = Char:FindFirstChild("HumanoidRootPart")
                if not Root then return end

                local Mouse = LP:GetMouse()
                if not Mouse or not Mouse.Hit then
                    return Logging.new("triangle-exclamation", "No mouse target!", 2)
                end

                local RawTarget = Mouse.Hit.Position

                local Params = RaycastParams.new()
                Params.FilterDescendantsInstances = { Char }
                Params.FilterType = Enum.RaycastFilterType.Exclude

                local Ray = workspace:Raycast(
                    RawTarget + Vector3.new(0, 50, 0),
                    Vector3.new(0, -300, 0),
                    Params
                )

                if not Ray then
                    return Logging.new("triangle-exclamation", "No ground below - TP cancelled", 2.5)
                end

                local FallHeight = workspace.FallenPartsDestroyHeight or -500
                if Ray.Position.Y <= FallHeight + 10 then
                    return Logging.new("triangle-exclamation", "Void detected - TP cancelled", 2.5)
                end

                local HitInst = Ray.Instance
                if HitInst then
                    if not HitInst.CanCollide then
                        return Logging.new("triangle-exclamation", "Clicked non-solid surface", 2.5)
                    end
                    if HitInst:IsA("BasePart") and HitInst.Transparency >= 1 and HitInst.CanCollide == false then
                        return Logging.new("triangle-exclamation", "Clicked invisible part", 2.5)
                    end
                    local NameLower = string.lower(HitInst.Name)
                    if NameLower:find("void") or NameLower:find("lava") or NameLower:find("kill") then
                        return Logging.new("triangle-exclamation", "Clicked a hazard", 2.5)
                    end
                    if Ray.Normal.Y < 0.5 then
                        return Logging.new("triangle-exclamation", "Clicked a wall - TP cancelled", 2.5)
                    end
                end

                local LandPos = Ray.Position + Vector3.new(0, 3, 0)
                local Look = Root.CFrame.LookVector
                Root.CFrame = CFrame.lookAt(LandPos, LandPos + Look)

                Logging.new("hammer-code", "Teleported!", 2)
            end)

            Tool.Parent = Backpack
            Logging.new("hammer-code", "TP Tool forged!", 3.5)

            Script.TPTool = Tool
        else
            local Char = LP.Character

            if Backpack then
                local T1 = Backpack:FindFirstChild("@TP_Tool")
                if T1 then T1:Destroy() end
            end

            if Char then
                local T2 = Char:FindFirstChild("@TP_Tool")
                if T2 then T2:Destroy() end
            end

            Script.TPTool = nil
            Logging.new("triangle-exclamation", "TP Tool sealed.", 3)
        end
    end,
})


local HipHeight_Label = Movement:AddLabel("Hip Height")

HipHeight_Label:AddToggle({
    Default = false,
    Flag = "Movement_HipHeight",
    Callback = function(Value)
        if Value then
            Script.OriginalHipHeight = Script:GetHumanoid() and Script:GetHumanoid().HipHeight or 2
            Script:SetHipHeight(NeverLose.Flags["Movement_HipHeight_Value"]:GetValue())
        else
            Script:SetHipHeight(Script.OriginalHipHeight or 2)
        end
    end,
})

HipHeight_Label:AddOption():AddLabel("Height"):AddSlider({
    Default = 2,
    Min = -10,
    Max = 20,
    Rounding = 1,
    Size = 100,
    Flag = "Movement_HipHeight_Value",
    Callback = function(Value)
        if NeverLose.Flags["Movement_HipHeight"] and NeverLose.Flags["Movement_HipHeight"]:GetValue() then
            Script:SetHipHeight(Value)
        end
    end,
})

local AntiTeleport = Movement:AddLabel("Anti Teleport")

AntiTeleport:ToolTip(
    "Prevents client-side teleports from moving you\n" ..
    "Blocks scripts that set your HumanoidRootPart.CFrame"
)

AntiTeleport:AddToggle({
    Default = false,
    Flag = "Anti_CFrame_TP",
    Callback = function(Value)
        Script:AntiCFrameTeleport(Value)
    end,
})

Movement:AddLabel("Anti Freefall"):AddToggle({
    Default = false,
    Flag = "Anti_Freefall",
    Callback = function(Value)
        Script:AntiVoid1(Value)
    end,
})

Movement:AddButton({
    Icon = "person-standing",
    Name = "Reset Character",
    Callback = function()
        Script:ForceReset()
        Logging.new("person-standing", "Character reset", 3.5)
    end,
})

local FOVLabel = Vision:AddLabel("Field of View")

FOVLabel:AddToggle({
    Default = false,
    Flag = "Vision_FOV",
    Callback = function(Value)
        if Value then
            Script:SetFOV(NeverLose.Flags["Field_of_View"]:GetValue())
        else
            Script:SetFOV(70)
        end
    end,
})

local FOVOptions = FOVLabel:AddOption()

FOVOptions:AddLabel("FOV"):AddSlider({
    Default = 90,
    Min = 40,
    Max = 130,
    Rounding = 0,
    Flag = "Field_of_View",
    Callback = function(Value)
        if NeverLose.Flags["Vision_FOV"] and NeverLose.Flags["Vision_FOV"]:GetValue() then
            Script:SetFOV(Value)
        end
    end,
})

local Look_Label = Vision:AddLabel("Look At Nearest")

Look_Label:AddToggle({
    Default = false,
    Flag = "Vision_LookAtNearest",
    Callback = function(Value)
        if Value then
            Script:WhileLoop(0.01, function(self)
                local Cam = self.CurrentCamera
                if not Cam then return end

                local Range = NeverLose.Flags["Vision_LookAtNearest_Range"]:GetValue()
                local Target, Dist = self:GetClosestPlayer(Range)
                if not Target or not Target.Character then return end

                local Head = Target.Character:FindFirstChild("Head")
                    or Target.Character:FindFirstChild("HumanoidRootPart")
                if not Head then return end

                Cam.CFrame = CFrame.lookAt(Cam.CFrame.Position, Head.Position)
            end, "LookAtNearest_Loop")
        else
            Script:ForceStop("LookAtNearest_Loop")
        end
    end,
})

Look_Label:AddOption():AddLabel("Range"):AddSlider({
    Default = 15,
    Min = 10,
    Max = 70,
    Rounding = 0,
    Size = 120,
    Flag = "Vision_LookAtNearest_Range",
    Callback = function() end,
})

Vision:AddLabel("X-Ray Vision"):AddToggle({
    Default = false,
    Flag = "Vision_XRay",
    Callback = function(Value)
        Script:XRay(Value)
    end,
})


Vision:AddLabel("Third Person"):AddToggle({
    Default = false,
    Flag = "Vision_ThirdPerson",
    Callback = function(Value)
        Script:ThirdPerson(Value)
    end,
})

local Fullbright_State = false
local FB_Originals = nil

Vision:AddLabel("Fullbright"):AddToggle({
    Default = false,
    Flag = "Vision_Fullbright",
    Callback = function(Value)
        local Lighting = game:GetService("Lighting")

        if Value then
            if Fullbright_State then return end

            FB_Originals = {
                Ambient = Lighting.Ambient,
                OutdoorAmbient = Lighting.OutdoorAmbient,
                Brightness = Lighting.Brightness,
                GlobalShadows = Lighting.GlobalShadows,
                ClockTime = Lighting.ClockTime,
                FogEnd = Lighting.FogEnd,
                FogStart = Lighting.FogStart,
            }

            Lighting.Ambient = Color3.fromRGB(178, 178, 178)
            Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
            Lighting.Brightness = 3
            Lighting.GlobalShadows = false
            Lighting.ClockTime = 14
            Lighting.FogEnd = 1e9
            Lighting.FogStart = 1e9

            Fullbright_State = true
        else
            if not Fullbright_State then return end

            if FB_Originals then
                Lighting.Ambient = FB_Originals.Ambient
                Lighting.OutdoorAmbient = FB_Originals.OutdoorAmbient
                Lighting.Brightness = FB_Originals.Brightness
                Lighting.GlobalShadows = FB_Originals.GlobalShadows
                Lighting.ClockTime = FB_Originals.ClockTime
                Lighting.FogEnd = FB_Originals.FogEnd
                Lighting.FogStart = FB_Originals.FogStart

                FB_Originals = nil
            end

            Fullbright_State = false
        end
    end,
})

-- // @ESP.luau
local function Build_ESP_Settings(Model, Color, IsPlayer, Prefix)
    local TracerFrom = NeverLose.Flags[Prefix .. "_Tracer_From"]
    TracerFrom = TracerFrom and TracerFrom:GetValue() or "Mouse"

    local TextSize = NeverLose.Flags[Prefix .. "_TextSize"]
    TextSize = TextSize and TextSize:GetValue() or 17

    return {
        Name = "",
        Model = Model,
        ESPType = "Highlight",
        MaxDistance = 5000,

        Color = Color,
        TextSize = TextSize,
        StudsOffset = Vector3.new(0, 2, 0),

        FillColor = Color,
        OutlineColor = Color,
        FillTransparency = 0.5,
        OutlineTransparency = 0,

        Thickness = 1,
        Transparency = 0.65,
        SurfaceColor = Color,

        Tracer = { Enabled = true, Color = Color, Thickness = 2, Transparency = 0, From = TracerFrom },
        Arrow = { Enabled = true, Color = Color, CenterOffset = 300 },
        Box2D = { Enabled = true, Color = Color, Thickness = 1.5, Transparency = 0, Filled = false },
        Box3D = { Enabled = true, Color = Color, Thickness = 1, Transparency = 0 },
        Skeleton = { Enabled = true, Color = Color, Thickness = 1, Transparency = 0 },
    }
end

local function Recolor_Handles(Handles, Color)
    if not Handles then return end
    for _, Instance in pairs(Handles) do
        if Instance and Instance.SetEveryColor then
            pcall(Instance.SetEveryColor, Instance, Color, true)
        end
    end
end

local function Set_Component(Handles, Component, Value)
    if not Handles then return end
    for _, Instance in pairs(Handles) do
        if not Instance or Instance.Deleted or not Instance.CurrentSettings then continue end

        local Setting = Instance.CurrentSettings[Component]
        if Setting == nil then continue end

        if typeof(Setting) == "table" then
            Setting.Enabled = Value
        else
            Instance.CurrentSettings[Component] = Value
        end
    end
end

Script.EspCache = Script.EspCache or { Players = {}, NPCs = {} }

local function Sync_ESP_State(Instance, Prefix, IsPlayer)
    if not Instance or Instance.Deleted or not Instance.CurrentSettings then return end

    local function Get(Key)
        local Flag = NeverLose.Flags[Prefix .. "_" .. Key]
        return Flag and Flag:GetValue() or false
    end
    local CS = Instance.CurrentSettings

    if CS.Tracer then CS.Tracer.Enabled = Get("Tracer") end
    if CS.Arrow then CS.Arrow.Enabled = Get("Arrow") end
    if CS.Box2D then CS.Box2D.Enabled = Get("Box2D") end
    if CS.Box3D then CS.Box3D.Enabled = Get("Box3D") end
    if CS.Skeleton then CS.Skeleton.Enabled = IsPlayer and Get("Skeleton") end

    local TracerFrom = NeverLose.Flags[Prefix .. "_Tracer_From"]
    if CS.Tracer and TracerFrom then CS.Tracer.From = string.lower(tostring(TracerFrom:GetValue())) end

    CS.FillTransparency = Get("Highlight") and 0.5 or 1
    CS.OutlineTransparency = Get("Highlight") and 0 or 1
    CS.Name = Get("Name") and CS.Model.Name or ""

    local TextSize = NeverLose.Flags[Prefix .. "_TextSize"]
    if TextSize then CS.TextSize = TextSize:GetValue() end
end

-- // @Shared Options Builder
local function Add_Options(Parent, Prefix, IsPlayer)
    local Options = Parent:AddOption()
    local Handles = Prefix == "ESP_Players" and Script.EspCache.Players or Script.EspCache.NPCs

    Options:AddLabel("Color"):AddColorPicker({
        Default = Color3.fromRGB(80, 180, 255),
        Flag = Prefix .. "_Color",
        OnColor = function(Value)
            local Team_Flag = NeverLose.Flags[Prefix .. "_TeamColor"]
            if Team_Flag and Team_Flag:GetValue() then return end
            Recolor_Handles(Handles, Value)
        end,
        Callback = function() end,
    })

    Options:AddLabel("Team Color"):AddToggle({
        Default = false, Flag = Prefix .. "_TeamColor",
        Callback = function(Value)
            if not Handles then return end
            local Picker = NeverLose.Flags[Prefix .. "_Color"]

            for Key, Instance in pairs(Handles) do
                if not Instance or Instance.Deleted or not Instance.SetEveryColor then continue end

                local Color = (Picker and Picker:GetValue()) or Color3.fromRGB(80, 180, 255)

                if Value then
                    local Player = typeof(Key) == "Instance" and Key:IsA("Model")
                        and Script.Players:GetPlayerFromCharacter(Key)
                    if Player and Player.Team then
                        Color = Player.Team.TeamColor.Color
                    end
                end

                pcall(Instance.SetEveryColor, Instance, Color, true)
            end
        end,
    })

    Options:AddLabel("Highlight"):AddToggle({
        Default = true, Flag = Prefix .. "_Highlight",
        Callback = function(Value)
            if not Handles then return end
            for _, Instance in pairs(Handles) do
                if Instance and not Instance.Deleted and Instance.CurrentSettings then
                    Instance.CurrentSettings.FillTransparency = Value and 0.5 or 1
                    Instance.CurrentSettings.OutlineTransparency = Value and 0 or 1
                end
            end
        end,
    })

    Options:AddLabel("Tracer"):AddToggle({
        Default = true, Flag = Prefix .. "_Tracer",
        Callback = function(Value) Set_Component(Handles, "Tracer", Value) end,
    })

    Options:AddLabel("Tracer From"):AddDropdown({
        Default = "Mouse",
        Values = { "Mouse", "Top", "Bottom", "Center" },
        Multi = false,
        Flag = Prefix .. "_Tracer_From",
        Callback = function(Value)
            if not Handles then return end
            for _, Instance in pairs(Handles) do
                if Instance and not Instance.Deleted and Instance.CurrentSettings.Tracer then
                    Instance.CurrentSettings.Tracer.From = string.lower(tostring(Value))
                end
            end
        end,
        AutoUpdate = false,
        Size = 100,
    })

    Options:AddLabel("Arrow"):AddToggle({
        Default = false, Flag = Prefix .. "_Arrow",
        Callback = function(Value) Set_Component(Handles, "Arrow", Value) end,
    })

    Options:AddLabel("Box 2D"):AddToggle({
        Default = true, Flag = Prefix .. "_Box2D",
        Callback = function(Value) Set_Component(Handles, "Box2D", Value) end,
    })

    Options:AddLabel("Box 3D"):AddToggle({
        Default = true, Flag = Prefix .. "_Box3D",
        Callback = function(Value) Set_Component(Handles, "Box3D", Value) end,
    })

    if IsPlayer then
        Options:AddLabel("Skeleton"):AddToggle({
            Default = true, Flag = Prefix .. "_Skeleton",
            Callback = function(Value) Set_Component(Handles, "Skeleton", Value) end,
        })
    end

    Options:AddLabel("Show Name"):AddToggle({
        Default = false, Flag = Prefix .. "_Name",
        Callback = function(Value)
            if not Handles then return end
            for _, Instance in pairs(Handles) do
                if Instance and not Instance.Deleted and Instance.CurrentSettings.Model then
                    Instance.CurrentSettings.Name = Value and Instance.CurrentSettings.Model.Name or ""
                end
            end
        end,
    })

    Options:AddLabel("Show Distance"):AddToggle({
        Default = true, Flag = Prefix .. "_Distance",
        Callback = function()
            local Flag = NeverLose.Flags[Prefix .. "_Distance"]
            Script:ESP_SetGlobal({ Distance = Flag and Flag:GetValue() or false })
        end,
    })

    Options:AddLabel("Text Size"):AddSlider({
        Default = 17, Min = 8, Max = 40, Decimals = 0,
        Flag = Prefix .. "_TextSize",
        Callback = function(Value)
            if not Handles then return end
            for _, Instance in pairs(Handles) do
                if Instance and not Instance.Deleted then
                    Instance.CurrentSettings.TextSize = Value
                end
            end
        end,
    })
end

-- // @ESP Players
local Players_State = false
local Players_EspLabel = Vision:AddLabel("ESP Players")

local function Tick_Players()
    if not Players_State then return end

    local Color = NeverLose.Flags["ESP_Players_Color"]:GetValue()
    local Handles = Script.EspCache.Players

    for _, LPlayer in ipairs(Script:GetPlayers(false)) do
        local Char = LPlayer.Character
        if not Char then continue end

        local Existing = Handles[Char]
        if Existing and not Existing.Deleted then continue end

        local Instance = Script:ESP_Add(Build_ESP_Settings(Char, Color, true, "ESP_Players"))
        Sync_ESP_State(Instance, "ESP_Players", true)

        Handles[Char] = Instance
    end

    for Char, Instance in pairs(Handles) do
        if not Char.Parent or (Instance and Instance.Deleted) then
            if Instance and Instance.Destroy then pcall(Instance.Destroy, Instance) end
            Handles[Char] = nil
        end
    end

    if NeverLose.Flags["ESP_Players_TeamColor"] and NeverLose.Flags["ESP_Players_TeamColor"]:GetValue() then
        for Char, Instance in pairs(Handles) do
            if not Instance or Instance.Deleted or not Instance.SetEveryColor then continue end

            local Player = Script.Players:GetPlayerFromCharacter(Char)
            if Player and Player.Team then
                pcall(Instance.SetEveryColor, Instance, Player.Team.TeamColor.Color, true)
            end
        end
    end
end

Players_EspLabel:AddToggle({
    Default = false,
    Flag = "Vision_ESP_Players",
    Callback = function(Value)
        Players_State = Value

        if Value then
            Tick_Players()
        else
            for Char, Instance in pairs(Script.EspCache.Players) do
                if Instance and Instance.Destroy then pcall(Instance.Destroy, Instance) end
                Script.EspCache.Players[Char] = nil
            end
        end
    end,
})

Add_Options(Players_EspLabel, "ESP_Players", true)
Script:WhileLoop(1, Tick_Players, "Vision_ESP_Players")

-- // @ESP NPCs
local NPCs_State = false
local NPCs_EspLabel = Vision:AddLabel("ESP NPCs")

local function Tick_NPCs()
    if not NPCs_State then return end

    local Color = NeverLose.Flags["ESP_NPCs_Color"]:GetValue()
    local Handles = Script.EspCache.NPCs

    for _, Model in ipairs(workspace:GetDescendants()) do
        if not Model:IsA("Model") then continue end
        if not Script:GetNPC(Model) then continue end

        local Existing = Handles[Model]
        if Existing and not Existing.Deleted then continue end

        local Instance = Script:ESP_Add(Build_ESP_Settings(Model, Color, false, "ESP_NPCs"))
        Sync_ESP_State(Instance, "ESP_NPCs", false)

        Handles[Model] = Instance
    end

    for Model, Instance in pairs(Handles) do
        if not Model.Parent or (Instance and Instance.Deleted) then
            if Instance and Instance.Destroy then pcall(Instance.Destroy, Instance) end
            Handles[Model] = nil
        end
    end
end

NPCs_EspLabel:AddToggle({
    Default = false,
    Flag = "Vision_ESP_NPCs",
    Callback = function(Value)
        NPCs_State = Value

        if Value then
            Tick_NPCs()
        else
            for Model, Instance in pairs(Script.EspCache.NPCs) do
                if Instance and Instance.Destroy then pcall(Instance.Destroy, Instance) end
                Script.EspCache.NPCs[Model] = nil
            end
        end
    end,
})

Add_Options(NPCs_EspLabel, "ESP_NPCs", false)
Script:WhileLoop(4.75, Tick_NPCs, "Vision_ESP_NPCs")

local Selected_Victim, UpdatingFlag = nil, false
local SpectateToggle

local function Format_Player(P)
    return P.DisplayName .. " (@" .. P.Name .. ")"
end

local function GetPlayerValues()
    local List = {}
    for _, P in ipairs(Script.Players:GetPlayers()) do
        if P ~= Script.LocalPlayer then
            table.insert(List, Format_Player(P))
        end
    end
    return List
end

local Player_Dropdown = Victim:AddLabel("Player"):AddDropdown({
    Default = "None",
    Values = GetPlayerValues(),
    Multi = false,
    AutoUpdate = true,
    Size = 130,
    Callback = function(Value)
        if UpdatingFlag then return end

        for _, Person in ipairs(Script.Players:GetPlayers()) do
            if Format_Player(Person) == Value then

                if Script:IsSpectating() then
                    Script:StopSpectate()
                end

                if SpectateToggle and SpectateToggle:GetValue() then
                    SpectateToggle:SetValue(false)
                end

                Selected_Victim = Person
                break
            end
        end
    end,
})

local Spectate_Label = Victim:AddLabel("Spectate")

SpectateToggle = Spectate_Label:AddToggle({
    Default = false,
    Callback = function(Value)
        if Value then
            if not Selected_Victim then
                return
            end
            Script:Spectate(Selected_Victim)
        else
            Script:StopSpectate()
        end
    end,
})

Script:WhileLoop(1, function()
    local NewValues = GetPlayerValues()
    local Current_Values = Player_Dropdown.Values or {}

    local Changed = #NewValues ~= #Current_Values
    if not Changed then
        for i = 1, #NewValues do
            if NewValues[i] ~= Current_Values[i] then
                Changed = true
                break
            end
        end
    end

    if Changed then
        UpdatingFlag = true
        Player_Dropdown:SetValues(NewValues)

        if Selected_Victim and not Selected_Victim.Parent then
            Selected_Victim = nil
            Player_Dropdown:SetValue("None")

            if Script:IsSpectating() then
                Script:StopSpectate()
            end

            if SpectateToggle and SpectateToggle:GetValue() then
                SpectateToggle:SetValue(false)
            end
        end

        UpdatingFlag = false
    end
end, "Player_Dropdown_Refresh")

Victim:AddButton({
    Icon = "person-teleport",
    Name = "TP 5 Studs Behind",
    Callback = function()
        if not Selected_Victim or not Selected_Victim.Character then
            return Logging.new("triangle-exclamation", "No player selected!", 3.5)
        end

        local Char = Selected_Victim.Character
        local Root = Char:FindFirstChild("HumanoidRootPart")
        local MyRoot = Script:GetRoot()

        if not Root or not MyRoot then
            return
        end

        MyRoot.CFrame = Root.CFrame * CFrame.new(0, 0, 5)
        Logging.new("person-teleport", "TP'd behind " .. Selected_Victim.DisplayName, 3.5)
    end,
})

Victim:AddButton({
    Icon = "person-falling",
    Name = "Fling",
    Callback = function()
        if not Selected_Victim then
            return Logging.new("triangle-exclamation", "No player selected!", 3.5)
        end

        local Success, Name = Script:Fling(Selected_Victim)
        if Success then
            Logging.new("person-falling", "Flung " .. tostring(Name or Selected_Victim.DisplayName), 3.5)
        else
            Logging.new("triangle-exclamation", "Fling failed!", 3.5)
        end
    end,
})

local Stats_Label = Victim:AddLabel("Speed: 0 MPH\nMoving: false")
Info:AddLabel("Executor: " .. tostring(Script:GetExecutor()))

local L_Health = Info:AddLabel("Health: ...")
local L_Speed = Info:AddLabel("Speed: ... MPH")
local L_Time = Info:AddLabel("Local Time: ...")
local L_Date = Info:AddLabel("Date: ...")

Script:WhileLoop(0.1, function(self)
    local MPH, Moving = 0, false

    if Selected_Victim then
        MPH = self:CalculateSpeed("MPH", 1, Selected_Victim)
        if Selected_Victim.Character then
            Moving = self:IsMoving(Selected_Victim.Character)
        end
    end

    Stats_Label:SetText(string.format("Speed: %s MPH\nMoving: %s", tostring(MPH), Moving and "true" or "false"))

    local Hum = self:GetHumanoid()

    local Health = Hum and string.format("%d/%d", math.floor(Hum.Health), math.floor(Hum.MaxHealth)) or "0/0"
    L_Health:SetText("Health: " .. Health)

    L_Speed:SetText("Speed: " .. tostring(self:CalculateSpeed("MPH", 1)) .. " MPH")

    L_Time:SetText("Local Time: " .. tostring(self:Time("%H:%M:%S")))
    L_Date:SetText("Date: " .. tostring(self:Date("%Y/%m/%d")))
end, "Info_Statistics")
