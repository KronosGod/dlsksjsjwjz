-- ============================================================
--  EvaKEventHud (LocalScript в StarterPlayerScripts)
--  Плашка активного ивента СПРАВА ВНИЗУ: название, описание, «ENDS IN». Работает сама по атрибутам workspace
--  (EvaKEvent / EvaKEventEnd), не зависит от других клиентских скриптов.
-- ============================================================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local INFO = {
	OwnerAscent = { "THE OWNER ASCENDS", "Heavenly descent - x2 BADGES" },
	BloodMoon = { "BLOOD MOON", "The whole screen turns red" },
	Blackout = { "BLACKOUT", "The lights are gone" },
	Invasion = { "INVASION", "Monsters come three times as often" },
	GiantEvaK = { "GIANT EVAK", "Something huge walks the halls" },
	Gravity = { "LOW GRAVITY", "You float" },
	FakeUpdate = { "FAKE UPDATE", "Don't trust the screen" },
	Earthquake = { "EARTHQUAKE", "The ground shakes" },
	Doppelgangers = { "DOPPELGANGERS", "Someone looks just like you" },
	SilentMode = { "SILENT MODE", "No sound at all" },
	Apocalypse = { "APOCALYPSE", "All of it. At once" },
	Taco = { "TACO RAIN", "Tacos fall from the sky" },
	NewYear = { "NEW YEAR", "Snow, trees and lights" },
	OwnerIsHere = { "THE OWNER IS HERE", "Behave" },
	RealityError = { "REALITY ERROR", "The world glitches" },
	LastGuest = { "THE LAST GUEST", "Don't get close" },
	FalseExit = { "FALSE EXIT", "Not every exit is an exit" },
	EvaKArrival = { "EVAK ARRIVES", "..." },
	Judgment = { "JUDGMENT", "Sinners will pay" },
	LostSouls = { "LOST SOULS", "They whisper your name" },
	TheEnd = { "THE END", "Everything is happening" },
	EternalNight = { "ETERNAL NIGHT", "The dark does not end" },
	Possession = { "POSSESSION", "Something is inside you" },
	TheEye = { "THE EYE", "It sees you" },
}

local GLYPH = {
	BloodMoon = "☾", Blackout = "✹", Invasion = "☠", GiantEvaK = "☗", Gravity = "↑", FakeUpdate = "!", Earthquake = "≈", Doppelgangers = "☻", SilentMode = "∅",
	Apocalypse = "☢", Taco = "T", NewYear = "*", OwnerAscent = "✦", OwnerIsHere = "♛", TheEye = "◉", EternalNight = "☾", Possession = "☠", Judgment = "⚖",
}
local gui = Instance.new("ScreenGui"); gui.Name = "EvaKEventHud"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 300; gui.Parent = playerGui
-- стопка плашек: у каждого активного ивента своя маленькая плашка (иконка + название + время), новые сверху
local stack = Instance.new("Frame")
stack.AnchorPoint = Vector2.new(1, 1); stack.Position = UDim2.new(1, -12, 1, -12); stack.Size = UDim2.fromOffset(190, 10)
stack.AutomaticSize = Enum.AutomaticSize.Y; stack.BackgroundTransparency = 1; stack.Parent = gui
local lay = Instance.new("UIListLayout"); lay.Padding = UDim.new(0, 4); lay.SortOrder = Enum.SortOrder.LayoutOrder
lay.VerticalAlignment = Enum.VerticalAlignment.Bottom; lay.HorizontalAlignment = Enum.HorizontalAlignment.Right; lay.Parent = stack
do   -- масштаб под размер экрана
	local cam = workspace.CurrentCamera
	local function k() local v = cam and cam.ViewportSize or Vector2.new(1280, 720); return math.clamp(math.min(v.X / 1100, v.Y / 700), 0.6, 1) end
	local us = Instance.new("UIScale"); us.Scale = k(); us.Parent = stack
	if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(function() us.Scale = k() end) end
end

local rows: {[string]: { box: Frame, time: TextLabel, st: UIStroke, bar: Frame, total: number, glow: UIGradient }} = {}
local ACCENT = { Taco = Color3.fromRGB(255, 190, 60), NewYear = Color3.fromRGB(120, 200, 255), OwnerAscent = Color3.fromRGB(255, 220, 120), OwnerIsHere = Color3.fromRGB(255, 220, 120) }
local function makeRow(name: string)
	local acc = ACCENT[name] or Color3.fromRGB(225, 56, 44)
	local box = Instance.new("Frame"); box.Size = UDim2.fromOffset(210, 40); box.BackgroundColor3 = Color3.fromRGB(22, 12, 12); box.BackgroundTransparency = 0.12; box.BorderSizePixel = 0; box.ClipsDescendants = true; box.Parent = stack
	local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0, 8); cr.Parent = box
	local bg = Instance.new("UIGradient"); bg.Rotation = 0
	bg.Color = ColorSequence.new(Color3.fromRGB(58, 26, 24), Color3.fromRGB(14, 8, 10)); bg.Parent = box
	local st = Instance.new("UIStroke"); st.Color = acc; st.Thickness = 1.5; st.Transparency = 0.15; st.Parent = box
	local badge = Instance.new("Frame"); badge.Position = UDim2.fromOffset(5, 5); badge.Size = UDim2.fromOffset(30, 30); badge.BackgroundColor3 = acc; badge.BorderSizePixel = 0; badge.Parent = box
	local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(1, 0); bc.Parent = badge
	local bgr = Instance.new("UIGradient"); bgr.Rotation = 90; bgr.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(120, 120, 120)); bgr.Parent = badge
	local icon = Instance.new("TextLabel"); icon.BackgroundTransparency = 1; icon.Size = UDim2.fromScale(1, 1)
	icon.Font = Enum.Font.GothamBold; icon.TextSize = 18; icon.TextColor3 = Color3.fromRGB(20, 8, 8); icon.Text = GLYPH[name] or "!"; icon.Parent = badge
	local nm = Instance.new("TextLabel"); nm.BackgroundTransparency = 1; nm.Position = UDim2.fromOffset(42, 3); nm.Size = UDim2.new(1, -104, 0, 20)
	nm.Font = Enum.Font.Arcade; nm.TextSize = 13; nm.TextColor3 = Color3.fromRGB(240, 226, 206); nm.TextXAlignment = Enum.TextXAlignment.Left; nm.TextTruncate = Enum.TextTruncate.AtEnd
	nm.Text = (INFO[name] and INFO[name][1]) or name:upper(); nm.Parent = box
	local sub = Instance.new("TextLabel"); sub.BackgroundTransparency = 1; sub.Position = UDim2.fromOffset(42, 20); sub.Size = UDim2.new(1, -104, 0, 14)
	sub.Font = Enum.Font.Gotham; sub.TextSize = 10; sub.TextColor3 = Color3.fromRGB(170, 150, 140); sub.TextXAlignment = Enum.TextXAlignment.Left; sub.TextTruncate = Enum.TextTruncate.AtEnd
	sub.Text = (INFO[name] and INFO[name][2]) or ""; sub.Parent = box
	local timeL = Instance.new("TextLabel"); timeL.BackgroundTransparency = 1; timeL.AnchorPoint = Vector2.new(1, 0); timeL.Position = UDim2.new(1, -8, 0, 0); timeL.Size = UDim2.fromOffset(56, 36)
	timeL.Font = Enum.Font.Arcade; timeL.TextSize = 16; timeL.TextColor3 = Color3.fromRGB(255, 220, 150); timeL.TextXAlignment = Enum.TextXAlignment.Right; timeL.Text = ""; timeL.Parent = box
	local track = Instance.new("Frame"); track.AnchorPoint = Vector2.new(0, 1); track.Position = UDim2.fromScale(0, 1); track.Size = UDim2.new(1, 0, 0, 3); track.BackgroundColor3 = Color3.fromRGB(0, 0, 0); track.BackgroundTransparency = 0.5; track.BorderSizePixel = 0; track.Parent = box
	local bar = Instance.new("Frame"); bar.Size = UDim2.fromScale(1, 1); bar.BackgroundColor3 = acc; bar.BorderSizePixel = 0; bar.Parent = track
	box.Position = UDim2.fromOffset(40, 0)
	rows[name] = { box = box, time = timeL, st = st, bar = bar, total = 0, glow = bg }
end

local function parse(): {[string]: number}
	local out = {}
	local str = workspace:GetAttribute("EvaKEvents")
	if type(str) == "string" and str ~= "" then
		for part in string.gmatch(str, "[^;]+") do
			local n, e = part:match("^([^=]+)=(%d+)")
			if n then out[n] = tonumber(e) or 0 end
		end
	else
		local ev = workspace:GetAttribute("EvaKEvent") or ""
		if ev ~= "" then out[ev] = workspace:GetAttribute("EvaKEventEnd") or 0 end
	end
	for _, e in { { "EvaKTaco", "Taco" }, { "EvaKNewYear", "NewYear" } } do
		if workspace:GetAttribute(e[1]) == true then
			local en = workspace:GetAttribute(e[1] .. "End")
			out[e[2]] = (type(en) == "number" and en > 0) and en or (os.time() + 3600)
		end
	end
	return out
end

task.spawn(function()
	while true do
		local cur = parse()
		for n in cur do if not rows[n] then makeRow(n) end end
		for n, r in rows do
			local e = cur[n]
			if not e then r.box:Destroy(); rows[n] = nil
			else
				local left = math.max(0, e - os.time())
				r.time.Text = string.format("%02d:%02d", left // 60, left % 60)
				r.box.LayoutOrder = left   -- чем меньше осталось, тем ближе к низу
				if left > r.total then r.total = left; r.box:TweenPosition(UDim2.fromOffset(0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.4, true) end
				r.bar.Size = UDim2.fromScale(math.clamp(left / math.max(r.total, 1), 0, 1), 1)
				r.st.Transparency = 0.15 + 0.3 * (0.5 + 0.5 * math.sin(os.clock() * 3))
			end
		end
		task.wait(0.25)
	end
end)
