-- ============================================================
--  EvaK ADMIN  (Script)  -  ServerScriptService > Script
--  Админ-панель ТОЛЬКО для владельца. Все права проверяются на сервере.
--  Работает на ВСЕХ серверах игры: подарки, ивенты и объявления доходят до любого сервера
--  (MessagingService + DataStore). Для этого игра должна быть опубликована;
--  в Studio межсерверная часть отключена, всё работает только локально.
--  Кто админ: владелец игры (если игра на твоём аккаунте), владелец группы (ранг 255),
--  или UserId из списка ADMIN_IDS ниже. В Studio админ - тот, кто тестирует.
--  Нужен обновлённый EvaKServer.server.lua (в нём EvaKAdminApi).
-- ============================================================
local ADMIN_IDS: {number} = {
	-- 123456789,   -- <- сюда впиши свой UserId, если игра в группе или не на твоём аккаунте
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local MessagingService = game:GetService("MessagingService")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local TOPIC = "EvaKAdminCmd"
local giftStore = DataStoreService:GetDataStore("EvaKGifts_v1")
local stateStore = DataStoreService:GetDataStore("EvaKEventState_v1")

local rf = Instance.new("RemoteFunction")
rf.Name = "EvaKAdmin"
rf.Parent = ReplicatedStorage
local msgEvent = Instance.new("RemoteEvent")
msgEvent.Name = "EvaKAdminMsg"
msgEvent.Parent = ReplicatedStorage

local adminCache: {[number]: boolean} = {}
local function isAdmin(plr: Player): boolean
	if adminCache[plr.UserId] ~= nil then return adminCache[plr.UserId] end
	local ok = false
	if RunService:IsStudio() then ok = true end
	if table.find(ADMIN_IDS, plr.UserId) then ok = true end
	if game.CreatorType == Enum.CreatorType.User and game.CreatorId == plr.UserId then ok = true end
	if not ok and game.CreatorType == Enum.CreatorType.Group then
		local s, rank = pcall(function() return plr:GetRankInGroup(game.CreatorId) end)
		if s and rank == 255 then ok = true end
	end
	adminCache[plr.UserId] = ok
	return ok
end
Players.PlayerRemoving:Connect(function(p) adminCache[p.UserId] = nil end)

local function api(...)
	local b = ServerStorage:FindFirstChild("EvaKAdminApi") or ServerStorage:WaitForChild("EvaKAdminApi", 6)
	if not b then return false, "EvaKServer не найден (нужна новая версия)" end
	return b:Invoke(...)
end

-- UserId твоих других аккаунтов: объявление можно отправить от имени только этих аккаунтов (чужие нельзя)
local ALT_ACCOUNTS: {number} = { 970054307 }

local function filterText(text: string, admin: Player): string
	local ok, res = pcall(function()
		return TextService:FilterStringAsync(text, admin.UserId):GetNonChatStringForBroadcastAsync()
	end)
	return ok and res or ""
end

-- ---------- межсерверная связь ----------
local seen: {[string]: boolean} = {}
local function publish(cmd: any)
	if RunService:IsStudio() then return end
	task.spawn(function()
		local ok, err = pcall(function() MessagingService:PublishAsync(TOPIC, cmd) end)
		if not ok then warn("[EvaKAdmin] не удалось разослать по серверам:", err) end
	end)
end

-- ---------- выдача ----------
local GRANTS = { Badges = true, Toy = true, Pack = true, Unlock = true, Snow = true, Skin = true, Revive = true }
local function applyGrant(plr: Player, g: any)
	if type(g) ~= "table" or not GRANTS[g.a] then return false, "bad grant" end
	return api(g.a, plr, g.p1, g.p2)
end

local function waitLoaded(plr: Player): boolean
	local t = 0
	while plr.Parent and plr:GetAttribute("Badges") == nil and t < 40 do task.wait(0.5); t += 0.5 end
	return plr.Parent ~= nil and plr:GetAttribute("Badges") ~= nil
end

local function enqueueGift(userId: number, g: any): boolean
	local ok = pcall(function()
		giftStore:UpdateAsync(tostring(userId), function(old)
			old = old or {}
			if #old >= 50 then return nil end
			table.insert(old, g)
			return old
		end)
	end)
	return ok
end

local delivering: {[number]: boolean} = {}
local function deliverGifts(plr: Player)
	if delivering[plr.UserId] then return end
	delivering[plr.UserId] = true
	task.spawn(function()
		if waitLoaded(plr) then
			local gifts
			local ok = pcall(function()
				giftStore:UpdateAsync(tostring(plr.UserId), function(old)
					gifts = old
					if old and #old > 0 then return {} end
					return nil
				end)
			end)
			if ok and gifts then
				for _, g in gifts do applyGrant(plr, g) end
			end
		end
		delivering[plr.UserId] = nil
	end)
end
Players.PlayerAdded:Connect(deliverGifts)
for _, p in Players:GetPlayers() do deliverGifts(p) end

-- ---------- ивенты ----------
local nyToken = 0
local function setNewYear(on: boolean, mins: number?)
	nyToken += 1
	local my = nyToken
	workspace:SetAttribute("EvaKNewYear", on)
	if on and mins then
		task.delay(mins * 60, function()
			if my == nyToken then workspace:SetAttribute("EvaKNewYear", false) end
		end)
	end
end

local EVENT_TEXT = {
	badge = function(c) return string.format("ИВЕНТ: x%s бейджи на %s мин!", tostring(c.mult), tostring(c.mins)) end,
	speed = function(c) return string.format("ИВЕНТ: скорость x%s на %s мин!", tostring(c.mult), tostring(c.mins)) end,
	newyear = function(c) return string.format("НОВОГОДНИЙ ИВЕНТ на %s мин: снег, ёлки и огни!", tostring(c.mins)) end,
	taco = function(c) return string.format("ТАКО ИВЕНТ на %s мин: с неба падают тако!", tostring(c.mins)) end,
	stop = function() return "Ивент закончился" end,
}
local tacoToken = 0
local function setTaco(on: boolean, mins: number?)
	tacoToken += 1
	local my = tacoToken
	workspace:SetAttribute("EvaKTaco", on)
	if on and mins then
		task.delay(mins * 60, function()
			if my == tacoToken then workspace:SetAttribute("EvaKTaco", false) end
		end)
	end
end
local function runEvent(c: any)
	local kind = c.kind
	if kind == "stop" then
		api("Event", nil, "stop")
		setNewYear(false)
		setTaco(false)
	elseif kind == "taco" then
		setTaco(true, c.mins)
	elseif kind == "newyear" then
		setNewYear(true, c.mins)
	elseif kind == "badge" or kind == "speed" then
		api("Event", nil, kind, { mult = c.mult, mins = c.mins })
	else
		return
	end
	if EVENT_TEXT[kind] then msgEvent:FireAllClients(EVENT_TEXT[kind](c)) end
end

local function persistEvent(c: any)
	if RunService:IsStudio() then return end
	task.spawn(function()
		pcall(function()
			if c.kind == "stop" then
				for _, k in { "badge", "speed", "newyear", "taco" } do stateStore:RemoveAsync(k) end
			else
				stateStore:SetAsync(c.kind, { mult = c.mult, untilT = os.time() + c.mins * 60 })
			end
		end)
	end)
end

-- новый сервер подхватывает уже идущие ивенты
if not RunService:IsStudio() then
	task.spawn(function()
		task.wait(3)
		for _, k in { "badge", "speed", "newyear", "taco" } do
			local ok, st = pcall(function() return stateStore:GetAsync(k) end)
			if ok and type(st) == "table" and type(st.untilT) == "number" and st.untilT > os.time() then
				local mins = (st.untilT - os.time()) / 60
				if k == "newyear" then
					setNewYear(true, mins)
				elseif k == "taco" then
					setTaco(true, mins)
				else
					api("Event", nil, k, { mult = st.mult, mins = mins })
				end
			end
		end
	end)
end

-- ---------- приём команд от других серверов ----------
local function runCmd(c: any)
	if type(c) ~= "table" or type(c.id) ~= "string" or seen[c.id] then return end
	seen[c.id] = true
	if c.k == "all" then
		for _, p in Players:GetPlayers() do applyGrant(p, c.g) end
	elseif c.k == "gift" then
		local p = Players:GetPlayerByUserId(tonumber(c.uid) or 0)
		if p then deliverGifts(p) end
	elseif c.k == "event" then
		if type(c.kind) == "string" then
			c.mult = math.clamp(tonumber(c.mult) or 2, 1, 10)
			c.mins = math.clamp(tonumber(c.mins) or 5, 0.5, 120)
			runEvent(c)
		end
	elseif c.k == "announce" then
		if type(c.text) == "string" and #c.text <= 200 then
			msgEvent:FireAllClients({ text = c.text, uid = tonumber(c.uid), name = type(c.name) == "string" and c.name or nil, owner = c.owner == true })
		end
	end
end
if not RunService:IsStudio() then
	local ok, err = pcall(function()
		MessagingService:SubscribeAsync(TOPIC, function(msg) runCmd(msg.Data) end)
	end)
	if not ok then warn("[EvaKAdmin] MessagingService недоступен:", err) end
end

local function newId(): string
	return HttpService:GenerateGUID(false)
end

-- ---------- запросы панели ----------
local lastCall: {[Player]: number} = {}
rf.OnServerInvoke = function(plr: Player, action: any, a: any, b: any, c: any)
	if not isAdmin(plr) then return false end            -- не админ: ничего не получает
	if action == "Check" then   -- админу панель показываем ВСЕГДА (даже если EvaKServer ещё не готов - просто без списка скинов/игрушек)
		local okA, res, msg = pcall(api, "Info")
		if okA and type(res) == "table" then return res end
		return { skins = {}, toys = {}, packs = {}, err = tostring(okA and msg or res) }
	end
	if os.clock() - (lastCall[plr] or 0) < 0.15 then return { ok = false, msg = "слишком быстро" } end
	lastCall[plr] = os.clock()

	if action == "Find" then   -- поиск игрока по нику или UserId (в любом месте Roblox)
		if type(a) ~= "string" then return { ok = false, msg = "введи ник" } end
		local n = string.match(a, "^%s*(.-)%s*$") or ""
		if #n < 1 or #n > 40 then return { ok = false, msg = "ник 1-40 символов" } end
		local uid
		if string.match(n, "^%d+$") then
			uid = tonumber(n)
		else
			local ok = pcall(function() uid = Players:GetUserIdFromNameAsync(n) end)
			if not ok or not uid then return { ok = false, msg = "такого ника нет" } end
		end
		local name
		local okN = pcall(function() name = Players:GetNameFromUserIdAsync(uid) end)
		if not okN or not name then return { ok = false, msg = "игрок не найден" } end
		local here = Players:GetPlayerByUserId(uid) ~= nil
		return { ok = true, msg = name .. " (" .. uid .. ")" .. (here and " - на этом сервере" or " - не на этом сервере"), userId = uid, name = name }
	end

	if action == "Event" then
		if b ~= "badge" and b ~= "speed" and b ~= "stop" and b ~= "newyear" and b ~= "taco" then return { ok = false, msg = "bad event" } end
		local cmd = {
			id = newId(), k = "event", kind = b,
			mult = math.clamp(tonumber(c and c.mult) or 2, 1, 10),
			mins = math.clamp(tonumber(c and c.mins) or 5, 0.5, 120),
		}
		if b == "speed" then cmd.mult = math.min(cmd.mult, 2) end
		runCmd(cmd)
		persistEvent(cmd)
		publish(cmd)
		return { ok = true, msg = "ивент запущен на ВСЕХ серверах" }
	elseif action == "Announce" then
		if type(a) ~= "string" or #a == 0 or #a > 120 then return { ok = false, msg = "текст 1-120 символов" } end
		local text = filterText(a, plr)
		local uid, name = plr.UserId, plr.DisplayName
		if type(b) == "string" and #b > 0 then   -- отправить от имени своего другого аккаунта
			local okU, altId = pcall(function() return Players:GetUserIdFromNameAsync(b) end)
			if not okU or type(altId) ~= "number" then return { ok = false, msg = "аккаунт не найден: " .. b } end
			if not table.find(ALT_ACCOUNTS, altId) then
				return { ok = false, msg = "добавь UserId " .. altId .. " в ALT_ACCOUNTS (EvaKAdmin.server): только свои аккаунты" }
			end
			uid, name = altId, b
		end
		local cmd = { id = newId(), k = "announce", text = text, uid = uid, name = name, owner = (uid == plr.UserId) }
		runCmd(cmd)
		publish(cmd)
		return { ok = true, msg = "отправлено на все серверы" }
	end

	if not GRANTS[action] then return { ok = false, msg = "unknown" } end
	-- что выдаём
	local g
	if action == "Badges" or action == "Snow" or action == "Revive" then
		if b ~= "give" and b ~= "take" and b ~= "set" then return { ok = false, msg = "bad mode" } end
		g = { a = action, p1 = b, p2 = math.clamp(math.floor(tonumber(c) or 0), 0, 10000000) }
	elseif action == "Toy" or action == "Pack" or action == "Skin" then
		if type(b) ~= "string" and type(b) ~= "number" then return { ok = false, msg = "bad id" } end
		g = { a = action, p1 = b }
	else
		g = { a = "Unlock" }
	end
	if type(a) ~= "number" then return { ok = false, msg = "bad target" } end

	if a == 0 or a == -1 then   -- 0 = все на этом сервере, -1 = все на всех серверах
		local cmd = { id = newId(), k = "all", g = g }
		runCmd(cmd)
		if a == -1 then publish(cmd) end
		return { ok = true, msg = (a == -1) and "выдано всем на ВСЕХ серверах" or "выдано всем на этом сервере" }
	end
	local target = Players:GetPlayerByUserId(a)
	if target then
		local ok, msg = applyGrant(target, g)
		return { ok = ok == true, msg = msg }
	end
	-- игрока нет на этом сервере: кладём подарок в очередь и будим другие серверы
	if not enqueueGift(a, g) then return { ok = false, msg = "не удалось сохранить подарок" } end
	publish({ id = newId(), k = "gift", uid = a })
	return { ok = true, msg = "подарок сохранён: игрок получит его на своём сервере или при входе" }
end

print("[EvaKAdmin] готово. Админы: владелец игры + ADMIN_IDS" .. (RunService:IsStudio() and " (Studio: ты админ; межсерверная часть выключена)" or ""))
