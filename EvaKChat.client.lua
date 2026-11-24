-- ============================================================
--  EvaKChat (LocalScript в StarterPlayerScripts)
--  Свой чат СВЕРХУ слева: кнопка CHAT открывает/закрывает окно. Клавиши "/" или T тоже открывают и ставят курсор в поле.
--  Enter - отправить. Показывает [CarBon]/[титул] + ник + сообщение. Стандартный чат Roblox выключен.
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local send = ReplicatedStorage:WaitForChild("EvaKChatSend", 30)
local recv = ReplicatedStorage:WaitForChild("EvaKChatRecv", 30)
if not send or not recv then warn("[EvaKChat] нет EvaKChatSend/EvaKChatRecv - запусти EvaKChat.server") return end

-- выключаем стандартный чат Roblox (CoreGui иногда готов не сразу - повторяем)
local function killDefault()
	pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false) end)
	pcall(function() TextChatService.ChatWindowConfiguration.Enabled = false end)
	pcall(function() TextChatService.ChatInputBarConfiguration.Enabled = false end)
	pcall(function() TextChatService.BubbleChatConfiguration.Enabled = false end)
end
killDefault()
task.spawn(function() for _ = 1, 20 do task.wait(1); killDefault() end end)

local GOLD, GOLD_DIM = Color3.fromRGB(230, 200, 140), Color3.fromRGB(150, 118, 70)
local FONT = Enum.Font.Arcade

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in props do o[k] = v end
	o.Parent = parent
	return o
end

local gui = new("ScreenGui", { Name = "EvaKChatGui", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 200 }, playerGui)

local toggle = new("TextButton", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 10, 1, -92), Size = UDim2.fromOffset(92, 30), BackgroundColor3 = Color3.fromRGB(14, 9, 6), BackgroundTransparency = 0.1,
	BorderSizePixel = 0, Text = "CHAT", Font = FONT, TextSize = 15, TextColor3 = GOLD, AutoButtonColor = false, ZIndex = 20 }, gui)
new("UIStroke", { Color = GOLD_DIM, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, toggle)
local dot = new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -3, 0, 3), Size = UDim2.fromOffset(8, 8), BackgroundColor3 = Color3.fromRGB(230, 50, 40), BorderSizePixel = 0, Visible = false, ZIndex = 21 }, toggle)

local box = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 10, 1, -128), Size = UDim2.fromOffset(400, 250), BackgroundColor3 = Color3.fromRGB(10, 7, 6),
	BackgroundTransparency = 0.12, BorderSizePixel = 0, Visible = false, ZIndex = 20 }, gui)
new("UIStroke", { Color = GOLD_DIM, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, box)
local scroll = new("ScrollingFrame", { Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 1, -56), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
	ScrollBarImageColor3 = GOLD, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 21 }, box)
new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)
local input = new("TextBox", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 8, 1, -8), Size = UDim2.new(1, -16, 0, 30), BackgroundColor3 = Color3.fromRGB(28, 18, 12),
	Text = "", PlaceholderText = "type here and press Enter", Font = FONT, TextSize = 14, TextColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0.6, PlaceholderColor3 = Color3.fromRGB(130, 110, 95),
	TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 22 }, box)
new("UIStroke", { Color = GOLD_DIM, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, input)
new("UIPadding", { PaddingLeft = UDim.new(0, 8) }, input)

local order = 0
local isOpen = false
local pending: {[number]: Frame} = {}   -- свои сообщения, которые ещё не подтвердил сервер
local mid = 0

local function esc(s: string): string
	return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local function setOpen(v: boolean)
	isOpen = v
	box.Visible = v
	if v then dot.Visible = false; task.defer(function() scroll.CanvasPosition = Vector2.new(0, 1e6) end) end
	toggle.TextColor3 = v and Color3.fromRGB(255, 255, 255) or GOLD
end

local function addMessage(m)
	if m.mid and m.mid > 0 and pending[m.mid] then pending[m.mid]:Destroy(); pending[m.mid] = nil end
	order += 1
	local row = new("Frame", { Size = UDim2.new(1, -6, 0, 18), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = order, ZIndex = 22 }, scroll)
	if m.sys then
		new("TextLabel", { Size = UDim2.new(1, 0, 0, 18), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
			Text = esc(m.text), RichText = true, Font = FONT, TextSize = 13, TextColor3 = Color3.fromRGB(200, 120, 100), ZIndex = 23 }, row)
	else
		local god = m.god and '<font color="#ffd24a"><b>[GOD]</b></font> ' or ""
		local crown = m.crown and "👑 " or ""
		local vip = m.vip and '<font color="#ff4646">[CarBon]</font> ' or ""
		local title = (m.title and m.title ~= "" and not m.vip) and ('<font color="#' .. tostring(m.tcol or "d73c32"):gsub("[^%x]", "") .. '">[' .. esc(m.title) .. ']</font> ') or ""
		new("TextLabel", { Size = UDim2.new(1, 0, 0, 18), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, TextWrapped = true,
			TextTransparency = m.pendingId and 0.45 or 0, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, RichText = true, Font = FONT, TextSize = 14, TextColor3 = Color3.fromRGB(245, 238, 226), ZIndex = 23,
			Text = god .. crown .. title .. vip .. '<font color="#e6c88c">' .. esc(m.name) .. "</font>: " .. esc(m.text) }, row)
	end
	if m.pendingId then pending[m.pendingId] = row end
	local kids = {}
	for _, c in scroll:GetChildren() do if c:IsA("Frame") then table.insert(kids, c) end end
	if #kids > 60 then table.sort(kids, function(a, b) return a.LayoutOrder < b.LayoutOrder end); kids[1]:Destroy() end
	task.defer(function() scroll.CanvasPosition = Vector2.new(0, 1e6) end)
	if not isOpen then dot.Visible = true end   -- красная точка: есть новое сообщение
end
recv.OnClientEvent:Connect(addMessage)

toggle.MouseButton1Click:Connect(function() setOpen(not isOpen) end)

UIS.InputBegan:Connect(function(i, processed)
	if i.KeyCode == Enum.KeyCode.Slash or (i.KeyCode == Enum.KeyCode.T and not processed) then
		if UIS:GetFocusedTextBox() then return end
		setOpen(true)
		task.defer(function() input:CaptureFocus(); input.Text = "" end)
	end
end)
input.FocusLost:Connect(function(enter)
	local t = input.Text
	if enter and t ~= "" then
		mid += 1
		local id = mid
		if t:sub(1, 1) ~= "/" then   -- сразу показываем своё сообщение (бледное), сервер подтвердит и заменит
			addMessage({ name = player.DisplayName, text = t, pendingId = id, vip = player:GetAttribute("XVip") == true, god = player:GetAttribute("EvaKOwner") == true, title = player:GetAttribute("XTitleText") or "", tcol = player:GetAttribute("XTitleColor") })
			task.delay(4, function()
				local row = pending[id]
				if row then
					pending[id] = nil
					local dups = 0
					for _, o in ReplicatedStorage:GetChildren() do if o.Name == "EvaKChatSend" then dups += 1 end end
					addMessage({ sys = true, text = dups > 1 and "TWO EvaKChat server scripts are running - delete the old copy in ServerScriptService." or
						(ReplicatedStorage:GetAttribute("EvaKChatReady") ~= true and "Chat server script did not start - see Output for red errors in EvaKChat (it must be a Script in ServerScriptService)." or "No reply from the chat server - see Output.") })
					for _, c in row:GetChildren() do if c:IsA("TextLabel") then c.TextColor3 = Color3.fromRGB(220, 90, 80); c.Text = c.Text .. "  <i>(not delivered)</i>" end end
				end
			end)
		end
		send:FireServer(t, id)
	end
	input.Text = ""
	if enter then   -- остаёмся в поле: можно сразу писать следующее сообщение
		task.defer(function() if isOpen then input:CaptureFocus(); input.Text = "" end end)
	end
end)

-- подсказка по горячим клавишам (внизу по центру, едва заметная)
do
	local hg = new("ScreenGui", { Name = "EvaKHotkeys", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 5 }, playerGui)
	new("TextLabel", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -4), Size = UDim2.fromOffset(520, 16), BackgroundTransparency = 1, Font = FONT, TextSize = 12,
		TextColor3 = Color3.fromRGB(200, 180, 150), TextTransparency = 0.45, Text = "J BOOK    P PLAYERS    T CHAT    F2 ADMIN    G FLASHLIGHT" }, hg)
end
