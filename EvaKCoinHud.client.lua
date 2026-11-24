-- ============================================================
--  EvaKCoinHud (LocalScript в StarterPlayerScripts)
--  Счётчик бейджей справа сверху (золотая монета + число). При получении бейджей число "подпрыгивает"
--  и над ним всплывает +N. Читает атрибут игрока Badges.
-- ============================================================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CREAM = Color3.fromRGB(255, 229, 200)
local GOLD = Color3.fromRGB(255, 214, 110)

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in props do o[k] = v end
	o.Parent = parent
	return o
end

local gui = new("ScreenGui", { Name = "EvaKCoinGui", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 88, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, playerGui)
local pill = new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -24, 0, 10), Size = UDim2.fromOffset(150, 46), BackgroundColor3 = Color3.fromRGB(16, 14, 14),
	BackgroundTransparency = 0.25, BorderSizePixel = 0 }, gui)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, pill)
local us = new("UIScale", {}, pill)
local function rescale()
	local cam = workspace.CurrentCamera
	local v = cam and cam.ViewportSize or Vector2.new(1280, 720)
	us.Scale = math.clamp(math.min(v.X / 1100, v.Y / 700), 0.6, 1.1)
end
rescale()
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale) end

-- монета (восьмиугольник из двух повёрнутых квадратов)
local coin = new("Frame", { Position = UDim2.fromOffset(-6, -4), Size = UDim2.fromOffset(54, 54), BackgroundTransparency = 1, ZIndex = 3 }, pill)
for i = 0, 1 do
	local sq = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(34, 34), Rotation = i * 45,
		BackgroundColor3 = i == 0 and Color3.fromRGB(255, 224, 120) or Color3.fromRGB(240, 190, 70), BorderSizePixel = 0, ZIndex = 3 }, coin)
	new("UICorner", { CornerRadius = UDim.new(0, 6) }, sq)
end
local inner = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(24, 24), Rotation = 22,
	BackgroundColor3 = Color3.fromRGB(255, 238, 170), BorderSizePixel = 0, ZIndex = 4 }, coin)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, inner)

local num = new("TextLabel", { Position = UDim2.fromOffset(52, 0), Size = UDim2.new(1, -62, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.Oswald, TextSize = 36, TextColor3 = CREAM,
	TextXAlignment = Enum.TextXAlignment.Left, Text = "0", ZIndex = 3 }, pill)

local shown = math.floor(player:GetAttribute("Badges") or 0)
num.Text = tostring(shown)

local function pop(delta: number)
	local f = new("TextLabel", { AnchorPoint = Vector2.new(0, 0), Position = UDim2.fromOffset(60, 40), Size = UDim2.fromOffset(100, 30), BackgroundTransparency = 1, Font = Enum.Font.Oswald,
		TextSize = 30, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Left, Text = "+" .. tostring(delta), ZIndex = 5 }, pill)
	new("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 2 }, f)
	TweenService:Create(f, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.fromOffset(60, 70), TextTransparency = 1 }):Play()
	task.delay(1.5, function() f:Destroy() end)
	-- подпрыгивание монеты и числа
	TweenService:Create(coin, TweenInfo.new(0.12), { Position = UDim2.fromOffset(-6, -10) }):Play()
	task.delay(0.12, function() TweenService:Create(coin, TweenInfo.new(0.25, Enum.EasingStyle.Bounce), { Position = UDim2.fromOffset(-6, -4) }):Play() end)
end

player:GetAttributeChangedSignal("Badges"):Connect(function()
	local v = math.floor(player:GetAttribute("Badges") or 0)
	if v > shown then pop(v - shown) end
	shown = v
	num.Text = tostring(v)
end)
