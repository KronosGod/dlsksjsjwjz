-- ============================================================
--  EvaKJournal (LocalScript в StarterPlayerScripts)
--  Книга-справочник (кнопка 📖 рядом с шестерёнкой или клавиши J / B, работают и в игре): вкладки MONSTERS / ITEMS / LOCATIONS / MISC.
--  Всё нарисовано кодом (никаких чужих картинок). Текст страниц - таблица ENTRIES ниже, можно править.
-- ============================================================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local PAPER = Color3.fromRGB(240, 212, 178)
local PAPER2 = Color3.fromRGB(222, 190, 152)
local INK = Color3.fromRGB(46, 30, 26)
local RED = Color3.fromRGB(122, 36, 32)
local TITLE_FONT = Enum.Font.PermanentMarker
local BODY_FONT = Enum.Font.PatrickHand

local TABS = {
	{ id = "m", glyph = "☠", color = Color3.fromRGB(214, 84, 84), name = "MONSTERS" },
	{ id = "i", glyph = "🔦", color = Color3.fromRGB(232, 200, 84), name = "ITEMS" },
	{ id = "l", glyph = "🚪", color = Color3.fromRGB(104, 190, 96), name = "LOCATIONS" },
	{ id = "x", glyph = "✎", color = Color3.fromRGB(96, 124, 214), name = "MISC" },
}

-- icon: "face:<цвет>" рисуется кодом, иначе символ/эмодзи
local ENTRIES = {
	{ tab = "m", title = "EvaK", icon = "face:60,60,66", text = "The master of this hotel. He hunts anyone who dares to open the doors. He never tires and never forgets a face.",
		tips = { "Never stop for long.", "When the lights flicker, get ready to hide.", "Wardrobes are great hiding spots." }, mark = "= HIDE!" },
	{ tab = "m", title = "Fallen", icon = "face:90,44,44", text = "Appears right behind you, out of thin air. You only notice it when the air turns cold.",
		tips = { "Keep moving and check behind you.", "It hits hard: heal at chests (+25 HP)." } },
	{ tab = "m", title = "The Preacher", icon = "face:70,52,84", text = "Copies your voice. 'Help me... I'm here... come closer...' Nobody is there. Nobody was ever there.",
		tips = { "Never walk toward a voice.", "Close the door behind you." } },
	{ tab = "m", title = "The Guest", icon = "face:200,200,206", text = "Stands at the end of the corridor and does not move. At least, not while you are watching.",
		tips = { "Keep it in sight.", "Never turn your back on it.", "Back away slowly." }, mark = "WATCH IT!" },
	{ tab = "m", title = "The Crawl", icon = "face:44,44,48", text = "Crawls along the ceiling above you. Slow, quiet and patient.",
		tips = { "Shine the FLASHLIGHT (G) at the ceiling.", "A cross appears on it and it burns away.", "Watch your battery." }, mark = "✝ = LIGHT" },
	{ tab = "m", title = "Wall Crawler", icon = "face:52,70,60", text = "Crawls along the wall beside you, twitching, and lunges the moment it gets close.",
		tips = { "Light it up with the flashlight.", "Don't let it reach you." }, mark = "✝ = LIGHT" },
	{ tab = "m", title = "The Witness", icon = "face:30,30,34", text = "Two white eyes in a window or behind a wall. It only watches. For now.",
		tips = { "Do not stare back.", "Move on to the next door." } },
	{ tab = "m", title = "The Bellman", icon = "face:150,110,50", text = "DING! DING! He rings his bell and the chase begins.",
		tips = { "Run, or hide in a wardrobe.", "He is faster than he looks." }, mark = "RUN!" },

	{ tab = "i", title = "Flashlight", icon = "🔦", text = "Buy it in the shop or before a run. It shines far brighter than a lamp, but has a battery.",
		tips = { "Press G to toggle.", "Aim at ceiling and wall crawlers: a cross appears and they vanish.", "Don't waste the battery." } },
	{ tab = "i", title = "Cursed Lantern", icon = "🏮", text = "Lights up dark rooms and keeps the shadows away from your feet.", tips = { "Buy it with badges in the shop." } },
	{ tab = "i", title = "Broken Watch", icon = "⌚", text = "It still ticks. It shows how long until the next event.", tips = { "Buy it with badges in the shop." } },
	{ tab = "i", title = "Owner's Key", icon = "🗝", text = "Opens the secret notes 6 to 9 in the lore menu.", tips = { "Buy it with badges in the shop." } },
	{ tab = "i", title = "Eye of EvaK", icon = "🧿", text = "A rare amulet with a red eye. People say it looks back.", tips = { "A rare shop item." } },

	{ tab = "l", title = "The Hotel", icon = "🚪", text = "One hundred doors. Rooms, corridors, storerooms and things that are not rooms at all.",
		tips = { "Search drawers and chests for badges.", "Some rooms have side storerooms.", "Not every door is real." } },
	{ tab = "l", title = "Room 666", icon = "👑", text = "The throne room. The throne is empty. EvaK is not here... yet.", tips = { "Reach it and survive." } },
	{ tab = "l", title = "Love Doors", icon = "♥", text = "A secret room behind a panel in a storeroom, marked with a chalk heart.", tips = { "Look for a panel that says PUSH.", "A note inside: <3 Love Doors." } },
	{ tab = "l", title = "Endless", icon = "∞", text = "There is no door 100. Only more doors. The leaderboard remembers how far you went.", tips = { "Pick ENDLESS in the difficulty menu." } },

	{ tab = "x", title = "Controls", icon = "⌨", text = "WASD to move. Shift to sprint. C to crouch. G for the flashlight. J or B opens this book. P - players menu. F2 - admin panel (admins). T or / - chat.",
		tips = { "Enable Toggle Crouch in Settings if you prefer." } },
	{ tab = "x", title = "Badges & Shop", icon = "★", text = "Badges are earned by opening doors and finishing runs. Spend them on cosmetics, cases and items.",
		tips = { "Open the player menu on the right for profiles, frames and titles." } },
	{ tab = "x", title = "Events", icon = "☾", text = "Blood Moon, Blackout, Invasion and worse. An event box in the bottom-right shows what is happening and for how long.",
		tips = { "The Broken Watch shows the next one." } },
}

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in props do o[k] = v end
	o.Parent = parent
	return o
end

local gui = new("ScreenGui", { Name = "EvaKJournalGui", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 91, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, playerGui)

local openBtn = new("TextButton", { Position = UDim2.fromOffset(250, 10), Size = UDim2.fromOffset(46, 46), BackgroundColor3 = Color3.fromRGB(14, 12, 12), Text = "📖", Font = Enum.Font.GothamBold,
	TextSize = 26, TextColor3 = Color3.new(1, 1, 1) }, gui)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, openBtn)

local dim = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Visible = false, Modal = true, ZIndex = 5 }, gui)
local book = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromOffset(840, 470), BackgroundTransparency = 1, ZIndex = 6 }, dim)
local us = new("UIScale", {}, book)
local function rescale()
	local cam = workspace.CurrentCamera
	local v = cam and cam.ViewportSize or Vector2.new(1280, 720)
	us.Scale = math.clamp(math.min(v.X / 900, v.Y / 600), 0.45, 1.2)
end
rescale()
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale) end

-- страницы
local function page(x: number)
	local p = new("Frame", { Position = UDim2.fromOffset(x, 0), Size = UDim2.fromOffset(410, 470), BackgroundColor3 = PAPER, BorderSizePixel = 0, ZIndex = 7 }, book)
	new("UICorner", { CornerRadius = UDim.new(0, 8) }, p)
	new("UIStroke", { Color = PAPER2, Thickness = 3 }, p)
	return p
end
local leftP, rightP = page(0), page(430)
local leftC = new("CanvasGroup", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 8 }, leftP)
local rightC = new("CanvasGroup", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 8 }, rightP)

-- пружина
for i = 0, 9 do
	local c = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(420, 30 + i * 44), Size = UDim2.fromOffset(86, 20), BackgroundColor3 = Color3.fromRGB(46, 32, 30),
		BorderSizePixel = 0, Rotation = -8, ZIndex = 10 }, book)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, c)
end

-- вкладки (бумажки сверху)
local tabBtns = {}
for i, t in TABS do
	local b = new("TextButton", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromOffset(540 + (i - 1) * 74, 6), Size = UDim2.fromOffset(66, 46), BackgroundColor3 = t.color,
		Text = t.glyph, Font = Enum.Font.GothamBold, TextSize = 26, TextColor3 = Color3.fromRGB(60, 36, 30), AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 6 }, book)
	new("UICorner", { CornerRadius = UDim.new(0, 4) }, b)
	tabBtns[t.id] = b
end

local function label(parent, text, size, font, color, pos, sz, align)
	return new("TextLabel", { Position = pos, Size = sz, BackgroundTransparency = 1, Text = text, Font = font, TextSize = size, TextColor3 = color, TextWrapped = true,
		TextXAlignment = align or Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 9 }, parent)
end

local function drawIcon(parent: Instance, icon: string, x: number, y: number)
	local r, g, b = icon:match("^face:(%d+),(%d+),(%d+)")
	if r then
		local head = new("Frame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(120, 110), BackgroundColor3 = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b)), BorderSizePixel = 0, ZIndex = 9 }, parent)
		new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, head)
		new("UIStroke", { Color = Color3.fromRGB(30, 18, 16), Thickness = 3 }, head)
		for _, ex in { 28, 72 } do
			local eye = new("Frame", { Position = UDim2.fromOffset(ex, 28), Size = UDim2.fromOffset(22, 22), BackgroundColor3 = Color3.fromRGB(250, 250, 245), BorderSizePixel = 0, ZIndex = 10 }, head)
			new("UICorner", { CornerRadius = UDim.new(1, 0) }, eye)
			local pu = new("Frame", { Position = UDim2.fromOffset(8, 7), Size = UDim2.fromOffset(7, 8), BackgroundColor3 = Color3.fromRGB(20, 12, 10), BorderSizePixel = 0, ZIndex = 11 }, eye)
			new("UICorner", { CornerRadius = UDim.new(1, 0) }, pu)
		end
		local mouth = new("Frame", { Position = UDim2.fromOffset(22, 66), Size = UDim2.fromOffset(76, 24), BackgroundColor3 = Color3.fromRGB(240, 238, 230), BorderSizePixel = 0, ZIndex = 10 }, head)
		new("UICorner", { CornerRadius = UDim.new(0, 10) }, mouth)
		for k = 1, 5 do
			new("Frame", { Position = UDim2.fromOffset(k * 12 - 2, 0), Size = UDim2.fromOffset(2, 24), BackgroundColor3 = Color3.fromRGB(60, 30, 28), BorderSizePixel = 0, ZIndex = 11 }, mouth)
		end
	else
		new("TextLabel", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(120, 110), BackgroundTransparency = 1, Text = icon, Font = Enum.Font.GothamBold, TextSize = 76,
			TextColor3 = INK, ZIndex = 9 }, parent)
	end
end

local spreads: {{number}} = {}   -- индексы записей на каждый разворот: по одному на разворот
local idx = 1
local function tabFirst(id: string): number
	for i, e in ENTRIES do if e.tab == id then return i end end
	return 1
end

local function clear(c: Instance) for _, ch in c:GetChildren() do ch:Destroy() end end

local function render()
	local e = ENTRIES[idx]
	clear(leftC); clear(rightC)
	-- левая страница: название, значок, описание
	label(leftC, tostring(idx * 2 - 1), 18, Enum.Font.GothamBold, INK, UDim2.fromOffset(18, 14), UDim2.fromOffset(40, 20))
	label(leftC, "... " .. (TABS[table.find({ "m", "i", "l", "x" }, e.tab) :: number].name), 15, Enum.Font.GothamBold, Color3.fromRGB(110, 90, 80), UDim2.fromOffset(60, 16), UDim2.fromOffset(300, 20))
	label(leftC, e.title, 44, TITLE_FONT, INK, UDim2.fromOffset(28, 48), UDim2.fromOffset(360, 56))
	drawIcon(leftC, e.icon, 28, 122)
	label(leftC, e.text, 24, BODY_FONT, INK, UDim2.fromOffset(160, 118), UDim2.fromOffset(226, 150))
	-- правая страница: советы
	label(rightC, tostring(idx * 2), 18, Enum.Font.GothamBold, INK, UDim2.new(1, -58, 0, 14), UDim2.fromOffset(40, 20), Enum.TextXAlignment.Right)
	label(rightC, "SURVIVAL NOTES", 22, TITLE_FONT, RED, UDim2.fromOffset(28, 30), UDim2.fromOffset(360, 30))
	local y = 74
	for _, t in e.tips do
		label(rightC, "•  " .. t, 25, BODY_FONT, INK, UDim2.fromOffset(28, y), UDim2.fromOffset(360, 60))
		y += 54
	end
	if e.mark then label(rightC, e.mark, 38, TITLE_FONT, INK, UDim2.fromOffset(28, 380), UDim2.fromOffset(360, 50)) end
	-- подсветка вкладок
	for id, b in tabBtns do
		TweenService:Create(b, TweenInfo.new(0.15), { Position = UDim2.fromOffset(b.Position.X.Offset, id == e.tab and -6 or 6) }):Play()
	end
end

local flipping = false
local function flipTo(i: number)
	if flipping then return end
	i = math.clamp(i, 1, #ENTRIES)
	if i == idx then return end
	flipping = true
	local ti = TweenInfo.new(0.12)
	TweenService:Create(leftC, ti, { GroupTransparency = 1 }):Play()
	TweenService:Create(rightC, ti, { GroupTransparency = 1 }):Play()
	task.wait(0.13)
	idx = i
	render()
	local ti2 = TweenInfo.new(0.22)
	TweenService:Create(leftC, ti2, { GroupTransparency = 0 }):Play()
	TweenService:Create(rightC, ti2, { GroupTransparency = 0 }):Play()
	task.wait(0.22)
	flipping = false
end

for id, b in tabBtns do
	b.MouseButton1Click:Connect(function() flipTo(tabFirst(id)) end)
end

-- стрелки и закрытие
local function arrow(text: string, x: number, dx: number)
	local a = new("TextButton", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0, x, 1, 12), Size = UDim2.fromOffset(110, 50), BackgroundTransparency = 1, Text = text,
		Font = Enum.Font.GothamBlack, TextSize = 54, TextColor3 = Color3.fromRGB(250, 226, 196), ZIndex = 10 }, book)
	a.MouseButton1Click:Connect(function() flipTo(idx + dx) end)
end
arrow("↶", 70, -1)
arrow("↷", 770, 1)
local closeBtn = new("TextButton", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 14), Size = UDim2.fromOffset(50, 50), BackgroundTransparency = 1, Text = "✕", Font = Enum.Font.GothamBlack,
	TextSize = 40, TextColor3 = Color3.fromRGB(250, 226, 196), ZIndex = 12 }, book)

local function setOpen(v: boolean)
	if v then
		render()
		dim.Visible = true
		dim.BackgroundTransparency = 1
		book.Position = UDim2.fromScale(0.5, 0.6)
		TweenService:Create(dim, TweenInfo.new(0.3), { BackgroundTransparency = 0.5 }):Play()
		TweenService:Create(book, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = UDim2.fromScale(0.5, 0.52) }):Play()
	else
		TweenService:Create(dim, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(book, TweenInfo.new(0.25), { Position = UDim2.fromScale(0.5, 0.6) }):Play()
		task.delay(0.26, function() dim.Visible = false end)
	end
end
openBtn.MouseButton1Click:Connect(function() setOpen(not dim.Visible) end)
closeBtn.MouseButton1Click:Connect(function() setOpen(false) end)
-- горячие клавиши J и B работают и в игре (от первого лица): ContextActionService с высоким приоритетом
local CAS = game:GetService("ContextActionService")
CAS:BindActionAtPriority("EvaKBookKey", function(_, state)
	if state == Enum.UserInputState.Begin then setOpen(not dim.Visible) end
	return Enum.ContextActionResult.Pass
end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.J, Enum.KeyCode.B)
