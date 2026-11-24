-- ============================================================
--  EvaKTrade  (Script в ServerScriptService)
--  Настоящие трейды между игроками: питомцы, скины, косметика (ауры/крылья/глаза),
--  бейджи и снежинки. Сервер сам проверяет, что вещи есть у владельцев, и меняет их
--  атомарно (проверка + передача без пауз). История трейдов хранится в DataStore.
--  Геймпассы Roblox передать другому аккаунту НЕЛЬЗЯ (они привязаны к аккаунту) - их тут нет.
--  Нужны хуки: EvaKServer (EvaKTradeApi), EvaKExtra (EvaKTradeItems), EvaKMap (EvaKInRun).
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local DataStoreService = game:GetService("DataStoreService")

local MAX_HISTORY = 40
local MAX_ENTRIES = 30

local rf = Instance.new("RemoteFunction"); rf.Name = "EvaKTrade"; rf.Parent = ReplicatedStorage
local ev = Instance.new("RemoteEvent"); ev.Name = "EvaKTradeEvent"; ev.Parent = ReplicatedStorage

local histStore = DataStoreService:GetDataStore("EvaKTradeHistory_v1")
local history: {[number]: {any}} = {}

local function api(name: string)
	return ServerStorage:FindFirstChild(name) or ServerStorage:WaitForChild(name, 15)
end
local function call(name: string, ...)
	local b = api(name)
	if not b then return false, "service offline" end
	local ok, a, c = pcall(function(...) return b:Invoke(...) end, ...)
	if not ok then return false, tostring(a) end
	return a, c
end
local function inRun(plr: Player): boolean
	local b = ServerStorage:FindFirstChild("EvaKInRun")
	if not b then return false end
	local ok, r = pcall(function() return b:Invoke(plr) end)
	return ok and r == true
end

-- ---------- инвентарь ----------
local function inventory(plr: Player)
	local ok, inv = call("EvaKTradeApi", "Inv", plr)
	if not ok then return nil end
	local ok2, items = call("EvaKTradeItems", "Inv", plr)
	inv.items = ok2 and items or {}
	return inv
end

-- ---------- чистка оффера от клиента ----------
local function clean(o: any)
	local out = { badges = 0, snow = 0, toys = {}, skins = {}, items = {} }
	if type(o) ~= "table" then return out end
	local function n(v) v = tonumber(v) or 0; return math.clamp(math.floor(v), 0, 1e8) end
	out.badges = n(o.badges); out.snow = n(o.snow)
	local cnt = 0
	if type(o.toys) == "table" then
		for id, c in o.toys do
			if type(id) == "string" and #id < 40 and cnt < MAX_ENTRIES then
				local k = n(c); if k > 0 then out.toys[id] = k; cnt += 1 end
			end
		end
	end
	if type(o.skins) == "table" then
		for id in o.skins do if type(id) == "string" and #id < 40 and cnt < MAX_ENTRIES then out.skins[id] = true; cnt += 1 end end
	end
	if type(o.items) == "table" then
		for id in o.items do if type(id) == "string" and #id < 40 and cnt < MAX_ENTRIES then out.items[id] = true; cnt += 1 end end
	end
	return out
end

local function describe(o): string
	local t = {}
	if o.badges > 0 then table.insert(t, o.badges .. " badges") end
	if o.snow > 0 then table.insert(t, o.snow .. " snowflakes") end
	for id, c in o.toys do table.insert(t, (c > 1 and (c .. "x ") or "") .. id) end
	for id in o.skins do table.insert(t, "skin " .. id) end
	for id in o.items do table.insert(t, id) end
	if #t == 0 then return "nothing" end
	table.sort(t)
	return table.concat(t, ", ")
end
local function empty(o): boolean
	return o.badges == 0 and o.snow == 0 and next(o.toys) == nil and next(o.skins) == nil and next(o.items) == nil
end

local function check(plr: Player, o): (boolean, string?)
	local ok, msg = call("EvaKTradeApi", "Check", plr, o)
	if not ok then return false, msg end
	local ok2, msg2 = call("EvaKTradeItems", "Check", plr, o.items)
	if not ok2 then return false, msg2 end
	return true
end

-- ---------- история ----------
local function loadHistory(plr: Player)
	local ok, res = pcall(function() return histStore:GetAsync("u" .. plr.UserId) end)
	history[plr.UserId] = (ok and type(res) == "table") and res or {}
end
local function pushHistory(plr: Player, entry)
	local h = history[plr.UserId]
	if not h then loadHistory(plr); h = history[plr.UserId] end
	table.insert(h, 1, entry)
	while #h > MAX_HISTORY do table.remove(h) end
	task.spawn(function() pcall(function() histStore:SetAsync("u" .. plr.UserId, h) end) end)
end

-- ---------- сессии ----------
local sessions: {[Player]: any} = {}      -- активные (и у a, и у b указывают на один объект)
local invites: {[Player]: {[Player]: number}} = {}   -- invites[target][from] = time

local function view(s, plr: Player)
	local other = (s.a == plr) and s.b or s.a
	return {
		partner = other.DisplayName, partnerId = other.UserId,
		mine = s.offers[plr], theirs = s.offers[other],
		myReady = s.ready[plr] == true, theirReady = s.ready[other] == true,
	}
end
local function push(s)
	ev:FireClient(s.a, "State", view(s, s.a))
	ev:FireClient(s.b, "State", view(s, s.b))
end
local function close(s, why: string?)
	if s.closed then return end
	s.closed = true
	sessions[s.a] = nil; sessions[s.b] = nil
	ev:FireClient(s.a, "Closed", why or "")
	ev:FireClient(s.b, "Closed", why or "")
end

local function execute(s)
	local a, b = s.a, s.b
	if not a.Parent or not b.Parent then close(s, "player left") return end
	if inRun(a) or inRun(b) then
		s.ready = {}; push(s)
		ev:FireClient(a, "Msg", "Trades are not possible during a run"); ev:FireClient(b, "Msg", "Trades are not possible during a run")
		return
	end
	local oa, ob = s.offers[a], s.offers[b]
	local ok1, m1 = check(a, oa)
	local ok2, m2 = check(b, ob)
	if not ok1 or not ok2 then
		s.ready = {}; push(s)
		local m = (not ok1 and (a.DisplayName .. ": " .. tostring(m1))) or (b.DisplayName .. ": " .. tostring(m2))
		ev:FireClient(a, "Msg", m); ev:FireClient(b, "Msg", m)
		return
	end
	-- Check и Apply идут подряд, без пауз -> обмен атомарный
	local okA = call("EvaKTradeApi", "Apply", a, oa, b)
	local okB = call("EvaKTradeApi", "Apply", b, ob, a)
	call("EvaKTradeItems", "Apply", a, oa.items, b)
	call("EvaKTradeItems", "Apply", b, ob.items, a)
	if not okA or not okB then warn("[EvaKTrade] Apply вернул ошибку", okA, okB) end
	local now = os.time()
	pushHistory(a, { t = now, with = b.DisplayName, gave = describe(oa), got = describe(ob) })
	pushHistory(b, { t = now, with = a.DisplayName, gave = describe(ob), got = describe(oa) })
	ev:FireClient(a, "Done", describe(ob), describe(oa), b.DisplayName); ev:FireClient(b, "Done", describe(oa), describe(ob), a.DisplayName)
	close(s, "done")
end

local function findPlayer(uid: any): Player?
	if type(uid) ~= "number" then return nil end
	return Players:GetPlayerByUserId(uid)
end

local last: {[Player]: number} = {}
rf.OnServerInvoke = function(plr: Player, action: any, a: any, b: any)
	if os.clock() - (last[plr] or 0) < 0.12 then return { ok = false, msg = "too fast" } end
	last[plr] = os.clock()
	local s = sessions[plr]

	if action == "Info" then
		local plist = {}
		for _, p in Players:GetPlayers() do
			if p ~= plr then table.insert(plist, { id = p.UserId, name = p.DisplayName, busy = sessions[p] ~= nil, inRun = inRun(p) }) end
		end
		if not history[plr.UserId] then loadHistory(plr) end
		local inv = inventory(plr)
		local inc = {}
		for from, t in invites[plr] or {} do
			if os.clock() - t < 60 and from.Parent then table.insert(inc, { id = from.UserId, name = from.DisplayName }) end
		end
		return { ok = true, players = plist, history = history[plr.UserId], inv = inv, incoming = inc, session = s and view(s, plr) or nil }

	elseif action == "Invite" then
		local t = findPlayer(a)
		if not t or t == plr then return { ok = false, msg = "player not found" } end
		if s then return { ok = false, msg = "you are already trading" } end
		if sessions[t] then return { ok = false, msg = "player is busy" } end
		if inRun(plr) or inRun(t) then return { ok = false, msg = "not during a run" } end
		invites[t] = invites[t] or {}
		invites[t][plr] = os.clock()
		ev:FireClient(t, "Invite", plr.DisplayName, plr.UserId)
		return { ok = true }

	elseif action == "Accept" then
		local from = findPlayer(a)
		if not from or s or sessions[from] then return { ok = false, msg = "unavailable" } end
		local t = invites[plr] and invites[plr][from]
		if not t or os.clock() - t > 60 then return { ok = false, msg = "invite expired" } end
		invites[plr][from] = nil
		local ns = { a = from, b = plr, offers = { [from] = clean(nil), [plr] = clean(nil) }, ready = {} }
		sessions[from] = ns; sessions[plr] = ns
		push(ns)
		return { ok = true }

	elseif action == "Decline" then
		local from = findPlayer(a)
		if from and invites[plr] then invites[plr][from] = nil; ev:FireClient(from, "Msg", plr.DisplayName .. " declined the trade") end
		return { ok = true }

	elseif action == "Offer" then
		if not s then return { ok = false } end
		local o = clean(a)
		local ok, msg = check(plr, o)
		if not ok then return { ok = false, msg = msg } end
		s.offers[plr] = o
		s.ready = {}
		push(s)
		return { ok = true }

	elseif action == "Ready" then
		if not s then return { ok = false } end
		local oa, ob = s.offers[s.a], s.offers[s.b]
		if empty(oa) and empty(ob) then return { ok = false, msg = "offer something first" } end
		s.ready[plr] = a == true
		push(s)
		if s.ready[s.a] and s.ready[s.b] then execute(s) end
		return { ok = true }

	elseif action == "Cancel" then
		if s then close(s, plr.DisplayName .. " cancelled") end
		return { ok = true }
	end
	return { ok = false }
end

Players.PlayerRemoving:Connect(function(plr)
	local s = sessions[plr]
	if s then close(s, plr.DisplayName .. " left") end
	invites[plr] = nil
	for _, t in invites do t[plr] = nil end
	history[plr.UserId] = nil
	last[plr] = nil
end)

print("[EvaKTrade] ready")
