-- ============================================================
--  EvaKLight  (LocalScript в StarterPlayerScripts)
--  Свет, тени и воздух: тёмный «профиль забега» с плавным переходом из лобби, мягкий тёплый свет
--  вокруг игрока (даёт читаемые градиенты и резкие тени в коридорах), ореолы у ламп,
--  густота тумана растёт с напряжением. Ничего не трогает в LOW-END режиме.
--  Работает вместе с EvaKGraphics / EvaKCinema / EvaKAtmosphere. Lighting.Technology = Future ставь вручную.
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local cam = workspace.CurrentCamera

local function set(o, p, v) pcall(function() o[p] = v end) end
local function low() return player:GetAttribute("EvaKLowEnd") == true end
local function inRun() return player:GetAttribute("IntroDone") == true end

-- ---------- профиль забега ----------
local LOBBY = {
	Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient, Brightness = Lighting.Brightness,
	ColorShift_Top = Lighting.ColorShift_Top, ShadowSoftness = Lighting.ShadowSoftness,
	EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale, EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
}
local RUN = {
	Ambient = Color3.fromRGB(32, 23, 20), OutdoorAmbient = Color3.fromRGB(34, 25, 21), Brightness = 0.7,
	ColorShift_Top = Color3.fromRGB(60, 28, 20), ShadowSoftness = 0.18,
	EnvironmentDiffuseScale = 0.55, EnvironmentSpecularScale = 1,
}
local mix = 0   -- 0 лобби .. 1 забег
local function lerpC(a: Color3, b: Color3, k: number) return a:Lerp(b, k) end
local function applyMix()
	for k, v in RUN do
		local a = LOBBY[k]
		if typeof(v) == "Color3" then set(Lighting, k, lerpC(a, v, mix))
		else set(Lighting, k, a + (v - a) * mix) end
	end
end

-- ---------- свет у игрока ----------
local lightPart = Instance.new("Part")
lightPart.Name = "EvaKCamLight"; lightPart.Anchored = true; lightPart.CanCollide = false; lightPart.CanQuery = false; lightPart.CanTouch = false
lightPart.Transparency = 1; lightPart.Size = Vector3.one * 0.2; lightPart.Parent = workspace
local camLight = Instance.new("PointLight")
camLight.Color = Color3.fromRGB(255, 190, 140); camLight.Range = 16; camLight.Brightness = 0.85; camLight.Shadows = true; camLight.Enabled = false
camLight.Parent = lightPart

-- ---------- ореолы у ламп ----------
local halos: {[Instance]: ParticleEmitter} = {}
local function addHalo(l: Instance)
	if halos[l] or not (l:IsA("PointLight") or l:IsA("SpotLight")) then return end
	local par = l.Parent
	if not par or not par:IsA("BasePart") or l.Brightness < 0.4 then return end
	if par:FindFirstAncestorWhichIsA("Model") and Players:GetPlayerFromCharacter(par:FindFirstAncestorWhichIsA("Model")) then return end
	local em = Instance.new("ParticleEmitter")
	em.Name = "EvaKHalo"
	em.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	em.Rate = 0; em.Lifetime = NumberRange.new(60, 60); em.Speed = NumberRange.new(0, 0)
	em.Size = NumberSequence.new(math.clamp(l.Range * 0.45, 3, 9)); em.LightEmission = 1; em.LightInfluence = 0
	em.Transparency = NumberSequence.new(0.86)
	em.Color = ColorSequence.new(l.Color)
	em.Orientation = Enum.ParticleOrientation.FacingCamera
	em.Parent = par
	em:Emit(1)
	halos[l] = em
end
local function dropHalo(l: Instance)
	local h = halos[l]
	if h then h:Destroy(); halos[l] = nil end
end
task.spawn(function()
	while true do
		task.wait(2.5)
		if cam and inRun() and not low() then
			local p = cam.CFrame.Position
			local n = 0
			for _, d in workspace:GetDescendants() do
				if (d:IsA("PointLight") or d:IsA("SpotLight")) and d.Parent and d.Parent:IsA("BasePart") then
					local dist = (d.Parent.Position - p).Magnitude
					if dist < 55 then
						if not halos[d] then addHalo(d) end
						n += 1
						if n % 150 == 0 then task.wait() end
					elseif halos[d] and dist > 90 then dropHalo(d) end
				end
			end
		else
			for l in halos do dropHalo(l) end
		end
	end
end)

-- ---------- туман ----------
local atmo = Lighting:FindFirstChild("EvaKAtmo") or Lighting:FindFirstChildOfClass("Atmosphere")
local baseDensity = atmo and atmo.Density or 0.3
local baseColor = atmo and atmo.Color or Color3.fromRGB(130, 80, 60)

RunService.RenderStepped:Connect(function(dt)
	local target = (inRun() and not low()) and 1 or 0
	mix += (target - mix) * math.min(1, dt * 1.6)
	if math.abs(mix - target) < 0.002 then mix = target end
	local ev = workspace:GetAttribute("EvaKEvent")
	local evOn = ev ~= nil and ev ~= "" and ev ~= "none"
	if (mix > 0 or target > 0) and not evOn then applyMix() end   -- во время ивента свет ведёт EvaKExtra

	cam = workspace.CurrentCamera
	if cam then
		lightPart.CFrame = cam.CFrame * CFrame.new(0, 0.3, -1.2)
	end
	local running = inRun() and not low()
	camLight.Enabled = running
	if running then
		local hp = player:GetAttribute("EvaKHpNow") or 100
		local fear = player:GetAttribute("EvaKFear") or 0
		camLight.Brightness = (0.85 - fear * 0.25) * (0.6 + 0.4 * math.clamp(hp / 100, 0, 1))
		camLight.Range = 16 - fear * 5
	end
	if atmo then
		local fear = player:GetAttribute("EvaKFear") or 0
		local d = running and (baseDensity + 0.2 + fear * 0.22) or baseDensity
		local ev = workspace:GetAttribute("EvaKEvent")
		local evs = "=" .. tostring(workspace:GetAttribute("EvaKEvents") or ""):gsub(";", ";=")
		local red = evs:find("=BloodMoon", 1, true) or evs:find("=Apocalypse", 1, true) or evs:find("=TheEnd", 1, true) or evs:find("=Judgment", 1, true)
		if red then d = 0.55 end
		atmo.Density += (d - atmo.Density) * math.min(1, dt * 1.2)
		atmo.Color = atmo.Color:Lerp(red and Color3.fromRGB(150, 10, 10) or (running and Color3.fromRGB(70, 36, 28) or baseColor), math.min(1, dt * 1.2))
	end
end)
