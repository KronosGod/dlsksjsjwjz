-- ============================================================
--  EvaKCursor (LocalScript в StarterPlayerScripts)
--  Курсор-щупальце: 30 сегментов, сужается к кончику, присоски по нижней стороне, мокрый блик,
--  инерция и волна по телу; при наведении на кнопку присоски наливаются янтарём, при клике по телу бежит судорога.
--  Работает только в лобби (в катке InMap = true курсор прячется). Вкл/выкл: атрибут игрока EvaKCursorOn.
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
if player:GetAttribute("EvaKCursorOn") == nil then player:SetAttribute("EvaKCursorOn", true) end

local gui = Instance.new("ScreenGui")
gui.Name = "EvaKCursorGui"; gui.IgnoreGuiInset = true; gui.ResetOnSpawn = false; gui.DisplayOrder = 1000; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local N, SEG = 30, 4.4
local pts: {Vector2} = {}
local body: {Frame} = {}
local shine: {Frame} = {}
local sucker: {Frame?} = {}
local suckerDot: {Frame?} = {}

local m0 = UIS:GetMouseLocation()
for i = 1, N do pts[i] = m0 + Vector2.new(i * 2.2, i * 3.4) end

local function lerpC(a: Color3, b: Color3, t: number) return a:Lerp(b, t) end
local FLESH_TIP, FLESH_BASE = Color3.fromRGB(96, 58, 74), Color3.fromRGB(24, 13, 20)

for i = 1, N - 1 do
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5); f.BorderSizePixel = 0; f.ZIndex = N - i
	f.BackgroundColor3 = lerpC(FLESH_TIP, FLESH_BASE, (i - 1) / (N - 2))
	f.Parent = gui
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = f
	local g = Instance.new("UIGradient")   -- объём: светлее сверху, темнее снизу
	g.Rotation = 90
	g.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 235, 245)), ColorSequenceKeypoint.new(0.55, Color3.fromRGB(190, 160, 175)), ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 40, 52)) })
	g.Parent = f
	local sh = Instance.new("Frame")   -- мокрый блик
	sh.AnchorPoint = Vector2.new(0.5, 0.5); sh.Position = UDim2.fromScale(0.5, 0.26); sh.Size = UDim2.fromScale(0.78, 0.2)
	sh.BackgroundColor3 = Color3.fromRGB(255, 225, 240); sh.BackgroundTransparency = 0.55; sh.BorderSizePixel = 0; sh.ZIndex = N - i + 1
	local sc = Instance.new("UICorner"); sc.CornerRadius = UDim.new(1, 0); sc.Parent = sh
	sh.Parent = f
	if i >= 4 and i % 2 == 0 then   -- присоски
		local s = Instance.new("Frame")
		s.AnchorPoint = Vector2.new(0.5, 0.5); s.Position = UDim2.fromScale(0.5, 0.8); s.Size = UDim2.fromScale(0.46, 0.46)
		s.SizeConstraint = Enum.SizeConstraint.RelativeYY
		s.BackgroundColor3 = Color3.fromRGB(196, 142, 150); s.BorderSizePixel = 0; s.ZIndex = N - i + 2
		local c2 = Instance.new("UICorner"); c2.CornerRadius = UDim.new(1, 0); c2.Parent = s
		local d = Instance.new("Frame")
		d.AnchorPoint = Vector2.new(0.5, 0.5); d.Position = UDim2.fromScale(0.5, 0.5); d.Size = UDim2.fromScale(0.5, 0.5)
		d.BackgroundColor3 = Color3.fromRGB(70, 28, 38); d.BorderSizePixel = 0; d.ZIndex = N - i + 3
		local c3 = Instance.new("UICorner"); c3.CornerRadius = UDim.new(1, 0); c3.Parent = d
		d.Parent = s; s.Parent = f
		sucker[i] = s; suckerDot[i] = d
	end
	body[i] = f; shine[i] = sh
end

local pulse = 0          -- судорога по телу после клика
local hover = false
local lastHoverCheck = 0
local vel = Vector2.zero
local prevMouse = m0

UIS.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then pulse = 1 end
end)

local function isOverButton(pos: Vector2): boolean
	local ok, objs = pcall(function() return playerGui:GetGuiObjectsAtPosition(pos.X, pos.Y - 36) end)   -- -36: поправка на инсет
	if not ok then return false end
	for _, o in objs do
		if o:IsDescendantOf(gui) then continue end
		if (o:IsA("TextButton") or o:IsA("ImageButton")) and o.Visible and o.Active then return true end
	end
	return false
end

RunService.RenderStepped:Connect(function(dt)
	local locked = UIS.MouseBehavior == Enum.MouseBehavior.LockCenter   -- в забеге мышь прижата к центру: курсор не нужен, но в меню/чате/журнале он появляется
	local show = player:GetAttribute("EvaKCursorOn") ~= false and not locked
	gui.Enabled = show
	if not show then return end
	UIS.MouseIconEnabled = false
	local t = os.clock()
	local mp = UIS:GetMouseLocation()
	vel = vel:Lerp((mp - prevMouse) / math.max(dt, 1e-3), math.min(1, dt * 10)); prevMouse = mp
	local speed = math.clamp(vel.Magnitude / 1400, 0, 1)
	if t - lastHoverCheck > 0.06 then lastHoverCheck = t; hover = isOverButton(mp) end
	pulse = math.max(0, pulse - dt * 1.6)
	pts[1] = mp
	local rest = Vector2.new(0.5, 0.86).Unit
	for i = 2, N do
		local prev = pts[i - 1]
		local d = pts[i] - prev
		if d.Magnitude < 1e-3 then d = Vector2.new(0.4, 1) end
		local dir = d.Unit
		local k = i / N
		local perp = Vector2.new(-dir.Y, dir.X)
		local wave = (0.06 + 0.1 * speed + 0.2 * pulse * math.sin(t * 22 - i * 0.7)) * k
		dir = (dir + rest * (0.10 - 0.04 * speed) + perp * (math.sin(t * 3.2 - i * 0.55) * wave + math.sin(t * 1.3 + i * 0.2) * 0.02)).Unit
		pts[i] = prev + dir * SEG
	end
	for i = 1, N - 1 do
		local a, b = pts[i], pts[i + 1]
		local mid, diff = (a + b) / 2, b - a
		local k = (i - 1) / (N - 2)
		local thick = (2.4 + k * k * 11 + k * 3) * (1 + pulse * 0.25 * math.sin(t * 20 - i * 0.6))
		local f = body[i]
		f.Position = UDim2.fromOffset(mid.X, mid.Y)
		f.Size = UDim2.fromOffset(SEG * 1.9 + thick * 0.3, thick)
		f.Rotation = math.deg(math.atan2(diff.Y, diff.X))
		local s, d = sucker[i], suckerDot[i]
		if s and d then
			s.BackgroundColor3 = hover and Color3.fromRGB(255, 190, 90) or Color3.fromRGB(196, 142, 150)
			d.BackgroundColor3 = hover and Color3.fromRGB(150, 70, 20) or Color3.fromRGB(70, 28, 38)
			local breathe = 0.46 + 0.05 * math.sin(t * 4 + i)
			s.Size = UDim2.fromScale(breathe, breathe)
		end
		-- блик «бежит» по телу
		shine[i].BackgroundTransparency = 0.45 + 0.35 * (0.5 + 0.5 * math.sin(t * 2.4 - i * 0.5))
	end
end)

player:GetAttributeChangedSignal("EvaKCursorOn"):Connect(function()
	UIS.MouseIconEnabled = player:GetAttribute("EvaKCursorOn") == false
end)
