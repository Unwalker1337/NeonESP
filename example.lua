local NeonESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/Unwalker1337/SwagModeESPlibrary/main/init.lua"))()

local esp = NeonESP.new({
    TeamCheck = true,
    MaxDistance = 5000,

    Box = {
        Enabled = true,
        Mode = "3D",
        Color = Color3.fromRGB(0, 180, 255),
        SecondaryColor = Color3.fromRGB(140, 180, 255),
        Thickness = 1.5,
        Transparency = 0.9,
    },

    Name = {
        Enabled = true,
        Color = Color3.fromRGB(255, 255, 255),
        Size = 14,
    },

    HealthBar = {
        Enabled = true,
        Width = 3,
        HighColor = Color3.fromRGB(0, 255, 120),
        LowColor = Color3.fromRGB(255, 40, 40),
    },

    HeadDot = {
        Enabled = true,
        Size = 5,
    },

    Distance = {
        Enabled = true,
        Color = Color3.fromRGB(180, 180, 200),
        Size = 12,
        Suffix = "m",
    },

    Tracers = {
        Enabled = true,
        Origin = "Bottom",
        Color = Color3.fromRGB(0, 180, 255),
        SecondaryColor = Color3.fromRGB(255, 255, 255),
        Thickness = 1,
    },

    Skeleton = {
        Enabled = true,
        Color = Color3.fromRGB(180, 180, 220),
    },

    ToolESP = {
        Enabled = true,
        Color = Color3.fromRGB(255, 220, 50),
        Size = 12,
    },

    ToolHighlight = {
        Enabled = true,
        FillColor = Color3.fromRGB(255, 220, 50),
        FillTransparency = 0.5,
    },

    Chams = {
        Enabled = true,
        FillColor = Color3.fromRGB(140, 60, 255),
        FillTransparency = 0.6,
    },

    OffscreenArrows = {
        Enabled = true,
        Color = Color3.fromRGB(0, 180, 255),
        SecondaryColor = Color3.fromRGB(160, 200, 255),
        Size = 18,
        Width = 12,
        Margin = 40,
        Transparency = 0.85,
        ShowDistance = true,
    },
})

esp:ApplyPreset("Cyber")
esp:Start()

game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.F then
        esp:SetConfig({ Tracers = { Enabled = not esp.Config.Tracers.Enabled } })
    elseif input.KeyCode == Enum.KeyCode.G then
        esp:SetConfig({ Chams = { Enabled = not esp.Config.Chams.Enabled } })
    elseif input.KeyCode == Enum.KeyCode.T then
        esp:SetConfig({ OffscreenArrows = { Enabled = not esp.Config.OffscreenArrows.Enabled } })
    end
end)