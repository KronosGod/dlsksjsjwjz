-- ============================================================
--  EvaKSick (LocalScript в StarterPlayerScripts)
--  1) Периодические «приступы страха»: тошнота, пульсация экрана в такт сердцу, качание камеры.
--  2) КРОВАВАЯ ЛУНА и другие красные ивенты: независимый красный свет/экран (не зависит от других скриптов).
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function inRun() return player:GetAttribute("EvaKInRun") == true end
local function low() return player:GetAttribute("EvaKLowEnd") == true end

local gui = Instance.new("ScreenGui")
gui.Name = "EvaKSickGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 9; gui.Parent = playerGui

-- виньетка: четыре красно-чёрных края
local vig = Instance.new("Frame"); vig.Size = UDim2.fromScale(1, 1); vig.BackgroundTransparency = 1; vig.BorderSizePixel = 0; vig.Parent = gui
local function edge(pos, size, rot)
	local f = Instance.new("Frame"); f.Position = pos; f.Size = size; f.BackgroundColor3 = Color3.fromRGB(90, 0, 0); f.BorderSizePixel = 0; f.BackgroundTransparency = 1; f.Parent = vig
	local g = Instance.new("UIGradient"); g.Rotation = rot; g.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }); g.Parent = f
	return f
end
local edges = {
	edge(UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.3), 90), edge(UDim2.fromScale(0, 0.7), UDim2.fromScale(1, 0.3), 270),
	edge(UDim2.fromScale(0, 0), UDim2.fromScale(0.25, 1), 0), edge(UDim2.fromScale(0.75, 0), UDim2.fromScale(0.25, 1), 180),
}
local note = Instance.new("TextLabel")
note.AnchorPoint = Vector2.new(0.5, 0.5); note.Position = UDim2.fromScale(0.5, 0.78); note.Size = UDim2.fromOffset(500, 30)
note.BackgroundTransparency = 1; note.Font = Enum.Font.Arcade; note.TextSize = 20; note.TextColor3 = Color3.fromRGB(200, 60, 50)
note.TextStrokeTransparency = 0.4; note.Text = ""; note.TextTransparency = 1; note.Parent = gui

local blur = Instance.new("BlurEffect"); blur.Name = "EvaKSickBlur"; blur.Size = 0; blur.Parent = Lighting
local sickCC = Instance.new("ColorCorrectionEffect"); sickCC.Name = "EvaKSickCC"; sickCC.Parent = Lighting

local MSGS = { "you feel sick...", "your heart is racing", "something is wrong", "you can't breathe", "it is close", "don't look back" }
local sick = 0          -- 0..1 текущая сила
local target = 0
local untilT = 0
local nextAt = os.clock() + math.random(50, 110)
local phase = 0

local function startEpisode(len)
	target = 0.65 + math.random() * 0.35
	untilT = os.clock() + len
	note.Text = MSGS[math.random(#MSGS)]
	TweenService:Create(note, TweenInfo.new(1.2), { TextTransparency = 0.15 }):Play()
	task.delay(math.min(5, len * 0.5), function() TweenService:Create(note, TweenInfo.new(1.5), { TextTransparency = 1 }):Play() end)
	player:SetAttribute("EvaKSick", true)
end

RunService:BindToRenderStep("EvaKSick", Enum.RenderPriority.Last.Value + 4, function(dt)
	local running = inRun()
	if running and os.clock() > nextAt and target == 0 then
		startEpisode(math.random(9, 16))
		nextAt = os.clock() + math.random(55, 130)
	end
	if target > 0 and (os.clock() > untilT or not running) then target = 0; player:SetAttribute("EvaKSick", false) end
	sick += (target - sick) * math.min(1, dt * (target > 0 and 1.5 or 0.8))
	if sick < 0.003 then sick = 0 end
	-- ручной вызов: player:SetAttribute("EvaKSickNow", true) (для скримеров)
	local fear = player:GetAttribute("EvaKFear") or 0
	local s = math.max(sick, fear > 0.85 and (fear - 0.85) * 3 or 0)
	local hp = player:GetAttribute("EvaKHpNow") or 100
	local lowHp = (running and hp < 35) and (1 - hp / 35) * 0.6 or 0
	s = math.max(s, lowHp)
	if s <= 0 then
		for _, e in edges do e.BackgroundTransparency = 1 end
		blur.Size = 0; sickCC.Enabled = false
		return
	end
	-- сердцебиение: двойной удар (луб-даб), чем сильнее страх, тем чаще
	local rate = 1.1 + s * 1.3
	phase += dt * rate
	local p = phase % 1
	local beat = math.max(math.exp(-((p - 0.05) * 14) ^ 2), 0.7 * math.exp(-((p - 0.32) * 14) ^ 2))
	for _, e in edges do e.BackgroundTransparency = 1 - math.clamp((0.18 + beat * 0.6) * s, 0, 0.85) end
	sickCC.Enabled = true
	sickCC.Saturation = -0.55 * s
	sickCC.TintColor = Color3.new(1, 1 - 0.25 * s * beat, 1 - 0.3 * s * beat)
	sickCC.Contrast = 0.1 * s * beat
	if not low() then blur.Size = (3 + beat * 9) * s end
	local cam = workspace.CurrentCamera
	if cam then
		local t = os.clock()
		-- тошнота: плывущий крен + «качка» + пульсация поля зрения
		local roll = math.sin(t * 0.9) * 0.07 * s + math.sin(t * 2.3) * 0.015 * s
		local pitch = math.sin(t * 0.6 + 1) * 0.04 * s
		cam.CFrame = cam.CFrame * CFrame.Angles(pitch + beat * 0.012 * s, math.cos(t * 0.7) * 0.03 * s, roll)
		cam.FieldOfView = cam.FieldOfView + beat * 3.5 * s - math.sin(t * 0.9) * 2 * s
	end
end)

-- ============================================================
--  КРОВАВАЯ ЛУНА (и красные ивенты): жёсткое независимое освещение
-- ============================================================
local RED_EVENTS = { BloodMoon = 1, Apocalypse = 0.85, TheEnd = 1, Judgment = 0.9 }
local bcc = Instance.new("ColorCorrectionEffect"); bcc.Name = "EvaKBloodCC"; bcc.Enabled = false; bcc.Parent = Lighting
local rOver = Instance.new("Frame"); rOver.Size = UDim2.fromScale(1, 1); rOver.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
rOver.BackgroundTransparency = 1; rOver.BorderSizePixel = 0; rOver.ZIndex = 1; rOver.Parent = gui
local moon = Instance.new("Frame"); moon.AnchorPoint = Vector2.new(0.5, 0.5); moon.Position = UDim2.fromScale(0.82, 0.14); moon.Size = UDim2.fromOffset(110, 110)
moon.BackgroundColor3 = Color3.fromRGB(210, 20, 15); moon.BackgroundTransparency = 1; moon.BorderSizePixel = 0; moon.Parent = gui
Instance.new("UICorner", moon).CornerRadius = UDim.new(1, 0)
local moonStroke = Instance.new("UIStroke"); moonStroke.Color = Color3.fromRGB(255, 70, 50); moonStroke.Thickness = 3; moonStroke.Transparency = 1; moonStroke.Parent = moon
local intens = 0
local saved = nil

RunService:BindToRenderStep("EvaKBloodMoon", Enum.RenderPriority.Last.Value + 6, function(dt)
	local k = 0
	for part in string.gmatch(tostring(workspace:GetAttribute("EvaKEvents") or workspace:GetAttribute("EvaKEvent") or ""), "[^;]+") do
		k = math.max(k, RED_EVENTS[part:match("^([^=]+)") or ""] or 0)
	end
	intens += (k - intens) * math.min(1, dt * 1.5)
	if intens < 0.01 then
		if saved then
			Lighting.Ambient = saved.a; Lighting.OutdoorAmbient = saved.o; saved = nil
		end
		bcc.Enabled = false; rOver.BackgroundTransparency = 1; moon.BackgroundTransparency = 1; moonStroke.Transparency = 1
		return
	end
	if not saved then saved = { a = Lighting.Ambient, o = Lighting.OutdoorAmbient } end
	local pulse = 0.5 + 0.5 * math.sin(os.clock() * 1.3)
	Lighting.Ambient = Color3.fromRGB(110 + pulse * 40, 6, 6)
	Lighting.OutdoorAmbient = Color3.fromRGB(100, 4, 4)
	bcc.Enabled = true
	bcc.TintColor = Color3.fromRGB(255, 70 - 25 * intens, 60 - 25 * intens)
	bcc.Saturation = 0.35 * intens; bcc.Contrast = 0.18 * intens; bcc.Brightness = -0.06 * intens
	rOver.BackgroundTransparency = 1 - (0.2 + pulse * 0.1) * intens
	moon.BackgroundTransparency = 1 - 0.85 * intens; moonStroke.Transparency = 1 - 0.8 * intens
	local at = Lighting:FindFirstChildOfClass("Atmosphere")
	if at then at.Color = Color3.fromRGB(160, 8, 8); at.Haze = 4; at.Density = math.max(at.Density, 0.5) end
end)

print("[EvaKSick] ready")
