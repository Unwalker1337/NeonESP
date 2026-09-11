--!nocheck

















local NeonESP = {}
NeonESP.__index = NeonESP
NeonESP.Version = "2.0"


local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Camera = workspace.CurrentCamera 


local floor, clamp, sin, exp, sqrt, tan, rad =
    math.floor, math.clamp, math.sin, math.exp, math.sqrt, math.tan, math.rad
local huge, format = math.huge, string.format
local V2, V3 = Vector2, Vector3
local BLACK = Color3.new(0, 0, 0)


local RENDER_PRIORITY = Enum.RenderPriority.Camera.Value + 1 
local TOOL_REFRESH    = 30    
local CHAMS_REFRESH   = 10    
local BOX_REFRESH     = 45    
local SNAP_FAR        = 60    
local SNAP_NEAR       = 3     
local MAX_PIXELS      = 2500  
local ID              = 0     

local DrawingLib
pcall(function() DrawingLib = Drawing end)
if not DrawingLib and getgenv then
    pcall(function() DrawingLib = getgenv().Drawing end)
end


local function deepCopy(orig)
    local copy = {}
    for k, v in pairs(orig) do
        copy[k] = type(v) == "table" and deepCopy(v) or v
    end
    return copy
end

local function makeDrawing(class, props)
    if not DrawingLib then return nil end
    local ok, d = pcall(DrawingLib.new, class)
    if not ok or not d then return nil end
    pcall(function()
        for k, v in pairs(props) do d[k] = v end
    end)
    return d
end

local function removeDrawing(d)
    if d then pcall(function() d:Remove() end) end
end


local BONE_CONNECTIONS = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
}
local NBONES = #BONE_CONNECTIONS

local CORNER_OFFSETS = {
    V3.new(-1, -1, -1), V3.new(1, -1, -1), V3.new(1, 1, -1), V3.new(-1, 1, -1),
    V3.new(-1, -1,  1), V3.new(1, -1,  1), V3.new(1, 1,  1), V3.new(-1, 1,  1),
}

local EDGES_3D = {
    {1,2}, {2,3}, {3,4}, {4,1},
    {5,6}, {6,7}, {7,8}, {8,5},
    {1,5}, {2,6}, {3,7}, {4,8},
}


local CORNER_SIGNS = {
    {0, 0,  1,  1},
    {1, 0, -1,  1},
    {0, 1,  1, -1},
    {1, 1, -1, -1},
}


local DEFAULT_CONFIG = {
    Enabled = true,
    TeamCheck = false,
    VisibilityCheck = false,
    MaxDistance = 2000,

    Rainbow = { Enabled = false, Speed = 2, PerPlayer = false },

    UseTeamColor = false,

    
    Smooth = { Enabled = true, Speed = 0.5 },

    Glow = { Enabled = true, Speed = 1.6, MinAlpha = 0.75, MaxAlpha = 0.95 },

    DistanceFade = {
        Enabled = true, StartDistance = 500, EndDistance = 2000, MinAlpha = 0.45,
    },

    Box = {
        Enabled = true, Mode = "Corner",
        Color = Color3.fromRGB(0, 180, 255),
        SecondaryColor = Color3.fromRGB(80, 120, 200),
        Thickness = 1.25, Transparency = 0.85,
        CornerLength = 0, Rainbow = false,
    },

    Name = {
        Enabled = true, Color = Color3.fromRGB(255, 255, 255), Size = 17,
        Font = Enum.Font.GothamBold, Outline = true, UseDisplayName = true,
        Prefix = "", Suffix = "", ShowHealth = false, ShowDistance = false,
        MaxLength = 32, Rainbow = false,
    },

    HealthBar = {
        Enabled = true, Width = 3, Offset = 6, Position = "Left",
        HighColor = Color3.fromRGB(0, 255, 120), LowColor = Color3.fromRGB(255, 40, 40),
        SmoothTransition = true, ShowText = false,
        TextColor = Color3.fromRGB(255, 255, 255), TextSize = 13, Rainbow = false,
    },

    HeadDot = {
        Enabled = true, Color = Color3.fromRGB(255, 255, 255),
        OutlineColor = Color3.fromRGB(40, 40, 40), Size = 5, Transparency = 0.85,
        Outline = true, Rainbow = false,
    },

    Distance = {
        Enabled = true, Color = Color3.fromRGB(180, 180, 200), Size = 14,
        Font = Enum.Font.Gotham, Suffix = "m", Rainbow = false,
    },

    Tracers = {
        Enabled = false, Origin = "Bottom",
        Color = Color3.fromRGB(0, 180, 255), SecondaryColor = Color3.fromRGB(200, 220, 255),
        Thickness = 1, Transparency = 0.5, Rainbow = false,
    },

    Skeleton = {
        Enabled = false, Color = Color3.fromRGB(160, 170, 200),
        Thickness = 1, Transparency = 0.8, Rainbow = false,
    },

    ToolESP = {
        Enabled = false, Color = Color3.fromRGB(255, 220, 50), Size = 12,
        Font = Enum.Font.Gotham, Brackets = true, Rainbow = false,
    },

    ToolHighlight = {
        Enabled = false, FillColor = Color3.fromRGB(255, 220, 50), FillTransparency = 0.5,
        OutlineColor = Color3.fromRGB(255, 255, 255), OutlineTransparency = 0.3,
    },

    Chams = {
        Enabled = false, FillColor = Color3.fromRGB(140, 60, 255), FillTransparency = 0.7,
        OutlineColor = Color3.fromRGB(200, 150, 255), OutlineTransparency = 0.5, Rainbow = false,
    },

    OffscreenArrows = {
        Enabled = true, Color = Color3.fromRGB(0, 180, 255),
        SecondaryColor = Color3.fromRGB(255, 255, 255), Size = 18, Width = 12,
        Margin = 40, Transparency = 0.85, ShowDistance = true, Rainbow = false,
    },
}

NeonESP.Presets = {
    Default = {},
    Neon = {
        Rainbow = { Enabled = true, Speed = 2 },
    },
    Cyber = {
        Box = { Color = Color3.fromRGB(0, 255, 170), SecondaryColor = Color3.fromRGB(0, 120, 255), Thickness = 1.5, Transparency = 0.95 },
        Tracers = { Enabled = true, Color = Color3.fromRGB(0, 255, 170), SecondaryColor = Color3.fromRGB(0, 120, 255) },
        HeadDot = { Enabled = true, Color = Color3.fromRGB(0, 255, 170) },
        Chams = { Enabled = true, FillColor = Color3.fromRGB(0, 200, 150), FillTransparency = 0.6 },
    },
    Amber = {
        Box = { Color = Color3.fromRGB(255, 170, 40), SecondaryColor = Color3.fromRGB(255, 220, 120), Transparency = 0.9 },
        Name = { Color = Color3.fromRGB(255, 200, 120) },
        HealthBar = { HighColor = Color3.fromRGB(255, 220, 80), LowColor = Color3.fromRGB(200, 30, 30) },
        Tracers = { Enabled = true, Color = Color3.fromRGB(255, 170, 40), SecondaryColor = Color3.fromRGB(255, 220, 120) },
        HeadDot = { Enabled = true, Color = Color3.fromRGB(255, 220, 120) },
        ToolESP = { Enabled = true, Color = Color3.fromRGB(255, 220, 120) },
    },
    Crimson = {
        Box = { Color = Color3.fromRGB(255, 60, 90), SecondaryColor = Color3.fromRGB(180, 40, 80), Transparency = 0.9 },
        Name = { Color = Color3.fromRGB(255, 150, 150) },
        HealthBar = { HighColor = Color3.fromRGB(255, 90, 90), LowColor = Color3.fromRGB(255, 30, 30) },
        Chams = { Enabled = true, FillColor = Color3.fromRGB(200, 40, 70), FillTransparency = 0.6 },
        HeadDot = { Enabled = true, Color = Color3.fromRGB(255, 120, 120) },
    },
    Frost = {
        Box = { Color = Color3.fromRGB(160, 220, 255), SecondaryColor = Color3.fromRGB(220, 245, 255), Transparency = 0.8 },
        Name = { Color = Color3.fromRGB(230, 245, 255) },
        HealthBar = { HighColor = Color3.fromRGB(120, 220, 255), LowColor = Color3.fromRGB(60, 120, 220) },
        Skeleton = { Enabled = true, Color = Color3.fromRGB(190, 230, 255), Transparency = 0.85 },
        HeadDot = { Enabled = true, Color = Color3.fromRGB(235, 250, 255) },
        OffscreenArrows = { Enabled = true, Color = Color3.fromRGB(160, 220, 255), SecondaryColor = Color3.fromRGB(235, 250, 255) },
    },
    Toxic = {
        Box = { Color = Color3.fromRGB(120, 255, 60), SecondaryColor = Color3.fromRGB(180, 255, 80), Transparency = 0.95 },
        Name = { Color = Color3.fromRGB(200, 255, 130) },
        Tracers = { Enabled = true, Color = Color3.fromRGB(120, 255, 60), SecondaryColor = Color3.fromRGB(220, 255, 120) },
        ToolHighlight = { Enabled = true, FillColor = Color3.fromRGB(120, 255, 60), FillTransparency = 0.4 },
        HeadDot = { Enabled = true, Color = Color3.fromRGB(200, 255, 130) },
    },
    Minimal = {
        Glow = { Enabled = false },
        Rainbow = { Enabled = false },
        Box = { Transparency = 0.7, Thickness = 1, Mode = "2D", SecondaryColor = Color3.fromRGB(200, 200, 200) },
        Name = { Color = Color3.fromRGB(255, 255, 255) },
        HealthBar = { ShowText = true },
        HeadDot = { Enabled = false },
        Distance = { Enabled = false },
        OffscreenArrows = { Enabled = false },
    },
    Violet = {
        Glow = { Enabled = false },
        Rainbow = { Enabled = false },
        Box = { Enabled = true, Mode = "2D", Thickness = 1, Transparency = 0.6, Color = Color3.fromRGB(176, 130, 255), SecondaryColor = Color3.fromRGB(176, 130, 255) },
        Name = { Enabled = true, Color = Color3.fromRGB(220, 200, 255), Size = 16 },
        HealthBar = { Enabled = true, ShowText = true, TextSize = 13, HighColor = Color3.fromRGB(176, 130, 255), LowColor = Color3.fromRGB(90, 40, 140) },
        Distance = { Enabled = true, Color = Color3.fromRGB(180, 160, 220), Size = 14 },
        Tracers = { Enabled = true, Color = Color3.fromRGB(176, 130, 255), SecondaryColor = Color3.fromRGB(140, 90, 220) },
        HeadDot = { Enabled = true, Color = Color3.fromRGB(230, 215, 255) },
        OffscreenArrows = { Enabled = true, Color = Color3.fromRGB(176, 130, 255), SecondaryColor = Color3.fromRGB(220, 200, 255), Transparency = 0.8 },
    },
}




local function edgePoint(dx, dy, margin, vsX, vsY)
    local cx, cy = vsX * 0.5, vsY * 0.5
    local iL, iR = margin, vsX - margin
    local iT, iB = margin, vsY - margin
    local bestT = huge
    local bx, by
    if dx > 1e-4 or dx < -1e-4 then
        local t = (iR - cx) / dx
        if t >= 0 and t < bestT then
            local py = cy + dy * t
            if py >= iT - 1 and py <= iB + 1 then bestT, bx, by = t, iR, py end
        end
        t = (iL - cx) / dx
        if t >= 0 and t < bestT then
            local py = cy + dy * t
            if py >= iT - 1 and py <= iB + 1 then bestT, bx, by = t, iL, py end
        end
    end
    if dy > 1e-4 or dy < -1e-4 then
        local t = (iB - cy) / dy
        if t >= 0 and t < bestT then
            local px = cx + dx * t
            if px >= iL - 1 and px <= iR + 1 then bestT, bx, by = t, px, iB end
        end
        t = (iT - cy) / dy
        if t >= 0 and t < bestT then
            local px = cx + dx * t
            if px >= iL - 1 and px <= iR + 1 then bestT, bx, by = t, px, iT end
        end
    end
    if bx then return bx, by end
    return nil, nil
end

local function boxSeg(esp, i, pA, pB, a)
    local L = esp.BoxLines
    local ln = L and L[i]
    if ln then
        ln.From = pA; ln.To = pB; ln.Transparency = a; ln.Visible = true
    end
    local O = esp.BoxOutline
    local ol = O and O[i]
    if ol then
        ol.From = pA; ol.To = pB; ol.Transparency = a * 0.55; ol.Visible = true
    end
    local G = esp.BoxGlow
    local gl = G and G[i]
    if gl then
        gl.From = pA; gl.To = pB; gl.Transparency = a * 0.12; gl.Visible = true
    end
end

local function applyBoxColors(esp, col, glowCol)
    if esp._bc ~= col then
        esp._bc = col
        local L = esp.BoxLines
        if L then
            for i = 1, 12 do
                if L[i] then L[i].Color = col end
            end
        end
    end
    local G = esp.BoxGlow
    if G and esp._gc ~= glowCol then
        esp._gc = glowCol
        for i = 1, 12 do
            if G[i] then G[i].Color = glowCol end
        end
    end
end

local function scaledSeg(ln, tipX, tipY, x1, y1, x2, y2, scale, a)
    if not ln then return end
    ln.From = V2.new(tipX + (x1 - tipX) * scale, tipY + (y1 - tipY) * scale)
    ln.To   = V2.new(tipX + (x2 - tipX) * scale, tipY + (y2 - tipY) * scale)
    ln.Transparency = a
    ln.Visible = true
end


local function rebuildBox(c)
    local char, root = c.char, c.root
    if not char or not root then
        c.boxValid = false
        return
    end
    local ok, bbCF, bbSize = pcall(char.GetBoundingBox, char)
    if not ok or not bbSize or bbSize.Y <= 0 then
        c.boxValid = false
        return
    end
    c.boxOffset = root.CFrame:ToObjectSpace(bbCF)
    local hx, hy, hz = bbSize.X * 0.5, bbSize.Y * 0.5, bbSize.Z * 0.5
    c.sizeY = bbSize.Y
    c.sizeX = clamp(bbSize.X, bbSize.Y * 0.35, bbSize.Y * 0.6) 
    local cl = c.cornerLocal
    for i = 1, 8 do
        local o = CORNER_OFFSETS[i]
        cl[i] = V3.new(o.X * hx, o.Y * hy, o.Z * hz)
    end
    c.boxValid = true
end


function NeonESP.new(config)
    local self = setmetatable({}, NeonESP)
    self.Config = deepCopy(DEFAULT_CONFIG)

    if config then
        for k, v in pairs(config) do
            if type(v) == "table" and type(self.Config[k]) == "table" then
                for k2, v2 in pairs(v) do
                    self.Config[k][k2] = v2
                end
            else
                self.Config[k] = v
            end
        end
    end

    self._drawings      = {} 
    self._cache         = {} 
    self._meta          = {} 
    self._playerColors  = {}
    self._highlights    = {} 
    self._toolHighlights = {}
    self._playerList    = {} 

    self._hue       = 0
    self._frame     = 0
    self._running   = false
    self._hiddenAll = false
    self._lastTime  = 0
    self._localRoot = nil
    self._rainbow   = false

    ID = ID + 1
    self._id = ID

    return self
end

function NeonESP:_getMeta(player)
    local m = self._meta[player]
    if not m then
        m = { hueOff = (player.UserId % 360) / 360 }
        local team = player.Team
        m.teamColor = team and team.TeamColor.Color or nil
        m.teamConn = player:GetPropertyChangedSignal("Team"):Connect(function()
            local t = player.Team
            m.teamColor = t and t.TeamColor.Color or nil
        end)
        self._meta[player] = m
    end
    return m
end

function NeonESP:_getCached(player)
    local c = self._cache[player]
    local char = player.Character
    if not c or c.char ~= char then
        c = {
            char = char, root = nil, head = nil, hum = nil,
            bones = nil, bonesOk = false, boneRetry = 0,
            tool = nil, toolName = nil, toolDirty = true,
            rp = nil, rpChar = nil, rpLocal = nil,
            boxValid = false, boxOffset = CFrame.new(),
            cornerLocal = {}, sizeY = 6, sizeX = 3,
            stagger = player.UserId % 60, 
        }
        self._cache[player] = c
    end
    if char then
        if not c.root or not c.root.Parent then c.root = char:FindFirstChild("HumanoidRootPart") end
        if not c.head or not c.head.Parent then c.head = char:FindFirstChild("Head") end
        if not c.hum  or not c.hum.Parent  then c.hum  = char:FindFirstChildOfClass("Humanoid") end
    end
    return c
end

function NeonESP:_refreshBones(c)
    local char = c.char
    if not char then
        c.bones, c.bonesOk = nil, false
        return
    end
    local bones = c.bones
    if not bones then
        bones = {}
        c.bones = bones
    end
    for i = 1, NBONES do
        local conn = BONE_CONNECTIONS[i]
        local pa, pb = bones[conn[1]], bones[conn[2]]
        if not pa or not pa.Parent then bones[conn[1]] = char:FindFirstChild(conn[1]) end
        if not pb or not pb.Parent then bones[conn[2]] = char:FindFirstChild(conn[2]) end
    end
    c.bonesOk = true
end

function NeonESP:_refreshTool(c)
    local char = c.char
    if not char then
        c.tool, c.toolName = nil, nil
        return
    end
    local tool = c.tool
    if not tool or tool.Parent ~= char then
        tool = char:FindFirstChildOfClass("Tool")
        c.tool = tool
        c.toolName = tool and tool.Name or nil
    end
end

function NeonESP:_rainbowColor(player)
    local cfg = self.Config.Rainbow
    local h = self._hue
    if cfg.PerPlayer then
        local m = self._meta[player] or self:_getMeta(player)
        h = h + m.hueOff
    end
    return Color3.fromHSV(h % 1, 1, 1)
end

function NeonESP:_teamColor(player)
    local m = self._meta[player] or self:_getMeta(player)
    return m.teamColor
end

function NeonESP:_color(player, rainbow, base)
    if rainbow and self._rainbow then
        return self:_rainbowColor(player)
    end
    if self.Config.UseTeamColor then
        local tc = self:_teamColor(player)
        if tc then return tc end
    end
    local pc = self._playerColors[player]
    if pc then return pc end
    return base
end


function NeonESP:_createESP()
    local c = self.Config
    local esp = {
        sm = {
            x = 0, y = 0, w = 0, h = 0,
            hp = 1, alpha = 1,
            tracerAlpha = c.Tracers.Transparency,
            arrowX = 0, arrowY = 0, arrowDX = 1, arrowDY = 0, arrowA = 0,
            visible = false,
        },
        
        px = {}, py = {}, pz = {},
        
        _boxOn = false, _skOn = false, _arwOn = false, _textsOn = false,
    }

    if c.Box.Enabled then
        esp.BoxLines, esp.BoxOutline = {}, {}
        for i = 1, 12 do
            esp.BoxLines[i]   = makeDrawing("Line", { Thickness = c.Box.Thickness, Color = c.Box.Color, Visible = false })
            esp.BoxOutline[i] = makeDrawing("Line", { Thickness = c.Box.Thickness + 2, Color = BLACK, Transparency = 0.55, Visible = false })
        end
        if c.Glow.Enabled then
            esp.BoxGlow = {}
            for i = 1, 12 do
                esp.BoxGlow[i] = makeDrawing("Line", { Thickness = c.Box.Thickness + 2, Color = c.Box.SecondaryColor or c.Box.Color, Visible = false })
            end
        end
    end

    if c.Name.Enabled then
        esp.Name = makeDrawing("Text", {
            Size = c.Name.Size, Color = c.Name.Color, Font = c.Name.Font,
            Outline = true, OutlineColor = BLACK, Center = true, Visible = false,
        })
    end

    if c.HealthBar.Enabled then
        esp.HealthBG     = makeDrawing("Square", { Color = BLACK, Filled = true, Visible = false })
        esp.HealthBorder = makeDrawing("Square", { Color = Color3.new(0.1, 0.1, 0.1), Filled = false, Thickness = 1, Visible = false })
        esp.HealthFill   = makeDrawing("Square", { Color = c.HealthBar.HighColor, Filled = true, Visible = false })
    end

    if c.HeadDot.Enabled then
        local hs = c.HeadDot.Size
        esp.HeadDot = makeDrawing("Square", {
            Color = c.HeadDot.Color, Filled = true,
            Size = V2.new(hs, hs), Visible = false, 
        })
        if c.HeadDot.Outline then
            esp.HeadDotOutline = makeDrawing("Square", {
                Color = c.HeadDot.OutlineColor, Filled = false, Thickness = 1,
                Size = V2.new(hs + 2, hs + 2), Visible = false,
            })
        end
    end

    if c.Distance.Enabled then
        esp.Distance = makeDrawing("Text", {
            Size = c.Distance.Size, Color = c.Distance.Color, Font = c.Distance.Font,
            Outline = true, OutlineColor = BLACK, Center = true, Visible = false,
        })
    end

    if c.Tracers.Enabled then
        esp.Tracer = makeDrawing("Line", { Thickness = c.Tracers.Thickness, Color = c.Tracers.Color, Visible = false })
        if c.Glow.Enabled then
            esp.TracerGlow = makeDrawing("Line", { Thickness = c.Tracers.Thickness + 3, Color = c.Tracers.Color, Visible = false })
        end
    end

    if c.Skeleton.Enabled then
        esp.SkeletonLines = {}
        for i = 1, NBONES do
            esp.SkeletonLines[i] = makeDrawing("Line", { Thickness = c.Skeleton.Thickness, Color = c.Skeleton.Color, Visible = false })
        end
        if c.Glow.Enabled then
            esp.SkeletonGlow = {}
            for i = 1, NBONES do
                esp.SkeletonGlow[i] = makeDrawing("Line", { Thickness = c.Skeleton.Thickness + 2, Color = c.Skeleton.Color, Visible = false })
            end
        end
    end

    if c.ToolESP.Enabled then
        esp.ToolText = makeDrawing("Text", {
            Size = c.ToolESP.Size, Color = c.ToolESP.Color, Font = c.ToolESP.Font,
            Outline = true, OutlineColor = BLACK, Center = true, Visible = false,
        })
    end

    if c.OffscreenArrows.Enabled then
        esp.ArrowLines, esp.ArrowGlowLines, esp.ArrowOutlines = {}, {}, {}
        for i = 1, 3 do
            esp.ArrowLines[i]     = makeDrawing("Line", { Thickness = c.Tracers.Thickness, Color = c.OffscreenArrows.Color, Visible = false })
            esp.ArrowGlowLines[i] = makeDrawing("Line", { Thickness = c.Tracers.Thickness + 3, Color = c.OffscreenArrows.SecondaryColor or c.OffscreenArrows.Color, Visible = false })
            esp.ArrowOutlines[i]  = makeDrawing("Line", { Thickness = c.Tracers.Thickness + 2, Color = BLACK, Transparency = 0.5, Visible = false })
        end
        if c.OffscreenArrows.ShowDistance then
            esp.ArrowText = makeDrawing("Text", {
                Size = 11, Color = c.OffscreenArrows.Color, Font = Enum.Font.Gotham,
                Outline = true, OutlineColor = BLACK, Center = true, Visible = false,
            })
        end
    end

    return esp
end


function NeonESP:_hideMain(esp)
    if esp._boxOn then
        esp._boxOn = false
        for i = 1, 12 do
            if esp.BoxLines and esp.BoxLines[i] then esp.BoxLines[i].Visible = false end
            if esp.BoxOutline and esp.BoxOutline[i] then esp.BoxOutline[i].Visible = false end
            if esp.BoxGlow and esp.BoxGlow[i] then esp.BoxGlow[i].Visible = false end
        end
    end
    if esp._skOn then
        esp._skOn = false
        for i = 1, NBONES do
            if esp.SkeletonLines and esp.SkeletonLines[i] then esp.SkeletonLines[i].Visible = false end
            if esp.SkeletonGlow and esp.SkeletonGlow[i] then esp.SkeletonGlow[i].Visible = false end
        end
    end
    if esp._textsOn then
        esp._textsOn = false
        if esp.Name then esp.Name.Visible = false end
        if esp.HealthBG then esp.HealthBG.Visible = false end
        if esp.HealthBorder then esp.HealthBorder.Visible = false end
        if esp.HealthFill then esp.HealthFill.Visible = false end
        if esp.HealthText then esp.HealthText.Visible = false end
        if esp.HeadDot then esp.HeadDot.Visible = false end
        if esp.HeadDotOutline then esp.HeadDotOutline.Visible = false end
        if esp.Distance then esp.Distance.Visible = false end
        if esp.Tracer then esp.Tracer.Visible = false end
        if esp.TracerGlow then esp.TracerGlow.Visible = false end
        if esp.ToolText then esp.ToolText.Visible = false end
    end
end

function NeonESP:_hideArrow(esp)
    if not esp._arwOn then return end
    esp._arwOn = false
    local M, G, O = esp.ArrowLines, esp.ArrowGlowLines, esp.ArrowOutlines
    for i = 1, 3 do
        if M and M[i] then M[i].Visible = false end
        if G and G[i] then G[i].Visible = false end
        if O and O[i] then O[i].Visible = false end
    end
    if esp.ArrowText then esp.ArrowText.Visible = false end
end

function NeonESP:_hideESP(esp)
    self:_hideMain(esp)
    self:_hideArrow(esp)
end

function NeonESP:_destroyESP(esp)
    if not esp then return end
    for i = 1, 12 do
        if esp.BoxLines then removeDrawing(esp.BoxLines[i]) end
        if esp.BoxOutline then removeDrawing(esp.BoxOutline[i]) end
        if esp.BoxGlow then removeDrawing(esp.BoxGlow[i]) end
    end
    removeDrawing(esp.Name)
    removeDrawing(esp.HealthBG)
    removeDrawing(esp.HealthBorder)
    removeDrawing(esp.HealthFill)
    removeDrawing(esp.HealthText)
    removeDrawing(esp.HeadDot)
    removeDrawing(esp.HeadDotOutline)
    removeDrawing(esp.Distance)
    removeDrawing(esp.Tracer)
    removeDrawing(esp.TracerGlow)
    removeDrawing(esp.ToolText)
    removeDrawing(esp.ArrowText)
    for i = 1, 3 do
        if esp.ArrowLines then removeDrawing(esp.ArrowLines[i]) end
        if esp.ArrowGlowLines then removeDrawing(esp.ArrowGlowLines[i]) end
        if esp.ArrowOutlines then removeDrawing(esp.ArrowOutlines[i]) end
    end
    for i = 1, NBONES do
        if esp.SkeletonLines then removeDrawing(esp.SkeletonLines[i]) end
        if esp.SkeletonGlow then removeDrawing(esp.SkeletonGlow[i]) end
    end
end


function NeonESP:_drawCornerBox(esp, bx, by, w, h, a, col, glowCol)
    applyBoxColors(esp, col, glowCol)
    esp._boxOn = true
    local len = clamp(w * 0.25, 5, 25)
    local x2, y2 = bx + w, by + h
    local i = 0
    for ci = 1, 4 do
        local s = CORNER_SIGNS[ci]
        local pX = s[1] > 0 and x2 or bx
        local pY = s[2] > 0 and y2 or by
        local p0 = V2.new(pX, pY)
        local pA = V2.new(pX + s[3] * len, pY)
        local pB = V2.new(pX, pY + s[4] * len)
        i = i + 1
        boxSeg(esp, i, p0, pA, a)
        i = i + 1
        boxSeg(esp, i, p0, pB, a)
    end
    for j = 9, 12 do
        local L = esp.BoxLines; if L and L[j] then L[j].Visible = false end
        local O = esp.BoxOutline; if O and O[j] then O[j].Visible = false end
        local G = esp.BoxGlow; if G and G[j] then G[j].Visible = false end
    end
end

function NeonESP:_draw2DBox(esp, bx, by, w, h, a, col, glowCol)
    applyBoxColors(esp, col, glowCol)
    esp._boxOn = true
    local x2, y2 = bx + w, by + h
    local p1, p2 = V2.new(bx, by), V2.new(x2, by)
    local p3, p4 = V2.new(x2, y2), V2.new(bx, y2)
    boxSeg(esp, 1, p1, p2, a)
    boxSeg(esp, 2, p2, p3, a)
    boxSeg(esp, 3, p3, p4, a)
    boxSeg(esp, 4, p4, p1, a)
    for j = 5, 12 do
        local L = esp.BoxLines; if L and L[j] then L[j].Visible = false end
        local O = esp.BoxOutline; if O and O[j] then O[j].Visible = false end
        local G = esp.BoxGlow; if G and G[j] then G[j].Visible = false end
    end
end

function NeonESP:_draw3DBox(esp, a, col, glowCol)
    applyBoxColors(esp, col, glowCol)
    esp._boxOn = true
    local px, py, pz = esp.px, esp.py, esp.pz
    local L, O, G = esp.BoxLines, esp.BoxOutline, esp.BoxGlow
    for i = 1, 12 do
        local e = EDGES_3D[i]
        local ia, ib = e[1], e[2]
        if pz[ia] > 0 and pz[ib] > 0 then
            boxSeg(esp, i, V2.new(px[ia], py[ia]), V2.new(px[ib], py[ib]), a)
        else
            local ln = L and L[i]; if ln then ln.Visible = false end
            local ol = O and O[i]; if ol then ol.Visible = false end
            local gl = G and G[i]; if gl then gl.Visible = false end
        end
    end
end


function NeonESP:_renderArrow(player, esp, tipX, tipY, dirX, dirY, alpha, dt, dist)
    local sm = esp.sm
    local cfg = self.Config
    local ac = cfg.OffscreenArrows

    if cfg.Smooth.Enabled then
        local t2 = clamp(cfg.Smooth.Speed * 30 * dt, 0, 1)
        sm.arrowX += (tipX - sm.arrowX) * t2
        sm.arrowY += (tipY - sm.arrowY) * t2
        sm.arrowA += (alpha - sm.arrowA) * t2
    else
        sm.arrowX, sm.arrowY = tipX, tipY
        sm.arrowA = alpha
    end
    sm.arrowDX, sm.arrowDY = dirX, dirY

    local a = sm.arrowA
    if a <= 0.01 then
        self:_hideArrow(esp)
        return
    end
    esp._arwOn = true

    local size = ac.Size
    local hw = ac.Width * 0.5
    local px, py = sm.arrowX, sm.arrowY
    local bCx = px - dirX * size
    local bCy = py - dirY * size
    local perpX, perpY = -dirY, dirX
    local lX, lY = bCx + perpX * hw, bCy + perpY * hw
    local rX, rY = bCx - perpX * hw, bCy - perpY * hw

    local col = self:_color(player, ac.Rainbow, ac.Color)
    local M, G, O = esp.ArrowLines, esp.ArrowGlowLines, esp.ArrowOutlines

    if M and esp._amC ~= col then
        esp._amC = col
        for i = 1, 3 do
            if M[i] then M[i].Color = col end
        end
    end
    if G and esp._agC ~= col then
        esp._agC = col
        for i = 1, 3 do
            if G[i] then G[i].Color = col end
        end
    end

    local ga = a * 0.12
    local oa = a * 0.5
    if G then
        scaledSeg(G[1], px, py, px, py, lX, lY, 1.35, ga)
        scaledSeg(G[2], px, py, px, py, rX, rY, 1.35, ga)
        scaledSeg(G[3], px, py, lX, lY, rX, rY, 1.35, ga)
    end
    if O then
        scaledSeg(O[1], px, py, px, py, lX, lY, 1.18, oa)
        scaledSeg(O[2], px, py, px, py, rX, rY, 1.18, oa)
        scaledSeg(O[3], px, py, lX, lY, rX, rY, 1.18, oa)
    end
    if M then
        scaledSeg(M[1], px, py, px, py, lX, lY, 1, a)
        scaledSeg(M[2], px, py, px, py, rX, rY, 1, a)
        scaledSeg(M[3], px, py, lX, lY, rX, rY, 1, a)
    end

    if esp.ArrowText then
        local s = format("%.0f", dist) .. cfg.Distance.Suffix
        if esp._atS ~= s then
            esp._atS = s
            esp.ArrowText.Text = s
        end
        esp.ArrowText.Position = V2.new(bCx + dirX * (size + 12), bCy + dirY * (size + 12))
        esp.ArrowText.Transparency = a
        esp.ArrowText.Visible = true
    end
end

function NeonESP:_updateOffscreenArrow(player, esp, rootPos, dt, dist)
    local cfg = self.Config
    local ac = cfg.OffscreenArrows

    local rel = self._camCF:PointToObjectSpace(rootPos)
    local dirX, dirY
    if rel.Z < 0 then
        dirX, dirY = rel.X, -rel.Y 
    else
        dirX, dirY = -rel.X, rel.Y
    end
    local m = sqrt(dirX * dirX + dirY * dirY)
    if m < 0.0001 then
        dirX, dirY = 0, -1
    else
        dirX, dirY = dirX / m, dirY / m
    end

    local ex, ey = edgePoint(dirX, dirY, ac.Margin, self._vsX, self._vsY)
    if not ex then
        self:_hideArrow(esp)
        return
    end

    local alpha = ac.Transparency
    local fd = cfg.DistanceFade
    if fd.Enabled then
        local range = fd.EndDistance - fd.StartDistance
        if range <= 0 then
            if dist >= fd.EndDistance then alpha = alpha * fd.MinAlpha end
        elseif dist > fd.EndDistance then
            alpha = alpha * fd.MinAlpha
        elseif dist > fd.StartDistance then
            alpha = alpha * (fd.MinAlpha + (1 - fd.MinAlpha) * (1 - clamp((dist - fd.StartDistance) / range, 0, 1)))
        end
    end

    self:_renderArrow(player, esp, ex, ey, dirX, dirY, alpha, dt, dist)
end


function NeonESP:_updatePlayer(player, esp, dt)
    local cfg = self.Config
    local c = self:_getCached(player)
    local char, hum, root = c.char, c.hum, c.root

    if not char or not hum or not root or not root.Parent or hum.Health <= 0 then
        self:_hideESP(esp)
        esp.sm.visible = false
        return
    end

    if cfg.TeamCheck and player.Team and player.Team == LocalPlayer.Team then
        self:_hideESP(esp)
        esp.sm.visible = false
        return
    end

    local localRoot = self._localRoot
    if not localRoot then
        self:_hideESP(esp)
        esp.sm.visible = false
        return
    end

    local rootPos = root.Position
    local dist = (rootPos - localRoot.Position).Magnitude
    if dist > cfg.MaxDistance then
        self:_hideESP(esp)
        esp.sm.visible = false
        return
    end

    if cfg.VisibilityCheck then
        local lc = LocalPlayer.Character
        if c.rpChar ~= char or c.rpLocal ~= lc then
            if not c.rp then
                c.rp = RaycastParams.new()
                c.rp.FilterType = Enum.RaycastFilterType.Exclude
            end
            c.rp.FilterDescendantsInstances = lc and {char, lc} or {char}
            c.rpChar, c.rpLocal = char, lc
        end
        local camPos = self._camPos
        if workspace:Raycast(camPos, rootPos - camPos, c.rp) then
            self:_hideESP(esp)
            esp.sm.visible = false
            return
        end
    end

    local frame = self._frame
    if not c.boxValid or (frame + c.stagger) % BOX_REFRESH == 0 then
        rebuildBox(c)
    end
    if not c.boxValid then
        self:_hideESP(esp)
        esp.sm.visible = false
        return
    end

    local boxCF = root.CFrame * c.boxOffset
    local vsX, vsY = self._vsX, self._vsY
    local sm = esp.sm
    local mode3D = cfg.Box.Enabled and cfg.Box.Mode == "3D"

    local minX, minY, maxX, maxY
    local onscreen

    if mode3D then
        local px, py, pz = esp.px, esp.py, esp.pz
        local cl = c.cornerLocal
        minX, minY = huge, huge
        maxX, maxY = -huge, -huge
        local viewCount = 0
        for i = 1, 8 do
            local sp = Camera:WorldToViewportPoint(boxCF * cl[i])
            px[i], py[i], pz[i] = sp.X, sp.Y, sp.Z
            if sp.Z > 0 then
                if sp.X < minX then minX = sp.X end
                if sp.Y < minY then minY = sp.Y end
                if sp.X > maxX then maxX = sp.X end
                if sp.Y > maxY then maxY = sp.Y end
                if sp.X >= 0 and sp.X <= vsX and sp.Y >= 0 and sp.Y <= vsY then
                    viewCount = viewCount + 1
                end
            end
        end
        onscreen = viewCount > 0
    else
        
        local cp = Camera:WorldToViewportPoint(boxCF.Position)
        if cp.Z <= 0.05 then
            onscreen = false
        else
            local scale = vsY / (2 * cp.Z * self._tanHalf) 
            local h = c.sizeY * scale
            local w = c.sizeX * scale
            if h < 2 then h = 2 elseif h > MAX_PIXELS then h = MAX_PIXELS end
            if w < 2 then w = 2 elseif w > MAX_PIXELS then w = MAX_PIXELS end
            minX, minY = cp.X - w * 0.5, cp.Y - h * 0.5
            maxX, maxY = minX + w, minY + h
            onscreen = cp.X >= -w and cp.X <= vsX + w and cp.Y >= -h and cp.Y <= vsY + h
        end
    end

    
    if not onscreen then
        self:_hideMain(esp)
        sm.visible = false
        if esp.ArrowLines then
            self:_updateOffscreenArrow(player, esp, rootPos, dt, dist)
        end
        return
    end

    
    local tx, ty = (minX + maxX) * 0.5, (minY + maxY) * 0.5
    local tw, th = maxX - minX, maxY - minY
    local smoothOn = cfg.Smooth.Enabled
    local t = smoothOn and (1 - exp(-cfg.Smooth.Speed * 30 * dt)) or 1

    if not sm.visible or t >= 1 then
        sm.x, sm.y, sm.w, sm.h = tx, ty, tw, th
    else
        local ddx, ddy = tx - sm.x, ty - sm.y
        local dd = sqrt(ddx * ddx + ddy * ddy)
        if dd < SNAP_NEAR or dd > SNAP_FAR then
            sm.x, sm.y = tx, ty
        else
            
            local tt = clamp(t * (1 + dd * 0.08), 0, 1)
            sm.x += (tx - sm.x) * tt
            sm.y += (ty - sm.y) * tt
        end
        sm.w += (tw - sm.w) * t
        sm.h += (th - sm.h) * t
    end
    sm.visible = true

    local distFade = 1
    local fd = cfg.DistanceFade
    if fd.Enabled then
        local range = fd.EndDistance - fd.StartDistance
        if range <= 0 then
            distFade = dist >= fd.EndDistance and fd.MinAlpha or 1
        else
            distFade = fd.MinAlpha + (1 - fd.MinAlpha) * (1 - clamp((dist - fd.StartDistance) / range, 0, 1))
        end
    end

    sm.alpha += (distFade * self._glowPulse * cfg.Box.Transparency - sm.alpha) * clamp(t * 1.5, 0, 1)
    local a = sm.alpha

    local hp = clamp(hum.Health / math.max(hum.MaxHealth, 0.01), 0, 1)
    if cfg.HealthBar.SmoothTransition and smoothOn then
        sm.hp += (hp - sm.hp) * clamp(t * 2, 0, 1)
    else
        sm.hp = hp
    end

    local bx, by = sm.x - sm.w * 0.5, sm.y - sm.h * 0.5
    local cx, cy = sm.x, sm.y
    local sw, sh = sm.w, sm.h
    local distInt = floor(dist + 0.5)

    esp._textsOn = true

    
    if cfg.Box.Enabled then
        local cB = cfg.Box
        local boxCol, glowCol
        if cB.Rainbow and self._rainbow then
            boxCol = self:_rainbowColor(player)
            glowCol = boxCol
        elseif cfg.UseTeamColor then
            local tc = self:_teamColor(player)
            boxCol = tc or cB.Color:Lerp(cB.SecondaryColor or cB.Color, 1 - distFade)
            glowCol = tc or cB.SecondaryColor or cB.Color
        else
            local pc = self._playerColors[player]
            if pc then
                boxCol, glowCol = pc, pc
            else
                boxCol = cB.Color:Lerp(cB.SecondaryColor or cB.Color, 1 - distFade)
                glowCol = cB.SecondaryColor or cB.Color
            end
        end

        if mode3D then
            self:_draw3DBox(esp, a, boxCol, glowCol)
        elseif cB.Mode == "Corner" then
            self:_drawCornerBox(esp, bx, by, sw, sh, a, boxCol, glowCol)
        else
            self:_draw2DBox(esp, bx, by, sw, sh, a, boxCol, glowCol)
        end
    end

    
    if esp.Name then
        local n = cfg.Name
        local dn = n.UseDisplayName and player.DisplayName or player.Name
        local hpInt = floor(hum.Health + 0.5)
        if esp._nBase ~= dn
            or (n.ShowDistance and esp._nDist ~= distInt)
            or (n.ShowHealth and esp._nHp ~= hpInt) then
            esp._nBase = dn
            if n.ShowDistance then esp._nDist = distInt end
            if n.ShowHealth then esp._nHp = hpInt end
            local text = dn
            if n.Prefix ~= "" then text = n.Prefix .. " " .. text end
            if n.Suffix ~= "" then text = text .. " " .. n.Suffix end
            if n.ShowDistance then text = text .. " " .. format("%.0f", dist) .. cfg.Distance.Suffix end
            if n.ShowHealth then text = text .. " " .. hpInt end
            if #text > n.MaxLength then text = text:sub(1, n.MaxLength) .. "…" end
            esp.Name.Text = text
        end
        esp.Name.Position = V2.new(cx, by - 18)
        local ncol = self:_color(player, n.Rainbow, n.Color)
        if esp._nc ~= ncol then
            esp._nc = ncol
            esp.Name.Color = ncol
        end
        esp.Name.Transparency = a
        esp.Name.Visible = true
    end

    
    if esp.HealthBG then
        local hb = cfg.HealthBar
        local pct = sm.hp
        local barW = hb.Width
        local hpos = hb.Position
        local isBottom = hpos == "Bottom" or hpos == "bottom"
        local fillH = sh * pct
        if fillH < 1 then fillH = 1 end

        local bgPos, bgSize, fillPos, fillSize
        if isBottom then
            local barY = by + sh + hb.Offset + 2
            local fillW = sw * pct
            if fillW < 1 then fillW = 1 end
            bgPos, bgSize = V2.new(bx - 1, barY - 1), V2.new(sw + 2, barW + 2)
            fillPos, fillSize = V2.new(bx, barY), V2.new(fillW, barW)
        else
            local barX = (hpos == "Left" or hpos == "left")
                and (bx - hb.Offset - barW - 4)
                or (bx + sw + hb.Offset + 2)
            bgPos, bgSize = V2.new(barX - 1, by - 1), V2.new(barW + 2, sh + 2)
            fillPos, fillSize = V2.new(barX, by + sh - fillH), V2.new(barW, fillH)
        end

        local bg = esp.HealthBG
        bg.Position = bgPos
        bg.Size = bgSize
        bg.Transparency = a * 0.8
        bg.Visible = true

        if esp.HealthBorder then
            local bd = esp.HealthBorder
            bd.Position = V2.new(bgPos.X - 1, bgPos.Y - 1)
            bd.Size = V2.new(bgSize.X + 2, bgSize.Y + 2)
            bd.Transparency = a * 0.4
            bd.Visible = true
        end

        local fill = esp.HealthFill
        fill.Position = fillPos
        fill.Size = fillSize
        local hpCol = (hb.Rainbow and self._rainbow) and self:_rainbowColor(player)
            or hb.LowColor:Lerp(hb.HighColor, pct)
        if esp._hc ~= hpCol then
            esp._hc = hpCol
            fill.Color = hpCol
        end
        fill.Transparency = a
        fill.Visible = true

        if hb.ShowText then
            local ht = esp.HealthText
            if not ht then
                ht = makeDrawing("Text", {
                    Size = hb.TextSize, Font = Enum.Font.GothamBold,
                    Outline = true, OutlineColor = BLACK, Center = true, Visible = false,
                })
                esp.HealthText = ht
            end
            if ht then
                local hpNow = floor(hum.Health + 0.5)
                if esp._hpT ~= hpNow or esp._hpM ~= hum.MaxHealth then
                    esp._hpT, esp._hpM = hpNow, hum.MaxHealth
                    ht.Text = format("%d/%d", hpNow, floor(hum.MaxHealth + 0.5))
                end
                local tx, ty
                if isBottom then
                    tx, ty = cx, by + sh + hb.Offset + barW + 2
                else
                    tx, ty = bx + sw + hb.Offset + barW + 6, by + sh * 0.5 - hb.TextSize * 0.5
                end
                ht.Position = V2.new(tx, ty)
                local htc = self:_color(player, false, hb.TextColor)
                if esp._hTc ~= htc then
                    esp._hTc = htc
                    ht.Color = htc
                end
                ht.Transparency = a
                ht.Visible = true
            end
        elseif esp.HealthText then
            esp.HealthText.Visible = false
        end
    end

    
    if esp.HeadDot then
        local head = c.head
        local hsp = Camera:WorldToViewportPoint(head and head.Position or (rootPos + V3.new(0, 3, 0)))
        if hsp.Z > 0 then
            local hd = cfg.HeadDot
            local hs = hd.Size
            esp.HeadDot.Position = V2.new(hsp.X - hs * 0.5, hsp.Y - hs * 0.5)
            local col = self:_color(player, hd.Rainbow, hd.Color)
            if esp._dc ~= col then
                esp._dc = col
                esp.HeadDot.Color = col
            end
            esp.HeadDot.Transparency = a * hd.Transparency
            esp.HeadDot.Visible = true
            if esp.HeadDotOutline then
                esp.HeadDotOutline.Position = V2.new(hsp.X - hs * 0.5 - 1, hsp.Y - hs * 0.5 - 1)
                if esp._doc ~= hd.OutlineColor then
                    esp._doc = hd.OutlineColor
                    esp.HeadDotOutline.Color = hd.OutlineColor
                end
                esp.HeadDotOutline.Transparency = a * hd.Transparency
                esp.HeadDotOutline.Visible = true
            end
        else
            esp.HeadDot.Visible = false
            if esp.HeadDotOutline then esp.HeadDotOutline.Visible = false end
        end
    end

    
    if esp.Distance then
        if esp._dInt ~= distInt then
            esp._dInt = distInt
            esp.Distance.Text = format("%.0f", dist) .. cfg.Distance.Suffix
        end
        esp.Distance.Position = V2.new(cx, by + sh + 4)
        local col = self:_color(player, cfg.Distance.Rainbow, cfg.Distance.Color)
        if esp._dCol ~= col then
            esp._dCol = col
            esp.Distance.Color = col
        end
        esp.Distance.Transparency = a
        esp.Distance.Visible = true
    end

    
    if esp.Tracer then
        local tc = cfg.Tracers
        local originY = vsY
        if tc.Origin == "Top" then
            originY = 0
        elseif tc.Origin == "Center" then
            originY = vsY * 0.5
        end
        local oX = vsX * 0.5
        local ta = a * tc.Transparency
        sm.tracerAlpha += (ta - sm.tracerAlpha) * clamp(t * 2, 0, 1)

        local tCol
        if tc.Rainbow and self._rainbow then
            tCol = self:_rainbowColor(player)
        else
            local fadeD = cfg.DistanceFade.Enabled and cfg.DistanceFade.EndDistance or 2000
            tCol = tc.Color:Lerp(tc.SecondaryColor or tc.Color, clamp(dist / fadeD, 0, 1))
        end

        if esp.TracerGlow then
            esp.TracerGlow.From = V2.new(oX, originY)
            esp.TracerGlow.To = V2.new(cx, cy)
            if esp._tgC ~= tCol then
                esp._tgC = tCol
                esp.TracerGlow.Color = tCol
            end
            esp.TracerGlow.Transparency = sm.tracerAlpha * 0.12
            esp.TracerGlow.Visible = true
        end

        esp.Tracer.From = V2.new(oX, originY)
        esp.Tracer.To = V2.new(cx, cy)
        if esp._trC ~= tCol then
            esp._trC = tCol
            esp.Tracer.Color = tCol
        end
        esp.Tracer.Transparency = sm.tracerAlpha
        esp.Tracer.Visible = true
    end

    
    if esp.SkeletonLines then
        local sk = cfg.Skeleton
        if not c.bonesOk or (frame + c.stagger) % 30 == 0 then
            self:_refreshBones(c)
        end
        local skCol = self:_color(player, sk.Rainbow, sk.Color)
        if esp._skC ~= skCol then
            esp._skC = skCol
            for i = 1, NBONES do
                if esp.SkeletonLines[i] then esp.SkeletonLines[i].Color = skCol end
                if esp.SkeletonGlow and esp.SkeletonGlow[i] then esp.SkeletonGlow[i].Color = skCol end
            end
        end
        esp._skOn = true
        local sA = a * sk.Transparency
        local bones = c.bones
        for i = 1, NBONES do
            local conn = BONE_CONNECTIONS[i]
            local pA, pB = bones[conn[1]], bones[conn[2]]
            if pA and pB and pA.Parent and pB.Parent then
                local s1 = Camera:WorldToViewportPoint(pA.Position)
                local s2 = Camera:WorldToViewportPoint(pB.Position)
                if s1.Z > 0 and s2.Z > 0 then
                    local vA, vB = V2.new(s1.X, s1.Y), V2.new(s2.X, s2.Y)
                    local ln = esp.SkeletonLines[i]
                    if ln then
                        ln.From = vA; ln.To = vB; ln.Transparency = sA; ln.Visible = true
                    end
                    local gl = esp.SkeletonGlow and esp.SkeletonGlow[i]
                    if gl then
                        gl.From = vA; gl.To = vB; gl.Transparency = sA * 0.12; gl.Visible = true
                    end
                else
                    if esp.SkeletonLines[i] then esp.SkeletonLines[i].Visible = false end
                    if esp.SkeletonGlow and esp.SkeletonGlow[i] then esp.SkeletonGlow[i].Visible = false end
                end
            else
                if esp.SkeletonLines[i] then esp.SkeletonLines[i].Visible = false end
                if esp.SkeletonGlow and esp.SkeletonGlow[i] then esp.SkeletonGlow[i].Visible = false end
                if frame >= c.boneRetry then
                    c.boneRetry = frame + 10
                    self:_refreshBones(c)
                end
            end
        end
    end

    
    if esp.ToolText then
        if c.toolDirty or (frame + c.stagger) % TOOL_REFRESH == 0 then
            c.toolDirty = false
            self:_refreshTool(c)
        end
        local tn = c.toolName
        if tn then
            local te = cfg.ToolESP
            local str = te.Brackets and ("[ " .. tn .. " ]") or tn
            if esp._toolStr ~= str then
                esp._toolStr = str
                esp.ToolText.Text = str
            end
            esp.ToolText.Position = V2.new(cx, by - 34)
            local col = self:_color(player, te.Rainbow, te.Color)
            if esp._toolC ~= col then
                esp._toolC = col
                esp.ToolText.Color = col
            end
            esp.ToolText.Transparency = a
            esp.ToolText.Visible = true
        else
            esp.ToolText.Visible = false
        end
    end

    
    if esp.ArrowLines and sm.arrowA > 0.015 then
        self:_renderArrow(player, esp, sm.arrowX, sm.arrowY, sm.arrowDX, sm.arrowDY, 0, dt, dist)
    end
end


function NeonESP:_updateChams(player)
    local cfg = self.Config.Chams
    local char = player.Character
    local hl = self._highlights[player]

    if not cfg.Enabled or not char then
        if hl then
            hl:Destroy()
            self._highlights[player] = nil
        end
        return
    end

    
    if hl and (hl.Adornee ~= char or hl.Parent ~= char) then
        hl:Destroy()
        hl = nil
    end
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = "NeonESP_Cham"
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Adornee = char
        hl.Parent = char
        self._highlights[player] = hl
    end

    local fill, outline
    if cfg.Rainbow and self._rainbow then
        local m = self._meta[player] or self:_getMeta(player)
        local h = (self._hue + (self.Config.Rainbow.PerPlayer and m.hueOff or 0)) % 1
        fill = Color3.fromHSV(h, 1, 1)
        outline = Color3.fromHSV((h + 0.2) % 1, 1, 1)
    else
        fill, outline = cfg.FillColor, cfg.OutlineColor
    end
    if hl.FillColor ~= fill then hl.FillColor = fill end
    if hl.FillTransparency ~= cfg.FillTransparency then hl.FillTransparency = cfg.FillTransparency end
    if hl.OutlineColor ~= outline then hl.OutlineColor = outline end
    if hl.OutlineTransparency ~= cfg.OutlineTransparency then hl.OutlineTransparency = cfg.OutlineTransparency end
end

function NeonESP:_updateToolHighlight(player)
    local cfg = self.Config.ToolHighlight
    local char = player.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    local hl = self._toolHighlights[player]

    if not cfg.Enabled or not tool then
        if hl then
            hl:Destroy()
            self._toolHighlights[player] = nil
        end
        return
    end

    if hl and (hl.Adornee ~= tool or hl.Parent ~= tool) then
        hl:Destroy()
        hl = nil
        self._toolHighlights[player] = nil
    end
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = "NeonESP_ToolHL"
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Adornee = tool
        hl.Parent = tool
        self._toolHighlights[player] = hl
    end

    if hl.FillColor ~= cfg.FillColor then hl.FillColor = cfg.FillColor end
    if hl.FillTransparency ~= cfg.FillTransparency then hl.FillTransparency = cfg.FillTransparency end
    if hl.OutlineColor ~= cfg.OutlineColor then hl.OutlineColor = cfg.OutlineColor end
    if hl.OutlineTransparency ~= cfg.OutlineTransparency then hl.OutlineTransparency = cfg.OutlineTransparency end
end


function NeonESP:_step()
    local cam = workspace.CurrentCamera
    if cam ~= Camera then
        Camera = cam
    end

    local now = os.clock()
    local dt = now - self._lastTime
    self._lastTime = now
    if dt <= 0 or dt > 0.25 then dt = 1 / 60 end

    local cfg = self.Config
    if not cfg.Enabled then
        if not self._hiddenAll then
            self._hiddenAll = true
            for _, esp in pairs(self._drawings) do self:_hideESP(esp) end
            for _, hl in pairs(self._highlights) do hl:Destroy() end
            self._highlights = {}
            for _, hl in pairs(self._toolHighlights) do hl:Destroy() end
            self._toolHighlights = {}
        end
        return
    end
    self._hiddenAll = false

    local frame = self._frame + 1
    self._frame = frame

    
    local vs = cam.ViewportSize
    self._vsX, self._vsY = vs.X, vs.Y
    self._tanHalf = math.max(tan(rad(cam.FieldOfView * 0.5)), 0.01)
    local camCF = cam.CFrame
    self._camCF = camCF
    self._camPos = camCF.Position

    self._rainbow = cfg.Rainbow.Enabled
    if self._rainbow then
        self._hue = (self._hue + dt * cfg.Rainbow.Speed * 0.12) % 1
    end

    local glow = 1
    if cfg.Glow.Enabled then
        local g = cfg.Glow
        glow = g.MinAlpha + (g.MaxAlpha - g.MinAlpha) * (sin(now * g.Speed * 6.28318) * 0.5 + 0.5)
    end
    self._glowPulse = glow

    
    local localRoot = self._localRoot
    if not localRoot or not localRoot.Parent then
        local lc = LocalPlayer.Character
        localRoot = lc and lc:FindFirstChild("HumanoidRootPart") or nil
        self._localRoot = localRoot
    end

    
    local list = self._playerList
    for i = 1, #list do
        local plr = list[i]
        if plr ~= LocalPlayer then
            local esp = self._drawings[plr]
            if not esp then
                esp = self:_createESP()
                self._drawings[plr] = esp
            end
            self:_updatePlayer(plr, esp, dt)
        end
    end

    
    if cfg.Chams.Enabled or cfg.ToolHighlight.Enabled
        or next(self._highlights) or next(self._toolHighlights) then
        if frame % CHAMS_REFRESH == 0 then
            for i = 1, #list do
                local plr = list[i]
                if plr ~= LocalPlayer then
                    self:_updateChams(plr)
                    self:_updateToolHighlight(plr)
                end
            end
        end
    end
end


function NeonESP:_removePlayer(player)
    local esp = self._drawings[player]
    if esp then
        self:_destroyESP(esp)
        self._drawings[player] = nil
    end
    self._cache[player] = nil

    local m = self._meta[player]
    if m then
        if m.teamConn then m.teamConn:Disconnect() end
        self._meta[player] = nil
    end
    self._playerColors[player] = nil

    local hl = self._highlights[player]
    if hl then hl:Destroy(); self._highlights[player] = nil end
    hl = self._toolHighlights[player]
    if hl then hl:Destroy(); self._toolHighlights[player] = nil end

    local list = self._playerList
    for i = #list, 1, -1 do
        if list[i] == player then
            table.remove(list, i)
            break
        end
    end
end

function NeonESP:Start()
    if self._running then return self end
    self._running = true
    self._lastTime = os.clock()

    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        list[#list + 1] = p
    end
    self._playerList = list

    self._connAdded = Players.PlayerAdded:Connect(function(p)
        list[#list + 1] = p
    end)
    self._connRemoving = Players.PlayerRemoving:Connect(function(p)
        self:_removePlayer(p)
    end)

    self._renderName = "NeonESP_" .. self._id
    local step = function()
        self:_step()
    end

    
    local ok = pcall(function()
        RunService:BindToRenderStep(self._renderName, RENDER_PRIORITY, step)
    end)
    if not ok then
        
        self._renderConn = RunService.RenderStepped:Connect(step)
    end
    return self
end

function NeonESP:Stop()
    if not self._running then return self end
    self._running = false
    pcall(function()
        RunService:UnbindFromRenderStep(self._renderName)
    end)
    if self._renderConn then self._renderConn:Disconnect(); self._renderConn = nil end
    if self._connAdded then self._connAdded:Disconnect(); self._connAdded = nil end
    if self._connRemoving then self._connRemoving:Disconnect(); self._connRemoving = nil end
    for _, esp in pairs(self._drawings) do
        self:_hideESP(esp)
    end
    return self
end

function NeonESP:IsRunning()
    return self._running
end

function NeonESP:Refresh()
    
    for p, esp in pairs(self._drawings) do
        self:_destroyESP(esp)
        self._drawings[p] = nil
    end
    return self
end

function NeonESP:SetConfig(patch)
    for k, v in pairs(patch) do
        if type(v) == "table" and type(self.Config[k]) == "table" then
            for k2, v2 in pairs(v) do
                self.Config[k][k2] = v2
            end
        else
            self.Config[k] = v
        end
    end
    return self:Refresh()
end

function NeonESP:ApplyPreset(name)
    local preset = NeonESP.Presets[name]
    if preset then
        return self:SetConfig(preset)
    end
    warn("[NeonESP] Preset not found: " .. tostring(name))
    return self
end

function NeonESP:SetPlayerColor(player, color)
    if color then
        self._playerColors[player] = color
    else
        self._playerColors[player] = nil
    end
    return self
end

function NeonESP:Destroy()
    self:Stop()
    for p, esp in pairs(self._drawings) do
        self:_destroyESP(esp)
        self._drawings[p] = nil
    end
    for _, hl in pairs(self._highlights) do hl:Destroy() end
    self._highlights = {}
    for _, hl in pairs(self._toolHighlights) do hl:Destroy() end
    self._toolHighlights = {}
    for _, m in pairs(self._meta) do
        if m.teamConn then m.teamConn:Disconnect() end
    end
    self._meta = {}
    self._cache = {}
    self._playerColors = {}
    self._playerList = {}
    return self
end

return NeonESP