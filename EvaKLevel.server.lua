-- ============================================================
--  EvaK LEVEL  (Script)  — отдельная кирпичная карта
--  Куда положить: ServerScriptService > Script
--  Строит кирпичный коридор с лампами и препятствиями в Workspace.EvaKLevel.
--  Проверка: напиши в чат  /map  — тебя перенесёт в карту,  /back — вернёт.
--  (Это отдельный файл: он не зависит от меню и от EvaKMap.)
-- ============================================================
local O = Vector3.new(0, 0, 3000)         -- далеко от лобби по Z
local W, H, L = 18, 14, 400

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local rng = Random.new(7)

local folder = Instance.new("Model")
folder.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
folder.Name = "EvaKLevel"
folder.Parent = workspace

local function part(name, size, pos, color, mat)
	local p = Instance.new("Part")
	p.Name = name; p.Size = size; p.Position = O + pos
	p.Anchored = true; p.Color = color; p.Material = mat or Enum.Material.Concrete
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = folder
	return p
end

local BRICK = Color3.fromRGB(160, 80, 58)
local DARK = Color3.fromRGB(50, 42, 38)

-- пол, стены (кирпич), потолок, торцы
part("Floor", Vector3.new(W, 1, L), Vector3.new(0, -0.5, L / 2), Color3.fromRGB(85, 76, 68), Enum.Material.Slate)
part("WallL", Vector3.new(1, H, L), Vector3.new(-W / 2 - 0.5, H / 2, L / 2), BRICK, Enum.Material.Brick)
part("WallR", Vector3.new(1, H, L), Vector3.new(W / 2 + 0.5, H / 2, L / 2), BRICK, Enum.Material.Brick)
part("Ceiling", Vector3.new(W + 2, 1, L), Vector3.new(0, H + 0.5, L / 2), Color3.fromRGB(70, 62, 58))
part("Back", Vector3.new(W + 2, H + 2, 1), Vector3.new(0, H / 2, -0.5), BRICK, Enum.Material.Brick)
part("End", Vector3.new(W + 2, H + 2, 1), Vector3.new(0, H / 2, L + 0.5), BRICK, Enum.Material.Brick)

-- кирпичные колонны вдоль стен
for z = 8, L - 8, 16 do
	for _, sx in { -1, 1 } do
		part("Rib", Vector3.new(1.2, H, 2), Vector3.new(sx * (W / 2 - 0.6), H / 2, z), Color3.fromRGB(120, 62, 46), Enum.Material.Brick)
	end
end

-- лампы
local lamps = {}
for z = 6, L - 6, 16 do
	part("Housing", Vector3.new(6, 0.6, 2.4), Vector3.new(0, H - 0.3, z), Color3.fromRGB(30, 28, 28), Enum.Material.Metal)
	local lamp = part("Lamp", Vector3.new(5.2, 0.3, 1.8), Vector3.new(0, H - 0.75, z), Color3.fromRGB(255, 214, 150), Enum.Material.Neon)
	local pl = Instance.new("PointLight")
	pl.Range = 36; pl.Brightness = 2.2; pl.Color = Color3.fromRGB(255, 200, 130); pl.Parent = lamp
	table.insert(lamps, { part = lamp, light = pl, seed = rng:NextNumber(0, 100), bad = rng:NextNumber() < 0.15 })
end
RunService.Heartbeat:Connect(function()
	local t = os.clock()
	for _, l in lamps do
		local f = l.bad and ((math.noise(t * 7, l.seed) > 0.25) and 0.15 or 1) or (0.9 + 0.1 * math.noise(t * 2, l.seed))
		l.light.Brightness = 2.2 * f
		l.part.Transparency = 0.5 * (1 - f)
	end
end)

-- препятствия
local function barrier(z)
	part("Barrier", Vector3.new(W, 3.2, 2), Vector3.new(0, 1.6, z), Color3.fromRGB(60, 52, 46), Enum.Material.Metal)
	part("Stripe", Vector3.new(W, 0.4, 0.1), Vector3.new(0, 2.5, z - 1.05), Color3.fromRGB(255, 190, 40), Enum.Material.Neon)
end
local function pillars(z)
	for _, x in { -6, 0, 6 } do part("Pillar", Vector3.new(3, H, 3), Vector3.new(x, H / 2, z), Color3.fromRGB(110, 60, 46), Enum.Material.Brick) end
end
local function vent(z)
	part("Vent", Vector3.new(W, H - 4.6, 14), Vector3.new(0, 4.6 + (H - 4.6) / 2, z), Color3.fromRGB(40, 38, 38), Enum.Material.Metal)
end
local function crates(z)
	for _ = 1, 3 do
		local c = part("Crate", Vector3.new(4, 4, 4), Vector3.new(rng:NextNumber(-6, 6), 2, z + rng:NextNumber(-6, 6)), Color3.fromRGB(110, 78, 46), Enum.Material.Wood)
		c.CFrame = c.CFrame * CFrame.Angles(0, rng:NextNumber(0, 1.5), 0)
	end
end
local kinds = { barrier, pillars, vent, crates, barrier }
local z = 50
while z < L - 30 do
	kinds[rng:NextInteger(1, #kinds)](z)
	z += 40 + rng:NextInteger(0, 12)
end

-- тест: /map и /back
local function go(plr, pos)
	local char = plr.Character
	if char then char:PivotTo(CFrame.new(pos)) end
end
Players.PlayerAdded:Connect(function(plr)
	plr.Chatted:Connect(function(msg)
		msg = string.lower(msg)
		if msg == "/map" then go(plr, O + Vector3.new(0, 4, 10))
		elseif msg == "/back" then
			local spawn = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
			go(plr, spawn and spawn.Position + Vector3.new(0, 5, 0) or Vector3.new(0, 10, 0))
		end
	end)
end)
print("[EvaKLevel] карта построена в Workspace.EvaKLevel, координаты:", O)
