-- ============================================================
--  EvaKFlash (LocalScript в StarterPlayerScripts)
--  ФОНАРИК (покупается перед забегом как предмет FLASHLIGHT): мощный направленный луч, есть батарейка.
--  Клавиша G. Если посветить на монстров на потолке/стене (The Crawl, WallCrawler) - на них проступает КРЕСТ,
--  и через ~1.4 сек света они исчезают.
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local hitRemote = ReplicatedStorage:WaitForChild("EvaKFlashHit", 30)

local CAP, DRAIN = 100, 1.35        -- ёмкость и расход в секунду (≈74 c света)
local battery = CAP
local on = false

local function hasFlash(): boolean
	return player:GetAttribute("EvaKInRun") == true and string.find("," .. tostring(player:GetAttribute("RunItems") or "") .. ",", ",FLASH,", 1, true) ~= nil
end

-- луч
local holder = Instance.new("Part")
holder.Name = "EvaKFlashHolder"; holder.Anchored = true; holder.CanCollide = false; holder.CanQuery = false; holder.CanTouch = false; holder.Transparency = 1; holder.Size = Vector3.one
holder.Parent = workspace
local spot = Instance.new("SpotLight")
spot.Face = Enum.NormalId.Front; spot.Range = 75; spot.Angle = 52; spot.Brightness = 8; spot.Color = Color3.fromRGB(255, 246, 220); spot.Shadows = true; spot.Enabled = false; spot.Parent = holder
local glow = Instance.new("PointLight")
glow.Range = 10; glow.Brightness = 0.8; glow.Color = Color3.fromRGB(255, 240, 210); glow.Enabled = false; glow.Parent = holder

-- HUD
local gui = Instance.new("ScreenGui"); gui.Name = "EvaKFlashHud"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 40; gui.Parent = playerGui
local root = Instance.new("Frame")
root.AnchorPoint = Vector2.new(0, 1); root.Position = UDim2.new(0, 16, 1, -70); root.Size = UDim2.fromOffset(190, 44); root.BackgroundColor3 = Color3.fromRGB(18, 14, 10); root.BorderSizePixel = 0; root.Visible = false; root.Parent = gui
local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(200, 170, 90); stroke.Thickness = 2; stroke.Parent = root
local title = Instance.new("TextLabel"); title.BackgroundTransparency = 1; title.Position = UDim2.fromOffset(8, 2); title.Size = UDim2.new(1, -16, 0, 16)
title.Font = Enum.Font.Arcade; title.TextSize = 13; title.TextColor3 = Color3.fromRGB(235, 215, 160); title.TextXAlignment = Enum.TextXAlignment.Left; title.Text = "FLASHLIGHT [G]"; title.Parent = root
local barBg = Instance.new("Frame"); barBg.Position = UDim2.fromOffset(8, 24); barBg.Size = UDim2.new(1, -16, 0, 12); barBg.BackgroundColor3 = Color3.fromRGB(40, 32, 24); barBg.BorderSizePixel = 0; barBg.Parent = root
local barFill = Instance.new("Frame"); barFill.Size = UDim2.fromScale(1, 1); barFill.BackgroundColor3 = Color3.fromRGB(120, 220, 120); barFill.BorderSizePixel = 0; barFill.Parent = barBg

UIS.InputBegan:Connect(function(i, gp)
	if gp or i.KeyCode ~= Enum.KeyCode.G then return end
	if not hasFlash() then return end
	if battery <= 0 then return end
	on = not on
end)

-- монстры, которых можно прогнать светом
local TARGETS = { TheCrawl = true, WallCrawler = true }
local crosses: {[Model]: BillboardGui} = {}
local exposure: {[Model]: number} = {}
local function crossFor(m: Model): BillboardGui?
	if crosses[m] then return crosses[m] end
	local adornee = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true)
	if not adornee then return nil end
	local bb = Instance.new("BillboardGui")
	bb.Adornee = adornee; bb.AlwaysOnTop = true; bb.Size = UDim2.fromOffset(150, 150); bb.StudsOffset = Vector3.new(0, 1.5, 0); bb.Enabled = false; bb.Parent = adornee
	local t = Instance.new("TextLabel"); t.Size = UDim2.fromScale(1, 1); t.BackgroundTransparency = 1; t.Font = Enum.Font.SourceSansBold; t.TextScaled = true
	t.Text = "✝"; t.TextColor3 = Color3.fromRGB(255, 245, 215); t.TextStrokeColor3 = Color3.fromRGB(255, 40, 20); t.TextStrokeTransparency = 0; t.Parent = bb
	crosses[m] = bb
	return bb
end

local acc = 0
RunService.RenderStepped:Connect(function(dt)
	local cam = workspace.CurrentCamera
	local active = hasFlash()
	root.Visible = active
	if not active then
		on = false; battery = CAP
		spot.Enabled = false; glow.Enabled = false
		return
	end
	if on then
		battery = math.max(0, battery - DRAIN * dt)
		if battery <= 0 then on = false end
	end
	local pct = battery / CAP
	barFill.Size = UDim2.fromScale(pct, 1)
	barFill.BackgroundColor3 = pct > 0.5 and Color3.fromRGB(120, 220, 120) or (pct > 0.2 and Color3.fromRGB(230, 200, 80) or Color3.fromRGB(230, 70, 60))
	title.Text = battery <= 0 and "BATTERY DEAD" or (on and "FLASHLIGHT [G]  ON" or "FLASHLIGHT [G]")
	local flick = (on and pct < 0.15 and math.random() < 0.18) and 0.15 or 1   -- садится: мигает
	spot.Enabled = on; glow.Enabled = on
	spot.Brightness = 8 * flick; glow.Brightness = 0.8 * flick
	if cam then holder.CFrame = cam.CFrame * CFrame.new(0.3, -0.3, -1.2) end

	-- поиск монстров под лучом
	acc += dt
	if acc < 0.1 or not cam then return end
	local step = acc; acc = 0
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: Instance, holder }
	for _, d in workspace:GetChildren() do
		if d:IsA("Model") and TARGETS[d.Name] then
			local m = d :: Model
			local ok, pos = pcall(function() return m:GetPivot().Position end)
			if ok then
				local v = pos - cam.CFrame.Position
				local dist = v.Magnitude
				local lit = false
				if on and flick == 1 and dist < 72 and dist > 1 then
					local ang = math.deg(math.acos(math.clamp(cam.CFrame.LookVector:Dot(v.Unit), -1, 1)))
					if ang < 26 then
						local r = workspace:Raycast(cam.CFrame.Position, v, params)
						lit = (r == nil) or r.Instance:IsDescendantOf(m)
					end
				end
				local bb = crossFor(m)
				if bb then bb.Enabled = lit end
				if lit then
					exposure[m] = (exposure[m] or 0) + step
					if exposure[m] >= 1.4 then
						exposure[m] = nil
						if hitRemote then hitRemote:FireServer(m) end
					end
				else
					exposure[m] = math.max(0, (exposure[m] or 0) - step * 0.7)
				end
			end
		end
	end
end)
