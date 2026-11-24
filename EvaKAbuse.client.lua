-- ============================================================
--  EvaKAbuse (LocalScript в StarterPlayerScripts)
--  Кинематик «ADMIN ABUSE»: за 30 секунд до конца - чёрный силуэт смотрит на часы, на которых тикают секунды.
--  Когда время вышло, камера уходит в часы (зум + белая вспышка), и ты в лобби; запускаются все ивенты сразу.
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local playing = false

local function new(class: string, props: {[string]: any}, parent: Instance?)
	local i = Instance.new(class)
	for k, v in props do (i :: any)[k] = v end
	i.Parent = parent
	return i
end

local function play(endAt: number)
	if playing then return end
	playing = true
	local gui = new("ScreenGui", { Name = "EvaKAbuseGui", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 900 }, playerGui)
	local bg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0 }, gui)
	TweenService:Create(bg, TweenInfo.new(1.5), { BackgroundTransparency = 0 }):Play()
	task.wait(1.4)

	-- стена с красноватым светом
	local glow = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.62, 0.42), Size = UDim2.fromOffset(700, 700), BackgroundColor3 = Color3.fromRGB(90, 8, 8), BackgroundTransparency = 0.6, BorderSizePixel = 0 }, gui)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, glow)

	-- часы: настоящий 3D-будильник во ViewportFrame (латунный корпус, звонки сверху, ножки, кремовый циферблат, стрелки); камера облетает его
	local clock = new("ViewportFrame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.62, 0.42), Size = UDim2.fromOffset(460, 460), BackgroundTransparency = 1, BorderSizePixel = 0,
		Ambient = Color3.fromRGB(150, 130, 120), LightColor = Color3.fromRGB(255, 235, 210), LightDirection = Vector3.new(-0.5, -0.7, 0.8) }, gui)
	local vcam = new("Camera", { FieldOfView = 42 }, clock)
	clock.CurrentCamera = vcam
	local BRASS, CREAM, INK = Color3.fromRGB(196, 150, 60), Color3.fromRGB(236, 226, 200), Color3.fromRGB(26, 20, 18)
	local function cyl(thick: number, dia: number, cf: CFrame, color: Color3, mat: Enum.Material): Part   -- ось цилиндра вдоль Z
		return new("Part", { Shape = Enum.PartType.Cylinder, Size = Vector3.new(thick, dia, dia), Anchored = true, CanCollide = false, Color = color, Material = mat,
			CFrame = cf * CFrame.Angles(0, math.rad(90), 0), TopSurface = Enum.SurfaceType.Smooth, BottomSurface = Enum.SurfaceType.Smooth }, clock)
	end
	local function ball(d: number, cf: CFrame, color: Color3, mat: Enum.Material): Part
		return new("Part", { Shape = Enum.PartType.Ball, Size = Vector3.new(d, d, d), Anchored = true, CanCollide = false, Color = color, Material = mat, CFrame = cf }, clock)
	end
	local function box(w: number, h: number, d: number, cf: CFrame, color: Color3, mat: Enum.Material?): Part
		return new("Part", { Size = Vector3.new(w, h, d), Anchored = true, CanCollide = false, Color = color, Material = mat or Enum.Material.SmoothPlastic, CFrame = cf,
			TopSurface = Enum.SurfaceType.Smooth, BottomSurface = Enum.SurfaceType.Smooth }, clock)
	end
	cyl(3, 11, CFrame.new(0, 0, 0), BRASS, Enum.Material.Metal)                       -- корпус
	cyl(0.5, 10.6, CFrame.new(0, 0, -1.6), BRASS:Lerp(Color3.new(1, 1, 1), 0.25), Enum.Material.Metal)   -- светлый ободок
	cyl(0.3, 9.2, CFrame.new(0, 0, -1.95), CREAM, Enum.Material.SmoothPlastic)         -- циферблат
	cyl(0.9, 11.4, CFrame.new(0, 0, 1.2), BRASS:Lerp(INK, 0.4), Enum.Material.Metal)  -- задняя крышка
	for _, sx in { -1, 1 } do   -- два звонка сверху, ножки снизу
		ball(3.2, CFrame.new(sx * 3.6, 5.7, 0), BRASS:Lerp(Color3.new(1, 1, 1), 0.15), Enum.Material.Metal)
		box(0.5, 1.6, 0.5, CFrame.new(sx * 2.6, 5.0, 0) * CFrame.Angles(0, 0, math.rad(sx * -35)), INK, Enum.Material.Metal)
		box(1, 1.8, 1, CFrame.new(sx * 3.3, -5.7, 0) * CFrame.Angles(0, 0, math.rad(sx * 25)), INK, Enum.Material.Metal)
	end
	box(0.4, 1.4, 0.4, CFrame.new(0, 5.9, 0), INK, Enum.Material.Metal)                   -- молоточек
	ball(0.9, CFrame.new(0, 6.7, 0), INK, Enum.Material.Metal)
	for i = 0, 11 do
		local a = math.rad(i * 30)
		local big = i % 3 == 0
		box(big and 0.42 or 0.2, big and 1.3 or 0.7, 0.15, CFrame.new(math.sin(a) * 3.8, math.cos(a) * 3.8, -2.2) * CFrame.Angles(0, 0, -a), INK)
	end
	local function hand(len: number, w: number, z: number, deg: number, color: Color3, tail: number?): Part
		local rot = CFrame.Angles(0, 0, -math.rad(deg))
		return box(w, len + (tail or 0), 0.14, rot * CFrame.new(0, (len - (tail or 0)) / 2, z), color)
	end
	hand(2.4, 0.46, -2.3, -3, INK)       -- часовая: почти на 12
	hand(3.6, 0.32, -2.4, -6, INK)       -- минутная: 11:59
	local secHand = hand(3.9, 0.14, -2.5, 0, Color3.fromRGB(215, 30, 26), 1)
	ball(0.8, CFrame.new(0, 0, -2.6), Color3.fromRGB(215, 30, 26), Enum.Material.Metal)
	local function setSec(deg: number)
		secHand.CFrame = CFrame.Angles(0, 0, -math.rad(deg)) * CFrame.new(0, (3.9 - 1) / 2, -2.5)
	end
	local function setCam(t: number)   -- камера покачивается вокруг будильника: видны объём, звонки и ножки
		local a = math.sin(t * 0.55) * 0.75
		vcam.CFrame = CFrame.lookAt(Vector3.new(math.sin(a) * 19, 3 + math.cos(t * 0.4) * 1.2, -math.cos(a) * 19), Vector3.new(0, 0.4, 0))
	end
	setCam(0); setSec(0)
	local digits = new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.62, 0, 0.42, 240), Size = UDim2.fromOffset(300, 60), BackgroundTransparency = 1,
		Font = Enum.Font.Arcade, TextSize = 52, TextColor3 = Color3.fromRGB(230, 40, 34), Text = "0:30" }, gui)
	local title = new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.05), Size = UDim2.fromOffset(800, 40), BackgroundTransparency = 1,
		Font = Enum.Font.Arcade, TextSize = 26, TextColor3 = Color3.fromRGB(170, 120, 110), Text = "ADMIN ABUSE" }, gui)

	-- чёрный силуэт слева: голова, тело, поднятая рука к часам
	local sil = new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.26, 1.02), Size = UDim2.fromOffset(240, 520), BackgroundTransparency = 1 }, gui)
	local ink = Color3.fromRGB(2, 2, 3)
	local head = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.02), Size = UDim2.fromOffset(78, 92), BackgroundColor3 = ink, BorderSizePixel = 0 }, sil)
	new("UICorner", { CornerRadius = UDim.new(0.45, 0) }, head)
	new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.17), Size = UDim2.fromOffset(34, 40), BackgroundColor3 = ink, BorderSizePixel = 0 }, sil)
	local body = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.22), Size = UDim2.fromOffset(190, 340), BackgroundColor3 = ink, BorderSizePixel = 0 }, sil)
	new("UICorner", { CornerRadius = UDim.new(0.18, 0) }, body)
	local arm = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.78, 0.3), Size = UDim2.fromOffset(190, 36), BackgroundColor3 = ink, BorderSizePixel = 0, Rotation = -18 }, sil)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, arm)
	-- два тусклых красных глаза: оно смотрит на часы
	local eyeL = new("Frame", { Position = UDim2.fromOffset(40, 40), Size = UDim2.fromOffset(8, 5), BackgroundColor3 = Color3.fromRGB(255, 40, 30), BorderSizePixel = 0 }, head)
	local eyeR = new("Frame", { Position = UDim2.fromOffset(54, 40), Size = UDim2.fromOffset(8, 5), BackgroundColor3 = Color3.fromRGB(255, 40, 30), BorderSizePixel = 0 }, head)
	local flash = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 10 }, gui)

	local conn
	conn = RunService.RenderStepped:Connect(function()
		local left = math.max(0, endAt - workspace:GetServerTimeNow())
		local t = os.clock()
		local whole = math.ceil(left)
		digits.Text = string.format("0:%02d", whole)
		local tick = (left % 1)
		setSec(math.floor(30 - left) * 6 + (tick < 0.12 and 2 or 0))
		setCam(t)
		local pulse = 0.5 + 0.5 * math.sin(t * 3)
		glow.BackgroundTransparency = 0.55 + 0.15 * pulse
		sil.Position = UDim2.new(0.26, 0, 1.02, math.sin(t * 0.8) * 3)
		local f = (math.random() < 0.01) and 0.2 or 1
		eyeL.BackgroundTransparency = f; eyeR.BackgroundTransparency = f
		if left <= 6 then digits.TextColor3 = Color3.fromRGB(255, 60 + 60 * pulse, 50) end
	end)

	-- ждём конец (серверное время)
	while endAt - workspace:GetServerTimeNow() > 0 do task.wait(0.1) end
	conn:Disconnect()
	-- камера уходит в часы
	digits.Visible = false; title.Visible = false
	TweenService:Create(sil, TweenInfo.new(1.2), { Position = UDim2.fromScale(-0.2, 1.02) }):Play()
	local zoom = TweenService:Create(clock, TweenInfo.new(2.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Size = UDim2.fromOffset(4200, 4200), Position = UDim2.fromScale(0.5, 0.5) })
	zoom:Play()
	TweenService:Create(glow, TweenInfo.new(2.4), { Size = UDim2.fromOffset(5000, 5000) }):Play()
	task.wait(1.9)
	TweenService:Create(flash, TweenInfo.new(0.6), { BackgroundTransparency = 0 }):Play()
	task.wait(1.2)
	for _, c in gui:GetChildren() do if c ~= flash then c:Destroy() end end
	TweenService:Create(flash, TweenInfo.new(1.5), { BackgroundTransparency = 1 }):Play()
	task.wait(1.6)
	gui:Destroy()
	playing = false
end

local function check()
	local e = workspace:GetAttribute("EvaKAbuse") or 0
	if e > workspace:GetServerTimeNow() then task.spawn(play, e) end
end
workspace:GetAttributeChangedSignal("EvaKAbuse"):Connect(check)
check()
