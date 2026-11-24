-- ============================================================
--  EvaKExtra (LocalScript в StarterPlayerScripts)
--  Эффекты ивентов, таймер ивента справа снизу, сообщения монстров,
--  кнопка «?» (справа сверху в меню) и окно COSMETICS (ауры, крылья, глаза, титулы).
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local rf = ReplicatedStorage:WaitForChild("EvaKExtra", 20)
local fx = ReplicatedStorage:WaitForChild("EvaKExtraFx", 20)

local RED, GOLD = Color3.fromRGB(215, 48, 40), Color3.fromRGB(230, 200, 140)
local FONT = Enum.Font.Arcade

local EVENT_INFO = {
	BloodMoon     = { "BLOOD MOON", "🌑", "The whole screen turns red" },
	Blackout      = { "BLACKOUT", "💡", "The lights are completely out" },
	Invasion      = { "INVASION", "👁", "Monsters appear more often" },
	GiantEvaK     = { "GIANT EVAK", "👹", "A giant EvaK hunts the players" },
	Gravity       = { "GRAVITY", "🪐", "Everyone starts to float" },
	FakeUpdate    = { "FAKE UPDATE", "⚠", "A fake update message appears" },
	Earthquake    = { "EARTHQUAKE", "🌋", "The map starts to shake" },
	Doppelgangers = { "DOPPELGANGERS", "👥", "Copies of players appear" },
	SilentMode    = { "SILENT MODE", "🔇", "All music and sounds vanish" },
	Apocalypse    = { "APOCALYPSE", "☠", "Every event at once" },
	OwnerIsHere   = { "THE OWNER IS HERE", "👑", "EvaK watches over the hotel" },
	RealityError  = { "REALITY ERROR", "⚡", "Textures, light and UI glitch" },
	LastGuest     = { "THE LAST GUEST", "🧍", "Everyone sees the same stranger" },
	FalseExit     = { "FALSE EXIT", "🚪", "An exit door... leads to the hotel" },
	EvaKArrival   = { "EVAK'S ARRIVAL", "👤", "EvaK appears in the lobby" },
	Judgment      = { "THE JUDGMENT", "🩸", "The sky turns red" },
	LostSouls     = { "LOST SOULS", "👻", "Ghost players walk the map" },
	TheEnd        = { "THE END", "💀", "A global chase begins" },
	EternalNight  = { "ETERNAL NIGHT", "🌌", "Complete darkness" },
	Possession    = { "POSSESSION", "🌀", "Your movement is not your own" },
	TheEye        = { "THE EYE", "👁", "A giant eye above the hotel" },
}

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in props do o[k] = v end
	o.Parent = parent
	return o
end

local gui = new("ScreenGui", { Name = "EvaKExtraGui", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 120, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, playerGui)

-- ---------- таймер ивента справа снизу ----------
local box = new("Frame", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16), Size = UDim2.fromOffset(250, 76),
	BackgroundColor3 = Color3.fromRGB(12, 8, 8), BackgroundTransparency = 0.15, BorderSizePixel = 0 }, gui)
new("UICorner", { CornerRadius = UDim.new(0, 0) }, box)
new("UIStroke", { Color = RED, Thickness = 1.5, Transparency = 0.2 }, box)
local pic = new("TextLabel", { Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(60, 60), BackgroundColor3 = Color3.fromRGB(30, 8, 8),
	Text = "👁", TextSize = 36, Font = FONT, TextColor3 = Color3.new(1, 1, 1) }, box)
new("UICorner", { CornerRadius = UDim.new(0, 0) }, pic)
local evName = new("TextLabel", { Position = UDim2.fromOffset(76, 8), Size = UDim2.fromOffset(166, 24), BackgroundTransparency = 1, Text = "NEXT EVENT",
	TextXAlignment = Enum.TextXAlignment.Left, Font = FONT, TextSize = 17, TextColor3 = RED }, box)
local evTime = new("TextLabel", { Position = UDim2.fromOffset(76, 32), Size = UDim2.fromOffset(166, 20), BackgroundTransparency = 1, Text = "--:--",
	TextXAlignment = Enum.TextXAlignment.Left, Font = FONT, TextSize = 20, TextColor3 = GOLD }, box)
local evDesc = new("TextLabel", { Position = UDim2.fromOffset(76, 54), Size = UDim2.fromOffset(166, 16), BackgroundTransparency = 1, Text = "",
	TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Arcade, TextSize = 11, TextColor3 = Color3.fromRGB(170, 150, 130) }, box)

-- ---------- баннер/сообщения ----------
local banner = new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 70), Size = UDim2.fromOffset(700, 60),
	BackgroundTransparency = 1, Text = "", Font = FONT, TextSize = 34, TextColor3 = RED, TextStrokeTransparency = 0.2, TextTransparency = 1, TextStrokeColor3 = Color3.new(0, 0, 0) }, gui)
local msgToken = 0

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
local EVIL = { "evak", "guest", "behind you", "look up", "crawling", "watching", "bellman", "help me", "burns away", "ding" }
local function isEvil(t: string): boolean
	local l = t:lower()
	if l:find("unlocked") or l:find("lore note") or l:find("achievement") or l:find("badges") then return false end
	for _, k in EVIL do if l:find(k, 1, true) then return true end end
	return false
end
local function say(text: string, big: boolean?)
	msgToken += 1
	if isEvil(text) then devilVoice(text); banner.TextColor3 = Color3.fromRGB(215, 30, 25) else banner.TextColor3 = Color3.fromRGB(255, 255, 255) end
	local my = msgToken
	banner.Text = text
	banner.TextSize = big and 38 or 22
	banner.TextTransparency = 0; banner.TextStrokeTransparency = 0.2
	task.delay(big and 4 or 3.2, function()
		if msgToken == my then
			TweenService:Create(banner, TweenInfo.new(0.6), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end

-- ---------- эффекты ----------
local cc = new("ColorCorrectionEffect", { Name = "EvaKEvtCC", Enabled = false }, Lighting)
local update = new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(520, 110),
	BackgroundColor3 = Color3.fromRGB(20, 20, 24), BorderSizePixel = 0, Visible = false, Font = FONT, TextSize = 22, TextWrapped = true,
	TextColor3 = Color3.fromRGB(240, 240, 240), Text = "" }, gui)
new("UIStroke", { Color = Color3.fromRGB(120, 120, 130), Thickness = 2 }, update)

local shakeAmt, shakeUntil = 0, 0
fx.OnClientEvent:Connect(function(kind, a)
	if kind == "Greet" then
		task.spawn(function()
			local l = new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.82), Size = UDim2.fromOffset(700, 40), BackgroundTransparency = 1,
				Font = Enum.Font.Code, TextSize = 26, TextColor3 = Color3.fromRGB(190, 40, 34), TextTransparency = 1, ZIndex = 40, Text = "" }, gui)
			for _, line in a do
				l.Text = line
				TweenService:Create(l, TweenInfo.new(1.2), { TextTransparency = 0 }):Play()
				task.wait(3)
				TweenService:Create(l, TweenInfo.new(1.2), { TextTransparency = 1 }):Play()
				task.wait(1.6)
			end
			l:Destroy()
		end)
	elseif kind == "CaseWon" then
		say("CASE: " .. tostring(a.name) .. (a.dup and (" (duplicate, +" .. a.refund .. " badges)") or "!"), true)
	elseif kind == "Say" then say(tostring(a))
	elseif kind == "Shake" then shakeAmt = math.max(shakeAmt, tonumber(a) or 0.2); shakeUntil = os.clock() + 0.5
	elseif kind == "Scare" then
		shakeAmt = 0.6; shakeUntil = os.clock() + 0.6
		local f = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0.5, 0, 0), BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 50 }, gui)
		TweenService:Create(f, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
		task.delay(0.6, function() f:Destroy() end)
	end
end)

local mutedSounds: {[Sound]: number} = {}
local function setSilent(on: boolean)
	if on then
		for _, s in workspace:GetDescendants() do
			if s:IsA("Sound") and not mutedSounds[s] then mutedSounds[s] = s.Volume; s.Volume = 0 end
		end
		for _, s in SoundService:GetDescendants() do
			if s:IsA("Sound") and not mutedSounds[s] then mutedSounds[s] = s.Volume; s.Volume = 0 end
		end
	else
		for s, v in mutedSounds do if s.Parent then s.Volume = v end end
		table.clear(mutedSounds)
	end
end

local lastEvent = ""
local curSet: {[string]: boolean} = {}
local savedAmbient, savedBright = nil, nil
local COMMON = { BloodMoon = true, Blackout = true, Invasion = true, GiantEvaK = true, Gravity = true, FakeUpdate = true, Earthquake = true, Doppelgangers = true, SilentMode = true }
local glitchToken = 0
local overlay = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 20 }, gui)

local function showEyeOverlay(kind: string, secs: number)   -- гигантский глаз / силуэт хозяина над экраном
	overlay:ClearAllChildren()
	overlay.Visible = true
	if kind == "TheEye" then
		local white = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, -0.18), Size = UDim2.fromOffset(520, 300), BackgroundColor3 = Color3.fromRGB(240, 240, 240), ZIndex = 21 }, overlay)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, white)
		new("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 6 }, white)
		local iris = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.55), Size = UDim2.fromOffset(190, 190), BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 22 }, white)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, iris)
		task.spawn(function()
			local t0 = os.clock()
			while overlay.Visible and os.clock() - t0 < secs do
				local t = os.clock() - t0
				iris.Position = UDim2.fromScale(0.5 + math.sin(t * 0.9) * 0.18, 0.55 + math.cos(t * 0.6) * 0.1)
				white.Size = UDim2.fromOffset(520, (math.sin(t * 0.7) > 0.96) and 40 or 300)   -- моргание
				task.wait(0.05)
			end
		end)
	else   -- OwnerIsHere: тёмный силуэт с красными глазами сверху
		local body = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, -0.05), Size = UDim2.fromOffset(420, 240), BackgroundColor3 = Color3.fromRGB(4, 4, 6), BackgroundTransparency = 0.1, ZIndex = 21 }, overlay)
		new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, body)
		for _, x in { 0.35, 0.65 } do
			local e = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, 0.7), Size = UDim2.fromOffset(36, 14), BackgroundColor3 = Color3.fromRGB(255, 20, 20), ZIndex = 22 }, body)
			new("UICorner", { CornerRadius = UDim.new(1, 0) }, e)
		end
	end
	task.delay(secs, function() overlay.Visible = false; overlay:ClearAllChildren() end)
end

local function applyEvent(set: {[string]: boolean}, fresh: {[string]: boolean})
	local function on(n) return set[n] == true end
	cc.Enabled = on("BloodMoon") or on("Blackout") or set.Judgment == true or set.EternalNight == true
	cc.TintColor = Color3.new(1, 1, 1); cc.Saturation = 0; cc.Brightness = 0; cc.Contrast = 0
	if on("BloodMoon") then cc.TintColor = Color3.fromRGB(255, 45, 40); cc.Saturation = 0.3; cc.Brightness = -0.08; cc.Contrast = 0.12 end
	if set.Judgment == true then cc.TintColor = Color3.fromRGB(255, 40, 30); cc.Saturation = 0.6; cc.Contrast = 0.15 end
	if on("Blackout") or set.EternalNight == true then
		if not savedAmbient then savedAmbient, savedBright = Lighting.Ambient, Lighting.Brightness end
		Lighting.Ambient = Color3.fromRGB(2, 2, 3); Lighting.Brightness = 0
		cc.Brightness = (set.EternalNight == true) and -0.55 or -0.35
	elseif on("BloodMoon") then
		if not savedAmbient then savedAmbient, savedBright = Lighting.Ambient, Lighting.Brightness end
		Lighting.Ambient = Color3.fromRGB(120, 10, 10)
		local at = Lighting:FindFirstChildOfClass("Atmosphere")
		if at then at.Color = Color3.fromRGB(150, 10, 10); at.Density = 0.55 end
	elseif set.Judgment == true then
		if not savedAmbient then savedAmbient, savedBright = Lighting.Ambient, Lighting.Brightness end
		Lighting.Ambient = Color3.fromRGB(150, 20, 16)
	elseif savedAmbient then
		Lighting.Ambient = savedAmbient; Lighting.Brightness = savedBright or Lighting.Brightness
		savedAmbient = nil
	end
	setSilent(on("SilentMode"))
	glitchToken += 1
	local my = glitchToken
	if set.RealityError == true then   -- глитчи света, цвета и интерфейса
		cc.Enabled = true
		task.spawn(function()
			while glitchToken == my do
				cc.TintColor = Color3.fromHSV(math.random(), 0.5, 1)
				cc.Contrast = math.random() * 0.6; cc.Saturation = math.random() * 1.2 - 0.4
				box.Rotation = math.random(-4, 4); box.Position = UDim2.new(1, -16 + math.random(-12, 12), 1, -16 + math.random(-8, 8))
				shakeAmt = 0.15; shakeUntil = os.clock() + 0.2
				task.wait(0.08 + math.random() * 0.4)
				cc.TintColor = Color3.new(1, 1, 1); cc.Contrast = 0; cc.Saturation = 0
				box.Rotation = 0; box.Position = UDim2.new(1, -16, 1, -16)
				task.wait(0.4 + math.random() * 1.6)
			end
			box.Rotation = 0; box.Position = UDim2.new(1, -16, 1, -16)
		end)
	end
	if fresh.TheEye == true or fresh.OwnerIsHere == true then showEyeOverlay(fresh.TheEye and "TheEye" or "OwnerIsHere", 90) end
	if fresh.EvaKArrival == true and player:GetAttribute("EvaKInRun") ~= true then   -- EvaK появляется в лобби
		local f = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, ZIndex = 45 }, gui)
		local fig = new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 1.05), Size = UDim2.fromOffset(260, 560), BackgroundColor3 = Color3.fromRGB(3, 3, 5), BackgroundTransparency = 1, ZIndex = 46 }, f)
		new("UICorner", { CornerRadius = UDim.new(0.3, 0) }, fig)
		for _, x in { 0.35, 0.65 } do
			local e = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, 0.12), Size = UDim2.fromOffset(30, 12), BackgroundColor3 = Color3.fromRGB(255, 20, 20), BackgroundTransparency = 1, ZIndex = 47 }, fig)
			new("UICorner", { CornerRadius = UDim.new(1, 0) }, e)
			TweenService:Create(e, TweenInfo.new(2.5), { BackgroundTransparency = 0 }):Play()
		end
		TweenService:Create(f, TweenInfo.new(2), { BackgroundTransparency = 0.4 }):Play()
		TweenService:Create(fig, TweenInfo.new(2.5), { BackgroundTransparency = 0 }):Play()
		task.delay(7, function() f:Destroy() end)
	end
	if fresh.FakeUpdate == true then
		task.spawn(function()
			update.Visible = true
			update.Text = "⚠ GAME UPDATE v2.0\nThis server will shut down in 10 seconds..."
			task.wait(5)
			update.Text = "⚠ Teleporting to a new server..."
			task.wait(3)
			update.Visible = false
			say("...just kidding.", false)
		end)
	end
end

local function restore() applyEvent({}, {}); update.Visible = false; overlay.Visible = false; overlay:ClearAllChildren() end

-- ---------- тряска камеры (землетрясение/монстры) ----------
RunService:BindToRenderStep("EvaKExtraShake", Enum.RenderPriority.Last.Value + 3, function()
	local amt = 0
	if curSet.Earthquake or curSet.Apocalypse or curSet.TheEnd then amt = 0.012 end
	if curSet.Possession then
		local cam0 = workspace.CurrentCamera
		local t0 = os.clock()
		cam0.CFrame = cam0.CFrame * CFrame.Angles(0, 0, math.sin(t0 * 1.6) * 0.16)
		cam0.FieldOfView = 70 + math.sin(t0 * 0.9) * 8
	end
	if os.clock() < shakeUntil then amt = math.max(amt, shakeAmt * 0.04) end
	if amt <= 0 then return end
	local cam = workspace.CurrentCamera
	local t = os.clock() * 30
	cam.CFrame = cam.CFrame * CFrame.Angles(math.noise(t, 0) * amt, math.noise(0, t) * amt, math.noise(t, t) * amt)
end)

-- ---------- цикл таймера ----------
local function fmt(sec: number): string
	sec = math.max(0, math.floor(sec))
	return string.format("%02d:%02d", sec // 60, sec % 60)
end
local function parseEvents(): {[string]: boolean}
	local set = {}
	local str = workspace:GetAttribute("EvaKEvents")
	if type(str) == "string" and str ~= "" then
		for part in string.gmatch(str, "[^;]+") do
			local n = part:match("^([^=]+)")
			if n then set[n] = true end
		end
	else
		local ev = workspace:GetAttribute("EvaKEvent") or ""
		if ev ~= "" then set[ev] = true end
	end
	return set
end
task.spawn(function()
	while true do
		local set = parseEvents()
		local keys = {}
		for n in set do table.insert(keys, n) end
		table.sort(keys)
		local sig = table.concat(keys, ",")
		if sig ~= lastEvent then
			local fresh = {}
			local old = curSet
			for n in set do if not old[n] then fresh[n] = true end end
			lastEvent = sig
			curSet = set
			if #keys > 0 then
				local shown = 0
				for _, n in keys do
					local info = EVENT_INFO[n]
					if fresh[n] and info and shown < 2 then shown += 1; say(info[2] .. " " .. info[1], true) end
				end
				applyEvent(set, fresh)
			else
				restore()
			end
		end
		box.Visible = false   -- плашки ивентов рисует EvaKEventHud
		task.wait(0.5)
	end
end)

-- ---------- кнопки меню: «?» и COSMETICS ----------
local function menuVisible(): boolean
	local m = playerGui:FindFirstChild("IntroMenu")
	return m ~= nil and (m :: ScreenGui).Enabled and player:GetAttribute("EvaKInRun") ~= true
end

local qBtn = new("TextButton", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -8, 1, -8), Size = UDim2.fromOffset(30, 30),
	BackgroundColor3 = Color3.fromRGB(26, 14, 10), Text = "?", Font = FONT, TextSize = 24, TextColor3 = GOLD, AutoButtonColor = true, Visible = false }, gui)
new("UIStroke", { Color = Color3.fromRGB(140, 100, 50), Thickness = 2 }, qBtn)
local cBtn = new("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -64, 0, 16), Size = UDim2.fromOffset(150, 40),
	BackgroundColor3 = Color3.fromRGB(40, 10, 10), Text = "COSMETICS", Font = FONT, TextSize = 16, TextColor3 = GOLD, AutoButtonColor = true, Visible = false }, gui)
new("UICorner", { CornerRadius = UDim.new(0, 0) }, cBtn)
new("UIStroke", { Color = RED, Thickness = 2 }, cBtn)

local function modal(w: number, h: number)
	local dim = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, Text = "", AutoButtonColor = false, Visible = false, ZIndex = 60 }, gui)
	local p = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(w, h),
		BackgroundColor3 = Color3.fromRGB(14, 9, 8), BorderSizePixel = 0, ZIndex = 61 }, dim)
	new("UICorner", { CornerRadius = UDim.new(0, 0) }, p)
	new("UIStroke", { Color = Color3.fromRGB(140, 100, 50), Thickness = 2 }, p)
	local x = new("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 8), Size = UDim2.fromOffset(30, 30), BackgroundTransparency = 1,
		Text = "X", Font = FONT, TextSize = 20, TextColor3 = GOLD, ZIndex = 63 }, p)
	x.MouseButton1Click:Connect(function() dim.Visible = false end)
	return dim, p
end

-- «?»
local qDim, qPanel = modal(520, 260)
new("TextLabel", { Position = UDim2.fromOffset(24, 20), Size = UDim2.new(1, -48, 0, 30), BackgroundTransparency = 1, Text = "A NOTE FROM THE AUTHOR", Font = FONT, TextSize = 20,
	TextColor3 = GOLD, ZIndex = 62 }, qPanel)
new("TextLabel", { Position = UDim2.fromOffset(28, 62), Size = UDim2.new(1, -56, 1, -84), BackgroundTransparency = 1, TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Font = Enum.Font.Arcade, TextSize = 18, TextColor3 = Color3.fromRGB(225, 210, 190), ZIndex = 62,
	Text = "dear believers, I'm sorry for this game, the very idea of the game is that sinners will have a bad fate, I was not trying to offend anyone's religion in any way." }, qPanel)
qBtn.MouseButton1Click:Connect(function() qDim.Visible = true end)

-- COSMETICS
local cDim, cPanel = modal(640, 470)
new("TextLabel", { Position = UDim2.fromOffset(24, 14), Size = UDim2.new(1, -140, 0, 30), BackgroundTransparency = 1, Text = "COSMETICS & TITLES", Font = FONT, TextSize = 22,
	TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 62 }, cPanel)
local bal = new("TextLabel", { Position = UDim2.fromOffset(24, 44), Size = UDim2.fromOffset(300, 20), BackgroundTransparency = 1, Text = "", Font = FONT, TextSize = 14,
	TextColor3 = Color3.fromRGB(180, 160, 130), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 62 }, cPanel)
local scroll = new("ScrollingFrame", { Position = UDim2.fromOffset(20, 72), Size = UDim2.new(1, -40, 1, -92), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 5, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 62 }, cPanel)
new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)

local refreshCos
do   -- вкладки: ВСЕ / ACCESSORIES / TITLES / FRAMES / PINS
	player:SetAttribute("EvaKCosTab", "all")
	local tabs = { { "ALL", "all" }, { "ACCESSORIES", "item" }, { "TITLES", "title" }, { "FRAMES", "frame" }, { "PINS", "pin" } }
	local btns = {}
	local function paint()
		for _, t in tabs do btns[t[2]].BackgroundColor3 = (player:GetAttribute("EvaKCosTab") == t[2]) and Color3.fromRGB(140, 36, 28) or Color3.fromRGB(46, 28, 24) end
	end
	local x = 0
	for _, t in tabs do
		local w = #t[1] * 11 + 20
		local b = new("TextButton", { Position = UDim2.fromOffset(24 + x, 68), Size = UDim2.fromOffset(w, 26), Text = t[1], Font = FONT, TextSize = 13, TextColor3 = GOLD, ZIndex = 63 }, cPanel)
		b.MouseButton1Click:Connect(function() player:SetAttribute("EvaKCosTab", t[2]); paint(); if refreshCos then refreshCos() end end)
		btns[t[2]] = b
		x += w + 6
	end
	paint()
	player:GetAttributeChangedSignal("EvaKCosTab"):Connect(paint)
	scroll.Position = UDim2.fromOffset(20, 102); scroll.Size = UDim2.new(1, -40, 1, -122)
end
local errGui = Instance.new("ScreenGui"); errGui.Name = "EvaKExtraErr"; errGui.ResetOnSpawn = false; errGui.DisplayOrder = 900; errGui.IgnoreGuiInset = true; errGui.Parent = playerGui
local errLbl = Instance.new("TextLabel")
errLbl.AnchorPoint = Vector2.new(0.5, 0); errLbl.Position = UDim2.new(0.5, 0, 0, 90); errLbl.Size = UDim2.fromOffset(760, 70)
errLbl.BackgroundColor3 = Color3.fromRGB(70, 10, 10); errLbl.BorderSizePixel = 0; errLbl.TextColor3 = Color3.fromRGB(255, 220, 200)
errLbl.Font = Enum.Font.Code; errLbl.TextSize = 14; errLbl.TextWrapped = true; errLbl.Visible = false; errLbl.ZIndex = 200; errLbl.Parent = errGui
local errToken = 0
local function showErr(msg: string)
	errToken += 1
	local my = errToken
	errLbl.Text = "EvaKExtra: " .. msg
	errLbl.Visible = true
	task.delay(14, function() if errToken == my then errLbl.Visible = false end end)
end
local function inv(...)
	local dups = 0
	for _, o in game:GetService("ReplicatedStorage"):GetChildren() do if o.Name == "EvaKExtra" then dups += 1 end end
	if dups > 1 or game:GetService("ReplicatedStorage"):GetAttribute("EvaKExtraDup") then
		showErr("TWO EvaKExtra SERVER SCRIPTS ARE RUNNING. Delete the old copy in ServerScriptService (keep ONE). " .. tostring(game:GetService("ReplicatedStorage"):GetAttribute("EvaKExtraDup") or ""))
	end
	if not rf then
		showErr("RemoteFunction EvaKExtra not found - the server Script EvaKExtra is not running (put EvaKExtra.server.lua into ServerScriptService as a Script and read the Output for red errors)")
		return { ok = false }
	end
	local ok, r = pcall(function(...) return rf:InvokeServer(...) end, ...)
	if not ok then showErr("server error: " .. tostring(r)); return { ok = false } end
	if type(r) ~= "table" or (r.ok == false and not r.msg) then showErr("server answered not-ok for the request (" .. tostring((...)) .. ") " .. tostring(type(r) == "table" and r.msg or "")) end
	return type(r) == "table" and r or { ok = false }
end
task.delay(6, function() inv("VipInfo") end)   -- проверка связи с сервером: покажет красную плашку с причиной
refreshCos = function()
	local r = inv("Info")
	if not r.ok then say("EvaKExtra server script is not responding - check Output", false) return end
	bal.Text = "BADGES: " .. tostring(r.badges)
	for _, c in scroll:GetChildren() do if c:IsA("Frame") then c:Destroy() end end
	local devilOnly = player:GetAttribute("EvaKCosFilter") == "devil"
	for i, it in r.items do
		if devilOnly and not it.devil then continue end
		local tabSel = player:GetAttribute("EvaKCosTab") or "all"
		if tabSel ~= "all" and it.kind ~= tabSel then continue end
		local row = new("Frame", { Size = UDim2.new(1, -8, 0, 54), BackgroundColor3 = Color3.fromRGB(26, 16, 14), BorderSizePixel = 0, LayoutOrder = i, ZIndex = 63 }, scroll)
		new("UICorner", { CornerRadius = UDim.new(0, 0) }, row)
		new("TextLabel", { Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -230, 0, 22), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
			Text = (it.kind == "title" and "TITLE: " or "") .. it.name:upper(), Font = FONT, TextSize = 16, TextColor3 = (it.tcol and Color3.fromHex(it.tcol)) or (it.equipped and RED or GOLD), ZIndex = 64 }, row)
		local sub = it.owned and (it.equipped and "EQUIPPED" or "OWNED") or (it.how == "buy" and (it.cost .. " BADGES") or it.how == "quest" and ("QUEST: " .. (it.quest or "")) or (it.how == "vip" or it.how == "shop") and "CARBON PASS ONLY" or "ADMIN GIFT ONLY")
		new("TextLabel", { Position = UDim2.fromOffset(12, 28), Size = UDim2.new(1, -170, 0, 18), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
			Text = sub, Font = Enum.Font.Arcade, TextSize = 12, TextColor3 = Color3.fromRGB(170, 150, 130), ZIndex = 64 }, row)
		do   -- VIEW: 3D-предпросмотр предмета
			local vb = new("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, (it.owned or it.how == "buy") and -148 or -10, 0.5, 0), Size = UDim2.fromOffset(64, 34),
				BackgroundColor3 = Color3.fromRGB(40, 30, 60), Text = "VIEW", Font = FONT, TextSize = 14, TextColor3 = GOLD, ZIndex = 64 }, row)
			vb.MouseButton1Click:Connect(function() player:SetAttribute("EvaKPreview", "item:" .. it.id .. ":" .. tostring(os.clock())) end)
		end
		local label, action
		if it.owned then
			label = it.equipped and "UNEQUIP" or "EQUIP"
			action = function() if it.equipped then inv("Unequip", it.slot) else inv("Equip", it.id) end end
		elseif it.how == "buy" then
			label = "BUY"; action = function() local rr = inv("Buy", it.id); if not rr.ok then say("Not enough badges") end end
		end
		if label then
			local b = new("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(130, 34),
				BackgroundColor3 = it.owned and Color3.fromRGB(60, 24, 20) or Color3.fromRGB(110, 28, 22), Text = label, Font = FONT, TextSize = 15, TextColor3 = GOLD, ZIndex = 64 }, row)
			new("UICorner", { CornerRadius = UDim.new(0, 0) }, b)
			b.MouseButton1Click:Connect(function() action(); refreshCos() end)
		end
	end
end
local function openCos() player:SetAttribute("EvaKCosFilter", ""); player:SetAttribute("EvaKCosTab", player:GetAttribute("EvaKCosWant") or "all"); player:SetAttribute("EvaKCosWant", nil); cDim.Visible = true; refreshCos() end
cBtn.MouseButton1Click:Connect(openCos)
player:GetAttributeChangedSignal('EvaKOpenCos'):Connect(openCos)
player:GetAttributeChangedSignal('EvaKOpenDevil'):Connect(function() player:SetAttribute("EvaKCosFilter", "devil"); cDim.Visible = true; refreshCos() end)

task.spawn(function()
	while true do
		local v = menuVisible()
		qBtn.Visible = v; cBtn.Visible = false
		if not v then qDim.Visible = false; cDim.Visible = false end
		task.wait(0.3)
	end
end)

-- ============================================================
-- LORE (кнопка внутри «?»), CASES, FALSE EXIT
-- ============================================================
local MarketplaceService = game:GetService("MarketplaceService")
qPanel.Size = UDim2.fromOffset(520, 320)

local loreDim, lorePanel = modal(620, 480)
new("TextLabel", { Position = UDim2.fromOffset(24, 14), Size = UDim2.new(1, -140, 0, 30), BackgroundTransparency = 1, Text = "LORE NOTES", Font = FONT, TextSize = 22,
	TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 62 }, lorePanel)
local loreScroll = new("ScrollingFrame", { Position = UDim2.fromOffset(20, 56), Size = UDim2.new(1, -40, 1, -76), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 5, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 62 }, lorePanel)
new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, loreScroll)
local function refreshLore()
	local r = inv("Notes")
	if not r.ok then return end
	for _, c in loreScroll:GetChildren() do if c:IsA("Frame") then c:Destroy() end end
	for _, n in r.notes do
		local f = new("Frame", { Size = UDim2.new(1, -8, 0, n.text and 88 or 46), BackgroundColor3 = Color3.fromRGB(26, 16, 14), BorderSizePixel = 0, LayoutOrder = n.i, ZIndex = 63 }, loreScroll)
		new("UICorner", { CornerRadius = UDim.new(0, 0) }, f)
		new("TextLabel", { Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -24, 0, 20), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
			Text = n.text and n.title or ("??? " .. n.title:sub(1, 6)), Font = FONT, TextSize = 15, TextColor3 = n.text and GOLD or Color3.fromRGB(110, 90, 80), ZIndex = 64 }, f)
		new("TextLabel", { Position = UDim2.fromOffset(12, 28), Size = UDim2.new(1, -24, 1, -34), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = true, Text = n.text or ("LOCKED: " .. n.hint), Font = Enum.Font.Arcade, TextSize = 13, TextColor3 = n.text and Color3.fromRGB(225, 210, 190) or Color3.fromRGB(120, 100, 90), ZIndex = 64 }, f)
	end
end
local loreBtn = new("TextButton", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -16), Size = UDim2.fromOffset(200, 38), BackgroundColor3 = Color3.fromRGB(110, 28, 22),
	Text = "LORE NOTES", Font = FONT, TextSize = 16, TextColor3 = GOLD, ZIndex = 63 }, qPanel)
new("UICorner", { CornerRadius = UDim.new(0, 0) }, loreBtn)
loreBtn.MouseButton1Click:Connect(function() qDim.Visible = false; loreDim.Visible = true; refreshLore() end)

-- CASES
local caseBtn = new("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -222, 0, 16), Size = UDim2.fromOffset(110, 40),
	BackgroundColor3 = Color3.fromRGB(28, 10, 30), Text = "CASES", Font = FONT, TextSize = 16, TextColor3 = GOLD, Visible = false }, gui)
new("UICorner", { CornerRadius = UDim.new(0, 0) }, caseBtn)
new("UIStroke", { Color = Color3.fromRGB(170, 70, 200), Thickness = 2 }, caseBtn)
local caseDim, casePanel = modal(780, 500)
new("TextLabel", { Position = UDim2.fromOffset(24, 14), Size = UDim2.new(1, -140, 0, 30), BackgroundTransparency = 1, Text = "CASES", Font = FONT, TextSize = 22,
	TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 62 }, casePanel)
local caseBal = new("TextLabel", { Position = UDim2.fromOffset(24, 44), Size = UDim2.fromOffset(300, 20), BackgroundTransparency = 1, Text = "", Font = FONT, TextSize = 14,
	TextColor3 = Color3.fromRGB(180, 160, 130), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 62 }, casePanel)
local reveal = new("TextLabel", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -14), Size = UDim2.fromOffset(700, 40), BackgroundTransparency = 1, Text = "",
	Font = FONT, TextSize = 22, TextColor3 = RED, ZIndex = 64 }, casePanel)
local caseRow = new("Frame", { Position = UDim2.fromOffset(20, 76), Size = UDim2.new(1, -40, 1, -140), BackgroundTransparency = 1, ZIndex = 62 }, casePanel)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12) }, caseRow)
local ALLNAMES = { "Curse Aura", "EvaK Wings", "Demon Eyes", "Devil Horns", "Devil Tail", "Hellfire Aura", "Devil Wings", "Eclipse Pendant", "Skull Pin", "Blood Frame", "Owner's Key", "Eye of EvaK", "Sinner" }
local opening = false
local refreshCases
refreshCases = function()
	local r = inv("Cases")
	if not r.ok then return end
	caseBal.Text = "BADGES: " .. tostring(r.badges)
	for _, c in caseRow:GetChildren() do if c:IsA("Frame") then c:Destroy() end end
	for _, c in r.cases do
		local card = new("Frame", { Size = UDim2.fromOffset(238, 330), BackgroundColor3 = Color3.fromRGB(26, 16, 18), BorderSizePixel = 0, ZIndex = 63 }, caseRow)
		new("UICorner", { CornerRadius = UDim.new(0, 0) }, card)
		new("UIStroke", { Color = c.product and Color3.fromRGB(240, 190, 60) or Color3.fromRGB(140, 60, 60), Thickness = 1.5 }, card)
		new("TextLabel", { Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -76, 0, 40), BackgroundTransparency = 1, Text = "📦 " .. c.name, Font = FONT, TextSize = 16, TextWrapped = true, TextColor3 = GOLD, ZIndex = 64 }, card)
		local vbc = new("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 8), Size = UDim2.fromOffset(58, 24), BackgroundColor3 = Color3.fromRGB(40, 30, 60), Text = "VIEW", Font = FONT, TextSize = 13, TextColor3 = GOLD, ZIndex = 65 }, card)
		vbc.MouseButton1Click:Connect(function() player:SetAttribute("EvaKPreview", "case:" .. tostring(c.id) .. ":" .. tostring(os.clock())) end)
		local lines = {}
		for _, l in c.loot do table.insert(lines, l.name .. "  " .. l.pct .. "%") end
		new("TextLabel", { Position = UDim2.fromOffset(10, 52), Size = UDim2.new(1, -20, 1, -126), BackgroundTransparency = 1, Text = table.concat(lines, "\n"), Font = Enum.Font.Arcade, TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = Color3.fromRGB(190, 170, 150), ZIndex = 64 }, card)
		new("TextLabel", { Position = UDim2.new(0, 10, 1, -70), Size = UDim2.new(1, -20, 0, 16), BackgroundTransparency = 1, Text = "Duplicate = +" .. c.refund .. " badges", Font = Enum.Font.Arcade, TextSize = 11,
			TextColor3 = Color3.fromRGB(140, 120, 100), ZIndex = 64 }, card)
		local isRobux = c.badges == nil
		local b = new("TextButton", { Position = UDim2.new(0, 10, 1, -48), Size = UDim2.new(1, -20, 0, 38), BackgroundColor3 = isRobux and Color3.fromRGB(150, 110, 20) or Color3.fromRGB(110, 28, 22),
			Text = isRobux and ((c.product and c.product ~= 0) and "BUY WITH ROBUX" or "ROBUX ID NOT SET") or ("OPEN  " .. c.badges .. " BADGES"), Font = FONT, TextSize = 14, TextColor3 = GOLD, ZIndex = 64 }, card)
		new("UICorner", { CornerRadius = UDim.new(0, 0) }, b)
		b.MouseButton1Click:Connect(function()
			if opening then return end
			if isRobux then
				if c.product and c.product ~= 0 then pcall(function() MarketplaceService:PromptProductPurchase(player, c.product) end) else say("Developer Product ID is not set for this case") end
				return
			end
			opening = true
			local res = inv("OpenCase", c.id)
			if not res.ok then reveal.Text = tostring(res.msg or "error"); opening = false; return end
			for i = 1, 22 do reveal.Text = ALLNAMES[math.random(1, #ALLNAMES)]; task.wait(0.05 + i * 0.012) end
			reveal.Text = "YOU GOT: " .. res.name .. (res.dup and ("  (duplicate +" .. res.refund .. " badges)") or "!")
			opening = false
			refreshCases()
		end)
	end
end
local function openCases() caseDim.Visible = true; reveal.Text = ""; refreshCases() end
caseBtn.MouseButton1Click:Connect(openCases)
player:GetAttributeChangedSignal('EvaKOpenCases'):Connect(openCases)

-- FALSE EXIT (дверь выхода в лобби во время события)
local exitDoor = new("TextButton", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 24, 0.5, 0), Size = UDim2.fromOffset(110, 200), BackgroundColor3 = Color3.fromRGB(70, 40, 22),
	Text = "EXIT", Font = FONT, TextSize = 24, TextColor3 = Color3.fromRGB(255, 235, 170), Visible = false, ZIndex = 30 }, gui)
new("UIStroke", { Color = Color3.fromRGB(255, 230, 150), Thickness = 3 }, exitDoor)
exitDoor.MouseButton1Click:Connect(function()
	exitDoor.Visible = false
	local f = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, ZIndex = 70 }, gui)
	local l = new("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "You step outside...\nand the hotel is waiting again.", Font = Enum.Font.Code, TextSize = 30,
		TextColor3 = Color3.fromRGB(200, 40, 36), TextTransparency = 1, ZIndex = 71 }, f)
	TweenService:Create(f, TweenInfo.new(1.4), { BackgroundTransparency = 0 }):Play()
	task.wait(1.4)
	TweenService:Create(l, TweenInfo.new(1), { TextTransparency = 0 }):Play()
	task.wait(3.5)
	TweenService:Create(f, TweenInfo.new(1.4), { BackgroundTransparency = 1 }):Play()
	TweenService:Create(l, TweenInfo.new(1.4), { TextTransparency = 1 }):Play()
	task.wait(1.5)
	f:Destroy()
end)

task.spawn(function()
	while true do
		local v = menuVisible()
		caseBtn.Visible = false
		exitDoor.Visible = v and curSet.FalseExit == true
		if not v then caseDim.Visible = false; loreDim.Visible = false end
		task.wait(0.3)
	end
end)

-- ============================================================
-- СТАТИСТИКА (кнопка STATISTICS в SETTINGS)
-- ============================================================
local statDim, statPanel = modal(460, 440)
new("TextLabel", { Position = UDim2.fromOffset(24, 14), Size = UDim2.new(1, -140, 0, 30), BackgroundTransparency = 1, Text = "STATISTICS", Font = FONT, TextSize = 22,
	TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 62 }, statPanel)
local statList = new("Frame", { Position = UDim2.fromOffset(24, 60), Size = UDim2.new(1, -48, 1, -80), BackgroundTransparency = 1, ZIndex = 62 }, statPanel)
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, statList)
local function fmtTime(sec: number): string
	local h = sec // 3600
	local m = (sec % 3600) // 60
	return string.format("%dh %02dm", h, m)
end
local function refreshStats()
	local r = inv("Stats")
	if not r.ok then say("EvaKExtra server script is not responding - check Output", false) return end
	for _, c in statList:GetChildren() do if c:IsA("Frame") then c:Destroy() end end
	local rows = {
		{ "Time played", fmtTime(r.play) },
		{ "Badges", tostring(math.floor(r.badges)) },
		{ "Snowflakes", tostring(math.floor(r.snow)) },
		{ "Cases opened", tostring(r.cases) },
		{ "Best door reached", tostring(r.best) .. " / 100" },
		{ "Runs completed", tostring(r.done) },
		{ "Runs failed", tostring(r.failed) },
		{ "Lore notes found", tostring(r.notes) .. " / 10" },
		{ "Cosmetics & items owned", tostring(r.items) },
		{ "Visits to the hotel", tostring(r.visits) },
	}
	for i, row in rows do
		local f = new("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Color3.fromRGB(26, 16, 14), BorderSizePixel = 0, LayoutOrder = i, ZIndex = 63 }, statList)
		new("UICorner", { CornerRadius = UDim.new(0, 0) }, f)
		new("TextLabel", { Position = UDim2.fromOffset(10, 0), Size = UDim2.new(0.6, 0, 1, 0), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
			Text = row[1], Font = Enum.Font.Arcade, TextSize = 14, TextColor3 = Color3.fromRGB(190, 170, 150), ZIndex = 64 }, f)
		new("TextLabel", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 0), Size = UDim2.new(0.4, 0, 1, 0), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Right,
			Text = row[2], Font = FONT, TextSize = 15, TextColor3 = GOLD, ZIndex = 64 }, f)
	end
end
player:GetAttributeChangedSignal("EvaKOpenStats"):Connect(function()
	statDim.Visible = true
	refreshStats()
end)

-- ============================================================
-- УГНЕТАЮЩАЯ АТМОСФЕРА В ЗАБЕГЕ: редкие фейки и страхи (без звуков, ID звуков можно вписать)
-- ============================================================
local HORROR_SOUNDS = { whisper = "", steps = "", knock = "", laugh = "" }   -- сюда можно вписать rbxassetid://...
local function playH(id: string, vol: number)
	if id == "" then return end
	local s = Instance.new("Sound"); s.SoundId = id; s.Volume = vol; s.Parent = SoundService; s:Play()
	game:GetService("Debris"):AddItem(s, 8)
end
local WHISPERS = { "...behind you...", "you are not alone", "don't look back", "it knows your name", "someone is counting your steps", "the walls are listening", "keep going. it likes that." }
local function peripheralFlash()   -- белые глаза в темноте по краю экрана
	local side = math.random() < 0.5 and 0.04 or 0.96
	local y = 0.35 + math.random() * 0.3
	local f = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 35 }, gui)
	for _, dx in { -0.012, 0.012 } do
		local e = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(side + dx, y), Size = UDim2.fromOffset(14, 8), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, ZIndex = 36 }, f)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, e)
		TweenService:Create(e, TweenInfo.new(0.5), { BackgroundTransparency = 0.05 }):Play()
		task.delay(1.1, function() TweenService:Create(e, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play() end)
	end
	task.delay(1.6, function() f:Destroy() end)
end
local function lightFlicker()
	local b0 = Lighting.Brightness
	for _ = 1, math.random(3, 6) do
		Lighting.Brightness = 0; task.wait(0.05 + math.random() * 0.12)
		Lighting.Brightness = b0; task.wait(0.05 + math.random() * 0.2)
	end
	Lighting.Brightness = b0
end
task.spawn(function()
	while true do
		task.wait(math.random(28, 70))
		if player:GetAttribute("EvaKInRun") == true and next(curSet) == nil then
			local r = math.random(1, 7)
			if r == 1 then say(WHISPERS[math.random(1, #WHISPERS)], false); playH(HORROR_SOUNDS.whisper, 0.7)
			elseif r == 2 then peripheralFlash()
			elseif r == 3 then lightFlicker()
			elseif r == 4 then shakeAmt = 0.25; shakeUntil = os.clock() + 0.8; playH(HORROR_SOUNDS.steps, 0.8)
			elseif r >= 6 then say("ehe... hey... ehe hehey...", false); playH(HORROR_SOUNDS.laugh, 0.8)
			else say("...knock... knock... knock...", false); playH(HORROR_SOUNDS.knock, 0.9) end
		end
	end
end)

-- ============================================================
-- VIP (Game Pass 259 R$): кнопка рядом с CASES
-- ============================================================
local vipBtn = new("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -340, 0, 16), Size = UDim2.fromOffset(100, 40),
	BackgroundColor3 = Color3.fromRGB(60, 44, 8), Text = "CARBON", Font = FONT, TextSize = 18, TextColor3 = Color3.fromRGB(255, 255, 255), Visible = false }, gui)
new("UICorner", { CornerRadius = UDim.new(0, 0) }, vipBtn)
new("UIStroke", { Color = Color3.fromRGB(255, 205, 60), Thickness = 2 }, vipBtn)
local vipDim, vipPanel = modal(480, 340)
new("TextLabel", { Position = UDim2.fromOffset(24, 16), Size = UDim2.new(1, -140, 0, 30), BackgroundTransparency = 1, Text = "CARBON", Font = FONT, TextSize = 24,
	TextColor3 = Color3.fromRGB(255, 80, 80), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 62 }, vipPanel)
new("TextLabel", { Position = UDim2.fromOffset(28, 60), Size = UDim2.new(1, -56, 0, 170), BackgroundTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top, Font = Enum.Font.Arcade, TextSize = 17, TextColor3 = Color3.fromRGB(225, 210, 190), ZIndex = 62,
	Text = "• [CarBon] tag next to your name and in chat\n• CarBon title\n• CarBon red-white aura\n• CarBon red-white eyes\n\nCarBon items cannot be traded." }, vipPanel)
local vipBuy = new("TextButton", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -20), Size = UDim2.fromOffset(240, 46), BackgroundColor3 = Color3.fromRGB(170, 25, 35),
	Text = "BUY CARBON", Font = FONT, TextSize = 18, TextColor3 = Color3.fromRGB(255, 240, 200), ZIndex = 63 }, vipPanel)
new("UICorner", { CornerRadius = UDim.new(0, 0) }, vipBuy)
local function openVip()
	local r = inv("VipInfo")
	if r.ok then
		if r.owned then vipBuy.Text = "YOU HAVE CARBON" elseif r.passId == 0 then vipBuy.Text = "GAME PASS ID NOT SET" else vipBuy.Text = "BUY CARBON" end
		vipBuy:SetAttribute("PassId", r.passId); vipBuy:SetAttribute("Owned", r.owned)
	else
		vipBuy.Text = "BUY CARBON"
	end
	vipDim.Visible = true
end
vipBtn.MouseButton1Click:Connect(openVip)
player:GetAttributeChangedSignal('EvaKOpenVip'):Connect(openVip)
vipBuy.MouseButton1Click:Connect(function()
	local id = vipBuy:GetAttribute("PassId") or 2092239089
	if vipBuy:GetAttribute("Owned") or id == 0 then return end
	pcall(function() MarketplaceService:PromptGamePassPurchase(player, id) end)
end)
task.spawn(function()
	while true do
		local v = menuVisible()
		vipBtn.Visible = false
		if not v then vipDim.Visible = false end
		task.wait(0.3)
	end
end)
