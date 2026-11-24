-- ============================================================
--  EvaKBlood (LocalScript в StarterPlayerScripts)
--  * Кровь (красная краска) сверху экрана: при малом HP стекает всё больше, при смерти заливает весь экран.
--  * Лечение: H - бинт (+25 HP себе), K - аптечка (+60 HP ближайшему другу, иначе +45 себе). Счётчики справа внизу.
--  * Концовки: демон (много урона за забег) / ангел (мало) - вспышка, рога или нимб и надпись.
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CAS = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local FONT = Enum.Font.Arcade

local function new(class: string, props: any, parent: Instance?)
	local o = Instance.new(class)
	for k, v in props do (o :: any)[k] = v end
	o.Parent = parent
	return o
end

local gui = new("ScreenGui", { Name = "EvaKBloodGui", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 400, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, playerGui)

-- ---------------- кровь ----------------
local PAINT, PAINT_DARK = Color3.fromRGB(176, 8, 14), Color3.fromRGB(110, 0, 6)
local COLS = 18
local drips: {Frame} = {}
local seeds: {number} = {}
local rng = Random.new(77)
local paintRoot = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 3 }, gui)
for i = 1, COLS do
	local w = 1 / COLS
	local d = new("Frame", { Position = UDim2.fromScale((i - 1) * w - 0.004, -0.02), Size = UDim2.new(w + 0.008, 0, 0, 0), BackgroundColor3 = PAINT, BorderSizePixel = 0, ZIndex = 3 }, paintRoot)
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(PAINT, PAINT_DARK) }, d)
	-- круглый конец капли
	local tip = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 1), Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = PAINT_DARK, BorderSizePixel = 0, ZIndex = 3 }, d)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, tip)
	tip:SetAttribute("w", 1)
	drips[i] = d
	seeds[i] = rng:NextNumber(0.5, 1)
end
-- красная виньетка по краям
local vig = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(150, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2 }, gui)
new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.35, 1), NumberSequenceKeypoint.new(0.65, 1), NumberSequenceKeypoint.new(1, 0) }), Rotation = 0 }, vig)
local vig2 = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(150, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2 }, gui)
new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 1), NumberSequenceKeypoint.new(0.7, 1), NumberSequenceKeypoint.new(1, 0) }), Rotation = 90 }, vig2)

local amount = 0       -- 0..1 насколько залито
local target = 0
local dead = false
local function hpToTarget(hp: number): number
	if hp >= 70 then return 0 end
	return math.clamp((70 - hp) / 70, 0, 1) * 0.55   -- 0..0.55 экрана при HP -> 0
end
local function refresh()
	if player:GetAttribute("InMap") ~= true and not dead then target = 0; return end
	local hp = player:GetAttribute("EvaKHpNow") or 100
	if hp <= 0 and player:GetAttribute("InMap") == true then
		dead = true; target = 1.15
	elseif hp > 0 then
		if dead then dead = false end
		target = hpToTarget(hp)
	end
end
player:GetAttributeChangedSignal("EvaKHpNow"):Connect(refresh)
player:GetAttributeChangedSignal("InMap"):Connect(function()
	if player:GetAttribute("InMap") == true then dead = false; amount = 0; refresh() else
		-- вышли из забега: краска стекает вниз и исчезает
		task.delay(2.5, function() if player:GetAttribute("InMap") ~= true then dead = false; target = 0 end end)
	end
end)
RunService.RenderStepped:Connect(function(dt)
	local speed = (target > amount) and 0.55 or 0.25
	amount += math.clamp(target - amount, -dt * speed, dt * speed)
	local t = os.clock()
	for i, d in drips do
		local h = amount * seeds[i] * 1.0 + (amount > 0.02 and 0.015 * math.sin(t * 1.3 + i) or 0)
		h = math.clamp(h, 0, 1.2)
		d.Size = UDim2.new(d.Size.X.Scale, 0, h, 0)
		local tip = d:FindFirstChildOfClass("Frame")
		if tip then tip.Size = UDim2.new(1, 0, 0, h > 0.01 and 34 or 0) end
	end
	local v = math.clamp(amount * 1.4, 0, 1)
	vig.BackgroundTransparency = 1 - 0.55 * v
	vig2.BackgroundTransparency = 1 - 0.55 * v
end)

-- ---------------- лечение ----------------
local world = ReplicatedStorage:WaitForChild("EvaKWorld", 20)
local items = new("TextLabel", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -64), Size = UDim2.fromOffset(250, 40), BackgroundTransparency = 1, Font = FONT, TextSize = 14,
	TextColor3 = Color3.fromRGB(235, 220, 200), TextXAlignment = Enum.TextXAlignment.Right, Visible = false, ZIndex = 6, Text = "" }, gui)
new("UIStroke", { Thickness = 1.5, Color = Color3.new(0, 0, 0) }, items)
local nB, nM = 0, 0
local function paintItems()
	items.Text = "[H] BANDAGE x" .. nB .. "\n[K] MEDKIT x" .. nM .. "  (heals a friend)"
end
local healFlash = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(80, 230, 120), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 8 }, gui)
local function bind(name: string, kind: string, key: Enum.KeyCode)
	CAS:BindActionAtPriority(name, function(_, state)
		if state == Enum.UserInputState.Begin and world and player:GetAttribute("InMap") == true then world:FireServer(kind) end
		return Enum.ContextActionResult.Pass
	end, false, Enum.ContextActionPriority.High.Value, key)
end
bind("EvaKBandage", "Bandage", Enum.KeyCode.H)
bind("EvaKMedkit", "Medkit", Enum.KeyCode.K)
player:GetAttributeChangedSignal("InMap"):Connect(function() items.Visible = player:GetAttribute("InMap") == true end)

-- ---------------- концовки ----------------
local function ending(kind: string)
	local demon = kind == "demon"
	task.wait(12.5)   -- после «THE END» и первых фраз
	local g = new("ScreenGui", { Name = "EvaKEnding", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 950 }, playerGui)
	local bg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = demon and Color3.fromRGB(60, 0, 0) or Color3.fromRGB(255, 252, 235), BackgroundTransparency = 1, BorderSizePixel = 0 }, g)
	TweenService:Create(bg, TweenInfo.new(1.2), { BackgroundTransparency = 0 }):Play()
	task.wait(1.3)
	local ink = demon and Color3.fromRGB(255, 40, 30) or Color3.fromRGB(210, 150, 20)
	-- эмблема: рога (демон) или нимб + крылья (ангел)
	local function ell(x: number, y: number, w: number, h: number, rot: number, c: Color3, z: number?)
		local f = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, y), Size = UDim2.fromOffset(w, h), Rotation = rot, BackgroundColor3 = c, BorderSizePixel = 0, ZIndex = z or 2 }, g)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, f)
		return f
	end
	if demon then
		for _, s in { -1, 1 } do
			ell(0.5 + s * 0.09, 0.28, 46, 120, s * 20, Color3.fromRGB(30, 0, 0))
			ell(0.5 + s * 0.065, 0.2, 30, 90, s * 40, Color3.fromRGB(80, 0, 4))
			ell(0.5 + s * 0.04, 0.14, 18, 60, s * 60, Color3.fromRGB(190, 20, 16))
		end
		ell(0.5, 0.38, 170, 190, 0, Color3.fromRGB(20, 0, 0))
		ell(0.44, 0.37, 30, 16, 12, Color3.fromRGB(255, 50, 30), 3); ell(0.56, 0.37, 30, 16, -12, Color3.fromRGB(255, 50, 30), 3)
	else
		for _, s in { -1, 1 } do
			for i = 0, 3 do ell(0.5 + s * (0.1 + i * 0.045), 0.36 + i * 0.03, 200, 46, s * (-22 + i * 12), Color3.fromRGB(255, 255, 255)) end
		end
		local halo = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.2), Size = UDim2.fromOffset(190, 48), BackgroundTransparency = 1, ZIndex = 3 }, g)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, halo)
		new("UIStroke", { Color = Color3.fromRGB(255, 200, 40), Thickness = 9 }, halo)
		ell(0.5, 0.38, 130, 160, 0, Color3.fromRGB(245, 235, 215))
	end
	local t1 = new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.62), Size = UDim2.fromOffset(900, 70), BackgroundTransparency = 1, Font = FONT, TextSize = 46, TextColor3 = ink, TextTransparency = 1,
		Text = demon and "YOU BECAME A DEMON" or "YOU ASCENDED" }, g)
	local t2 = new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.72), Size = UDim2.fromOffset(900, 40), BackgroundTransparency = 1, Font = FONT, TextSize = 20, TextColor3 = ink, TextTransparency = 1,
		Text = demon and "too much blood was spilled - the hotel keeps you" or "you walked through hell and stayed clean" }, g)
	TweenService:Create(t1, TweenInfo.new(1.2), { TextTransparency = 0 }):Play()
	task.wait(1.0)
	TweenService:Create(t2, TweenInfo.new(1.2), { TextTransparency = 0 }):Play()
	task.wait(5)
	TweenService:Create(bg, TweenInfo.new(1.0), { BackgroundTransparency = 1 }):Play()
	for _, c in g:GetChildren() do if c ~= bg then TweenService:Create(c, TweenInfo.new(1.0), { BackgroundTransparency = 1 }):Play() end end
	task.wait(1.1)
	g:Destroy()
end

if world then
	world.OnClientEvent:Connect(function(kind, a, b)
		if kind == "Items" then nB, nM = a or 0, b or 0; paintItems()
		elseif kind == "HealFx" then
			healFlash.BackgroundTransparency = 0.6
			TweenService:Create(healFlash, TweenInfo.new(0.7), { BackgroundTransparency = 1 }):Play()
		elseif kind == "TheEnd" and (a == "demon" or a == "angel") then task.spawn(ending, a)
		elseif kind == "Dead" then dead = true; target = 1.15 end
	end)
end
