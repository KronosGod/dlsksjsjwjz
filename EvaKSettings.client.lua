-- ============================================================
--  EvaKSettings (LocalScript в StarterPlayerScripts)
--  Кнопка-шестерёнка слева сверху -> окно Settings: громкость лобби/игры, переключатели, ПРОМОКОД внизу.
--  Настройки хранятся в атрибутах игрока (EvaKVolLobby, EvaKVolGame, EvaKToggleCrouch, EvaKReduceMotion, EvaKHideClothes, EvaKLowEnd).
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CREAM = Color3.fromRGB(255, 229, 200)
local FILL = Color3.fromRGB(32, 17, 14)
local ROW = Color3.fromRGB(76, 46, 38)
local FONT = Enum.Font.Oswald

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in props do o[k] = v end
	o.Parent = parent
	return o
end

player:SetAttribute("EvaKVolLobby", player:GetAttribute("EvaKVolLobby") or 0.5)
player:SetAttribute("EvaKVolGame", player:GetAttribute("EvaKVolGame") or 0.5)

local gui = new("ScreenGui", { Name = "EvaKSettingsGui", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 90, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, playerGui)

-- кнопка-шестерёнка
local gear = new("TextButton", { Position = UDim2.fromOffset(196, 10), Size = UDim2.fromOffset(46, 46), BackgroundColor3 = Color3.fromRGB(14, 12, 12), Text = "⚙", Font = Enum.Font.GothamBold,
	TextSize = 28, TextColor3 = Color3.new(1, 1, 1), AutoButtonColor = true }, gui)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, gear)

-- окно
local dim = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Visible = false, ZIndex = 5 }, gui)
local win = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(500, 600), BackgroundColor3 = FILL, BorderSizePixel = 0, ZIndex = 6 }, dim)
new("UICorner", { CornerRadius = UDim.new(0, 26) }, win)
new("UIStroke", { Color = CREAM, Thickness = 5 }, win)
local us = new("UIScale", {}, win)
local function rescale()
	local cam = workspace.CurrentCamera
	local v = cam and cam.ViewportSize or Vector2.new(1280, 720)
	us.Scale = math.clamp(math.min(v.X / 620, v.Y / 680), 0.5, 1.15)
end
rescale()
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale) end

new("TextLabel", { Position = UDim2.fromOffset(28, 16), Size = UDim2.fromOffset(300, 48), BackgroundTransparency = 1, Text = "Settings", Font = FONT, TextSize = 46, TextColor3 = CREAM,
	TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7 }, win)
local closeX = new("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -18, 0, 14), Size = UDim2.fromOffset(50, 50), BackgroundTransparency = 1, Text = "✕", Font = Enum.Font.GothamBlack,
	TextSize = 36, TextColor3 = CREAM, ZIndex = 8 }, win)

local list = new("ScrollingFrame", { Position = UDim2.fromOffset(20, 76), Size = UDim2.new(1, -40, 1, -92), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
	CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 7 }, win)
new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, list)
local order = 0
local function nx() order += 1; return order end

local function header(text: string)
	local f = new("Frame", { Size = UDim2.new(1, -6, 0, 48), BackgroundColor3 = ROW, BorderSizePixel = 0, LayoutOrder = nx(), ZIndex = 8 }, list)
	new("UICorner", { CornerRadius = UDim.new(0, 10) }, f)
	new("TextLabel", { Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -20, 1, 0), BackgroundTransparency = 1, Text = text, Font = FONT, TextSize = 32, TextColor3 = CREAM,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9 }, f)
end

local function rowBase(label: string)
	local f = new("Frame", { Size = UDim2.new(1, -6, 0, 54), BackgroundTransparency = 1, LayoutOrder = nx(), ZIndex = 8 }, list)
	new("TextLabel", { Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0.5, -12, 1, 0), BackgroundTransparency = 1, Text = label, Font = FONT, TextSize = 29, TextColor3 = CREAM,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9 }, f)
	return f
end

local function slider(label: string, attr: string)
	local f = rowBase(label)
	local track = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -4, 0.5, 0), Size = UDim2.fromOffset(230, 36), BackgroundColor3 = ROW, BorderSizePixel = 0, ZIndex = 9 }, f)
	new("UICorner", { CornerRadius = UDim.new(0, 8) }, track)
	for i = 0, 8 do
		new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.06 + i * 0.11, 0, 0.5, 0), Size = UDim2.fromOffset(8, 8), BackgroundColor3 = Color3.fromRGB(150, 100, 80),
			BorderSizePixel = 0, ZIndex = 10 }, track).BackgroundTransparency = 0.2
	end
	local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.fromRGB(120, 76, 62), BorderSizePixel = 0, ZIndex = 9 }, track)
	new("UICorner", { CornerRadius = UDim.new(0, 8) }, fill)
	local knob = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(14, 42), BackgroundColor3 = CREAM, BorderSizePixel = 0, ZIndex = 12 }, track)
	new("UICorner", { CornerRadius = UDim.new(0, 5) }, knob)
	local function show()
		local v = player:GetAttribute(attr) or 0.5
		knob.Position = UDim2.fromScale(v, 0.5)
		fill.Size = UDim2.fromScale(v, 1)
	end
	local function setFromX(x: number)
		local v = math.clamp((x - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
		v = math.floor(v * 20 + 0.5) / 20
		player:SetAttribute(attr, v)
		show()
	end
	local dragging = false
	track.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; setFromX(i.Position.X) end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then setFromX(i.Position.X) end
	end)
	UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
	show()
end

local function toggle(label: string, attr: string, default: boolean)
	local f = rowBase(label)
	if player:GetAttribute(attr) == nil then player:SetAttribute(attr, default) end
	local pill = new("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -4, 0.5, 0), Size = UDim2.fromOffset(100, 44), Text = "", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 9 }, f)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, pill)
	local dot = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(34, 34), BackgroundColor3 = CREAM, BorderSizePixel = 0, ZIndex = 10 }, pill)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)
	local function show()
		local on = player:GetAttribute(attr) == true
		TweenService:Create(pill, TweenInfo.new(0.18), { BackgroundColor3 = on and Color3.fromRGB(150, 100, 82) or Color3.fromRGB(58, 34, 30) }):Play()
		TweenService:Create(dot, TweenInfo.new(0.18), { Position = UDim2.new(on and 0.76 or 0.24, 0, 0.5, 0), BackgroundColor3 = on and CREAM or Color3.fromRGB(130, 90, 78) }):Play()
	end
	pill.MouseButton1Click:Connect(function() player:SetAttribute(attr, not (player:GetAttribute(attr) == true)); show() end)
	player:GetAttributeChangedSignal(attr):Connect(show)
	show()
end

header("VOLUME")
slider("Lobby Music", "EvaKVolLobby")
slider("Game Music", "EvaKVolGame")
header("CAMERA & GRAPHICS")
player:SetAttribute("EvaKFov", player:GetAttribute("EvaKFov") or 0.25)
player:SetAttribute("EvaKShake", player:GetAttribute("EvaKShake") or 0.5)
player:SetAttribute("EvaKBright", player:GetAttribute("EvaKBright") or 0.68)
slider("Field of View", "EvaKFov")
slider("Camera Shake", "EvaKShake")
slider("Brightness", "EvaKBright")
header("MISC")
toggle("New Year theme (off = classic: first song, no snow)", "EvaKNYTheme", true)
local function syncTheme() player:SetAttribute("EvaKTheme", player:GetAttribute("EvaKNYTheme") == false and "classic" or "ny") end
player:GetAttributeChangedSignal("EvaKNYTheme"):Connect(syncTheme); syncTheme()
toggle("Show FPS", "EvaKShowFps", false)
toggle("Crosshair", "EvaKCrosshair", true)
toggle("Toggle Crouch", "EvaKToggleCrouch", false)
toggle("Reduce Motion", "EvaKReduceMotion", false)
toggle("Hide Own Clothes", "EvaKHideClothes", false)
toggle("Low-End Mode", "EvaKLowEnd", false)

-- ПРОМОКОД (внизу)
header("PROMO CODE")
do
	local f = new("Frame", { Size = UDim2.new(1, -6, 0, 54), BackgroundTransparency = 1, LayoutOrder = nx(), ZIndex = 8 }, list)
	local box = new("TextBox", { Position = UDim2.fromOffset(8, 5), Size = UDim2.new(1, -170, 0, 44), BackgroundColor3 = ROW, BorderSizePixel = 0, Text = "", PlaceholderText = "ENTER CODE",
		PlaceholderColor3 = Color3.fromRGB(170, 130, 110), TextColor3 = CREAM, Font = FONT, TextSize = 26, ClearTextOnFocus = false, ZIndex = 9 }, f)
	new("UICorner", { CornerRadius = UDim.new(0, 10) }, box)
	local btn = new("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 5), Size = UDim2.fromOffset(142, 44), BackgroundColor3 = Color3.fromRGB(150, 100, 82),
		Text = "REDEEM", Font = FONT, TextSize = 26, TextColor3 = FILL, ZIndex = 9 }, f)
	new("UICorner", { CornerRadius = UDim.new(0, 10) }, btn)
	local res = new("TextLabel", { Size = UDim2.new(1, -6, 0, 26), BackgroundTransparency = 1, Text = "", Font = FONT, TextSize = 22, TextColor3 = CREAM, LayoutOrder = nx(), ZIndex = 9 }, list)
	local busy = false
	local function redeem()
		if busy or string.gsub(box.Text, "%s", "") == "" then return end
		busy = true
		local shop = ReplicatedStorage:FindFirstChild("EvaKShop") or ReplicatedStorage:WaitForChild("EvaKShop", 5)
		local ok, r = false, nil
		if shop then ok, r = pcall(function() return shop:InvokeServer("Redeem", box.Text) end) end
		if ok and type(r) == "table" and r.ok then
			res.Text = "+" .. tostring(r.msg) .. (tostring(r.msg):match("%a") and "!" or " BADGES!")
			res.TextColor3 = Color3.fromRGB(150, 230, 150)
			box.Text = ""
		else
			local m = ok and type(r) == "table" and r.msg or "error"
			res.Text = (m == "used" and "CODE ALREADY USED") or (m == "invalid" and "INVALID CODE") or "TRY AGAIN LATER"
			res.TextColor3 = Color3.fromRGB(240, 130, 110)
		end
		busy = false
	end
	btn.MouseButton1Click:Connect(redeem)
	box.FocusLost:Connect(function(enter) if enter then redeem() end end)
end

local function setOpen(v: boolean)
	if v then
		dim.Visible = true
		dim.BackgroundTransparency = 1
		win.Position = UDim2.fromScale(0.5, 0.56)
		TweenService:Create(dim, TweenInfo.new(0.3), { BackgroundTransparency = 0.45 }):Play()
		TweenService:Create(win, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = UDim2.fromScale(0.5, 0.5) }):Play()
	else
		TweenService:Create(dim, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(win, TweenInfo.new(0.25), { Position = UDim2.fromScale(0.5, 0.56) }):Play()
		task.delay(0.26, function() dim.Visible = false end)
	end
end
gear.MouseButton1Click:Connect(function() setOpen(not dim.Visible) end)
closeX.MouseButton1Click:Connect(function() setOpen(false) end)
dim.MouseButton1Click:Connect(function() setOpen(false) end)

-- ГРОМКОСТЬ: звуки лобби и игры назначаются в SoundGroup, громкость группы = ползунок * 2 (по умолчанию 1)
local lobbyG = new("SoundGroup", { Name = "EvaKLobbyVol" }, SoundService)
local gameG = new("SoundGroup", { Name = "EvaKGameVol" }, SoundService)
local function assign(s: Instance)
	if not s:IsA("Sound") then return end
	local n = s.Name
	if n == "MenuMusic" then s.SoundGroup = lobbyG
	elseif n:find("^EvaKNY") or n:find("^EvaKAtmo") or n == "EvaKBreath" then s.SoundGroup = gameG end
end
task.spawn(function()
	while true do
		lobbyG.Volume = (player:GetAttribute("EvaKVolLobby") or 0.5) * 2
		gameG.Volume = (player:GetAttribute("EvaKVolGame") or 0.5) * 2
		for _, s in SoundService:GetChildren() do assign(s) end
		for _, s in playerGui:GetDescendants() do assign(s) end
		task.wait(0.7)
	end
end)

-- HIDE OWN CLOTHES: скрывает свои аксессуары (шапки и т.п.)
RunService.Heartbeat:Connect(function()
	local char = player.Character
	if not char then return end
	local hide = player:GetAttribute("EvaKHideClothes") == true
	for _, a in char:GetChildren() do
		if a:IsA("Accessory") then
			local h = a:FindFirstChild("Handle")
			if h and h:IsA("BasePart") then h.LocalTransparencyModifier = hide and 1 or 0 end
		end
	end
end)


-- ---------- эффекты новых настроек ----------
do
	local Lighting = game:GetService("Lighting")
	local cc = Instance.new("ColorCorrectionEffect"); cc.Name = "EvaKUserBright"; cc.Parent = Lighting
	local fps = Instance.new("TextLabel"); fps.Name = "EvaKFps"; fps.AnchorPoint = Vector2.new(1, 0); fps.Position = UDim2.new(1, -150, 0, 6); fps.Size = UDim2.fromOffset(90, 20)
	fps.BackgroundTransparency = 1; fps.Font = Enum.Font.Code; fps.TextSize = 14; fps.TextColor3 = Color3.fromRGB(190, 230, 190); fps.TextXAlignment = Enum.TextXAlignment.Right; fps.Visible = false; fps.Parent = gui
	local frames, acc = 0, 0
	RunService.RenderStepped:Connect(function(dt)
		frames += 1; acc += dt
		if acc >= 0.5 then fps.Text = math.floor(frames / acc + 0.5) .. " FPS"; frames = 0; acc = 0 end
	end)
	task.spawn(function()
		while true do
			cc.Brightness = ((player:GetAttribute("EvaKBright") or 0.68) - 0.5) * 0.35
			fps.Visible = player:GetAttribute("EvaKShowFps") == true
			local ch = playerGui:FindFirstChild("EvaKCrosshair")
			if ch and ch:IsA("ScreenGui") then ch.Enabled = player:GetAttribute("EvaKCrosshair") ~= false end
			task.wait(0.4)
		end
	end)
end
