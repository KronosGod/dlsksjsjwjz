-- ============================================================
--  EvaK SERVER  (Script)
--  Куда положить: ServerScriptService > Script
--  Бейджи, игрушки, промокоды, сложности, лобби (Team Play), покупки за робуксы.
-- ============================================================

local CONFIG = {
	StoreName = "EvaKData_v1",

	Products = {                    -- Developer Product -> бейджи
		[2081810443] = 100,         -- 59 R$
		[2082098430] = 500,         -- 249 R$
		[2093547126] = 1000,        -- 449 R$
	},

	SnowProducts = {                -- Developer Product -> снежинки (впиши свои ID и раскомментируй)
		[2093517085] = 100,         -- 59 R$
		[2094483033] = 500,         -- 249 R$
		[2094279092] = 1000,        -- 449 R$
	},

	ReviveProduct = 2089588137,     -- возрождение после смерти (29 R$)

	ToyProducts = {                 -- Developer Product / Game Pass -> игрушка за робуксы
		[2089390111] = "DUCK",      -- 19 R$
		[2088628140] = "TOP",       -- 29 R$
		[2089510228] = "ROBOT",     -- 79 R$
		[2089954220] = "BEAR",      -- 89 R$
		[2088610215] = "JACK",      -- 259 R$
		[2089420241] = "MUSIC",     -- 279 R$
		[2089180150] = "DRAGON",    -- 749 R$
		[2087920254] = "ROCKET",    -- 999 R$
		[2093055126] = "NEWYEAR",    -- 799 R$
		[2094567071] = "SANTADRAGON", -- 1099 R$
		[2093775047] = "SANTA",       -- 1499 R$
	},

	SnowCodes = { NEWYEAR = 50 },   -- промокод на снежинки (один раз на аккаунт)
	TitleCodes = { HACKER = { id = "hacker", text = "TITLE HACKER" } },   -- промокод -> титул (один раз на аккаунт)
	ReviveCodes = { REBIRTH = 1 },   -- промокод: даёт возрождения (раз на аккаунт)
	PromoCodes = { KRONOS = 50 },   -- один раз на аккаунт

	RunItems = { LANTERN = 10, BAR = 20, FLASH = 40 },

	-- ГЕЙМПАССЫ-МНОЖИТЕЛИ: впиши ID своих геймпассов (0 = выключено)
	Passes = { Speed2 = 0, Badge2 = 0 },
	PassSpeedMult = 2,   -- х2 скорость (множитель итоговой скорости; можно поставить меньше, напр. 1.5)
	PassBadgeMult = 2,   -- х2 бейджи

	-- Id должны совпадать с клиентом. Speed/Badge = доля бонуса.
	Toys = {
		DUCK    = { Cost = 50,   Speed = 0.02, Badge = 0.00 },
		TOP     = { Cost = 80,   Speed = 0.00, Badge = 0.03 },
		ROBOT   = { Cost = 250,  Speed = 0.06, Badge = 0.00 },
		BEAR    = { Cost = 300,  Speed = 0.00, Badge = 0.08 },
		JACK    = { Cost = 900,  Speed = 0.12, Badge = 0.10 },
		MUSIC   = { Cost = 1100, Speed = 0.10, Badge = 0.15 },
		DRAGON  = { Cost = 3000, Speed = 0.25, Badge = 0.25 },
		ROCKET  = { Cost = 5000, Speed = 0.30, Badge = 0.35 },
		SANTA   = { Cost = 10000, Speed = 0.40, Badge = 0.50 },
		NEWYEAR = { Cost = 0, Speed = 0.35, Badge = 0.40, Event = true },
		CARBONCAR = { Cost = 0, Speed = 0.22, Badge = 0.22, Vip = true },   -- выдаётся ТОЛЬКО владельцам CarBon
		SANTADRAGON = { Cost = 0, Speed = 0.30, Badge = 0.30, Event = true },   -- ивент: пройти все 100 дверей на NEW YEAR   -- ивент: 10 шаров на карте New Year; после 31.12 лимитированная
	},

	-- Порядок = порядок открытия. Чтобы открыть следующую, надо пройти предыдущую.
	Difficulties = { "easy", "normal", "hard", "insane", "newyear", "endless" },
	RewardMult   = { easy = 1, normal = 1.5, hard = 2, insane = 3, newyear = 3 },     -- множитель авто-награды
	CompleteBonus = { easy = 5, normal = 10, hard = 20, insane = 40, newyear = 50 },   -- бонус за прохождение

	AutoAwardEvery  = 15,   -- сек, 0 = выключить
	AutoAwardAmount = 1,

	LobbyMax = 5,

	NYEventYear = 2026,   -- ивент заканчивается 31 декабря этого года (23:59:59 UTC)
	NYBaubles = 10,       -- сколько шаров собрать на карте New Year
}
local NY_END = os.time({ year = CONFIG.NYEventYear, month = 12, day = 31, hour = 23, min = 59, sec = 59 })
workspace:SetAttribute("EvaKNYEnd", NY_END)

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local store = DataStoreService:GetDataStore(CONFIG.StoreName)
local applySkin: (Player) -> ()
local Skins: any = nil   -- модуль скинов (ReplicatedStorage > EvaKSkins)
task.spawn(function()
	-- всегда берём встроенную копию: старый ModuleScript EvaKSkins (без смены цвета) игнорируется
	do
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
		Skins = embedded()
	end
end)
local data: {[Player]: any} = {}
local ev = { badge = 1, speed = 1 }   -- ивенты админа: множители бейджей и скорости

local shop = Instance.new("RemoteFunction")
shop.Name = "EvaKShop"
shop.Parent = ReplicatedStorage

local lobbyEvent = Instance.new("RemoteEvent")
lobbyEvent.Name = "EvaKLobby"
lobbyEvent.Parent = ReplicatedStorage

-- События для твоего геймплея:
--   ServerStorage.AwardBadges:Fire(player, amount)  -- награда за катку (учитывает бонусы)
--   ServerStorage.RunCompleted:Fire(player)         -- игрок прошёл забег -> открывает след. сложность
--   ServerStorage.RunFailed:Fire(player)            -- игрок проиграл/вышел из забега
local function bindable(name: string)
	local b = Instance.new("BindableEvent")
	b.Name = name
	b.Parent = ServerStorage
	return b
end
local awardEvent, completedEvent, failedEvent = bindable("AwardBadges"), bindable("RunCompleted"), bindable("RunFailed")

-- ------------------------------------------------------------
local function diffIndex(id: any): number?
	for i, d in CONFIG.Difficulties do
		if d == id then return i end
	end
	return nil
end

local function isUnlocked(d, id: string): boolean
	local i = diffIndex(id)
	if not i then return false end
	if i == 1 or id == "newyear" or id == "endless" then return true end   -- New Year открыт сразу
	return d.Cleared[CONFIG.Difficulties[i - 1]] == true
end

local function joinKeys(t): string
	local list = {}
	for k in t do table.insert(list, k) end
	table.sort(list)
	return table.concat(list, ",")
end

local function ownedCount(d, id: string): number
	local v = d.Owned[id]
	if v == true then return 1 end
	return type(v) == "number" and v or 0
end
local function teamCount(d, id: string): number
	local n = 0
	for _, t in d.Team or {} do if t == id then n += 1 end end
	return n
end
local function addOwned(d, id: string)
	d.Owned[id] = ownedCount(d, id) + 1
	d.Team = d.Team or {}
	if #d.Team < 3 then table.insert(d.Team, id) end   -- новая игрушка сразу в команде, если есть место
end

local function sync(plr: Player)
	local d = data[plr]
	if not d then return end
	local spd, bdg = 0, 0
	for _, id in d.Team or {} do
		local toy = CONFIG.Toys[id]
		if toy then spd += toy.Speed; bdg += toy.Badge end
	end
	local cnts = {}
	for id in d.Owned do table.insert(cnts, id .. ":" .. ownedCount(d, id)) end
	table.sort(cnts)
	plr:SetAttribute("Badges", d.Badges)
	plr:SetAttribute("OwnedToys", joinKeys(d.Owned))
	plr:SetAttribute("ToyCounts", table.concat(cnts, ","))
	plr:SetAttribute("EquippedToy", table.concat(d.Team or {}, ","))
	plr:SetAttribute("SpeedMult", (1 + math.min(spd, 1.2)) * ev.speed * (plr:GetAttribute("PassSpeed2") and CONFIG.PassSpeedMult or 1))
	plr:SetAttribute("BadgeMult", (1 + bdg) * (plr:GetAttribute("PassBadge2") and CONFIG.PassBadgeMult or 1))
	plr:SetAttribute("SkinColor", d.SkinColor or "")
	plr:SetAttribute("Cleared", joinKeys(d.Cleared))
	plr:SetAttribute("ReviveTokens", d.Revives or 0)
	local nyList, nyN = {}, 0
	for k in d.NYSet or {} do table.insert(nyList, k); nyN += 1 end
	table.sort(nyList)
	plr:SetAttribute("NYSet", table.concat(nyList, ","))
	plr:SetAttribute("NYBaubles", nyN)
	plr:SetAttribute("Snow", d.Snow or 0)
	plr:SetAttribute("OwnedSkins", joinKeys(d.Skins or {}))
	plr:SetAttribute("EquippedSkin", d.Skin or "")
	plr:SetAttribute("Ach", joinKeys(d.Ach or {}))
	plr:SetAttribute("RobuxSpent", d.Spent or 0)
	local donor = (d.Spent or 0) >= 1000
	plr:SetAttribute("Donor", donor)
	if donor and not plr:GetAttribute("DonorCrownSent") then   -- золотая корона победителя на персонажа
		plr:SetAttribute("DonorCrownSent", true)
		task.delay(4, function()
			local gi = ServerStorage:FindFirstChild("EvaKGrantItem")
			if gi and plr.Parent then gi:Fire(plr, "crown") end
		end)
	end
end

local function save(plr: Player)
	local d = data[plr]
	if not d or not d.Ready then return end
	local ok, err = pcall(function()
		store:SetAsync("u" .. plr.UserId, {
			Badges = d.Badges, Owned = d.Owned, Team = d.Team, SkinColor = d.SkinColor,
			Receipts = d.Receipts, Redeemed = d.Redeemed, Cleared = d.Cleared, Revives = d.Revives, NYSet = d.NYSet, Snow = d.Snow, Skins = d.Skins, Skin = d.Skin, Ach = d.Ach, Endless = d.Endless, Spent = d.Spent,
		})
	end)
	if not ok then warn("[EvaK] save failed:", err) end
end

local function checkPasses(plr: Player)
	for key, id in CONFIG.Passes do
		if id and id > 0 then
			local ok, owns = pcall(function() return MarketplaceService:UserOwnsGamePassAsync(plr.UserId, id) end)
			if ok and owns then plr:SetAttribute("Pass" .. key, true) end
		end
	end
	if plr.Parent then sync(plr) end
end
workspace:SetAttribute("PassSpeed2Id", CONFIG.Passes.Speed2)
workspace:SetAttribute("PassBadge2Id", CONFIG.Passes.Badge2)

local function load(plr: Player)
	-- данные доступны СРАЗУ (по умолчанию), сохранённое подгружается в фоне: меню/магазин не зависают
	local d = { Badges = 0, Owned = {}, Team = {}, SkinColor = "", Receipts = {}, Redeemed = {}, Cleared = {}, Revives = 0, InRun = false, Difficulty = "easy", TeamPass = nil, NYSet = {}, Snow = 0, Skins = {}, Skin = "", Ach = {}, Endless = 0, Spent = 0, Ready = false }
	data[plr] = d
	plr:SetAttribute("RunItems", "")
	plr:SetAttribute("Difficulty", "")
	sync(plr)
	task.spawn(function()
		local ok, res = pcall(function() return store:GetAsync("u" .. plr.UserId) end)
		if ok and type(res) == "table" then
			d.Badges += res.Badges or 0
			for k, v in res.Owned or {} do d.Owned[k] = v end
			d.Team = res.Team or d.Team
			if not res.Team and type(res.Equipped) == "string" and res.Equipped ~= "" then d.Team = { res.Equipped } end
			d.SkinColor = res.SkinColor or ""
			d.Receipts = res.Receipts or {}
			d.Redeemed = res.Redeemed or {}
			d.Cleared = res.Cleared or {}
			d.Revives += res.Revives or 0
			d.NYSet = res.NYSet or {}
			d.Endless = res.Endless or 0
			d.Spent += res.Spent or 0
			if not res.NYSet and type(res.NYBaubles) == "number" then   -- миграция со старой версии (счётчик)
				for i = 1, math.min(10, res.NYBaubles) do d.NYSet[tostring(i)] = true end
			end
			d.Snow += res.Snow or 0
			d.Skins = res.Skins or {}
			d.Skin = res.Skin or ""
			d.Ach = res.Ach or {}
		elseif not ok then
			warn("[EvaK] load failed (в Studio включи Game Settings > Security > Enable Studio Access to API Services):", res)
		end
		d.Ready = ok   -- пока не загрузились, не сохраняем (иначе затрём прогресс)
		if plr.Parent then sync(plr); applySkin(plr) end
	end)
	task.spawn(checkPasses, plr)
	plr.CharacterAdded:Connect(function(c)
		c:WaitForChild("Head", 10)
		task.wait(0.4)
		applySkin(plr)
	end)
	if plr.Character then task.spawn(function() task.wait(0.4); applySkin(plr) end) end
end

Players.PlayerAdded:Connect(load)
for _, p in Players:GetPlayers() do task.spawn(load, p) end

local function addBadges(plr: Player, amount: number, useMult: boolean?)
	local d = data[plr]
	if not d or amount <= 0 then return end
	if useMult then
		amount = math.floor(amount * (plr:GetAttribute("BadgeMult") or 1) * ev.badge + 0.5)
	end
	if useMult and d.InRun and d.Difficulty == "newyear" then
		d.Snow = (d.Snow or 0) + amount   -- на сложности NEW YEAR вместо бейджей снежинки
	else
		d.Badges += amount
	end
	sync(plr)
end

awardEvent.Event:Connect(function(plr: Player, amount: number)
	if typeof(plr) == "Instance" and plr:IsA("Player") and type(amount) == "number" then
		local d = data[plr]
		local mult = d and CONFIG.RewardMult[d.Difficulty] or 1
		addBadges(plr, amount * mult, true)
	end
end)

do   -- рекорд Endless: ServerStorage.EvaKEndlessResult:Fire(plr, doors)
	local ee = Instance.new("BindableEvent"); ee.Name = "EvaKEndlessResult"; ee.Parent = ServerStorage
	ee.Event:Connect(function(plr, doors)
		local d = data[plr]
		if d and type(doors) == "number" and doors > (d.Endless or 0) then d.Endless = math.floor(doors); save(plr) end
	end)
end

do   -- хук для EvaKExtra: выдача бейджей (возврат за дубликаты из кейсов)
	local gb = Instance.new("BindableEvent"); gb.Name = "EvaKGrantBadges"; gb.Parent = ServerStorage
	gb.Event:Connect(function(plr, amt)
		local d = data[plr]
		if d and type(amt) == "number" and amt > 0 then d.Badges += math.floor(amt); sync(plr); save(plr) end
	end)
end

do   -- хук для EvaKExtra: машина CarBon (только владельцам пасса)
	local gt = Instance.new("BindableEvent"); gt.Name = "EvaKGrantToy"; gt.Parent = ServerStorage
	gt.Event:Connect(function(plr, id)
		local toy = type(id) == "string" and CONFIG.Toys[id]
		if not toy or not toy.Vip then return end
		local t0 = os.clock()
		while not data[plr] and plr.Parent and os.clock() - t0 < 20 do task.wait(0.5) end
		local d = data[plr]
		if d and ownedCount(d, id) == 0 then addOwned(d, id); sync(plr); save(plr) end
	end)
end

do   -- хук для EvaKExtra: списание бейджей
	local sp = Instance.new("BindableFunction"); sp.Name = "EvaKSpend"; sp.Parent = ServerStorage
	sp.OnInvoke = function(plr, amt)
		local d = data[plr]
		if not d or type(amt) ~= "number" or amt < 0 or d.Badges < amt then return false end
		d.Badges -= amt; sync(plr); save(plr)
		return true
	end
end

do   -- хук для EvaKTrade: инвентарь / проверка / обмен (без yield между Check и Apply)
	local api = Instance.new("BindableFunction"); api.Name = "EvaKTradeApi"; api.Parent = ServerStorage
	local function okInt(n) return type(n) == "number" and n >= 0 and n == math.floor(n) and n < 1e9 end
	api.OnInvoke = function(cmd, plr, offer, to)
		local d = data[plr]
		if not d then return false, "no data" end
		if cmd == "Inv" then
			local toys = {}
			for id in d.Owned do local c = ownedCount(d, id); if c > 0 then toys[id] = c end end
			local sk = {}
			for id in d.Skins or {} do table.insert(sk, id) end
			table.sort(sk)
			return true, { badges = d.Badges, snow = d.Snow or 0, toys = toys, skins = sk }
		elseif cmd == "Check" then
			if type(offer) ~= "table" then return false, "bad offer" end
			local b, sn = offer.badges or 0, offer.snow or 0
			if not okInt(b) or not okInt(sn) then return false, "bad amount" end
			if b > d.Badges then return false, "not enough badges" end
			if sn > (d.Snow or 0) then return false, "not enough snowflakes" end
			for id, n in offer.toys or {} do
				if type(id) ~= "string" or not okInt(n) or n > ownedCount(d, id) then return false, "toy missing: " .. tostring(id) end
				if CONFIG.Toys[id] and CONFIG.Toys[id].Vip then return false, "CarBon car cannot be traded" end
			end
			for id in offer.skins or {} do
				if type(id) ~= "string" or not (d.Skins or {})[id] then return false, "skin missing: " .. tostring(id) end
			end
			return true
		elseif cmd == "Apply" then   -- plr отдаёт offer игроку to
			local dt = data[to]
			if not dt or type(offer) ~= "table" then return false, "bad" end
			local b, sn = offer.badges or 0, offer.snow or 0
			d.Badges -= b; dt.Badges += b
			d.Snow = (d.Snow or 0) - sn; dt.Snow = (dt.Snow or 0) + sn
			for id, n in offer.toys or {} do
				if n > 0 then
					local left = ownedCount(d, id) - n
					d.Owned[id] = left > 0 and left or nil
					while teamCount(d, id) > math.max(left, 0) do
						for i = #d.Team, 1, -1 do if d.Team[i] == id then table.remove(d.Team, i) break end end
					end
					dt.Owned[id] = ownedCount(dt, id) + n
				end
			end
			dt.Skins = dt.Skins or {}
			for id in offer.skins or {} do
				d.Skins[id] = nil
				if d.Skin == id then d.Skin = "" end
				dt.Skins[id] = true
			end
			sync(plr); sync(to)
			task.spawn(save, plr); task.spawn(save, to)
			return true
		end
		return false, "unknown"
	end
end

completedEvent.Event:Connect(function(plr: Player)
	local d = data[plr]
	if not d or not d.InRun then return end
	d.InRun = false
	d.Cleared[d.Difficulty] = true
	if d.Difficulty == "newyear" and os.time() <= NY_END then if ownedCount(d, "SANTADRAGON") == 0 then addOwned(d, "SANTADRAGON") end end   -- Santa Dragon: 100 дверей на NEW YEAR
	addBadges(plr, CONFIG.CompleteBonus[d.Difficulty] or 0, true)
	task.defer(function() local e = ServerStorage:FindFirstChild("EvaKAchieve"); if e then e:Fire(plr, "win_" .. tostring(d.Difficulty)) end end)
	sync(plr); save(plr)
end)

-- шар с карты New Year: 10 штук = игрушка (только пока идёт ивент)
local baubleEvent = bindable("EvaKBauble")
baubleEvent.Event:Connect(function(plr: Player, kind: any)
	local d = typeof(plr) == "Instance" and data[plr]
	if not d or os.time() > NY_END or ownedCount(d, "NEWYEAR") > 0 then return end
	d.NYSet = d.NYSet or {}
	kind = math.clamp(math.floor(tonumber(kind) or 1), 1, CONFIG.NYBaubles)
	if d.NYSet[tostring(kind)] then   -- такой шар уже есть: дарим один из недостающих
		local missing = {}
		for i = 1, CONFIG.NYBaubles do if not d.NYSet[tostring(i)] then table.insert(missing, i) end end
		if #missing == 0 then return end
		kind = missing[math.random(1, #missing)]
	end
	d.NYSet[tostring(kind)] = true
	task.defer(function() local e = ServerStorage:FindFirstChild("EvaKAchieve"); if e then e:Fire(plr, "bauble") end end)
	local n = 0
	for _ in d.NYSet do n += 1 end
	if n >= CONFIG.NYBaubles then addOwned(d, "NEWYEAR") end
	sync(plr); save(plr)
end)


-- ------------------------------------------------------------
-- ДОСТИЖЕНИЯ (ServerStorage.EvaKAchieve:Fire(plr, id)) и ТАБЛИЦЫ ЛИДЕРОВ
-- ------------------------------------------------------------
local ACH = {
	{ id = "d1", name = "FIRST STEPS", desc = "Open your first door", reward = 1 },
	{ id = "d10", name = "WARMING UP", desc = "Reach door 10", reward = 2 },
	{ id = "d30", name = "SLIME SURVIVOR", desc = "Reach door 30", reward = 5 },
	{ id = "d50", name = "HALFWAY", desc = "Reach door 50", reward = 10 },
	{ id = "d75", name = "DEEP DOWN", desc = "Reach door 75", reward = 15 },
	{ id = "d100", name = "THE END", desc = "Open door 100", reward = 40 },
	{ id = "humanoid", name = "MET THE HUMANOID", desc = "Be hunted by the Humanoid", reward = 3 },
	{ id = "eyes", name = "EYE CONTACT", desc = "Look into the Eyes", reward = 3 },
	{ id = "slime", name = "RUN FROM THE SLIME", desc = "Start the slime escape", reward = 5 },
	{ id = "boss", name = "CANTEEN CHEF", desc = "Defeat the canteen zombie", reward = 15 },
	{ id = "cross", name = "BLESSED OR CURSED", desc = "Look at the wooden cross", reward = 3 },
	{ id = "die", name = "FIRST DEATH", desc = "Get caught for the first time", reward = 1 },
	{ id = "santa", name = "DARK SANTA", desc = "Meet Dark Santa on New Year", reward = 5 },
	{ id = "bauble", name = "BAUBLE HUNTER", desc = "Find a New Year bauble", reward = 3 },
	{ id = "toy", name = "COLLECTOR", desc = "Own a toy", reward = 2 },
	{ id = "skin", name = "NEW LOOK", desc = "Own a skin", reward = 2 },
	{ id = "win_easy", name = "EASY CLEAR", desc = "Beat EASY", reward = 5 },
	{ id = "win_normal", name = "NORMAL CLEAR", desc = "Beat NORMAL", reward = 10 },
	{ id = "win_hard", name = "HARD CLEAR", desc = "Beat HARD", reward = 20 },
	{ id = "win_insane", name = "INSANE CLEAR", desc = "Beat INSANE", reward = 40 },
	{ id = "win_newyear", name = "NEW YEAR HERO", desc = "Beat NEW YEAR", reward = 30 },
}
local ACH_BY = {}
for _, a in ACH do ACH_BY[a.id] = a end

local achieveEvent = bindable("EvaKAchieve")
local metaRF = Instance.new("RemoteFunction")
metaRF.Name = "EvaKMeta"; metaRF.Parent = ReplicatedStorage
local achNotify = Instance.new("RemoteEvent")
achNotify.Name = "EvaKAchNotify"; achNotify.Parent = ReplicatedStorage

local function unlock(plr: Player, id: string)
	local d = data[plr]
	local a = ACH_BY[id]
	if not d or not a then return end
	d.Ach = d.Ach or {}
	if d.Ach[id] then return end
	d.Ach[id] = true
	d.Badges += a.reward or 0
	sync(plr)
	achNotify:FireClient(plr, a.name, a.desc, a.reward or 0)
end
achieveEvent.Event:Connect(function(plr: Player, id: any)
	if typeof(plr) == "Instance" and type(id) == "string" then unlock(plr, id) end
end)

local LB: {[string]: any} = {}
do
	local okLB, errLB = pcall(function()
		LB.badges = DataStoreService:GetOrderedDataStore("EvaKLB_Badges_v1")
		LB.snow = DataStoreService:GetOrderedDataStore("EvaKLB_Snow_v1")
		LB.endless = DataStoreService:GetOrderedDataStore("EvaKLB_Endless_v1")
		LB.robux = DataStoreService:GetOrderedDataStore("EvaKLB_Robux_v1")
	end)
	if not okLB then warn("[EvaK] leaderboard unavailable:", errLB) end
end
local lbCache = { badges = {}, snow = {}, endless = {}, robux = {} }
local nameCache: {[number]: string} = {}
local function nameOf(uid: number): string
	if nameCache[uid] then return nameCache[uid] end
	local pl = Players:GetPlayerByUserId(uid)
	if pl then nameCache[uid] = pl.Name; return pl.Name end
	local ok, n = pcall(function() return Players:GetNameFromUserIdAsync(uid) end)
	nameCache[uid] = ok and n or ("Player" .. uid)
	return nameCache[uid]
end
local function pushScores()
	for _, plr in Players:GetPlayers() do
		local d = data[plr]
		if d then
			if next(d.Owned or {}) then unlock(plr, "toy") end
			if next(d.Skins or {}) then unlock(plr, "skin") end
			if LB.badges then pcall(function() LB.badges:SetAsync(tostring(plr.UserId), math.floor(d.Badges)) end) end
			if LB.snow then pcall(function() LB.snow:SetAsync(tostring(plr.UserId), math.floor(d.Snow or 0)) end) end
			if LB.robux and (d.Spent or 0) > 0 then pcall(function() LB.robux:SetAsync(tostring(plr.UserId), math.floor(d.Spent)) end) end
			if LB.endless and (d.Endless or 0) > 0 then pcall(function() LB.endless:SetAsync(tostring(plr.UserId), math.floor(d.Endless)) end) end
		end
	end
end
local function refreshBoards()
	for kind, ods in LB do
		local ok, pages = pcall(function() return ods:GetSortedAsync(false, 100) end)
		if ok and pages then
			local ok2, top = pcall(function() return pages:GetCurrentPage() end)
			if ok2 then
				local list = {}
				for i, e in top do
					local uid = tonumber(e.key)
					if uid and e.value > 0 then table.insert(list, { rank = i, uid = uid, name = nameOf(uid), value = e.value }) end
				end
				lbCache[kind] = list
			end
		end
	end
	workspace:SetAttribute("EvaKLBStamp", os.time())
end
task.spawn(function()
	while true do
		pushScores()
		task.wait(2)
		refreshBoards()
		task.wait(30)
	end
end)
metaRF.OnServerInvoke = function(plr: Player, action: any, arg: any)
	if action == "Ach" then
		local list = {}
		for _, a in ACH do table.insert(list, { id = a.id, name = a.name, desc = a.desc, reward = a.reward }) end
		return list
	elseif action == "Leaders" then
		local k = (arg == "snow" or arg == "endless" or arg == "robux") and arg or "badges"
		-- берём кеш DataStore и подмешиваем живые значения игроков на сервере (работает и без DataStore)
		local merged: {[number]: any} = {}
		for _, e in lbCache[k] or {} do merged[e.uid] = { uid = e.uid, name = e.name, value = e.value } end
		for _, p in Players:GetPlayers() do
			local d = data[p]
			if d then
				local val = math.floor(k == "snow" and (d.Snow or 0) or (k == "endless" and (d.Endless or 0) or (k == "robux" and (d.Spent or 0) or d.Badges)))
				if val > 0 then merged[p.UserId] = { uid = p.UserId, name = p.Name, value = val } end
			end
		end
		local list = {}
		for _, e in merged do table.insert(list, e) end
		table.sort(list, function(x, y) return x.value > y.value end)
		while #list > 100 do table.remove(list) end
		for i, e in list do e.rank = i end
		return { list = list, stamp = workspace:GetAttribute("EvaKLBStamp") or 0, now = os.time() }
	end
	return nil
end

local resumedEvent = bindable("RunResumed")
resumedEvent.Event:Connect(function(plr: Player)
	local d = data[plr]
	if d then d.InRun = true end
end)
local useRevive = Instance.new("BindableFunction")
useRevive.Name = "EvaKUseRevive"
useRevive.Parent = ServerStorage
useRevive.OnInvoke = function(plr: Player)
	local d = data[plr]
	if not d or (d.Revives or 0) <= 0 then return false end
	d.Revives -= 1
	sync(plr); save(plr)
	return true
end

failedEvent.Event:Connect(function(plr: Player)
	local d = data[plr]
	if d then d.InRun = false end
end)

-- ------------------------------------------------------------
-- ЛОББИ (в пределах одного сервера)
-- ------------------------------------------------------------
local lobbies: {[number]: any} = {}
local lobbyOf: {[Player]: any} = {}
local nextLobbyId = 0

local function memberList(lob)
	local list = {}
	for _, m in lob.Members do table.insert(list, { Name = m.Name, UserId = m.UserId }) end
	return list
end

local function lobbyState(lob, plr: Player)
	return {
		Id = lob.Id, HostName = lob.Host.Name, HostId = lob.Host.UserId, Difficulty = lob.Difficulty,
		FriendsOnly = lob.FriendsOnly == true, Members = memberList(lob), IsHost = (lob.Host == plr), Max = CONFIG.LobbyMax,
	}
end

-- можно ли игроку видеть/входить в лобби (для "только для друзей")
local function canSee(lob, plr: Player): boolean
	if not lob.FriendsOnly or lob.Host == plr then return true end
	local ok, res = pcall(function() return plr:IsFriendsWith(lob.Host.UserId) end)
	return ok and res == true
end

local function pushLobby(lob)
	for _, m in lob.Members do lobbyEvent:FireClient(m, "State", lobbyState(lob, m)) end
end

local function leaveLobby(plr: Player)
	local lob = lobbyOf[plr]
	if not lob then return end
	lobbyOf[plr] = nil
	if lob.Host == plr then
		lobbies[lob.Id] = nil
		for _, m in lob.Members do
			if m ~= plr then
				lobbyOf[m] = nil
				lobbyEvent:FireClient(m, "State", nil)
			end
		end
	else
		table.remove(lob.Members, table.find(lob.Members, plr))
		pushLobby(lob)
	end
	if plr.Parent then lobbyEvent:FireClient(plr, "State", nil) end
end

do   -- хук для EvaKExtra: приглашения в лобби (Info = id лобби игрока, Join = вступить)
	local la = Instance.new("BindableFunction"); la.Name = "EvaKLobbyApi"; la.Parent = ServerStorage
	la.OnInvoke = function(cmd, plr, arg)
		if cmd == "Info" then
			local lob = lobbyOf[plr]
			if lob then return lob.Id, #lob.Members end
			return nil
		elseif cmd == "Join" then
			if lobbyOf[plr] then return false, "you are already in a lobby" end
			if data[plr] and data[plr].InRun then return false, "in run" end
			local lob = lobbies[arg]
			if not lob then return false, "lobby is gone" end
			if #lob.Members >= CONFIG.LobbyMax then return false, "lobby is full" end
			table.insert(lob.Members, plr)
			lobbyOf[plr] = lob
			pushLobby(lob)
			return true
		end
		return false, "unknown"
	end
end

-- ------------------------------------------------------------
-- Запросы из меню
-- ------------------------------------------------------------
applySkin = function(plr: Player)
	local d = data[plr]
	local char = plr.Character
	if not char or not d then return end
	local oldSkin = char:FindFirstChild("EvaKSkin")
	if oldSkin then oldSkin:Destroy() end
	-- skin colour: tint the base character body (works with no skin equipped)
	do
		local col = Skins and Skins.parseColor and Skins.parseColor(d.SkinColor)
		if col then
			local bc = char:FindFirstChildOfClass("BodyColors")
			if not bc then bc = Instance.new("BodyColors"); bc.Parent = char end
			bc.HeadColor3 = col; bc.TorsoColor3 = col
			bc.LeftArmColor3 = col; bc.RightArmColor3 = col
			bc.LeftLegColor3 = col; bc.RightLegColor3 = col
			for _, n in ipairs({"Head","UpperTorso","LowerTorso","LeftUpperArm","LeftLowerArm","LeftHand","RightUpperArm","RightLowerArm","RightHand","LeftUpperLeg","LeftLowerLeg","LeftFoot","RightUpperLeg","RightLowerLeg","RightFoot","Torso","Left Arm","Right Arm","Left Leg","Right Leg"}) do
				local bp = char:FindFirstChild(n)
				if bp and bp:IsA("BasePart") then bp.Color = col end
			end
		end
	end
	if not Skins or not d.Skin or d.Skin == "" then return end
	local head = char:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		local ok, err = pcall(Skins.attach, char, d.Skin, head, Skins.parseColor and Skins.parseColor(d.SkinColor) or nil)
		if not ok then warn("[EvaK] skin:", err) end
	end
end

shop.OnServerInvoke = function(plr: Player, action: any, arg: any)
	local d = data[plr]
	if not d then return { ok = false, msg = "loading" } end

	if action == "BuyToy" then
		local toy = type(arg) == "string" and CONFIG.Toys[arg]
		if not toy then return { ok = false, msg = "unknown" } end
		if toy.Event then return { ok = false, msg = "event toy: collect baubles on the NEW YEAR map" } end
		if toy.Vip then return { ok = false, msg = "carbon only" } end
		if ownedCount(d, arg) >= 20 then return { ok = false, msg = "max 20 copies" } end
		if d.Badges < toy.Cost then return { ok = false, msg = "not enough badges" } end
		d.Badges -= toy.Cost
		addOwned(d, arg)
		sync(plr); save(plr)
		return { ok = true }

	elseif action == "BuySkin" or action == "EquipSkin" then
		if not Skins then return { ok = false, msg = "skins unavailable" } end
		local sk = type(arg) == "string" and Skins.find(arg)
		if not sk then return { ok = false, msg = "unknown" } end
		d.Skins = d.Skins or {}
		if not d.Skins[arg] then
			if action ~= "BuySkin" then return { ok = false, msg = "not owned" } end
			if (d.Snow or 0) < sk.Cost then return { ok = false, msg = "not enough snowflakes" } end
			d.Snow -= sk.Cost
			d.Skins[arg] = true
		end
		d.Skin = arg
		sync(plr); save(plr); applySkin(plr)
		return { ok = true }

	elseif action == "SkinColor" then
		if type(arg) ~= "string" or not string.match(arg, "^%d+,%d+,%d+$") then return { ok = false, msg = "bad color" } end
		d.SkinColor = arg
		sync(plr); save(plr); applySkin(plr)
		return { ok = true }

	elseif action == "UnequipSkin" then
		d.Skin = ""
		sync(plr); save(plr); applySkin(plr)
		return { ok = true }

	elseif action == "EquipToy" then
		if type(arg) ~= "string" or ownedCount(d, arg) == 0 then return { ok = false, msg = "not owned" } end
		d.Team = d.Team or {}
		if #d.Team >= 3 then return { ok = false, msg = "team full (3/3)" } end
		if teamCount(d, arg) >= ownedCount(d, arg) then return { ok = false, msg = "all copies equipped" } end
		table.insert(d.Team, arg)
		sync(plr); save(plr)
		return { ok = true }

	elseif action == "Unequip" then
		if type(arg) == "string" and arg ~= "" then
			for i = #(d.Team or {}), 1, -1 do
				if d.Team[i] == arg then table.remove(d.Team, i) break end
			end
		else
			d.Team = {}
		end
		sync(plr); save(plr)
		return { ok = true }

	elseif action == "Redeem" then
		local code = string.upper((string.gsub(tostring(arg), "%s", "")))
		local snowCode = CONFIG.SnowCodes[code]
		if snowCode then
			if d.Redeemed[code] then return { ok = false, msg = "used" } end
			d.Redeemed[code] = true
			d.Snow = (d.Snow or 0) + snowCode
			sync(plr); save(plr)
			return { ok = true, msg = snowCode .. " SNOWFLAKES" }
		end
		local rvAmt = CONFIG.ReviveCodes[code]
		if rvAmt then
			if d.Redeemed[code] then return { ok = false, msg = "used" } end
			d.Redeemed[code] = true
			d.Revives = (d.Revives or 0) + rvAmt
			sync(plr); save(plr)
			return { ok = true, msg = rvAmt .. " REVIVE" }
		end
		local tc = CONFIG.TitleCodes[code]
		if tc then
			if d.Redeemed[code] then return { ok = false, msg = "used" } end
			local gi = ServerStorage:FindFirstChild("EvaKGrantItem")
			if not gi then   -- EvaKExtra.server не запущен: код НЕ сгорает
				warn("[EvaK] промокод-титул: нет ServerStorage.EvaKGrantItem - скрипт EvaKExtra.server не работает (смотри Output)")
				return { ok = false, msg = "titles offline" }
			end
			d.Redeemed[code] = true
			save(plr)
			gi:Fire(plr, tc.id)
			return { ok = true, msg = tc.text }
		end
		local amount = CONFIG.PromoCodes[code]
		if not amount then return { ok = false, msg = "invalid" } end
		if d.Redeemed[code] then return { ok = false, msg = "used" } end
		d.Redeemed[code] = true
		d.Badges += amount
		sync(plr); save(plr)
		return { ok = true, msg = tostring(amount) }

	elseif action == "StartRun" then
		if type(arg) ~= "table" or type(arg.Items) ~= "table" then return { ok = false, msg = "bad args" } end
		local diff = arg.Difficulty
		if not diffIndex(diff) then return { ok = false, msg = "bad difficulty" } end
		if not isUnlocked(d, diff) and not (arg.Team == true and d.TeamPass == diff) then
			return { ok = false, msg = "locked" }
		end
		local picked, seen, total = {}, {}, 0
		for _, id in arg.Items do
			local cost = type(id) == "string" and CONFIG.RunItems[id]
			if cost and not seen[id] then
				seen[id] = true
				total += cost
				table.insert(picked, id)
			end
		end
		if d.Badges < total then return { ok = false, msg = "not enough badges" } end
		d.Badges -= total
		if arg.Team ~= true then plr:SetAttribute("PartyId", nil) end
		d.InRun = true
		d.Difficulty = diff
		d.TeamPass = nil
		plr:SetAttribute("RunItems", table.concat(picked, ","))
		plr:SetAttribute("Difficulty", diff)
		sync(plr); save(plr)
		return { ok = true }

	elseif action == "LobbyList" then
		local list = {}
		for _, lob in lobbies do
			if canSee(lob, plr) then
				table.insert(list, {
					Id = lob.Id, HostName = lob.Host.Name, HostId = lob.Host.UserId, Difficulty = lob.Difficulty,
					FriendsOnly = lob.FriendsOnly == true, Count = #lob.Members, Max = CONFIG.LobbyMax, Members = memberList(lob),
				})
			end
		end
		return { ok = true, lobbies = list }

	elseif action == "LobbyCreate" then
		if lobbyOf[plr] then return { ok = false, msg = "in lobby" } end
		local diff = type(arg) == "table" and arg.Difficulty
		if not diffIndex(diff) then return { ok = false, msg = "bad difficulty" } end
		if not data[plr] or not isUnlocked(data[plr], diff) then return { ok = false, msg = "locked" } end
		nextLobbyId += 1
		local friendsOnly = type(arg) == "table" and arg.FriendsOnly == true
		local lob = { Id = nextLobbyId, Host = plr, Members = { plr }, Difficulty = diff, FriendsOnly = friendsOnly }
		lobbies[lob.Id] = lob
		lobbyOf[plr] = lob
		return { ok = true, state = lobbyState(lob, plr) }

	elseif action == "LobbyJoin" then
		if lobbyOf[plr] then return { ok = false, msg = "in lobby" } end
		local lob = lobbies[arg]
		if not lob then return { ok = false, msg = "gone" } end
		if #lob.Members >= CONFIG.LobbyMax then return { ok = false, msg = "full" } end
		if not canSee(lob, plr) then return { ok = false, msg = "friends only" } end
		table.insert(lob.Members, plr)
		lobbyOf[plr] = lob
		pushLobby(lob)
		return { ok = true, state = lobbyState(lob, plr) }

	elseif action == "LobbyLeave" then
		leaveLobby(plr)
		return { ok = true }

	elseif action == "LobbySetDiff" then
		local lob = lobbyOf[plr]
		if not lob or lob.Host ~= plr then return { ok = false, msg = "not host" } end
		if not diffIndex(arg) then return { ok = false, msg = "bad difficulty" } end
		if not data[plr] or not isUnlocked(data[plr], arg) then return { ok = false, msg = "locked" } end
		lob.Difficulty = arg
		pushLobby(lob)
		return { ok = true, state = lobbyState(lob, plr) }

	elseif action == "LobbySetFriends" then
		local lob = lobbyOf[plr]
		if not lob or lob.Host ~= plr then return { ok = false, msg = "not host" } end
		lob.FriendsOnly = (arg == true)
		pushLobby(lob)
		return { ok = true, state = lobbyState(lob, plr) }

	elseif action == "LobbyStart" then
		local lob = lobbyOf[plr]
		if not lob or lob.Host ~= plr then return { ok = false, msg = "not host" } end
		if not data[plr] or not isUnlocked(data[plr], lob.Difficulty) then return { ok = false, msg = "locked" } end
		lobbies[lob.Id] = nil
		for _, m in lob.Members do
			lobbyOf[m] = nil
			m:SetAttribute("PartyId", lob.Id)   -- EvaKMap сажает команду на одну карту
			if data[m] then data[m].TeamPass = lob.Difficulty end
			lobbyEvent:FireClient(m, "State", nil)
			lobbyEvent:FireClient(m, "Start", lob.Difficulty)
		end
		return { ok = true }
	end
	return { ok = false, msg = "unknown action" }
end

-- Покупка бейджей за робуксы
MarketplaceService.ProcessReceipt = function(info)
	local plr = Players:GetPlayerByUserId(info.PlayerId)
	if not plr then return Enum.ProductPurchaseDecision.NotProcessedYet end
	local d = data[plr]
	if not d then return Enum.ProductPurchaseDecision.NotProcessedYet end

	local key = tostring(info.PurchaseId)
	if d.Receipts[key] then return Enum.ProductPurchaseDecision.PurchaseGranted end

	if info.ProductId == CONFIG.ReviveProduct then
		d.Receipts[key] = true
		d.Revives = (d.Revives or 0) + 1
		sync(plr); save(plr)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local cp = ServerStorage:FindFirstChild("EvaKCaseProduct")   -- кейсы за робуксы (EvaKExtra)
	if cp then
		local okc, handled = pcall(function() return cp:Invoke(plr, info.ProductId) end)
		if okc and handled then
			d.Receipts[key] = true
			save(plr)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	local toyId = CONFIG.ToyProducts[info.ProductId]
	if toyId then
		d.Receipts[key] = true
		addOwned(d, toyId)
		sync(plr); save(plr)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local snowAmt = CONFIG.SnowProducts[info.ProductId]
	if snowAmt then
		d.Receipts[key] = true
		d.Snow = (d.Snow or 0) + snowAmt
		sync(plr); save(plr)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local amount = CONFIG.Products[info.ProductId]
	if not amount then
		warn("[EvaK] Покупка неизвестного продукта " .. tostring(info.ProductId) .. " - проверь CONFIG.Products")
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	d.Receipts[key] = true
	d.Badges += amount
	sync(plr); save(plr)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- если ID окажется Game Pass (покупается один раз) - тоже начисляем бейджи
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(plr: Player, passId: number, purchased: boolean)
	local amount = CONFIG.Products[passId]
	local toyId = CONFIG.ToyProducts[passId]
	local snowP = CONFIG.SnowProducts[passId]
	if not purchased or not (amount or toyId or snowP or passId == CONFIG.ReviveProduct) then return end
	local d = data[plr]
	if not d then return end
	local key = "pass" .. tostring(passId)
	if d.Receipts[key] then return end
	if passId == CONFIG.ReviveProduct then
		d.Receipts[key] = true
		d.Revives = (d.Revives or 0) + 1
		sync(plr); save(plr)
		return
	end
	if toyId then
		d.Receipts[key] = true
		addOwned(d, toyId)
		sync(plr); save(plr)
		return
	end
	if snowP then
		d.Receipts[key] = true
		d.Snow = (d.Snow or 0) + snowP
		sync(plr); save(plr)
		return
	end
	d.Receipts[key] = true
	d.Badges += amount
	sync(plr); save(plr)
end)

-- ------------------------------------------------------------
-- ------------------------------------------------------------
-- API для админ-панели (вызывает только EvaKAdmin.server.lua, проверка прав там)
-- ------------------------------------------------------------
local adminApi = Instance.new("BindableFunction")
adminApi.Name = "EvaKAdminApi"
adminApi.Parent = ServerStorage
local evToken = 0
local function targetsOf(t: any): {Player}
	if typeof(t) == "Instance" and t:IsA("Player") then return { t } end
	return Players:GetPlayers()
end

do   -- учёт потраченных Robux (для таблицы «GOT MORE ROBUX» и золотой короны от 1000)
	local origReceipt = MarketplaceService.ProcessReceipt
	MarketplaceService.ProcessReceipt = function(info)
		local plr = Players:GetPlayerByUserId(info.PlayerId)
		local d = plr and data[plr]
		local key = tostring(info.PurchaseId)
		local before = d and d.Receipts[key]
		local r = origReceipt(info)
		if d and not before and r == Enum.ProductPurchaseDecision.PurchaseGranted then
			d.Spent = (d.Spent or 0) + (tonumber(info.CurrencySpent) or 0)
			sync(plr); save(plr)
		end
		return r
	end
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(plr: Player, passId: number, purchased: boolean)
		if not purchased then return end
		for k, id in CONFIG.Passes do
			if id > 0 and id == passId then plr:SetAttribute("Pass" .. k, true); sync(plr) end
		end
		local d = data[plr]
		if not d then return end
		local key = "spent" .. tostring(passId)
		if d.Receipts[key] then return end
		d.Receipts[key] = true
		local ok, pinfo = pcall(function() return MarketplaceService:GetProductInfo(passId, Enum.InfoType.GamePass) end)
		local price = ok and type(pinfo) == "table" and tonumber(pinfo.PriceInRobux) or 0
		d.Spent = (d.Spent or 0) + price
		sync(plr); save(plr)
	end)
end
local function resyncAll()
	for _, pl in Players:GetPlayers() do sync(pl) end
end
adminApi.OnInvoke = function(action: any, target: any, p1: any, p2: any)
	if action == "Info" then   -- каждый список собирается отдельно: ошибка в одном не ломает остальные
		local info: any = { toys = {}, packs = {}, skins = {}, diffs = CONFIG.Difficulties }
		pcall(function()
			for id in CONFIG.Toys do table.insert(info.toys, id) end
			table.sort(info.toys, function(a, b) return (CONFIG.Toys[a].Cost or 0) < (CONFIG.Toys[b].Cost or 0) or ((CONFIG.Toys[a].Cost or 0) == (CONFIG.Toys[b].Cost or 0) and a < b) end)
		end)
		pcall(function()
			for pid, amt in CONFIG.Products do table.insert(info.packs, { id = pid, badges = amt }) end
			table.sort(info.packs, function(a, b) return a.badges < b.badges end)
		end)
		pcall(function()
			if Skins then for _, sk in Skins.List do table.insert(info.skins, sk.Id) end end
		end)
		return info
	elseif action == "Snow" then
		local amt = math.clamp(math.floor(tonumber(p2) or 0), 0, 10000000)
		for _, pl in targetsOf(target) do
			local d = data[pl]
			if d then
				if p1 == "give" then d.Snow = (d.Snow or 0) + amt
				elseif p1 == "take" then d.Snow = math.max(0, (d.Snow or 0) - amt)
				elseif p1 == "set" then d.Snow = amt end
				sync(pl); save(pl)
			end
		end
		return true, "OK"
	elseif action == "Revive" then
		local amt = math.clamp(math.floor(tonumber(p2) or 0), 0, 1000)
		for _, pl in targetsOf(target) do
			local d = data[pl]
			if d then
				if p1 == "give" then d.Revives = math.min(100000, (d.Revives or 0) + amt)
				elseif p1 == "take" then d.Revives = math.max(0, (d.Revives or 0) - amt)
				elseif p1 == "set" then d.Revives = amt end
				sync(pl); save(pl)
			end
		end
		return true, "OK"
	elseif action == "Skin" then
		if not Skins or type(p1) ~= "string" or not Skins.find(p1) then return false, "нет такого аксессуара" end
		for _, pl in targetsOf(target) do
			local d = data[pl]
			if d then d.Skins = d.Skins or {}; d.Skins[p1] = true; sync(pl); save(pl) end
		end
		return true, "OK"
	elseif action == "Badges" then
		local amt = math.clamp(math.floor(tonumber(p2) or 0), 0, 10000000)
		for _, pl in targetsOf(target) do
			local d = data[pl]
			if d then
				if p1 == "give" then d.Badges += amt
				elseif p1 == "take" then d.Badges = math.max(0, d.Badges - amt)
				elseif p1 == "set" then d.Badges = amt end
				sync(pl); save(pl)
			end
		end
		return true, "OK"
	elseif action == "Toy" then
		if type(p1) ~= "string" or not CONFIG.Toys[p1] then return false, "нет такой игрушки" end
		for _, pl in targetsOf(target) do
			local d = data[pl]
			if d then addOwned(d, p1); sync(pl); save(pl) end
		end
		return true, "OK"
	elseif action == "Pack" then
		local amt = CONFIG.Products[p1]
		if not amt then return false, "нет такого пакета" end
		for _, pl in targetsOf(target) do
			local d = data[pl]
			if d then d.Badges += amt; sync(pl); save(pl) end
		end
		return true, "OK"
	elseif action == "Unlock" then
		for _, pl in targetsOf(target) do
			local d = data[pl]
			if d then
				for _, df in CONFIG.Difficulties do d.Cleared[df] = true end
				sync(pl); save(pl)
			end
		end
		return true, "OK"
	elseif action == "Event" then
		evToken += 1
		local my = evToken
		if p1 == "stop" then
			ev.badge, ev.speed = 1, 1
			resyncAll()
			return true, "ивенты остановлены"
		end
		local mult = math.clamp(tonumber(p2 and p2.mult) or 2, 1, 10)
		local mins = math.clamp(tonumber(p2 and p2.mins) or 5, 0.5, 120)
		if p1 == "badge" then ev.badge = mult elseif p1 == "speed" then ev.speed = math.min(mult, 2) else return false, "неизвестный ивент" end
		resyncAll()
		task.delay(mins * 60, function()
			if my == evToken then ev.badge, ev.speed = 1, 1; resyncAll() end
		end)
		return true, "OK"
	end
	return false, "неизвестное действие"
end


Players.PlayerRemoving:Connect(function(plr)
	leaveLobby(plr)
	save(plr)
	data[plr] = nil
end)

game:BindToClose(function()
	for _, plr in Players:GetPlayers() do save(plr) end
end)

task.spawn(function()
	while true do
		task.wait(60)
		for _, plr in Players:GetPlayers() do save(plr) end
	end
end)

if CONFIG.AutoAwardEvery > 0 then
	task.spawn(function()
		while true do
			task.wait(CONFIG.AutoAwardEvery)
			for plr, d in data do
				if d.InRun and plr.Parent then
					addBadges(plr, CONFIG.AutoAwardAmount * (CONFIG.RewardMult[d.Difficulty] or 1), true)
				end
			end
		end
	end)
end
print("[EvaK] EvaKServer ready: shop, lobby, admin API, achievements, leaderboards")
