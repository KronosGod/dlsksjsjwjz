-- ============================================================
--  EvaKTrade (LocalScript в StarterPlayerScripts)
--  Кнопка TRADES справа в меню: список игроков, окно обмена, история.
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local rf = ReplicatedStorage:WaitForChild("EvaKTrade", 30)
local ev = ReplicatedStorage:WaitForChild("EvaKTradeEvent", 30)
if not rf or not ev then return end

local GOLD, RED = Color3.fromRGB(230, 200, 140), Color3.fromRGB(215, 48, 40)
local FONT = Enum.Font.Arcade
local BG, CARD = Color3.fromRGB(14, 9, 8), Color3.fromRGB(28, 18, 15)

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in props do o[k] = v end
	o.Parent = parent
	return o
end
local function lbl(parent, text, size, pos, sz, color, align)
	return new("TextLabel", { BackgroundTransparency = 1, Text = text, Font = FONT, TextSize = size, TextColor3 = color or GOLD, Position = pos, Size = sz,
		TextXAlignment = align or Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 83 }, parent)
end
local function btn(parent, text, pos, sz, color)
	local b = new("TextButton", { Position = pos, Size = sz, BackgroundColor3 = color or Color3.fromRGB(110, 28, 22), Text = text, Font = FONT, TextSize = 14, TextColor3 = GOLD, ZIndex = 84 }, parent)
	new("UICorner", { CornerRadius = UDim.new(0, 0) }, b)
	return b
end
local function call(...)
	local ok, r = pcall(function(...) return rf:InvokeServer(...) end, ...)
	return ok and r or { ok = false, msg = "error" }
end

local gui = new("ScreenGui", { Name = "EvaKTradeGui", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 121, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, playerGui)

-- кнопка справа
local open = new("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 64), Size = UDim2.fromOffset(150, 40),
	BackgroundColor3 = Color3.fromRGB(26, 22, 8), Text = "TRADES", Font = FONT, TextSize = 16, TextColor3 = GOLD, Visible = false }, gui)
new("UICorner", { CornerRadius = UDim.new(0, 0) }, open)
new("UIStroke", { Color = Color3.fromRGB(200, 160, 60), Thickness = 2 }, open)
local dot = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -4, 0, 4), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = RED, Visible = false, ZIndex = 5 }, open)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)

-- окно
local dim = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.4, Text = "", AutoButtonColor = false, Visible = false, ZIndex = 80 }, gui)
local win = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(780, 520), BackgroundColor3 = BG, BorderSizePixel = 0, ZIndex = 81 }, dim)
new("UICorner", { CornerRadius = UDim.new(0, 0) }, win)
new("UIStroke", { Color = Color3.fromRGB(200, 160, 60), Thickness = 2 }, win)
local titleLbl = lbl(win, "TRADES", 22, UDim2.fromOffset(22, 12), UDim2.fromOffset(200, 30))
local status = lbl(win, "", 13, UDim2.fromOffset(230, 16), UDim2.fromOffset(440, 24), Color3.fromRGB(200, 120, 100))
local closeBtn = btn(win, "X", UDim2.new(1, -44, 0, 10), UDim2.fromOffset(32, 32), Color3.fromRGB(50, 20, 16))

local tabs, pages = {}, {}
local function showTab(n: string)
	for k, p in pages do p.Visible = (k == n) end
	for k, b in tabs do
		b.BackgroundColor3 = (k == n) and Color3.fromRGB(150, 40, 30) or Color3.fromRGB(50, 22, 18)
		b.Visible = (n ~= "TRADE")   -- во время обмена вкладок нет: только окно обмена
	end
	if titleLbl then titleLbl.Text = (n == "TRADE") and "TRADE WINDOW" or "TRADES" end
end
for i, n in { "PLAYERS", "HISTORY", "TRADE" } do
	tabs[n] = btn(win, n == "PLAYERS" and "SEND TRADE" or n, UDim2.fromOffset(22 + (i - 1) * 170, 52), UDim2.fromOffset(160, 30))
	if n == "TRADE" then tabs[n].Visible = false end
	pages[n] = new("Frame", { Position = UDim2.fromOffset(16, 90), Size = UDim2.new(1, -32, 1, -104), BackgroundTransparency = 1, Visible = false, ZIndex = 82 }, win)
	tabs[n].MouseButton1Click:Connect(function() showTab(n) end)
end

local function msg(t: string)
	status.Text = t
	task.delay(4, function() if status.Text == t then status.Text = "" end end)
end

local function listFrame(parent, pos, size)
	local sf = new("ScrollingFrame", { Position = pos, Size = size, BackgroundColor3 = Color3.fromRGB(20, 13, 11), BorderSizePixel = 0, ScrollBarThickness = 5,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 82 }, parent)
	new("UICorner", { CornerRadius = UDim.new(0, 0) }, sf)
	new("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, sf)
	new("UIPadding", { PaddingTop = UDim.new(0, 5), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5) }, sf)
	return sf
end
local function clear(sf) for _, c in sf:GetChildren() do if c:IsA("GuiObject") then c:Destroy() end end end
local function row(sf, h, order)
	local r = new("Frame", { Size = UDim2.new(1, -4, 0, h or 40), BackgroundColor3 = CARD, BorderSizePixel = 0, LayoutOrder = order or 0, ZIndex = 83 }, sf)
	new("UICorner", { CornerRadius = UDim.new(0, 0) }, r)
	return r
end

-- ===== PLAYERS =====
local pl = pages.PLAYERS
lbl(pl, "INVITES", 14, UDim2.fromOffset(0, 0), UDim2.fromOffset(300, 20))
local invList = listFrame(pl, UDim2.fromOffset(0, 22), UDim2.new(1, 0, 0, 120))
lbl(pl, "PLAYERS IN THIS SERVER", 14, UDim2.fromOffset(0, 150), UDim2.fromOffset(300, 20))
local plList = listFrame(pl, UDim2.fromOffset(0, 172), UDim2.new(1, 0, 1, -172))

-- ===== TRADE =====
local tr = pages.TRADE
local partnerLbl = lbl(tr, "", 16, UDim2.fromOffset(0, 0), UDim2.fromOffset(500, 22))
lbl(tr, "YOU GIVE", 13, UDim2.fromOffset(0, 26), UDim2.fromOffset(200, 18), Color3.fromRGB(200, 170, 120))
local mineList = listFrame(tr, UDim2.fromOffset(0, 46), UDim2.fromOffset(360, 110))
local theirLbl = lbl(tr, "YOU GET", 13, UDim2.fromOffset(372, 26), UDim2.fromOffset(300, 18), Color3.fromRGB(200, 170, 120))
local theirList = listFrame(tr, UDim2.fromOffset(372, 46), UDim2.fromOffset(360, 110))
lbl(tr, "YOUR INVENTORY (click to add)", 13, UDim2.fromOffset(0, 164), UDim2.fromOffset(300, 18), Color3.fromRGB(200, 170, 120))
local invFrame = listFrame(tr, UDim2.fromOffset(0, 184), UDim2.fromOffset(500, 190))
-- валюта
lbl(tr, "BADGES", 12, UDim2.fromOffset(512, 184), UDim2.fromOffset(100, 16))
local badgeBox = new("TextBox", { Position = UDim2.fromOffset(512, 202), Size = UDim2.fromOffset(110, 30), BackgroundColor3 = CARD, Text = "0", Font = FONT, TextSize = 15,
	TextColor3 = GOLD, ClearTextOnFocus = true, ZIndex = 84 }, tr)
new("UICorner", { CornerRadius = UDim.new(0, 0) }, badgeBox)
lbl(tr, "SNOWFLAKES", 12, UDim2.fromOffset(630, 184), UDim2.fromOffset(110, 16))
local snowBox = new("TextBox", { Position = UDim2.fromOffset(630, 202), Size = UDim2.fromOffset(100, 30), BackgroundColor3 = CARD, Text = "0", Font = FONT, TextSize = 15,
	TextColor3 = GOLD, ClearTextOnFocus = true, ZIndex = 84 }, tr)
new("UICorner", { CornerRadius = UDim.new(0, 0) }, snowBox)
local haveLbl = lbl(tr, "", 11, UDim2.fromOffset(512, 236), UDim2.fromOffset(230, 16), Color3.fromRGB(160, 140, 120))
local myState = lbl(tr, "", 13, UDim2.fromOffset(512, 262), UDim2.fromOffset(230, 36), Color3.fromRGB(200, 170, 120))
local readyBtn = btn(tr, "READY", UDim2.fromOffset(512, 308), UDim2.fromOffset(220, 40), Color3.fromRGB(40, 110, 50))
local cancelBtn = btn(tr, "CANCEL TRADE", UDim2.fromOffset(512, 356), UDim2.fromOffset(220, 34), Color3.fromRGB(90, 24, 20))

-- ===== HISTORY =====
local hs = pages.HISTORY
local histList = listFrame(hs, UDim2.fromOffset(0, 0), UDim2.new(1, 0, 1, 0))

-- ---------- состояние ----------
local inv: any = { badges = 0, snow = 0, toys = {}, skins = {}, items = {} }
local offer = { badges = 0, snow = 0, toys = {}, skins = {}, items = {} }
local session: any = nil
local myReady = false

local pushOffer
local function offerLines(sf, o, removable: boolean)
	clear(sf)
	local n = 0
	local function add(text, onClick)
		n += 1
		local r = row(sf, 26, n)
		local b = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = text, Font = FONT, TextSize = 13, TextColor3 = GOLD,
			TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 84 }, r)
		new("UIPadding", { PaddingLeft = UDim.new(0, 8) }, b)
		if removable and onClick then b.MouseButton1Click:Connect(onClick) else b.Active = false end
	end
	if (o.badges or 0) > 0 then add((o.badges) .. " BADGES") end
	if (o.snow or 0) > 0 then add((o.snow) .. " SNOWFLAKES") end
	for id, c in o.toys or {} do add("PET " .. id .. "  x" .. c .. (removable and "  (click: -1)" or ""), function()
		offer.toys[id] = (offer.toys[id] or 1) - 1
		if offer.toys[id] <= 0 then offer.toys[id] = nil end
		pushOffer()
	end) end
	for id in o.skins or {} do add("SKIN " .. id .. (removable and "  (click: remove)" or ""), function() offer.skins[id] = nil; pushOffer() end) end
	for id in o.items or {} do add("ITEM " .. id .. (removable and "  (click: remove)" or ""), function() offer.items[id] = nil; pushOffer() end) end
	if n == 0 then add("(nothing)") end
end

local function renderInv()
	clear(invFrame)
	local n = 0
	local function add(text, onClick)
		n += 1
		local r = row(invFrame, 28, n)
		local b = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = text, Font = FONT, TextSize = 13, TextColor3 = GOLD,
			TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 84 }, r)
		new("UIPadding", { PaddingLeft = UDim.new(0, 8) }, b)
		b.MouseButton1Click:Connect(onClick)
	end
	for id, c in inv.toys or {} do
		local used = offer.toys[id] or 0
		if c - used > 0 then add("PET " .. id .. "  (" .. (c - used) .. " left)", function()
			offer.toys[id] = (offer.toys[id] or 0) + 1; pushOffer()
		end) end
	end
	for _, id in inv.skins or {} do
		if not offer.skins[id] then add("SKIN " .. id, function() offer.skins[id] = true; pushOffer() end) end
	end
	for _, id in inv.items or {} do
		if not offer.items[id] then add("ITEM " .. id, function() offer.items[id] = true; pushOffer() end) end
	end
	if n == 0 then add("(nothing left to trade)", function() end) end
	haveLbl.Text = "You have: " .. tostring(inv.badges) .. " badges / " .. tostring(inv.snow) .. " snow"
end

pushOffer = function()
	offer.badges = math.clamp(math.floor(tonumber(badgeBox.Text) or 0), 0, inv.badges or 0)
	offer.snow = math.clamp(math.floor(tonumber(snowBox.Text) or 0), 0, inv.snow or 0)
	badgeBox.Text = tostring(offer.badges); snowBox.Text = tostring(offer.snow)
	local r = call("Offer", offer)
	if not r.ok then msg(tostring(r.msg or "invalid offer")) end
	offerLines(mineList, offer, true)
	renderInv()
end
badgeBox.FocusLost:Connect(function() if session then pushOffer() end end)
snowBox.FocusLost:Connect(function() if session then pushOffer() end end)

local function renderSession(v)
	session = v
	if not v then return end
	partnerLbl.Text = "Trading with " .. v.partner
	theirLbl.Text = "YOU GET FROM " .. v.partner:upper()
	offer = { badges = v.mine.badges, snow = v.mine.snow, toys = v.mine.toys, skins = v.mine.skins, items = v.mine.items }
	badgeBox.Text = tostring(offer.badges); snowBox.Text = tostring(offer.snow)
	offerLines(mineList, offer, true)
	offerLines(theirList, v.theirs, false)
	myReady = v.myReady
	readyBtn.Text = myReady and "NOT READY" or "READY"
	readyBtn.BackgroundColor3 = myReady and Color3.fromRGB(120, 90, 20) or Color3.fromRGB(40, 110, 50)
	myState.Text = (myReady and "You: READY" or "You: not ready") .. "\n" .. (v.theirReady and "They: READY" or "They: not ready")
	renderInv()
end

local function timeAgo(t)
	local d = os.time() - t
	if d < 3600 then return math.max(1, d // 60) .. " min ago" end
	if d < 86400 then return d // 3600 .. " h ago" end
	return d // 86400 .. " d ago"
end

local function refresh()
	local r = call("Info")
	if not r.ok then return end
	-- игроки
	clear(plList)
	for i, p in r.players do
		local rw = row(plList, 38, i)
		lbl(rw, p.name, 15, UDim2.fromOffset(10, 0), UDim2.new(1, -200, 1, 0))
		if p.inRun then lbl(rw, "IN RUN", 12, UDim2.new(1, -180, 0, 0), UDim2.fromOffset(80, 38), Color3.fromRGB(150, 120, 100))
		elseif p.busy then lbl(rw, "BUSY", 12, UDim2.new(1, -180, 0, 0), UDim2.fromOffset(80, 38), Color3.fromRGB(150, 120, 100))
		else
			local b = btn(rw, "TRADE", UDim2.new(1, -96, 0, 5), UDim2.fromOffset(86, 28))
			b.MouseButton1Click:Connect(function()
				local rr = call("Invite", p.id)
				msg(rr.ok and ("Invite sent to " .. p.name) or tostring(rr.msg))
			end)
		end
	end
	if #r.players == 0 then lbl(row(plList, 38, 1), "No other players here", 14, UDim2.fromOffset(10, 0), UDim2.new(1, -20, 1, 0), Color3.fromRGB(150, 130, 110)) end
	-- приглашения
	clear(invList)
	for i, inc in r.incoming do
		local rw = row(invList, 38, i)
		lbl(rw, inc.name .. " wants to trade", 14, UDim2.fromOffset(10, 0), UDim2.new(1, -220, 1, 0))
		local ok = btn(rw, "ACCEPT", UDim2.new(1, -190, 0, 5), UDim2.fromOffset(86, 28), Color3.fromRGB(40, 110, 50))
		local no = btn(rw, "DECLINE", UDim2.new(1, -98, 0, 5), UDim2.fromOffset(86, 28), Color3.fromRGB(90, 24, 20))
		ok.MouseButton1Click:Connect(function()
			local rr = call("Accept", inc.id)
			if not rr.ok then msg(tostring(rr.msg)) end
		end)
		no.MouseButton1Click:Connect(function() call("Decline", inc.id); refresh() end)
	end
	dot.Visible = #r.incoming > 0
	-- история
	clear(histList)
	for i, h in r.history or {} do
		local rw = row(histList, 58, i)
		lbl(rw, h.with .. "  ·  " .. timeAgo(h.t), 13, UDim2.fromOffset(10, 4), UDim2.new(1, -20, 0, 18))
		local g = lbl(rw, "GAVE: " .. h.gave, 12, UDim2.fromOffset(10, 22), UDim2.new(1, -20, 0, 16), Color3.fromRGB(220, 130, 110))
		lbl(rw, "GOT: " .. h.got, 12, UDim2.fromOffset(10, 38), UDim2.new(1, -20, 0, 16), Color3.fromRGB(130, 210, 140))
	end
	if #(r.history or {}) == 0 then lbl(row(histList, 38, 1), "No trades yet", 14, UDim2.fromOffset(10, 0), UDim2.new(1, -20, 1, 0), Color3.fromRGB(150, 130, 110)) end
	-- инвентарь/сессия
	inv = r.inv or inv
	if r.session then renderSession(r.session); showTab("TRADE") else renderInv() end
end

readyBtn.MouseButton1Click:Connect(function()
	local r = call("Ready", not myReady)
	if not r.ok then msg(tostring(r.msg or "")) end
end)
cancelBtn.MouseButton1Click:Connect(function() call("Cancel") end)

ev.OnClientEvent:Connect(function(kind, a, b, c)
	if kind == "State" then
		if not dim.Visible then dim.Visible = true end
		local r = call("Info")
		if r.ok then inv = r.inv or inv end
		renderSession(a)
		showTab("TRADE")
	elseif kind == "Closed" then
		session = nil
		myReady = false
		if a and a ~= "" and a ~= "done" then msg("Trade closed: " .. a) end
		task.defer(function() refresh(); showTab(a == "done" and "HISTORY" or "PLAYERS") end)
	elseif kind == "Done" then
		msg("TRADE COMPLETE!")
		local bn = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(520, 150), BackgroundColor3 = Color3.fromRGB(20, 40, 22), ZIndex = 120 }, gui)
		new("UIStroke", { Color = Color3.fromRGB(120, 220, 130), Thickness = 3 }, bn)
		local function bl(t, y, sz, col) local l = lbl(bn, t, sz, UDim2.fromOffset(10, y), UDim2.new(1, -20, 0, sz + 6), col, Enum.TextXAlignment.Center); l.ZIndex = 121; l.TextTruncate = Enum.TextTruncate.None; l.TextWrapped = true end
		bl("TRADE COMPLETE", 12, 26, Color3.fromRGB(150, 255, 160))
		bl("with " .. tostring(c or "?"), 46, 14, GOLD)
		bl("YOU GOT: " .. tostring(a or "nothing"), 74, 13, Color3.fromRGB(130, 210, 140))
		bl("YOU GAVE: " .. tostring(b or "nothing"), 104, 13, Color3.fromRGB(220, 130, 110))
		task.delay(3.5, function() bn:Destroy() end)
	elseif kind == "Msg" then
		msg(tostring(a))
	elseif kind == "Invite" then
		dot.Visible = true
		if not session then dim.Visible = true; showTab("PLAYERS"); refresh() end   -- приглашение сразу показывается с кнопкой ACCEPT
		msg(tostring(a) .. " wants to trade!")
	end
end)

local function openTrades() dim.Visible = true; showTab("PLAYERS"); refresh() end
open.MouseButton1Click:Connect(openTrades)
player:GetAttributeChangedSignal('EvaKOpenTrades'):Connect(openTrades)
closeBtn.MouseButton1Click:Connect(function() dim.Visible = false end)
dim.MouseButton1Click:Connect(function() end)

-- кнопка видна только в меню
task.spawn(function()
	while true do
		local m = playerGui:FindFirstChild("IntroMenu")
		local v = m ~= nil and (m :: ScreenGui).Enabled and player:GetAttribute("EvaKInRun") ~= true
		open.Visible = false
		if not v and not session then dim.Visible = false end
		task.wait(0.3)
	end
end)
