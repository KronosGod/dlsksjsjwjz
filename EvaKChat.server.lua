-- ============================================================
--  EvaKChat (Script в ServerScriptService)
--  Общий чат: перед сообщением круглая аватарка игрока, [VIP] и ник.
--  ВЛАДЕЛЕЦ может писать от имени СВОЕГО другого аккаунта: /as <ник альта>  и  /as off
--  Работает только для аккаунтов из списка ALT_ACCOUNTS (впиши UserId своих альтов),
--  чужой аккаунт так подставить нельзя. Все сообщения проходят через фильтр Roblox.
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")

local ALT_ACCOUNTS: {number} = { 970054307 }   -- UserId твоих альт-аккаунтов, например { 123456789 }

local send = Instance.new("RemoteEvent"); send.Name = "EvaKChatSend"; send.Parent = ReplicatedStorage
local recv = Instance.new("RemoteEvent"); recv.Name = "EvaKChatRecv"; recv.Parent = ReplicatedStorage

local function isOwner(plr: Player): boolean
	if RunService:IsStudio() then return true end
	if game.CreatorType == Enum.CreatorType.User and game.CreatorId == plr.UserId then return true end
	if game.CreatorType == Enum.CreatorType.Group then
		local ok, rank = pcall(function() return plr:GetRankInGroup(game.CreatorId) end)
		if ok and rank == 255 then return true end
	end
	return false
end

local ADJ = { "Dark", "Silent", "Rusty", "Cursed", "Lost", "Pale", "Wicked", "Frozen", "Hollow", "Burning", "Twisted", "Blind", "Crimson", "Ghostly", "Mad" }
local NOUN = { "Wolf", "Raven", "Moth", "Spirit", "Hunter", "Wraith", "Crow", "Shade", "Ghoul", "Fox", "Knight", "Demon", "Mouse", "Skull", "Eye" }
local nick: {[Player]: string} = {}
local function nickOf(plr: Player): string
	if not nick[plr] then nick[plr] = plr.DisplayName ~= "" and plr.DisplayName or plr.Name end
	return nick[plr]
end
local alias: {[Player]: { uid: number, name: string }} = {}
local last: {[Player]: number} = {}

local function sys(plr: Player, text: string)
	recv:FireClient(plr, { sys = true, text = text })
end

send.OnServerEvent:Connect(function(plr: Player, text: any, mid: any)
	if type(text) ~= "string" then return end
	if type(mid) ~= "number" then mid = 0 end
	text = text:gsub("^%s+", ""):gsub("%s+$", "")
	if #text == 0 or #text > 200 then return end
	if os.clock() - (last[plr] or 0) < 0.3 then return end
	last[plr] = os.clock()

	-- админ-команды игры (/event, /give, /take, /monster) обрабатывает EvaKExtra
	if text:match("^/event%f[%s%z]") or text:match("^/give%f[%s%z]") or text:match("^/take%f[%s%z]") or text:match("^/monster%f[%s%z]") then
		local ServerStorage = game:GetService("ServerStorage")
		local b = ServerStorage:FindFirstChild("EvaKChatCmd")
		if b then b:Fire(plr, text) end
		return
	end
	-- /nick <имя> - свой ник в чате; /nick - вернуть свой ник Roblox
	local nn = text:match("^/nick%f[%s%z]%s*(.-)%s*$")
	if nn ~= nil then
		if nn == "" then nick[plr] = nil
		else
			nn = nn:sub(1, 16)
			local okn, fr = pcall(function() return TextService:FilterStringAsync(nn, plr.UserId, Enum.TextFilterContext.PublicChat) end)
			local clean = okn and select(2, pcall(function() return fr:GetNonChatStringForBroadcastAsync() end)) or nil
			if type(clean) ~= "string" or clean ~= nn then sys(plr, "This nickname is not allowed") return end
			nick[plr] = nn
		end
		sys(plr, "Your chat nickname: " .. nickOf(plr))
		return
	end
	-- команда владельца: писать от имени своего альта
	local cmd = text:match("^/as%f[%s%z]%s*(%S*)")
	if cmd ~= nil then
		if not isOwner(plr) then return end
		if cmd == "" or cmd:lower() == "off" then
			alias[plr] = nil
			sys(plr, "Chat identity: your own account")
			return
		end
		local ok, uid = pcall(function() return Players:GetUserIdFromNameAsync(cmd) end)
		if not ok or type(uid) ~= "number" then sys(plr, "Account not found: " .. cmd) return end
		if not table.find(ALT_ACCOUNTS, uid) then
			sys(plr, "Add UserId " .. uid .. " to ALT_ACCOUNTS in EvaKChat.server first (only your own accounts are allowed)")
			return
		end
		alias[plr] = { uid = uid, name = cmd }
		sys(plr, "Now chatting as " .. cmd .. "  (/as off to go back)")
		return
	end

	local ok, result = pcall(function() return TextService:FilterStringAsync(text, plr.UserId, Enum.TextFilterContext.PublicChat) end)
	local a = alias[plr]
	local base = {
		uid = a and a.uid or plr.UserId,
		name = a and a.name or nickOf(plr),
		vip = (not a) and plr:GetAttribute("XVip") == true,
		crown = (not a) and plr:GetAttribute("Donor") == true,
		title = (not a) and (plr:GetAttribute("XTitleText") or "") or "",
		tcol = (not a) and (plr:GetAttribute("XTitleColor") or "d73c32") or "d73c32",
		god = (not a) and plr:GetAttribute("EvaKOwner") == true,
	}
	for _, rcp in Players:GetPlayers() do
		local filtered = nil
		if ok then
			local okc, f = pcall(function() return result:GetChatForUserAsync(rcp.UserId) end)
			if okc then filtered = f end
		end
		-- в Studio (игра не опубликована) фильтр может не работать - показываем текст как есть
		if filtered == nil and RunService:IsStudio() then filtered = text end
		if filtered == nil then
			if rcp == plr then sys(plr, "Message was blocked by the Roblox filter") end
		else
			recv:FireClient(rcp, { uid = base.uid, name = base.name, vip = base.vip, crown = base.crown, title = base.title, tcol = base.tcol, god = base.god, text = filtered, mid = (rcp == plr) and mid or 0 })
		end
	end
end)

Players.PlayerRemoving:Connect(function(p) alias[p] = nil; last[p] = nil; nick[p] = nil end)
ReplicatedStorage:SetAttribute("EvaKChatReady", true)
print("[EvaKChat] ready")
