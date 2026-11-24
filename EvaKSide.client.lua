-- ============================================================
--  EvaKSide (LocalScript в StarterPlayerScripts)
--  Справа две белые линии-«ручка»: нажми - выдвигается меню с игроками сервера.
--  Для каждого: приглашение в лобби и просмотр статистики. Также принимает приглашения.
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local rf = ReplicatedStorage:WaitForChild("EvaKExtra", 30)
local fx = ReplicatedStorage:WaitForChild("EvaKExtraFx", 30)
if not rf or not fx then return end

local GOLD, RED = Color3.fromRGB(230, 200, 140), Color3.fromRGB(215, 48, 40)
local FONT = Enum.Font.Arcade
local PANEL_W = 330

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in props do o[k] = v end
	o.Parent = parent
	return o
end
local function call(...)
	local ok, r = pcall(function(...) return rf:InvokeServer(...) end, ...)
	return ok and r or { ok = false, msg = "error" }
end

local gui = new("ScreenGui", { Name = "EvaKSideGui", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 320 }, playerGui)

-- выдвижная панель
local panel = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, PANEL_W + 20, 0.5, 0), Size = UDim2.fromOffset(PANEL_W, 430),
	BackgroundColor3 = Color3.fromRGB(12, 8, 8), BackgroundTransparency = 0.08, BorderSizePixel = 0 }, gui)
new("UICorner", { CornerRadius = UDim.new(0, 0) }, panel)
new("UIStroke", { Color = Color3.fromRGB(235, 235, 235), Thickness = 1.5, Transparency = 0.3 }, panel)

do   -- масштаб под размер экрана (телефон/планшет/ПК)
	local cam = workspace.CurrentCamera
	local function k() local v = cam and cam.ViewportSize or Vector2.new(1280, 720); return math.clamp(math.min(v.X / 1100, v.Y / 700), 0.55, 1.1) end
	local us = Instance.new("UIScale"); us.Scale = k(); us.Parent = panel
	if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(function() us.Scale = k() end) end
end
new("TextLabel", { Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -32, 0, 26), BackgroundTransparency = 1, Text = "PLAYERS", Font = FONT, TextSize = 16,
	TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Left }, panel)
local showProfile
local myBtn = new("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 8), Size = UDim2.fromOffset(150, 26), BackgroundColor3 = Color3.fromRGB(110, 28, 22),
	Text = "MY PROFILE / SHOP", Font = FONT, TextSize = 11, TextColor3 = GOLD }, panel)
myBtn.MouseButton1Click:Connect(function() showProfile(player.UserId) end)
local hint = new("TextLabel", { Position = UDim2.fromOffset(16, 34), Size = UDim2.new(1, -32, 0, 16), BackgroundTransparency = 1, Text = "Create a lobby first to invite players", Font = Enum.Font.Arcade,
	TextSize = 11, TextColor3 = Color3.fromRGB(150, 130, 110), TextXAlignment = Enum.TextXAlignment.Left }, panel)
local list = new("ScrollingFrame", { Position = UDim2.fromOffset(10, 58), Size = UDim2.new(1, -20, 1, -68), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
	CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y }, panel)
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, list)

-- ручка: две белые линии
local handle = new("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(26, 90), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, gui)
local lines = {}
for i = 0, 1 do
	local l = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, (i - 0.5) * 8, 0.5, 0), Size = UDim2.fromOffset(3, 64), BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.15, BorderSizePixel = 0 }, handle)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, l)
	table.insert(lines, l)
end
handle.MouseEnter:Connect(function() for _, l in lines do TweenService:Create(l, TweenInfo.new(0.15), { BackgroundTransparency = 0, Size = UDim2.fromOffset(3, 76) }):Play() end end)
handle.MouseLeave:Connect(function() for _, l in lines do TweenService:Create(l, TweenInfo.new(0.15), { BackgroundTransparency = 0.15, Size = UDim2.fromOffset(3, 64) }):Play() end end)

local function toast(text: string)
	hint.Text = text
	hint.TextColor3 = Color3.fromRGB(230, 140, 110)
	task.delay(3.5, function()
		if hint.Text == text then hint.Text = "Create a lobby first to invite players"; hint.TextColor3 = Color3.fromRGB(150, 130, 110) end
	end)
end

local function circleAvatar(parent: Instance, uid: number, size: number)
	local img = new("ImageLabel", { Size = UDim2.fromOffset(size, size), BackgroundColor3 = Color3.fromRGB(40, 28, 24), Image = "" }, parent)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, img)
	task.spawn(function()
		local ok, url = pcall(function() return Players:GetUserThumbnailAsync(uid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100) end)
		if ok and img.Parent then img.Image = url end
	end)
	return img
end


-- ================= ПРОФИЛЬ (рамка, титул, значки, аксессуары, статистика, магазин) =================
local FRAMES = {
	frame_bronze = { Color3.fromRGB(215, 140, 60), Color3.fromRGB(110, 60, 20) },
	frame_silver = { Color3.fromRGB(240, 240, 250), Color3.fromRGB(130, 135, 150) },
	frame_gold   = { Color3.fromRGB(255, 225, 90), Color3.fromRGB(170, 110, 20) },
	frame_blood  = { Color3.fromRGB(230, 30, 30), Color3.fromRGB(70, 0, 0) },
	frame_neon   = { Color3.fromRGB(60, 255, 230), Color3.fromRGB(190, 60, 255) },
	frame_devil  = { Color3.fromRGB(255, 190, 30), Color3.fromRGB(220, 20, 10) },
	frame_royal  = { Color3.fromRGB(255, 232, 110), Color3.fromRGB(150, 30, 190) },   -- королевская (только владелец)
	frame_horns  = { Color3.fromRGB(255, 70, 30), Color3.fromRGB(70, 0, 0) },        -- дьявольская: красно-чёрная, рога сверху
	frame_demon  = { Color3.fromRGB(255, 40, 20), Color3.fromRGB(40, 0, 0) },
	frame_angel  = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(190, 225, 255) },  -- ангельская: белая, золотой нимб и крылья
	frame_halo   = { Color3.fromRGB(255, 236, 140), Color3.fromRGB(255, 255, 255) },
	frame_seraph = { Color3.fromRGB(255, 240, 150), Color3.fromRGB(150, 210, 255) },
}

-- украшения рамок: рога, нимб, крылья (рисуются вокруг аватара в профиле)
local function decorate(av: GuiObject, id: string?)
	for _, c in av:GetChildren() do if c.Name == "Deco" then c:Destroy() end end
	if not id then return end
	local W = av.AbsoluteSize.X > 0 and av.AbsoluteSize.X or 170
	local function ell(x: number, y: number, w: number, h: number, rot: number, c0: Color3, c1: Color3, z: number)
		local f = new("Frame", { Name = "Deco", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(x, 0, y, 0), Size = UDim2.fromOffset(w, h), Rotation = rot, BackgroundColor3 = c0, BorderSizePixel = 0, ZIndex = z }, av)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, f)
		new("UIGradient", { Color = ColorSequence.new(c0, c1), Rotation = 90 }, f)
		return f
	end
	if id == "frame_horns" or id == "frame_demon" then
		for _, s in { -1, 1 } do   -- рог из 3 звеньев, загибается к центру
			local x0 = 0.5 + s * 0.42
			ell(x0, -0.02, W * 0.17, W * 0.26, s * 22, Color3.fromRGB(70, 6, 8), Color3.fromRGB(160, 20, 16), 51)
			ell(x0 - s * 0.045, -0.15, W * 0.11, W * 0.22, s * 42, Color3.fromRGB(110, 10, 10), Color3.fromRGB(220, 40, 24), 51)
			ell(x0 - s * 0.11, -0.25, W * 0.06, W * 0.17, s * 62, Color3.fromRGB(190, 30, 20), Color3.fromRGB(255, 120, 60), 51)
		end
		ell(0.5, 1.04, W * 0.7, W * 0.08, 0, Color3.fromRGB(255, 70, 20), Color3.fromRGB(90, 0, 0), 51)   -- тлеющая полоса снизу
	elseif id == "frame_angel" or id == "frame_halo" or id == "frame_seraph" then
		local halo = new("Frame", { Name = "Deco", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, -0.1, 0), Size = UDim2.fromOffset(W * 0.62, W * 0.16), BackgroundTransparency = 1, ZIndex = 55 }, av)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, halo)
		local hs = new("UIStroke", { Color = Color3.fromRGB(255, 215, 70), Thickness = 5 }, halo)
		new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(255, 245, 160), Color3.fromRGB(255, 190, 40)), Rotation = 0 }, hs)
		if id ~= "frame_halo" then
			for _, s in { -1, 1 } do   -- крылья: три пера
				for i = 0, 2 do
					ell(0.5 + s * (0.62 + i * 0.07), 0.28 + i * 0.12, W * 0.34, W * 0.1, s * (-24 + i * 14), Color3.fromRGB(235, 245, 255), Color3.fromRGB(255, 255, 255), 50)
				end
			end
		end
	end
end

-- переливающийся ник владельца: все такие подписи красятся одним циклом
local rainbowLabels: {TextLabel} = {}
game:GetService("RunService").Heartbeat:Connect(function()
	local hue = (os.clock() * 0.35) % 1
	for i = #rainbowLabels, 1, -1 do
		local l = rainbowLabels[i]
		if l.Parent then l.TextColor3 = Color3.fromHSV((hue + i * 0.05) % 1, 0.7, 1) else table.remove(rainbowLabels, i) end
	end
end)
local PIN_GLYPH = { pin_cross = "✝", pin_skull = "☠", pin_heart = "♥", pin_star = "★", pin_moon = "☾", pin_flame = "✦" }
local PIN_COL = { pin_cross = Color3.fromRGB(235, 235, 235), pin_skull = Color3.fromRGB(210, 210, 190), pin_heart = Color3.fromRGB(235, 60, 90),
	pin_star = Color3.fromRGB(255, 215, 70), pin_moon = Color3.fromRGB(150, 190, 255), pin_flame = Color3.fromRGB(255, 130, 40) }

local profDim = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.5, Text = "", AutoButtonColor = false, Visible = false, ZIndex = 50 }, gui)
local win = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(640, 500), BackgroundColor3 = Color3.fromRGB(14, 9, 8), BorderSizePixel = 0, ZIndex = 51 }, profDim)
new("UIStroke", { Color = Color3.fromRGB(140, 100, 50), Thickness = 2 }, win)
new("UISizeConstraint", { MaxSize = Vector2.new(640, 500) }, win)

do   -- масштаб под размер экрана (телефон/планшет/ПК)
	local cam = workspace.CurrentCamera
	local function k() local v = cam and cam.ViewportSize or Vector2.new(1280, 720); return math.clamp(math.min(v.X / 1100, v.Y / 700), 0.55, 1.1) end
	local us = Instance.new("UIScale"); us.Scale = k(); us.Parent = win
	if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(function() us.Scale = k() end) end
end
local xBtn = new("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 8), Size = UDim2.fromOffset(30, 30), BackgroundTransparency = 1, Text = "X", Font = FONT, TextSize = 20, TextColor3 = GOLD, ZIndex = 53 }, win)
xBtn.MouseButton1Click:Connect(function() profDim.Visible = false end)

local avFrame = new("Frame", { Position = UDim2.fromOffset(22, 24), Size = UDim2.fromOffset(170, 170), BackgroundColor3 = Color3.fromRGB(30, 20, 18), BorderSizePixel = 0, ZIndex = 52 }, win)
local avStroke = new("UIStroke", { Color = Color3.fromRGB(90, 70, 55), Thickness = 3 }, avFrame)
local avGrad = new("UIGradient", { Color = ColorSequence.new(Color3.new(1, 1, 1)), Rotation = 45 }, avStroke)
local avImg = new("ImageLabel", { Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 1, -12), BackgroundTransparency = 1, Image = "", ZIndex = 53 }, avFrame)
local nameLbl = new("TextLabel", { Position = UDim2.fromOffset(12, 202), Size = UDim2.fromOffset(190, 24), BackgroundTransparency = 1, Font = FONT, TextSize = 17, TextColor3 = GOLD, Text = "", TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 52 }, win)
local titleLbl2 = new("TextLabel", { Position = UDim2.fromOffset(12, 226), Size = UDim2.fromOffset(190, 20), BackgroundTransparency = 1, Font = FONT, TextSize = 13, TextColor3 = Color3.fromRGB(230, 60, 50), Text = "", TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 52 }, win)
local pinsRow = new("Frame", { Position = UDim2.fromOffset(16, 254), Size = UDim2.fromOffset(182, 70), BackgroundTransparency = 1, ZIndex = 52 }, win)
new("UIGridLayout", { CellSize = UDim2.fromOffset(34, 34), CellPadding = UDim2.fromOffset(4, 4), SortOrder = Enum.SortOrder.LayoutOrder }, pinsRow)
local invBtn = new("TextButton", { Position = UDim2.fromOffset(22, 340), Size = UDim2.fromOffset(170, 34), BackgroundColor3 = Color3.fromRGB(110, 28, 22), Text = "INVITE TO LOBBY", Font = FONT, TextSize = 14, TextColor3 = GOLD, ZIndex = 52 }, win)
local msgLbl = new("TextLabel", { Position = UDim2.fromOffset(12, 380), Size = UDim2.fromOffset(190, 60), BackgroundTransparency = 1, Font = Enum.Font.Arcade, TextSize = 11, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top,
	TextColor3 = Color3.fromRGB(230, 140, 110), Text = "", ZIndex = 52 }, win)

local right = new("ScrollingFrame", { Position = UDim2.fromOffset(222, 48), Size = UDim2.new(1, -240, 1, -62), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
	CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 52 }, win)
new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, right)

local profUid = 0
local shopTab = "frame"

local function pmsg(t: string) msgLbl.Text = t; task.delay(4, function() if msgLbl.Text == t then msgLbl.Text = "" end end) end

local function rowLabel(a: string, bText: string, order: number)
	local f = new("Frame", { Size = UDim2.new(1, -8, 0, 26), BackgroundColor3 = Color3.fromRGB(26, 16, 14), BorderSizePixel = 0, LayoutOrder = order, ZIndex = 53 }, right)
	new("TextLabel", { Position = UDim2.fromOffset(10, 0), Size = UDim2.new(0.55, 0, 1, 0), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Text = a,
		Font = Enum.Font.Arcade, TextSize = 13, TextColor3 = Color3.fromRGB(190, 170, 150), ZIndex = 54 }, f)
	new("TextLabel", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 0), Size = UDim2.new(0.45, 0, 1, 0), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Right,
		Text = bText, Font = FONT, TextSize = 14, TextColor3 = GOLD, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 54 }, f)
end

local function header(text: string, order: number)
	new("TextLabel", { Size = UDim2.new(1, -8, 0, 24), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Text = text, Font = FONT, TextSize = 14,
		TextColor3 = RED, LayoutOrder = order, ZIndex = 53 }, right)
end

showProfile = function(uid: number)
	local r = call("StatsOf", uid)
	if not r.ok then toast("profile unavailable"); return end
	profUid = uid
	nameLbl.Text = (r.owner and "[GOD] " or "") .. (r.vip and "[CarBon] " or "") .. r.name
	if r.owner then table.insert(rainbowLabels, nameLbl) else nameLbl.TextColor3 = GOLD end
	titleLbl2.Text = r.title ~= "" and r.title:upper() or "NO TITLE"
	pcall(function() titleLbl2.TextColor3 = (r.title ~= "" and r.tcol) and Color3.fromHex(r.tcol) or Color3.fromRGB(150, 130, 110) end)
	msgLbl.Text = ""
	-- рамка
	local fc = FRAMES[r.frame]
	avStroke.Thickness = fc and 5 or 3
	avGrad.Color = fc and ColorSequence.new(fc[1], fc[2]) or ColorSequence.new(Color3.fromRGB(90, 70, 55))
	decorate(avFrame, fc and r.frame or nil)
	avImg.Image = ""
	task.spawn(function()
		local ok, url = pcall(function() return Players:GetUserThumbnailAsync(uid, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size150x150) end)
		if ok and profUid == uid then avImg.Image = url end
	end)
	-- значки
	for _, c in pinsRow:GetChildren() do if c:IsA("TextLabel") then c:Destroy() end end
	for i, id in r.pins do
		local g = new("TextLabel", { BackgroundColor3 = Color3.fromRGB(34, 22, 20), Text = PIN_GLYPH[id] or "?", Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = PIN_COL[id] or GOLD, LayoutOrder = i, ZIndex = 53 }, pinsRow)
		new("UIStroke", { Color = PIN_COL[id] or GOLD, Thickness = 1, Transparency = 0.4 }, g)
	end
	invBtn.Visible = not r.self
	-- правая часть
	for _, c in right:GetChildren() do if c:IsA("GuiObject") then c:Destroy() end end
	local o = 0
	local function nx() o += 1; return o end
	header("STATISTICS", nx())
	rowLabel("Time played", string.format("%dh %02dm", r.play // 3600, (r.play % 3600) // 60), nx())
	rowLabel("Badges", tostring(math.floor(r.badges)), nx())
	rowLabel("Snowflakes", tostring(math.floor(r.snow)), nx())
	rowLabel("Cases opened", tostring(r.cases), nx())
	rowLabel("Best door", tostring(r.best) .. " / 100", nx())
	rowLabel("Runs completed", tostring(r.done), nx())
	rowLabel("Runs failed", tostring(r.failed), nx())
	rowLabel("Items owned", tostring(r.owned), nx())
	header("ACCESSORIES", nx())
	rowLabel("Equipped", #r.acc > 0 and table.concat(r.acc, ", ") or "none", nx())
	if r.self then
		header("SHOP  -  YOUR BADGES: " .. tostring(math.floor(r.badges)), nx())
		local tabs = new("Frame", { Size = UDim2.new(1, -8, 0, 30), BackgroundTransparency = 1, LayoutOrder = nx(), ZIndex = 53 }, right)
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4) }, tabs)
		for _, t in { { "frame", "FRAMES" }, { "title", "TITLES" }, { "pin", "PINS" }, { "item", "ACCESSORIES" } } do
			local tb = new("TextButton", { Size = UDim2.fromOffset(86, 28), BackgroundColor3 = shopTab == t[1] and Color3.fromRGB(110, 28, 22) or Color3.fromRGB(50, 36, 24),
				Text = t[2], Font = FONT, TextSize = 11, TextColor3 = GOLD, ZIndex = 54 }, tabs)
			tb.MouseButton1Click:Connect(function() shopTab = t[1]; showProfile(uid) end)
		end
		local info = call("Info")
		if info.ok then
			for _, it in info.items do
				if it.kind ~= shopTab then continue end
				local f = new("Frame", { Size = UDim2.new(1, -8, 0, 42), BackgroundColor3 = Color3.fromRGB(26, 16, 14), BorderSizePixel = 0, LayoutOrder = nx(), ZIndex = 53 }, right)
				new("TextLabel", { Position = UDim2.fromOffset(10, 3), Size = UDim2.new(1, -120, 0, 20), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Text = it.name:upper(),
					Font = FONT, TextSize = 13, TextColor3 = it.equipped and RED or GOLD, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 54 }, f)
				local sub = it.owned and (it.kind == "pin" and "OWNED" or (it.equipped and "EQUIPPED" or "OWNED")) or (it.how == "buy" and (it.cost .. " BADGES") or it.how == "quest" and ("QUEST: " .. (it.quest or "")) or "NOT FOR SALE")
				new("TextLabel", { Position = UDim2.fromOffset(10, 23), Size = UDim2.new(1, -120, 0, 16), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Text = sub,
					Font = Enum.Font.Arcade, TextSize = 10, TextColor3 = Color3.fromRGB(170, 150, 130), TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 54 }, f)
				local label, act
				if it.owned and it.kind ~= "pin" then
					label = it.equipped and "UNEQUIP" or "EQUIP"
					act = function() call(it.equipped and "Unequip" or "Equip", it.equipped and it.slot or it.id) end
				elseif not it.owned and it.how == "buy" then
					label = "BUY"
					act = function() local rr = call("Buy", it.id); if not rr.ok then pmsg("Not enough badges") end end
				end
				if label then
					local b = new("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(92, 28), BackgroundColor3 = Color3.fromRGB(110, 28, 22),
						Text = label, Font = FONT, TextSize = 12, TextColor3 = GOLD, ZIndex = 54 }, f)
					b.MouseButton1Click:Connect(function() act(); showProfile(uid) end)
				end
			end
		end
	end
	profDim.Visible = true
end
invBtn.MouseButton1Click:Connect(function()
	if profUid == 0 then return end
	local rr = call("Invite", profUid)
	pmsg(rr.ok and "Invite sent" or tostring(rr.msg or "error"))
end)

local opened = false
local function refresh()
	local r = call("Players")
	for _, c in list:GetChildren() do if c:IsA("Frame") then c:Destroy() end end
	if not r.ok then
		local er = new("Frame", { Size = UDim2.new(1, -6, 0, 60), BackgroundTransparency = 1, LayoutOrder = 1 }, list)
		new("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, TextWrapped = true, Text = "Players list unavailable: " .. tostring(r.msg or "server not ready") .. " (retrying)", Font = Enum.Font.Arcade, TextSize = 12, TextColor3 = Color3.fromRGB(230, 140, 110) }, er)
		task.delay(3, function() if opened then refresh() end end)
		return
	end
	for i, p in r.players do
		local row = new("Frame", { Size = UDim2.new(1, -6, 0, 58), BackgroundColor3 = Color3.fromRGB(28, 18, 15), BorderSizePixel = 0, LayoutOrder = i }, list)
		new("UICorner", { CornerRadius = UDim.new(0, 0) }, row)
		local av = circleAvatar(row, p.id, 40); av.Position = UDim2.fromOffset(8, 9)
		local nameL = new("TextLabel", { Position = UDim2.fromOffset(56, 6), Size = UDim2.new(1, -150, 0, 20), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			Text = (p.owner and "[GOD] " or "") .. (p.vip and "[CarBon] " or "") .. p.name .. (p.self and "  (you)" or ""), Font = FONT, TextSize = 14, TextColor3 = p.vip and Color3.fromRGB(255, 90, 90) or GOLD }, row)
		if p.owner then table.insert(rainbowLabels, nameL) end
		local fcl = FRAMES[p.frame]
		if fcl then   -- рамка вокруг аватарки из купленной/выданной
			local st0 = new("UIStroke", { Thickness = 3, Color = Color3.new(1, 1, 1) }, av)
			new("UIGradient", { Color = ColorSequence.new(fcl[1], fcl[2]), Rotation = 45 }, st0)
		end
		new("TextLabel", { Position = UDim2.fromOffset(56, 28), Size = UDim2.new(1, -150, 0, 16), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			Text = p.inRun and "in a run" or (p.title ~= "" and p.title or "@" .. p.user), Font = Enum.Font.Arcade, TextSize = 11, TextColor3 = (p.title ~= "" and p.tcol) and Color3.fromHex(p.tcol) or Color3.fromRGB(150, 130, 110) }, row)
		local inv = new("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 6), Size = UDim2.fromOffset(78, 20), BackgroundColor3 = Color3.fromRGB(110, 28, 22), Text = "INVITE",
			Font = FONT, TextSize = 11, TextColor3 = GOLD }, row)
		new("UICorner", { CornerRadius = UDim.new(0, 0) }, inv)
		if p.self then inv.Visible = false end
		local st = new("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 31), Size = UDim2.fromOffset(78, 20), BackgroundColor3 = Color3.fromRGB(50, 36, 24), Text = "PROFILE",
			Font = FONT, TextSize = 11, TextColor3 = GOLD }, row)
		new("UICorner", { CornerRadius = UDim.new(0, 0) }, st)
		inv.MouseButton1Click:Connect(function()
			local rr = call("Invite", p.id)
			toast(rr.ok and ("Invite sent to " .. p.name) or tostring(rr.msg or "error"))
		end)
		st.MouseButton1Click:Connect(function() showProfile(p.id) end)
	end
	if #r.players == 0 then
		local row = new("Frame", { Size = UDim2.new(1, -6, 0, 40), BackgroundTransparency = 1, LayoutOrder = 1 }, list)
		new("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "Nobody else is here", Font = Enum.Font.Arcade, TextSize = 14, TextColor3 = Color3.fromRGB(150, 130, 110) }, row)
	end
end

local function setOpen(v: boolean)
	opened = v
	if v then refresh() end
	TweenService:Create(panel, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = UDim2.new(1, v and -34 or PANEL_W + 20, 0.5, 0) }):Play()
	TweenService:Create(handle, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = UDim2.new(1, v and -(PANEL_W + 40) or 0, 0.5, 0) }):Play()
end
handle.MouseButton1Click:Connect(function() setOpen(not opened) end)
-- кнопка Modal освобождает мышь в игре от первого лица, пока меню открыто
local freeMouse = new("TextButton", { Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1, Text = "", Modal = false }, panel)
local CAS = game:GetService("ContextActionService")
CAS:BindActionAtPriority("EvaKPlayersKey", function(_, state)
	if state == Enum.UserInputState.Begin then setOpen(not opened); freeMouse.Modal = opened end
	return Enum.ContextActionResult.Pass
end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.P)
handle.MouseButton1Click:Connect(function() freeMouse.Modal = opened end)
Players.PlayerAdded:Connect(function() if opened then task.delay(1, refresh) end end)
Players.PlayerRemoving:Connect(function() if opened then task.delay(0.5, refresh) end end)
task.spawn(function() while true do task.wait(8); if opened then refresh() end end end)

-- входящее приглашение в лобби
fx.OnClientEvent:Connect(function(kind, a, b)
	if kind ~= "LobbyInvite" then return end
	local card = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, -90), Size = UDim2.fromOffset(380, 76), BackgroundColor3 = Color3.fromRGB(14, 9, 8), BorderSizePixel = 0 }, gui)
	new("UICorner", { CornerRadius = UDim.new(0, 0) }, card)
	new("UIStroke", { Color = RED, Thickness = 1.5 }, card)
	new("TextLabel", { Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -28, 0, 22), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Text = tostring(a) .. " invites you to a lobby",
		Font = FONT, TextSize = 15, TextColor3 = GOLD }, card)
	local yes = new("TextButton", { Position = UDim2.fromOffset(14, 38), Size = UDim2.fromOffset(110, 28), BackgroundColor3 = Color3.fromRGB(40, 110, 50), Text = "ACCEPT", Font = FONT, TextSize = 13, TextColor3 = GOLD }, card)
	new("UICorner", { CornerRadius = UDim.new(0, 0) }, yes)
	local no = new("TextButton", { Position = UDim2.fromOffset(132, 38), Size = UDim2.fromOffset(110, 28), BackgroundColor3 = Color3.fromRGB(90, 24, 20), Text = "DECLINE", Font = FONT, TextSize = 13, TextColor3 = GOLD }, card)
	new("UICorner", { CornerRadius = UDim.new(0, 0) }, no)
	TweenService:Create(card, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Position = UDim2.new(0.5, 0, 0, 16) }):Play()
	local function close() TweenService:Create(card, TweenInfo.new(0.3), { Position = UDim2.new(0.5, 0, 0, -90) }):Play(); task.delay(0.4, function() card:Destroy() end) end
	yes.MouseButton1Click:Connect(function()
		close()
		local r = call("JoinInvite", b)
		if not r.ok then toast(tostring(r.msg or "could not join")) end
	end)
	no.MouseButton1Click:Connect(close)
	task.delay(20, function() if card.Parent then close() end end)
end)
