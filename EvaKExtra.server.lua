-- ============================================================
--  EvaKExtra  (Script в ServerScriptService)
--  Новые монстры (Fallen, Preacher, EvaK, The Guest, The Crawl, The Witness, The Bellman),
--  ивенты (Blood Moon, Blackout, Invasion, Giant EvaK, Gravity, Fake Update, Earthquake,
--  Doppelgangers, Silent Mode, Apocalypse), косметика (ауры, крылья, глаза демона, корона),
--  титулы. Всё из деталей, без чужих ассетов.
--  Для работы нужны хуки в EvaKMap (EvaKDamage / EvaKInRun) и EvaKServer (EvaKSpend).
--  Команды для админов в чате:  /event <name|off>   /give <ник> <id>   /take <ник> <id>
--  ID предметов: aura, wings, demoneyes, crown | титулы: survivor, chosen, collector, sinner, believer, abuser
-- ============================================================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

-- защита от дублей: если в ServerScriptService лежит несколько копий EvaKExtra, они конфликтуют (одна отвечает {ok=false})
do
	local found = {}
	for _, d in game:GetService("ServerScriptService"):GetDescendants() do
		if d:IsA("BaseScript") and d.Name:lower():find("evakextra") then table.insert(found, d:GetFullName()) end
	end
	if #found > 1 then
		warn("[EvaKExtra] НАЙДЕНО НЕСКОЛЬКО КОПИЙ СКРИПТА, оставь ОДНУ: " .. table.concat(found, "  |  "))
		ReplicatedStorage:SetAttribute("EvaKExtraDup", table.concat(found, " | "))
	end
	-- старые копии могли оставить свои RemoteFunction/RemoteEvent: убираем, чтобы клиент говорил именно с этим скриптом
	for _, n in { "EvaKExtra", "EvaKExtraFx" } do
		for _, o in ReplicatedStorage:GetChildren() do if o.Name == n then o:Destroy() end end
	end
end
print("[EvaKExtra] запуск скрипта")

local ADMIN_IDS: {number} = {}   -- сюда можно добавить UserId админов (владелец игры определяется сам)

local CONFIG = {
	EventEvery = { 240, 420 },    -- пауза между ивентами (сек)
	EventLength = 100,            -- длительность ивента (сек)
	MonsterEvery = { 80, 160 },   -- монстры редкие: новый на игрока раз в 80-160 сек (первый позже)
	KnockSoundId = "rbxassetid://9119713951",            -- звук стука в окно (rbxassetid://...)
	BellSoundId = "",             -- свой звук колокольчика (rbxassetid://...)
	WhisperSoundId = "",          -- голос/шёпот Preacher
}

-- ---------------- каталог ----------------
-- kind: item (косметика) / title; how: buy (за бейджи), quest, admin
local ITEMS = {
	aura      = { name = "Curse Aura",      slot = "aura",  kind = "item", how = "buy", cost = 500 },
	wings     = { name = "EvaK Wings",      slot = "wings", kind = "item", how = "buy", cost = 1500 },
	demoneyes = { name = "Demon Eyes",      slot = "eyes",  kind = "item", how = "buy", cost = 800 },
	crown     = { name = "Sinner's Crown",  slot = "crown", kind = "item", how = "admin" },
	lantern   = { name = "Cursed Lantern",  slot = "lantern", kind = "item", how = "buy", cost = 1200 },   -- освещает тёмные комнаты
	watch     = { name = "Broken Watch",    slot = "watch", kind = "item", how = "buy", cost = 900 },      -- показывает время до след. ивента
	ownerkey  = { name = "Owner's Key",     slot = "key",   kind = "item", how = "buy", cost = 2500 },     -- открывает секретные записки 6-9
	eyeofevak = { name = "Eye of EvaK",     slot = "amulet", kind = "item", how = "buy", cost = 3000 },    -- редкий кулон
	-- ДЬЯВОЛЬСКИЕ ПРЕДМЕТЫ (вкладка DEVIL в магазине)
	devhorns  = { name = "Devil Horns",     slot = "horns", kind = "item", how = "buy", cost = 700,  devil = true },
	devtail   = { name = "Devil Tail",      slot = "tail",  kind = "item", how = "buy", cost = 900,  devil = true },
	hellaura  = { name = "Hellfire Aura",   slot = "aura",  kind = "item", how = "buy", cost = 1800, devil = true },
	devwings  = { name = "Devil Wings",     slot = "wings", kind = "item", how = "buy", cost = 2200, devil = true },
	pentagram = { name = "Eclipse Pendant", slot = "amulet", kind = "item", how = "buy", cost = 1500, devil = true },
	hellspawn = { name = "Hellspawn",       slot = "title", kind = "title", how = "buy", cost = 1500, devil = true },
	advocate  = { name = "Devil's Advocate", slot = "title", kind = "title", how = "buy", cost = 700, devil = true },
	sixsix    = { name = "666",             slot = "title", kind = "title", how = "buy", cost = 666,  devil = true },
	oldgod    = { name = "Old God",         slot = "title", kind = "title", how = "quest", quest = "Only at the FIRST Admin Abuse" },
	hacker    = { name = "Hacker",          slot = "title", kind = "title", how = "quest", quest = "Promo code" },
	god       = { name = "GOD",             slot = "title", kind = "title", how = "owner", quest = "Owner only" },
	survivor  = { name = "Survivor",        slot = "title", kind = "title", how = "quest", quest = "Finish any run" },
	collector = { name = "Collector",       slot = "title", kind = "title", how = "quest", quest = "Have 1000 badges" },
	sinner    = { name = "Sinner",          slot = "title", kind = "title", how = "buy", cost = 300 },
	believer  = { name = "Believer",        slot = "title", kind = "title", how = "buy", cost = 700 },
	lol       = { name = "lol",             slot = "title", kind = "title", how = "quest", quest = "Reach door 100 in under 1 minute" },
	speedrun  = { name = "Speedrunner",     slot = "title", kind = "title", how = "quest", quest = "Reach door 100 in under 5 minutes" },
	veteran   = { name = "Veteran",         slot = "title", kind = "title", how = "quest", quest = "Play for 10 hours" },
	vip       = { name = "CarBon",          slot = "title", kind = "title", how = "shop", quest = "CarBon pass" },
	vipaura   = { name = "CarBon Aura",   slot = "aura",  kind = "item", how = "vip" },
	vipeyes   = { name = "CarBon Eyes",   slot = "eyes",  kind = "item", how = "vip" },
	seengod   = { name = "Seen by God",     slot = "title", kind = "title", how = "quest", quest = "See the Owner on your server" },
	rookie    = { name = "Rookie", slot = "title", kind = "title", how = "buy", cost = 100 },
	guest     = { name = "Hotel Guest", slot = "title", kind = "title", how = "buy", cost = 150 },
	sleepwalker = { name = "Sleepwalker", slot = "title", kind = "title", how = "buy", cost = 250 },
	lurker    = { name = "Lurker", slot = "title", kind = "title", how = "buy", cost = 350 },
	ghosty    = { name = "Ghost", slot = "title", kind = "title", how = "buy", cost = 500 },
	nightowl  = { name = "Night Owl", slot = "title", kind = "title", how = "buy", cost = 600 },
	runner    = { name = "Runner", slot = "title", kind = "title", how = "buy", cost = 800 },
	hunter    = { name = "Monster Hunter", slot = "title", kind = "title", how = "buy", cost = 1000 },
	lucky     = { name = "Lucky One", slot = "title", kind = "title", how = "buy", cost = 1300 },
	legend    = { name = "Legend", slot = "title", kind = "title", how = "buy", cost = 2000 },
	cobweb    = { name = "Cobweb Lord", slot = "title", kind = "title", how = "buy", cost = 2500 },
	insomnia  = { name = "Insomniac", slot = "title", kind = "title", how = "buy", cost = 450 },
	bellhop   = { name = "Bellhop", slot = "title", kind = "title", how = "admin" },
	manager   = { name = "Hotel Manager", slot = "title", kind = "title", how = "admin" },
	vipguest  = { name = "VIP Guest", slot = "title", kind = "title", how = "admin" },
	chosen    = { name = "Chosen of EvaK",  slot = "title", kind = "title", how = "admin" },
	abuser    = { name = "Admin Abuse Survivor", slot = "title", kind = "title", how = "admin" },
	-- РАМКИ вокруг скина в профиле
	frame_bronze = { name = "Bronze Frame", slot = "frame", kind = "frame", how = "buy", cost = 300 },
	frame_silver = { name = "Silver Frame", slot = "frame", kind = "frame", how = "buy", cost = 600 },
	frame_gold   = { name = "Gold Frame",   slot = "frame", kind = "frame", how = "buy", cost = 1200 },
	frame_blood  = { name = "Blood Frame",  slot = "frame", kind = "frame", how = "buy", cost = 900 },
	frame_neon   = { name = "Neon Frame",   slot = "frame", kind = "frame", how = "buy", cost = 1800 },
	frame_devil  = { name = "Hellfire Frame", slot = "frame", kind = "frame", how = "buy", cost = 2500 },
	frame_horns  = { name = "Horned Frame", slot = "frame", kind = "frame", how = "buy", cost = 3200 },
	frame_angel  = { name = "Angel Frame",  slot = "frame", kind = "frame", how = "buy", cost = 3200 },
	frame_halo   = { name = "Halo Frame",   slot = "frame", kind = "frame", how = "buy", cost = 2200 },
	frame_demon  = { name = "Demon Frame",  slot = "frame", kind = "frame", how = "quest", quest = "Finish the game badly hurt (Demon ending)" },
	frame_seraph = { name = "Seraph Frame", slot = "frame", kind = "frame", how = "quest", quest = "Finish the game almost unhurt (Angel ending)" },
	endemon = { name = "Demon", slot = "title", kind = "title", how = "quest", quest = "Demon ending: finish the game badly hurt" },
	enangel = { name = "Angel", slot = "title", kind = "title", how = "quest", quest = "Angel ending: finish the game almost unhurt" },
	frame_royal  = { name = "Royal Frame",  slot = "frame", kind = "frame", how = "owner", quest = "Owner only" },
	-- ЗНАЧКИ (показываются в профиле все купленные)
	pin_cross = { name = "Cross Pin", slot = "pin", kind = "pin", how = "buy", cost = 200 },
	pin_skull = { name = "Skull Pin", slot = "pin", kind = "pin", how = "buy", cost = 400 },
	pin_heart = { name = "Heart Pin", slot = "pin", kind = "pin", how = "buy", cost = 400 },
	pin_star  = { name = "Star Pin",  slot = "pin", kind = "pin", how = "buy", cost = 600 },
	pin_moon  = { name = "Moon Pin",  slot = "pin", kind = "pin", how = "buy", cost = 800 },
	pin_flame = { name = "Flame Pin", slot = "pin", kind = "pin", how = "buy", cost = 1000 },
}
local TITLE_COLOR = {sinner = "c8322a", believer = "8cc8ff", hellspawn = "ff7a1a", advocate = "b050e0", sixsix = "e01818", oldgod = "ffd24a", hacker = "3cff6a", god = "ffcd3c", survivor = "5cd05c", endemon = "ff3a2a", enangel = "fff0b0", collector = "34d6c0", lol = "fff04a", speedrun = "40e0ff", veteran = "d08a40", vip = "ff4646", seengod = "ffe27a", chosen = "c070ff", abuser = "ff9a3a", rookie = "b8b8b8", guest = "d8c090", sleepwalker = "b8a8ff", lurker = "4a8a4a", ghosty = "d8ecff", nightowl = "6a70ff", runner = "a8ff3a", hunter = "c05030", lucky = "7aff9a", legend = "ffc020", cobweb = "d8dce8", insomnia = "c8a0ff", bellhop = "d4a84a", manager = "ff6a3a", vipguest = "ff8ad0"}
local ORDER = { "endemon", "enangel", "frame_horns", "frame_angel", "frame_halo", "frame_demon", "frame_seraph", "aura", "wings", "demoneyes", "crown", "lantern", "watch", "ownerkey", "eyeofevak", "survivor", "collector", "rookie","guest","sleepwalker","lurker","ghosty","nightowl","runner","hunter","lucky","legend","cobweb","insomnia","bellhop","manager","vipguest", "sinner", "believer", "seengod", "lol", "speedrun", "veteran", "vip", "vipaura", "vipeyes", "chosen", "abuser", "oldgod", "hacker", "god", "frame_royal", "devhorns", "devtail", "hellaura", "devwings", "pentagram", "hellspawn", "advocate", "sixsix", "frame_bronze", "frame_silver", "frame_gold", "frame_blood", "frame_neon", "frame_devil", "pin_cross", "pin_skull", "pin_heart", "pin_star", "pin_moon", "pin_flame" }

local function folder(name: string): Folder
	local f = ReplicatedStorage:FindFirstChild(name)
	if not f then f = Instance.new("Folder"); f.Name = name; f.Parent = ReplicatedStorage end
	return f
end

local rf = Instance.new("RemoteFunction"); rf.Name = "EvaKExtra"; rf.Parent = ReplicatedStorage
local fx = Instance.new("RemoteEvent"); fx.Name = "EvaKExtraFx"; fx.Parent = ReplicatedStorage

local function inRun(plr: Player): boolean
	local b = ServerStorage:FindFirstChild("EvaKInRun")
	if not b then return false end
	local ok, r = pcall(function() return b:Invoke(plr) end)
	return ok and r == true
end
local function damage(plr: Player, amt: number)
	local e = ServerStorage:FindFirstChild("EvaKDamage")
	if e then e:Fire(plr, amt) end
end
local function isAdmin(plr: Player): boolean
	if RunService:IsStudio() then return true end
	if table.find(ADMIN_IDS, plr.UserId) then return true end
	if game.CreatorType == Enum.CreatorType.User and game.CreatorId == plr.UserId then return true end
	if game.CreatorType == Enum.CreatorType.Group then
		local s, rank = pcall(function() return plr:GetRankInGroup(game.CreatorId) end)
		if s and rank == 255 then return true end
	end
	return false
end

local function isOwner(plr: Player): boolean   -- только настоящий владелец игры (в Studio - тот, кто тестирует)
	if RunService:IsStudio() then return true end
	if game.CreatorType == Enum.CreatorType.User then return game.CreatorId == plr.UserId end
	local s, rank = pcall(function() return plr:GetRankInGroup(game.CreatorId) end)
	return s and rank == 255
end

-- ---------------- данные ----------------
local store = DataStoreService:GetDataStore("EvaKExtra_v1")
local data: {[Player]: any} = {}
local EXTRA = {}   -- обработчики запросов (заполняются ниже)
local BASE: any = nil
-- диспетчер ставится СРАЗУ: даже если ниже в скрипте случится ошибка, уже объявленные запросы работают
rf.OnServerInvoke = function(plr: Player, action: any, a: any, b: any, c: any, d: any)
	local t0 = os.clock()
	while not data[plr] and plr.Parent and os.clock() - t0 < 12 do task.wait(0.25) end
	local h = EXTRA[action]
	if h then return h(plr, a, b, c, d) end
	if BASE then return BASE(plr, action, a, b) end
	return { ok = false, msg = "server not ready - see Output for red errors in EvaKExtra" }
end
print("[EvaKExtra] v21b: диспетчер запросов запущен")

local function load(plr: Player)
	-- данные доступны СРАЗУ (значения по умолчанию), а сохранённое подгружается в фоне: так меню/титулы не зависают, если DataStore медленный или выключен
	local d = { Owned = {}, Equip = {}, Notes = {}, Visits = 0, Best = 0, Play = 0, Cases = 0, Done = 0, Failed = 0, Custom = "", Ready = false }
	data[plr] = d
	task.spawn(function()
		local ok, res = pcall(function() return store:GetAsync("u" .. plr.UserId) end)
		if ok and type(res) == "table" then
			for id in res.Owned or {} do d.Owned[id] = true end
			for k, v in res.Equip or {} do d.Equip[k] = v end
			d.Notes = res.Notes or {}; d.Visits = res.Visits or 0; d.Best = res.Best or 0
			d.Play = res.Play or 0; d.Cases = res.Cases or 0; d.Done = res.Done or 0; d.Failed = res.Failed or 0; d.Custom = res.Custom or ""
		elseif not ok then
			warn("[EvaKExtra] load failed (в Studio включи Game Settings > Security > Enable Studio Access to API Services):", res)
		end
		d.Ready = ok   -- пока не загрузились, не сохраняем (иначе затрём прогресс значениями по умолчанию)
		d.Loaded = true
	end)
end
local function save(plr: Player)
	local d = data[plr]
	if not d or not d.Ready then return end
	pcall(function() store:SetAsync("u" .. plr.UserId, { Owned = d.Owned, Equip = d.Equip, Notes = d.Notes, Visits = d.Visits, Best = d.Best, Play = d.Play, Cases = d.Cases, Done = d.Done, Failed = d.Failed, Custom = d.Custom }) end)
end
Players.PlayerAdded:Connect(load)
for _, p in Players:GetPlayers() do load(p) end

-- ---------------- косметика на персонаже ----------------
local function mkp(parent: Instance, name: string, size: Vector3, color: Color3, mat: Enum.Material, shape: Enum.PartType?)
	local p = Instance.new("Part")
	p.Name = name; p.Size = size; p.Color = color; p.Material = mat
	p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.Massless = true; p.CastShadow = false
	if shape then p.Shape = shape end
	p.Parent = parent
	return p
end
local function weld(a: BasePart, b: BasePart, cf: CFrame)   -- b закреплена к a со смещением cf
	b.CFrame = a.CFrame * cf
	local w = Instance.new("WeldConstraint"); w.Part0 = a; w.Part1 = b; w.Parent = b
end

local function clearCosmetics(char: Model)
	for _, n in { "EvaKAura", "EvaKWings", "EvaKDemonEyes", "EvaKCrown", "EvaKLantern", "EvaKAmulet", "EvaKHorns", "EvaKTail" } do
		local o = char:FindFirstChild(n)
		if o then o:Destroy() end
	end
end

local function applyCosmetics(plr: Player)
	local char = plr.Character
	local d = data[plr]
	if not char or not d then return end
	clearCosmetics(char)
	local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
	local head = char:FindFirstChild("Head")
	local eq = d.Equip
	if eq.aura and torso then   -- красное кольцо вокруг персонажа
		local m = Instance.new("Model"); m.Name = "EvaKAura"; m.Parent = char
		local gold = eq.aura == "vipaura"
		local ring = mkp(m, "Ring", Vector3.new(0.18, 7.5, 7.5), gold and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(255, 30, 20), Enum.Material.Neon, Enum.PartType.Cylinder)
		weld(torso :: BasePart, ring, CFrame.Angles(0, 0, math.rad(90)))
		local ring2 = mkp(m, "Ring2", Vector3.new(0.1, 6.3, 6.3), gold and Color3.fromRGB(230, 20, 30) or Color3.fromRGB(120, 0, 0), Enum.Material.Neon, Enum.PartType.Cylinder)
		weld(torso :: BasePart, ring2, CFrame.new(0, -0.9, 0) * CFrame.Angles(0, 0, math.rad(90)))
		local pl = Instance.new("PointLight"); pl.Color = Color3.fromRGB(255, 40, 30); pl.Range = 12; pl.Brightness = 1.2; pl.Parent = ring
		if eq.aura == "hellaura" then
			ring.Color = Color3.fromRGB(255, 110, 10); ring2.Color = Color3.fromRGB(255, 40, 0); pl.Color = Color3.fromRGB(255, 110, 30); pl.Range = 16
			local fire = Instance.new("ParticleEmitter")
			fire.Texture = "rbxasset://textures/particles/fire_main.dds"
			fire.Rate = 40; fire.Lifetime = NumberRange.new(0.7, 1.3); fire.Speed = NumberRange.new(2, 5)
			fire.SpreadAngle = Vector2.new(25, 25); fire.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.4), NumberSequenceKeypoint.new(1, 0) })
			fire.Color = ColorSequence.new(Color3.fromRGB(255, 160, 40), Color3.fromRGB(200, 20, 0)); fire.LightEmission = 1
			fire.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
			fire.EmissionDirection = Enum.NormalId.Top; fire.Parent = ring
		end
	end
	if eq.wings and torso then   -- крылья: перепонки-клинья + чёрные кости
		local m = Instance.new("Model"); m.Name = "EvaKWings"; m.Parent = char
		for side = -1, 1, 2 do
			local bone = mkp(m, "Bone", Vector3.new(0.35, 5.5, 0.35), Color3.fromRGB(14, 8, 8), Enum.Material.SmoothPlastic)
			weld(torso :: BasePart, bone, CFrame.new(side * 2.5, 1.4, 1.1) * CFrame.Angles(0, 0, math.rad(side * -38)))
			for i = 1, 3 do
				local mem = Instance.new("WedgePart")
				mem.Name = "Membrane"; mem.Size = Vector3.new(0.12, 4.2 - i * 0.6, 2.2)
				mem.Color = eq.wings == "devwings" and Color3.fromRGB(70 - i * 10, 4, 6) or Color3.fromRGB(150 - i * 20, 12, 18); mem.Material = eq.wings == "devwings" and Enum.Material.Neon or Enum.Material.SmoothPlastic
				mem.CanCollide = false; mem.CanQuery = false; mem.CanTouch = false; mem.Massless = true; mem.CastShadow = false
				mem.Parent = m
				weld(torso :: BasePart, mem, CFrame.new(side * (1.5 + i * 0.9), 0.5 + i * 0.35 - 0.4, 1.0) * CFrame.Angles(0, math.rad(side * 14), math.rad(side * -8)))
			end
		end
	end
	if eq.eyes and head then   -- светящиеся глаза демона: овальные, чуть скошенные, с узким зрачком-щелью
		local m = Instance.new("Model"); m.Name = "EvaKDemonEyes"; m.Parent = char
		local col = eq.eyes == "vipeyes" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(255, 50, 70)
		local first
		for side = -1, 1, 2 do
			local roll = math.rad(side * 16)
			local e = mkp(m, "Eye", Vector3.new(0.05, 0.2, 0.38), col, Enum.Material.Neon, Enum.PartType.Cylinder)
			weld(head :: BasePart, e, CFrame.new(side * 0.3, 0.12, -0.62) * CFrame.Angles(0, 0, roll) * CFrame.Angles(0, math.pi / 2, 0))
			local pu = mkp(m, "Pupil", Vector3.new(0.05, 0.19, 0.07), Color3.fromRGB(10, 0, 0), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
			weld(head :: BasePart, pu, CFrame.new(side * 0.3, 0.12, -0.645) * CFrame.Angles(0, 0, roll) * CFrame.Angles(0, math.pi / 2, 0))
			first = first or e
		end
		local pl = Instance.new("PointLight"); pl.Color = col; pl.Range = 8; pl.Brightness = 1; pl.Parent = first
	end
	if eq.crown and head then   -- корона грешника
		local m = Instance.new("Model"); m.Name = "EvaKCrown"; m.Parent = char
		local band = mkp(m, "Band", Vector3.new(0.3, 1.5, 1.5), (plr:GetAttribute("Donor") and Color3.fromRGB(255, 205, 60) or Color3.fromRGB(16, 10, 12)), (plr:GetAttribute("Donor") and Enum.Material.Metal or Enum.Material.Metal), Enum.PartType.Cylinder)
		weld(head :: BasePart, band, CFrame.new(0, 0.75, 0) * CFrame.Angles(0, 0, math.rad(90)))
		for i = 0, 6 do
			local a = i / 7 * math.pi * 2
			local sp = Instance.new("WedgePart")
			sp.Name = "Spike"; sp.Size = Vector3.new(0.2, 0.8 + (i % 2) * 0.5, 0.35)
			sp.Color = (plr:GetAttribute("Donor") and Color3.fromRGB(255, 205, 60) or Color3.fromRGB(30, 10, 12)); sp.Material = Enum.Material.Metal
			sp.CanCollide = false; sp.CanQuery = false; sp.CanTouch = false; sp.Massless = true; sp.CastShadow = false; sp.Parent = m
			weld(head :: BasePart, sp, CFrame.new(math.cos(a) * 0.72, 1.15 + (i % 2) * 0.25, math.sin(a) * 0.72) * CFrame.Angles(0, -a, 0))
		end
		local gem = mkp(m, "Gem", Vector3.new(0.3, 0.3, 0.12), Color3.fromRGB(255, 20, 20), Enum.Material.Neon)
		weld(head :: BasePart, gem, CFrame.new(0, 0.85, -0.78))
	end
	if eq.horns and head then   -- рога чудовища
		local m = Instance.new("Model"); m.Name = "EvaKHorns"; m.Parent = char
		for side = -1, 1, 2 do
			local h1 = mkp(m, "HornBase", Vector3.new(0.35, 0.7, 0.35), Color3.fromRGB(40, 6, 6), Enum.Material.SmoothPlastic)
			weld(head :: BasePart, h1, CFrame.new(side * 0.42, 0.75, -0.05) * CFrame.Angles(0, 0, math.rad(side * -12)))
			local h2 = mkp(m, "HornMid", Vector3.new(0.25, 0.7, 0.25), Color3.fromRGB(80, 8, 8), Enum.Material.SmoothPlastic)
			weld(head :: BasePart, h2, CFrame.new(side * 0.62, 1.3, -0.05) * CFrame.Angles(0, 0, math.rad(side * -28)))
			local h3 = mkp(m, "HornTip", Vector3.new(0.14, 0.55, 0.14), Color3.fromRGB(255, 40, 20), Enum.Material.Neon)
			weld(head :: BasePart, h3, CFrame.new(side * 0.88, 1.78, -0.05) * CFrame.Angles(0, 0, math.rad(side * -50)))
		end
	end
	if eq.tail and torso then   -- хвост со стрелкой
		local m = Instance.new("Model"); m.Name = "EvaKTail"; m.Parent = char
		local segs = { { 0, -0.9, 0.9, 0 }, { 0, -1.3, 1.5, 25 }, { 0, -1.4, 2.1, 50 }, { 0, -1.2, 2.6, 75 } }
		for i, sg in segs do
			local p = mkp(m, "TailSeg", Vector3.new(0.25, 0.25, 0.7), Color3.fromRGB(110, 10, 10), Enum.Material.SmoothPlastic)
			weld(torso :: BasePart, p, CFrame.new(sg[1], sg[2], sg[3]) * CFrame.Angles(math.rad(-sg[4]), 0, 0))
		end
		local tip = Instance.new("WedgePart"); tip.Name = "TailTip"; tip.Size = Vector3.new(0.12, 0.6, 0.6); tip.Color = Color3.fromRGB(255, 30, 20)
		tip.Material = Enum.Material.Neon; tip.CanCollide = false; tip.CanQuery = false; tip.CanTouch = false; tip.Massless = true; tip.Parent = m
		weld(torso :: BasePart, tip, CFrame.new(0, -0.9, 3.0) * CFrame.Angles(math.rad(-95), 0, 0))
	end
	if eq.lantern then   -- проклятый фонарь: светит тёмные комнаты (виден всем)
		local m = Instance.new("Model"); m.Name = "EvaKLantern"; m.Parent = char
		local root = char:FindFirstChild("HumanoidRootPart") or torso
		if root then
			local body = mkp(m, "LanternBody", Vector3.new(0.7, 1.1, 0.7), Color3.fromRGB(255, 50, 35), Enum.Material.Neon)
			weld(root :: BasePart, body, CFrame.new(1.7, -0.6, -0.4))
			local cap = mkp(m, "LanternCap", Vector3.new(0.9, 0.25, 0.9), Color3.fromRGB(20, 12, 12), Enum.Material.Metal)
			weld(root :: BasePart, cap, CFrame.new(1.7, 0.05, -0.4))
			local base = mkp(m, "LanternBase", Vector3.new(0.9, 0.25, 0.9), Color3.fromRGB(20, 12, 12), Enum.Material.Metal)
			weld(root :: BasePart, base, CFrame.new(1.7, -1.2, -0.4))
			local pl = Instance.new("PointLight"); pl.Color = Color3.fromRGB(255, 120, 90); pl.Range = 34; pl.Brightness = 2.4; pl.Shadows = true; pl.Parent = body
		end
	end
	if eq.amulet == "pentagram" and torso then   -- кулон-затмение: чёрный диск с золотым светящимся ободком
		local m = Instance.new("Model"); m.Name = "EvaKAmulet"; m.Parent = char
		local disc = mkp(m, "EclipseDisc", Vector3.new(0.12, 1.1, 1.1), Color3.fromRGB(8, 8, 12), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		weld(torso :: BasePart, disc, CFrame.new(0, 0.4, -0.72) * CFrame.Angles(0, math.rad(90), 0))
		local ringP = mkp(m, "EclipseRing", Vector3.new(0.08, 1.3, 1.3), Color3.fromRGB(255, 190, 90), Enum.Material.Neon, Enum.PartType.Cylinder)
		weld(torso :: BasePart, ringP, CFrame.new(0, 0.4, -0.7) * CFrame.Angles(0, math.rad(90), 0))
		local cover = mkp(m, "EclipseCover", Vector3.new(0.14, 1.15, 1.15), Color3.fromRGB(8, 8, 12), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		weld(torso :: BasePart, cover, CFrame.new(0.14, 0.4, -0.76) * CFrame.Angles(0, math.rad(90), 0))
		local pl = Instance.new("PointLight"); pl.Color = Color3.fromRGB(255, 190, 90); pl.Range = 6; pl.Brightness = 0.8; pl.Parent = ringP
	elseif eq.amulet and torso then   -- Eye of EvaK: бронзовый кулон с красным глазом
		local m = Instance.new("Model"); m.Name = "EvaKAmulet"; m.Parent = char
		local frame = mkp(m, "AmuletFrame", Vector3.new(0.9, 1.2, 0.18), Color3.fromRGB(120, 84, 40), Enum.Material.Metal, Enum.PartType.Ball)
		weld(torso :: BasePart, frame, CFrame.new(0, 0.4, -0.7))
		local iris = mkp(m, "AmuletIris", Vector3.new(0.5, 0.6, 0.1), Color3.fromRGB(255, 20, 20), Enum.Material.Neon, Enum.PartType.Ball)
		weld(torso :: BasePart, iris, CFrame.new(0, 0.4, -0.82))
		local pupil = mkp(m, "AmuletPupil", Vector3.new(0.18, 0.4, 0.1), Color3.fromRGB(0, 0, 0), Enum.Material.SmoothPlastic)
		weld(torso :: BasePart, pupil, CFrame.new(0, 0.4, -0.88))
	end
	-- титул над головой
	local old = char:FindFirstChild("EvaKTitleGui", true)
	if old then old:Destroy() end
	local ttext: string? = nil
	if eq.title == "custom" and d.Custom ~= "" then ttext = d.Custom
	elseif eq.title and ITEMS[eq.title] then ttext = ITEMS[eq.title].name end
	local isVip = d.Owned.vip == true
	if isVip then ttext = "[CarBon] " .. (ttext and ttext ~= "CarBon" and ttext or "") end
	if ttext and head then
		local bb = Instance.new("BillboardGui")
		bb.Name = "EvaKTitleGui"; bb.Size = UDim2.fromOffset(200, 26); bb.StudsOffset = Vector3.new(0, 2.6, 0)
		bb.AlwaysOnTop = false; bb.MaxDistance = 60; bb.Adornee = head; bb.Parent = head
		local l = Instance.new("TextLabel"); l.Size = UDim2.fromScale(1, 1); l.BackgroundTransparency = 1
		l.Text = ttext:upper(); l.Font = Enum.Font.GothamBold; l.TextSize = 15
		l.TextColor3 = (eq.title == "god") and Color3.fromRGB(255, 205, 60) or isVip and Color3.fromRGB(255, 70, 70) or Color3.fromHex(TITLE_COLOR[eq.title or ""] or "e63c32"); l.TextStrokeTransparency = 0.3; l.Parent = bb
		if eq.title == "god" then l.TextSize = 18; local gr = Instance.new("UIGradient"); gr.Color = ColorSequence.new(Color3.fromRGB(255, 240, 150), Color3.fromRGB(230, 150, 20)); gr.Parent = l end
	end
end

local function pushAttrs(plr: Player)
	local d = data[plr]
	if not d then return end
	local own = {}
	for id in d.Owned do table.insert(own, id) end
	table.sort(own)
	plr:SetAttribute("XOwned", table.concat(own, ","))
	plr:SetAttribute("XTitle", d.Equip.title or "")
	plr:SetAttribute("XVip", d.Owned.vip == true)
	local tt = ""
	if d.Equip.title == "custom" then tt = d.Custom elseif d.Equip.title and ITEMS[d.Equip.title] then tt = ITEMS[d.Equip.title].name end
	plr:SetAttribute("XTitleText", tt)
	plr:SetAttribute("XTitleColor", TITLE_COLOR[d.Equip.title or ""] or "d73c32")
	plr:SetAttribute("XFrame", d.Equip.frame or "")
	local eqs = {}
	for _, v in d.Equip do table.insert(eqs, v) end
	table.sort(eqs)
	plr:SetAttribute("XEquip", table.concat(eqs, ","))
end

local function grant(plr: Player, id: string): boolean
	local d = data[plr]
	if not d or not ITEMS[id] or d.Owned[id] then return false end
	d.Owned[id] = true
	pushAttrs(plr); save(plr)
	local n = ITEMS[id].name
	fx:FireClient(plr, "Say", "UNLOCKED: " .. n)
	return true
end

do   -- промокоды с титулами (EvaKServer вызывает этот хук)
	local gi = Instance.new("BindableEvent"); gi.Name = "EvaKGrantItem"; gi.Parent = ServerStorage
	local ALLOWED = { hacker = true, crown = true }
	gi.Event:Connect(function(plr: Player, id: any)
		if type(id) ~= "string" or not ALLOWED[id] then return end
		local d = data[plr]
		if not d then
			for _ = 1, 20 do task.wait(0.5); d = data[plr]; if d then break end end   -- данные ещё грузятся
			if not d then return end
		end
		grant(plr, id)
		if id == "crown" then d.Equip.crown = "crown" else d.Equip.title = id end
		pushAttrs(plr); applyCosmetics(plr); save(plr)
	end)
end

local function checkQuests(plr: Player)
	local d = data[plr]
	if not d then return end
	if (plr:GetAttribute("Badges") or 0) >= 1000 then grant(plr, "collector") end
	if d.Play >= 36000 then grant(plr, "veteran") end
end

local rc = ServerStorage:FindFirstChild("RunCompleted")
if rc then rc.Event:Connect(function(plr)
	grant(plr, "survivor")
	local d = data[plr]; if d then d.Done += 1 end
end) end
local rfail = ServerStorage:FindFirstChild("RunFailed")
if rfail then rfail.Event:Connect(function(plr) local d = data[plr]; if d then d.Failed += 1 end end) end

do   -- хук для EvaKTrade: предметы косметики (без админских и титулов)
	local api = Instance.new("BindableFunction"); api.Name = "EvaKTradeItems"; api.Parent = ServerStorage
	local function tradable(id) local it = ITEMS[id]; return it ~= nil and it.kind == "item" and it.how ~= "admin" and it.how ~= "vip" end
	api.OnInvoke = function(cmd, plr, ids, to)
		local d = data[plr]
		if not d then return false, "no data" end
		if cmd == "Inv" then
			local out = {}
			for _, id in ORDER do if d.Owned[id] and tradable(id) then table.insert(out, id) end end
			return true, out
		elseif cmd == "Check" then
			for id in ids or {} do
				if not tradable(id) or not d.Owned[id] then return false, "item missing: " .. tostring(id) end
			end
			return true
		elseif cmd == "Apply" then
			local dt = data[to]
			if not dt then return false, "no data" end
			for id in ids or {} do
				d.Owned[id] = nil
				if d.Equip[ITEMS[id].slot] == id then d.Equip[ITEMS[id].slot] = nil end
				dt.Owned[id] = true
			end
			pushAttrs(plr); pushAttrs(to); applyCosmetics(plr); applyCosmetics(to)
			task.spawn(save, plr); task.spawn(save, to)
			return true
		end
		return false, "unknown"
	end
end

BASE = function(plr: Player, action: any, a: any, b: any)
	local d = data[plr]
	if not d then return { ok = false } end
	if action == "Info" then
		checkQuests(plr)
		local list = {}
		for _, id in ORDER do
			local it = ITEMS[id]
			table.insert(list, { id = id, name = it.name, slot = it.slot, kind = it.kind, how = it.how, cost = it.cost, quest = it.quest,
				owned = d.Owned[id] == true, equipped = d.Equip[it.slot] == id, devil = it.devil == true, tcol = (it.kind == "title") and TITLE_COLOR[id] or nil })
		end
		return { ok = true, items = list, badges = plr:GetAttribute("Badges") or 0 }
	elseif action == "Buy" then
		local it = ITEMS[a]
		if type(a) ~= "string" or not it or it.how ~= "buy" or d.Owned[a] then return { ok = false, msg = "cannot" } end
		local sp = ServerStorage:FindFirstChild("EvaKSpend")
		if not sp or not sp:Invoke(plr, it.cost) then return { ok = false, msg = "not enough badges" } end
		grant(plr, a)
		return { ok = true }
	elseif action == "Equip" then
		local it = ITEMS[a]
		if type(a) ~= "string" or not it or not d.Owned[a] then return { ok = false } end
		d.Equip[it.slot] = a
		pushAttrs(plr); applyCosmetics(plr); save(plr)
		return { ok = true }
	elseif action == "Unequip" then
		if type(a) ~= "string" then return { ok = false } end
		d.Equip[a] = nil
		pushAttrs(plr); applyCosmetics(plr); save(plr)
		return { ok = true }
	end
	return { ok = false }
end

local runStart: {[Player]: number} = {}
-- ---------------- лор-записки ----------------
local NOTES = {
	{ title = "Note 1 - The Hotel",       at = 10, text = "The hotel was built over a hole in the world. Every guest checks in. Nobody remembers checking out." },
	{ title = "Note 2 - The First Owner", at = 25, text = "He signed the guest book first. His room number was never written down. Later, the book signed itself." },
	{ title = "Note 3 - The Staff",        at = 40, text = "Staff vanish one by one. The night manager left a message: 'It knows my name. It says it from behind me.'" },
	{ title = "Note 4 - EvaK",             at = 55, text = "EvaK did not arrive. EvaK was always here. The hotel just learned how to let it out." },
	{ title = "Note 5 - The Guest",        at = 70, text = "You wanted to be forgiven. You asked the wrong one. That is how you got a key to this place." },
	{ title = "Note 6 - The Fallen",       at = 80, key = true, text = "The Fallen were guests who looked back. They walk behind you now, so you never see their faces." },
	{ title = "Note 7 - The Preacher",     at = 88, key = true, text = "The Preacher borrows voices. It practised on a choir once. Nobody in the choir answers anymore." },
	{ title = "Note 8 - The Bellman",      at = 94, key = true, text = "When the bell rings, the hotel is hungry. The bellman only carries what the hotel wants to eat." },
	{ title = "Note 9 - The Witness",      at = 100, key = true, text = "The Witness is not a monster. It only watches. That is the cruelest thing the hotel does." },
	{ title = "Note 10 - The Reason",      at = nil, text = "You were never lost. You were sent. The throne is empty because the owner is the one reading this." },
}
local function bindEv(name: string): BindableEvent
	local b = Instance.new("BindableEvent"); b.Name = name; b.Parent = ServerStorage
	return b
end
local function unlockNote(plr: Player, i: number)
	local d = data[plr]
	if not d or d.Notes[tostring(i)] then return end
	d.Notes[tostring(i)] = true
	save(plr)
	fx:FireClient(plr, "Say", "LORE NOTE #" .. i .. " FOUND  (open the ? menu)")
end
local function evalNotes(plr: Player)
	local d = data[plr]
	if not d then return end
	for i, nt in NOTES do
		if nt.at and d.Best >= nt.at and (not nt.key or d.Owned.ownerkey) then unlockNote(plr, i) end
	end
end
bindEv("EvaKDoors").Event:Connect(function(plr, n)
	local d = data[plr]
	if not d or type(n) ~= "number" then return end
	if n > d.Best then d.Best = n end
	evalNotes(plr)
	if n == 100 and runStart[plr] then   -- скоростные титулы: добежал до 100-й двери
		local el = os.clock() - runStart[plr]
		if el < 60 then grant(plr, "lol") end
		if el < 300 then grant(plr, "speedrun") end
	end
end)
bindEv("EvaKReached666").Event:Connect(function(plr) unlockNote(plr, 10) end)
bindEv("EvaKEnding").Event:Connect(function(plr, kind)   -- концовка: демон (много урона) / ангел (мало): титул, рамка и 500 бейджей
	local d = data[plr]
	if not d then return end
	local title, frame = (kind == "demon") and "endemon" or "enangel", (kind == "demon") and "frame_demon" or "frame_seraph"
	local first = not d.Owned[title]
	d.Owned[title] = true; d.Owned[frame] = true
	if first then d.Equip.title = title end
	pushAttrs(plr); applyCosmetics(plr); save(plr)
	local g = ServerStorage:FindFirstChild("EvaKGrantBadges")
	if g and first then g:Fire(plr, 500) end
	fx:FireClient(plr, "Say", (kind == "demon") and "Demon ending: title, frame and 500 badges!" or "Angel ending: title, frame and 500 badges!")
end)

-- ---------------- кейсы ----------------
local CASES = {
	rusty = { name = "Rusty Case", badges = 600, refund = 180,   -- ржавый: титулы, значки, рамки и простая косметика
		loot = { { "sinner", 20 }, { "believer", 12 }, { "pin_cross", 12 }, { "pin_heart", 10 }, { "frame_bronze", 12 }, { "frame_silver", 8 }, { "aura", 8 }, { "lantern", 6 }, { "watch", 6 }, { "demoneyes", 4 }, { "frame_gold", 2 } } },
	cursed = { name = "Cursed Case", badges = 2500, refund = 750,   -- проклятый: дьявольская косметика, крылья, неоновые рамки
		loot = { { "demoneyes", 16 }, { "devhorns", 14 }, { "devtail", 12 }, { "pin_skull", 10 }, { "pin_flame", 8 }, { "frame_blood", 10 }, { "frame_neon", 6 }, { "wings", 8 }, { "hellaura", 5 }, { "pentagram", 4 }, { "hellspawn", 3 }, { "pin_moon", 4 } } },
	evak = { name = "EvaK Case (Robux)", product = 0, refund = 1000,   -- product: ID Developer Product (Robux). 0 = ещё не задан
		loot = { { "devwings", 22 }, { "hellaura", 18 }, { "pentagram", 14 }, { "eyeofevak", 14 }, { "ownerkey", 12 }, { "frame_devil", 10 }, { "wings", 6 }, { "sixsix", 4 } } },
}
local CASE_ORDER = { "rusty", "cursed", "evak" }
local function roll(caseId: string): string
	local c = CASES[caseId]
	local tot = 0
	for _, e in c.loot do tot += e[2] end
	local r = math.random() * tot
	for _, e in c.loot do r -= e[2]; if r <= 0 then return e[1] end end
	return c.loot[1][1]
end
local function openCase(plr: Player, caseId: string)
	local d = data[plr]
	local id = roll(caseId)
	local dup = d.Owned[id] == true
	d.Cases += 1
	local refund = 0
	if dup then
		refund = CASES[caseId].refund
		local g = ServerStorage:FindFirstChild("EvaKGrantBadges")
		if g then g:Fire(plr, refund) end
	else
		d.Owned[id] = true
		pushAttrs(plr); save(plr)
	end
	return { ok = true, id = id, name = ITEMS[id].name, dup = dup, refund = refund, case = caseId }
end

do
	local cp = Instance.new("BindableFunction"); cp.Name = "EvaKCaseProduct"; cp.Parent = ServerStorage
	cp.OnInvoke = function(plr, productId)
		for cid, c in CASES do
			if c.product and c.product ~= 0 and c.product == productId and data[plr] then
				fx:FireClient(plr, "CaseWon", openCase(plr, cid))
				return true
			end
		end
		return false
	end
end


-- ---------- VIP (Game Pass 259 R$) ----------
local VIP_PASS_ID = 2092239089   -- геймпасс CarBon
local MarketplaceService = game:GetService("MarketplaceService")
local function applyVip(plr: Player)
	local d = data[plr]
	if not d then return end
	local new = not d.Owned.vip
	d.Owned.vip = true; d.Owned.vipaura = true; d.Owned.vipeyes = true
	if new then d.Equip.title = "vip"; fx:FireClient(plr, "Say", "CarBon unlocked: title, red-white aura and eyes") end
	pushAttrs(plr); applyCosmetics(plr); save(plr)
	local gt = ServerStorage:FindFirstChild("EvaKGrantToy")
	if gt then gt:Fire(plr, "CARBONCAR") end   -- питомец-машина (только за CarBon)
end
local function checkVip(plr: Player)
	if VIP_PASS_ID == 0 then return end
	if isAdmin(plr) then   -- владелец/админ «владеет» всеми своими геймпассами сам - CarBon ему автоматически не выдаём
		local t0 = os.clock()
		while data[plr] and not data[plr].Loaded and os.clock() - t0 < 30 do task.wait(0.3) end
		local d = data[plr]
		if d and (d.Owned.vip or d.Owned.vipaura or d.Owned.vipeyes) then
			d.Owned.vip = nil; d.Owned.vipaura = nil; d.Owned.vipeyes = nil
			if d.Equip.title == "vip" then d.Equip.title = nil end
			pushAttrs(plr); applyCosmetics(plr); save(plr)
		end
		return
	end
	local ok, owns = pcall(function() return MarketplaceService:UserOwnsGamePassAsync(plr.UserId, VIP_PASS_ID) end)
	if ok and owns then applyVip(plr) end
end
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(plr, passId, purchased)
	if purchased and VIP_PASS_ID ~= 0 and passId == VIP_PASS_ID then applyVip(plr) end
end)
EXTRA.VipInfo = function(plr) return { ok = true, passId = VIP_PASS_ID, owned = data[plr] ~= nil and data[plr].Owned.vip == true } end

-- ---------- игроки сервера / приглашения / чужая статистика ----------
EXTRA.Players = function(plr)
	local list = {}
	for _, p in Players:GetPlayers() do
		table.insert(list, { id = p.UserId, name = p.DisplayName, user = p.Name, title = p:GetAttribute("XTitleText") or "", tcol = p:GetAttribute("XTitleColor") or "d73c32", vip = p:GetAttribute("XVip") == true,
			inRun = p:GetAttribute("EvaKInRun") == true, owner = p:GetAttribute("EvaKOwner") == true, frame = p:GetAttribute("XFrame") or "", self = (p == plr) })
	end
	table.sort(list, function(a, b) if a.self ~= b.self then return a.self end return a.name < b.name end)
	return { ok = true, players = list }
end
EXTRA.StatsOf = function(plr, uid)
	local p = type(uid) == "number" and Players:GetPlayerByUserId(uid)
	local d = p and data[p]
	if not d then return { ok = false } end
	local pins, acc, ownedN = {}, {}, 0
	for _, id in ORDER do
		local it = ITEMS[id]
		if d.Owned[id] then
			ownedN += 1
			if it.kind == "pin" then table.insert(pins, id) end
			if it.kind == "item" and d.Equip[it.slot] == id then table.insert(acc, it.name) end
		end
	end
	return { ok = true, id = p.UserId, self = (p == plr), name = p.DisplayName, user = p.Name, title = p:GetAttribute("XTitleText") or "", tcol = p:GetAttribute("XTitleColor") or "d73c32", vip = d.Owned.vip == true, owner = p:GetAttribute("EvaKOwner") == true,
		play = d.Play, badges = p:GetAttribute("Badges") or 0, snow = p:GetAttribute("Snow") or 0, cases = d.Cases, best = d.Best, done = d.Done, failed = d.Failed,
		frame = d.Equip.frame or "", pins = pins, acc = acc, owned = ownedN }
end
local lastInvite: {[Player]: number} = {}
EXTRA.Invite = function(plr, uid)
	local p = type(uid) == "number" and Players:GetPlayerByUserId(uid)
	if not p or p == plr then return { ok = false, msg = "player not found" } end
	if os.clock() - (lastInvite[plr] or 0) < 3 then return { ok = false, msg = "wait a moment" } end
	local api = ServerStorage:FindFirstChild("EvaKLobbyApi")
	local lobId = api and api:Invoke("Info", plr)
	if not lobId then return { ok = false, msg = "create a lobby first" } end
	lastInvite[plr] = os.clock()
	fx:FireClient(p, "LobbyInvite", plr.DisplayName, lobId)
	return { ok = true }
end
EXTRA.JoinInvite = function(plr, lobId)
	local api = ServerStorage:FindFirstChild("EvaKLobbyApi")
	if not api or type(lobId) ~= "number" then return { ok = false } end
	local ok, msg = api:Invoke("Join", plr, lobId)
	return { ok = ok == true, msg = msg }
end

-- ---------- админ: выдать титул (существующий или любой текст) ----------
EXTRA.AdminTitles = function(plr)
	if not isAdmin(plr) then return { ok = false } end
	local out = {}
	for _, id in ORDER do if ITEMS[id].kind == "title" and id ~= "oldgod" and id ~= "god" then table.insert(out, { id = id, name = ITEMS[id].name }) end end
	return { ok = true, titles = out }
end
EXTRA.AdminTitle = function(plr, uid, mode, value)
	if not isAdmin(plr) then return { ok = false, msg = "no access" } end
	local p = type(uid) == "number" and Players:GetPlayerByUserId(uid)
	local d = p and data[p]
	if not d then return { ok = false, msg = "player must be on this server" } end
	if mode == "give" then
		local it = type(value) == "string" and ITEMS[value]
		if not it or it.kind ~= "title" then return { ok = false, msg = "unknown title" } end
		if value == "oldgod" then return { ok = false, msg = "Old God is given only at the FIRST Admin Abuse" } end
		if value == "god" then return { ok = false, msg = "GOD is only for the owner" } end
		d.Owned[value] = true; d.Equip.title = value
	elseif mode == "custom" then
		local t = type(value) == "string" and value:gsub("[<>]", ""):match("^%s*(.-)%s*$") or ""
		if #t < 1 or #t > 24 then return { ok = false, msg = "text 1-24 characters" } end
		d.Custom = t; d.Equip.title = "custom"
	elseif mode == "clear" then
		d.Equip.title = nil
	else
		return { ok = false }
	end
	pushAttrs(p); applyCosmetics(p); save(p)
	return { ok = true, msg = "done" }
end
EXTRA.Notes = function(plr)
	local d = data[plr]
	if not d then return { ok = false } end
	evalNotes(plr)
	local out = {}
	for i, nt in NOTES do
		local got = d.Notes[tostring(i)] == true
		local hint = nt.at and ("Break " .. nt.at .. " doors" .. (nt.key and " (needs Owner's Key)" or "")) or "Reach Room 666"
		table.insert(out, { i = i, title = nt.title, text = got and nt.text or nil, hint = hint })
	end
	return { ok = true, notes = out, best = d.Best }
end
EXTRA.Stats = function(plr)
	local d = data[plr]
	if not d then return { ok = false } end
	local n, items = 0, 0
	for _ in d.Notes do n += 1 end
	for _ in d.Owned do items += 1 end
	return { ok = true, play = d.Play, badges = plr:GetAttribute("Badges") or 0, snow = plr:GetAttribute("Snow") or 0, cases = d.Cases,
		best = d.Best, done = d.Done, failed = d.Failed, visits = d.Visits, notes = n, items = items }
end
EXTRA.Cases = function(plr)
	local out = {}
	for _, cid in CASE_ORDER do
		local c = CASES[cid]
		local loot, tot = {}, 0
		for _, e in c.loot do tot += e[2] end
		for _, e in c.loot do table.insert(loot, { name = ITEMS[e[1]].name, pct = math.floor(e[2] / tot * 1000) / 10 }) end
		table.insert(out, { id = cid, name = c.name, badges = c.badges, product = c.product, loot = loot, refund = c.refund })
	end
	return { ok = true, cases = out, badges = plr:GetAttribute("Badges") or 0 }
end
EXTRA.OpenCase = function(plr, cid)
	local c = type(cid) == "string" and CASES[cid]
	if not c or not c.badges or not data[plr] then return { ok = false, msg = "use Robux for this case" } end
	local sp = ServerStorage:FindFirstChild("EvaKSpend")
	if not sp or not sp:Invoke(plr, c.badges) then return { ok = false, msg = "not enough badges" } end
	return openCase(plr, cid)
end
print("[EvaKExtra] обработчики кейсов/статистики/титулов подключены")
-- ---------------- приветствия лобби ----------------
local function greet(plr: Player)
	local d = data[plr]
	if not d then return end
	d.Visits += 1
	save(plr)
	local lines
	if d.Visits == 1 then lines = { "Welcome back, Guest.", "I remember you." }
	elseif d.Visits == 2 then lines = { "You came back. Interesting." }
	else
		local pool = { { "You came back. Interesting." }, { "Welcome back, " .. plr.DisplayName .. "." }, { "I remember you." }, { "Room " .. math.random(1, 100) .. " was waiting for you." } }
		lines = pool[math.random(1, #pool)]
	end
	task.delay(5, function() if plr.Parent then fx:FireClient(plr, "Greet", lines) end end)
end

-- ---------------- монстры ----------------
local function groundY(hrp: BasePart): number return hrp.Position.Y - 3 end

local function model(name: string): Model
	local m = Instance.new("Model"); m.Name = name
	return m
end
local function part(m: Model, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = true
	p.Size = size; p.CFrame = cf; p.Color = color; p.Material = mat or Enum.Material.SmoothPlastic
	if shape then p.Shape = shape end
	p.Parent = m
	return p
end
local function glow(m: Model, cf: CFrame, color: Color3, size: number)
	local p = part(m, Vector3.new(size, size * 0.6, size * 0.3), cf, color, Enum.Material.Neon)
	return p
end

-- человекоподобная фигура: s - масштаб, origin - CFrame ног (стоит на полу, смотрит -Z)
local function figure(name: string, s: number, body: Color3, opts: any): Model
	opts = opts or {}
	local m = model(name)
	local o = CFrame.new()
	local legH, torsoH = 3.2 * s, 3 * s
	part(m, Vector3.new(0.9 * s, legH, 1 * s), o * CFrame.new(-0.55 * s, legH / 2, 0), body)
	part(m, Vector3.new(0.9 * s, legH, 1 * s), o * CFrame.new(0.55 * s, legH / 2, 0), body)
	part(m, Vector3.new(2.4 * s, torsoH, 1.3 * s), o * CFrame.new(0, legH + torsoH / 2, 0), body)
	local armL = opts.armLen or 3.4
	part(m, Vector3.new(0.8 * s, armL * s, 0.8 * s), o * CFrame.new(-1.6 * s, legH + torsoH - armL * s / 2 - 0.1 * s, 0), body)
	part(m, Vector3.new(0.8 * s, armL * s, 0.8 * s), o * CFrame.new(1.6 * s, legH + torsoH - armL * s / 2 - 0.1 * s, 0), body)
	local headY = legH + torsoH + 0.9 * s
	local head = part(m, Vector3.new(1.6 * s, 1.8 * s, 1.5 * s), o * CFrame.new(0, headY, 0), opts.headColor or body)
	if opts.eye then
		glow(m, o * CFrame.new(-0.4 * s, headY + 0.1 * s, -0.78 * s), opts.eye, 0.45 * s)
		glow(m, o * CFrame.new(0.4 * s, headY + 0.1 * s, -0.78 * s), opts.eye, 0.45 * s)
	end
	if opts.hat then   -- красная шапочка Bellman
		part(m, Vector3.new(1.7 * s, 0.9 * s, 1.6 * s), o * CFrame.new(0, headY + 1.2 * s, 0), opts.hat)
	end
	m.PrimaryPart = head
	return m
end

local function place(m: Model, cf: CFrame)
	m:PivotTo(cf)
end

local monsters: {[Player]: {any}} = {}

local function track(plr: Player, m: Model, life: number, step: (number, BasePart, Humanoid?) -> boolean)
	-- step(dt, hrp) возвращает true когда монстра нужно убрать
	m:SetAttribute("EvaKMonster", true)
	m.Parent = workspace
	local t0 = os.clock()
	local last = t0
	local conn
	conn = RunService.Heartbeat:Connect(function()
		local now = os.clock()
		local dt = now - last; last = now
		local char = plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp or not m.Parent or now - t0 > life or not inRun(plr) then
			conn:Disconnect(); m:Destroy(); return
		end
		local ok, done = pcall(step, dt, hrp)
		if not ok or done then conn:Disconnect(); m:Destroy() end
	end)
end

local function flat(v: Vector3): Vector3 return Vector3.new(v.X, 0, v.Z) end

-- движение к игроку; возвращает расстояние
local function chase(m: Model, hrp: BasePart, speed: number, dt: number, gy: number, yOff: number?): number
	local pos = m:GetPivot().Position
	local target = Vector3.new(hrp.Position.X, gy + (yOff or 0), hrp.Position.Z)
	local dir = target - Vector3.new(pos.X, gy + (yOff or 0), pos.Z)
	local dist = flat(dir).Magnitude
	if dist > 0.1 then
		local step = math.min(dist, speed * dt)
		local np = Vector3.new(pos.X, gy + (yOff or 0), pos.Z) + flat(dir).Unit * step
		m:PivotTo(CFrame.lookAt(np, np + flat(dir).Unit))
	end
	return dist
end

local function pivotFeet(m: Model, cf: CFrame)   -- PrimaryPart=голова, поэтому сдвиг по низу делаем через bounding box
	m:PivotTo(cf)
end

local SPAWN = {}

SPAWN.fallen = function(plr, hrp)   -- появляется за спиной
	local gy = groundY(hrp)
	local m = figure("Fallen", 1.15, Color3.fromRGB(10, 10, 12), { eye = Color3.fromRGB(255, 20, 20), armLen = 3.8 })
	local behind = hrp.Position - hrp.CFrame.LookVector * 16
	local hh = m:GetExtentsSize().Y
	m:PivotTo(CFrame.new(Vector3.new(behind.X, gy + hh / 2 - 0.2, behind.Z)))
	fx:FireClient(plr, "Say", "Something is behind you...")
	track(plr, m, 9, function(dt, h)
		local d = chase(m, h, 21, dt, gy + m:GetExtentsSize().Y / 2 - 0.2)
		if d < 4 then damage(plr, 25); fx:FireClient(plr, "Scare"); return true end
		return false
	end)
end

SPAWN.preacher = function(plr, hrp)   -- имитирует голос игрока
	local gy = groundY(hrp)
	local m = figure("Preacher", 1, Color3.fromRGB(40, 30, 28), { headColor = Color3.fromRGB(210, 205, 195), armLen = 3 })
	local pos = hrp.Position + hrp.CFrame.LookVector * 42
	m:PivotTo(CFrame.new(pos.X, gy + m:GetExtentsSize().Y / 2, pos.Z) * CFrame.Angles(0, math.rad(180), 0))
	fx:FireClient(plr, "Say", plr.DisplayName .. ": «...help me... I'm here... come closer...»")
	if CONFIG.WhisperSoundId ~= "" then
		local s = Instance.new("Sound"); s.SoundId = CONFIG.WhisperSoundId; s.Volume = 1; s.RollOffMaxDistance = 80; s.Parent = m.PrimaryPart; s:Play()
	end
	track(plr, m, 16, function(dt, h)
		local d = (flat(h.Position) - flat(m:GetPivot().Position)).Magnitude
		m:PivotTo(CFrame.lookAt(m:GetPivot().Position, Vector3.new(h.Position.X, m:GetPivot().Position.Y, h.Position.Z)))
		if d < 10 then damage(plr, 20); fx:FireClient(plr, "Scare"); return true end
		return false
	end)
end

SPAWN.evak = function(plr, hrp)   -- главный преследователь
	local gy = groundY(hrp)
	local m = figure("EvaK", 1.5, Color3.fromRGB(6, 6, 8), { eye = Color3.fromRGB(255, 10, 10), armLen = 4.2 })
	local pos = hrp.Position + hrp.CFrame.LookVector * 55
	m:PivotTo(CFrame.new(pos.X, gy + m:GetExtentsSize().Y / 2, pos.Z))
	fx:FireClient(plr, "Say", "EvaK is hunting you.")
	track(plr, m, 28, function(dt, h)
		local d = chase(m, h, 15, dt, gy + m:GetExtentsSize().Y / 2)
		if d < 5 then damage(plr, 40); fx:FireClient(plr, "Scare"); return true end
		return false
	end)
end

SPAWN.guest = function(plr, hrp)   -- стоит в конце коридора, идёт когда отвернёшься
	local gy = groundY(hrp)
	local m = figure("TheGuest", 1.3, Color3.fromRGB(12, 12, 16), { headColor = Color3.fromRGB(215, 210, 200), armLen = 5 })
	local pos = hrp.Position + hrp.CFrame.LookVector * 70
	m:PivotTo(CFrame.new(pos.X, gy + m:GetExtentsSize().Y / 2, pos.Z))
	fx:FireClient(plr, "Say", "Don't turn your back on the Guest.")
	track(plr, m, 45, function(dt, h)
		local p = m:GetPivot().Position
		local toM = flat(p - h.Position)
		local looking = toM.Magnitude > 0.1 and h.CFrame.LookVector:Dot(toM.Unit) > 0.35
		if not looking then
			local d = chase(m, h, 17, dt, p.Y)
			if d < 4 then damage(plr, 30); fx:FireClient(plr, "Scare"); return true end
		else
			m:PivotTo(CFrame.lookAt(p, Vector3.new(h.Position.X, p.Y, h.Position.Z)))
		end
		return false
	end)
end

SPAWN.crawl = function(plr, hrp)   -- ползёт по потолку
	local gy = groundY(hrp)
	local m = figure("TheCrawl", 1, Color3.fromRGB(70, 60, 52), { eye = Color3.fromRGB(230, 230, 200), armLen = 3.6 })
	local ceilY = hrp.Position.Y + 9.5
	local pos = hrp.Position + hrp.CFrame.LookVector * 38
	m:PivotTo(CFrame.new(pos.X, ceilY - m:GetExtentsSize().Y / 2, pos.Z) * CFrame.Angles(math.rad(180), 0, 0))
	fx:FireClient(plr, "Say", "Look up.")
	track(plr, m, 18, function(dt, h)
		local p = m:GetPivot().Position
		local dir = flat(h.Position - p)
		local d = dir.Magnitude
		if d > 0.2 then
			local np = p + dir.Unit * math.min(d, 19 * dt)
			m:PivotTo(CFrame.lookAt(np, np + dir.Unit) * CFrame.Angles(0, 0, math.rad(180)))
		end
		if d < 5 then damage(plr, 25); fx:FireClient(plr, "Scare"); return true end
		return false
	end)
end

do   -- фонарик: свет на потолочных/настенных монстров прогоняет их
	local hit = Instance.new("RemoteEvent"); hit.Name = "EvaKFlashHit"; hit.Parent = ReplicatedStorage
	local lastHit: {[Player]: number} = {}
	hit.OnServerEvent:Connect(function(plr: Player, m: any)
		if typeof(m) ~= "Instance" or not m:IsA("Model") or not m.Parent then return end
		if m.Name ~= "TheCrawl" and m.Name ~= "WallCrawler" then return end
		if not m:GetAttribute("EvaKMonster") then return end
		if not string.find("," .. tostring(plr:GetAttribute("RunItems") or "") .. ",", ",FLASH,", 1, true) then return end
		local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp or (m:GetPivot().Position - hrp.Position).Magnitude > 95 then return end
		if os.clock() - (lastHit[plr] or 0) < 0.5 then return end
		lastHit[plr] = os.clock()
		m:Destroy()
		fx:FireClient(plr, "Say", "It burns away in the light...")
	end)
end

SPAWN.wallcrawl = function(plr, hrp)   -- ползёт по СТЕНЕ рядом, дёргаясь, и бросается, когда подползёт близко
	local gy = groundY(hrp)
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { plr.Character :: Instance }
	params.FilterType = Enum.RaycastFilterType.Exclude
	local best
	for _, dirx in { 1, -1 } do
		local r = workspace:Raycast(hrp.Position, Vector3.new(dirx * 45, 0, 0), params)
		if r and (not best or r.Distance < best.Distance) then best = r end
	end
	if not best then SPAWN.fallen(plr, hrp) return end
	local nx = best.Normal.X >= 0 and 1 or -1     -- нормаль стены: куда смотрит её поверхность
	local m = figure("WallCrawler", 1.1, Color3.fromRGB(14, 12, 12), { eye = Color3.fromRGB(255, 255, 255), armLen = 4.4 })
	local wallX = best.Position.X + nx * 0.9
	local y0 = hrp.Position.Y + 2.5
	local startZ = hrp.Position.Z + (math.random() < 0.5 and 1 or -1) * 40
	local function wallCF(z: number, y: number, lookZ: number)
		return CFrame.lookAt(Vector3.new(wallX, y, z), Vector3.new(wallX, y, z + lookZ)) * CFrame.Angles(0, 0, math.rad(90 * nx))
	end
	m:PivotTo(wallCF(startZ, y0, 1))
	fx:FireClient(plr, "Say", "Something is crawling on the wall...")
	local dropped = false
	local t = 0
	track(plr, m, 22, function(dt, h)
		t += dt
		local p = m:GetPivot().Position
		if not dropped then
			local dz = h.Position.Z - p.Z
			local dir = dz >= 0 and 1 or -1
			-- рывками: замирает и дёргается, как насекомое
			local burst = (math.sin(t * 5) > -0.25) and 1 or 0.08
			local nz = p.Z + dir * math.min(math.abs(dz), 17 * dt * burst)
			local ny = y0 + math.sin(t * 9) * 0.5 + math.sin(t * 2.3) * 1.2
			m:PivotTo(wallCF(nz, ny, dir))
			if math.abs(dz) < 12 then dropped = true; fx:FireClient(plr, "Shake", 0.6) end
			return false
		end
		-- прыжок на игрока
		local dir = h.Position - p
		local d = dir.Magnitude
		if d < 4 then damage(plr, 30); fx:FireClient(plr, "Scare"); return true end
		local np = p + dir.Unit * math.min(d, 30 * dt)
		m:PivotTo(CFrame.lookAt(np, np + dir.Unit))
		return false
	end)
end

SPAWN.witness = function(plr, hrp)   -- смотрит из окна/из-за стены двумя белыми глазами
	local m = model("TheWitness")
	local side = (math.random() < 0.5) and -1 or 1
	local base = part(m, Vector3.new(4, 7, 1), CFrame.new(), Color3.fromRGB(4, 4, 4))
	local e1 = part(m, Vector3.new(0.9, 0.9, 0.2), CFrame.new(), Color3.fromRGB(255, 255, 255), Enum.Material.Neon, Enum.PartType.Ball)
	local e2 = part(m, Vector3.new(0.9, 0.9, 0.2), CFrame.new(), Color3.fromRGB(255, 255, 255), Enum.Material.Neon, Enum.PartType.Ball)
	base.Transparency = 0.15
	m.PrimaryPart = base
	local function put(h)
		local p = Vector3.new(h.Position.X + side * 12.5, h.Position.Y + 0.5, h.Position.Z + 6)
		local cf = CFrame.lookAt(p, Vector3.new(h.Position.X, p.Y, h.Position.Z))
		base.CFrame = cf
		e1.CFrame = cf * CFrame.new(-0.8, 1.6, -0.55); e2.CFrame = cf * CFrame.new(0.8, 1.6, -0.55)
	end
	put(hrp)
	fx:FireClient(plr, "Say", "Someone is watching you through the walls.")
	track(plr, m, 13, function(dt, h) put(h); return false end)
end

-- Стук в окно: бледный силуэт прижат к стеклу ближайшего окна, стучит всё чаще, потом разбивает стекло и бросается
SPAWN.knocker = function(plr, hrp)
	local best, bd = nil, 70
	for _, w in workspace:GetDescendants() do
		if w.Name == "WinSky" and w:IsA("BasePart") then
			local d = (flat(w.Position) - flat(hrp.Position)).Magnitude
			if d < bd then best, bd = w, d end
		end
	end
	if not best then return SPAWN.witness(plr, hrp) end
	local glass: BasePart? = nil
	for _, w in workspace:GetDescendants() do
		if w.Name == "WinGlass" and w:IsA("BasePart") and (w.Position - best.Position).Magnitude < 1 then glass = w; break end
	end
	local sx = (best.Position.X > hrp.Position.X) and 1 or -1       -- окно на стороне sx, игрок стоит с другой
	local wx = best.Position.X - sx * 0.18
	local yc, z = best.Position.Y, best.Position.Z
	local m = model("WindowKnocker")
	local PALE, DARK = Color3.fromRGB(176, 170, 160), Color3.fromRGB(4, 4, 5)
	local function disc(w, h, y, dz, c, mat) return part(m, Vector3.new(0.05, h, w), CFrame.new(wx, y, z + dz), c, mat, Enum.PartType.Cylinder) end
	disc(2.6, 2.0, yc + 0.9, 0, PALE)                                  -- лицо
	disc(0.5, 0.5, yc + 1.2, -0.5, Color3.fromRGB(255, 255, 255), Enum.Material.Neon)   -- глаза
	disc(0.5, 0.5, yc + 1.2, 0.5, Color3.fromRGB(255, 255, 255), Enum.Material.Neon)
	local mouth = part(m, Vector3.new(0.05, 1.1, 0.7), CFrame.new(wx - sx * 0.01, yc + 0.2, z), DARK)   -- рот
	part(m, Vector3.new(0.05, 6, 2.4), CFrame.new(wx, yc - 3.2, z), DARK)                              -- тело
	local hands = { disc(1.0, 1.0, yc - 0.5, -2.0, PALE), disc(1.0, 1.0, yc - 0.5, 2.0, PALE) }
	local arms = { part(m, Vector3.new(0.05, 0.4, 2.0), CFrame.new(wx, yc - 1.5, z - 1.0), DARK), part(m, Vector3.new(0.05, 0.4, 2.0), CFrame.new(wx, yc - 1.5, z + 1.0), DARK) }
	m.PrimaryPart = hands[1]
	m.Parent = workspace
	m:SetAttribute("EvaKMonster", true)
	fx:FireClient(plr, "Say", "Knock... knock... Something is at the window.")
	local function knock(i: number)
		local h = hands[i]
		h.CFrame = h.CFrame * CFrame.new(0, 0, 0)
		local cf = h.CFrame
		h.CFrame = cf * CFrame.new(0, 0.7, 0); task.wait(0.07); h.CFrame = cf
		fx:FireClient(plr, "Shake", 0.18)
		if CONFIG.KnockSoundId ~= "" then
			local sd = Instance.new("Sound"); sd.SoundId = CONFIG.KnockSoundId; sd.Volume = 1.6; sd.RollOffMaxDistance = 90; sd.Parent = h; sd:Play(); game:GetService("Debris"):AddItem(sd, 3)
		end
	end
	local alive = true
	task.spawn(function()
		local gap = 1.1
		local t0 = os.clock()
		while alive and m.Parent and os.clock() - t0 < 14 and inRun(plr) do
			local c = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not c then break end
			if (flat(c.Position) - flat(best.Position)).Magnitude > 55 then break end   -- ушёл далеко - сдался
			knock(1); task.wait(gap * 0.5); knock(2); task.wait(gap)
			gap = math.max(0.25, gap * 0.82)
			mouth.Size = Vector3.new(0.05, 1.1 + (os.clock() - t0) * 0.14, 0.7 + (os.clock() - t0) * 0.04)
		end
		alive = false
		local c = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if c and m.Parent and inRun(plr) and (flat(c.Position) - flat(best.Position)).Magnitude <= 55 then
			-- разбивает стекло и врывается
			fx:FireClient(plr, "Shake", 1.2)
			if glass then glass.Transparency = 1 end
			local pe = Instance.new("ParticleEmitter"); pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"; pe.Color = ColorSequence.new(Color3.fromRGB(200, 225, 255))
			pe.Size = NumberSequence.new(0.5, 0); pe.Lifetime = NumberRange.new(0.6, 1.2); pe.Speed = NumberRange.new(10, 28); pe.SpreadAngle = Vector2.new(60, 60); pe.Rate = 0
			pe.EmitterDirection = (sx == 1) and Enum.NormalId.Left or Enum.NormalId.Right; pe.Parent = hands[1]; pe:Emit(60)
			m:Destroy()
			local gy = groundY(c)
			local mon = figure("WindowKnocker", 1.15, Color3.fromRGB(8, 8, 10), { eye = Color3.fromRGB(255, 255, 255), headColor = Color3.fromRGB(176, 170, 160), armLen = 4 })
			mon:PivotTo(CFrame.new(wx - sx * 1.5, gy + mon:GetExtentsSize().Y / 2, z))
			track(plr, mon, 9, function(dt, h)
				local d = chase(mon, h, 24, dt, gy + mon:GetExtentsSize().Y / 2)
				if d < 4 then damage(plr, 35); fx:FireClient(plr, "Scare"); return true end
				return false
			end)
			task.delay(10, function() if glass and glass.Parent then glass.Transparency = 0.8 end end)
		else
			if m.Parent then m:Destroy() end
		end
	end)
	track(plr, m, 16, function() return not alive and not m.Parent end)
end

SPAWN.bellman = function(plr, hrp)   -- звонит и начинает погоню
	local gy = groundY(hrp)
	local m = figure("TheBellman", 1.1, Color3.fromRGB(150, 24, 20), { headColor = Color3.fromRGB(196, 190, 170), hat = Color3.fromRGB(190, 30, 24), armLen = 3.4 })
	local pos = hrp.Position + hrp.CFrame.LookVector * 34
	m:PivotTo(CFrame.new(pos.X, gy + m:GetExtentsSize().Y / 2, pos.Z) * CFrame.Angles(0, math.rad(180), 0))
	fx:FireClient(plr, "Say", "DING! DING! — the Bellman rings. RUN!")
	if CONFIG.BellSoundId ~= "" then
		local s = Instance.new("Sound"); s.SoundId = CONFIG.BellSoundId; s.Volume = 2; s.RollOffMaxDistance = 120; s.Parent = m.PrimaryPart; s:Play()
	end
	local t = 0
	track(plr, m, 16, function(dt, h)
		t += dt
		if t < 3 then
			fx:FireClient(plr, "Shake", 0.25)
			return false
		end
		local d = chase(m, h, 23, dt, gy + m:GetExtentsSize().Y / 2)
		if d < 4.5 then damage(plr, 40); fx:FireClient(plr, "Scare"); return true end
		return false
	end)
end

local TYPES = { "fallen", "preacher", "evak", "guest", "crawl", "witness", "bellman", "wallcrawl", "knocker" }
local WEIGHT = { fallen = 3, preacher = 2, evak = 1, guest = 2, crawl = 2, witness = 2, bellman = 2, wallcrawl = 3, knocker = 3 }

local function pickType(): string
	local tot = 0
	for _, t in TYPES do tot += WEIGHT[t] end
	local r = math.random() * tot
	for _, t in TYPES do r -= WEIGHT[t]; if r <= 0 then return t end end
	return "fallen"
end

local function spawnFor(plr: Player, kind: string?)
	local char = plr.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp or not inRun(plr) then return end
	local k = kind or pickType()
	local f = SPAWN[k]
	if f then local ok, e = pcall(f, plr, hrp); if not ok then warn("[EvaKExtra] монстр " .. k .. ": " .. tostring(e)) end end
end

-- ---------------- ивенты ----------------
local EVENTS = { "BloodMoon", "Blackout", "Invasion", "GiantEvaK", "Gravity", "FakeUpdate", "Earthquake", "Doppelgangers", "SilentMode", "Apocalypse" }
local RARE = { "OwnerAscent", "OwnerIsHere", "RealityError", "LastGuest", "FalseExit", "EvaKArrival", "Judgment", "LostSouls", "TheEnd", "EternalNight", "Possession", "TheEye" }
local COMMON = {}
for _, e in EVENTS do COMMON[e] = true end
COMMON.Apocalypse = nil
local COMBO: {[string]: {string}} = { TheEnd = { "GiantEvaK", "Invasion", "BloodMoon", "Earthquake" } }   -- ивенты, которые запускает составной ивент
local ALIAS = {
	ownerascent = "OwnerAscent", ownerishere = "OwnerIsHere", realityerror = "RealityError", lastguest = "LastGuest", falseexit = "FalseExit", evakarrival = "EvaKArrival",
	judgment = "Judgment", lostsouls = "LostSouls", theend = "TheEnd", eternalnight = "EternalNight", possession = "Possession", theeye = "TheEye", bloodmoon = "BloodMoon", blackout = "Blackout", invasion = "Invasion", giantevak = "GiantEvaK", gravity = "Gravity",
	fakeupdate = "FakeUpdate", earthquake = "Earthquake", doppelgangers = "Doppelgangers", silentmode = "SilentMode", apocalypse = "Apocalypse" }
local active: {[string]: number} = {}   -- имя -> unix-время конца; можно держать несколько ивентов сразу
local tokens: {[string]: number} = {}
local primary: string = ""
local baseGravity = workspace.Gravity
local eventToken = 0

local function evOn(name: string): boolean
	return active[name] ~= nil
end

-- публикуем список активных ивентов: "Имя=конец;Имя=конец" (клиентский HUD рисует их стопкой справа внизу)
local function publishEvents()
	local parts, best, bestEnd = {}, "", 0
	for n, e in active do
		table.insert(parts, n .. "=" .. e)
		if e >= bestEnd then best, bestEnd = n, e end
	end
	table.sort(parts)
	workspace:SetAttribute("EvaKEvents", table.concat(parts, ";"))
	if active[primary] == nil then primary = best end
	workspace:SetAttribute("EvaKEvent", primary)
	workspace:SetAttribute("EvaKEventEnd", active[primary] or 0)
end
local function giantEvaK()
	for _, plr in Players:GetPlayers() do
		local char = plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp and inRun(plr) then
			local gy = groundY(hrp :: BasePart)
			local m = figure("GiantEvaK", 4.2, Color3.fromRGB(5, 5, 7), { eye = Color3.fromRGB(255, 10, 10), armLen = 4.5 })
			local pos = (hrp :: BasePart).Position + (hrp :: BasePart).CFrame.LookVector * 90
			m:PivotTo(CFrame.new(pos.X, gy + m:GetExtentsSize().Y / 2, pos.Z))
			track(plr, m, CONFIG.EventLength, function(dt, h)
				local d = chase(m, h, 13, dt, gy + m:GetExtentsSize().Y / 2)
				if d < 9 then damage(plr, 60); fx:FireClient(plr, "Scare"); return true end
				return false
			end)
		end
	end
end

local function doppelgangers()
	for _, plr in Players:GetPlayers() do
		local char = plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp and inRun(plr) then
			for i = 1, 3 do
				local gy = groundY(hrp :: BasePart)
				local m = figure("Doppelganger", 1, Color3.fromRGB(14, 12, 14), { eye = Color3.fromRGB(255, 255, 255), armLen = 3 })
				local pos = (hrp :: BasePart).Position + (hrp :: BasePart).CFrame.LookVector * (30 + i * 14)
				m:PivotTo(CFrame.new(pos.X, gy + m:GetExtentsSize().Y / 2, pos.Z))
				track(plr, m, CONFIG.EventLength, function(dt, h)
					local d = chase(m, h, 11 + i, dt, gy + m:GetExtentsSize().Y / 2)
					if d < 4 then damage(plr, 20); fx:FireClient(plr, "Scare"); return true end
					return false
				end)
			end
		end
	end
end

local function ghostify(m: Model, tr: number)
	for _, p in m:GetDescendants() do if p:IsA("BasePart") then p.Transparency = tr end end
end

local function lostSouls()   -- призрачные игроки бродят по карте (безвредные)
	for _, plr in Players:GetPlayers() do
		local char = plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp and inRun(plr) then
			for i = 1, 4 do
				local gy = groundY(hrp :: BasePart)
				local m = figure("LostSoul", 1, Color3.fromRGB(150, 165, 175), { eye = Color3.fromRGB(255, 255, 255), armLen = 3 })
				ghostify(m, 0.6)
				local pos = (hrp :: BasePart).Position + (hrp :: BasePart).CFrame.LookVector * (24 + i * 16) + Vector3.new((i % 2 == 0 and 1 or -1) * 6, 0, 0)
				m:PivotTo(CFrame.new(pos.X, gy + m:GetExtentsSize().Y / 2, pos.Z))
				track(plr, m, CONFIG.EventLength, function(dt, h)
					local d = chase(m, h, 4 + i, dt, gy + m:GetExtentsSize().Y / 2)
					return d < 5
				end)
			end
		end
	end
end

local function lastGuest()   -- все игроки видят одного и того же незнакомца
	for _, plr in Players:GetPlayers() do
		local char = plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp and inRun(plr) then
			local gy = groundY(hrp :: BasePart)
			local m = figure("LastGuest", 1.1, Color3.fromRGB(70, 55, 45), { headColor = Color3.fromRGB(205, 195, 180), armLen = 3 })
			local pos = (hrp :: BasePart).Position + (hrp :: BasePart).CFrame.LookVector * 30
			m:PivotTo(CFrame.new(pos.X, gy + m:GetExtentsSize().Y / 2, pos.Z))
			fx:FireClient(plr, "Say", "The Last Guest is standing there. Don't get close.")
			track(plr, m, CONFIG.EventLength, function(dt, h)
				local p = m:GetPivot().Position
				m:PivotTo(CFrame.lookAt(p, Vector3.new(h.Position.X, p.Y, h.Position.Z)))
				if (flat(h.Position) - flat(p)).Magnitude < 8 then fx:FireClient(plr, "Scare"); return true end
				return false
			end)
		end
	end
end

local function stopEvent(name: string?)   -- без имени - остановить всё
	if name then
		active[name] = nil
		tokens[name] = (tokens[name] or 0) + 1
		if name == primary then primary = "" end
	else
		for n in active do tokens[n] = (tokens[n] or 0) + 1 end
		table.clear(active); primary = ""
	end
	workspace.Gravity = active.Gravity and 40 or baseGravity
	publishEvents()
end

-- Владелец возносится к небесам со световым столбом, потом падает: ударная волна, начинается ивент x2 БЕЙДЖИ
local function ascend(starter: Player?, my: number)
	local who = starter
	if not who or not who.Character then
		for _, p in Players:GetPlayers() do if isAdmin(p) and p.Character then who = p; break end end
	end
	local char = who and who.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local function startX2()
		local b = ServerStorage:FindFirstChild("EvaKAdminApi")
		if b then pcall(function() b:Invoke("Event", nil, "badge", { mult = 2, mins = CONFIG.EventLength / 60 }) end) end
		fx:FireAllClients("Say", "x2 BADGES for " .. CONFIG.EventLength .. " seconds!")
	end
	if not hrp then startX2() return end
	fx:FireAllClients("Say", ((who :: Player).DisplayName) .. " ascends to the heavens...")
	local hum = char:FindFirstChildOfClass("Humanoid")
	local p0 = hrp.CFrame
	hrp.Anchored = true
	if hum then hum.PlatformStand = true end
	local hl = Instance.new("Highlight"); hl.FillColor = Color3.fromRGB(255, 220, 120); hl.OutlineColor = Color3.fromRGB(255, 255, 255); hl.FillTransparency = 0.5; hl.Parent = char
	local lt = Instance.new("PointLight"); lt.Color = Color3.fromRGB(255, 225, 140); lt.Range = 40; lt.Brightness = 4; lt.Parent = hrp
	local pe = Instance.new("ParticleEmitter"); pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"; pe.Color = ColorSequence.new(Color3.fromRGB(255, 230, 150))
	pe.Size = NumberSequence.new(1.2, 0); pe.Lifetime = NumberRange.new(1, 2); pe.Rate = 80; pe.Speed = NumberRange.new(2, 8); pe.SpreadAngle = Vector2.new(180, 180); pe.LightEmission = 1; pe.Parent = hrp
	local beam = Instance.new("Part"); beam.Anchored = true; beam.CanCollide = false; beam.CanQuery = false; beam.CanTouch = false; beam.CastShadow = false
	beam.Material = Enum.Material.Neon; beam.Color = Color3.fromRGB(255, 235, 170); beam.Transparency = 0.55
	beam.Size = Vector3.new(7, 600, 7); beam.CFrame = p0 * CFrame.new(0, 300, 0); beam.Shape = Enum.PartType.Cylinder; beam.Orientation = Vector3.new(0, 0, 90)
	beam.CFrame = CFrame.new(p0.Position + Vector3.new(0, 300, 0)) * CFrame.Angles(0, 0, math.rad(90)); beam.Parent = workspace
	Debris:AddItem(beam, 30)
	local H, T = 140, 7
	local t0 = os.clock()
	while true do
		local k = (os.clock() - t0) / T
		if k >= 1 or not hrp.Parent then break end
		local e = k * k * (3 - 2 * k)
		hrp.CFrame = CFrame.new(p0.Position + Vector3.new(0, H * e, 0)) * CFrame.Angles(0, k * math.rad(720), 0) * CFrame.Angles(math.rad(-90 * e), 0, 0)
		beam.Transparency = 0.55 + 0.25 * math.sin(os.clock() * 8)
		task.wait()
	end
	fx:FireAllClients("Shake", 1.2)
	task.wait(1.2)
	if hrp.Parent then
		hrp.CFrame = CFrame.new(hrp.Position)
		hrp.Anchored = false
		hrp.AssemblyLinearVelocity = Vector3.new(0, -140, 0)
		pe.Rate = 200
	end
	local landed = os.clock()
	while hrp.Parent and os.clock() - landed < 3 and hrp.Position.Y > p0.Position.Y + 4 do task.wait() end
	local land = hrp.Parent and hrp.Position or p0.Position
	local ring = Instance.new("Part"); ring.Anchored = true; ring.CanCollide = false; ring.Material = Enum.Material.Neon; ring.Color = Color3.fromRGB(255, 220, 120)
	ring.Shape = Enum.PartType.Cylinder; ring.Size = Vector3.new(1, 4, 4); ring.CFrame = CFrame.new(land) * CFrame.Angles(0, 0, math.rad(90)); ring.Parent = workspace
	TweenService:Create(ring, TweenInfo.new(1.2), { Size = Vector3.new(1, 160, 160), Transparency = 1 }):Play()
	Debris:AddItem(ring, 2)
	fx:FireAllClients("Shake", 2.5)
	if hum then hum.PlatformStand = false end
	task.delay(2, function() hl:Destroy(); lt:Destroy(); pe:Destroy(); beam:Destroy() end)
	if tokens.OwnerAscent == my then startX2() end
end

local APOCALYPSE_SET = { "BloodMoon", "Blackout", "Invasion", "GiantEvaK", "Gravity", "FakeUpdate", "Earthquake", "Doppelgangers", "SilentMode" }
local startEvent
startEvent = function(name: string, starter: Player?, fromCombo: boolean?)
	tokens[name] = (tokens[name] or 0) + 1
	local my = tokens[name]
	active[name] = os.time() + CONFIG.EventLength
	if not fromCombo then primary = name end
	workspace.Gravity = active.Gravity and 40 or baseGravity
	publishEvents()
	if name == "Apocalypse" then   -- запускает ВСЕ обычные ивенты одновременно
		for _, e in APOCALYPSE_SET do task.spawn(startEvent, e, starter, true) end
	elseif COMBO[name] then
		for _, e in COMBO[name] do task.spawn(startEvent, e, starter, true) end
	end
	if name == "GiantEvaK" then task.spawn(giantEvaK) end
	if name == "Doppelgangers" then task.spawn(doppelgangers) end
	if name == "OwnerAscent" then task.spawn(ascend, starter, my) end
	if name == "LostSouls" then task.spawn(lostSouls) end
	if name == "LastGuest" then task.spawn(lastGuest) end
	task.delay(CONFIG.EventLength, function() if tokens[name] == my then stopEvent(name) end end)
end

-- ADMIN ABUSE: 30 секунд кинематика (клиент) -> все возвращаются в лобби -> стартуют сразу все ивенты (Apocalypse)
local abuseBusy = false
local oldGodGiven = false
local function adminAbuse(starter: Player?)
	if abuseBusy then return end
	abuseBusy = true
	workspace:SetAttribute("EvaKAbuse", os.time() + 30)
	task.delay(30, function()
		local rc = ServerStorage:FindFirstChild("EvaKRecall")
		if rc then rc:Fire() end
		task.wait(1.5)
		-- титул Old God: выдаётся ТОЛЬКО при самом первом Admin Abuse (флаг хранится в DataStore, дальше выдать нельзя)
		local given = oldGodGiven
		if not given then
			local okG, v = pcall(function() return store:GetAsync("global_oldgod") end)
			given = okG and v == true
		end
		if not given then
			oldGodGiven = true
			pcall(function() store:SetAsync("global_oldgod", true) end)
			for _, p in Players:GetPlayers() do
				local d = data[p]
				if d then
					d.Owned.oldgod = true; d.Equip.title = "oldgod"
					pushAttrs(p); applyCosmetics(p); save(p)
					fx:FireClient(p, "Say", "OLD GOD unlocked - the first Admin Abuse")
				end
			end
		end
		workspace:SetAttribute("EvaKAbuse", 0)
		startEvent("Apocalypse", starter)
		abuseBusy = false
	end)
end

EXTRA.AdminEvent = function(plr, name)
	if not isAdmin(plr) then return { ok = false, msg = "no access" } end
	if type(name) == "string" and name:lower() == "adminabuse" then adminAbuse(plr); return { ok = true } end
	if name == "off" then stopEvent(); return { ok = true } end
	if type(name) ~= "string" or not ALIAS[name:lower()] and not table.find(EVENTS, name) and not table.find(RARE, name) then return { ok = false, msg = "unknown event" } end
	startEvent(ALIAS[name:lower()] or name, plr)
	return { ok = true }
end
EXTRA.AdminEventList = function(plr)
	if not isAdmin(plr) then return { ok = false } end
	local l = {}
	for _, n in EVENTS do table.insert(l, n) end
	for _, n in RARE do table.insert(l, n) end
	return { ok = true, list = l }
end


-- ---------------- АДМИН-ИНСТРУМЕНТЫ (кнопки панели ADMIN) ----------------
local function runAdmin(cmd: string, plr: Player): boolean
	local b = ServerStorage:FindFirstChild("EvaKRunAdmin")
	if not b then return false end
	local ok, r = pcall(function() return b:Invoke(cmd, plr) end)
	return ok and r == true
end
local function setInvisible(char: Model, on: boolean)
	for _, d in char:GetDescendants() do
		if (d:IsA("BasePart") and d.Name ~= "HumanoidRootPart") or d:IsA("Decal") then d.Transparency = on and 1 or 0 end
	end
end
local MONSTER_KINDS = { "fallen", "preacher", "evak", "guest", "crawl", "witness", "bellman", "wallcrawl", "knocker" }
EXTRA.AdminTool = function(plr, tool, uid, val)
	if not isAdmin(plr) then return { ok = false, msg = "no access" } end
	if type(tool) ~= "string" then return { ok = false, msg = "bad tool" } end
	-- серверные инструменты без цели
	if tool == "clearmon" then
		local n = 0
		for _, o in workspace:GetChildren() do if o:IsA("Model") and o:GetAttribute("EvaKMonster") then o:Destroy(); n += 1 end end
		return { ok = true, msg = "monsters removed: " .. n }
	elseif tool == "stopevents" then
		stopEvent(); return { ok = true, msg = "all events stopped" }
	elseif tool == "gravity" then
		local g = math.clamp(tonumber(val) or 196.2, 5, 400)
		baseGravity = g; workspace.Gravity = active.Gravity and 40 or g
		return { ok = true, msg = "gravity " .. g }
	end
	local targets: {Player} = {}
	if uid == 0 or uid == -1 then targets = Players:GetPlayers()
	else
		local t = type(uid) == "number" and Players:GetPlayerByUserId(uid)
		if not t then return { ok = false, msg = "player is not on this server" } end
		targets = { t }
	end
	local n = 0
	for _, t in targets do
		local char = t.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local done = false
		if tool == "heal" then
			runAdmin("heal", t); if hum then hum.Health = hum.MaxHealth end; done = true
		elseif tool == "kill" then
			if not runAdmin("kill", t) and hum then hum.Health = 0 end; done = true
		elseif tool == "god" then
			local on = t:GetAttribute("EvaKGod") ~= true
			t:SetAttribute("EvaKGod", on)
			if char then
				local ff = char:FindFirstChild("EvaKGodFF")
				if on and not ff then local f = Instance.new("ForceField"); f.Name = "EvaKGodFF"; f.Visible = true; f.Parent = char
				elseif not on and ff then ff:Destroy() end
			end
			done = true
		elseif tool == "speed" and hum then
			local v = math.clamp(tonumber(val) or 16, 2, 120)
			t:SetAttribute("EvaKAdminSpeed", v); hum.WalkSpeed = v; done = true
		elseif tool == "jump" and hum then
			hum.UseJumpPower = true; hum.JumpPower = math.clamp(tonumber(val) or 50, 0, 300); done = true
		elseif tool == "freeze" and hrp then
			hrp.Anchored = true; done = true
		elseif tool == "unfreeze" and hrp then
			hrp.Anchored = false; done = true
		elseif tool == "invisible" and char then
			local on = t:GetAttribute("EvaKInvisible") ~= true
			t:SetAttribute("EvaKInvisible", on); setInvisible(char, on); done = true
		elseif tool == "lobby" then
			done = runAdmin("leave", t)
		elseif tool == "bring" and hrp then
			local me = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if me and t ~= plr then hrp.CFrame = me.CFrame * CFrame.new(0, 0, -4); done = true end
		elseif tool == "goto" and hrp then
			local me = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if me and t ~= plr then me.CFrame = hrp.CFrame * CFrame.new(0, 0, 4); done = true; break end
		elseif tool == "monster" then
			if type(val) == "string" and table.find(MONSTER_KINDS, val) then
				if inRun(t) then spawnFor(t, val); done = true end
			end
		elseif tool == "kick" and t ~= plr then
			t:Kick(type(val) == "string" and val ~= "" and val:sub(1, 80) or "Kicked by admin"); done = true
		end
		if done then n += 1 end
	end
	if n == 0 then
		local why = (tool == "monster") and "target must be inside a run" or "nothing happened (target in a run? wrong tool?)"
		return { ok = false, msg = why }
	end
	return { ok = true, msg = tool .. ": " .. n .. " player(s)" }
end


-- запасной путь для админ-панели, если скрипт EvaKAdmin не запущен: выдача и списки через EvaKAdminApi
local GRANT_OK = { Badges = true, Toy = true, Pack = true, Unlock = true, Snow = true, Skin = true, Revive = true }
EXTRA.AdminInfo = function(plr)
	if not isAdmin(plr) then return false end
	local b = ServerStorage:FindFirstChild("EvaKAdminApi") or ServerStorage:WaitForChild("EvaKAdminApi", 6)
	if not b then return { skins = {}, toys = {}, packs = {}, err = "EvaKServer.server.lua is NOT running (no EvaKAdminApi). Put it into ServerScriptService as a Script." } end
	local ok, res = pcall(function() return b:Invoke("Info") end)
	if ok and type(res) == "table" then
		if #res.toys == 0 and #res.packs == 0 then res.err = "EvaKServer answered but lists are empty (old EvaKServer.server.lua?). Replace it with the latest one." end
		return res
	end
	return { skins = {}, toys = {}, packs = {}, err = "EvaKServer is OUTDATED: it does not answer 'Info' (got " .. tostring(ok and res or "error: " .. tostring(res)) .. "). Replace EvaKServer.server.lua with the latest version." }
end
EXTRA.AdminGrant = function(plr, action, uid, b, c)
	if not isAdmin(plr) then return { ok = false, msg = "no access" } end
	if type(action) ~= "string" or not GRANT_OK[action] then return { ok = false, msg = "unknown" } end
	local api = ServerStorage:FindFirstChild("EvaKAdminApi")
	if not api then   -- запасной путь через хуки EvaKServer (только выдача: бейджи и игрушки)
		local tl = {}
		if uid == 0 or uid == -1 then tl = Players:GetPlayers() else local t = type(uid) == "number" and Players:GetPlayerByUserId(uid); if t then tl = { t } end end
		if #tl == 0 then return { ok = false, msg = "player is not on this server" } end
		local n = 0
		for _, t in tl do
			if action == "Badges" and b == "give" then
				local g = ServerStorage:FindFirstChild("EvaKGrantBadges")
				if g then g:Fire(t, math.clamp(math.floor(tonumber(c) or 0), 0, 10000000)); n += 1 end
			elseif action == "Toy" and type(b) == "string" then
				local g = ServerStorage:FindFirstChild("EvaKGrantToy")
				if g then g:Fire(t, b); n += 1 end
			end
		end
		if n == 0 then return { ok = false, msg = "EvaKAdminApi missing: only 'give badges' and toys work. Check EvaKServer.server.lua (Output, red lines)" } end
		return { ok = true, msg = action .. ": " .. n .. " player(s) (via fallback hook)" }
	end
	local p1, p2
	if action == "Badges" or action == "Snow" or action == "Revive" then
		if b ~= "give" and b ~= "take" and b ~= "set" then return { ok = false, msg = "bad mode" } end
		p1, p2 = b, math.clamp(math.floor(tonumber(c) or 0), 0, 10000000)
	elseif action == "Toy" or action == "Pack" or action == "Skin" then
		p1 = b
	end
	local targets = {}
	if uid == 0 or uid == -1 then targets = Players:GetPlayers()
	else
		local t = type(uid) == "number" and Players:GetPlayerByUserId(uid)
		if not t then return { ok = false, msg = "player is not on this server (EvaKAdmin script is needed for other servers)" } end
		targets = { t }
	end
	local n, lastMsg = 0, nil
	for _, t in targets do
		local ok, r1, r2 = pcall(function() return api:Invoke(action, t, p1, p2) end)
		if ok and r1 == true then n += 1
		elseif not ok then lastMsg = "error: " .. tostring(r1)
		elseif r1 == nil then lastMsg = "EvaKServer is OUTDATED (no answer to '" .. action .. "') - replace EvaKServer.server.lua with the latest"
		else lastMsg = tostring(r2 or "refused") end
	end
	if n == 0 then return { ok = false, msg = lastMsg or "nothing was granted" } end
	return { ok = true, msg = action .. ": " .. n .. " player(s)" }
end


EXTRA.AdminDoctor = function(plr)
	if not isAdmin(plr) then return false end
	local lines, bad = {}, false
	local function chk(name, ok, hint)
		table.insert(lines, (ok and "OK " or "MISSING ") .. name .. ((not ok and hint) and (" (" .. hint .. ")") or ""))
		if not ok then bad = true end
	end
	chk("EvaKServer/AdminApi", ServerStorage:FindFirstChild("EvaKAdminApi") ~= nil, "EvaKServer.server.lua crashed or not a Script")
	chk("GrantBadges", ServerStorage:FindFirstChild("EvaKGrantBadges") ~= nil)
	chk("GrantToy", ServerStorage:FindFirstChild("EvaKGrantToy") ~= nil)
	chk("EvaKAdmin.server", ReplicatedStorage:FindFirstChild("EvaKAdmin") ~= nil, "optional")
	chk("EvaKChat.server", ReplicatedStorage:FindFirstChild("EvaKChatSend") ~= nil)
	chk("EvaKSkins module", ReplicatedStorage:FindFirstChild("EvaKSkins") ~= nil)
	chk("EvaKMap.server", ServerStorage:FindFirstChild("EvaKInRun") ~= nil)
	return { lines = lines, bad = bad }
end

-- серверные ивенты панели (x2 бейджи / скорость / Новый год / Тако) без EvaKAdmin.server
local srvTokens = { newyear = 0, taco = 0 }
EXTRA.AdminSrvEvent = function(plr, kind, c)
	if not isAdmin(plr) then return { ok = false, msg = "no access" } end
	c = type(c) == "table" and c or {}
	local mins = math.clamp(tonumber(c.mins) or 5, 0.5, 120)
	local api = ServerStorage:FindFirstChild("EvaKAdminApi")
	local function attr(name, key)
		srvTokens[key] += 1
		local my = srvTokens[key]
		workspace:SetAttribute(name, true)
		workspace:SetAttribute(name .. "End", os.time() + mins * 60)
		task.delay(mins * 60, function() if srvTokens[key] == my then workspace:SetAttribute(name, false) end end)
	end
	if kind == "badge" or kind == "speed" then
		if not api then return { ok = false, msg = "EvaKServer is not running" } end
		local mult = math.clamp(tonumber(c.mult) or 2, 1, 10)
		if kind == "speed" then mult = math.min(mult, 2) end
		pcall(function() api:Invoke("Event", nil, kind, { mult = mult, mins = mins }) end)
	elseif kind == "newyear" then attr("EvaKNewYear", "newyear")
	elseif kind == "taco" then attr("EvaKTaco", "taco")
	elseif kind == "stop" then
		if api then pcall(function() api:Invoke("Event", nil, "stop") end) end
		srvTokens.newyear += 1; srvTokens.taco += 1
		workspace:SetAttribute("EvaKNewYear", false); workspace:SetAttribute("EvaKTaco", false)
		workspace:SetAttribute("EvaKNewYearEnd", 0); workspace:SetAttribute("EvaKTacoEnd", 0)
	else return { ok = false, msg = "bad event" } end
	return { ok = true, msg = kind .. " started on this server" }
end

-- цикл ивентов
task.spawn(function()
	workspace:SetAttribute("EvaKEvent", ""); workspace:SetAttribute("EvaKEvents", "")
	while true do
		local wait = math.random(CONFIG.EventEvery[1], CONFIG.EventEvery[2])
		workspace:SetAttribute("EvaKNextEvent", os.time() + wait)
		task.wait(wait)
		if #Players:GetPlayers() > 0 and next(active) == nil then
			if math.random() < 0.25 then startEvent(RARE[math.random(1, #RARE)]) else startEvent(EVENTS[math.random(1, #EVENTS)]) end
			task.wait(CONFIG.EventLength + 1)
		end
	end
end)

-- спавн монстров
task.spawn(function()
	local nextAt: {[Player]: number} = {}
	while true do
		task.wait(2)
		local now = os.clock()
		for _, plr in Players:GetPlayers() do
			if inRun(plr) then
				plr:SetAttribute("EvaKInRun", true)
				if not runStart[plr] then runStart[plr] = os.clock() end
				if not nextAt[plr] then nextAt[plr] = now + math.random(45, 85) end
				if now >= nextAt[plr] then
					spawnFor(plr)
					local div = evOn("Invasion") and 3 or 1
					nextAt[plr] = now + math.random(CONFIG.MonsterEvery[1], CONFIG.MonsterEvery[2]) / div
				end
			else
				plr:SetAttribute("EvaKInRun", false)
				runStart[plr] = nil
				nextAt[plr] = nil
			end
		end
	end
end)

-- ---------------- игроки / чат-команды ----------------
local function onChar(plr: Player)
	plr.CharacterAdded:Connect(function(ch)
		task.wait(1.2)
		applyCosmetics(plr)
	end)
end

local function findPlr(name: string): Player?
	name = name:lower()
	for _, p in Players:GetPlayers() do
		if p.Name:lower() == name or p.DisplayName:lower() == name then return p end
	end
	return nil
end

local function checkOwner(plr: Player)   -- золотой титул GOD и королевская рамка - только владельцу
	local t0 = os.clock()
	while data[plr] and not data[plr].Loaded and plr.Parent and os.clock() - t0 < 40 do task.wait(0.3) end
	local d = data[plr]
	if not d or not plr.Parent then return end
	if isOwner(plr) then
		plr:SetAttribute("EvaKOwner", true)
		if not d.Owned.god then d.Owned.god = true; d.Owned.frame_royal = true; d.Equip.title = "god"; d.Equip.frame = "frame_royal" end
	else
		plr:SetAttribute("EvaKOwner", false)
		if d.Owned.god or d.Owned.frame_royal then
			d.Owned.god = nil; d.Owned.frame_royal = nil
			if d.Equip.title == "god" then d.Equip.title = nil end
			if d.Equip.frame == "frame_royal" then d.Equip.frame = nil end
		end
	end
	pushAttrs(plr); applyCosmetics(plr); save(plr)
end
local function onPlayer(plr: Player)
	if not data[plr] then load(plr) end
	pushAttrs(plr)
	onChar(plr)
	task.spawn(checkVip, plr)
	task.spawn(checkOwner, plr)
	task.spawn(function()
		local d = data[plr]
		local t0 = os.clock()
		while d and not d.Loaded and plr.Parent and os.clock() - t0 < 40 do task.wait(0.3) end
		if d and plr.Parent then pushAttrs(plr); applyCosmetics(plr); greet(plr) end
	end)
	if plr.Character then task.delay(1, function() applyCosmetics(plr) end) end
	local function runCmd(msg: string)
		if not isAdmin(plr) then return end
		local args = string.split(msg, " ")
		local cmd = (args[1] or ""):lower()
		if cmd == "/event" then
			local a = (args[2] or ""):lower()
			if a == "off" then stopEvent()
			elseif ALIAS[a] then startEvent(ALIAS[a]) end
		elseif cmd == "/give" or cmd == "/take" then
			local t = args[2] and findPlr(args[2])
			local id = args[3] and args[3]:lower()
			if t and id and ITEMS[id] then
				if cmd == "/give" then grant(t, id)
				else
					local d = data[t]
					if d then
						d.Owned[id] = nil
						if d.Equip[ITEMS[id].slot] == id then d.Equip[ITEMS[id].slot] = nil end
						pushAttrs(t); applyCosmetics(t); save(t)
					end
				end
			end
		elseif cmd == "/monster" then
			spawnFor(plr, args[2] and args[2]:lower() or nil)
		end
	end
	plr.Chatted:Connect(runCmd)
	-- кастомный чат (EvaKChat) отключает стандартный, поэтому команды приходят ещё и через BindableEvent
	local cb = ServerStorage:FindFirstChild("EvaKChatCmd")
	if not cb then cb = Instance.new("BindableEvent"); cb.Name = "EvaKChatCmd"; cb.Parent = ServerStorage end
	cb.Event:Connect(function(p: Player, msg: string) if p == plr then runCmd(msg) end end)
end

-- ---------- Seen by God: игрок увидел владельца игры на своём сервере ----------
local function isOwner(plr: Player): boolean
	if game.CreatorType == Enum.CreatorType.User and game.CreatorId == plr.UserId then return true end
	if game.CreatorType == Enum.CreatorType.Group then
		local s, rank = pcall(function() return plr:GetRankInGroup(game.CreatorId) end)
		if s and rank == 255 then return true end
	end
	return false
end
local function checkSeen()
	local owner = false
	for _, p in Players:GetPlayers() do if isOwner(p) then owner = true break end end
	if not owner then return end
	for _, p in Players:GetPlayers() do
		local d = data[p]
		if d and not isOwner(p) and not d.Owned.seengod then
			grant(p, "seengod")
			d.Equip.title = d.Equip.title or "seengod"
			pushAttrs(p); applyCosmetics(p); save(p)
			local an = ReplicatedStorage:FindFirstChild("EvaKAchNotify")
			if an then an:FireClient(p, "Seen by God", "You saw the Owner on your server", 0) end
			fx:FireClient(p, "Say", "ACHIEVEMENT: Seen by God")
		end
	end
end
task.spawn(function()
	while true do
		task.wait(15)
		pcall(checkSeen)
		for _, p in Players:GetPlayers() do local d = data[p]; if d then d.Play += 15 end end
	end
end)

Players.PlayerAdded:Connect(onPlayer)
for _, p in Players:GetPlayers() do task.spawn(onPlayer, p) end
Players.PlayerRemoving:Connect(function(plr)
	save(plr)
	data[plr] = nil
end)
game:BindToClose(function() for _, p in Players:GetPlayers() do save(p) end end)

-- квесты проверяем раз в 20 секунд
task.spawn(function()
	while true do
		task.wait(20)
		for _, p in Players:GetPlayers() do checkQuests(p) end
	end
end)

print("[EvaKExtra] ready")
