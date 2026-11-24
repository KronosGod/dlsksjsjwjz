-- EvaKGraphics (LocalScript в StarterPlayerScripts): максимальная графика на клиенте
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local function set(o, p, v) pcall(function() o[p] = v end) end
local function eff(class, name, props)
	local e = Lighting:FindFirstChild(name)
	if not e then e = Instance.new(class); e.Name = name; e.Parent = Lighting end
	for k, v in props do set(e, k, v) end
	return e
end

set(Lighting, "GlobalShadows", true)
set(Lighting, "ShadowSoftness", 0.12)
set(Lighting, "EnvironmentDiffuseScale", 1)
set(Lighting, "EnvironmentSpecularScale", 1)
set(Lighting, "Technology", Enum.Technology.Future) -- на клиенте обычно не сработает; задай в Studio вручную
pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level21 end)

eff("BloomEffect", "EvaKBloom", { Intensity = 0.75, Size = 36, Threshold = 0.92 })
eff("ColorCorrectionEffect", "EvaKCC", { Contrast = 0.1, Saturation = 0.12, Brightness = 0, TintColor = Color3.fromRGB(255, 232, 215) })
eff("SunRaysEffect", "EvaKRays", { Intensity = 0.06, Spread = 0.6 })
eff("DepthOfFieldEffect", "EvaKDoF", { FarIntensity = 0.16, FocusDistance = 40, InFocusRadius = 40, NearIntensity = 0 })
eff("Atmosphere", "EvaKAtmo", { Density = 0.32, Offset = 0.1, Color = Color3.fromRGB(130, 80, 60), Decay = Color3.fromRGB(80, 40, 30), Glare = 0, Haze = 1.4 })

-- все лампы получают тени, а ближние к игроку - полную яркость; дальние отключаются ради FPS
local lights = {}
local function track(l)
	if l:IsA("PointLight") or l:IsA("SpotLight") then
		set(l, "Shadows", true)
		lights[l] = true
	end
end
for _, d in workspace:GetDescendants() do track(d) end
workspace.DescendantAdded:Connect(track)
workspace.DescendantRemoving:Connect(function(d) lights[d] = nil end)

local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 0.5 then return end
	acc = 0
	local cam = workspace.CurrentCamera
	if not cam then return end
	local p = cam.CFrame.Position
	for l in lights do
		local par = l.Parent
		if par and par:IsA("BasePart") then
			local near = (par.Position - p).Magnitude < 90
			set(l, "Enabled", near)
		end
	end
end)

-- РЕЖИМ ДЛЯ СЛАБЫХ УСТРОЙСТВ (переключатель в SETTINGS -> LOW-END MODE)
local function applyLow()
	local low = player:GetAttribute("EvaKLowEnd") == true
	set(Lighting, "GlobalShadows", not low)
	for _, n in { "EvaKBloom", "EvaKDoF", "EvaKRays", "EvaKAtmo" } do
		local e = Lighting:FindFirstChild(n)
		if e then set(e, "Enabled", not low) end
	end
	for l in lights do set(l, "Shadows", not low) end
	pcall(function() settings().Rendering.QualityLevel = low and Enum.QualityLevel.Level03 or Enum.QualityLevel.Level21 end)
end
player:GetAttributeChangedSignal("EvaKLowEnd"):Connect(applyLow)
