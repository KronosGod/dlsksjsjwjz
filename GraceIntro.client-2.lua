-- ============================================================
--  INTRO / MAIN MENU  (LocalScript)
--  Куда положить: StarterPlayer > StarterPlayerScripts > LocalScript
--  Всё строится кодом, ничего рисовать в Studio не нужно.
-- ============================================================

local CONFIG = {
	GameTitle   = "EvaK",                           -- название игры
	Subtitle    = "purgatory awaits",
	PlayTitle   = "PLAY",                      -- надпись на большой кнопке
	PlayTagline = "endless rooms, sins and redemption",
	Hint        = "choose your path",

	OfflineTestBadges = 0,                          -- бейджи в тестовом режиме (когда нет серверного скрипта)

	-- ВСТАВЬ СВОЙ ID музыки (rbxassetid://123456789). Пусто = без музыки.
	MusicId     = "rbxassetid://128075226050917",
	MusicVolume = 0.6,
	ClickSoundId = "rbxassetid://72046313",                              -- необязательно
	HoverSoundId = "rbxassetid://6895079853",                              -- необязательно

	-- Пиксельный шрифт. Arcade — самый близкий встроенный.
	Font        = Enum.Font.Arcade,

	Items = {   -- предметы на один забег (платятся бейджами)
		{ Id = "LANTERN", Name = "LANTERN",    Desc = "light in your hand",                 Cost = 10, Icon = "lantern" },
		{ Id = "FLASH",   Name = "FLASHLIGHT", Desc = "strong beam, battery. G. burns ceiling monsters", Cost = 40, Icon = "lantern" },
		{ Id = "BAR",     Name = "CANDY BAR",  Desc = "sweet and quick, eat it to run faster", Cost = 20, Icon = "bar" },
	},
	BarBoost = { Mult = 1.6, Seconds = 12, Key = Enum.KeyCode.Q },   -- батончик: ускорение, клавиша Q

	Products = {   -- Developer Products
		{ Id = 2081810443, Badges = 100, Robux = 59 },
		{ Id = 2082098430, Badges = 500, Robux = 249 },
		{ Id = 2093547126, Badges = 1000, Robux = 449 },   -- ProductId: впиши ID продукта "1000 бейджей"
	},
	SnowProducts = {   -- снежинки за робуксы (ProductId впиши свои)
		{ Id = 2093517085, Snow = 100, Robux = 59 },
		{ Id = 2094483033, Snow = 500, Robux = 249 },
		{ Id = 2094279092, Snow = 1000, Robux = 449 },
	},

	Difficulties = {   -- порядок = порядок открытия
		{ Id = "easy",   Name = "EASY",   Desc = "a gentle fall",          Color = Color3.fromRGB(120, 205, 120) },
		{ Id = "normal", Name = "NORMAL", Desc = "the rooms bite back",    Color = Color3.fromRGB(240, 205, 90) },
		{ Id = "hard",   Name = "HARD",   Desc = "no mercy",                 Color = Color3.fromRGB(240, 140, 50) },
		{ Id = "insane", Name = "INSANE", Desc = "only the damned return", Color = Color3.fromRGB(235, 70, 60) },
		{ Id = "newyear", Name = "NEW YEAR", Desc = "snow, tinsel and a very dark Santa", Color = Color3.fromRGB(120, 230, 255) },
		{ Id = "endless", Name = "ENDLESS", Desc = "doors never end - climb the leaderboard", Color = Color3.fromRGB(190, 90, 255) },
	},

	Rarities = {
		["Common"]     = Color3.fromRGB(196, 190, 178),
		["Rare"]       = Color3.fromRGB(92, 156, 255),
		["Super Rare"] = Color3.fromRGB(196, 104, 255),
		["Legendary"]  = Color3.fromRGB(255, 190, 60),
		["Mythic"]     = Color3.fromRGB(255, 70, 70),
		["Event"]      = Color3.fromRGB(120, 230, 255),
		["Limited"]    = Color3.fromRGB(255, 120, 200),
	},
	-- Speed/Badge = бонус (0.1 = +10%). Цены и бонусы должны совпадать с EvaKServer.
	Toys = {
		{ Id = "DUCK",   Name = "RUBBER DUCK",     Rarity = "Common",     Cost = 50,   Speed = 0.02, Badge = 0.00, Icon = "duck",   Color = Color3.fromRGB(255, 214, 70) , Robux = 19, ProductId = 2089390111 },
		{ Id = "TOP",    Name = "SPINNING TOP",    Rarity = "Common",     Cost = 80,   Speed = 0.00, Badge = 0.03, Icon = "top",    Color = Color3.fromRGB(220, 90, 70) , Robux = 29, ProductId = 2088628140 },
		{ Id = "ROBOT",  Name = "TIN ROBOT",       Rarity = "Rare",       Cost = 250,  Speed = 0.06, Badge = 0.00, Icon = "robot",  Color = Color3.fromRGB(150, 175, 205) , Robux = 79, ProductId = 2089510228 },
		{ Id = "BEAR",   Name = "OLD TEDDY",       Rarity = "Rare",       Cost = 300,  Speed = 0.00, Badge = 0.08, Icon = "bear",   Color = Color3.fromRGB(170, 110, 66) , Robux = 89, ProductId = 2089954220 },
		{ Id = "JACK",   Name = "JACK IN THE BOX", Rarity = "Super Rare", Cost = 900,  Speed = 0.12, Badge = 0.10, Icon = "box",    Color = Color3.fromRGB(170, 70, 210) , Robux = 259, ProductId = 2088610215 },
		{ Id = "MUSIC",  Name = "MUSIC BOX",       Rarity = "Super Rare", Cost = 1100, Speed = 0.10, Badge = 0.15, Icon = "music",    Color = Color3.fromRGB(70, 150, 215) , Robux = 279, ProductId = 2089420241 },
		{ Id = "DRAGON", Name = "GILDED DRAGON",   Rarity = "Legendary",  Cost = 3000, Speed = 0.25, Badge = 0.25, Icon = "dragon", Color = Color3.fromRGB(255, 196, 60) , Robux = 749, ProductId = 2089180150 },
		{ Id = "ROCKET", Name = "STAR ROCKET",     Rarity = "Legendary",  Cost = 5000, Speed = 0.30, Badge = 0.35, Icon = "rocket", Color = Color3.fromRGB(255, 255, 255) , Robux = 999, ProductId = 2087920254 },
		{ Id = "SANTA",  Name = "SANTA CLAUS",     Rarity = "Mythic",     Cost = 10000, Speed = 0.40, Badge = 0.50, Icon = "santa",  Color = Color3.fromRGB(220, 40, 40), Robux = 1499, ProductId = 2093775047 },   -- ProductId: впиши ID продукта Санты
		{ Id = "CARBONCAR", Name = "CARBON CAR", Rarity = "Mythic", Cost = 0, Speed = 0.22, Badge = 0.22, Icon = "car", Color = Color3.fromRGB(215, 22, 34), Vip = true },
		{ Id = "NEWYEAR", Name = "NEW YEAR TOY", Rarity = "Event", Cost = 0, Speed = 0.35, Badge = 0.40, Icon = "bauble", Color = Color3.fromRGB(225, 36, 48), Event = true, Robux = 799, ProductId = 2093055126 },   -- ProductId: впиши ID продукта
		{ Id = "SANTADRAGON", Name = "SANTA DRAGON", Rarity = "Event", Cost = 0, Speed = 0.30, Badge = 0.30, Icon = "sdragon", Color = Color3.fromRGB(255, 196, 60), Event = true, Robux = 1099, ProductId = 2094567071 },   -- ProductId: впиши ID продукта   -- ивент: пройти 100 дверей на NEW YEAR   -- ивент: 10 шаров на карте NEW YEAR
	},
}

-- ============================================================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
for _, n in { "IntroMenu", "IntroCursor", "EvaKHud" } do
	local old = playerGui:FindFirstChild(n)
	if old then old:Destroy() end
end
player:SetAttribute("IntroDone", false)
do   -- старые копии музыки / ошибок
	local oldMusic = game:GetService("SoundService"):FindFirstChild("MenuMusic")
	if oldMusic then oldMusic:Destroy() end
	local oldErr = playerGui:FindFirstChild("EvaKErr")
	if oldErr then oldErr:Destroy() end
end
-- уникальный id этой копии: если запустилась другая (респавн), старая копия выключается (нет двойного меню/музыки)
local myId = tostring(os.clock()) .. tostring(math.random(1, 1e9))
player:SetAttribute("IntroId", myId)
task.spawn(function()
	while script.Parent do
		if player:GetAttribute("IntroId") ~= myId then
			script:Destroy()
			return
		end
		task.wait(0.2)
	end
end)
-- если скрипт лежит в StarterPlayerScripts, то при ВОЗРОЖДЕНИИ запускаем свежую копию в персонаже
-- (первый спавн игнорируем: меню уже запущено этой копией)
if script.Parent and script.Parent:IsA("PlayerScripts") then
	local skipNext = (player.Character == nil)
	player.CharacterAdded:Connect(function(char)
		if skipNext then skipNext = false return end
		local c = script:Clone()
		c.Parent = char
	end)
end

-- палитра
local GOLD       = Color3.fromRGB(255, 214, 140)
local GOLD_DIM   = Color3.fromRGB(150, 112, 62)
local GOLD_TEXT  = Color3.fromRGB(246, 226, 182)
local BTN_BG     = Color3.fromRGB(20, 14, 10)
local BTN_BG_HOV = Color3.fromRGB(34, 24, 16)
local BG_DARK    = Color3.fromRGB(34, 19, 8)
local cursorHover = 0   -- >0 пока мышь над кнопкой (щупальце реагирует)

local function new(class: string, props: {[string]: any}, parent: Instance?): any
	local i = Instance.new(class)
	for k, v in props do (i :: any)[k] = v end
	i.Parent = parent
	return i
end

local function tw(o: Instance, t: number, props: {[string]: any}, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	local tween = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tween:Play()
	return tween
end


-- ============================================================
-- ДАННЫЕ / СЕРВЕР (бейджи, игрушки, покупки)
-- Состояние лежит в атрибутах игрока: Badges, OwnedToys, EquippedToy, RunItems, SpeedMult, BadgeMult
-- ============================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local shopRemote = (ReplicatedStorage:FindFirstChild("EvaKShop") or ReplicatedStorage:WaitForChild("EvaKShop", 8))
local lobbyEvent = shopRemote and (ReplicatedStorage:FindFirstChild("EvaKLobby") or ReplicatedStorage:WaitForChild("EvaKLobby", 8)) or nil
if not shopRemote then
	warn("[EvaK] EvaKServer не найден — меню работает в ТЕСТОВОМ режиме (без сохранения и покупок за робуксы)")
	player:SetAttribute("Badges", CONFIG.OfflineTestBadges)
	player:SetAttribute("OwnedToys", "")
	player:SetAttribute("EquippedToy", "")
	player:SetAttribute("RunItems", "")
	player:SetAttribute("Cleared", "")
end

local function getBadges(): number
	return player:GetAttribute("Badges") or 0
end
local function ownedToys(): {[string]: boolean}
	local t = {}
	for id in string.gmatch(player:GetAttribute("OwnedToys") or "", "[^,]+") do t[id] = true end
	return t
end
local function toyCount(id: string): number
	for k, n in string.gmatch(player:GetAttribute("ToyCounts") or "", "([^,:]+):(%d+)") do
		if k == id then return tonumber(n) or 0 end
	end
	return ownedToys()[id] and 1 or 0
end
local function teamList(): {string}
	local t = {}
	for id in string.gmatch(player:GetAttribute("EquippedToy") or "", "[^,]+") do table.insert(t, id) end
	return t
end
local function teamCount(id: string): number
	local n = 0
	for _, t in teamList() do if t == id then n += 1 end end
	return n
end
local function toyById(id: string)
	for _, t in CONFIG.Toys do
		if t.Id == id then return t end
	end
	return nil
end
local function offlinePerks()
	local sp, bd = 0, 0
	for _, id in teamList() do
		local toy = toyById(id)
		if toy then sp += toy.Speed; bd += toy.Badge end
	end
	player:SetAttribute("SpeedMult", 1 + sp)
	player:SetAttribute("BadgeMult", 1 + bd)
end

-- action: "BuyToy" | "EquipToy" | "StartRun" ; возвращает ok, сообщение
local function invoke(action: string, arg: any): (boolean, string, any?)
	if shopRemote then
		local ok, res = pcall(function() return shopRemote:InvokeServer(action, arg) end)
		if ok and type(res) == "table" then
			if res.ok ~= true then warn("[EvaK] " .. tostring(action) .. " -> " .. tostring(res.msg)) end
			return res.ok == true, tostring(res.msg or ""), res
		end
		warn("[EvaK] " .. tostring(action) .. " -> ошибка сервера: " .. tostring(res))
		return false, "server error"
	end
	-- тестовый режим без сервера
	if action == "BuyToy" then
		local toy = toyById(arg)
		if not toy then return false, "unknown" end
		if ownedToys()[arg] then return false, "owned" end
		if getBadges() < toy.Cost then return false, "not enough badges" end
		player:SetAttribute("Badges", getBadges() - toy.Cost)
		local owned = player:GetAttribute("OwnedToys") or ""
		player:SetAttribute("OwnedToys", owned == "" and arg or (owned .. "," .. arg))
		player:SetAttribute("EquippedToy", arg)
		offlinePerks()
		return true, ""
	elseif action == "EquipToy" then
		if not ownedToys()[arg] then return false, "not owned" end
		player:SetAttribute("EquippedToy", arg)
		offlinePerks()
		return true, ""
	elseif action == "Unequip" then
		player:SetAttribute("EquippedToy", "")
		offlinePerks()
		return true, ""
	elseif action == "Redeem" then
		local code = string.upper((string.gsub(tostring(arg), "%s", "")))
		if code ~= "KRONOS" then return false, "invalid" end
		if player:GetAttribute("PromoUsed") then return false, "used" end
		player:SetAttribute("PromoUsed", true)
		player:SetAttribute("Badges", getBadges() + 50)
		return true, "50"
	elseif action == "StartRun" then
		local total = 0
		for _, id in arg.Items do
			for _, it in CONFIG.Items do
				if it.Id == id then total += it.Cost end
			end
		end
		if getBadges() < total then return false, "not enough badges" end
		player:SetAttribute("Badges", getBadges() - total)
		player:SetAttribute("RunItems", table.concat(arg.Items, ","))
		player:SetAttribute("Difficulty", arg.Difficulty)
		return true, ""
	end
	if string.sub(action, 1, 5) == "Lobby" then return false, "no server" end
	return false, "unknown"
end

local function clearedSet(): {[string]: boolean}
	local t = {}
	for id in string.gmatch(player:GetAttribute("Cleared") or "", "[^,]+") do t[id] = true end
	return t
end
local function isUnlocked(idx: number): boolean
	if idx <= 1 or CONFIG.Difficulties[idx].Id == "newyear" or CONFIG.Difficulties[idx].Id == "endless" then return true end
	return clearedSet()[CONFIG.Difficulties[idx - 1].Id] == true
end

-- ============================================================
-- 3D ИГРУШКИ (детали + процедурная анимация)
-- makeToy(parent, toy, scale?) -> { model, render(pivotCFrame, t) }
-- ============================================================
local function makeToy(parent: Instance, toy, scale: number?)
	local sc = scale or 1
	local model = new("Model", { Name = toy.Id }, parent)
	local recs = {}
	local c = toy.Color
	local shade, light = c:Lerp(Color3.new(0, 0, 0), 0.35), c:Lerp(Color3.new(1, 1, 1), 0.45)
	local dark, white = Color3.fromRGB(30, 20, 16), Color3.fromRGB(250, 244, 232)
	local NEON, METAL = Enum.Material.Neon, Enum.Material.Metal

	local function sized(v: Vector3): Vector3
		return Vector3.new(math.max(0.05, v.X * sc), math.max(0.05, v.Y * sc), math.max(0.05, v.Z * sc))
	end
	local function add(shape: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?)
		local pt = new("Part", {
			Size = sized(size), Anchored = true, CanCollide = false, CanTouch = false, CanQuery = false, CastShadow = false,
			Color = color, Material = mat or Enum.Material.SmoothPlastic,
			TopSurface = Enum.SurfaceType.Smooth, BottomSurface = Enum.SurfaceType.Smooth,
		}, model)
		if shape == "ball" then new("SpecialMesh", { MeshType = Enum.MeshType.Sphere }, pt)
		elseif shape == "cyl" then pt.Shape = Enum.PartType.Cylinder end
		local r = { part = pt, cf = cf, size = size }
		table.insert(recs, r)
		return r
	end
	local function blk(sx, sy, sz, x, y, z, color, mat) return add("block", Vector3.new(sx, sy, sz), CFrame.new(x, y, z), color, mat) end
	local function bal(sx, sy, sz, x, y, z, color, mat) return add("ball", Vector3.new(sx, sy, sz), CFrame.new(x, y, z), color, mat) end
	local function cyl(h, d, x, y, z, color, mat)   -- вертикальный цилиндр
		return add("cyl", Vector3.new(h, d, d), CFrame.new(x, y, z) * CFrame.Angles(0, 0, math.pi / 2), color, mat)
	end

	local anim: ((number) -> CFrame)? = nil
	local kind = toy.Icon

	if kind == "duck" then
		local orange = Color3.fromRGB(240, 130, 40)
		bal(2.8, 2.2, 3.2, 0, 0, 0, c)
		bal(1.7, 1.7, 1.7, 0, 1.5, 1.0, c)
		blk(1.0, 0.35, 0.9, 0, 1.35, 1.95, orange)
		bal(0.3, 0.3, 0.3, -0.55, 1.85, 1.7, dark); bal(0.3, 0.3, 0.3, 0.55, 1.85, 1.7, dark)
		bal(1, 0.8, 1.2, 0, 0.6, -1.7, c)
		local wl = bal(0.5, 1.3, 1.8, -1.45, 0.1, -0.1, shade)
		local wr = bal(0.5, 1.3, 1.8, 1.45, 0.1, -0.1, shade)
		bal(0.46, 0.46, 0.22, -0.55, 1.85, 1.64, white); bal(0.46, 0.46, 0.22, 0.55, 1.85, 1.64, white)
		bal(0.13, 0.13, 0.13, -0.5, 1.93, 1.84, white); bal(0.13, 0.13, 0.13, 0.6, 1.93, 1.84, white)
		bal(0.5, 0.3, 0.2, -0.9, 1.4, 1.55, Color3.fromRGB(255, 150, 130)); bal(0.5, 0.3, 0.2, 0.9, 1.4, 1.55, Color3.fromRGB(255, 150, 130))
		blk(0.9, 0.14, 0.75, 0, 1.12, 1.95, Color3.fromRGB(205, 95, 30))
		bal(0.5, 0.6, 0.5, 0, 1.15, -1.9, light); bal(0.4, 0.5, 0.4, 0.25, 0.95, -2.1, c)
		bal(1.2, 0.3, 1.3, 0, 0.7, 1.35, light)
		bal(1.5, 0.4, 2.0, 0, 1.0, -0.2, light)
anim = function(t)
			wl.cf = CFrame.new(-1.45, 0.1, -0.1) * CFrame.Angles(0, 0, math.sin(t * 4) * 0.35)
			wr.cf = CFrame.new(1.45, 0.1, -0.1) * CFrame.Angles(0, 0, -math.sin(t * 4) * 0.35)
			return CFrame.Angles(math.sin(t * 2) * 0.05, 0, math.sin(t * 1.6) * 0.1)
		end

	elseif kind == "top" then
		bal(2.6, 2.2, 2.6, 0, 0.2, 0, c)
		cyl(0.35, 2.75, 0, 0.3, 0, light)
		cyl(0.5, 1.5, 0, 1.4, 0, shade)
		cyl(1.1, 0.35, 0, 2.1, 0, dark)
		cyl(0.9, 0.5, 0, -1.1, 0, Color3.fromRGB(170, 175, 185), METAL)
		bal(0.5, 0.5, 0.5, 0, -1.6, 0, Color3.fromRGB(170, 175, 185), METAL)
		for k, ry in { 0.85, 0.0, -0.55 } do
			cyl(0.16, 2.2 + (k == 2 and 0.5 or 0) - (k == 3 and 0.9 or 0), 0, ry, 0, (k == 2) and white or dark)
		end
		for k = 0, 7 do
			local a = k * math.pi / 4
			bal(0.28, 0.28, 0.28, math.cos(a) * 1.2, 0.35, math.sin(a) * 1.2, (k % 2 == 0) and white or Color3.fromRGB(255, 220, 90), NEON)
		end
		cyl(0.25, 1.0, 0, 2.8, 0, Color3.fromRGB(190, 195, 205), METAL)
		bal(0.7, 0.7, 0.7, 0, 3.0, 0, Color3.fromRGB(200, 60, 50))
anim = function(t)
			return CFrame.Angles(math.sin(t * 1.3) * 0.18, 0, math.cos(t * 1.3) * 0.18) * CFrame.Angles(0, t * 8, 0)
		end

	elseif kind == "robot" then
		local cyan = Color3.fromRGB(80, 230, 255)
		blk(1.8, 1.5, 1.6, 0, 2.1, 0, c, METAL)
		blk(0.45, 0.45, 0.12, -0.45, 2.2, 0.84, cyan, NEON); blk(0.45, 0.45, 0.12, 0.45, 2.2, 0.84, cyan, NEON)
		blk(1.0, 0.14, 0.1, 0, 1.72, 0.83, dark)
		cyl(0.7, 0.15, 0, 3.2, 0, dark)
		local ant = bal(0.5, 0.5, 0.5, 0, 3.7, 0, Color3.fromRGB(255, 80, 60), NEON)
		blk(2.2, 2.2, 1.5, 0, 0, 0, shade, METAL)
		local chest = blk(0.9, 0.9, 0.1, 0, 0.2, 0.78, Color3.fromRGB(255, 170, 50), NEON)
		local al, ar = blk(0.6, 1.8, 0.6, 0, 0, 0, c, METAL), blk(0.6, 1.8, 0.6, 0, 0, 0, c, METAL)
		local rivet = Color3.fromRGB(200, 205, 215)
		for _, rx in { -0.85, 0.85 } do for _, ry in { 0.95, -0.95, 2.75, 1.45 } do bal(0.16, 0.16, 0.16, rx, ry, 0.8, rivet, METAL) end end
		for k = -2, 2 do blk(0.7, 0.06, 0.06, 0, 1.62 + k * 0.0, 0.84, dark); end
		for k = 0, 3 do blk(0.9, 0.05, 0.08, 0, 1.58 - k * 0.1, 0.85, dark) end
		cyl(0.5, 0.5, -1.05, 2.1, 0, shade, METAL); cyl(0.5, 0.5, 1.05, 2.1, 0, shade, METAL)
		cyl(0.18, 1.4, 0, 0.1, -0.78, Color3.fromRGB(160, 165, 175), METAL)
		cyl(0.12, 0.8, 0, 0.1, -0.84, dark, METAL)
		blk(1.0, 0.06, 0.06, 0, -0.6, 0.78, dark); blk(0.06, 1.7, 0.06, -0.6, 0.15, 0.78, dark); blk(0.06, 1.7, 0.06, 0.6, 0.15, 0.78, dark)
		blk(1.0, 0.25, 1.3, -0.55, -2.8, 0.25, shade, METAL); blk(1.0, 0.25, 1.3, 0.55, -2.8, 0.25, shade, METAL)
		bal(0.5, 0.5, 0.5, -1.55, -0.1, 0, rivet, METAL); bal(0.5, 0.5, 0.5, 1.55, -0.1, 0, rivet, METAL)
blk(0.8, 1.6, 0.8, -0.55, -1.9, 0, c, METAL); blk(0.8, 1.6, 0.8, 0.55, -1.9, 0, c, METAL)
		anim = function(t)
			local sw = math.sin(t * 3) * 0.7
			al.cf = CFrame.new(-1.55, 0.9, 0) * CFrame.Angles(sw, 0, 0) * CFrame.new(0, -0.9, 0)
			ar.cf = CFrame.new(1.55, 0.9, 0) * CFrame.Angles(-sw, 0, 0) * CFrame.new(0, -0.9, 0)
			local k = (math.sin(t * 5) + 1) / 2
			chest.part.Color = Color3.fromRGB(255, 170, 50):Lerp(Color3.fromRGB(255, 240, 160), k)
			ant.part.Color = Color3.fromRGB(255, 80, 60):Lerp(Color3.fromRGB(255, 200, 160), 1 - k)
			return CFrame.Angles(0, math.sin(t * 1.5) * 0.15, 0)
		end

	elseif kind == "bear" then
		local tan, red = Color3.fromRGB(226, 186, 136), Color3.fromRGB(200, 50, 50)
		bal(2.6, 2.8, 2.2, 0, -0.6, 0, c); bal(1.6, 1.8, 0.4, 0, -0.5, 1.0, tan)
		bal(2.2, 2.0, 2.0, 0, 1.6, 0, c)
		bal(0.8, 0.8, 0.5, -0.95, 2.5, 0, c); bal(0.8, 0.8, 0.5, 0.95, 2.5, 0, c)
		bal(0.45, 0.45, 0.3, -0.95, 2.5, 0.2, tan); bal(0.45, 0.45, 0.3, 0.95, 2.5, 0.2, tan)
		bal(1.0, 0.8, 0.7, 0, 1.3, 0.95, tan); bal(0.35, 0.25, 0.25, 0, 1.5, 1.3, dark)
		bal(0.25, 0.25, 0.25, -0.5, 1.9, 0.95, dark); bal(0.25, 0.25, 0.25, 0.5, 1.9, 0.95, dark)
		blk(0.5, 0.5, 0.15, -0.35, 0.7, 1.05, red); blk(0.5, 0.5, 0.15, 0.35, 0.7, 1.05, red); bal(0.3, 0.3, 0.3, 0, 0.7, 1.1, shade)
		bal(1, 1, 1.2, -0.8, -2, 0.3, c); bal(1, 1, 1.2, 0.8, -2, 0.3, c)
		local aw, al = bal(0.8, 1.5, 0.8, 0, 0, 0, c), bal(0.8, 1.5, 0.8, 0, 0, 0, c)
		local stitch = Color3.fromRGB(60, 40, 30)
		bal(0.42, 0.42, 0.16, -0.5, 1.9, 0.92, white); bal(0.42, 0.42, 0.16, 0.5, 1.9, 0.92, white)
		bal(0.1, 0.1, 0.1, -0.45, 1.97, 1.07, white); bal(0.1, 0.1, 0.1, 0.55, 1.97, 1.07, white)
		bal(0.5, 0.5, 0.2, 0, 1.52, 1.34, Color3.fromRGB(70, 50, 44))
		blk(0.05, 0.3, 0.05, 0, 1.2, 1.28, stitch)
		blk(1.2, 1.2, 0.12, 0.3, -0.5, 1.12, Color3.fromRGB(180, 130, 90))
		for _, sx2 in { -0.5, 0.0, 0.5 } do blk(0.05, 0.05, 0.14, 0.3 + sx2 * 0.9, -0.5 + 0.55, 1.13, stitch); blk(0.05, 0.05, 0.14, 0.3 + sx2 * 0.9, -0.5 - 0.55, 1.13, stitch) end
		bal(0.9, 0.9, 0.6, -1.2, 2.55, 0.0, tan); bal(0.9, 0.9, 0.6, 1.2, 2.55, 0.0, tan)
		for k = 1, 6 do bal(0.5, 0.5, 0.5, -1.1 + (k % 3) * 1.1, -1.6 + math.floor(k / 3) * 1.2, -0.95, shade) end
anim = function(t)
			aw.cf = CFrame.new(1.45, 0.5, 0.1) * CFrame.Angles(0, 0, 2.0 + math.sin(t * 6) * 0.4) * CFrame.new(0, -0.7, 0)
			al.cf = CFrame.new(-1.45, 0.5, 0.1) * CFrame.Angles(0, 0, -0.25) * CFrame.new(0, -0.7, 0)
			return CFrame.Angles(0, 0, math.sin(t * 1.5) * 0.06)
		end

	elseif kind == "box" then   -- jack in the box
		blk(2.6, 2.0, 2.6, 0, -1.2, 0, c)
		blk(2.7, 0.3, 2.7, 0, -0.55, 0, white); blk(2.7, 0.3, 2.7, 0, -1.9, 0, white)
		local lid = blk(2.8, 0.3, 2.8, 0, 0, 0, shade)
		local gold = Color3.fromRGB(240, 196, 70)
		for _, cx in { -1.3, 1.3 } do for _, cz in { -1.3, 1.3 } do blk(0.25, 2.1, 0.25, cx, -1.2, cz, gold, METAL) end end
		for k = 0, 4 do for _, face in { 1, -1 } do bal(0.4, 0.4, 0.06, -1.0 + k * 0.5, -1.2 + ((k % 2 == 0) and 0.4 or -0.3), 1.33 * face, (k % 2 == 0) and white or gold) end end
		cyl(0.5, 0.7, 1.55, -1.2, 0, Color3.fromRGB(170, 175, 185), METAL)
		cyl(1.0, 0.18, 1.95, -1.2, 0.5, Color3.fromRGB(170, 175, 185), METAL)
		bal(0.4, 0.4, 0.4, 1.95, -0.65, 0.5, Color3.fromRGB(220, 60, 50))
		blk(2.0, 0.08, 0.08, 0, -0.55, 1.36, gold, METAL)
local coils = {}
		for i = 1, 5 do coils[i] = cyl(0.16, 0.9, 0, 0, 0, Color3.fromRGB(190, 190, 200), METAL) end
		local head = bal(1.8, 1.8, 1.8, 0, 0, 0, Color3.fromRGB(255, 224, 190))
		local eL, eR = bal(0.28, 0.28, 0.28, 0, 0, 0, dark), bal(0.28, 0.28, 0.28, 0, 0, 0, dark)
		local mouth = blk(0.8, 0.16, 0.1, 0, 0, 0, Color3.fromRGB(200, 50, 50))
		local hat, pom = blk(1.3, 0.8, 1.3, 0, 0, 0, c), bal(0.45, 0.45, 0.45, 0, 0, 0, white)
		anim = function(t)
			local pop = math.max(0, math.sin(t * 1.6)) ^ 0.7
			lid.cf = CFrame.new(0, -0.2, -1.4) * CFrame.Angles(-1.9 * math.min(1, pop * 4), 0, 0) * CFrame.new(0, 0.15, 1.4)
			local hy = -1.3 + pop * 2.6
			local top = hy - 0.9
			for i, co in coils do co.cf = CFrame.new(0, -0.5 + (i - 1) / 4 * (top + 0.5), 0) end
			head.cf = CFrame.new(0, hy, 0) * CFrame.Angles(math.sin(t * 3) * 0.1 * pop, 0, 0)
			eL.cf = CFrame.new(-0.4, hy + 0.2, 0.82); eR.cf = CFrame.new(0.4, hy + 0.2, 0.82)
			mouth.cf = CFrame.new(0, hy - 0.35, 0.86)
			hat.cf = CFrame.new(0, hy + 1.05, 0); pom.cf = CFrame.new(0, hy + 1.55, 0)
			local vis = pop < 0.08 and 1 or 0
			hat.part.Transparency, pom.part.Transparency = vis, vis
			return CFrame.new(0, 0.4, 0)
		end

	elseif kind == "music" then   -- музыкальная шкатулка
		blk(3.0, 1.7, 2.2, 0, -0.85, 0, c)
		blk(3.1, 0.25, 2.3, 0, -1.6, 0, shade); blk(3.1, 0.2, 2.3, 0, -0.1, 0, light)
		local lid = blk(3.1, 0.25, 2.3, 0, 0, 0, shade)
		local gold = Color3.fromRGB(235, 190, 70)
		for _, cx in { -1.5, 1.5 } do for _, cz in { -1.05, 1.05 } do blk(0.3, 1.7, 0.3, cx, -0.85, cz, gold, METAL); bal(0.5, 0.5, 0.5, cx, -1.85, cz, gold, METAL) end end
		blk(3.15, 0.1, 0.1, 0, -0.4, 1.12, gold, METAL); blk(3.15, 0.1, 0.1, 0, -1.3, 1.12, gold, METAL)
		blk(0.5, 0.7, 0.1, 0, -0.85, 1.12, gold, METAL); bal(0.18, 0.18, 0.12, 0, -0.9, 1.18, dark)
		blk(2.2, 0.9, 0.06, 0, -0.85, -1.12, Color3.fromRGB(150, 110, 70))
		cyl(0.4, 0.5, 1.9, -0.8, 0, gold, METAL); blk(0.9, 0.12, 0.12, 2.3, -0.8, 0, gold, METAL)
		blk(2.5, 0.06, 1.7, 0, -0.04, 0, Color3.fromRGB(120, 30, 50))
		local bd = add("cyl", Vector3.new(0.9, 0.35, 0.35), CFrame.new(), Color3.fromRGB(255, 140, 190))
local sk = add("cyl", Vector3.new(0.12, 1.0, 1.0), CFrame.new(), Color3.fromRGB(255, 200, 220))
		local bh = bal(0.4, 0.4, 0.4, 0, 0, 0, Color3.fromRGB(255, 224, 190))
		local arm = blk(1.0, 0.12, 0.12, 0, 0, 0, Color3.fromRGB(255, 224, 190))
		local notes = {}
		for i = 1, 3 do notes[i] = bal(0.3, 0.3, 0.3, 0, 0, 0, light, NEON) end
		anim = function(t)
			lid.cf = CFrame.new(0, -0.1, -1.1) * CFrame.Angles(-1.25 - 0.1 * math.sin(t * 1.2), 0, 0) * CFrame.new(0, 0.12, 1.1)
			local sp = CFrame.Angles(0, t * 3, 0)
			bd.cf = sp * CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.pi / 2)
			sk.cf = sp * CFrame.new(0, 0.2, 0) * CFrame.Angles(0, 0, math.pi / 2)
			bh.cf = sp * CFrame.new(0, 1.15, 0)
			arm.cf = sp * CFrame.new(0, 0.85, 0)
			for i, n in notes do
				local ph = (t * 0.6 + i / 3) % 1
				n.cf = CFrame.new(math.sin(t * 2 + i * 2) * 1.1, 0.6 + ph * 2.8, math.cos(t * 2 + i * 2) * 0.9)
				n.part.Transparency = ph ^ 2
			end
			return CFrame.new(0, 0.3, 0) * CFrame.Angles(0.12, 0, 0)
		end

	elseif kind == "car" then   -- чёрно-красная пиксельная машина CarBon
		local black, glass = Color3.fromRGB(14, 12, 12), Color3.fromRGB(255, 220, 220)
		blk(2.4, 0.9, 4.4, 0, -0.3, 0, black)
		blk(2.0, 0.8, 2.2, 0, 0.55, -0.2, black)
		blk(2.1, 0.15, 2.3, 0, 1.0, -0.2, c)
		blk(2.05, 0.45, 0.8, 0, 0.62, 0.45, glass); blk(2.05, 0.45, 0.8, 0, 0.62, -0.85, glass)
		blk(0.5, 0.05, 4.4, 0, 0.18, 0, c)
		blk(2.45, 0.18, 4.45, 0, -0.6, 0, c)
		for _, sx in { -1.3, 1.3 } do for _, sz in { -1.45, 1.45 } do blk(0.5, 0.95, 0.95, sx, -0.75, sz, Color3.fromRGB(6, 6, 6)); blk(0.52, 0.4, 0.4, sx, -0.75, sz, c) end end
		bal(0.4, 0.3, 0.2, -0.8, -0.2, 2.25, Color3.fromRGB(255, 240, 150), NEON); bal(0.4, 0.3, 0.2, 0.8, -0.2, 2.25, Color3.fromRGB(255, 240, 150), NEON)
		bal(0.4, 0.3, 0.2, -0.8, -0.2, -2.25, Color3.fromRGB(255, 30, 30), NEON); bal(0.4, 0.3, 0.2, 0.8, -0.2, -2.25, Color3.fromRGB(255, 30, 30), NEON)
		blk(0.12, 0.4, 0.9, 0, 1.2, -1.9, c)
		anim = function(t)
			return CFrame.Angles(math.sin(t * 2) * 0.03, t * 0.7, 0) * CFrame.new(0, 0.3, 0)
		end

	elseif kind == "dragon" or kind == "sdragon" then
		local orange, red = Color3.fromRGB(255, 140, 50), Color3.fromRGB(255, 60, 40)
		bal(2.4, 2.2, 4.0, 0, 0, 0, c); bal(1.6, 1.3, 3.2, 0, -0.4, 0.2, light)
		bal(1.1, 1.8, 1.2, 0, 1.2, 1.7, c)
		local head = bal(1.5, 1.2, 1.9, 0, 2.1, 2.4, c)
		bal(1.0, 0.7, 1.1, 0, 1.85, 3.3, c)
		blk(0.2, 0.8, 0.2, -0.5, 3.0, 2.0, dark); blk(0.2, 0.8, 0.2, 0.5, 3.0, 2.0, dark)
		bal(0.28, 0.28, 0.28, -0.5, 2.3, 3.0, red, NEON); bal(0.28, 0.28, 0.28, 0.5, 2.3, 3.0, red, NEON)
		local fire = bal(0.5, 0.5, 0.5, 0, 1.85, 3.9, Color3.fromRGB(255, 150, 40), NEON)
		for _, lx in { -0.85, 0.85 } do
			bal(0.8, 1.2, 0.9, lx, -1.3, 1.0, shade); bal(0.8, 1.2, 0.9, lx, -1.3, -1.0, shade)
		end
		for k = 0, 6 do
			local sp = add("block", Vector3.new(0.3, 0.9 - k * 0.07, 0.3), CFrame.new(0, 1.25 - k * 0.05, 1.3 - k * 0.55) * CFrame.Angles(0.4, 0, 0), dark)
		end
		for k = 0, 5 do for _, sx2 in { -0.5, 0.5, 0 } do bal(0.5, 0.35, 0.5, sx2, 1.0 - math.abs(sx2) * 0.3, 1.2 - k * 0.6, light) end end
		for k = 1, 5 do blk(1.3, 0.1, 0.08, 0, -0.55, 1.3 - k * 0.55, light) end
		for _, lx in { -0.85, 0.85 } do for _, lz in { 1.0, -1.0 } do for cx = -1, 1 do blk(0.16, 0.16, 0.5, lx + cx * 0.25, -1.95, lz + 0.35, white) end end end
		blk(0.9, 0.12, 0.2, -0.3, 2.0, 3.35, white); blk(0.9, 0.12, 0.2, 0.3, 2.0, 3.35, white)
		bal(0.12, 0.12, 0.12, -0.2, 2.15, 3.82, dark); bal(0.12, 0.12, 0.12, 0.2, 2.15, 3.82, dark)
		bal(0.3, 0.7, 0.3, -0.7, 3.0, 1.4, dark); bal(0.3, 0.7, 0.3, 0.7, 3.0, 1.4, dark)
		local wArmL, wMemL = blk(2.6, 0.3, 0.3, 0, 0, 0, shade), blk(2.4, 0.08, 1.9, 0, 0, 0, orange)
local wArmR, wMemR = blk(2.6, 0.3, 0.3, 0, 0, 0, shade), blk(2.4, 0.08, 1.9, 0, 0, 0, orange)
		if kind == "sdragon" then   -- шапка Санты, мех, гирлянда
			local hatRed, fur = Color3.fromRGB(205, 28, 34), Color3.fromRGB(250, 246, 240)
			bal(1.8, 0.45, 1.8, 0, 2.75, 2.35, fur)
			bal(1.45, 0.8, 1.45, 0, 3.15, 2.3, hatRed)
			bal(1.0, 0.8, 1.0, 0, 3.6, 2.0, hatRed)
			bal(0.65, 0.7, 0.65, 0, 4.0, 1.6, hatRed)
			bal(0.45, 0.45, 0.45, 0, 4.2, 1.25, fur)
			bal(1.25, 0.4, 1.25, 0, 1.55, 1.85, hatRed)   -- шарф
			for k = 0, 6 do bal(0.2, 0.2, 0.2, 0, 1.65 - k * 0.04, 1.0 - k * 0.55, (k % 2 == 0) and Color3.fromRGB(255, 70, 70) or Color3.fromRGB(110, 255, 140), NEON) end
		end
		local tail = {}
		for i = 1, 5 do tail[i] = bal(1.3 - 0.2 * i, 1.1 - 0.15 * i, 1.3 - 0.2 * i, 0, 0, 0, c) end
		anim = function(t)
			local flap = math.sin(t * 3.2)
			local function wing(sd: number, arm, mem)
				local base = CFrame.new(sd * 1.0, 1.0, -0.2) * CFrame.Angles(0, 0, sd * (0.25 + flap * 0.6))
				arm.cf = base * CFrame.new(sd * 1.3, 0, 0)
				mem.cf = base * CFrame.new(sd * 1.2, 0, 0.8)
			end
			wing(1, wArmR, wMemR); wing(-1, wArmL, wMemL)
			for i, seg in tail do
				seg.cf = CFrame.new(math.sin(t * 2 - i * 0.7) * 0.35 * i, -0.1 - i * 0.05, -2.0 - i * 0.95)
			end
			head.cf = CFrame.new(0, 2.1 + 0.08 * math.sin(t * 2), 2.4)
			fire.part.Transparency = 0.2 + 0.5 * math.abs(math.sin(t * 9))
			return CFrame.new(0, -0.6, -0.3)
		end

	elseif kind == "rocket" then
		local red, blue = Color3.fromRGB(230, 70, 60), Color3.fromRGB(90, 170, 255)
		cyl(3.6, 1.7, 0, 0, 0, c)
		cyl(0.4, 1.76, 0, 0.5, 0, red)
		bal(1.7, 2.1, 1.7, 0, 2.2, 0, red)
		add("cyl", Vector3.new(0.12, 1.15, 1.15), CFrame.new(0, 0.6, 0.82) * CFrame.Angles(0, math.pi / 2, 0), dark)
		add("cyl", Vector3.new(0.15, 0.9, 0.9), CFrame.new(0, 0.6, 0.88) * CFrame.Angles(0, math.pi / 2, 0), blue, NEON)
		for k = 0, 2 do
			add("block", Vector3.new(1.0, 1.7, 0.15), CFrame.Angles(0, k * 2 * math.pi / 3, 0) * CFrame.new(1.2, -1.3, 0) * CFrame.Angles(0, 0, -0.35), red)
		end
		cyl(0.5, 1.0, 0, -2.05, 0, dark, METAL)
		local rivet = Color3.fromRGB(215, 220, 230)
		add("cyl", Vector3.new(0.18, 1.35, 1.35), CFrame.new(0, 0.6, 0.78) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(230, 190, 80), METAL)
		for k = 0, 9 do local a = k * math.pi / 5; bal(0.12, 0.12, 0.12, math.cos(a) * 0.62, 0.6 + math.sin(a) * 0.62, 0.9, rivet, METAL) end
		for k = 0, 2 do cyl(0.22, 1.78, 0, -0.6 - k * 0.55, 0, (k % 2 == 0) and white or red) end
		for k = 0, 5 do local a = k * math.pi / 3; blk(0.08, 3.2, 0.08, math.cos(a) * 0.86, 0, math.sin(a) * 0.86, Color3.fromRGB(170, 175, 185), METAL) end
		for k = 0, 2 do bal(0.45, 0.45, 0.45, math.cos(k * 2.09 + 1.0) * 1.0, -1.9, math.sin(k * 2.09 + 1.0) * 1.0, Color3.fromRGB(240, 240, 250), METAL) end
		add("cyl", Vector3.new(0.14, 1.1, 1.1), CFrame.new(0, 1.7, 0.0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(255, 220, 90), NEON)
local f1 = bal(0.9, 1.8, 0.9, 0, -3.0, 0, Color3.fromRGB(255, 140, 40), NEON)
		local f2 = bal(0.5, 1.2, 0.5, 0, -2.8, 0, Color3.fromRGB(255, 235, 140), NEON)
		anim = function(t)
			local fl = 1 + 0.25 * math.sin(t * 28) + 0.15 * math.sin(t * 17)
			f1.part.Size = sized(Vector3.new(0.9, 1.8 * fl, 0.9)); f1.cf = CFrame.new(0, -2.5 - 0.9 * fl, 0)
			f2.part.Size = sized(Vector3.new(0.5, 1.2 * fl, 0.5)); f2.cf = CFrame.new(0, -2.5 - 0.6 * fl, 0)
			return CFrame.new(0, 0.9, 0) * CFrame.Angles(math.sin(t * 1.7) * 0.08, 0, math.cos(t * 1.3) * 0.08)
		end
	elseif kind == "bauble" then
		local gold = Color3.fromRGB(240, 200, 80)
		local ball = bal(3.0, 3.0, 3.0, 0, 0, 0, c)
		bal(3.12, 3.12, 3.12, 0, 0, 0, Color3.fromRGB(255, 150, 150)).part.Transparency = 0.75
		cyl(0.5, 1.4, 0, 1.6, 0, gold, METAL)
		cyl(0.25, 1.8, 0, 1.95, 0, gold, METAL)
		for k = 0, 9 do   -- кольцо-петля
			local a = k / 10 * math.pi * 2
			bal(0.28, 0.28, 0.28, math.cos(a) * 0.55, 2.8 + math.sin(a) * 0.55, 0, gold, METAL)
		end
		blk(3.02, 0.35, 0.2, 0, 0.3, 1.45, Color3.fromRGB(250, 244, 232))   -- полосы
		blk(3.02, 0.35, 0.2, 0, -0.4, 1.4, Color3.fromRGB(240, 200, 80))
		for k = 0, 5 do
			local a = k / 6 * math.pi * 2
			bal(0.32, 0.32, 0.2, math.cos(a) * 0.95, -0.05 + math.sin(a) * 0.95, 1.38, Color3.fromRGB(255, 255, 255), NEON)
		end
		bal(0.9, 0.9, 0.3, -0.7, 0.75, 1.3, Color3.fromRGB(255, 220, 220)).part.Transparency = 0.45
		anim = function(t)
			return CFrame.new(0, 0.12 * math.sin(t * 2.2), 0) * CFrame.Angles(0, math.sin(t * 0.8) * 0.35, math.sin(t * 1.5) * 0.08)
		end
	elseif kind == "santa" then
		local skin, black, gold = Color3.fromRGB(245, 200, 170), Color3.fromRGB(26, 20, 18), Color3.fromRGB(240, 200, 80)
		local fur = Color3.fromRGB(250, 246, 240)
		for _, lx in { -0.6, 0.6 } do
			bal(0.95, 1.3, 0.95, lx, -1.45, 0, c)
			blk(0.95, 0.75, 1.3, lx, -2.15, 0.15, black)
		end
		bal(2.6, 2.8, 2.4, 0, 0, 0, c)
		blk(0.5, 2.3, 0.12, 0, 0, 1.12, fur)
		bal(2.75, 0.55, 2.55, 0, -1.2, 0, fur)
		blk(2.7, 0.42, 2.5, 0, -0.35, 0, black)
		blk(0.7, 0.55, 0.12, 0, -0.35, 1.27, gold, METAL)
		local armL, armR = bal(0.85, 1.7, 0.85, 0, 0, 0, c), bal(0.85, 1.7, 0.85, 0, 0, 0, c)
		local handL, handR = bal(0.62, 0.62, 0.62, 0, 0, 0, black), bal(0.62, 0.62, 0.62, 0, 0, 0, black)
		bal(1.75, 1.65, 1.65, 0, 1.95, 0.1, skin)
		bal(0.5, 0.3, 0.2, -0.65, 1.8, 0.88, Color3.fromRGB(255, 160, 140)); bal(0.5, 0.3, 0.2, 0.65, 1.8, 0.88, Color3.fromRGB(255, 160, 140))
		bal(0.36, 0.36, 0.36, 0, 1.88, 0.95, Color3.fromRGB(240, 140, 120))
		bal(0.22, 0.26, 0.12, -0.36, 2.15, 0.86, dark); bal(0.22, 0.26, 0.12, 0.36, 2.15, 0.86, dark)
		bal(2.0, 1.3, 1.2, 0, 1.4, 0.55, fur); bal(1.3, 0.95, 1.0, 0, 0.8, 0.7, fur)
		bal(1.4, 0.42, 0.55, 0, 1.78, 0.92, fur)
		bal(1.85, 1.2, 1.85, 0, 2.9, 0.0, c)
		bal(1.35, 1.0, 1.35, -0.3, 3.6, -0.25, c)
		bal(0.85, 0.85, 0.85, -0.75, 4.0, -0.55, c)
		bal(0.55, 0.55, 0.55, -1.05, 4.05, -0.75, fur)
		bal(2.0, 0.48, 2.0, 0, 2.4, 0.05, fur)
		local sack = bal(2.3, 2.5, 1.9, 0, 0.1, -1.95, Color3.fromRGB(140, 96, 56), Enum.Material.Fabric)
		bal(0.9, 0.45, 0.9, 0, 1.4, -1.95, Color3.fromRGB(110, 70, 40), Enum.Material.Fabric)
		blk(0.7, 0.7, 0.7, 0.9, 1.8, -1.9, Color3.fromRGB(70, 150, 230)); blk(0.7, 0.12, 0.12, 0.9, 2.16, -1.9, gold)
		anim = function(t)
			local sw = math.sin(t * 3) * 0.35
			armL.cf = CFrame.new(-1.55, 0.25, 0.2) * CFrame.Angles(sw, 0, 0.15)
			armR.cf = CFrame.new(1.55, 0.25, 0.2) * CFrame.Angles(-sw, 0, -0.15)
			handL.cf = CFrame.new(-1.62, -0.7, 0.3 + sw * 0.5); handR.cf = CFrame.new(1.62, -0.7, 0.3 - sw * 0.5)
			return CFrame.new(0, 0.12 * math.sin(t * 2.4), 0) * CFrame.Angles(0, math.sin(t * 0.9) * 0.12, 0)
		end
	end

	for _, r in recs do
		local pt = r.part
		if pt.Material == METAL then pt.Reflectance = 0.25
		elseif pt.Material == Enum.Material.SmoothPlastic then
			if kind == "bear" then pt.Material = Enum.Material.Fabric else pt.Reflectance = 0.07 end
		end
	end

	-- ===== улучшенная графика питомцев: блики, аура, искры, мягкое покачивание =====
	local sparkFn: ((number) -> ())? = nil
	do
		local snap = table.clone(recs)
		local maxR = 1
		for _, r in snap do
			maxR = math.max(maxR, r.cf.Position.Magnitude + math.max(r.size.X, r.size.Y, r.size.Z) * 0.5)
			local pt = r.part
			if r.size.Y > 0.9 and pt:FindFirstChildOfClass("SpecialMesh") and pt.Material ~= NEON and pt.Transparency == 0 then
				add("ball", Vector3.new(r.size.X * 0.22, r.size.Y * 0.16, r.size.Z * 0.1),
					r.cf * CFrame.new(-r.size.X * 0.2, r.size.Y * 0.28, r.size.Z * 0.4), Color3.new(1, 1, 1), NEON).part.Transparency = 0.45
			end
			if pt.Material == Enum.Material.SmoothPlastic and pt.Reflectance < 0.1 then pt.Reflectance = 0.1 end
		end
		if sc >= 0.5 then
			local aura = add("ball", Vector3.new(maxR * 2.5, maxR * 2.5, maxR * 2.5), CFrame.new(0, 0.5, 0), light, NEON)
			aura.part.Transparency = 0.93
			local aura2 = add("ball", Vector3.new(maxR * 1.9, maxR * 1.9, maxR * 1.9), CFrame.new(0, 0.5, 0), light, NEON)
			aura2.part.Transparency = 0.9
			local sparks = {}
			for i = 1, 8 do
				local sp = add("ball", Vector3.new(0.16, 0.16, 0.16), CFrame.new(), (i % 2 == 0) and Color3.fromRGB(255, 232, 150) or white, NEON)
				sparks[i] = sp
			end
			sparkFn = function(t: number)
				aura.part.Transparency = 0.92 + math.sin(t * 2) * 0.03
				for i, sp in sparks do
					local a = t * (0.8 + i * 0.07) + i * 0.785
					local rad = maxR * (1.15 + 0.15 * math.sin(t * 1.3 + i))
					sp.cf = CFrame.new(math.cos(a) * rad, 0.5 + math.sin(a * 1.3 + i) * maxR * 0.7, math.sin(a) * rad)
					sp.part.Transparency = 0.15 + 0.5 * (0.5 + 0.5 * math.sin(t * 5 + i * 2))
				end
			end
		end
	end

	local function render(pivot: CFrame, t: number)
	if sparkFn then sparkFn(t) end
	local extra = anim and anim(t) or CFrame.new(0, math.sin(t * 2) * 0.1, 0) * CFrame.Angles(0, math.sin(t * 0.8) * 0.08, 0)
		local base = pivot * CFrame.Angles(0, math.pi, 0) * extra
		for _, r in recs do
			local cf = r.cf
			r.part.CFrame = base * (CFrame.new(cf.Position * sc) * cf.Rotation)
		end
	end
	render(CFrame.new(), 0)
	return { model = model, render = render }
end

-- 3D-витрина игрушки в карточке (ViewportFrame + свечение редкости)
local toyWidgets = {}
local function toyView(parent: Instance, toy, cx: number, cy: number, w: number, h: number, isShown: () -> boolean, hoverSrc: GuiObject?)
	local rc = CONFIG.Rarities[toy.Rarity] or GOLD
	local glow = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, cy), Size = UDim2.fromOffset(h * 1.1, h * 1.1),
		BackgroundColor3 = rc, BackgroundTransparency = 0.9, BorderSizePixel = 0, ZIndex = 8,
	}, parent)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, glow)
	local vf = new("ViewportFrame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, cy), Size = UDim2.fromOffset(w, h),
		BackgroundTransparency = 1, Ambient = Color3.fromRGB(120, 100, 85), LightColor = Color3.fromRGB(255, 232, 195),
		LightDirection = Vector3.new(0.35, -0.6, 0.8), ZIndex = 9,
	}, parent)
	local cam = new("Camera", { FieldOfView = 30 }, vf)
	vf.CurrentCamera = cam
	local widget = {
		vf = vf, cam = cam, glow = glow, obj = makeToy(vf, toy), isShown = isShown, hover = false, pop = -10, spin = 0,
		seed = math.random() * 6.28, rare = (toy.Rarity == "Legendary" and 3) or (toy.Rarity == "Super Rare" and 2) or 1,
	}
	if hoverSrc then
		hoverSrc.MouseEnter:Connect(function() widget.hover = true end)
		hoverSrc.MouseLeave:Connect(function() widget.hover = false end)
	end
	table.insert(toyWidgets, widget)
	return widget
end

local toyConn = RunService.RenderStepped:Connect(function(dt)
	local t = os.clock()
	for _, wd in toyWidgets do
		if wd.isShown() then
			wd.spin += dt * (wd.hover and 2.6 or 1)
			local pop = math.max(0, 1 - (t - wd.pop) / 0.7)
			local yaw = math.sin(wd.spin * 0.7 + wd.seed) * 0.7 + pop * pop * 6.28
			local bob = math.sin(t * 1.7 + wd.seed) * 0.2
			wd.obj.render(CFrame.new(0, bob, 0) * CFrame.Angles(0, yaw, 0), t)
			local dist = 12.5 - 3.0 * pop - (wd.hover and 0.8 or 0)
			wd.cam.CFrame = CFrame.lookAt(Vector3.new(0, 0.9, -dist), Vector3.new(0, 0.4, 0))
			local base = (wd.rare == 3 and 0.80) or (wd.rare == 2 and 0.86) or 0.92
			wd.glow.BackgroundTransparency = math.clamp(base + math.sin(t * 2 + wd.seed) * 0.04 - pop * 0.3, 0, 1)
		end
	end
end)

-- ============================================================
-- GUI root
-- ============================================================
local gui = new("ScreenGui", {
	Name = "IntroMenu", IgnoreGuiInset = true, ResetOnSpawn = false,
	DisplayOrder = 100, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

-- отключаем управление пока открыто меню
local function setControls(on: boolean)
	pcall(function()
		local pm = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 5))
		local c = pm:GetControls()
		if on then c:Enable() else c:Disable() end
	end)
end
setControls(false)

-- ---------- звук ----------
local music: Sound? = nil
local LT = { jingle = true }   -- одна переменная вместо трёх (лимит локальных)
if true then
	music = new("Sound", { Name = "MenuMusic", SoundId = CONFIG.MusicId, Looped = true, Volume = 0 }, SoundService)
	music:Play()
	tw(music, 3, { Volume = CONFIG.MusicVolume })
end
function LT.id(): string
	local j = workspace:GetAttribute("NYSndMusic")
	if LT.jingle and player:GetAttribute("EvaKTheme") ~= "classic" and type(j) == "string" and j ~= "" then return j end
	return CONFIG.MusicId
end
function LT.set(on: boolean)
	LT.jingle = on
	local id = LT.id()
	if music and id ~= "" and music.SoundId ~= id then
		music.SoundId = id
		music:Play()
	end
end
task.spawn(function()   -- Jingle Bells подключается, как только сервер выставит атрибут
	for _ = 1, 40 do
		if type(workspace:GetAttribute("NYSndMusic")) == "string" then break end
		task.wait(0.25)
	end
	if music then LT.set(LT.jingle) end
end)
local function sfx(id: string)
	if id == "" then return end
	local s = new("Sound", { SoundId = id, Volume = 0.5 }, SoundService)
	s:Play()
	s.Ended:Once(function() s:Destroy() end)
end

-- ============================================================
-- ФОН
-- ============================================================
local bg = new("Frame", { Name = "Background", Size = UDim2.fromScale(1, 1), BackgroundColor3 = BG_DARK, BorderSizePixel = 0 }, gui)
new("UIGradient", {
	Rotation = 90,
	Color = ColorSequence.new(Color3.fromRGB(52, 30, 12), Color3.fromRGB(24, 13, 6)),
}, bg)

-- центр свечения (в долях экрана)
local glowHolder = new("Frame", {
	Size = UDim2.fromOffset(0, 0), Position = UDim2.fromScale(0.72, 0.46), BackgroundTransparency = 1,
}, bg)

-- концентрические круги = радиальное свечение
local glowCircles = {}
for i = 1, 30 do
	local d = 1100 - (i - 1) * 34
	local c = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(d, d),
		BackgroundColor3 = Color3.fromRGB(255, 190 - i * 2, 80), BackgroundTransparency = 0.982,
		BorderSizePixel = 0,
	}, glowHolder)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, c)
	table.insert(glowCircles, c)
end

-- лучи
local rays = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(1800, 1800), BackgroundTransparency = 1,
}, glowHolder)
local RAY_COUNT = 16
for i = 1, RAY_COUNT do
	local w = (i % 2 == 0) and 46 or 26
	local r = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(w, 1800), Rotation = (180 / RAY_COUNT) * i,
		BackgroundColor3 = Color3.fromRGB(255, 190, 90), BorderSizePixel = 0, BackgroundTransparency = 0,
	}, rays)
	new("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.35, 0.975),
			NumberSequenceKeypoint.new(0.5, 0.88),
			NumberSequenceKeypoint.new(0.65, 0.975),
			NumberSequenceKeypoint.new(1, 1),
		}),
	}, r)
end

-- 3D-силуэт персонажа (ViewportFrame + процедурная анимация)
local vp = new("ViewportFrame", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.72, 0.6), Size = UDim2.fromOffset(1100, 760),
	BackgroundTransparency = 1, Ambient = Color3.fromRGB(70, 42, 20), LightColor = Color3.fromRGB(255, 196, 120),
	LightDirection = Vector3.new(-0.9, -0.15, -0.5), ZIndex = 1,
}, bg)
local vpCam = new("Camera", { FieldOfView = 32 }, vp)
vpCam.CFrame = CFrame.lookAt(Vector3.new(0, 0.3, -22), Vector3.new(0, 0.2, 0))
vp.CurrentCamera = vpCam
local figure = new("Model", { Name = "Silhouette" }, vp)

local BODY = Color3.fromRGB(26, 17, 11)
local function mkPart(size: Vector3, head: boolean?)
	local p = new("Part", {
		Size = size, Anchored = true, CanCollide = false, CanTouch = false, CanQuery = false,
		Color = BODY, Material = Enum.Material.SmoothPlastic, TopSurface = Enum.SurfaceType.Smooth,
		BottomSurface = Enum.SurfaceType.Smooth,
	}, figure)
	if head then new("SpecialMesh", { MeshType = Enum.MeshType.Head, Scale = Vector3.new(1.25, 1.25, 1.25) }, p) end
	return p
end
local pHead  = mkPart(Vector3.new(2, 1, 1), true)
local pTorso = mkPart(Vector3.new(2, 2, 1))
local pArmR, pArmL = mkPart(Vector3.new(1, 2, 1)), mkPart(Vector3.new(1, 2, 1))
local pLegR, pLegL = mkPart(Vector3.new(1, 2, 1)), mkPart(Vector3.new(1, 2, 1))

local fallU: number? = nil   -- nil = обычная idle-анимация, 0..1 = прогресс падения
local dropY = 0                -- смещение по высоте (раздевалка SKINS: падает сверху / взлетает)
local skinUpdate: () -> () = function() end
local raySpeed = 3

local function animateFigureCore(t: number)
	if fallU then
		-- ПАДЕНИЕ: кувыркается и улетает вглубь, руки-ноги болтаются
		local u: number = fallU
		local root = CFrame.new(0, 0.3 - u * 1.5, u * 16) * CFrame.Angles(u * 3.4, u * 2.1 + 0.5, u * 4.3)
		pTorso.CFrame = root
		pHead.CFrame = root * CFrame.new(0, 1, 0) * CFrame.Angles(math.sin(t * 7) * 0.3, 0, math.sin(t * 5) * 0.2) * CFrame.new(0, 0.5, 0)
		for _, side in { 1, -1 } do
			local spread = 1.15 + 0.4 * math.sin(t * 8 + side)
			local arm = root * CFrame.new(side * 1, 1, 0) * CFrame.Angles(math.sin(t * 6 + side) * 0.5, 0, side * spread) * CFrame.new(side * 0.5, -1, 0)
			local leg = root * CFrame.new(side * 0.5, -1, 0) * CFrame.Angles(math.sin(t * 7 + side * 2) * 0.6, 0, side * 0.25) * CFrame.new(0, -1, 0)
			if side == 1 then pArmR.CFrame, pLegR.CFrame = arm, leg else pArmL.CFrame, pLegL.CFrame = arm, leg end
		end
		return
	end
	-- плавный подъём рук при появлении
	local rise = TweenService:GetValue(math.clamp(t / 3.5, 0, 1), Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local breathe = math.sin(t * 1.1)
	local hover = breathe * 0.18 + 0.2
	local root = CFrame.new(0, hover + dropY, 0) * CFrame.Angles(math.sin(t * 0.6) * 0.03, math.sin(t * 0.45) * 0.14 + math.pi, 0)
	-- (math.pi: персонаж лицом к камере)

	pTorso.CFrame = root
	local neck = CFrame.Angles(-0.05 + math.sin(t * 0.9) * 0.04, math.sin(t * 0.7) * 0.22, math.sin(t * 0.5) * 0.04)
	pHead.CFrame = root * CFrame.new(0, 1, 0) * neck * CFrame.new(0, 0.5, 0)

	for _, side in { 1, -1 } do
		local spread = rise * (0.95 + 0.14 * math.sin(t * 1.1 + side * 0.8)) + 0.08
		local swing = math.sin(t * 0.8 + side) * 0.12
		local shoulder = root * CFrame.new(side * 1, 1, 0) * CFrame.Angles(swing, 0, side * spread)
		local arm = shoulder * CFrame.new(side * 0.5, -1, 0)
		local hip = root * CFrame.new(side * 0.5, -1, 0) * CFrame.Angles(math.sin(t * 1.1 + side * 1.3) * 0.07, 0, side * 0.05)
		local leg = hip * CFrame.new(0, -1, 0)
		if side == 1 then pArmR.CFrame, pLegR.CFrame = arm, leg else pArmL.CFrame, pLegL.CFrame = arm, leg end
	end
end
local function animateFigure(t: number)
	animateFigureCore(t)
	skinUpdate()
end
animateFigure(0)

local menuToys: {any} = {}
local menuToyBorn = 0
local MENU_SLOTS = { Vector3.new(-3.7, 1.2, 0), Vector3.new(-5.6, 3.3, 1), Vector3.new(-5.6, -1.2, 1) }
local function setMenuToy(_: string)
	for _, m in menuToys do m.obj.model:Destroy() end
	table.clear(menuToys)
	for i, id in teamList() do
		local toy = toyById(id)
		if toy and i <= 3 then table.insert(menuToys, { obj = makeToy(vp, toy), slot = i }) end
	end
	menuToyBorn = os.clock()
end
local function updateMenuToy(t: number)
	local age = math.clamp((os.clock() - menuToyBorn) / 0.9, 0, 1)
	local ease = TweenService:GetValue(age, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local u: number = fallU or 0
	for i, m in menuToys do
		local sl = MENU_SLOTS[m.slot]
		local pos = Vector3.new(sl.X, sl.Y + math.sin(t * 1.5 + i * 1.7) * 0.35 - (1 - ease) * 4 - u * 3, sl.Z + u * 18)
		m.obj.render(CFrame.new(pos) * CFrame.Angles(0, t * (0.8 + u * 6) + i, 0), t)
	end
end
player:GetAttributeChangedSignal("EquippedToy"):Connect(function() setMenuToy(player:GetAttribute("EquippedToy") or "") end)
setMenuToy("")

-- пыль / боке
local dustFolder = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, bg)
local rng = Random.new()
local function spawnDust(big: boolean)
	local s = big and rng:NextInteger(16, 34) or rng:NextInteger(2, 6)
	local p = new("Frame", {
		Size = UDim2.fromOffset(s, s), BorderSizePixel = 0,
		BackgroundColor3 = big and Color3.fromRGB(255, 190, 100) or Color3.fromRGB(255, 232, 190),
		BackgroundTransparency = 1,
	}, dustFolder)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, p)
	task.spawn(function()
		while p.Parent do
			local x, y = rng:NextNumber(), rng:NextNumber(0.2, 1.1)
			p.Position = UDim2.fromScale(x, y)
			local dur = rng:NextNumber(7, 16)
			local base = big and rng:NextNumber(0.9, 0.95) or rng:NextNumber(0.25, 0.7)
			p.BackgroundTransparency = 1
			tw(p, 1.5, { BackgroundTransparency = base })
			tw(p, dur, { Position = UDim2.fromScale(x + rng:NextNumber(-0.06, 0.06), y - rng:NextNumber(0.2, 0.5)) }, Enum.EasingStyle.Linear)
			task.wait(dur - 1.5)
			tw(p, 1.5, { BackgroundTransparency = 1 })
			task.wait(1.5)
		end
	end)
end
for _ = 1, 38 do spawnDust(false) end
for _ = 1, 14 do spawnDust(true) end

-- виньетка
local function vignette(pos: UDim2, size: UDim2, anchor: Vector2, rot: number)
	local f = new("Frame", { Position = pos, Size = size, AnchorPoint = anchor, BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 2 }, bg)
	new("UIGradient", { Rotation = rot, Transparency = NumberSequence.new(0.25, 1) }, f)
end
vignette(UDim2.fromScale(0, 0), UDim2.new(1, 0, 0, 260), Vector2.new(0, 0), 90)
vignette(UDim2.fromScale(0, 1), UDim2.new(1, 0, 0, 260), Vector2.new(0, 1), -90)
vignette(UDim2.fromScale(0, 0), UDim2.new(0, 360, 1, 0), Vector2.new(0, 0), 0)
vignette(UDim2.fromScale(1, 0), UDim2.new(0, 360, 1, 0), Vector2.new(1, 0), 180)

-- затемнение фона (используется в сцене падения)
local dim = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 3 }, bg)

-- анимация фона
local t0 = os.clock()
local bgConn = RunService.RenderStepped:Connect(function(dt)
	local t = os.clock() - t0
	rays.Rotation = (rays.Rotation + dt * raySpeed) % 360
	for i, c in glowCircles do
		local pulse = 1 + math.sin(t * 0.9 + i * 0.3) * 0.02
		local d = (1100 - (i - 1) * 34) * pulse
		c.Size = UDim2.fromOffset(d, d)
	end
	animateFigure(t)
	updateMenuToy(t)
end)

-- ============================================================
-- STAGE 1280x720 (масштабируется под экран)
-- ============================================================
local stage = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(1280, 720), BackgroundTransparency = 1, ZIndex = 5,
}, gui)
local scale = new("UIScale", {}, stage)
local function rescale()
	local v = gui.AbsoluteSize
	scale.Scale = math.min(v.X / 1280, v.Y / 720)
end
rescale()
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(rescale)

local function text(parent: Instance, str: string, size: number, color: Color3, x: number, y: number, props: {[string]: any}?)
	local l = new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(600, size + 6),
		BackgroundTransparency = 1, Text = str, TextSize = size, TextColor3 = color, Font = CONFIG.Font,
		TextWrapped = false,
	}, parent)
	if props then for k, v in props do l[k] = v end end
	return l
end

-- пиксельная 4-конечная звезда (в Arcade-шрифте нет символа ✦)
local function star(parent: Instance, cx: number, cy: number, s: number, z: number?)
	local h = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, cy), Size = UDim2.fromOffset(s, s), BackgroundTransparency = 1, ZIndex = z or 9 }, parent)
	local th = math.max(2, math.floor(s * 0.26))
	for _, sz in { Vector2.new(th, s), Vector2.new(s, th) } do
		new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(sz.X, sz.Y), BackgroundColor3 = GOLD, BorderSizePixel = 0, ZIndex = z or 9 }, h)
	end
	new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(s * 0.55, s * 0.55), Rotation = 45, BackgroundColor3 = GOLD, BorderSizePixel = 0, ZIndex = z or 9 }, h)
	return h
end

-- линия с ромбом
local function divider(parent: Instance, cx: number, y: number, width: number, gap: number)
	local half = width / 2
	local function seg(x: number, w: number)
		new("Frame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, 2), BackgroundColor3 = GOLD_DIM, BorderSizePixel = 0 }, parent)
	end
	seg(cx - half, half - gap)
	seg(cx + gap, half - gap)
	new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, y + 1), Size = UDim2.fromOffset(10, 10),
		Rotation = 45, BackgroundColor3 = GOLD, BorderSizePixel = 0,
	}, parent)
end

-- уголки на кнопке
local function brackets(btn: GuiObject): {Frame}
	local list = {}
	local L, T = 9, 2
	local function mk(ax: number, ay: number)
		local ox, oy = (ax == 0) and -3 or 3, (ay == 0) and -3 or 3
		local h = new("Frame", {
			AnchorPoint = Vector2.new(ax, ay), Position = UDim2.new(ax, ox, ay, oy), Size = UDim2.fromOffset(L, T),
			BackgroundColor3 = GOLD, BorderSizePixel = 0, ZIndex = 8,
		}, btn)
		local v = new("Frame", {
			AnchorPoint = Vector2.new(ax, ay), Position = UDim2.new(ax, ox, ay, oy), Size = UDim2.fromOffset(T, L),
			BackgroundColor3 = GOLD, BorderSizePixel = 0, ZIndex = 8,
		}, btn)
		table.insert(list, h); table.insert(list, v)
	end
	mk(0, 0); mk(1, 0); mk(0, 1); mk(1, 1)
	return list
end

local function setBrackets(list: {Frame}, color: Color3)
	for _, f in list do tw(f, 0.15, { BackgroundColor3 = color }) end
end

-- универсальная кнопка (x,y,w,h = левый верхний угол в координатах 1280x720)
local function makeButton(parent: Instance, x: number, y: number, w: number, h: number, selected: boolean?)
	local b = new("TextButton", {
		Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), Text = "", AutoButtonColor = false,
		BackgroundColor3 = BTN_BG, BackgroundTransparency = 0.12, BorderSizePixel = 0, ZIndex = 6,
	}, parent)
	local stroke = new("UIStroke", { Color = selected and GOLD or GOLD_DIM, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, b)
	local br = brackets(b)
	local active = selected == true
	local function paint(hover: boolean)
		local on = hover or active
		tw(b, 0.15, { BackgroundColor3 = on and BTN_BG_HOV or BTN_BG })
		tw(stroke, 0.15, { Color = on and GOLD or GOLD_DIM })
		setBrackets(br, on and GOLD or GOLD_DIM)
	end
	paint(false)
	b.MouseEnter:Connect(function() sfx(CONFIG.HoverSoundId); cursorHover += 1; paint(true) end)
	b.MouseLeave:Connect(function() cursorHover = math.max(0, cursorHover - 1); paint(false) end)
	return b, function(v: boolean) active = v; paint(false) end
end

-- ============================================================
-- Валюта (всегда сверху справа)
-- ============================================================
local openShop: (string) -> () = function() end   -- назначается ниже, в разделе МАГАЗИН
local coinLabel = new("TextLabel", {
	AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromOffset(1222, 40), Size = UDim2.fromOffset(160, 26),
	BackgroundTransparency = 1, Text = tostring(getBadges()), TextSize = 22, TextColor3 = GOLD_TEXT, Font = CONFIG.Font,
	TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 10,
}, stage)
star(stage, 1238, 40, 18, 10)

-- плюсик рядом с бейджами -> магазин (вкладка BADGES)
local plusBtn = new("TextButton", {
	Size = UDim2.fromOffset(24, 24), Text = "", AutoButtonColor = false, BackgroundColor3 = BTN_BG,
	BackgroundTransparency = 0.1, BorderSizePixel = 0, ZIndex = 10,
}, stage)
local plusStroke = new("UIStroke", { Color = GOLD, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, plusBtn)
for _, sz in { Vector2.new(12, 3), Vector2.new(3, 12) } do
	new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(sz.X, sz.Y), BackgroundColor3 = GOLD, BorderSizePixel = 0, ZIndex = 11 }, plusBtn)
end
plusBtn.MouseEnter:Connect(function() cursorHover += 1; tw(plusBtn, 0.15, { BackgroundColor3 = BTN_BG_HOV }) end)
plusBtn.MouseLeave:Connect(function() cursorHover = math.max(0, cursorHover - 1); tw(plusBtn, 0.15, { BackgroundColor3 = BTN_BG }) end)
plusBtn.MouseButton1Click:Connect(function() sfx(CONFIG.ClickSoundId); openShop("badges") end)

local function refreshCoins()
	coinLabel.Text = tostring(getBadges())
	plusBtn.Position = UDim2.fromOffset(1222 - coinLabel.TextBounds.X - 38, 28)
end
player:GetAttributeChangedSignal("Badges"):Connect(refreshCoins)
refreshCoins()
task.delay(0.2, refreshCoins)

-- ============================================================
-- ЭКРАН 1: заголовок + кнопки
-- ============================================================
local function screen(): CanvasGroup
	return new("CanvasGroup", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 6 }, stage)
end
local s1, s2 = screen(), screen()
s2.GroupTransparency = 1
s2.Visible = false
local s4, s5, s6 = screen(), screen(), screen()   -- сложность / инвентарь / team play
for _, g in { s4, s5, s6 } do
	g.GroupTransparency = 1
	g.Visible = false
end

-- раскладка слева: заголовок и кнопки колонкой, персонаж справа
local title = text(s1, CONFIG.GameTitle, 84, GOLD_TEXT, 570, 170, { Size = UDim2.fromOffset(900, 100), TextXAlignment = Enum.TextXAlignment.Left })
new("UIStroke", { Color = Color3.fromRGB(160, 100, 30), Thickness = 3 }, title)
divider(s1, 300, 232, 360, 0)
text(s1, CONFIG.Subtitle, 14, Color3.fromRGB(170, 140, 100), 270, 262, { Size = UDim2.fromOffset(300, 20), TextXAlignment = Enum.TextXAlignment.Left })

local playBtn = makeButton(s1, 120, 300, 360, 84, true)
text(playBtn, CONFIG.PlayTitle, 26, GOLD_TEXT, 180, 32, { ZIndex = 9 })
text(playBtn, CONFIG.PlayTagline, 11, Color3.fromRGB(190, 160, 120), 180, 62, { ZIndex = 9 })

local teamBtn = makeButton(s1, 120, 394, 360, 46)
text(teamBtn, "TEAM PLAY", 17, GOLD_TEXT, 180, 23, { ZIndex = 9 })
local invBtn = makeButton(s1, 120, 450, 174, 46)
text(invBtn, "INVENTORY", 15, GOLD_TEXT, 87, 23, { ZIndex = 9 })
local shopBtn1 = makeButton(s1, 306, 450, 174, 46)
text(shopBtn1, "SHOP", 15, GOLD_TEXT, 87, 23, { ZIndex = 9 })
local skinsBtn = makeButton(s1, 120, 506, 174, 46)
text(skinsBtn, "SKINS", 15, GOLD_TEXT, 87, 23, { ZIndex = 9 })
local settingsBtn = makeButton(s1, 306, 506, 174, 46)
text(settingsBtn, "SETTINGS", 15, GOLD_TEXT, 87, 23, { ZIndex = 9 })

local hint = text(s1, CONFIG.Hint, 12, Color3.fromRGB(190, 160, 120), 300, 676)
hint.TextTransparency = 0.7
task.spawn(function()
	while hint.Parent do
		tw(hint, 1.8, { TextTransparency = 0.85 }, Enum.EasingStyle.Sine)
		task.wait(1.8)
		tw(hint, 1.8, { TextTransparency = 0.55 }, Enum.EasingStyle.Sine)
		task.wait(1.8)
	end
end)

-- ============================================================
-- ЭКРАН 2: "WHAT WILL YOU TAKE?"
-- ============================================================
text(s2, "WHAT WILL YOU TAKE?", 24, GOLD_TEXT, 420, 95, { Size = UDim2.fromOffset(600, 30), TextXAlignment = Enum.TextXAlignment.Left })
divider(s2, 300, 128, 360, 14)
local diffLabel = text(s2, "DIFFICULTY: " .. CONFIG.Difficulties[1].Name, 12, CONFIG.Difficulties[1].Color, 420, 146, { Size = UDim2.fromOffset(600, 18), TextXAlignment = Enum.TextXAlignment.Left })

-- пиксельные иконки
local function px(parent: Instance, x: number, y: number, w: number, h: number, c: Color3)
	new("Frame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundColor3 = c, BorderSizePixel = 0, ZIndex = 9 }, parent)
end
local function drawIcon(parent: Instance, kind: string, cx: number, cy: number)
	local holder = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, cy), Size = UDim2.fromOffset(60, 76), BackgroundTransparency = 1, ZIndex = 9 }, parent)
	if kind == "lantern" then
		local dark = Color3.fromRGB(46, 32, 24)
		px(holder, 22, 0, 16, 6, dark); px(holder, 18, 6, 4, 8, dark); px(holder, 38, 6, 4, 8, dark)
		px(holder, 12, 14, 36, 8, dark)
		px(holder, 14, 22, 32, 40, Color3.fromRGB(255, 205, 70))
		px(holder, 22, 28, 16, 26, Color3.fromRGB(240, 130, 40))
		px(holder, 12, 62, 36, 8, dark)
	elseif kind == "bar" then   -- батончик в обёртке
		local wrap, crimp = Color3.fromRGB(150, 56, 40), Color3.fromRGB(226, 184, 96)
		px(holder, 8, 6, 44, 6, crimp); px(holder, 8, 64, 44, 6, crimp)
		px(holder, 12, 12, 36, 52, wrap)
		px(holder, 12, 12, 6, 52, Color3.fromRGB(120, 42, 30))
		px(holder, 18, 26, 24, 14, Color3.fromRGB(255, 206, 70))
		px(holder, 22, 30, 16, 6, Color3.fromRGB(150, 56, 40))
		px(holder, 20, 46, 20, 4, Color3.fromRGB(255, 232, 170))
		px(holder, 20, 54, 12, 3, Color3.fromRGB(255, 232, 170))
	end
	return holder
end

local function drawToyIcon(parent: Instance, kind: string, c: Color3, cx: number, cy: number)
	local h = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, cy), Size = UDim2.fromOffset(60, 76), BackgroundTransparency = 1, ZIndex = 9 }, parent)
	local dark, light = Color3.fromRGB(34, 22, 16), Color3.fromRGB(255, 244, 214)
	local shade = c:Lerp(Color3.new(0, 0, 0), 0.3)
	if kind == "duck" then
		px(h, 4, 34, 10, 10, shade); px(h, 8, 36, 38, 26, c); px(h, 28, 12, 24, 26, c)
		px(h, 50, 24, 10, 8, Color3.fromRGB(240, 130, 40)); px(h, 40, 20, 4, 4, dark); px(h, 14, 44, 20, 10, shade)
	elseif kind == "top" then
		px(h, 26, 6, 8, 14, dark); px(h, 14, 20, 32, 10, shade); px(h, 8, 30, 44, 24, c)
		px(h, 8, 38, 44, 5, light); px(h, 20, 54, 20, 8, shade); px(h, 26, 62, 8, 10, Color3.fromRGB(150, 150, 160))
	elseif kind == "robot" then
		px(h, 28, 0, 4, 8, dark); px(h, 14, 8, 32, 24, c); px(h, 20, 16, 7, 7, Color3.fromRGB(90, 230, 255)); px(h, 34, 16, 7, 7, Color3.fromRGB(90, 230, 255))
		px(h, 10, 34, 40, 26, shade); px(h, 22, 42, 16, 8, Color3.fromRGB(255, 190, 60)); px(h, 2, 36, 8, 20, c); px(h, 50, 36, 8, 20, c)
		px(h, 16, 60, 10, 14, c); px(h, 34, 60, 10, 14, c)
	elseif kind == "bear" then
		px(h, 6, 4, 16, 16, shade); px(h, 38, 4, 16, 16, shade); px(h, 10, 10, 40, 34, c)
		px(h, 22, 28, 16, 12, Color3.fromRGB(226, 186, 136)); px(h, 18, 20, 5, 5, dark); px(h, 37, 20, 5, 5, dark); px(h, 28, 30, 5, 5, dark)
		px(h, 14, 46, 32, 26, c); px(h, 24, 52, 12, 14, Color3.fromRGB(226, 186, 136))
	elseif kind == "box" or kind == "music" then
		px(h, 24, 6, 12, 8, light); px(h, 26, 14, 8, 6, c:Lerp(light, 0.5)); px(h, 20, 2, 20, 16, Color3.fromRGB(240, 200, 160))
		px(h, 26, 8, 4, 4, dark); px(h, 34, 8, 4, 4, dark)
		px(h, 4, 22, 52, 10, shade); px(h, 8, 32, 44, 38, c); px(h, 8, 46, 44, 6, light); px(h, 26, 36, 8, 6, Color3.fromRGB(255, 214, 90))
	elseif kind == "car" then
		local black = Color3.fromRGB(16, 14, 14)
		px(h, 6, 52, 16, 16, Color3.fromRGB(6, 6, 6)); px(h, 38, 52, 16, 16, Color3.fromRGB(6, 6, 6)); px(h, 11, 57, 6, 6, c); px(h, 43, 57, 6, 6, c)
		px(h, 0, 36, 60, 20, black); px(h, 0, 44, 60, 5, c)
		px(h, 12, 20, 34, 18, black); px(h, 12, 18, 34, 4, c); px(h, 16, 24, 12, 10, Color3.fromRGB(255, 225, 225)); px(h, 31, 24, 11, 10, Color3.fromRGB(255, 225, 225))
		px(h, 54, 38, 6, 6, Color3.fromRGB(255, 240, 150)); px(h, 0, 38, 4, 6, Color3.fromRGB(255, 40, 40))
	elseif kind == "dragon" or kind == "sdragon" then
		px(h, 0, 50, 10, 6, shade); px(h, 6, 34, 40, 26, c); px(h, 4, 14, 16, 22, Color3.fromRGB(255, 140, 50))
		px(h, 36, 14, 22, 22, c); px(h, 46, 4, 6, 12, shade); px(h, 50, 22, 4, 4, dark); px(h, 56, 28, 4, 4, Color3.fromRGB(255, 90, 40))
		px(h, 12, 60, 10, 12, shade); px(h, 32, 60, 10, 12, shade); px(h, 12, 42, 28, 4, light)
		if kind == "sdragon" then
			px(h, 36, 8, 22, 6, Color3.fromRGB(250, 246, 240)); px(h, 38, 2, 18, 8, Color3.fromRGB(205, 28, 34)); px(h, 52, 0, 6, 6, Color3.fromRGB(250, 246, 240))
		end
	elseif kind == "rocket" then
		px(h, 24, 0, 12, 10, Color3.fromRGB(230, 70, 60)); px(h, 20, 10, 20, 46, c); px(h, 26, 22, 8, 8, Color3.fromRGB(70, 150, 255))
		px(h, 20, 42, 20, 4, Color3.fromRGB(230, 70, 60)); px(h, 10, 40, 10, 18, Color3.fromRGB(230, 70, 60)); px(h, 40, 40, 10, 18, Color3.fromRGB(230, 70, 60))
		px(h, 24, 58, 12, 10, Color3.fromRGB(255, 170, 50)); px(h, 27, 68, 6, 8, Color3.fromRGB(255, 230, 120))
	elseif kind == "bauble" then
		local gold = Color3.fromRGB(240, 200, 80)
		px(h, 24, 0, 12, 4, gold); px(h, 20, 4, 4, 6, gold); px(h, 36, 4, 4, 6, gold); px(h, 24, 8, 12, 5, gold)
		px(h, 14, 14, 32, 6, c); px(h, 8, 20, 44, 34, c); px(h, 14, 54, 32, 8, c); px(h, 22, 62, 16, 6, shade)
		px(h, 8, 34, 44, 5, light); px(h, 8, 42, 44, 4, gold); px(h, 14, 24, 8, 8, Color3.fromRGB(255, 220, 220))
	elseif kind == "santa" then
		local red, wh = Color3.fromRGB(220, 40, 40), Color3.fromRGB(250, 246, 240)
		px(h, 40, 2, 9, 9, wh); px(h, 16, 6, 30, 14, red); px(h, 10, 18, 42, 6, wh); px(h, 16, 24, 28, 14, Color3.fromRGB(245, 200, 170))
		px(h, 20, 28, 4, 4, dark); px(h, 36, 28, 4, 4, dark); px(h, 14, 36, 32, 16, wh); px(h, 10, 52, 40, 18, red)
		px(h, 10, 58, 40, 4, dark); px(h, 26, 58, 8, 4, Color3.fromRGB(240, 200, 80))
	end
	return h
end

local selected: {[string]: boolean} = {}
local selectedDiff = CONFIG.Difficulties[1].Id
local totalLabel = text(s2, "total 0", 15, GOLD_TEXT, 380, 447)

local function total(): number
	local t = 0
	for _, it in CONFIG.Items do
		if selected[it.Id] then t += it.Cost end
	end
	return t
end
local function refreshTotal() totalLabel.Text = "total " .. total() end

for idx, it in CONFIG.Items do
	local x = 120 + (idx - 1) * 273
	local card, setActive = makeButton(s2, x, 160, 247, 257)
	drawIcon(card, it.Icon, 123, 66)
	text(card, it.Name, 19, GOLD_TEXT, 124, 142, { ZIndex = 9 })
	text(card, it.Desc, 11, Color3.fromRGB(190, 165, 130), 124, 172, { ZIndex = 9, Size = UDim2.fromOffset(235, 16) })
	star(card, 108, 235, 13, 9)
	text(card, tostring(it.Cost), 15, GOLD_TEXT, 138, 235, { ZIndex = 9, Size = UDim2.fromOffset(40, 20), TextXAlignment = Enum.TextXAlignment.Left })

	card.MouseButton1Click:Connect(function()
		sfx(CONFIG.ClickSoundId)
		if selected[it.Id] then
			selected[it.Id] = nil
			setActive(false)
		else
			if total() + it.Cost > getBadges() then
				local p = card.Position
				for _ = 1, 3 do
					tw(card, 0.04, { Position = p + UDim2.fromOffset(6, 0) }).Completed:Wait()
					tw(card, 0.04, { Position = p - UDim2.fromOffset(6, 0) }).Completed:Wait()
				end
				card.Position = p
				return
			end
			selected[it.Id] = true
			setActive(true)
		end
		refreshTotal()
	end)
end

local fallBtn = makeButton(s2, 120, 480, 520, 56, true)
text(fallBtn, "FALL INTO PURGATORY", 17, GOLD_TEXT, 260, 28, { ZIndex = 9, Size = UDim2.fromOffset(500, 22) })
local backBtn = makeButton(s2, 120, 548, 254, 50)
text(backBtn, "BACK", 16, GOLD_TEXT, 127, 25, { ZIndex = 9 })
local shopBtn2 = makeButton(s2, 386, 548, 254, 50)
text(shopBtn2, "SHOP", 16, GOLD_TEXT, 127, 25, { ZIndex = 9 })

-- ============================================================
-- Мини-окно (GIFTS / SETTINGS)
-- ============================================================
local modal = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, Visible = false, ZIndex = 30, Active = true }, stage)
local panel = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(640, 360), Size = UDim2.fromOffset(420, 200),
	BackgroundColor3 = Color3.fromRGB(22, 15, 10), BorderSizePixel = 0, ZIndex = 31 }, modal)
new("UIStroke", { Color = GOLD, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, panel)
brackets(panel)
local modalTitle = text(panel, "", 20, GOLD_TEXT, 210, 36, { ZIndex = 32 })
local modalBody = text(panel, "", 13, Color3.fromRGB(190, 165, 130), 210, 90, { ZIndex = 32, Size = UDim2.fromOffset(380, 60), TextWrapped = true })
local closeBtn = makeButton(panel, 110, 138, 200, 40)
closeBtn.ZIndex = 32
text(closeBtn, "CLOSE", 15, GOLD_TEXT, 100, 20, { ZIndex = 33 })

local function openModal(titleStr: string, body: string)
	modalTitle.Text, modalBody.Text = titleStr, body
	modal.Visible = true
	tw(modal, 0.2, { BackgroundTransparency = 0.5 })
end
closeBtn.MouseButton1Click:Connect(function()
	sfx(CONFIG.ClickSoundId)
	modal.Visible = false
	modal.BackgroundTransparency = 1
end)

-- ============================================================
-- НАСТРОЙКИ: громкость, переключатели, промокод
-- ============================================================
local applyCursor: (boolean) -> () = function() end   -- назначается ниже, после курсора
local UIS = game:GetService("UserInputService")
local DIM = Color3.fromRGB(190, 165, 130)

local settingsModal = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, Visible = false, ZIndex = 30, Active = true }, stage)
local sp = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(640, 360), Size = UDim2.fromOffset(560, 640),
	BackgroundColor3 = Color3.fromRGB(22, 15, 10), BorderSizePixel = 0, ZIndex = 31 }, settingsModal)
do   -- блок: освобождает локальные переменные (лимит Luau 200)
new("UIStroke", { Color = GOLD, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, sp)
brackets(sp)
text(sp, "SETTINGS", 22, GOLD_TEXT, 280, 34, { ZIndex = 32 })

local function leftLabel(str: string, y: number)
	text(sp, str, 13, GOLD_TEXT, 150, y, { ZIndex = 32, Size = UDim2.fromOffset(240, 18), TextXAlignment = Enum.TextXAlignment.Left })
end

-- слайдер громкости
leftLabel("MUSIC VOLUME", 100)
local track = new("Frame", { Position = UDim2.fromOffset(250, 96), Size = UDim2.fromOffset(270, 8), BackgroundColor3 = Color3.fromRGB(50, 36, 22), BorderSizePixel = 0, ZIndex = 32 }, sp)
local fill = new("Frame", { Size = UDim2.fromScale(CONFIG.MusicVolume, 1), BackgroundColor3 = GOLD, BorderSizePixel = 0, ZIndex = 33 }, track)
local knob = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(CONFIG.MusicVolume, 0, 0.5, 0), Size = UDim2.fromOffset(12, 24), BackgroundColor3 = GOLD_TEXT, BorderSizePixel = 0, ZIndex = 34 }, track)
local sliderHit = new("TextButton", { Position = UDim2.fromOffset(240, 84), Size = UDim2.fromOffset(290, 32), BackgroundTransparency = 1, Text = "", ZIndex = 35 }, sp)
local musicVol, musicOn = CONFIG.MusicVolume, true
local function applyMusic() if music then music.Volume = musicOn and musicVol or 0 end end
local dragging = false
local function setFromX(x: number)
	local r = math.clamp((x - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
	musicVol = r
	fill.Size = UDim2.fromScale(r, 1)
	knob.Position = UDim2.new(r, 0, 0.5, 0)
	applyMusic()
end
sliderHit.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		setFromX(input.Position.X)
	end
end)
UIS.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		setFromX(input.Position.X)
	end
end)
UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

-- переключатели ON/OFF
local function toggle(y: number, label: string, initial: boolean, onChange: (boolean) -> ())
	leftLabel(label, y + 17)
	local b, setA = makeButton(sp, 410, y, 110, 34, initial)
	local lab = text(b, initial and "ON" or "OFF", 14, GOLD_TEXT, 55, 17, { ZIndex = 9 })
	local state = initial
	b.MouseButton1Click:Connect(function()
		sfx(CONFIG.ClickSoundId)
		state = not state
		lab.Text = state and "ON" or "OFF"
		setA(state)
		onChange(state)
	end)
end
toggle(120, "MUSIC", true, function(on) musicOn = on; applyMusic() end)
toggle(158, "TENTACLE CURSOR", true, function(on) applyCursor(on) end)
toggle(196, "FLOATING DUST", true, function(on) dustFolder.Visible = on end)
toggle(234, "LIGHT RAYS", true, function(on) rays.Visible = on end)
toggle(272, "JINGLE BELLS (LOBBY)", true, function(on) LT.set(on) end)
toggle(310, "LOW-END MODE (WEAK DEVICE)", false, function(on) pcall(function() player:SetAttribute("EvaKLowEnd", on) end) end)
toggle(348, "NEW YEAR THEME", player:GetAttribute("EvaKNYTheme") ~= false, function(on)
	player:SetAttribute("EvaKNYTheme", on)
	player:SetAttribute("EvaKTheme", on and "ny" or "classic")
end)
toggle(386, "FPS COUNTER", player:GetAttribute("EvaKShowFps") == true, function(on) player:SetAttribute("EvaKShowFps", on) end)
toggle(424, "CROSSHAIR", player:GetAttribute("EvaKCrosshair") ~= false, function(on) player:SetAttribute("EvaKCrosshair", on) end)

-- промокод
leftLabel("PROMO CODE", 482)
end
local codeBox = new("TextBox", {
	Position = UDim2.fromOffset(30, 496), Size = UDim2.fromOffset(340, 40), BackgroundColor3 = Color3.fromRGB(14, 10, 7), BorderSizePixel = 0,
	Text = "", PlaceholderText = "ENTER CODE", PlaceholderColor3 = Color3.fromRGB(120, 100, 75), TextColor3 = GOLD_TEXT,
	Font = CONFIG.Font, TextSize = 16, ClearTextOnFocus = false, ZIndex = 32,
}, sp)
new("UIStroke", { Color = GOLD_DIM, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, codeBox)
local redeemBtn = makeButton(sp, 380, 496, 140, 40)
text(redeemBtn, "REDEEM", 14, GOLD_TEXT, 70, 20, { ZIndex = 9 })
local promoResult = text(sp, "", 13, DIM, 280, 554, { ZIndex = 32, Size = UDim2.fromOffset(500, 18) })

local function redeem()
	sfx(CONFIG.ClickSoundId)
	if string.gsub(codeBox.Text, "%s", "") == "" then return end
	local ok, msg = invoke("Redeem", codeBox.Text)
	if ok then
		promoResult.Text = "+" .. msg .. (tostring(msg):match("%a") and "!" or " BADGES!")
		promoResult.TextColor3 = GOLD
		codeBox.Text = ""
	else
		promoResult.Text = (msg == "used" and "CODE ALREADY USED") or (msg == "invalid" and "INVALID CODE") or "TRY AGAIN LATER"
		promoResult.TextColor3 = Color3.fromRGB(235, 110, 90)
	end
end
redeemBtn.MouseButton1Click:Connect(redeem)
codeBox.FocusLost:Connect(function(enter) if enter then redeem() end end)

local closeSettings = makeButton(sp, 180, 584, 200, 40)
text(closeSettings, "CLOSE", 15, GOLD_TEXT, 100, 20, { ZIndex = 9 })
closeSettings.MouseButton1Click:Connect(function() sfx(CONFIG.ClickSoundId); settingsModal.Visible = false end)
do
	local statsBtn = makeButton(sp, 30, 584, 140, 40)
	text(statsBtn, "STATISTICS", 14, GOLD_TEXT, 70, 20, { ZIndex = 9 })
	statsBtn.MouseButton1Click:Connect(function() sfx(CONFIG.ClickSoundId); pcall(function() player:SetAttribute("EvaKOpenStats", os.clock()) end) end)
end
settingsBtn.MouseButton1Click:Connect(function()
	sfx(CONFIG.ClickSoundId)
	promoResult.Text = ""
	settingsModal.Visible = true
end)

-- ============================================================
-- Переходы между экранами
-- ============================================================
local busy = false
local function switch(from: CanvasGroup, to: CanvasGroup)
	if busy then return end
	busy = true
	tw(from, 0.4, { GroupTransparency = 1 }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut).Completed:Wait()
	from.Visible = false
	to.Visible = true
	to.GroupTransparency = 1
	tw(to, 0.7, { GroupTransparency = 0 }, Enum.EasingStyle.Sine, Enum.EasingDirection.Out).Completed:Wait()
	busy = false
end

local current: CanvasGroup = s1
local function go(to: CanvasGroup)
	if busy or to == current then return end
	local from = current
	current = to
	switch(from, to)
end

local beginFall: (string, boolean?) -> () = function() end   -- назначается ниже (сцена падения)

playBtn.MouseButton1Click:Connect(function() sfx(CONFIG.ClickSoundId); go(s4) end)
backBtn.MouseButton1Click:Connect(function() sfx(CONFIG.ClickSoundId); go(s4) end)

-- маленькие помощники
local function shake(o: GuiObject)
	task.spawn(function()
		local p = o.Position
		for _ = 1, 3 do
			tw(o, 0.04, { Position = p + UDim2.fromOffset(6, 0) }).Completed:Wait()
			tw(o, 0.04, { Position = p - UDim2.fromOffset(6, 0) }).Completed:Wait()
		end
		o.Position = p
	end)
end
local function burst(card: GuiObject, color: Color3)
	local ring = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(120, 64), Size = UDim2.fromOffset(40, 40), BackgroundTransparency = 1, ZIndex = 12 }, card)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, ring)
	local st = new("UIStroke", { Color = color, Thickness = 3 }, ring)
	tw(ring, 0.6, { Size = UDim2.fromOffset(230, 230) })
	tw(st, 0.6, { Transparency = 1, Thickness = 1 }).Completed:Once(function() ring:Destroy() end)
	for i = 1, 10 do
		local a = (i / 10) * math.pi * 2 + rng:NextNumber() * 0.4
		local d = rng:NextNumber(70, 120)
		local sparkle = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(120, 64), Size = UDim2.fromOffset(6, 6),
			BackgroundColor3 = color, BorderSizePixel = 0, Rotation = 45, ZIndex = 12 }, card)
		tw(sparkle, 0.7, { Position = UDim2.fromOffset(120 + math.cos(a) * d, 64 + math.sin(a) * d), BackgroundTransparency = 1, Size = UDim2.fromOffset(2, 2) }).Completed:Once(function() sparkle:Destroy() end)
	end
end
local toastLabel = text(stage, "", 16, GOLD_TEXT, 640, 664, { ZIndex = 40, TextTransparency = 1, Size = UDim2.fromOffset(700, 24) })
local toastId = 0
local function toast(msg: string)
	toastId += 1
	local my = toastId
	toastLabel.Text = msg
	toastLabel.TextTransparency = 0
	task.delay(2, function()
		if my == toastId then tw(toastLabel, 0.5, { TextTransparency = 1 }) end
	end)
end
local function failText(msg: string): string
	if msg == "not enough badges" then return "NOT ENOUGH BADGES - PRESS +" end
	if msg == "loading" then return "LOADING DATA, TRY AGAIN" end
	if msg == "server error" then return "SERVER ERROR - SEE OUTPUT" end
	if msg == "full" then return "PARTY IS FULL (MAX 5)" end
	if msg == "friends only" then return "FRIENDS ONLY PARTY" end
	if msg == "gone" then return "PARTY NO LONGER EXISTS" end
	if msg == "locked" then return "DIFFICULTY LOCKED" end
	if msg == "in lobby" then return "ALREADY IN A PARTY" end
	if msg == "no server" then return "TEAM PLAY NEEDS THE SERVER SCRIPT" end
	return "SOMETHING WENT WRONG"
end

-- ============================================================
-- МАГАЗИН (вкладки TOYS / BADGES)
-- ============================================================
local s3 = screen()
s3.GroupTransparency = 1
s3.Visible = false

text(s3, "SHOP", 40, GOLD_TEXT, 420, 62, { Size = UDim2.fromOffset(600, 50), TextXAlignment = Enum.TextXAlignment.Left })
divider(s3, 300, 100, 360, 0)

local shopPanel = new("Frame", {
	Position = UDim2.fromOffset(100, 126), Size = UDim2.fromOffset(1080, 486), BackgroundColor3 = Color3.fromRGB(14, 9, 6),
	BackgroundTransparency = 0.2, BorderSizePixel = 0, ZIndex = 5,
}, s3)
new("UIStroke", { Color = GOLD_DIM, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, shopPanel)

local toysPage = new("ScrollingFrame", {
	Position = UDim2.fromOffset(0, 176), Size = UDim2.new(1, 0, 0, 430), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 6,
	ScrollBarThickness = 6, ScrollBarImageColor3 = GOLD, CanvasSize = UDim2.fromOffset(0, 8 + math.ceil(#CONFIG.Toys / 4) * 194),
	ScrollingDirection = Enum.ScrollingDirection.Y, ClipsDescendants = true,
}, s3)
local badgesPage = new("ScrollingFrame", {
	Position = UDim2.fromOffset(0, 184), Size = UDim2.new(1, 0, 0, 422), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 6, Visible = false,
	ScrollBarThickness = 6, ScrollBarImageColor3 = GOLD, CanvasSize = UDim2.fromOffset(0, 1800), ScrollingDirection = Enum.ScrollingDirection.Y, ClipsDescendants = true,
}, s3)

local tabToys, setTabToys = makeButton(s3, 126, 138, 200, 36, true)
text(tabToys, "TOYS SHOP", 15, GOLD_TEXT, 100, 18, { ZIndex = 9 })
local tabBadges, setTabBadges = makeButton(s3, 342, 138, 200, 36)
text(tabBadges, "SHOP", 15, GOLD_TEXT, 100, 18, { ZIndex = 9 })

local function showTab(name: string)
	toysPage.Visible = (name == "toys")
	badgesPage.Visible = (name == "badges")
	setTabToys(name == "toys")
	setTabBadges(name == "badges")
end
tabToys.MouseButton1Click:Connect(function() sfx(CONFIG.ClickSoundId); showTab("toys") end)
tabBadges.MouseButton1Click:Connect(function() sfx(CONFIG.ClickSoundId); showTab("badges") end)

local function perkText(t): string
	local parts = {}
	if t.Speed > 0 then table.insert(parts, string.format("+%d%% speed", math.round(t.Speed * 100))) end
	if t.Badge > 0 then table.insert(parts, string.format("+%d%% badges", math.round(t.Badge * 100))) end
	return table.concat(parts, "  ")
end

-- покупка за робуксы: определяем тип ID (Developer Product или Game Pass) и открываем окно оплаты
local function promptRobux(id: number)
	if type(id) ~= "number" or id <= 0 then toast("PRODUCT ID NOT SET YET"); warn("[EvaK] у этой игрушки не указан ProductId"); return end
	local isPass = false
	local okP = pcall(function() return MarketplaceService:GetProductInfo(id, Enum.InfoType.Product) end)
	if not okP then
		local okG, infoG = pcall(function() return MarketplaceService:GetProductInfo(id, Enum.InfoType.GamePass) end)
		if okG and infoG then isPass = true end
		warn("[EvaK] ID " .. id .. (isPass and " - это Game Pass (покупается 1 раз)" or " не найден ни как Product, ни как Game Pass этой игры"))
	end
	if not shopRemote then
		warn("[EvaK] Серверный скрипт EvaKServer не найден - оплата пройдёт, но покупка НЕ начислится")
		toast("SERVER SCRIPT MISSING")
	end
	local ok, err = pcall(function()
		if isPass then MarketplaceService:PromptGamePassPurchase(player, id)
		else MarketplaceService:PromptProductPurchase(player, id) end
	end)
	if not ok then
		warn("[EvaK] покупка не открылась: " .. tostring(err))
		toast("PURCHASE UNAVAILABLE - SEE OUTPUT")
	end
end

-- --- таймер новогоднего ивента (до 31 декабря) ---
local NY_FALLBACK_END = os.time({ year = 2026, month = 12, day = 31, hour = 23, min = 59, sec = 59 })
local function nyRemaining(): number
	local e = workspace:GetAttribute("EvaKNYEnd") or NY_FALLBACK_END
	return e - workspace:GetServerTimeNow()
end

-- --- игрушки ---
local toyViews = {}
for i, toy in CONFIG.Toys do
	local col, row = (i - 1) % 4, (i - 1) // 4
	local card = makeButton(toysPage, 126 + col * 256, 8 + row * 194, 240, 180)
	local rc = CONFIG.Rarities[toy.Rarity] or GOLD
	new("Frame", { Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = rc, BorderSizePixel = 0, ZIndex = 9 }, card)
	local rarLbl = text(card, string.upper(toy.Rarity), 11, rc, 120, 18, { ZIndex = 9 })
	local view = toyView(card, toy, 120, 64, 210, 100, function() return s3.Visible and toysPage.Visible end, card)
	text(card, toy.Name, 14, GOLD_TEXT, 120, 112, { ZIndex = 9, Size = UDim2.fromOffset(232, 18) })
	text(card, perkText(toy), 10, Color3.fromRGB(190, 165, 130), 120, 132, { ZIndex = 9, Size = UDim2.fromOffset(232, 14) })
	local costStar = star(card, 36, 156, 13, 9)
	local costText = text(card, tostring(toy.Cost), 14, GOLD_TEXT, 92, 156, { ZIndex = 9, Size = UDim2.fromOffset(80, 18), TextXAlignment = Enum.TextXAlignment.Left })
	local rbx = new("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(190, 156), Size = UDim2.fromOffset(84, 24),
		BackgroundColor3 = Color3.fromRGB(48, 32, 14), BorderSizePixel = 0, AutoButtonColor = true, ZIndex = 10,
		Text = "R$ " .. tostring(toy.Robux or "?"), TextColor3 = GOLD_TEXT, Font = Enum.Font.Arcade, TextSize = 13,
	}, card)
	new("UIStroke", { Color = GOLD, Thickness = 1.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, rbx)
	rbx.MouseButton1Click:Connect(function()
		sfx(CONFIG.ClickSoundId)
		if toy.ProductId then promptRobux(toy.ProductId) end
	end)
	local status = text(card, "", 12, GOLD_TEXT, 120, 156, { ZIndex = 9, Size = UDim2.fromOffset(232, 18), Visible = false })
	table.insert(toyViews, { toy = toy, star = costStar, cost = costText, status = status, rbx = rbx, rar = rarLbl, rarName = string.upper(toy.Rarity) })

	card.MouseButton1Click:Connect(function()
		sfx(CONFIG.ClickSoundId)
		local owned = ownedToys()
		local ok, msg = true, ""
		if toy.Vip then
			shake(card)
			toast(owned[toy.Id] and "YOUR CARBON CAR" or "ONLY FOR CARBON OWNERS - SHOP > CARBON")
			return
		end
		if toy.Event then
			shake(card)
			if not owned[toy.Id] then
				toast(toy.Id == "NEWYEAR" and "COLLECT 10 BAUBLES ON NEW YEAR MAP OR BUY FOR R$" or "BEAT 100 DOORS ON NEW YEAR OR BUY FOR R$")
			end
			return
		end
		ok, msg = invoke("BuyToy", toy.Id)   -- можно покупать несколько одинаковых
		if not ok then shake(card); toast(failText(msg)) else view.pop = os.clock(); burst(card, rc) end
	end)
end

local function refreshShop()
	local owned = ownedToys()
	for _, v in toyViews do
		local id = v.toy.Id
		v.status.Position = UDim2.fromOffset(120, 156)
		v.status.TextSize = 12
		if v.toy.Vip then
			v.star.Visible, v.cost.Visible, v.rbx.Visible, v.status.Visible = false, false, false, true
			v.status.Text = owned[id] and "OWNED - CARBON" or "ONLY WITH CARBON"
			v.status.TextColor3 = owned[id] and GOLD or Color3.fromRGB(255, 90, 90)
		elseif owned[id] and v.toy.Event then
			v.star.Visible, v.cost.Visible, v.rbx.Visible, v.status.Visible = false, false, false, true
			v.status.Text = "OWNED"
			v.status.TextColor3 = GOLD
		elseif owned[id] then   -- обычную игрушку можно докупать: показываем цену и счётчик копий
			v.star.Visible, v.cost.Visible, v.status.Visible = true, true, false
			v.rbx.Visible = true
			v.rar.Text = v.rarName .. "  -  OWNED x" .. toyCount(id)
		elseif v.toy.Event then   -- ивент-игрушка: за шары или за робуксы
			v.star.Visible, v.cost.Visible, v.rbx.Visible = false, false, nyRemaining() > 0
			v.status.Visible = true
			v.status.Position = UDim2.fromOffset(100, 156)
			v.status.TextSize = 10
			v.status.Size = UDim2.fromOffset(190, 18)
			if nyRemaining() > 0 then
				v.status.Text = (v.toy.Id == "NEWYEAR") and ("BAUBLES " .. (player:GetAttribute("NYBaubles") or 0) .. " / 10  (NEW YEAR MAP)") or "BEAT 100 DOORS ON NEW YEAR"
				v.status.TextColor3 = Color3.fromRGB(255, 140, 140)
			else
				v.status.Text = "LIMITED - EVENT OVER"
				v.status.TextColor3 = Color3.fromRGB(255, 120, 200)
			end
		else
			v.star.Visible, v.cost.Visible, v.status.Visible = true, true, false
			v.rbx.Visible = true
			v.rar.Text = v.rarName
		end
		if v.toy.Event and nyRemaining() <= 0 then v.rar.Text = "LIMITED"; v.rar.TextColor3 = CONFIG.Rarities.Limited end
	end
end
for _, attr in { "OwnedToys", "EquippedToy", "ToyCounts", "Badges", "NYBaubles" } do
	player:GetAttributeChangedSignal(attr):Connect(refreshShop)
end
refreshShop()

-- подписи таймера ивента: главное меню, магазин, выбор сложности
local function nyText(): (string, Color3)
	local r = nyRemaining()
	if r <= 0 then return "NEW YEAR EVENT OVER - THE TOY IS NOW LIMITED", Color3.fromRGB(255, 120, 200) end
	local days = math.floor(r / 86400)
	if days >= 1 then
		return string.format("NEW YEAR EVENT: %d DAY%s LEFT - collect 10 baubles on the NEW YEAR map", days, days == 1 and "" or "S"), Color3.fromRGB(120, 230, 255)
	end
	return string.format("NEW YEAR EVENT: %dH %dM LEFT", math.floor(r / 3600), math.floor(r % 3600 / 60)), Color3.fromRGB(255, 190, 120)
end
do   -- блок: освобождает локальные переменные (лимит Luau 200)
local nyLabels = {
	text(s2, "", 12, Color3.fromRGB(120, 230, 255), 420, 168, { Size = UDim2.fromOffset(620, 18), TextXAlignment = Enum.TextXAlignment.Left }),
	text(s3, "", 12, Color3.fromRGB(120, 230, 255), 506, 112, { Size = UDim2.fromOffset(760, 18), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9 }),
}
local function refreshNY()
	local t, col = nyText()
	for _, l in nyLabels do l.Text = t; l.TextColor3 = col end
end
refreshNY()
task.spawn(function()
	while true do
		task.wait(30)
		refreshNY()
		refreshShop()
	end
end)

-- --- SHOP: CarBon, кейсы, дьявольские предметы, бейджи и снежинки (внизу) ---
do
	local TweenService = game:GetService("TweenService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RED, WHITE = Color3.fromRGB(215, 22, 34), Color3.fromRGB(255, 255, 255)
	local ICE = Color3.fromRGB(150, 225, 255)
	local shines = {}

	local function fr(parent: Instance, x: number, y: number, w: number, h: number, col: Color3, z: number?, rot: number?, tr: number?)
		return new("Frame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundColor3 = col, BackgroundTransparency = tr or 0,
			BorderSizePixel = 0, ZIndex = z or 10, Rotation = rot or 0 }, parent)
	end
	local function glow(parent: Instance, cx: number, cy: number, r: number, col: Color3, tr: number)
		local g = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, cy), Size = UDim2.fromOffset(r * 2, r * 2), BackgroundColor3 = col,
			BackgroundTransparency = tr, BorderSizePixel = 0, ZIndex = 8 }, parent)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, g)
		new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }), Rotation = 90 }, g)
		return g
	end
	local function section(title: string, y: number, col: Color3?)
		text(badgesPage, title, 20, col or GOLD_TEXT, 126, y, { Size = UDim2.fromOffset(500, 26), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9, AnchorPoint = Vector2.new(0, 0.5) })
		fr(badgesPage, 126, y + 16, 1020, 2, GOLD_DIM, 9, 0, 0.4)
	end
	local function card(x: number, y: number, w: number, h: number, accent: Color3, bg: Color3?)
		local c = makeButton(badgesPage, x, y, w, h)
		local back = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = bg or Color3.fromRGB(26, 14, 10), BorderSizePixel = 0, ZIndex = 7 }, c)
		new("UIGradient", { Color = ColorSequence.new(accent:Lerp(Color3.new(0, 0, 0), 0.75), Color3.fromRGB(8, 5, 4)), Rotation = 35 }, back)
		fr(c, 0, 0, w, 3, accent, 9)
		-- «блик»: светлая полоса пробегает по карточке
		local clip = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 11 }, c)
		local bar = fr(clip, -80, -30, 26, h + 80, WHITE, 11, 18, 0.9)
		table.insert(shines, { bar = bar, w = w, off = math.random() })
		return c
	end

	-- ---------- иконки ----------
	local function carIcon(p: Instance, cx: number, cy: number, s: number)
		local black, glass = Color3.fromRGB(14, 12, 12), Color3.fromRGB(255, 225, 225)
		local function b(x, y, w, h, c, z) return fr(p, cx + x * s, cy + y * s, w * s, h * s, c, z or 10) end
		glow(p, cx, cy + 4 * s, 20 * s, RED, 0.55)
		for i = 0, 3 do b(-34 - i * 4, -2 + i * 5, 10, 1.5, RED, 9).BackgroundTransparency = 0.3 + i * 0.15 end   -- линии скорости
		b(-26, 8, 8, 8, Color3.fromRGB(6, 6, 6)); b(14, 8, 8, 8, Color3.fromRGB(6, 6, 6))
		b(-30, -4, 60, 14, black); b(-30, 3, 60, 3, RED)
		b(-16, -14, 32, 11, black); b(-16, -16, 32, 3, RED)
		b(-12, -12, 11, 7, glass); b(2, -12, 11, 7, glass)
		b(-24, 10, 5, 5, RED, 11); b(16, 10, 5, 5, RED, 11)
		b(30, 0, 3, 4, Color3.fromRGB(255, 240, 150), 11); b(-33, 0, 3, 4, Color3.fromRGB(255, 40, 40), 11)
	end
	local function crateIcon(p: Instance, cx: number, cy: number, s: number, tier: number)
		local pal = ({
			{ wood = Color3.fromRGB(122, 78, 44), dark = Color3.fromRGB(66, 40, 22), metal = Color3.fromRGB(150, 150, 160), gl = Color3.fromRGB(255, 160, 60) },
			{ wood = Color3.fromRGB(58, 30, 78), dark = Color3.fromRGB(26, 12, 38), metal = Color3.fromRGB(170, 110, 220), gl = Color3.fromRGB(190, 70, 255) },
			{ wood = Color3.fromRGB(210, 170, 70), dark = Color3.fromRGB(120, 86, 24), metal = Color3.fromRGB(255, 244, 200), gl = Color3.fromRGB(255, 60, 40) },
		})[tier]
		glow(p, cx, cy, 30 * s, pal.gl, 0.6)
		local function b(x, y, w, h, c, z) return fr(p, cx + x * s, cy + y * s, w * s, h * s, c, z or 10) end
		b(-24, -10, 48, 30, pal.wood); b(-24, -10, 48, 4, pal.dark)
		b(-26, -18, 52, 10, pal.dark); b(-26, -18, 52, 3, pal.wood)   -- крышка
		for i = 0, 3 do b(-24 + i * 12, -6, 1.5, 24, pal.dark) end
		b(-24, 2, 48, 3, pal.metal); b(-24, 12, 48, 3, pal.metal)
		b(-5, -4, 10, 14, pal.metal, 11); b(-2, 0, 4, 5, Color3.fromRGB(10, 6, 6), 12)
		if tier >= 2 then   -- светящийся глаз на проклятых кейсах
			b(-12, -14, 24, 2, pal.gl, 12)
			for _, ex in { -12, 8 } do b(ex, 8, 4, 3, pal.gl, 12) end
		end
		if tier == 3 then
			for _, sp in { { -34, -22 }, { 32, -24 }, { 36, 6 }, { -36, 8 } } do b(sp[1], sp[2], 3, 3, WHITE, 12) end
		end
	end
	local function hornsIcon(p: Instance, cx: number, cy: number, s: number)
		local red, dark = Color3.fromRGB(170, 16, 20), Color3.fromRGB(40, 6, 8)
		glow(p, cx, cy, 34 * s, RED, 0.55)
		local function b(x, y, w, h, c, z, rot) return fr(p, cx + x * s, cy + y * s, w * s, h * s, c, z or 10, rot) end
		b(-18, -8, 36, 34, red); b(-18, -8, 36, 4, dark)
		b(-22, -22, 8, 18, dark, 9, -20); b(14, -22, 8, 18, dark, 9, 20)
		b(-28, -34, 5, 14, RED, 9, -30); b(23, -34, 5, 14, RED, 9, 30)
		b(-12, 2, 9, 4, Color3.fromRGB(255, 230, 80), 11); b(3, 2, 9, 4, Color3.fromRGB(255, 230, 80), 11)
		b(-8, 16, 16, 3, dark, 11); b(-4, 19, 8, 2, Color3.fromRGB(240, 220, 200), 11)
	end
	local function badgeIcon(p: Instance, cx: number, cy: number, n: number)
		glow(p, cx, cy, 44, GOLD, 0.65)
		for i = 1, math.min(3, n) do
			star(p, cx + (i - 2) * 20, cy + (i == 2 and -8 or 6), i == 2 and 34 or 24, 10)
		end
		for _, sp in { { -42, -20 }, { 40, -22 }, { 0, 30 } } do fr(p, cx + sp[1], cy + sp[2], 4, 4, WHITE, 11) end
	end
	local function snowIconBig(p: Instance, cx: number, cy: number, s: number)
		glow(p, cx, cy, 46 * s, ICE, 0.6)
		for _, r in { 0, 60, 120 } do
			fr(p, cx - 30 * s, cy - 2 * s, 60 * s, 4 * s, ICE, 10, r).BackgroundColor3 = ICE
			for _, sgn in { -1, 1 } do
				for _, d in { 14, 24 } do
					local ang = math.rad(r)
					local px_, py_ = cx + math.cos(ang) * d * s * sgn, cy + math.sin(ang) * d * s * sgn
					fr(p, px_ - 6 * s, py_ - 1.5 * s, 12 * s, 3 * s, WHITE, 11, r + 55)
					fr(p, px_ - 6 * s, py_ - 1.5 * s, 12 * s, 3 * s, WHITE, 11, r - 55)
				end
			end
		end
		fr(p, cx - 4 * s, cy - 4 * s, 8 * s, 8 * s, WHITE, 12, 45)
	end

	-- ---------- 1. CARBON ----------
	local carbonY = 10
	section("CARBON", carbonY + 12, Color3.fromRGB(255, 90, 90))
	local cb = card(126, carbonY + 40, 1020, 170, RED, Color3.fromRGB(20, 8, 8))
	carIcon(cb, 170, 90, 2.3)
	text(cb, "CARBON PASS", 34, Color3.fromRGB(255, 255, 255), 640, 34, { ZIndex = 12, Size = UDim2.fromOffset(500, 40) })
	text(cb, "RED-WHITE AURA AND EYES  -  [CarBon] TAG  -  CARBON TITLE", 13, Color3.fromRGB(255, 190, 190), 640, 72, { ZIndex = 12, Size = UDim2.fromOffset(640, 18) })
	text(cb, "+ CARBON CAR PET  (+22% SPEED   +22% BADGES)", 15, GOLD_TEXT, 640, 100, { ZIndex = 12, Size = UDim2.fromOffset(640, 20) })
	local carBuy = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(640, 142), Size = UDim2.fromOffset(240, 34), BackgroundColor3 = Color3.fromRGB(150, 18, 28), BorderSizePixel = 0, ZIndex = 12 }, cb)
	new("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, carBuy)
	local carBuyLbl = text(carBuy, "GET CARBON", 16, WHITE, 120, 17, { ZIndex = 13 })
	local function refreshCarbon()
		local own = player:GetAttribute("XVip") == true
		carBuyLbl.Text = own and "YOU HAVE CARBON" or "GET CARBON  -  R$"
	end
	player:GetAttributeChangedSignal("XVip"):Connect(refreshCarbon); refreshCarbon()
	cb.MouseButton1Click:Connect(function()
		sfx(CONFIG.ClickSoundId)
		if player:GetAttribute("XVip") == true then toast("YOU ALREADY HAVE CARBON") else promptRobux(2092239089) end
	end)

	-- ---------- 1b. BOOSTS: x2 SPEED / x2 BADGES (геймпассы) ----------
	section("BOOSTS", carbonY + 252, Color3.fromRGB(255, 205, 90))
	for i, spec in { { "x2 SPEED", "PassSpeed2", "PassSpeed2Id", "double your running speed" }, { "x2 BADGES", "PassBadge2", "PassBadge2Id", "double badges from every run" } } do
		local bc = card(126 + (i - 1) * 530, carbonY + 280, 490, 100, Color3.fromRGB(255, 190, 70))
		text(bc, spec[1], 28, WHITE, 245, 30, { ZIndex = 12, Size = UDim2.fromOffset(460, 34) })
		text(bc, spec[4], 12, Color3.fromRGB(230, 205, 160), 245, 56, { ZIndex = 12, Size = UDim2.fromOffset(460, 16) })
		local bl = text(bc, "", 15, GOLD_TEXT, 245, 80, { ZIndex = 12, Size = UDim2.fromOffset(460, 18) })
		local function refreshBoost()
			local id = workspace:GetAttribute(spec[3]) or 0
			bl.Text = player:GetAttribute(spec[2]) == true and "OWNED" or (id > 0 and "BUY  -  R$" or "COMING SOON")
		end
		player:GetAttributeChangedSignal(spec[2]):Connect(refreshBoost)
		workspace:GetAttributeChangedSignal(spec[3]):Connect(refreshBoost)
		refreshBoost()
		bc.MouseButton1Click:Connect(function()
			sfx(CONFIG.ClickSoundId)
			if player:GetAttribute(spec[2]) == true then toast("ALREADY OWNED") else promptRobux(workspace:GetAttribute(spec[3]) or 0) end
		end)
	end

	-- ---------- 2. CASES ----------
	local casesY = carbonY + 400
	section("CASES", casesY + 12)
	local overlay = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.25, BorderSizePixel = 0, ZIndex = 80, Visible = false, Active = true }, stage)
	local ovIcon = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(640, 300), Size = UDim2.fromOffset(200, 200), BackgroundTransparency = 1, ZIndex = 81 }, overlay)
	local ovTitle = text(overlay, "", 38, GOLD_TEXT, 640, 440, { ZIndex = 82, Size = UDim2.fromOffset(900, 50) })
	local ovSub = text(overlay, "", 18, Color3.fromRGB(220, 200, 170), 640, 490, { ZIndex = 82, Size = UDim2.fromOffset(900, 26) })
	local ovToken = 0
	local function reveal(tier: number, res: any)
		ovToken += 1
		local my = ovToken
		overlay.Visible = true
		ovTitle.Text, ovSub.Text = "", ""
		ovIcon:ClearAllChildren()
		crateIcon(ovIcon, 100, 100, 2.6, tier)
		for _ = 1, 14 do
			if ovToken ~= my then return end
			ovIcon.Rotation = (math.random() - 0.5) * 16
			task.wait(0.07)
		end
		ovIcon.Rotation = 0
		if ovToken ~= my then return end
		ovTitle.Text = string.upper(tostring(res.name))
		ovTitle.TextColor3 = res.dup and Color3.fromRGB(170, 160, 150) or GOLD_TEXT
		ovSub.Text = res.dup and ("DUPLICATE  -  +" .. tostring(res.refund) .. " BADGES BACK") or "NEW ITEM!  EQUIP IT IN SKINS > COSMETICS"
		task.delay(4.5, function() if ovToken == my then overlay.Visible = false end end)
	end
	overlay.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then ovToken += 1; overlay.Visible = false end
	end)

	local function extraRf(): RemoteFunction? return ReplicatedStorage:FindFirstChild("EvaKExtra") :: RemoteFunction? end
	local CASES_UI = {
		{ id = "rusty", name = "RUSTY CASE", badges = 600, tier = 1, accent = Color3.fromRGB(230, 130, 50), sub = "COMMON - RARE DROPS" },
		{ id = "cursed", name = "CURSED CASE", badges = 2500, tier = 2, accent = Color3.fromRGB(180, 70, 255), sub = "WINGS - EYE OF EVAK" },
		{ id = "evak", name = "EVAK CASE", robux = true, tier = 3, accent = Color3.fromRGB(255, 80, 60), sub = "BEST ODDS - ROBUX" },
	}
	for i, cs in CASES_UI do
		local c = card(126 + (i - 1) * 345, casesY + 40, 330, 210, cs.accent)
		crateIcon(c, 165, 70, 1.9, cs.tier)
		do   -- VIEW: покрутить кейс и посмотреть весь дроп в 3D
			local vb = new("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 8), Size = UDim2.fromOffset(64, 24), BackgroundColor3 = Color3.fromRGB(40, 30, 60), Text = "VIEW", Font = Enum.Font.Arcade, TextSize = 13, TextColor3 = GOLD_TEXT, ZIndex = 20 }, c)
			vb.MouseButton1Click:Connect(function() sfx(CONFIG.ClickSoundId); player:SetAttribute("EvaKPreview", "case:" .. cs.id .. ":" .. tostring(os.clock())) end)
		end
		text(c, cs.name, 20, GOLD_TEXT, 165, 118, { ZIndex = 12, Size = UDim2.fromOffset(310, 24) })
		text(c, cs.sub, 11, Color3.fromRGB(200, 175, 140), 165, 136, { ZIndex = 12, Size = UDim2.fromOffset(310, 16) })
		local price = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(165, 192), Size = UDim2.fromOffset(220, 26), BackgroundColor3 = Color3.fromRGB(48, 32, 14), BorderSizePixel = 0, ZIndex = 12 }, c)
		new("UIStroke", { Color = cs.accent, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, price)
		text(price, cs.badges and ("OPEN - " .. cs.badges .. " BADGES") or "OPEN - ROBUX", 14, GOLD_TEXT, 110, 15, { ZIndex = 13 })
		do   -- список дропа с шансами под карточкой
			local DR = {
				rusty = "Titles - Pins - Bronze/Silver/Gold frames - Aura - Lantern - Watch - Demon Eyes 4%",
				cursed = "Demon Eyes - Horns - Tail - Skull/Flame pins - Blood/Neon frames - Wings - Hellfire Aura 5% - Eclipse Pendant 4%",
				evak = "Devil Wings 22% - Hellfire Aura 18% - Eclipse Pendant - Eye of EvaK - Owner Key - Hellfire Frame - 666 title  (duplicate = badges back)",
			}
			local t = new("TextLabel", { Position = UDim2.fromOffset(6, 146), Size = UDim2.fromOffset(318, 32), BackgroundTransparency = 1, Text = "DROPS: " .. DR[cs.id], TextWrapped = true,
				TextSize = 10, Font = Enum.Font.Arcade, TextColor3 = Color3.fromRGB(215, 190, 150), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 12 }, c)
		end
		local busy = false
		c.MouseButton1Click:Connect(function()
			sfx(CONFIG.ClickSoundId)
			if busy then return end
			local rf = extraRf()
			if not rf then toast("CASES OFFLINE - EvaKExtra SERVER SCRIPT IS NOT RUNNING"); return end
			busy = true
			if cs.badges then
				local ok, res = pcall(function() return rf:InvokeServer("OpenCase", cs.id) end)
				if ok and type(res) == "table" and res.ok then task.spawn(reveal, cs.tier, res)
				else shake(c); toast(ok and type(res) == "table" and tostring(res.msg or "ERROR"):upper() or "SERVER ERROR") end
			else
				local ok, res = pcall(function() return rf:InvokeServer("Cases") end)
				local product = 0
				if ok and type(res) == "table" and res.cases then
					for _, k in res.cases do if k.id == cs.id then product = k.product or 0 end end
				end
				promptRobux(product)
			end
			busy = false
		end)
	end
	-- результат кейса, купленного за Robux, приходит от сервера отдельным событием
	task.spawn(function()
		local fx = ReplicatedStorage:WaitForChild("EvaKExtraFx", 30)
		if fx then
			(fx :: RemoteEvent).OnClientEvent:Connect(function(kind, a)
				if kind == "CaseWon" and type(a) == "table" then
					local tier = a.case == "evak" and 3 or (a.case == "cursed" and 2 or 1)
					task.spawn(reveal, tier, a)
				end
			end)
		end
	end)

	-- ---------- 3. DEVIL ----------
	local devilY = casesY + 280
	section("DEVIL ITEMS", devilY + 12, Color3.fromRGB(255, 80, 60))
	local dv = card(126, devilY + 40, 1020, 130, RED, Color3.fromRGB(22, 6, 6))
	hornsIcon(dv, 120, 70, 1.5)
	text(dv, "DEVIL SHOP", 30, Color3.fromRGB(255, 90, 70), 560, 36, { ZIndex = 12, Size = UDim2.fromOffset(500, 36) })
	text(dv, "HORNS  -  TAIL  -  HELLFIRE AURA  -  DEVIL WINGS  -  ECLIPSE PENDANT  -  TITLES   (CLICK, THEN PRESS VIEW TO SEE IT IN 3D)", 13, Color3.fromRGB(255, 190, 170), 560, 74, { ZIndex = 12, Size = UDim2.fromOffset(700, 18) })
	text(dv, "BOUGHT WITH BADGES  -  TAP TO OPEN", 13, GOLD_TEXT, 560, 100, { ZIndex = 12, Size = UDim2.fromOffset(500, 18) })
	dv.MouseButton1Click:Connect(function() sfx(CONFIG.ClickSoundId); player:SetAttribute("EvaKOpenDevil", os.clock()) end)

	-- ---------- 4. БЕЙДЖИ и СНЕЖИНКИ (в самом низу) ----------
	local function packs(list: any, y: number, label: string, snow: boolean)
		for i, pack in list do
			local col = snow and ICE or GOLD
			local c = card(126 + ((i - 1) % 3) * 345, y + 40 + ((i - 1) // 3) * 200, 330, 185, col)
			if snow then snowIconBig(c, 165, 58, 1.1) else badgeIcon(c, 165, 58, 3) end
			text(c, "+" .. tostring(snow and pack.Snow or pack.Badges), 30, GOLD_TEXT, 165, 112, { ZIndex = 12, Size = UDim2.fromOffset(310, 36) })
			text(c, label, 13, col, 165, 134, { ZIndex = 12 })
			local price = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(165, 161), Size = UDim2.fromOffset(200, 28), BackgroundColor3 = Color3.fromRGB(48, 32, 14), BorderSizePixel = 0, ZIndex = 12 }, c)
			new("UIStroke", { Color = GOLD, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, price)
			text(price, pack.Robux .. " ROBUX", 14, GOLD_TEXT, 100, 14, { ZIndex = 13 })
			c.MouseButton1Click:Connect(function() sfx(CONFIG.ClickSoundId); promptRobux(pack.Id) end)
		end
		return y + 40 + math.ceil(#list / 3) * 200
	end
	local function tiSection(tiY: number)   -- отдельная функция: у главного чанка почти исчерпан лимит локальных переменных
		section("TITLES & ACCESSORIES", tiY + 12)
		for i, t in { { "TITLES", "title", "Sinner - Believer - Hacker - 666 ..." }, { "ACCESSORIES", "item", "Aura - Wings - Eyes - Lantern - Horns ..." },
			{ "FRAMES", "frame", "Bronze - Gold - Horned - Angel - Halo ..." }, { "PINS", "pin", "Cross - Skull - Heart - Star - Moon ..." } } do
			local c = card(126 + (i - 1) * 258, tiY + 40, 246, 120, GOLD, Color3.fromRGB(20, 14, 8))
			text(c, t[1], 24, GOLD_TEXT, 123, 34, { ZIndex = 12, Size = UDim2.fromOffset(230, 32) })
			text(c, t[3], 11, Color3.fromRGB(210, 190, 160), 123, 74, { ZIndex = 12, Size = UDim2.fromOffset(230, 30) })
			text(c, "TAP TO OPEN", 12, GOLD_TEXT, 123, 100, { ZIndex = 12, Size = UDim2.fromOffset(230, 16) })
			c.MouseButton1Click:Connect(function() sfx(CONFIG.ClickSoundId); player:SetAttribute("EvaKCosWant", t[2]); player:SetAttribute("EvaKOpenCos", os.clock()) end)
		end
	end
	tiSection(devilY + 200)
	local badgesY = devilY + 200 + 190
	section("BADGES", badgesY + 12)
	local snowY = packs(CONFIG.Products, badgesY, "BADGES", false)
	section("SNOWFLAKES", snowY + 12, ICE)
	local endY = packs(CONFIG.SnowProducts, snowY, "SNOWFLAKES", true)
	text(badgesPage, "everything is added right after purchase", 11, Color3.fromRGB(170, 140, 100), 640, endY + 14, { ZIndex = 9, Size = UDim2.fromOffset(700, 16) })
	badgesPage.CanvasSize = UDim2.fromOffset(0, endY + 50)

	-- анимация бликов, пока магазин открыт
	RunService.Heartbeat:Connect(function()
		if not (s3.Visible and badgesPage.Visible) then return end
		local t = os.clock()
		for _, s in shines do
			local k = (t * 0.28 + s.off) % 2.2 - 0.3
			s.bar.Position = UDim2.fromOffset(k * (s.w + 100) - 60, -30)
		end
	end)
end
MarketplaceService.PromptProductPurchaseFinished:Connect(function(_, _, purchased)
	if not purchased then toast("PURCHASE CANCELLED") end
end)

local shopBack: CanvasGroup = s1
local shopBackBtn = makeButton(s3, 120, 626, 200, 50)
text(shopBackBtn, "BACK", 16, GOLD_TEXT, 100, 25, { ZIndex = 9 })
shopBackBtn.MouseButton1Click:Connect(function() sfx(CONFIG.ClickSoundId); go(shopBack) end)

openShop = function(tab: string)
	showTab(tab)
	badgesPage.CanvasPosition = (tab == "badges") and Vector2.new(0, 99999) or Vector2.zero   -- «+» у счётчиков открывает низ магазина (бейджи и снежинки)
	if current ~= s3 then shopBack = current end
	go(s3)
end
shopBtn1.MouseButton1Click:Connect(function() sfx(CONFIG.ClickSoundId); openShop("toys") end)
shopBtn2.MouseButton1Click:Connect(function() sfx(CONFIG.ClickSoundId); openShop("toys") end)

-- ============================================================
-- СЛОЖНОСТЬ (следующая открывается после прохождения предыдущей)
-- ============================================================
text(s4, "SELECT DIFFICULTY", 24, GOLD_TEXT, 420, 95, { Size = UDim2.fromOffset(600, 30), TextXAlignment = Enum.TextXAlignment.Left })
divider(s4, 300, 128, 360, 14)

local diffViews = {}
for i, d in CONFIG.Difficulties do
	local card = makeButton(s4, 120, 150 + (i - 1) * 68, 520, 62)
	new("Frame", { Size = UDim2.new(0, 5, 1, 0), BackgroundColor3 = d.Color, BorderSizePixel = 0, ZIndex = 9 }, card)
	local nameL = text(card, d.Name, 22, d.Color, 188, 26, { ZIndex = 9, Size = UDim2.fromOffset(320, 28), TextXAlignment = Enum.TextXAlignment.Left })
	local descL = text(card, d.Desc, 11, Color3.fromRGB(190, 165, 130), 188, 52, { ZIndex = 9, Size = UDim2.fromOffset(320, 16), TextXAlignment = Enum.TextXAlignment.Left })
	local status = text(card, "", 11, GOLD, 365, 36, { ZIndex = 9, Size = UDim2.fromOffset(230, 16), TextXAlignment = Enum.TextXAlignment.Right })
	local lock = new("Frame", { Position = UDim2.fromOffset(486, 20), Size = UDim2.fromOffset(24, 32), BackgroundTransparency = 1, ZIndex = 9 }, card)
	local lc = Color3.fromRGB(170, 140, 100)
	px(lock, 5, 0, 14, 3, lc); px(lock, 5, 0, 3, 12, lc); px(lock, 16, 0, 3, 12, lc)
	px(lock, 0, 11, 24, 18, lc); px(lock, 10, 16, 4, 7, Color3.fromRGB(30, 20, 14))
	diffViews[i] = { name = nameL, desc = descL, status = status, lock = lock, d = d }

	card.MouseButton1Click:Connect(function()
		sfx(CONFIG.ClickSoundId)
		if not isUnlocked(i) then
			shake(card)
			toast("CLEAR " .. CONFIG.Difficulties[i - 1].Name .. " FIRST")
			return
		end
		selectedDiff = d.Id
		diffLabel.Text = "DIFFICULTY: " .. d.Name
		diffLabel.TextColor3 = d.Color
		go(s2)
	end)
end
local function refreshDiff()
	local cleared = clearedSet()
	for i, v in diffViews do
		local open = isUnlocked(i)
		v.lock.Visible = not open
		v.name.TextTransparency = open and 0 or 0.55
		v.desc.TextTransparency = open and 0 or 0.55
		if not open then
			v.status.Text = "CLEAR " .. CONFIG.Difficulties[i - 1].Name .. " TO UNLOCK"
			v.status.TextColor3 = Color3.fromRGB(170, 140, 100)
		elseif cleared[v.d.Id] then
			v.status.Text = "CLEARED"
			v.status.TextColor3 = GOLD
		else
			v.status.Text = ""
		end
	end
end
player:GetAttributeChangedSignal("Cleared"):Connect(refreshDiff)
refreshDiff()
local diffBack = makeButton(s4, 120, 556, 254, 50)
text(diffBack, "BACK", 16, GOLD_TEXT, 127, 25, { ZIndex = 9 })
diffBack.MouseButton1Click:Connect(function() sfx(CONFIG.ClickSoundId); go(s1) end)

-- ============================================================
-- ИНВЕНТАРЬ (3D-игрушки, одну можно экипировать)
-- ============================================================
text(s5, "INVENTORY", 40, GOLD_TEXT, 420, 62, { Size = UDim2.fromOffset(600, 50), TextXAlignment = Enum.TextXAlignment.Left })
divider(s5, 300, 100, 360, 0)
local invPanel = new("Frame", { Position = UDim2.fromOffset(100, 126), Size = UDim2.fromOffset(1080, 450), BackgroundColor3 = Color3.fromRGB(14, 9, 6),
	BackgroundTransparency = 0.2, BorderSizePixel = 0, ZIndex = 5 }, s5)
new("UIStroke", { Color = GOLD_DIM, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, invPanel)
end
do   -- блок: освобождает локальные переменные (лимит Luau 200)
local invTeam = text(s5, "", 15, GOLD, 960, 76, { Size = UDim2.fromOffset(300, 20), TextXAlignment = Enum.TextXAlignment.Right })
local invEmpty = text(s5, "your inventory is empty - buy toys in the shop", 14, Color3.fromRGB(170, 140, 100), 640, 340, { ZIndex = 9, Size = UDim2.fromOffset(700, 20) })

local invViews = {}
for _, toy in CONFIG.Toys do
	local card, setActive = makeButton(s5, 126, 184, 240, 180)
	local rc = CONFIG.Rarities[toy.Rarity] or GOLD
	new("Frame", { Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = rc, BorderSizePixel = 0, ZIndex = 9 }, card)
	text(card, string.upper(toy.Rarity), 11, rc, 120, 18, { ZIndex = 9 })
	local view = toyView(card, toy, 120, 64, 210, 100, function() return s5.Visible and card.Visible end, card)
	text(card, toy.Name, 14, GOLD_TEXT, 120, 112, { ZIndex = 9, Size = UDim2.fromOffset(232, 18) })
	text(card, perkText(toy), 10, Color3.fromRGB(190, 165, 130), 120, 132, { ZIndex = 9, Size = UDim2.fromOffset(232, 14) })
	local status = text(card, "", 12, GOLD_TEXT, 120, 156, { ZIndex = 9, Size = UDim2.fromOffset(232, 18) })
	card.Visible = false
	table.insert(invViews, { toy = toy, card = card, setActive = setActive, status = status })

	card.MouseButton1Click:Connect(function()
		sfx(CONFIG.ClickSoundId)
		local ok, msg
		local eqN, tm = teamCount(toy.Id), #teamList()
		if eqN > 0 and (eqN >= toyCount(toy.Id) or tm >= 3) then
			ok, msg = invoke("Unequip", toy.Id)   -- снять одну копию
		else
			ok, msg = invoke("EquipToy", toy.Id)  -- надеть ещё одну (до 3 питомцев)
		end
		if ok then
			view.pop = os.clock()
			burst(card, rc)
		else
			shake(card)
			toast(failText(msg))
		end
	end)
end
local function refreshInv()
	local owned = ownedToys()
	local k = 0
	for _, v in invViews do
		local has = owned[v.toy.Id] == true
		v.card.Visible = has
		if has then
			v.card.Position = UDim2.fromOffset(126 + (k % 4) * 256, 184 + (k // 4) * 194)
			k += 1
			local en, tot = teamCount(v.toy.Id), toyCount(v.toy.Id)
			local on = en > 0
			v.setActive(on)
			v.status.Text = (on and ("EQUIPPED " .. en .. "/" .. tot) or "CLICK TO EQUIP") .. "   x" .. tot
			v.status.TextColor3 = on and GOLD or Color3.fromRGB(170, 140, 100)
		end
	end
	invEmpty.Visible = (k == 0)
	invTeam.Text = "TEAM " .. #teamList() .. " / 3  (click to equip / unequip)"
end
for _, attr in { "OwnedToys", "EquippedToy", "ToyCounts" } do player:GetAttributeChangedSignal(attr):Connect(refreshInv) end
refreshInv()

local invBack = makeButton(s5, 120, 610, 200, 50)
text(invBack, "BACK", 16, GOLD_TEXT, 100, 25, { ZIndex = 9 })
invBack.MouseButton1Click:Connect(function() sfx(CONFIG.ClickSoundId); go(s1) end)
local invShop = makeButton(s5, 332, 610, 200, 50)
text(invShop, "SHOP", 16, GOLD_TEXT, 100, 25, { ZIndex = 9 })
invShop.MouseButton1Click:Connect(function() sfx(CONFIG.ClickSoundId); openShop("toys") end)
invBtn.MouseButton1Click:Connect(function() sfx(CONFIG.ClickSoundId); refreshInv(); go(s5) end)

-- ============================================================
-- TEAM PLAY: парти (создать / зайти), аватарки игроков в кружках, "только для друзей", до 5 человек
-- ============================================================
text(s6, "TEAM PLAY", 40, GOLD_TEXT, 420, 62, { Size = UDim2.fromOffset(600, 50), TextXAlignment = Enum.TextXAlignment.Left })
divider(s6, 300, 100, 360, 0)
local listPage = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 6 }, s6)
local lobbyPage = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 6, Visible = false }, s6)
local myLobby: any = nil
local MAXP = 5

local function thumb(uid: number): string
	return string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", uid)
end
-- круглая аватарка игрока
local function avatarCircle(parent: Instance, size: number, x: number, y: number)
	local f = new("Frame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(size, size), BackgroundColor3 = Color3.fromRGB(34, 24, 16), BorderSizePixel = 0, ZIndex = 8 }, parent)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, f)
	local stroke = new("UIStroke", { Color = GOLD_DIM, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, f)
	local img = new("ImageLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = "", ZIndex = 9 }, f)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, img)
	return f, img, stroke
end
local function fillAvatars(avs, members)
	for k, a in avs do
		local m = members[k]
		a.img.Image = m and thumb(m.UserId) or ""
		a.f.BackgroundTransparency = m and 0 or 0.55
		a.stroke.Color = m and GOLD or GOLD_DIM
		a.stroke.Transparency = m and 0 or 0.45
	end
end

-- список всех парти
local emptyLbl = text(listPage, "no parties yet - create one", 13, Color3.fromRGB(170, 140, 100), 380, 300, { Size = UDim2.fromOffset(500, 20) })
local lobbyRows = {}
for i = 1, 5 do
	local row = makeButton(listPage, 120, 130 + (i - 1) * 64, 520, 58)
	row.Visible = false
	local avs = {}
	for k = 1, MAXP do
		local f, img, stroke = avatarCircle(row, 34, 12 + (k - 1) * 38, 12)
		avs[k] = { f = f, img = img, stroke = stroke }
	end
	local nameL = text(row, "", 15, GOLD_TEXT, 372, 19, { ZIndex = 9, Size = UDim2.fromOffset(300, 20), TextXAlignment = Enum.TextXAlignment.Left })
	local infoL = text(row, "", 12, GOLD, 372, 40, { ZIndex = 9, Size = UDim2.fromOffset(300, 16), TextXAlignment = Enum.TextXAlignment.Left })
	lobbyRows[i] = { btn = row, avs = avs, name = nameL, info = infoL, id = 0 }
end

local applyLobbyState: (any) -> ()
local function refreshLobbies()
	local ok, msg, res = invoke("LobbyList")
	if not ok or not res then
		if msg ~= "" then toast(failText(msg)) end
		return
	end
	local list = res.lobbies or {}
	emptyLbl.Visible = (#list == 0)
	for i, r in lobbyRows do
		local l = list[i]
		r.btn.Visible = (l ~= nil)
		if l then
			r.id = l.Id
			r.name.Text = string.upper(l.HostName) .. "'S PARTY"
			r.info.Text = string.upper(l.Difficulty) .. "   " .. l.Count .. "/" .. (l.Max or MAXP) .. (l.FriendsOnly and "   FRIENDS" or "")
			fillAvatars(r.avs, l.Members or {})
		end
	end
end
for _, r in lobbyRows do
	r.btn.MouseButton1Click:Connect(function()
		sfx(CONFIG.ClickSoundId)
		local ok, msg, res = invoke("LobbyJoin", r.id)
		if ok and res and res.state then applyLobbyState(res.state) else toast(failText(msg)); refreshLobbies() end
	end)
end

local createBtn = makeButton(listPage, 120, 462, 254, 48)
text(createBtn, "CREATE PARTY", 15, GOLD_TEXT, 127, 24, { ZIndex = 9 })
local refreshBtn = makeButton(listPage, 386, 462, 254, 48)
text(refreshBtn, "REFRESH", 15, GOLD_TEXT, 127, 24, { ZIndex = 9 })
local teamBack = makeButton(listPage, 120, 518, 520, 46)
text(teamBack, "BACK", 16, GOLD_TEXT, 260, 23, { ZIndex = 9 })
createBtn.MouseButton1Click:Connect(function()
	sfx(CONFIG.ClickSoundId)
	local ok, msg, res = invoke("LobbyCreate", { Difficulty = selectedDiff, FriendsOnly = false })
	if ok and res and res.state then applyLobbyState(res.state) else toast(failText(msg)) end
end)
refreshBtn.MouseButton1Click:Connect(function() sfx(CONFIG.ClickSoundId); refreshLobbies() end)
teamBack.MouseButton1Click:Connect(function() sfx(CONFIG.ClickSoundId); go(s1) end)

-- внутри парти
local lobbyTitle = text(lobbyPage, "", 22, GOLD_TEXT, 420, 146, { Size = UDim2.fromOffset(600, 28), TextXAlignment = Enum.TextXAlignment.Left })
local slotAv, slotName = {}, {}
for i = 1, MAXP do
	local x = 120 + (i - 1) * 109
	local f, img, stroke = avatarCircle(lobbyPage, 84, x, 176)
	text(f, "+", 30, GOLD_DIM, 42, 42, { ZIndex = 8, Size = UDim2.fromOffset(84, 36) })
	slotAv[i] = { f = f, img = img, stroke = stroke }
	slotName[i] = text(lobbyPage, "", 11, GOLD_TEXT, x + 42, 276, { ZIndex = 9, Size = UDim2.fromOffset(104, 16) })
end
local lobbyDiffBtn = makeButton(lobbyPage, 120, 304, 520, 46)
local lobbyDiffLbl = text(lobbyDiffBtn, "", 14, GOLD_TEXT, 260, 23, { ZIndex = 9, Size = UDim2.fromOffset(500, 20) })
local friendsBtn = makeButton(lobbyPage, 120, 358, 520, 46)
local friendsLbl = text(friendsBtn, "", 14, GOLD_TEXT, 260, 23, { ZIndex = 9, Size = UDim2.fromOffset(500, 20) })
local countLbl = text(lobbyPage, "", 12, Color3.fromRGB(190, 160, 120), 380, 424, { Size = UDim2.fromOffset(500, 18) })
local startBtn = makeButton(lobbyPage, 120, 446, 520, 56, true)
text(startBtn, "START", 18, GOLD_TEXT, 260, 28, { ZIndex = 9 })
local waitLbl = text(lobbyPage, "waiting for the host to start...", 13, Color3.fromRGB(190, 160, 120), 380, 474, { Size = UDim2.fromOffset(500, 20) })
local leaveBtn = makeButton(lobbyPage, 120, 514, 520, 46)
text(leaveBtn, "LEAVE PARTY", 15, GOLD_TEXT, 260, 23, { ZIndex = 9 })

applyLobbyState = function(state)
	myLobby = state
	listPage.Visible = (state == nil)
	lobbyPage.Visible = (state ~= nil)
	if not state then return end
	lobbyTitle.Text = string.upper(state.HostName) .. "'S PARTY"
	lobbyDiffLbl.Text = "DIFFICULTY: " .. string.upper(state.Difficulty) .. (state.IsHost and "  (CLICK TO CHANGE)" or "")
	friendsLbl.Text = "FRIENDS ONLY: " .. (state.FriendsOnly and "ON" or "OFF") .. (state.IsHost and "  (CLICK TO CHANGE)" or "")
	fillAvatars(slotAv, state.Members)
	for i = 1, MAXP do
		local m = state.Members[i]
		slotName[i].Text = m and (string.upper(string.sub(m.Name, 1, 12)) .. (i == 1 and "\nHOST" or "")) or ""
		slotName[i].Size = UDim2.fromOffset(104, 30)
	end
	countLbl.Text = #state.Members .. " / " .. (state.Max or MAXP) .. " PLAYERS"
	startBtn.Visible = state.IsHost
	waitLbl.Visible = not state.IsHost
end

lobbyDiffBtn.MouseButton1Click:Connect(function()
	if not (myLobby and myLobby.IsHost) then return end
	sfx(CONFIG.ClickSoundId)
	local idx = 1
	for i, d in CONFIG.Difficulties do
		if d.Id == myLobby.Difficulty then idx = i end
	end
	local n = #CONFIG.Difficulties
	for step = 1, n do
		local j = (idx - 1 + step) % n + 1
		do
			local ok, msg, res = invoke("LobbySetDiff", CONFIG.Difficulties[j].Id)
			if ok and res and res.state then applyLobbyState(res.state); return end   -- закрытые сложности пропускаем
		end
	end
end)
friendsBtn.MouseButton1Click:Connect(function()
	if not (myLobby and myLobby.IsHost) then return end
	sfx(CONFIG.ClickSoundId)
	local ok, msg, res = invoke("LobbySetFriends", not myLobby.FriendsOnly)
	if ok and res and res.state then applyLobbyState(res.state) else toast(failText(msg)) end
end)
startBtn.MouseButton1Click:Connect(function()
	sfx(CONFIG.ClickSoundId)
	local ok, msg = invoke("LobbyStart")
	if not ok then toast(failText(msg)) end
end)
leaveBtn.MouseButton1Click:Connect(function()
	sfx(CONFIG.ClickSoundId)
	invoke("LobbyLeave")
	applyLobbyState(nil)
end)

-- события лобби (подключаем, как только сервер появился)
local lobbyHooked = false
local function hookLobbyEvent()
	if lobbyHooked then return end
	lobbyEvent = lobbyEvent or ReplicatedStorage:FindFirstChild("EvaKLobby")
	if not lobbyEvent then return end
	lobbyHooked = true
	lobbyEvent.OnClientEvent:Connect(function(kind, payload)
		if kind == "State" then
			applyLobbyState(payload)
		elseif kind == "Start" then
			beginFall(payload, true)
		end
	end)
end
hookLobbyEvent()

teamBtn.MouseButton1Click:Connect(function()
	sfx(CONFIG.ClickSoundId)
	shopRemote = shopRemote or ReplicatedStorage:FindFirstChild("EvaKShop")
	if not shopRemote then
		warn("[EvaK] TEAM PLAY не работает: положи EvaKServer.server.lua в ServerScriptService (Script)")
		toast("TEAM PLAY: ADD EvaKServer SCRIPT")
		return
	end
	hookLobbyEvent()
	refreshLobbies()
	go(s6)
end)
task.spawn(function()
	while gui.Parent do
		task.wait(3)
		if current == s6 and listPage.Visible then refreshLobbies() end
	end
end)

end
-- ============================================================
-- FALL INTO PURGATORY: затемнение, полосы света, старт игры
-- ============================================================
-- КУРСОР-ЩУПАЛЬЦЕ теперь в отдельном EvaKCursor.client.lua; здесь только заглушки
applyCursor = function(on: boolean)
	player:SetAttribute("EvaKCursorOn", on)
end

-- ============================================================
-- ИГРА: HUD с бейджами, фонарь, батончик (E = съесть, бежишь быстрее)
-- ============================================================
local function startGameplay()
	local items = {}
	for id in string.gmatch(player:GetAttribute("RunItems") or "", "[^,]+") do items[id] = true end

	local hud = new("ScreenGui", { Name = "EvaKHud", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 50 }, playerGui)
	local diffName = string.upper(player:GetAttribute("Difficulty") or "")
	if diffName ~= "" then
		text(hud, "DIFFICULTY: " .. diffName, 12, GOLD, 100, 36, { Size = UDim2.fromOffset(200, 18) })
	end

	-- бейджи сверху справа
	local box = new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 24), Size = UDim2.fromOffset(200, 30), BackgroundTransparency = 1 }, hud)
	local lbl = new("TextLabel", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromOffset(176, 15), Size = UDim2.fromOffset(150, 26),
		BackgroundTransparency = 1, Text = tostring(getBadges()), TextSize = 22, TextColor3 = GOLD_TEXT, Font = CONFIG.Font, TextXAlignment = Enum.TextXAlignment.Right }, box)
	star(box, 190, 15, 18, 3)
	player:GetAttributeChangedSignal("Badges"):Connect(function() lbl.Text = tostring(getBadges()) end)

	-- скорость: базовая * бонус игрушки * буст батончика
	local boost = 1
	local moveRemote = ReplicatedStorage:FindFirstChild("EvaKMove")   -- есть сервер: скорость считает он
	local function applySpeed()
		if moveRemote then return end
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = player:GetAttribute("EvaKAdminSpeed") or (16 * (player:GetAttribute("SpeedMult") or 1) * boost) end
	end
	local function setupCharacter(char: Model)
		char:WaitForChild("Humanoid")
		applySpeed()
		if items.LANTERN then
			local hrp = char:WaitForChild("HumanoidRootPart")
			if not hrp:FindFirstChild("EvaKLantern") then
				new("PointLight", { Name = "EvaKLantern", Brightness = 1.6, Range = 28, Color = Color3.fromRGB(255, 190, 110) }, hrp)
			end
		end
	end
	player.CharacterAdded:Connect(setupCharacter)
	if player.Character then task.spawn(setupCharacter, player.Character) end

	-- экипированная игрушка парит рядом с персонажем (видна только тебе)
	local followers: {any} = {}
	local FOLLOW_POS = { Vector3.new(2.4, 1.8, 0.6), Vector3.new(-2.4, 2.2, 0.6), Vector3.new(0, 3.6, 1.4) }
	local function buildFollower()
		for _, f in followers do f.model:Destroy() end
		table.clear(followers)
		for i, id in teamList() do
			local toy = toyById(id)
			if toy and i <= 3 then table.insert(followers, makeToy(player.Character or workspace, toy, 0.28)) end
		end
	end
	buildFollower()
	player:GetAttributeChangedSignal("EquippedToy"):Connect(buildFollower)
	RunService.RenderStepped:Connect(function()
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if #followers > 0 and hrp then
			local t = os.clock()
			for i, f in followers do
				local p = FOLLOW_POS[i]
				f.render(hrp.CFrame * CFrame.new(p.X, p.Y + math.sin(t * 2 + i) * 0.25, p.Z) * CFrame.Angles(0, t * 0.8 + i, 0), t)
			end
		end
	end)

	-- слоты предметов (восьмиугольные, как в DOORS)
	local function octagon(parent: Instance, cx: number, cy: number, size: number, c: number, color: Color3, tr: number, z: number): Frame
		local f = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, cy), Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, ZIndex = z }, parent)
		local function rect(w: number, h: number, x: number, y: number, rot: number?)
			new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), Rotation = rot or 0,
				BackgroundColor3 = color, BackgroundTransparency = tr, BorderSizePixel = 0, ZIndex = z }, f)
		end
		rect(size, size - 2 * c, size / 2, size / 2)
		rect(size - 2 * c, size, size / 2, size / 2)
		local d = c * 1.4143
		for _, sx in { -1, 1 } do
			for _, sy in { -1, 1 } do rect(d, d, size / 2 + sx * (size / 2 - c), size / 2 + sy * (size / 2 - c), 45) end
		end
		return f
	end
	local defs = {}
	if items.LANTERN then table.insert(defs, { id = "LANTERN", icon = "lantern", key = Enum.KeyCode.F, name = "LANTERN" }) end
	if items.BAR then table.insert(defs, { id = "BAR", icon = "bar", key = CONFIG.BarBoost.Key, name = "CANDY BAR" }) end
	for i, def in defs do
		local root = new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, (i - (#defs + 1) / 2) * 100, 1, -16), Size = UDim2.fromOffset(90, 112), BackgroundTransparency = 1 }, hud)
		local glow = octagon(root, 45, 49, 98, 19, GOLD, 0.85, 1)
		octagon(root, 45, 49, 86, 15, GOLD_DIM, 0, 2)
		octagon(root, 45, 49, 80, 13, Color3.fromRGB(22, 15, 11), 0, 3)
		octagon(root, 45, 49, 70, 11, Color3.fromRGB(44, 31, 21), 0, 4)
		octagon(root, 45, 49, 62, 9, Color3.fromRGB(24, 17, 12), 0, 5)
		local ic = drawIcon(root, def.icon, 45, 49)
		new("UIScale", { Scale = 0.62 }, ic)
		ic.ZIndex = 8
		octagon(root, 14, 14, 26, 7, GOLD_DIM, 0, 9)
		octagon(root, 14, 14, 21, 5, Color3.fromRGB(22, 15, 11), 0, 10)
		new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(14, 14), Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1,
			Text = def.key.Name, TextSize = 12, TextColor3 = GOLD_TEXT, Font = CONFIG.Font, ZIndex = 11 }, root)
		new("TextLabel", { Position = UDim2.fromOffset(-10, 98), Size = UDim2.fromOffset(110, 14), BackgroundTransparency = 1,
			Text = def.name, TextSize = 11, TextColor3 = GOLD_TEXT, Font = CONFIG.Font, ZIndex = 11 }, root)
		local status = new("TextLabel", { Position = UDim2.fromOffset(0, 70), Size = UDim2.fromOffset(90, 14), BackgroundTransparency = 1,
			Text = (def.id == "LANTERN") and "ON" or "READY", TextSize = 11, TextColor3 = GOLD, Font = CONFIG.Font, ZIndex = 11 }, root)
		local btn = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 12 }, root)

		local used = false
		local function activate()
			if def.id == "LANTERN" then
				local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				local l = hrp and hrp:FindFirstChild("EvaKLantern")
				if l then
					l.Enabled = not l.Enabled
					status.Text = l.Enabled and "ON" or "OFF"
					status.TextColor3 = l.Enabled and GOLD or GOLD_DIM
					tw(glow, 0.2, { Size = UDim2.fromOffset(l.Enabled and 98 or 90, l.Enabled and 98 or 90) })
				end
			elseif not used then
				used = true
				if moveRemote then moveRemote:FireServer("Bar") end
				pcall(function() player:SetAttribute("EvaKBarUsed", true) end)
				boost = CONFIG.BarBoost.Mult
				applySpeed()
				status.Text = "FASTER!"
				task.delay(CONFIG.BarBoost.Seconds, function()
					boost = 1
					applySpeed()
					status.Text = "EMPTY"
					status.TextColor3 = GOLD_DIM
					ic.Visible = false
				end)
			end
		end
		btn.MouseButton1Click:Connect(activate)
		UIS.InputBegan:Connect(function(input, processed)
			if not processed and input.KeyCode == def.key then activate() end
		end)
	end
end

local overlay = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 50 }, gui)

beginFall = function(difficulty: string, team: boolean?)
	if busy then
		if not team then return end
		local waited = 0
		while busy and waited < 3 do waited += task.wait() end
	end
	busy = true

	local chosen = {}
	for _, it in CONFIG.Items do
		if selected[it.Id] then table.insert(chosen, it.Id) end
	end
	local okRun, runMsg = invoke("StartRun", { Items = chosen, Difficulty = difficulty, Team = team == true })
	if not okRun then
		toast(failText(runMsg))
		busy = false
		return
	end

	-- ===== СЦЕНА ПАДЕНИЯ =====
	-- вспышка -> персонаж кувыркается в свете -> свет гаснет, полосы летят вверх
	-- -> чёрный -> серая дымка -> открывается игра
	stage.Visible = false
	overlay.BackgroundColor3 = Color3.fromRGB(206, 198, 178)
	overlay.BackgroundTransparency = 0.05
	tw(overlay, 0.8, { BackgroundTransparency = 1 })
	tw(vp, 0.6, { Position = UDim2.fromScale(0.72, 0.46) })
	if music then tw(music, 3, { Volume = 0 }) end
	raySpeed = 40
	fallU = 0

	local fallDur, blackDur = 2.4, 1.0
	local streakLayer = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 20 }, gui)
	task.spawn(function()
		local st = os.clock()
		while os.clock() - st < fallDur + blackDur do
			local k = (os.clock() - st) / (fallDur + blackDur)
			local x = rng:NextNumber()
			local f = new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, 1.12),
				Size = UDim2.fromOffset(rng:NextInteger(4, 9), rng:NextInteger(40, 130)), Rotation = rng:NextNumber(-14, 14),
				BackgroundColor3 = Color3.fromRGB(255, 205, 130), BackgroundTransparency = 0.45 + 0.4 * k, BorderSizePixel = 0,
			}, streakLayer)
			new("UICorner", { CornerRadius = UDim.new(1, 0) }, f)
			tw(f, rng:NextNumber(0.45, 0.9), { Position = UDim2.fromScale(x, -0.15) }, Enum.EasingStyle.Linear).Completed:Once(function() f:Destroy() end)
			task.wait(0.04)
		end
	end)

	task.delay(0.4, function() tw(dim, 1.9, { BackgroundTransparency = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In) end)
	local st = os.clock()
	while os.clock() - st < fallDur do
		fallU = (os.clock() - st) / fallDur
		task.wait()
	end
	fallU = 1
	task.wait(blackDur)

	bgConn:Disconnect()
	bg:Destroy()
	streakLayer:Destroy()

	-- тёмный экран + вступительный текст; пока он идёт, карта уже строится за чёрным
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0
	player:SetAttribute("IntroDone", true)
	startGameplay()

	do   -- 3D-сцена: отель EvaK Hotel, персонаж заходит, дверь захлопывается (EvaKHotelIntro.client.lua)
		if player:GetAttribute("EvaKHotelReady") then
			player:SetAttribute("EvaKHotelDone", nil)
			player:SetAttribute("EvaKPlayHotel", os.clock())
			local hw = 0
			while not player:GetAttribute("EvaKHotelDone") and hw < 60 do hw += task.wait(0.1) end
		end
	end

	local storyLines = {
		"You only wanted a quiet night...",
		"but you checked into the wrong hotel.",
		"A hotel that never lets its guests leave.",
		"The halls are alive, and they know your name.",
		"Now monsters fly after you, and they want to kill you.",
	}
	if difficulty == "newyear" then
		storyLines = {
			"You wanted to send a letter to Santa...",
			"but it went to the wrong address.",
			"Now its monsters are flying after you",
			"to deliver you your GIFT.",
			"Run before they hand it over.",
		}
	end
	local storyGui = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 200 }, gui)
	local storyLabels = {}
	for i, line in storyLines do
		local last = i == #storyLines
		local l = new("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, (i - 3) * 46), Size = UDim2.fromOffset(1000, 40),
			BackgroundTransparency = 1, Font = Enum.Font.Arcade, TextSize = last and 24 or 28, Text = line, TextTransparency = 1, ZIndex = 201,
			TextColor3 = (i == 2 or i == 4) and Color3.fromRGB(210, 40, 36) or Color3.fromRGB(235, 220, 190),
		}, storyGui)
		storyLabels[i] = l
	end
	task.wait(0.6)
	for _, l in storyLabels do
		tw(l, 0.9, { TextTransparency = 0 })
		task.wait(1.7)
	end
	local waited = 0   -- ждём, пока сервер построит карту и бросит игрока
	while not player:GetAttribute("InMap") and waited < 10 do waited += task.wait(0.2) end
	task.wait(1.2)
	for _, l in storyLabels do tw(l, 1.0, { TextTransparency = 1 }) end
	task.wait(1.1)
	do   -- «GOOD LUCK»: открывается глаз, зрачок бегает, потом глаз медленно закрывается
		local eye = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.4), Size = UDim2.fromOffset(340, 150), BackgroundTransparency = 1, ZIndex = 202 }, storyGui)
		local sclera = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(226, 214, 200), BorderSizePixel = 0, ZIndex = 202 }, eye)
		new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, sclera)
		new("UIStroke", { Color = Color3.fromRGB(90, 12, 14), Thickness = 4 }, sclera)
		new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(150, 120, 110), Color3.fromRGB(240, 232, 220), Color3.fromRGB(150, 120, 110)) }, sclera)
		local iris = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(112, 112), BackgroundColor3 = Color3.fromRGB(196, 22, 24), BorderSizePixel = 0, ZIndex = 203 }, sclera)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, iris)
		new("UIStroke", { Color = Color3.fromRGB(60, 4, 6), Thickness = 3 }, iris)
		new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(255, 90, 60), Color3.fromRGB(120, 6, 10)), Rotation = 45 }, iris)
		local pupil = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(20, 96), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 204 }, iris)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, pupil)
		new("Frame", { Position = UDim2.fromOffset(22, 18), Size = UDim2.fromOffset(18, 12), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.25, BorderSizePixel = 0, ZIndex = 205 }, iris)
		-- веки: чёрные, закрывают глаз (фон чёрный), раздвигаются
		local lidT = new("Frame", { Size = UDim2.new(1.2, 0, 0.52, 0), Position = UDim2.fromScale(-0.1, -0.02), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 210 }, eye)
		local lidB = new("Frame", { Size = UDim2.new(1.2, 0, 0.52, 0), Position = UDim2.fromScale(-0.1, 0.5), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 210 }, eye)
		task.wait(0.8)
		tw(lidT, 1.6, { Position = UDim2.fromScale(-0.1, -0.62) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		tw(lidB, 1.6, { Position = UDim2.fromScale(-0.1, 1.06) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		task.wait(1.7)
		for _, pos in { UDim2.fromScale(0.3, 0.46), UDim2.fromScale(0.7, 0.55), UDim2.fromScale(0.45, 0.4), UDim2.fromScale(0.5, 0.5) } do
			tw(iris, 0.28, { Position = pos }, Enum.EasingStyle.Quad)
			task.wait(0.5)
		end
		tw(pupil, 0.9, { Size = UDim2.fromOffset(10, 100) })
		local gl = new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.68), Size = UDim2.fromOffset(700, 60), BackgroundTransparency = 1,
			Font = Enum.Font.Arcade, TextSize = 48, Text = "GOOD LUCK", TextColor3 = Color3.fromRGB(210, 30, 28), TextTransparency = 1, ZIndex = 202 }, storyGui)
		tw(gl, 1.0, { TextTransparency = 0 })
		task.wait(2.6)
		tw(gl, 0.8, { TextTransparency = 1 })
		tw(lidT, 1.0, { Position = UDim2.fromScale(-0.1, -0.02) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tw(lidB, 1.0, { Position = UDim2.fromScale(-0.1, 0.5) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.wait(1.2)
	end
	storyGui:Destroy()
	setControls(true)
	do   -- смотрим вперёд (по ходу карты), а не назад
		local cam = workspace.CurrentCamera
		local t0 = os.clock()
		local RS = game:GetService("RunService")
		RS:BindToRenderStep("EvaKFaceFwd", Enum.RenderPriority.Camera.Value + 2, function()
			if os.clock() - t0 > 0.7 or not cam then RS:UnbindFromRenderStep("EvaKFaceFwd") return end
			local p = cam.CFrame.Position
			cam.CFrame = CFrame.lookAt(p, p + Vector3.new(0, -0.12, 1))
		end)
	end
	tw(overlay, 3.0, { BackgroundTransparency = 1 }, Enum.EasingStyle.Sine).Completed:Wait()
	if music then music:Destroy() end
	toyConn:Disconnect()
	gui:Destroy()
end

fallBtn.MouseButton1Click:Connect(function() sfx(CONFIG.ClickSoundId); beginFall(selectedDiff, false) end)

local function setupNewYear()   -- в функции, чтобы не упереться в лимит локальных переменных
-- ============================================================
-- NEW YEAR: красная кнопка, экран ивента (10 разных шаров), снежинки, скины за снежинки
-- ============================================================
local NY_RED, NY_WHITE = Color3.fromRGB(190, 26, 34), Color3.fromRGB(250, 246, 240)
local NY_ICE = Color3.fromRGB(150, 225, 255)
local SoundServiceNY = game:GetService("SoundService")

local function snowIcon(parent: Instance, cx: number, cy: number, s: number, z: number?, col: Color3?)
	local f = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, cy), Size = UDim2.fromOffset(s, s), BackgroundTransparency = 1, ZIndex = z or 10 }, parent)
	for _, r in { 0, 60, 120 } do
		new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, 0, 0, math.max(2, s * 0.14)),
			Rotation = r, BackgroundColor3 = col or NY_ICE, BorderSizePixel = 0, ZIndex = z or 10 }, f)
	end
	return f
end

-- ---------- снегопад в меню (пока идёт ивент) ----------
local snowFolder = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 4 }, bg)
local function spawnFlake(big: boolean)
	local sz = big and rng:NextInteger(14, 24) or rng:NextInteger(3, 7)
	local p
	if big then
		p = snowIcon(snowFolder, 0, 0, sz, 4, Color3.fromRGB(235, 248, 255))
		p.AnchorPoint = Vector2.new(0.5, 0.5)
	else
		p = new("Frame", { Size = UDim2.fromOffset(sz, sz), BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(245, 250, 255), BackgroundTransparency = 0.15, ZIndex = 4 }, snowFolder)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, p)
	end
	task.spawn(function()
		task.wait(rng:NextNumber(0, 8))
		while p.Parent do
			if nyRemaining() <= 0 or player:GetAttribute("EvaKTheme") == "classic" then snowFolder.Visible = false; task.wait(3) else
				snowFolder.Visible = true
				local x0 = rng:NextNumber(-0.05, 1.05)
				local dur = rng:NextNumber(9, 18) * (big and 1.3 or 1)
				p.Position = UDim2.fromScale(x0, -0.06)
				tw(p, dur, { Position = UDim2.fromScale(x0 + rng:NextNumber(-0.12, 0.12), 1.06) }, Enum.EasingStyle.Linear)
				if big then tw(p, dur, { Rotation = rng:NextInteger(-200, 200) }, Enum.EasingStyle.Linear) end
				task.wait(dur)
			end
		end
	end)
end
for _ = 1, 70 do spawnFlake(false) end
for _ = 1, 12 do spawnFlake(true) end

-- ---------- баланс снежинок ----------
local snowLabel = new("TextLabel", {
	AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromOffset(1222, 76), Size = UDim2.fromOffset(160, 24),
	BackgroundTransparency = 1, Text = "0", TextSize = 20, TextColor3 = NY_ICE, Font = CONFIG.Font,
	TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 10,
}, stage)
local snowCoin = snowIcon(stage, 1238, 76, 20, 10)
local function getSnow(): number return player:GetAttribute("Snow") or 0 end
do
local snowPlus = new("TextButton", { Name = "SnowPlus", Size = UDim2.fromOffset(24, 24), Text = "", AutoButtonColor = false, BackgroundColor3 = BTN_BG,
	BackgroundTransparency = 0.1, BorderSizePixel = 0, ZIndex = 10 }, stage)
new("UIStroke", { Color = NY_ICE, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, snowPlus)
for _, sz in { Vector2.new(12, 3), Vector2.new(3, 12) } do
	new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(sz.X, sz.Y), BackgroundColor3 = NY_ICE, BorderSizePixel = 0, ZIndex = 11 }, snowPlus)
end
snowPlus.MouseButton1Click:Connect(function() sfx(CONFIG.ClickSoundId); openShop("badges") end)
end
local function refreshSnow()
	snowLabel.Text = tostring(getSnow())
	local show = (nyRemaining() > 0 or getSnow() > 0) and player:GetAttribute("EvaKTheme") ~= "classic"
	snowLabel.Visible, snowCoin.Visible = show, show
	local sp = stage:FindFirstChild("SnowPlus")
	if sp then (sp :: GuiObject).Visible = show; (sp :: GuiObject).Position = UDim2.fromOffset(1222 - snowLabel.TextBounds.X - 38, 64) end
end
player:GetAttributeChangedSignal("Snow"):Connect(refreshSnow)
player:GetAttributeChangedSignal("EvaKTheme"):Connect(function() refreshSnow(); LT.set(LT.jingle) end)
refreshSnow()

-- ---------- 10 РАЗНЫХ ШАРОВ (рисунки) ----------
local BAUBLES = {
	{ name = "RED DOTS",   base = Color3.fromRGB(212, 28, 40) },
	{ name = "WOODEN CROSS", base = Color3.fromRGB(24, 70, 40) },
	{ name = "SNOWFLAKE",  base = Color3.fromRGB(40, 100, 235) },
	{ name = "GOLD STRIPES", base = Color3.fromRGB(236, 190, 60) },
	{ name = "LUCKY STAR", base = Color3.fromRGB(50, 170, 80) },
	{ name = "DIAMONDS",   base = Color3.fromRGB(150, 60, 210) },
	{ name = "CANDY",      base = Color3.fromRGB(244, 244, 248) },
	{ name = "WATCHING EYE", base = Color3.fromRGB(16, 14, 16) },
	{ name = "SILVER BELL", base = Color3.fromRGB(200, 206, 214) },
	{ name = "LITTLE TREE", base = Color3.fromRGB(40, 190, 190) },
}
local BALL_ROWS = { 24, 36, 44, 48, 52, 52, 52, 48, 44, 36, 24 }   -- ширины строк круга (px), высота строки 5
local function drawBauble(parent: Instance, kind: number, cx: number, cy: number, found: boolean)
	local h = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, cy), Size = UDim2.fromOffset(60, 76), BackgroundTransparency = 1, ZIndex = 9 }, parent)
	local def = BAUBLES[kind]
	local base = found and def.base or Color3.fromRGB(38, 30, 26)
	local gold = found and Color3.fromRGB(240, 200, 80) or Color3.fromRGB(60, 50, 40)
	px(h, 24, 0, 12, 4, gold); px(h, 26, 4, 8, 8, gold)
	for i, w in BALL_ROWS do
		px(h, 30 - w / 2, 10 + (i - 1) * 5, w, 5, base)
	end
	px(h, 12, 22, 8, 8, found and base:Lerp(Color3.new(1, 1, 1), 0.45) or Color3.fromRGB(52, 42, 36))   -- блик
	if not found then
		text(h, "?", 22, Color3.fromRGB(110, 90, 70), 30, 40, { ZIndex = 10, Size = UDim2.fromOffset(40, 28) })
		return h
	end
	local W = Color3.fromRGB(252, 252, 255)
	if kind == 1 then
		for _, p in { { 14, 28 }, { 28, 24 }, { 38, 34 }, { 20, 44 }, { 32, 50 }, { 42, 46 } } do px(h, p[1], p[2], 5, 5, W) end
	elseif kind == 2 then
		px(h, 27, 24, 6, 34, Color3.fromRGB(150, 98, 54)); px(h, 18, 32, 24, 6, Color3.fromRGB(160, 106, 60))
		px(h, 27, 24, 2, 34, Color3.fromRGB(100, 64, 34))
	elseif kind == 3 then
		px(h, 29, 22, 3, 36, W); px(h, 12, 39, 36, 3, W); px(h, 18, 27, 24, 3, W); px(h, 18, 51, 24, 3, W)
		px(h, 17, 31, 3, 3, W); px(h, 40, 31, 3, 3, W); px(h, 17, 47, 3, 3, W); px(h, 40, 47, 3, 3, W)
	elseif kind == 4 then
		for _, y in { 26, 36, 46 } do px(h, 10, y, 40, 4, Color3.fromRGB(200, 30, 36)) end
	elseif kind == 5 then
		local Y = Color3.fromRGB(255, 230, 90)
		px(h, 27, 24, 6, 30, Y); px(h, 15, 36, 30, 6, Y); px(h, 20, 28, 20, 4, Y); px(h, 20, 46, 20, 4, Y)
	elseif kind == 6 then
		local Y = Color3.fromRGB(255, 210, 90)
		for _, p in { { 26, 24 }, { 18, 34 }, { 34, 34 }, { 26, 44 } } do px(h, p[1], p[2], 8, 8, Y) end
	elseif kind == 7 then
		for _, x in { 12, 24, 36 } do px(h, x, 18, 7, 42, Color3.fromRGB(210, 30, 40)) end
	elseif kind == 8 then
		px(h, 15, 32, 30, 16, Color3.fromRGB(250, 240, 236)); px(h, 24, 30, 12, 20, Color3.fromRGB(235, 20, 20)); px(h, 28, 34, 4, 12, Color3.new(0, 0, 0))
	elseif kind == 9 then
		local G = Color3.fromRGB(240, 200, 80)
		px(h, 22, 28, 16, 3, G); px(h, 18, 31, 24, 16, G); px(h, 14, 47, 32, 4, G); px(h, 27, 51, 6, 6, Color3.fromRGB(130, 96, 30))
	elseif kind == 10 then
		local G = Color3.fromRGB(26, 120, 54)
		px(h, 26, 22, 8, 6, G); px(h, 20, 28, 20, 8, G); px(h, 14, 36, 32, 8, G); px(h, 8, 44, 44, 8, G); px(h, 27, 52, 6, 6, Color3.fromRGB(110, 70, 40))
	end
	return h
end

local function nySet(): {[number]: boolean}
	local t = {}
	for k in string.gmatch(player:GetAttribute("NYSet") or "", "[^,]+") do
		local n = tonumber(k)
		if n then t[n] = true end
	end
	return t
end

-- ---------- экран s7 ----------
local s7, s8 = screen(), screen()
for _, g in { s7, s8 } do g.GroupTransparency = 1; g.Visible = false end

text(s7, "NEW YEAR EVENT", 24, NY_ICE, 420, 95, { Size = UDim2.fromOffset(600, 30), TextXAlignment = Enum.TextXAlignment.Left })
divider(s7, 300, 128, 360, 14)
local nyTimer = text(s7, "", 12, Color3.fromRGB(120, 230, 255), 440, 148, { Size = UDim2.fromOffset(640, 18), TextXAlignment = Enum.TextXAlignment.Left })
local nyFound = text(s7, "", 15, GOLD_TEXT, 330, 182, { Size = UDim2.fromOffset(420, 22), TextXAlignment = Enum.TextXAlignment.Left })
local cells = {}
for i = 1, 10 do
	local col, row = (i - 1) % 5, (i - 1) // 5
	local cell = new("Frame", { Position = UDim2.fromOffset(120 + col * 112, 214 + row * 136), Size = UDim2.fromOffset(100, 124), BackgroundColor3 = Color3.fromRGB(18, 12, 9), BackgroundTransparency = 0.25, BorderSizePixel = 0, ZIndex = 8 }, s7)
	local st = new("UIStroke", { Color = GOLD_DIM, Thickness = 1.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, cell)
	local art = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 9 }, cell)
	local nm = text(cell, "", 9, GOLD_TEXT, 50, 108, { ZIndex = 10, Size = UDim2.fromOffset(98, 14) })
	cells[i] = { art = art, name = nm, stroke = st }
end
local function refreshNYScreen()
	local set = nySet()
	local n = 0
	for i = 1, 10 do
		local found = set[i] == true
		if found then n += 1 end
		for _, ch in cells[i].art:GetChildren() do ch:Destroy() end
		drawBauble(cells[i].art, i, 50, 52, found)
		cells[i].name.Text = found and BAUBLES[i].name or "???"
		cells[i].name.TextColor3 = found and GOLD_TEXT or Color3.fromRGB(120, 100, 80)
		cells[i].stroke.Color = found and NY_ICE or GOLD_DIM
	end
	nyFound.Text = "BAUBLES FOUND: " .. n .. " / 10"
	local t, col = nyText()
	nyTimer.Text = t; nyTimer.TextColor3 = col
end

-- награды справа
local function rewardCard(x: number, toy, caption: string)
	local card = new("Frame", { Position = UDim2.fromOffset(x, 214), Size = UDim2.fromOffset(240, 190), BackgroundColor3 = Color3.fromRGB(18, 12, 9), BackgroundTransparency = 0.25, BorderSizePixel = 0, ZIndex = 8 }, s7)
	new("UIStroke", { Color = CONFIG.Rarities.Event, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, card)
	text(card, "EVENT REWARD", 10, CONFIG.Rarities.Event, 120, 16, { ZIndex = 9 })
	toyView(card, toy, 120, 68, 210, 100, function() return s7.Visible end, card)
	text(card, toy.Name, 14, GOLD_TEXT, 120, 124, { ZIndex = 9, Size = UDim2.fromOffset(232, 18) })
	text(card, caption, 10, Color3.fromRGB(190, 165, 130), 120, 146, { ZIndex = 9, Size = UDim2.fromOffset(232, 14) })
	local own = text(card, "", 12, GOLD, 120, 168, { ZIndex = 9, Size = UDim2.fromOffset(232, 16) })
	return own
end
local ownNY = rewardCard(704, toyById("NEWYEAR"), "FIND ALL 10 DIFFERENT BAUBLES")
local ownSD = rewardCard(960, toyById("SANTADRAGON"), "BEAT ALL 100 DOORS ON NEW YEAR")
local function refreshNYOwn()
	local o = ownedToys()
	for _, p in { { ownNY, "NEWYEAR" }, { ownSD, "SANTADRAGON" } } do
		if o[p[2]] then p[1].Text = "OWNED"; p[1].TextColor3 = GOLD
		elseif nyRemaining() <= 0 then p[1].Text = "LIMITED - EVENT OVER"; p[1].TextColor3 = Color3.fromRGB(255, 120, 200)
		else p[1].Text = "NOT YET"; p[1].TextColor3 = Color3.fromRGB(170, 140, 100) end
	end
end
text(s7, "on NEW YEAR you earn SNOWFLAKES instead of badges - spend them in SKINS", 11, NY_ICE, 800, 496, { Size = UDim2.fromOffset(560, 16) })
text(s7, "baubles hide in the rooms of the NEW YEAR map, grab them as you run", 11, Color3.fromRGB(190, 165, 130), 800, 518, { Size = UDim2.fromOffset(560, 16) })

local nyPlay = new("TextButton", { Position = UDim2.fromOffset(120, 520), Size = UDim2.fromOffset(360, 56), Text = "", AutoButtonColor = false, BackgroundColor3 = NY_RED, BackgroundTransparency = 0.1, BorderSizePixel = 0, ZIndex = 6 }, s7)
new("UIStroke", { Color = NY_WHITE, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, nyPlay)
text(nyPlay, "PLAY NEW YEAR", 20, NY_WHITE, 180, 28, { ZIndex = 9 })
local nyBack = makeButton(s7, 120, 590, 360, 46)
text(nyBack, "BACK", 16, GOLD_TEXT, 180, 23, { ZIndex = 9 })

-- музыка на экране ивента
local nyMusic: Sound? = nil
local function nyMenuMusic(on: boolean)
	if nyMusic then nyMusic:Destroy(); nyMusic = nil end
	if not on or LT.jingle then return end
	local id = workspace:GetAttribute("NYSndMusic")
	if type(id) == "string" and id ~= "" then
		nyMusic = Instance.new("Sound")
		nyMusic.SoundId = id; nyMusic.Volume = 0.45; nyMusic.Looped = true; nyMusic.Parent = SoundServiceNY
		nyMusic:Play()
	end
end

nyPlay.MouseButton1Click:Connect(function()
	sfx(CONFIG.ClickSoundId)
	local d = CONFIG.Difficulties[#CONFIG.Difficulties]
	selectedDiff = d.Id
	diffLabel.Text = "DIFFICULTY: " .. d.Name
	diffLabel.TextColor3 = d.Color
	nyMenuMusic(false)
	go(s2)
end)
nyBack.MouseButton1Click:Connect(function() sfx(CONFIG.ClickSoundId); nyMenuMusic(false); go(s1) end)

-- красная кнопка с шапкой Санты на главном экране
local nyBtn = new("TextButton", { Position = UDim2.fromOffset(120, 562), Size = UDim2.fromOffset(360, 60), Text = "", AutoButtonColor = false, BackgroundColor3 = NY_RED, BackgroundTransparency = 0.08, BorderSizePixel = 0, ZIndex = 6 }, s1)
local nyStroke = new("UIStroke", { Color = NY_WHITE, Thickness = 1.6, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, nyBtn)
do   -- шапка Санты (пиксели)
	local hat = new("Frame", { Position = UDim2.fromOffset(12, 6), Size = UDim2.fromOffset(52, 48), BackgroundTransparency = 1, ZIndex = 9 }, nyBtn)
	local R2 = Color3.fromRGB(120, 10, 16)
	px(hat, 30, 2, 12, 8, NY_WHITE); px(hat, 14, 8, 28, 8, R2); px(hat, 10, 16, 36, 8, R2); px(hat, 6, 24, 44, 8, R2)
	px(hat, 2, 32, 50, 10, NY_WHITE)
	px(hat, 14, 10, 6, 4, Color3.fromRGB(230, 60, 64))
end
text(nyBtn, "NEW YEAR", 22, NY_WHITE, 200, 22, { ZIndex = 9, Size = UDim2.fromOffset(240, 28) })
local nyBtnSub = text(nyBtn, "", 11, Color3.fromRGB(255, 220, 220), 200, 46, { ZIndex = 9, Size = UDim2.fromOffset(240, 16) })
snowIcon(nyBtn, 336, 30, 22, 9, NY_WHITE)
nyBtn.MouseEnter:Connect(function() sfx(CONFIG.HoverSoundId); cursorHover += 1; tw(nyBtn, 0.15, { BackgroundColor3 = Color3.fromRGB(225, 40, 48) }) end)
nyBtn.MouseLeave:Connect(function() cursorHover = math.max(0, cursorHover - 1); tw(nyBtn, 0.15, { BackgroundColor3 = NY_RED }) end)
local function refreshNYBtn()
	nyBtnSub.Text = "BAUBLES FOUND: " .. (player:GetAttribute("NYBaubles") or 0) .. " / 10"
end
refreshNYBtn()
nyBtn.MouseButton1Click:Connect(function()
	sfx(CONFIG.ClickSoundId)
	refreshNYScreen(); refreshNYOwn()
	nyMenuMusic(true)
	go(s7)
end)
for _, a in { "NYSet", "NYBaubles", "OwnedToys" } do
	player:GetAttributeChangedSignal(a):Connect(function() refreshNYBtn(); refreshNYScreen(); refreshNYOwn() end)
end

-- ============================================================
-- SKINS: раздевалка (персонаж справа падает в неё, при выходе взлетает обратно)
-- ============================================================
local SkinsMod: any = nil
local function findSkinsModule(timeout)
	local t0 = os.clock()
	repeat
		for _, d in ReplicatedStorage:GetDescendants() do
			if d:IsA("ModuleScript") and string.find(string.lower(d.Name), "evakskins", 1, true) then return d end
		end
		task.wait(0.5)
	until os.clock() - t0 > timeout
	return nil
end
task.spawn(function()
	do   -- встроенная копия модуля скинов (отдельный ModuleScript не нужен и игнорируется)
		local function embedded()
	-- ============================================================
	--  EvaKSkins  (ModuleScript)  -  ReplicatedStorage > ModuleScript, имя: EvaKSkins
	--  Новогодние скины-шапки за снежинки. Общий для меню (силуэт), магазина и сервера (надеваются на персонажа).
	--  Все размеры даны для головы ~1.25 стад., лицо смотрит в -Z, верх головы ~ +0.62.
	-- ============================================================
	local M = {}

	local function C(r, g, b) return Color3.fromRGB(r, g, b) end

	M.List = {
		{ Id = "SANTAHAT", Name = "SANTA HAT",     Cost = 50 },
		{ Id = "ELFHAT",   Name = "ELF HAT",       Cost = 80 },
		{ Id = "ANTLERS",  Name = "REINDEER",      Cost = 120 },
		{ Id = "SCARF",    Name = "WINTER SCARF",  Cost = 150 },
		{ Id = "SNOWMAN",  Name = "SNOWMAN",       Cost = 220 },
		{ Id = "CROWN",    Name = "FROST CROWN",   Cost = 400 },
	}

	function M.find(id: string)
		for _, s in M.List do if s.Id == id then return s end end
		return nil
	end

	-- спецификации деталей: { shape = "block"|"ball"|"cyl", size, cf (относительно центра головы), color, mat, neon }
	function M.specs(id: string, tint: Color3?)
		local P = {}
		local function add(shape: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?)
			table.insert(P, { shape = shape, size = size, cf = cf, color = color, mat = mat or Enum.Material.SmoothPlastic })
		end
		local function cyl(h: number, d: number, x: number, y: number, z: number, color: Color3, mat: Enum.Material?, rx: number?, rz: number?)
			add("cyl", Vector3.new(h, d, d), CFrame.new(x, y, z) * CFrame.Angles(rx or 0, 0, math.pi / 2 + (rz or 0)), color, mat)
		end
		local red, white = C(200, 28, 34), C(248, 248, 252)
		if id == "SANTAHAT" then
			cyl(0.3, 1.55, 0, 0.55, 0, white, Enum.Material.Fabric)
			cyl(0.45, 1.3, 0, 0.82, 0.02, red, Enum.Material.Fabric)
			cyl(0.4, 1.0, 0, 1.15, 0.1, red, Enum.Material.Fabric, 0.25)
			cyl(0.4, 0.7, 0, 1.45, 0.3, red, Enum.Material.Fabric, 0.5)
			add("ball", Vector3.new(0.42, 0.42, 0.42), CFrame.new(0, 1.55, 0.6), white, Enum.Material.Fabric)
		elseif id == "ELFHAT" then
			local g = C(36, 150, 70)
			cyl(0.28, 1.4, 0, 0.55, 0, red, Enum.Material.Fabric)
			cyl(0.5, 1.2, 0, 0.85, 0, g, Enum.Material.Fabric)
			cyl(0.45, 0.85, 0, 1.25, 0.05, g, Enum.Material.Fabric, 0.15)
			cyl(0.4, 0.5, 0, 1.62, 0.2, g, Enum.Material.Fabric, 0.35)
			add("ball", Vector3.new(0.3, 0.3, 0.3), CFrame.new(0, 1.85, 0.42), C(255, 215, 80), Enum.Material.Metal)
			add("block", Vector3.new(0.12, 0.5, 0.12), CFrame.new(-0.72, 0.15, 0.1) * CFrame.Angles(0, 0, 0.9), C(60, 170, 90))
			add("block", Vector3.new(0.12, 0.5, 0.12), CFrame.new(0.72, 0.15, 0.1) * CFrame.Angles(0, 0, -0.9), C(60, 170, 90))
		elseif id == "ANTLERS" then
			local br = C(110, 72, 40)
			for _, sx in { -1, 1 } do
				add("block", Vector3.new(0.13, 1.0, 0.13), CFrame.new(sx * 0.42, 0.95, 0) * CFrame.Angles(0, 0, -sx * 0.35), br, Enum.Material.Wood)
				add("block", Vector3.new(0.11, 0.6, 0.11), CFrame.new(sx * 0.62, 1.1, 0) * CFrame.Angles(0, 0, -sx * 1.0), br, Enum.Material.Wood)
				add("block", Vector3.new(0.11, 0.5, 0.11), CFrame.new(sx * 0.72, 1.45, 0.05) * CFrame.Angles(0, 0, sx * 0.1), br, Enum.Material.Wood)
				add("block", Vector3.new(0.11, 0.4, 0.11), CFrame.new(sx * 0.52, 1.3, 0) * CFrame.Angles(0, 0, sx * 0.6), br, Enum.Material.Wood)
			end
			add("ball", Vector3.new(0.34, 0.34, 0.34), CFrame.new(0, -0.1, -0.66), C(255, 40, 40), Enum.Material.Neon)
		elseif id == "SCARF" then
			cyl(0.4, 1.55, 0, -0.78, 0, red, Enum.Material.Fabric)
			cyl(0.12, 1.6, 0, -0.68, 0, white, Enum.Material.Fabric)
			cyl(0.12, 1.6, 0, -0.9, 0, white, Enum.Material.Fabric)
			add("block", Vector3.new(0.34, 1.0, 0.14), CFrame.new(0.45, -1.35, -0.7) * CFrame.Angles(0.1, 0, 0.1), red, Enum.Material.Fabric)
			add("block", Vector3.new(0.34, 0.14, 0.15), CFrame.new(0.45, -1.7, -0.7), white, Enum.Material.Fabric)
		elseif id == "SNOWMAN" then
			local black = C(22, 20, 22)
			cyl(0.14, 1.6, 0, 0.58, 0, black)
			cyl(0.9, 1.0, 0, 1.08, 0, black)
			cyl(0.2, 1.02, 0, 0.82, 0, red)
			add("block", Vector3.new(0.16, 0.16, 0.7), CFrame.new(0, -0.05, -0.85), C(250, 130, 30))
			add("ball", Vector3.new(0.14, 0.14, 0.1), CFrame.new(-0.28, 0.2, -0.64), C(10, 10, 10))
			add("ball", Vector3.new(0.14, 0.14, 0.1), CFrame.new(0.28, 0.2, -0.64), C(10, 10, 10))
			for k = 0, 3 do add("ball", Vector3.new(0.1, 0.1, 0.08), CFrame.new((k - 1.5) * 0.18, -0.35 + math.abs(k - 1.5) * -0.07, -0.64), C(10, 10, 10)) end
		elseif id == "CROWN" then
			local ice = C(140, 230, 255)
			cyl(0.25, 1.4, 0, 0.62, 0, C(200, 240, 255), Enum.Material.Glass)
			for k = 0, 7 do
				local a = k / 8 * math.pi * 2
				local h = (k % 2 == 0) and 0.8 or 0.5
				add("block", Vector3.new(0.16, h, 0.16), CFrame.new(math.cos(a) * 0.6, 0.62 + h / 2, math.sin(a) * 0.6) * CFrame.Angles(math.sin(a) * 0.2, 0, -math.cos(a) * 0.2), ice, Enum.Material.Neon)
			end
			add("ball", Vector3.new(0.3, 0.3, 0.3), CFrame.new(0, 1.0, 0), C(255, 255, 255), Enum.Material.Neon)
		end
		if tint then   -- смена цвета: насыщенные цвета меняют оттенок, белое/чёрное остаётся
			local th = tint:ToHSV()
			for _, p in P do
				local h, sat, v = p.color:ToHSV()
				if sat > 0.12 and v > 0.12 then p.color = Color3.fromHSV(th, math.max(sat, 0.55), v) end
			end
		end
		return P
	end

	M.Palette = {   -- цвета для выбора
		{ 200, 28, 34 }, { 255, 130, 30 }, { 255, 205, 40 }, { 60, 190, 80 }, { 40, 190, 200 },
		{ 50, 110, 230 }, { 150, 70, 220 }, { 240, 80, 170 },
	}
	function M.parseColor(str: any): Color3?
		if type(str) ~= "string" then return nil end
		local r, g, b = string.match(str, "^(%d+),(%d+),(%d+)$")
		if not r then return nil end
		if tonumber(r) == 0 and tonumber(g) == 0 and tonumber(b) == 0 then return nil end
		return Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
	end

	local function makePart(spec, parent: Instance): Part
		local p = Instance.new("Part")
		p.Name = "EvaKSkinPart"
		p.Size = spec.size
		p.Color = spec.color; p.Material = spec.mat
		p.CanCollide = false; p.CanTouch = false; p.CanQuery = false; p.CastShadow = false; p.Massless = true
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		if spec.shape == "ball" then
			local m = Instance.new("SpecialMesh"); m.MeshType = Enum.MeshType.Sphere; m.Parent = p
		elseif spec.shape == "cyl" then
			p.Shape = Enum.PartType.Cylinder
		end
		p.Parent = parent
		return p
	end

	-- на живого персонажа (сервер): детали привариваются к Head
	function M.attach(parent: Instance, id: string, head: BasePart, tint: Color3?): Model
		local m = Instance.new("Model")
		m.Name = "EvaKSkin"
		local k = head.Size.Y / 1.2   -- подгонка под размер головы персонажа
		for _, spec in M.specs(id, tint) do
			local s2 = { shape = spec.shape, size = spec.size * k, color = spec.color, mat = spec.mat }
			local p = makePart(s2, m)
			p.CFrame = head.CFrame * (CFrame.new(spec.cf.Position * k) * spec.cf.Rotation)
			local w = Instance.new("Weld")
			w.Part0 = head; w.Part1 = p
			w.C0 = head.CFrame:ToObjectSpace(p.CFrame)
			w.Parent = p
		end
		m.Parent = parent
		return m
	end

	-- в меню (клиент): якорные детали, positions = pivot * spec.cf. Возвращает {parts, update(headCF)}
	function M.build(parent: Instance, id: string, scale: number?, tint: Color3?)
		local sc = scale or 1
		local list = {}
		for _, spec in M.specs(id, tint) do
			local p = makePart({ shape = spec.shape, size = spec.size * sc, color = spec.color, mat = spec.mat }, parent)
			p.Anchored = true
			table.insert(list, { part = p, cf = spec.cf })
		end
		return {
			parts = list,
			update = function(headCF: CFrame)
				for _, r in list do
					r.part.CFrame = headCF * (CFrame.new(r.cf.Position * sc) * r.cf.Rotation)
				end
			end,
			destroy = function()
				for _, r in list do r.part:Destroy() end
				table.clear(list)
			end,
		}
	end

	return M
		end
		SkinsMod = embedded()
	end
end)

text(s8, "SKINS", 24, NY_ICE, 420, 95, { Size = UDim2.fromOffset(600, 30), TextXAlignment = Enum.TextXAlignment.Left })
divider(s8, 300, 128, 360, 14)
text(s8, "pay with snowflakes - earn them on NEW YEAR difficulty", 11, Color3.fromRGB(190, 165, 130), 400, 150, { Size = UDim2.fromOffset(560, 16), TextXAlignment = Enum.TextXAlignment.Left })

-- скин на силуэте
local menuSkin: any = nil
local menuSkinId = ""
local function setMenuSkin(id: string)
	if menuSkin then menuSkin.destroy(); menuSkin = nil end
	menuSkinId = id
	if id ~= "" and SkinsMod then menuSkin = SkinsMod.build(vp, id, 1, SkinsMod.parseColor(player:GetAttribute("SkinColor"))) end
end
skinUpdate = function()
	if menuSkin then menuSkin.update(pHead.CFrame * CFrame.Angles(0, math.pi, 0)) end
end

local skinCards = {}
local previews = {}
local function ownedSkins(): {[string]: boolean}
	local t = {}
	for id in string.gmatch(player:GetAttribute("OwnedSkins") or "", "[^,]+") do t[id] = true end
	return t
end
local function buildSkinCards()
	if #skinCards > 0 or not SkinsMod then return end
	-- палитра цветов скина
	text(s8, "SKIN COLOR", 13, NY_ICE, 640, 188, { ZIndex = 9, Size = UDim2.fromOffset(160, 18) })
	for i, c in SkinsMod.Palette do
		local col, row = (i - 1) % 4, (i - 1) // 4
		local sw = new("TextButton", { Position = UDim2.fromOffset(552 + col * 46, 208 + row * 46), Size = UDim2.fromOffset(38, 38), Text = "", AutoButtonColor = false,
			BackgroundColor3 = Color3.fromRGB(c[1], c[2], c[3]), BorderSizePixel = 0, ZIndex = 30, Active = true }, s8)
		new("UIStroke", { Color = GOLD_TEXT, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, sw)
		sw.MouseButton1Click:Connect(function()
			sfx(CONFIG.ClickSoundId)
			invoke("SkinColor", c[1] .. "," .. c[2] .. "," .. c[3])
		end)
	end
	local reset = makeButton(s8, 552, 304, 176, 34)
	text(reset, "ORIGINAL COLOR", 12, GOLD_TEXT, 88, 17, { ZIndex = 9 })
	reset.MouseButton1Click:Connect(function() sfx(CONFIG.ClickSoundId); invoke("SkinColor", "0,0,0") end)
	for i, sk in SkinsMod.List do
		local col, row = (i - 1) % 2, (i - 1) // 2
		local card = makeButton(s8, 120 + col * 212, 180 + row * 150, 200, 138)
		local vf = new("ViewportFrame", { Position = UDim2.fromOffset(6, 6), Size = UDim2.fromOffset(188, 70), BackgroundTransparency = 1, ZIndex = 9 }, card)
		local cam = new("Camera", { FieldOfView = 36 }, vf)
		cam.CFrame = CFrame.lookAt(Vector3.new(0, 0.6, -5.2), Vector3.new(0, 0.5, 0))
		vf.CurrentCamera = cam
		local head = new("Part", { Shape = Enum.PartType.Ball, Size = Vector3.new(1.25, 1.25, 1.25), Anchored = true, CanCollide = false, Color = Color3.fromRGB(34, 24, 18), Material = Enum.Material.SmoothPlastic }, vf)
		new("Part", { Size = Vector3.new(0.5, 0.5, 0.5), Anchored = true, CanCollide = false, Color = Color3.fromRGB(34, 24, 18), Position = Vector3.new(0, -0.8, 0) }, vf)
		local built = SkinsMod.build(vf, sk.Id, 1)
		table.insert(previews, { vf = vf, built = built })
		text(card, sk.Name, 13, GOLD_TEXT, 100, 92, { ZIndex = 9, Size = UDim2.fromOffset(190, 18) })
		local st = text(card, "", 12, NY_ICE, 100, 118, { ZIndex = 9, Size = UDim2.fromOffset(190, 16) })
		skinCards[i] = { sk = sk, card = card, status = st }
		card.MouseButton1Click:Connect(function()
			sfx(CONFIG.ClickSoundId)
			local owned = ownedSkins()
			local ok, msg
			if owned[sk.Id] and player:GetAttribute("EquippedSkin") == sk.Id then
				ok, msg = invoke("UnequipSkin", "")
			elseif owned[sk.Id] then
				ok, msg = invoke("EquipSkin", sk.Id)
			else
				ok, msg = invoke("BuySkin", sk.Id)
				if ok then burst(card, NY_ICE) end
			end
			if not ok then shake(card); toast(failText(msg)) end
		end)
	end
end
local function refreshSkins()
	if not SkinsMod then return end
	buildSkinCards()
	local owned, eq = ownedSkins(), player:GetAttribute("EquippedSkin") or ""
	for _, c in skinCards do
		if eq == c.sk.Id then c.status.Text = "EQUIPPED"; c.status.TextColor3 = GOLD
		elseif owned[c.sk.Id] then c.status.Text = "CLICK TO EQUIP"; c.status.TextColor3 = Color3.fromRGB(170, 140, 100)
		else c.status.Text = tostring(c.sk.Cost) .. " SNOWFLAKES"; c.status.TextColor3 = (getSnow() >= c.sk.Cost) and NY_ICE or Color3.fromRGB(150, 110, 110) end
	end
	setMenuSkin(eq)
end
for _, a in { "OwnedSkins", "EquippedSkin", "Snow", "SkinColor" } do player:GetAttributeChangedSignal(a):Connect(refreshSkins) end
RunService.RenderStepped:Connect(function()
	if not s8.Visible then return end
	local t = os.clock()
	for _, p in previews do p.built.update(CFrame.new(0, 0, 0) * CFrame.Angles(0, t * 0.9, 0)) end
end)
local skinSnowRow = new("Frame", { Position = UDim2.fromOffset(120, 106), Size = UDim2.fromOffset(160, 24), BackgroundTransparency = 1, ZIndex = 9 }, s8)
snowIcon(skinSnowRow, 12, 12, 18, 9)
local skinSnowLbl = text(skinSnowRow, "0", 16, NY_ICE, 86, 12, { ZIndex = 9, Size = UDim2.fromOffset(120, 20), TextXAlignment = Enum.TextXAlignment.Left })
player:GetAttributeChangedSignal("Snow"):Connect(function() skinSnowLbl.Text = tostring(getSnow()) end)
skinSnowLbl.Text = tostring(getSnow())

local skinsBack = makeButton(s8, 120, 640, 200, 46)
text(skinsBack, "BACK", 16, GOLD_TEXT, 100, 23, { ZIndex = 9 })
do
	local cb = makeButton(s8, 340, 640, 260, 46)
	text(cb, "COSMETICS", 16, GOLD_TEXT, 130, 23, { ZIndex = 9 })
	cb.MouseButton1Click:Connect(function() sfx(CONFIG.ClickSoundId); player:SetAttribute("EvaKOpenCos", os.clock()) end)
end

local function dropTo(y: number, dur: number, style: Enum.EasingStyle, dir: Enum.EasingDirection)
	local v = Instance.new("NumberValue")
	v.Value = dropY
	local tween = TweenService:Create(v, TweenInfo.new(dur, style, dir), { Value = y })
	v:GetPropertyChangedSignal("Value"):Connect(function() dropY = v.Value end)
	tween:Play()
	tween.Completed:Once(function() v:Destroy() end)
	return tween
end

skinsBtn.MouseButton1Click:Connect(function()
	sfx(CONFIG.ClickSoundId)
	if not SkinsMod then toast("SKINS: put ModuleScript named EvaKSkins into ReplicatedStorage"); return end
	refreshSkins()
	go(s8)
	dropY = 16   -- персонаж падает в раздевалку сверху
	dropTo(0, 1.3, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
end)
skinsBack.MouseButton1Click:Connect(function()
	sfx(CONFIG.ClickSoundId)
	dropTo(18, 0.6, Enum.EasingStyle.Back, Enum.EasingDirection.In)   -- взлетает обратно
	task.delay(0.4, function() go(s1) end)
	task.delay(1.3, function() dropY = -10; dropTo(0, 0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out) end)
end)

task.spawn(function()
	while true do
		task.wait(30)
		refreshNYScreen(); refreshNYOwn(); refreshSnow()
	end
end)

task.spawn(function()
	while not SkinsMod do task.wait(0.5) end
	refreshSkins()
end)

end
do
	local okNY, errNY = pcall(setupNewYear)
	if not okNY then warn("[EvaK] setupNewYear: " .. tostring(errNY)) end
end

-- ============================================================
-- BADGES (достижения) и LEADERS (топ-100 по бейджам и снежинкам)
-- ============================================================
local function setupExtras()
local metaRF = ReplicatedStorage:FindFirstChild("EvaKMeta")
local function meta(action: string, arg: any): any
	if not metaRF then metaRF = ReplicatedStorage:WaitForChild("EvaKMeta", 5) end
	if not metaRF then return nil end
	local ok, res = pcall(function() return (metaRF :: RemoteFunction):InvokeServer(action, arg) end)
	return ok and res or nil
end
local sA, sL = screen(), screen()
for _, g in { sA, sL } do g.GroupTransparency = 1; g.Visible = false end

-- кнопки справа (под счётчиками валют)
local aBtn = makeButton(s1, 1090, 118, 170, 44)
text(aBtn, "BADGES", 15, GOLD_TEXT, 85, 22, { ZIndex = 9 })
local lBtn = makeButton(s1, 1090, 170, 170, 44)
text(lBtn, "LEADERS", 15, GOLD_TEXT, 85, 22, { ZIndex = 9 })
do
	local tBtn = makeButton(s1, 1090, 222, 170, 44)
	text(tBtn, "TRADES", 15, GOLD_TEXT, 85, 22, { ZIndex = 9 })
	tBtn.MouseButton1Click:Connect(function() sfx(CONFIG.ClickSoundId); player:SetAttribute("EvaKOpenTrades", os.clock()) end)
end

-- ---------- достижения ----------
text(sA, "BADGES", 24, GOLD_TEXT, 420, 95, { Size = UDim2.fromOffset(600, 30), TextXAlignment = Enum.TextXAlignment.Left })
divider(sA, 300, 128, 360, 14)
local aCount = text(sA, "", 13, DIM, 330, 146, { Size = UDim2.fromOffset(400, 18), TextXAlignment = Enum.TextXAlignment.Left })
local aScroll = new("ScrollingFrame", { Position = UDim2.fromOffset(120, 166), Size = UDim2.fromOffset(640, 410), BackgroundTransparency = 1,
	BorderSizePixel = 0, ScrollBarThickness = 5, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 8 }, sA)
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, aScroll)
local aRows, aDefs = {}, nil
local function buildAch()
	if aDefs then return end
	aDefs = meta("Ach")
	if type(aDefs) ~= "table" then aDefs = nil return end
	for i, a in aDefs do
		local row = new("Frame", { Size = UDim2.new(1, -10, 0, 54), BackgroundColor3 = Color3.fromRGB(18, 12, 9), BackgroundTransparency = 0.2, BorderSizePixel = 0, LayoutOrder = i, ZIndex = 9 }, aScroll)
		local st = new("UIStroke", { Color = GOLD_DIM, Thickness = 1.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, row)
		local mark = text(row, "?", 22, GOLD_DIM, 28, 27, { ZIndex = 10, Size = UDim2.fromOffset(40, 30) })
		local nm = text(row, a.name, 15, GOLD_TEXT, 60 + 230, 17, { ZIndex = 10, Size = UDim2.fromOffset(460, 20), TextXAlignment = Enum.TextXAlignment.Left })
		local ds = text(row, a.desc, 11, Color3.fromRGB(190, 165, 130), 60 + 230, 38, { ZIndex = 10, Size = UDim2.fromOffset(460, 16), TextXAlignment = Enum.TextXAlignment.Left })
		local rw = text(row, "+" .. a.reward, 15, GOLD_DIM, 585, 27, { ZIndex = 10, Size = UDim2.fromOffset(80, 20) })
		aRows[a.id] = { stroke = st, mark = mark, name = nm, reward = rw }
	end
end
local function refreshAch()
	buildAch()
	if not aDefs then aCount.Text = "LOADING..."; return end
	local have = {}
	for id in string.gmatch(player:GetAttribute("Ach") or "", "[^,]+") do have[id] = true end
	local n = 0
	for _, a in aDefs do
		local r = aRows[a.id]
		local got = have[a.id] == true
		if got then n += 1 end
		r.mark.Text = got and "V" or "?"
		r.mark.TextColor3 = got and Color3.fromRGB(130, 255, 150) or GOLD_DIM
		r.stroke.Color = got and Color3.fromRGB(120, 200, 130) or GOLD_DIM
		r.name.TextColor3 = got and GOLD_TEXT or Color3.fromRGB(150, 130, 105)
		r.reward.TextColor3 = got and GOLD_TEXT or GOLD_DIM
	end
	aCount.Text = n .. " / " .. #aDefs .. " UNLOCKED  -  rewards are paid in badges"
end
player:GetAttributeChangedSignal("Ach"):Connect(function() if sA.Visible then refreshAch() end end)
local aBack = makeButton(sA, 120, 590, 360, 46)
text(aBack, "BACK", 16, GOLD_TEXT, 180, 23, { ZIndex = 9 })
aBtn.MouseButton1Click:Connect(function() sfx(CONFIG.ClickSoundId); refreshAch(); go(sA) end)
aBack.MouseButton1Click:Connect(function() sfx(CONFIG.ClickSoundId); go(s1) end)

-- ---------- лидеры ----------
text(sL, "LEADERS", 24, GOLD_TEXT, 420, 95, { Size = UDim2.fromOffset(600, 30), TextXAlignment = Enum.TextXAlignment.Left })
divider(sL, 300, 128, 360, 14)
local lKind = "badges"
local tabB, setTabB = makeButton(sL, 120, 146, 150, 36, true)
text(tabB, "BADGES", 14, GOLD_TEXT, 75, 18, { ZIndex = 9 })
local tabS, setTabS = makeButton(sL, 280, 146, 150, 36)
text(tabS, "SNOWFLAKES", 14, GOLD_TEXT, 75, 18, { ZIndex = 9 })
local tabE, setTabE = makeButton(sL, 440, 146, 100, 36)
text(tabE, "ENDLESS", 13, GOLD_TEXT, 50, 18, { ZIndex = 9 })
local tabR, setTabR = makeButton(sL, 550, 146, 130, 36)
text(tabR, "GOT MORE ROBUX", 11, GOLD_TEXT, 65, 18, { ZIndex = 9 })
local lInfo = text(sL, "TOP 100 - Robux spent. 1000+ = gold crown", 11, DIM, 690, 164, { Size = UDim2.fromOffset(300, 16), TextXAlignment = Enum.TextXAlignment.Left })
local lScroll = new("ScrollingFrame", { Position = UDim2.fromOffset(120, 192), Size = UDim2.fromOffset(640, 384), BackgroundTransparency = 1,
	BorderSizePixel = 0, ScrollBarThickness = 5, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 8 }, sL)
new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, lScroll)
local function refreshLeaders()
	local res = meta("Leaders", lKind)
	for _, c in lScroll:GetChildren() do if c:IsA("Frame") then c:Destroy() end end
	if type(res) ~= "table" or type(res.list) ~= "table" then
		local f = new("Frame", { Size = UDim2.new(1, -10, 0, 30), BackgroundTransparency = 1, ZIndex = 9 }, lScroll)
		text(f, "SERVER NOT RESPONDING - EvaKServer SCRIPT?", 13, DIM, 300, 15, { ZIndex = 10, Size = UDim2.fromOffset(500, 20) })
		return
	end
	if #res.list == 0 then
		local f = new("Frame", { Size = UDim2.new(1, -10, 0, 30), BackgroundTransparency = 1, ZIndex = 9 }, lScroll)
		text(f, "NO DATA YET", 13, DIM, 300, 15, { ZIndex = 10, Size = UDim2.fromOffset(300, 20) })
		return
	end
	for _, e in res.list do
		local mine = e.uid == player.UserId
		local top = e.rank <= 3
		local row = new("Frame", { Size = UDim2.new(1, -10, 0, 30), LayoutOrder = e.rank, BackgroundColor3 = mine and Color3.fromRGB(60, 44, 20) or Color3.fromRGB(18, 12, 9), BackgroundTransparency = 0.25, BorderSizePixel = 0, ZIndex = 9 }, lScroll)
		local col = top and GOLD_TEXT or (mine and Color3.fromRGB(150, 225, 255) or Color3.fromRGB(215, 195, 160))
		text(row, "#" .. e.rank, 14, col, 36, 15, { ZIndex = 10, Size = UDim2.fromOffset(60, 20) })
		text(row, e.name, 14, col, 90 + 190, 15, { ZIndex = 10, Size = UDim2.fromOffset(380, 20), TextXAlignment = Enum.TextXAlignment.Left })
		if lKind == "robux" and (tonumber(e.value) or 0) >= 1000 then   -- золотая корона победителя
			new("TextLabel", { Position = UDim2.fromOffset(66, 3), Size = UDim2.fromOffset(24, 24), BackgroundTransparency = 1, Text = "👑", TextSize = 18, Font = Enum.Font.SourceSansBold, TextColor3 = Color3.fromRGB(255, 205, 60), ZIndex = 11 }, row)
		end
		text(row, tostring(e.value), 14, col, 540, 15, { ZIndex = 10, Size = UDim2.fromOffset(160, 20), TextXAlignment = Enum.TextXAlignment.Right })
	end
end
local function setTab(k: string)
	lKind = k
	setTabB(k == "badges"); setTabS(k == "snow"); setTabE(k == "endless"); setTabR(k == "robux")
	refreshLeaders()
end
tabB.MouseButton1Click:Connect(function() sfx(CONFIG.ClickSoundId); setTab("badges") end)
tabS.MouseButton1Click:Connect(function() sfx(CONFIG.ClickSoundId); setTab("snow") end)
tabE.MouseButton1Click:Connect(function() sfx(CONFIG.ClickSoundId); setTab("endless") end)
tabR.MouseButton1Click:Connect(function() sfx(CONFIG.ClickSoundId); setTab("robux") end)
task.spawn(function()   -- пока открыт экран, обновляем раз в минуту
	while true do
		task.wait(60)
		if sL.Visible then refreshLeaders() end
	end
end)
local lBack = makeButton(sL, 120, 590, 360, 46)
text(lBack, "BACK", 16, GOLD_TEXT, 180, 23, { ZIndex = 9 })
lBtn.MouseButton1Click:Connect(function() sfx(CONFIG.ClickSoundId); task.spawn(refreshLeaders); go(sL) end)
lBack.MouseButton1Click:Connect(function() sfx(CONFIG.ClickSoundId); go(s1) end)
end
do
	local okEx, errEx = pcall(setupExtras)
	if not okEx then warn("[EvaK] setupExtras: " .. tostring(errEx)) end
end

-- ============================================================
-- Появление при запуске
-- ============================================================
overlay.BackgroundTransparency = 0
s1.GroupTransparency = 1
tw(overlay, 3.2, { BackgroundTransparency = 1 }, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
task.delay(1.0, function() tw(s1, 2.2, { GroupTransparency = 0 }, Enum.EasingStyle.Sine, Enum.EasingDirection.Out) end)

-- появление в лобби: чёрный силуэт поднимается снизу в клубах дыма, кнопки въезжают по очереди
do
	dropY = -16
	task.delay(0.7, function()
		local v = Instance.new("NumberValue")
		v.Value = -16
		v:GetPropertyChangedSignal("Value"):Connect(function() dropY = v.Value end)
		local tween = TweenService:Create(v, TweenInfo.new(2.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Value = 0 })
		tween:Play()
		tween.Completed:Once(function() v:Destroy() end)
	end)
	-- дым из-под пола
	local smoke = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 3, ClipsDescendants = true }, gui)
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < 3.6 do
			local k = (os.clock() - t0) / 3.6
			local sz = rng:NextInteger(90, 230)
			local x = 0.72 + rng:NextNumber(-0.16, 0.16)
			local p = new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, 1.1), Size = UDim2.fromOffset(sz, sz),
				BackgroundColor3 = Color3.fromRGB(6, 5, 8), BackgroundTransparency = 0.35 + 0.4 * k, BorderSizePixel = 0,
			}, smoke)
			new("UICorner", { CornerRadius = UDim.new(1, 0) }, p)
			tw(p, rng:NextNumber(1.4, 2.4), { Position = UDim2.fromScale(x + rng:NextNumber(-0.05, 0.05), rng:NextNumber(0.3, 0.7)), BackgroundTransparency = 1, Size = UDim2.fromOffset(sz * 1.8, sz * 1.8) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out).Completed:Once(function() p:Destroy() end)
			task.wait(0.05)
		end
		smoke:Destroy()
	end)
	local items = { title, playBtn, teamBtn, invBtn, shopBtn1, skinsBtn, settingsBtn }
	for i, o in items do
		local pos = o.Position
		o.Position = pos + UDim2.fromOffset(-70, 0)
		task.delay(1.0 + i * 0.12, function()
			tw(o, 0.7, { Position = pos }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		end)
	end
end

-- "NEW GAME" с экрана результатов: сразу открываем выбор сложности
if player:GetAttribute("AutoPlay") then
	player:SetAttribute("AutoPlay", nil)
	task.delay(1.2, function()
if busy or current ~= s1 then return end
local d = player:GetAttribute("LastDiff")
if type(d) == "string" and d ~= "" then
selectedDiff = d
beginFall(d, false)
if not busy and current == s1 then go(s4) end
else
go(s4)
end
end)
end
