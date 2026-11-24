-- ============================================================
--  EvaK ADMIN PANEL  (LocalScript)  -  StarterPlayer > StarterPlayerScripts
--  Панель появится только у админа (сервер проверяет права). Открыть/закрыть: F2 или кнопка ADMIN.
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function mk(class: string, props: {[string]: any}, parent: Instance?): any
	local o = Instance.new(class)
	for k, v in props do o[k] = v end
	if parent then o.Parent = parent end
	return o
end

-- ---------- проба: видно сразу, что клиентский скрипт админки ЗАПУЩЕН ----------
local probeGui = mk("ScreenGui", { Name = "EvaKAdminProbe", ResetOnSpawn = false, DisplayOrder = 901 }, playerGui)
mk("TextLabel", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 10, 1, -48), Size = UDim2.fromOffset(300, 22), BackgroundColor3 = Color3.fromRGB(22, 16, 12), BackgroundTransparency = 0.2,
	TextColor3 = Color3.fromRGB(236, 190, 72), Font = Enum.Font.Arcade, TextSize = 12, Text = "ADMIN: checking server..." }, probeGui)
task.delay(40, function() if probeGui.Parent then probeGui:Destroy() end end)

-- ---------- объявления (видят все) ----------
local msgEvent = ReplicatedStorage:WaitForChild("EvaKAdminMsg", 8)
local bannerGui = mk("ScreenGui", { Name = "EvaKBanner", ResetOnSpawn = false, DisplayOrder = 950, IgnoreGuiInset = true }, playerGui)
if msgEvent then
	msgEvent.OnClientEvent:Connect(function(payload)
		local text, uid, nick = payload, nil, nil
		if type(payload) == "table" then text, uid, nick = payload.text, payload.uid, payload.name end
		if type(text) ~= "string" or text == "" then return end
		local hasAuthor = type(uid) == "number" and type(nick) == "string"
		local l = mk("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, -80), Size = UDim2.fromOffset(660, hasAuthor and 62 or 46),
			BackgroundColor3 = Color3.fromRGB(24, 16, 10), BackgroundTransparency = 0.1, TextColor3 = Color3.fromRGB(255, 214, 140),
			Font = Enum.Font.Arcade, TextSize = 22, Text = hasAuthor and "" or text, TextWrapped = true,
		}, bannerGui)
		if hasAuthor then   -- круглая аватарка автора + ник + текст объявления
			local av = mk("ImageLabel", { Position = UDim2.fromOffset(10, 9), Size = UDim2.fromOffset(44, 44), BackgroundColor3 = Color3.fromRGB(50, 36, 26), Image = "" }, l)
			mk("UICorner", { CornerRadius = UDim.new(1, 0) }, av)
			mk("UIStroke", { Color = Color3.fromRGB(180, 130, 60), Thickness = 2 }, av)
			task.spawn(function()
				local okT, url = pcall(function() return Players:GetUserThumbnailAsync(uid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100) end)
				if okT and av.Parent then av.Image = url end
			end)
			local nl = mk("TextLabel", { Position = UDim2.fromOffset(64, 6), Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
				Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Color3.fromRGB(236, 190, 72), Text = nick }, l)
			if type(payload) == "table" and payload.owner then   -- значок владельца: золотая круглая галочка (свой дизайн)
				local bd = mk("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(1, 5, 0.5, 0), Size = UDim2.fromOffset(18, 18), BackgroundColor3 = Color3.fromRGB(236, 176, 40), BorderSizePixel = 0 }, nl)
				mk("UICorner", { CornerRadius = UDim.new(1, 0) }, bd)
				mk("UIStroke", { Color = Color3.fromRGB(255, 236, 160), Thickness = 1 }, bd)
				mk("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 13, TextColor3 = Color3.new(1, 1, 1), Text = "✓" }, bd)
			end
			mk("TextLabel", { Position = UDim2.fromOffset(64, 26), Size = UDim2.new(1, -76, 0, 30), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top, Font = Enum.Font.GothamMedium, TextSize = 17, TextWrapped = true, TextColor3 = Color3.fromRGB(255, 232, 190), Text = text }, l)
		end
		mk("UICorner", { CornerRadius = UDim.new(0, 8) }, l)
		mk("UIStroke", { Color = Color3.fromRGB(180, 130, 60), Thickness = 2 }, l)
		TweenService:Create(l, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Position = UDim2.new(0.5, 0, 0, 24) }):Play()
		task.delay(7, function()
			local t = TweenService:Create(l, TweenInfo.new(0.4), { Position = UDim2.new(0.5, 0, 0, -80) })
			t:Play(); t.Completed:Wait(); l:Destroy()
		end)
	end)
end

-- ---------- панель (только админ) ----------
local rf = ReplicatedStorage:WaitForChild("EvaKAdmin", 8)
local limited = false   -- EvaKAdmin.server не запущен: работаем через EvaKExtra (теряем только поиск игроков на других серверах, объявления и межсерверные ивенты)
if not rf then
	rf = ReplicatedStorage:WaitForChild("EvaKExtra", 10)
	if rf then
		limited = true
	else
		local g1 = mk("ScreenGui", { Name = "EvaKAdminWhy", ResetOnSpawn = false, DisplayOrder = 900 }, playerGui)
		mk("TextLabel", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 10, 1, -10), Size = UDim2.fromOffset(560, 40), BackgroundColor3 = Color3.fromRGB(60, 14, 10), BackgroundTransparency = 0.1,
			TextColor3 = Color3.fromRGB(255, 200, 120), Font = Enum.Font.Arcade, TextSize = 12, TextWrapped = true,
			Text = "ADMIN PANEL OFF: no server scripts found. Put EvaKAdmin.server.lua and EvaKExtra.server.lua into ServerScriptService as Script (not LocalScript) and read Output for red errors." }, g1)
		return
	end
end
local okC, info = false, nil
local answered = false
task.spawn(function()
	for _ = 1, 4 do   -- сервер мог ещё не подготовить данные: пробуем несколько раз
		okC, info = pcall(function() return rf:InvokeServer(limited and "AdminInfo" or "Check") end)
		if okC and type(info) == "table" then break end
		if okC and info == false then break end   -- сервер ответил «ты не админ»
		task.wait(2)
	end
	answered = true
end)
local t0 = os.clock()
while not answered and os.clock() - t0 < 12 do task.wait(0.2) end
local function whyPlaque(msg: string, red: boolean)
	local g0 = mk("ScreenGui", { Name = "EvaKAdminWhy", ResetOnSpawn = false, DisplayOrder = 900 }, playerGui)
	mk("TextLabel", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 10, 1, -48), Size = UDim2.fromOffset(560, 40), BackgroundColor3 = red and Color3.fromRGB(60, 14, 10) or Color3.fromRGB(22, 16, 12), BackgroundTransparency = 0.1,
		TextColor3 = Color3.fromRGB(255, 200, 120), Font = Enum.Font.Arcade, TextSize = 12, TextWrapped = true, Text = msg }, g0)
	task.delay(40, function() g0:Destroy() end)
end
if not answered then   -- сервер не отвечает на Check: панель всё равно показываем, чтобы было видно кнопку и причину
	whyPlaque("ADMIN: server did not answer. EvaKAdmin.server.lua is old or crashed - replace it and read Output (red lines with EvaKAdmin).", true)
	okC, info = true, { skins = {}, toys = {}, packs = {} }
elseif not okC or type(info) ~= "table" then   -- не админ (или ошибка): панели нет, но объясняем почему
	probeGui:Destroy()
	whyPlaque("ADMIN PANEL OFF: " .. ((not okC) and ("server error: " .. tostring(info)) or ("you are not an admin. Put your UserId " .. player.UserId .. " into ADMIN_IDS in EvaKAdmin.server.lua")), true)
	return
end
info = info or {}
if limited then whyPlaque("ADMIN (limited): EvaKAdmin.server is not running - using EvaKExtra. Grants, tools, monsters and game events work; search, announcements and cross-server events need EvaKAdmin.server in ServerScriptService.", false) end

local GOLD, BG, BTN = Color3.fromRGB(236, 190, 72), Color3.fromRGB(22, 16, 12), Color3.fromRGB(52, 38, 26)

local gui = mk("ScreenGui", { Name = "EvaKAdminPanel", ResetOnSpawn = false, DisplayOrder = 900, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, playerGui)

local openBtn = mk("TextButton", {
	AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 10, 1, -10), Size = UDim2.fromOffset(90, 30),
	BackgroundColor3 = BG, TextColor3 = GOLD, Font = Enum.Font.Arcade, TextSize = 16, Text = "ADMIN [F2]", AutoButtonColor = true,
}, gui)
mk("UICorner", { CornerRadius = UDim.new(0, 6) }, openBtn)
mk("UIStroke", { Color = GOLD, Thickness = 1.5 }, openBtn)

local panel = mk("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(700, 560),
	BackgroundColor3 = BG, BorderSizePixel = 0, Visible = false,
}, gui)
mk("UICorner", { CornerRadius = UDim.new(0, 10) }, panel)
mk("UIStroke", { Color = GOLD, Thickness = 2 }, panel)
local modal = mk("TextButton", { Size = UDim2.fromScale(0, 0), BackgroundTransparency = 1, Text = "", Modal = true, Visible = true }, panel)  -- освобождает мышь

mk("TextLabel", {
	Size = UDim2.new(1, -50, 0, 36), Position = UDim2.fromOffset(14, 4), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
	Font = Enum.Font.Arcade, TextSize = 22, TextColor3 = GOLD, Text = "ADMIN PANEL",
}, panel)
local closeBtn = mk("TextButton", {
	Position = UDim2.new(1, -40, 0, 6), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = Color3.fromRGB(120, 30, 30),
	Text = "X", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.Arcade, TextSize = 18,
}, panel)
mk("UICorner", { CornerRadius = UDim.new(0, 6) }, closeBtn)

local status = mk("TextLabel", {
	AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 14, 1, -6), Size = UDim2.new(1, -28, 0, 22), BackgroundTransparency = 1,
	TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Code, TextSize = 14, TextColor3 = Color3.fromRGB(190, 200, 190), Text = "готов",
}, panel)

-- запасные списки: если EvaKServer не отдал данные, кнопки всё равно рисуются (выдача пойдёт через хуки EvaKGrantToy/EvaKGrantBadges)
info.toys = (info.toys and #info.toys > 0) and info.toys or { "DUCK", "TOP", "ROBOT", "BEAR", "JACK", "MUSIC", "DRAGON", "ROCKET", "SANTA", "NEWYEAR", "SANTADRAGON", "CARBONCAR" }
if not info.skins or #info.skins == 0 then
	info.skins = {}
	local okM, mod = pcall(function() return require(ReplicatedStorage:WaitForChild("EvaKSkins", 3)) end)
	if okM and type(mod) == "table" and mod.List then for _, sk in mod.List do table.insert(info.skins, sk.Id) end end
end
if info.err then status.Text = "ОШИБКА списка: " .. tostring(info.err); whyPlaque("ADMIN: " .. tostring(info.err), true) end
local scroll = mk("ScrollingFrame", {
	Position = UDim2.fromOffset(10, 44), Size = UDim2.new(1, -20, 1, -74), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 6, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, panel)
mk("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)

local order = 0
local function section(title: string): Frame
	order += 1
	local f = mk("Frame", { Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Color3.fromRGB(34, 25, 18), BorderSizePixel = 0, LayoutOrder = order }, scroll)
	mk("UICorner", { CornerRadius = UDim.new(0, 8) }, f)
	mk("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, f)
	mk("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, f)
	mk("TextLabel", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Arcade, TextSize = 15, TextColor3 = GOLD, Text = title, LayoutOrder = 0 }, f)
	return f
end
local function row(parent: Instance, lo: number): Frame
	local r = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = lo }, parent)
	mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Wraps = true, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, r)
	return r
end
local function button(parent: Instance, text: string, w: number, cb: () -> ()): TextButton
	local b = mk("TextButton", { Size = UDim2.fromOffset(w, 28), BackgroundColor3 = BTN, TextColor3 = Color3.fromRGB(246, 226, 182), Font = Enum.Font.Arcade, TextSize = 14, Text = text, AutoButtonColor = true }, parent)
	mk("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
	b.Activated:Connect(cb)
	return b
end
local function box(parent: Instance, placeholder: string, text: string, w: number): TextBox
	local t = mk("TextBox", { Size = UDim2.fromOffset(w, 28), BackgroundColor3 = Color3.fromRGB(14, 10, 8), TextColor3 = Color3.new(1, 1, 1), PlaceholderText = placeholder, PlaceholderColor3 = Color3.fromRGB(120, 110, 100), Text = text, Font = Enum.Font.Code, TextSize = 14, ClearTextOnFocus = false }, parent)
	mk("UICorner", { CornerRadius = UDim.new(0, 6) }, t)
	return t
end

-- запрос на сервер
local target = 0   -- 0 = все
local function call(...)
	local args = { ... }
	if limited then
		local act = args[1]
		if act == "Badges" or act == "Snow" or act == "Revive" or act == "Toy" or act == "Pack" or act == "Skin" or act == "Unlock" then
			args = { "AdminGrant", act, args[2], args[3], args[4] }
		elseif act == "Event" then
			args = { "AdminSrvEvent", args[3], args[4] }
		else
			status.Text = "ERROR: server script EvaKAdmin is not running - search and announcements need it"; status.TextColor3 = Color3.fromRGB(240, 110, 110)
			return
		end
	end
	local watchAttr = (args[1] == "Badges" or args[1] == "Snow" or (args[1] == "AdminGrant" and (args[2] == "Badges" or args[2] == "Snow"))) and (args[1] == "AdminGrant" and args[2] or args[1]) or nil
	local watchPlr = watchAttr and game:GetService("Players"):GetPlayerByUserId(target) or nil
	local before = watchPlr and watchPlr:GetAttribute(watchAttr)
	local ok, res = pcall(function() return rf:InvokeServer(table.unpack(args)) end)
	if not ok or type(res) ~= "table" then status.Text = "ошибка запроса"; status.TextColor3 = Color3.fromRGB(240, 110, 110); return end
	status.Text = res.ok and ("OK  " .. tostring(res.msg or "")) or ("ОШИБКА: " .. tostring(res.msg))
	status.TextColor3 = res.ok and Color3.fromRGB(150, 230, 150) or Color3.fromRGB(240, 110, 110)
	if res.ok and watchPlr then   -- честная проверка: число у игрока реально изменилось?
		task.delay(0.6, function()
			local after = watchPlr:GetAttribute(watchAttr)
			status.Text = status.Text .. string.format("   [%s: %s -> %s]", watchAttr, tostring(before), tostring(after))
			if before == after and args[3] ~= "set" and args[4] ~= 0 then
				status.Text = status.Text .. "  - ЧИСЛО НЕ ИЗМЕНИЛОСЬ: старый EvaKServer.server.lua? нажми ПРОВЕРИТЬ СКРИПТЫ"
				status.TextColor3 = Color3.fromRGB(240, 170, 90)
			end
		end)
	end
	return res
end

-- 1. Цель
local sTarget = section("ЦЕЛЬ (кому выдать) - работает на любом сервере")
local searchRow = row(sTarget, 1)
local searchBox = box(searchRow, "ник или UserId", "", 190)
local targetRow = row(sTarget, 2)
local targetBtns: {[number]: TextButton} = {}
local extra: { id: number, name: string }? = nil   -- найденный игрок (может быть на другом сервере)
local function paintTargets()
	for id, b in targetBtns do b.BackgroundColor3 = (id == target) and Color3.fromRGB(150, 100, 30) or BTN end
end
local function applyFilter()
	local q = string.lower(searchBox.Text)
	for id, b in targetBtns do
		if id > 0 and not (extra and id == extra.id) then
			b.Visible = (q == "") or (string.find(string.lower(b.Text), q, 1, true) ~= nil)
		else
			b.Visible = true
		end
	end
end
local function rebuildTargets()
	for _, b in targetBtns do b:Destroy() end
	table.clear(targetBtns)
	targetBtns[0] = button(targetRow, "ВСЕ (этот сервер)", 140, function() target = 0; paintTargets() end)
	targetBtns[-1] = button(targetRow, "ВСЕ СЕРВЕРА", 110, function() target = -1; paintTargets() end)
	if extra then
		targetBtns[extra.id] = button(targetRow, "* " .. extra.name, 150, function() target = extra.id; paintTargets() end)
	end
	for _, p in Players:GetPlayers() do
		if not (extra and p.UserId == extra.id) then
			targetBtns[p.UserId] = button(targetRow, p.Name, 130, function() target = p.UserId; paintTargets() end)
		end
	end
	if not targetBtns[target] then target = player.UserId end
	paintTargets()
	applyFilter()
end
button(searchRow, "НАЙТИ", 70, function()
	local res = call("Find", searchBox.Text)
	if res and res.ok and res.userId then
		extra = { id = res.userId, name = res.name or tostring(res.userId) }
		target = res.userId
		rebuildTargets()
	end
end)
searchBox:GetPropertyChangedSignal("Text"):Connect(applyFilter)
Players.PlayerAdded:Connect(rebuildTargets)
Players.PlayerRemoving:Connect(function() task.defer(rebuildTargets) end)
target = player.UserId
rebuildTargets()

-- 2. Бейджи
local sBadge = section("БЕЙДЖИ (монетки)")
local br = row(sBadge, 1)
local amount = box(br, "кол-во", "100", 110)
button(br, "ДАТЬ", 70, function() call("Badges", target, "give", tonumber(amount.Text) or 0) end)
button(br, "ЗАБРАТЬ", 80, function() call("Badges", target, "take", tonumber(amount.Text) or 0) end)
button(br, "УСТАНОВИТЬ", 100, function() call("Badges", target, "set", tonumber(amount.Text) or 0) end)

-- 2a. Возрождения (те, что продаются за 30 R$)
local sRev = section("ВОЗРОЖДЕНИЯ (REVIVE, 30 R$)")
local rr = row(sRev, 1)
local revAmount = box(rr, "кол-во", "1", 110)
button(rr, "ДАТЬ", 70, function() call("Revive", target, "give", tonumber(revAmount.Text) or 0) end)
button(rr, "ЗАБРАТЬ", 80, function() call("Revive", target, "take", tonumber(revAmount.Text) or 0) end)
button(rr, "УСТАНОВИТЬ", 100, function() call("Revive", target, "set", tonumber(revAmount.Text) or 0) end)

-- 2b. Снежинки
local sSnow = section("СНЕЖИНКИ (валюта New Year)")
local sr = row(sSnow, 1)
local snowAmount = box(sr, "кол-во", "100", 110)
button(sr, "ДАТЬ", 70, function() call("Snow", target, "give", tonumber(snowAmount.Text) or 0) end)
button(sr, "ЗАБРАТЬ", 80, function() call("Snow", target, "take", tonumber(snowAmount.Text) or 0) end)
button(sr, "УСТАНОВИТЬ", 100, function() call("Snow", target, "set", tonumber(snowAmount.Text) or 0) end)

-- 2c. Аксессуары (скины)
local sSkin = section("АКСЕССУАРЫ / СКИНЫ (подарить)")
local skm = row(sSkin, 0)
local skinId = box(skm, "id аксессуара", "", 200)
button(skm, "ДАТЬ", 70, function() call("Skin", target, skinId.Text) end)
local skr = row(sSkin, 1)
for _, id in info.skins or {} do
	button(skr, id, 100, function() call("Skin", target, id) end)
end

-- 2d. Титулы: существующие или любой свой текст
local sTitle = section("ТИТУЛЫ (выдать игроку на этом сервере)")
do
	local function tcall(...)
		local extraRf = game:GetService("ReplicatedStorage"):WaitForChild("EvaKExtra", 8)
		if not extraRf then return nil end
		local ok, r = pcall(function(...) return extraRf:InvokeServer(...) end, ...)
		return ok and r or nil
	end
	local tr1 = row(sTitle, 1)
	local lst = tcall("AdminTitles")
	for _, t in (lst and lst.titles) or {} do
		button(tr1, t.name, 110, function() tcall("AdminTitle", target, "give", t.id) end)
	end
	local tr2 = row(sTitle, 2)
	local customBox = box(tr2, "любой текст (до 24)", "", 220)
	button(tr2, "ВЫДАТЬ ТЕКСТ", 130, function() tcall("AdminTitle", target, "custom", customBox.Text) end)
	button(tr2, "СНЯТЬ ТИТУЛ", 110, function() tcall("AdminTitle", target, "clear", "") end)
end

-- 3. Игрушки
local sToy = section("ИГРУШКИ (подарить)")
local trm = row(sToy, 0)
local toyId = box(trm, "id игрушки (например CARBONCAR)", "", 250)
button(trm, "ДАТЬ ИГРУШКУ", 130, function() call("Toy", target, string.upper(toyId.Text)) end)
local tr = row(sToy, 1)
for _, id in info.toys or {} do
	button(tr, id, 84, function() call("Toy", target, id) end)
end

-- 4. «Геймпассы» (пакеты бейджей)
local sPack = section("ГЕЙМПАССЫ / ПАКЕТЫ (подарить)")
local pr = row(sPack, 1)
for _, pk in info.packs or {} do
	button(pr, "+" .. tostring(pk.badges) .. " бейджей", 130, function() call("Pack", target, pk.id) end)
end
button(pr, "ОТКРЫТЬ ВСЕ СЛОЖНОСТИ", 190, function() call("Unlock", target) end)

-- 5. Ивенты
local sEv = section("ИВЕНТЫ (сразу на ВСЕХ серверах)")
local er = row(sEv, 1)
local mult = box(er, "множитель", "2", 80)
local mins = box(er, "минут", "5", 70)
button(er, "x БЕЙДЖИ", 100, function() call("Event", 0, "badge", { mult = tonumber(mult.Text) or 2, mins = tonumber(mins.Text) or 5 }) end)
button(er, "x СКОРОСТЬ (до 2)", 150, function() call("Event", 0, "speed", { mult = tonumber(mult.Text) or 1.25, mins = tonumber(mins.Text) or 5 }) end)
button(er, "СТОП", 70, function() call("Event", 0, "stop", {}) end)
local erNY = row(sEv, 3)
button(erNY, "НОВЫЙ ГОД: снег и ёлки", 210, function() call("Event", 0, "newyear", { mins = tonumber(mins.Text) or 10 }) end)
button(erNY, "ТАКО: падают с неба", 180, function() call("Event", 0, "taco", { mins = tonumber(mins.Text) or 10 }) end)
local er2 = row(sEv, 2)
local gift = box(er2, "подарок всем", "50", 110)
button(er2, "ВСЕМ НА СЕРВЕРЕ", 150, function() call("Badges", 0, "give", tonumber(gift.Text) or 0) end)
button(er2, "ВСЕМ НА ВСЕХ СЕРВЕРАХ", 200, function() call("Badges", -1, "give", tonumber(gift.Text) or 0) end)

-- 5b. Игровые ивенты (обычные и редкие)
local sGE = section("ИВЕНТЫ ИГРЫ (на этом сервере)")
do
	local function ecall(...)
		local extraRf = game:GetService("ReplicatedStorage"):WaitForChild("EvaKExtra", 8)   -- ищем при нажатии, а не один раз при загрузке
		if not extraRf then warn("[EvaKAdmin] RemoteFunction EvaKExtra не найден: скрипт EvaKExtra.server не запущен") return nil end
		local ok, r = pcall(function(...) return extraRf:InvokeServer(...) end, ...)
		if not ok then warn("[EvaKAdmin] EvaKExtra ошибка:", r) end
		return ok and r or nil
	end
	local list = { "AdminAbuse", "OwnerAscent", "BloodMoon", "Blackout", "Invasion", "GiantEvaK", "Gravity", "FakeUpdate", "Earthquake", "Doppelgangers", "SilentMode", "Apocalypse",
		"OwnerIsHere", "RealityError", "LastGuest", "FalseExit", "EvaKArrival", "Judgment", "LostSouls", "TheEnd", "EternalNight", "Possession", "TheEye" }
	local g = row(sGE, 1)
	for _, n in list do
		button(g, n, 130, function() ecall("AdminEvent", n) end)
	end
	button(g, "СТОП ИВЕНТ", 130, function() ecall("AdminEvent", "off") end)
end

-- 5b. Диагностика скриптов сервера
local sDoc = section("ДИАГНОСТИКА")
do
	local r = row(sDoc, 1)
	button(r, "ПРОВЕРИТЬ СКРИПТЫ СЕРВЕРА", 260, function()
		local exRf = ReplicatedStorage:FindFirstChild("EvaKExtra")
		if not exRf then status.Text = "EvaKExtra.server НЕ запущен"; return end
		local okD, res = pcall(function() return exRf:InvokeServer("AdminDoctor") end)
		if okD and type(res) == "table" and res.lines then
			status.Text = table.concat(res.lines, " | ")
			status.TextColor3 = res.bad and Color3.fromRGB(240, 110, 110) or Color3.fromRGB(150, 230, 150)
		else status.Text = "диагностика не ответила: " .. tostring(res) end
	end)
end

-- 5c. Инструменты над игроками (цель выбирается вверху; ВСЕ = все на этом сервере)
local sTool = section("ИГРОК: ДЕЙСТВИЯ (над выбранной целью)")
local toolCall
do
	toolCall = function(tool: string, val: any)
		local extraRf = game:GetService("ReplicatedStorage"):WaitForChild("EvaKExtra", 8)
		if not extraRf then status.Text = "ERROR: EvaKExtra server script is not running"; status.TextColor3 = Color3.fromRGB(240, 110, 110); return end
		local ok, r = pcall(function() return extraRf:InvokeServer("AdminTool", tool, target, val) end)
		if not ok or type(r) ~= "table" then status.Text = "request error: " .. tostring(r); status.TextColor3 = Color3.fromRGB(240, 110, 110); return end
		status.Text = (r.ok and "OK  " or "ERROR: ") .. tostring(r.msg or "")
		status.TextColor3 = r.ok and Color3.fromRGB(150, 230, 150) or Color3.fromRGB(240, 110, 110)
	end
	local r1 = row(sTool, 1)
	button(r1, "HEAL", 70, function() toolCall("heal") end)
	button(r1, "KILL", 70, function() toolCall("kill") end)
	button(r1, "GOD MODE (toggle)", 160, function() toolCall("god") end)
	button(r1, "INVISIBLE (toggle)", 170, function() toolCall("invisible") end)
	button(r1, "FREEZE", 80, function() toolCall("freeze") end)
	button(r1, "UNFREEZE", 90, function() toolCall("unfreeze") end)
	local r2 = row(sTool, 2)
	local spd = box(r2, "speed", "32", 70)
	button(r2, "SET SPEED", 100, function() toolCall("speed", tonumber(spd.Text) or 16) end)
	button(r2, "RESET SPEED", 110, function() toolCall("speed", 16) end)
	local jmp = box(r2, "jump", "80", 70)
	button(r2, "SET JUMP", 90, function() toolCall("jump", tonumber(jmp.Text) or 50) end)
	local r3 = row(sTool, 3)
	button(r3, "BRING TO ME", 120, function() toolCall("bring") end)
	button(r3, "GO TO PLAYER", 120, function() toolCall("goto") end)
	button(r3, "SEND TO LOBBY", 130, function() toolCall("lobby") end)
	local kr = box(r3, "kick reason", "", 130)
	button(r3, "KICK", 70, function() toolCall("kick", kr.Text) end)
end

-- 5d. Монстры и сервер
local sMon = section("МОНСТРЫ (появятся у цели, только если она в забеге)")
do
	local r1 = row(sMon, 1)
	for _, k in { "fallen", "preacher", "evak", "guest", "crawl", "witness", "bellman", "wallcrawl", "knocker" } do
		button(r1, k, 100, function() toolCall("monster", k) end)
	end
	local r2 = row(sMon, 2)
	button(r2, "CLEAR ALL MONSTERS", 190, function() toolCall("clearmon") end)
	button(r2, "STOP ALL EVENTS", 160, function() toolCall("stopevents") end)
	local gv = box(r2, "gravity", "196.2", 80)
	button(r2, "SET GRAVITY", 120, function() toolCall("gravity", tonumber(gv.Text) or 196.2) end)
end

-- 6. Объявление
local sMsg = section("ОБЪЯВЛЕНИЕ ВСЕМ")
local mr = row(sMsg, 1)
local txt = box(mr, "текст (до 120 символов)", "", 250)
local altBox = box(mr, "от имени альта (пусто = я)", "", 150)
button(mr, "ОТПРАВИТЬ", 100, function() call("Announce", txt.Text, altBox.Text) end)

-- открыть/закрыть
local function setOpen(v: boolean)
	panel.Visible = v
	if v then UIS.MouseIconEnabled = true end
end
openBtn.Activated:Connect(function() setOpen(not panel.Visible) end)
closeBtn.Activated:Connect(function() setOpen(false) end)
game:GetService("ContextActionService"):BindActionAtPriority("EvaKAdminKey", function(_, state)
	if state == Enum.UserInputState.Begin then setOpen(not panel.Visible) end
	return Enum.ContextActionResult.Pass
end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.F2, Enum.KeyCode.Insert)
