-- ============================================================
--  EvaK NEW YEAR  (LocalScript)  -  StarterPlayer > StarterPlayerScripts
--  Снег и снежинки вокруг камеры + мигающие огоньки гирлянд, пока идёт новогодний ивент.
-- ============================================================
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local camera = workspace.CurrentCamera
local snowPart: Part? = nil
local conn: RBXScriptConnection? = nil

local function makeSnow()
	if snowPart then return end
	local p = Instance.new("Part")
	p.Name = "EvaKSnow"; p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	p.Transparency = 1; p.Size = Vector3.new(80, 1, 80)
	p.Parent = workspace
	local function emitter(rate: number, size0: number, size1: number, life: number, speed: number)
		local e = Instance.new("ParticleEmitter")
		e.Rate = rate; e.Lifetime = NumberRange.new(life, life + 2); e.Speed = NumberRange.new(speed, speed + 2)
		e.EmissionDirection = Enum.NormalId.Bottom; e.SpreadAngle = Vector2.new(20, 20)
		e.Shape = Enum.ParticleEmitterShape.Box; e.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size0), NumberSequenceKeypoint.new(1, size1) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.1, 0.1), NumberSequenceKeypoint.new(0.85, 0.2), NumberSequenceKeypoint.new(1, 1) })
		e.Color = ColorSequence.new(Color3.fromRGB(245, 250, 255))
		e.LightEmission = 0.5; e.LightInfluence = 0.15
		e.Acceleration = Vector3.new(1.6, -0.6, 0.9)
		e.RotSpeed = NumberRange.new(-90, 90); e.Rotation = NumberRange.new(0, 360)
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Parent = p
	end
	emitter(180, 0.28, 0.4, 4.5, 4)    -- мелкий снег
	emitter(26, 0.9, 1.2, 4.5, 3)      -- крупные снежинки
	snowPart = p
	conn = RunService.RenderStepped:Connect(function()
		if snowPart then
			snowPart.CFrame = CFrame.new(camera.CFrame.Position + Vector3.new(0, 16, 0))
		end
	end)
end

local function stopSnow()
	if conn then conn:Disconnect(); conn = nil end
	if snowPart then snowPart:Destroy(); snowPart = nil end
	for _, b in CollectionService:GetTagged("XmasBulb") do
		if b:IsA("BasePart") then b.Transparency = 0 end
	end
end

local Players = game:GetService("Players")
local me = Players.LocalPlayer
local function refresh()
	if me:GetAttribute("EvaKTheme") == "classic" then stopSnow() elseif workspace:GetAttribute("EvaKNewYear") == true or me:GetAttribute("Difficulty") == "newyear" then makeSnow() else stopSnow() end
end
workspace:GetAttributeChangedSignal("EvaKNewYear"):Connect(refresh)
me:GetAttributeChangedSignal("Difficulty"):Connect(refresh)
me:GetAttributeChangedSignal("EvaKTheme"):Connect(refresh)
refresh()

-- мигающие огоньки (по близости к камере)
local tick = 0
task.spawn(function()
	while true do
		task.wait(0.5)
		if snowPart then
			tick += 1
			local cp = camera.CFrame.Position
			for _, b in CollectionService:GetTagged("XmasBulb") do
				if b:IsA("BasePart") and (b.Position - cp).Magnitude < 150 then
					local ph = b:GetAttribute("Phase") or 0
					b.Transparency = ((tick + ph) % 3 == 0) and 0.65 or 0
				end
			end
		end
	end
end)
