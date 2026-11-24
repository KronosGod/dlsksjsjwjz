-- ============================================================
--  EvaKAtmosphere  (LocalScript в StarterPlayerScripts)
--  Страх и «ещё один забег»: нарастающее напряжение, пульс при низком HP, виньетка, зерно,
--  шёпоты на экране, тень на краю экрана, мигание света, кинематографичные плашки дверей
--  (10 / 25 / 50 / 66 / 100) и фраза после смерти, которая подталкивает сыграть ещё и заглянуть в магазин.
--  Всё рисуется кодом, без чужих ассетов. Звук - по желанию: впиши ID в SOUNDS.
--  Читает атрибуты: IntroDone, EvaKDoorsNow, EvaKHpNow, EvaKLowEnd (их ставят EvaKGameplay и GraceIntro).
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SOUNDS = {         -- rbxassetid://... (пусто = без звука)
	heart = "",          -- удары сердца (зацикленный, громкость растёт с напряжением)
	drone = "",          -- низкий гул (зацикленный)
	stinger = "",        -- короткий «удар» при появлении тени/на плашках дверей
}

local WHISPERS = {
	"don't look back", "it knows your name", "someone is breathing", "the hotel is listening",
	"you were warned", "keep walking", "not alone",
	"door by door", "it is behind the next one", "the guest list has your name", "pray quietly",
	"nobody checks out", "he is counting your steps", "turn around", "do not turn around",
}
local MILESTONES = {
	[10]  = { "DOOR 10",  "the lobby feels very far away" },
	[25]  = { "DOOR 25",  "most guests never get this far" },
	[50]  = { "DOOR 50",  "something has started to follow" },
	[66]  = { "DOOR 66",  "the ballroom remembers your steps" },
	[100] = { "DOOR 100", "the hotel is out of rooms. it is not out of doors." },
}
local AFTER_DEATH = {
	"The hotel keeps your name. Come back.",
	"So close. One more run?",
	"It was right behind you. Try again.",
	"The cases in the SHOP hold things the hotel dropped.",
	"CARBON wears the hotel's colours. Look in the SHOP.",
	"Every guest comes back. That is how it works.",
}

local function lowEnd(): boolean return player:GetAttribute("EvaKLowEnd") == true end

-- ---------- UI ----------
local gui = Instance.new("ScreenGui")
gui.Name = "EvaKAtmosphere"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 60
gui.Parent = playerGui

local function frame(parent: Instance, props): Frame
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0; f.BackgroundColor3 = Color3.new(0, 0, 0)
	for k, v in props do (f :: any)[k] = v end
	f.Parent = parent
	return f
end

local vigFrames = {}
do
	local specs = {   -- сторона, размер, позиция, поворот градиента
		{ UDim2.new(1, 0, 0.28, 0), UDim2.fromScale(0, 0), 90 },
		{ UDim2.new(1, 0, 0.28, 0), UDim2.fromScale(0, 0.72), 270 },
		{ UDim2.new(0.22, 0, 1, 0), UDim2.fromScale(0, 0), 0 },
		{ UDim2.new(0.22, 0, 1, 0), UDim2.fromScale(0.78, 0), 180 },
	}
	for _, s in specs do
		local f = frame(gui, { Size = s[1], Position = s[2], BackgroundTransparency = 1, Visible = false, ZIndex = 1 })
		local g = Instance.new("UIGradient")
		g.Rotation = s[3]
		g.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
		g.Parent = f
		table.insert(vigFrames, f)
	end
end

local blink = frame(gui, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2, Visible = false })
local redPulse = frame(gui, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(120, 0, 0), BackgroundTransparency = 1, ZIndex = 1, Visible = false })

local grain = {}
for i = 1, 22 do
	local f = frame(gui, { Size = UDim2.fromOffset(3, 3), BackgroundTransparency = 1, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 3, Visible = false })
	table.insert(grain, f)
end

local whisper = Instance.new("TextLabel")
whisper.AnchorPoint = Vector2.new(0.5, 0.5); whisper.Position = UDim2.fromScale(0.5, 0.74); whisper.Size = UDim2.fromOffset(700, 40)
whisper.BackgroundTransparency = 1; whisper.Font = Enum.Font.Arcade; whisper.TextSize = 22; whisper.TextColor3 = Color3.fromRGB(190, 30, 30)
whisper.TextTransparency = 1; whisper.Text = ""; whisper.ZIndex = 5; whisper.Parent = gui
local ws = Instance.new("UIStroke"); ws.Color = Color3.new(0, 0, 0); ws.Thickness = 1.5; ws.Transparency = 1; ws.Parent = whisper

-- тень на краю экрана
local shadow = frame(gui, { Size = UDim2.fromOffset(70, 230), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.04, 0.96), BackgroundTransparency = 1, ZIndex = 4, Visible = false })
local shHead = frame(shadow, { Size = UDim2.fromOffset(42, 46), Position = UDim2.fromOffset(14, 0), BackgroundColor3 = Color3.fromRGB(2, 0, 0), BackgroundTransparency = 0 })
local shBody = frame(shadow, { Size = UDim2.fromOffset(60, 175), Position = UDim2.fromOffset(5, 52), BackgroundColor3 = Color3.fromRGB(2, 0, 0), BackgroundTransparency = 0 })
for _, eyeX in { 20, 36 } do
	frame(shHead, { Size = UDim2.fromOffset(6, 4), Position = UDim2.fromOffset(eyeX - 14, 16), BackgroundColor3 = Color3.fromRGB(255, 40, 30), ZIndex = 5 })
end

-- плашка двери
local bars = {
	frame(gui, { Size = UDim2.new(1, 0, 0.12, 0), Position = UDim2.new(0, 0, -0.12, 0), ZIndex = 6 }),
	frame(gui, { Size = UDim2.new(1, 0, 0.12, 0), Position = UDim2.new(0, 0, 1, 0), ZIndex = 6 }),
}
local cardTitle = Instance.new("TextLabel")
cardTitle.AnchorPoint = Vector2.new(0.5, 0.5); cardTitle.Position = UDim2.fromScale(0.5, 0.42); cardTitle.Size = UDim2.fromOffset(800, 70)
cardTitle.BackgroundTransparency = 1; cardTitle.Font = Enum.Font.Arcade; cardTitle.TextSize = 54; cardTitle.TextColor3 = Color3.fromRGB(240, 210, 150)
cardTitle.TextTransparency = 1; cardTitle.ZIndex = 7; cardTitle.Parent = gui
local cardSub = cardTitle:Clone(); cardSub.Position = UDim2.fromScale(0.5, 0.5); cardSub.Size = UDim2.fromOffset(900, 30); cardSub.TextSize = 20
cardSub.TextColor3 = Color3.fromRGB(190, 160, 130); cardSub.Parent = gui

local lobbyMsg = Instance.new("TextLabel")
lobbyMsg.AnchorPoint = Vector2.new(0.5, 1); lobbyMsg.Position = UDim2.new(0.5, 0, 1, -22); lobbyMsg.Size = UDim2.fromOffset(900, 28)
lobbyMsg.BackgroundTransparency = 1; lobbyMsg.Font = Enum.Font.Arcade; lobbyMsg.TextSize = 18; lobbyMsg.TextColor3 = Color3.fromRGB(220, 190, 140)
lobbyMsg.TextTransparency = 1; lobbyMsg.ZIndex = 5; lobbyMsg.Parent = gui

-- ---------- звук (по желанию) ----------
local snd = {}
for name, id in SOUNDS do
	if id ~= "" then
		local s = Instance.new("Sound")
		s.Name = "EvaKAtmo_" .. name; s.SoundId = id; s.Looped = name ~= "stinger"; s.Volume = 0; s.Parent = gui
		snd[name] = s
	end
end
local function stinger(vol: number)
	local s = snd.stinger
	if s then s.Volume = vol; s:Play() end
end

-- ---------- пост-эффекты на время забега ----------
local cc: ColorCorrectionEffect? = nil
local bloom: BloomEffect? = nil
local function ensureFx(on: boolean)
	if on and not cc then
		local c = Instance.new("ColorCorrectionEffect"); c.Name = "EvaKAtmoCC"; c.Parent = Lighting; cc = c
		if not lowEnd() then
			local b = Instance.new("BloomEffect"); b.Name = "EvaKAtmoBloom"; b.Intensity = 0.25; b.Size = 18; b.Threshold = 1.6; b.Parent = Lighting; bloom = b
		end
	elseif not on and cc then
		cc:Destroy(); cc = nil
		if bloom then bloom:Destroy(); bloom = nil end
	end
end

-- ---------- состояние ----------
local inRun = false
local runClock = 0
local spike = 0             -- кратковременный всплеск напряжения (0..1)
local bestDoor = 0
local lastDoors = 0


-- ГОЛОС ЧУДОВИЩА: рык, замедленный и с эхом (настоящая речь требует своего аудио: впиши ID в DEVIL_VOICE_ID)
local DEVIL_VOICE_ID = "rbxassetid://9119864327"
local function devilVoice(text: string)
	if DEVIL_VOICE_ID == "" then return end
	local SoundService = game:GetService("SoundService")
	local snd = Instance.new("Sound")
	snd.SoundId = DEVIL_VOICE_ID; snd.Volume = 0.9; snd.PlaybackSpeed = 0.62
	local ps = Instance.new("PitchShiftSoundEffect"); ps.Octave = 0.55; ps.Parent = snd
	local ds = Instance.new("DistortionSoundEffect"); ds.Level = 0.35; ds.Parent = snd
	local rv = Instance.new("ReverbSoundEffect"); rv.DecayTime = 3.2; rv.Wetness = 6; rv.Parent = snd
	local eq = Instance.new("EqualizerSoundEffect"); eq.LowGain = 6; eq.MidGain = -4; eq.HighGain = -8; eq.Parent = snd
	snd.Parent = SoundService
	snd:Play()
	task.delay(math.clamp(#text * 0.07, 1.2, 3.4), function() if snd.Parent then snd:Stop(); snd:Destroy() end end)
end
local function say(text: string, hold: number?)
	whisper.Text = text
	whisper.TextColor3 = Color3.fromRGB(215, 30, 25)
	devilVoice(text)
	TweenService:Create(whisper, TweenInfo.new(1.2), { TextTransparency = 0.15 }):Play()
	TweenService:Create(ws, TweenInfo.new(1.2), { Transparency = 0.2 }):Play()
	task.delay((hold or 2.8) + 1.2, function()
		if whisper.Text ~= text then return end
		TweenService:Create(whisper, TweenInfo.new(1.6), { TextTransparency = 1 }):Play()
		TweenService:Create(ws, TweenInfo.new(1.6), { Transparency = 1 }):Play()
	end)
end

local function doBlink()   -- свет «моргает»
	if not inRun then return end
	blink.Visible = true
	for _, t in { 0.35, 0.9, 0.2, 0.75, 1 } do
		blink.BackgroundTransparency = t
		task.wait(0.06 + math.random() * 0.06)
	end
	blink.Visible = false
	spike = math.max(spike, 0.4)
end

local function doShadow()  -- силуэт на краю экрана
	if not inRun then return end
	local left = math.random() < 0.5
	shadow.Position = UDim2.fromScale(left and 0.035 or 0.965, 0.97)
	shadow.Visible = true
	stinger(0.6)
	spike = 1
	for i = 1, 5 do
		shadow.Visible = (i % 2 == 1)
		task.wait(0.06)
	end
	shadow.Visible = true
	task.wait(0.28)
	shadow.Visible = false
end

local function milestone(n: number)
	local m = MILESTONES[n]
	if not m then return end
	stinger(0.5)
	cardTitle.Text, cardSub.Text = m[1], m[2]
	local ti = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(bars[1], ti, { Position = UDim2.new(0, 0, 0, 0) }):Play()
	TweenService:Create(bars[2], ti, { Position = UDim2.new(0, 0, 0.88, 0) }):Play()
	TweenService:Create(cardTitle, TweenInfo.new(1.1), { TextTransparency = 0 }):Play()
	task.wait(0.6)
	TweenService:Create(cardSub, TweenInfo.new(1.1), { TextTransparency = 0.1 }):Play()
	task.wait(3.2)
	local to = TweenInfo.new(1.2)
	TweenService:Create(cardTitle, to, { TextTransparency = 1 }):Play()
	TweenService:Create(cardSub, to, { TextTransparency = 1 }):Play()
	TweenService:Create(bars[1], to, { Position = UDim2.new(0, 0, -0.12, 0) }):Play()
	TweenService:Create(bars[2], to, { Position = UDim2.new(0, 0, 1, 0) }):Play()
end

local function lobbyLine(text: string)
	lobbyMsg.Text = text
	TweenService:Create(lobbyMsg, TweenInfo.new(1.5), { TextTransparency = 0 }):Play()
	task.delay(7, function()
		if lobbyMsg.Text == text then TweenService:Create(lobbyMsg, TweenInfo.new(2), { TextTransparency = 1 }):Play() end
	end)
end

-- ---------- события забега ----------
local function onIntro()
	local now = player:GetAttribute("IntroDone") == true
	if now and not inRun then
		inRun = true; runClock = 0; spike = 0; lastDoors = 0
		ensureFx(true)
		for _, s in snd do if s.Looped then s:Play() end end
	elseif not now and inRun then
		inRun = false
		ensureFx(false)
		for _, s in snd do if s.Looped then s:Stop() end end
		for _, f in vigFrames do f.Visible = false end
		redPulse.Visible = false
		for _, g in grain do g.Visible = false end
		shadow.Visible = false; blink.Visible = false
		if lastDoors >= 3 then
			task.delay(2.5, function()
				if not inRun then lobbyLine("DOOR " .. lastDoors .. ".  " .. AFTER_DEATH[math.random(1, #AFTER_DEATH)]) end
			end)
		end
	end
end
player:GetAttributeChangedSignal("IntroDone"):Connect(onIntro)
onIntro()

player:GetAttributeChangedSignal("EvaKDoorsNow"):Connect(function()
	local n = player:GetAttribute("EvaKDoorsNow") or 0
	if n > lastDoors then
		lastDoors = n
		if n > bestDoor then bestDoor = n end
		if MILESTONES[n] then task.spawn(milestone, n) end
	end
end)

player:GetAttributeChangedSignal("EvaKHpNow"):Connect(function()
	-- удар по HP: красная вспышка
	local hp = player:GetAttribute("EvaKHpNow") or 100
	if inRun and hp < (player:GetAttribute("EvaKHpPrev") or 100) then
		spike = 1
		redPulse.Visible = true; redPulse.BackgroundTransparency = 0.55
		TweenService:Create(redPulse, TweenInfo.new(0.7), { BackgroundTransparency = 1 }):Play()
	end
	player:SetAttribute("EvaKHpPrev", hp)
end)

-- случайные «жуткие» события: редко, чтобы не приедались
task.spawn(function()
	while true do
		task.wait(math.random(35, 80))
		if inRun and runClock > 25 then
			local r = math.random()
			if r < 0.5 then say(WHISPERS[math.random(1, #WHISPERS)])
			elseif r < 0.8 then task.spawn(doBlink)
			else task.spawn(doShadow) end
		end
	end
end)
task.spawn(function()   -- редкая тень отдельно, чтобы не пугать слишком часто
	while true do
		task.wait(math.random(120, 260))
		if inRun and runClock > 90 then task.spawn(doShadow) end
	end
end)

-- ---------- покадровое напряжение ----------
local phase = 0
local accGrain = 0
RunService.RenderStepped:Connect(function(dt)
	if not inRun then return end
	runClock += dt
	local hp = player:GetAttribute("EvaKHpNow") or 100
	local doors = player:GetAttribute("EvaKDoorsNow") or 0
	local base = math.clamp(doors / 100, 0, 1) * 0.35 + math.clamp(runClock / 600, 0, 1) * 0.1
	local low = math.clamp((60 - hp) / 60, 0, 1)
	spike = math.max(0, spike - dt * 0.7)
	local fear = player:GetAttribute("EvaKFear") or 0   -- близость монстра (ставит EvaKCinema)
	local T = math.clamp(base + low * 0.7 + spike * 0.5 + fear * 0.6, 0, 1)

	-- пульс: чем ниже HP и выше напряжение, тем чаще
	phase += dt * (0.9 + T * 2.6)
	local beat = math.max(0, math.sin(phase * math.pi * 2)) ^ 6
	local vig = math.clamp(0.9 - (0.25 + T * 0.55) - beat * low * 0.35, 0.05, 1)   -- прозрачность виньетки (меньше = темнее)
	for _, f in vigFrames do
		f.Visible = true
		f.BackgroundTransparency = vig
	end
	if cc then
		cc.Saturation = -0.12 - T * 0.3
		cc.Contrast = 0.06 + T * 0.12 + beat * low * 0.1
		cc.TintColor = Color3.new(1, 1 - T * 0.12, 1 - T * 0.2)
		cc.Brightness = 0.03 - T * 0.03
	end
	if bloom then bloom.Intensity = 0.2 + T * 0.4 + spike * 0.4 end
	if snd.heart then snd.heart.Volume = low * 0.9; snd.heart.PlaybackSpeed = 0.9 + T * 0.6 end
	if snd.drone then snd.drone.Volume = 0.15 + T * 0.5 end

	-- зерно плёнки
	if not lowEnd() then
		accGrain += dt
		if accGrain > 0.08 then
			accGrain = 0
			for _, g in grain do
				g.Visible = true
				g.Position = UDim2.fromScale(math.random(), math.random())
				g.BackgroundColor3 = math.random() < 0.5 and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
				g.BackgroundTransparency = 0.88 - T * 0.12
			end
		end
	else
		for _, g in grain do g.Visible = false end
	end
end)
