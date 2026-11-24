-- ============================================================
--  EvaKSkins  (ModuleScript)  -  ReplicatedStorage > ModuleScript, имя: EvaKSkins
--  Новогодние скины-шапки за снежинки. Общий для меню (силуэт), магазина и сервера (надеваются на персонажа).
--  Все размеры даны для головы ~1.25 стад., лицо смотрит в -Z, верх головы ~ +0.62.
-- ============================================================
local M = {}

local function C(r, g, b) return Color3.fromRGB(r, g, b) end

M.List = {
	{ Id = "SANTAHAT", Name = "SANTA HAT",     Cost = 50 },
	{ Id = "ELFHAT",   Name = "ELF HAT",       Cost = 80 },
	{ Id = "ANTLERS",  Name = "REINDEER",      Cost = 120 },
	{ Id = "SCARF",    Name = "WINTER SCARF",  Cost = 150 },
	{ Id = "SNOWMAN",  Name = "SNOWMAN",       Cost = 220 },
	{ Id = "CROWN",    Name = "FROST CROWN",   Cost = 400 },
}

function M.find(id: string)
	for _, s in M.List do if s.Id == id then return s end end
	return nil
end

-- спецификации деталей: { shape = "block"|"ball"|"cyl", size, cf (относительно центра головы), color, mat, neon }
function M.specs(id: string, tint: Color3?)
	local P = {}
	local function add(shape: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?)
		table.insert(P, { shape = shape, size = size, cf = cf, color = color, mat = mat or Enum.Material.SmoothPlastic })
	end
	local function cyl(h: number, d: number, x: number, y: number, z: number, color: Color3, mat: Enum.Material?, rx: number?, rz: number?)
		add("cyl", Vector3.new(h, d, d), CFrame.new(x, y, z) * CFrame.Angles(rx or 0, 0, math.pi / 2 + (rz or 0)), color, mat)
	end
	local red, white = C(200, 28, 34), C(248, 248, 252)
	if id == "SANTAHAT" then
		cyl(0.3, 1.55, 0, 0.55, 0, white, Enum.Material.Fabric)
		cyl(0.45, 1.3, 0, 0.82, 0.02, red, Enum.Material.Fabric)
		cyl(0.4, 1.0, 0, 1.15, 0.1, red, Enum.Material.Fabric, 0.25)
		cyl(0.4, 0.7, 0, 1.45, 0.3, red, Enum.Material.Fabric, 0.5)
		add("ball", Vector3.new(0.42, 0.42, 0.42), CFrame.new(0, 1.55, 0.6), white, Enum.Material.Fabric)
	elseif id == "ELFHAT" then
		local g = C(36, 150, 70)
		cyl(0.28, 1.4, 0, 0.55, 0, red, Enum.Material.Fabric)
		cyl(0.5, 1.2, 0, 0.85, 0, g, Enum.Material.Fabric)
		cyl(0.45, 0.85, 0, 1.25, 0.05, g, Enum.Material.Fabric, 0.15)
		cyl(0.4, 0.5, 0, 1.62, 0.2, g, Enum.Material.Fabric, 0.35)
		add("ball", Vector3.new(0.3, 0.3, 0.3), CFrame.new(0, 1.85, 0.42), C(255, 215, 80), Enum.Material.Metal)
		add("block", Vector3.new(0.12, 0.5, 0.12), CFrame.new(-0.72, 0.15, 0.1) * CFrame.Angles(0, 0, 0.9), C(60, 170, 90))
		add("block", Vector3.new(0.12, 0.5, 0.12), CFrame.new(0.72, 0.15, 0.1) * CFrame.Angles(0, 0, -0.9), C(60, 170, 90))
	elseif id == "ANTLERS" then
		local br = C(110, 72, 40)
		for _, sx in { -1, 1 } do
			add("block", Vector3.new(0.13, 1.0, 0.13), CFrame.new(sx * 0.42, 0.95, 0) * CFrame.Angles(0, 0, -sx * 0.35), br, Enum.Material.Wood)
			add("block", Vector3.new(0.11, 0.6, 0.11), CFrame.new(sx * 0.62, 1.1, 0) * CFrame.Angles(0, 0, -sx * 1.0), br, Enum.Material.Wood)
			add("block", Vector3.new(0.11, 0.5, 0.11), CFrame.new(sx * 0.72, 1.45, 0.05) * CFrame.Angles(0, 0, sx * 0.1), br, Enum.Material.Wood)
			add("block", Vector3.new(0.11, 0.4, 0.11), CFrame.new(sx * 0.52, 1.3, 0) * CFrame.Angles(0, 0, sx * 0.6), br, Enum.Material.Wood)
		end
		add("ball", Vector3.new(0.34, 0.34, 0.34), CFrame.new(0, -0.1, -0.66), C(255, 40, 40), Enum.Material.Neon)
	elseif id == "SCARF" then
		cyl(0.4, 1.55, 0, -0.78, 0, red, Enum.Material.Fabric)
		cyl(0.12, 1.6, 0, -0.68, 0, white, Enum.Material.Fabric)
		cyl(0.12, 1.6, 0, -0.9, 0, white, Enum.Material.Fabric)
		add("block", Vector3.new(0.34, 1.0, 0.14), CFrame.new(0.45, -1.35, -0.7) * CFrame.Angles(0.1, 0, 0.1), red, Enum.Material.Fabric)
		add("block", Vector3.new(0.34, 0.14, 0.15), CFrame.new(0.45, -1.7, -0.7), white, Enum.Material.Fabric)
	elseif id == "SNOWMAN" then
		local black = C(22, 20, 22)
		cyl(0.14, 1.6, 0, 0.58, 0, black)
		cyl(0.9, 1.0, 0, 1.08, 0, black)
		cyl(0.2, 1.02, 0, 0.82, 0, red)
		add("block", Vector3.new(0.16, 0.16, 0.7), CFrame.new(0, -0.05, -0.85), C(250, 130, 30))
		add("ball", Vector3.new(0.14, 0.14, 0.1), CFrame.new(-0.28, 0.2, -0.64), C(10, 10, 10))
		add("ball", Vector3.new(0.14, 0.14, 0.1), CFrame.new(0.28, 0.2, -0.64), C(10, 10, 10))
		for k = 0, 3 do add("ball", Vector3.new(0.1, 0.1, 0.08), CFrame.new((k - 1.5) * 0.18, -0.35 + math.abs(k - 1.5) * -0.07, -0.64), C(10, 10, 10)) end
	elseif id == "CROWN" then
		local ice = C(140, 230, 255)
		cyl(0.25, 1.4, 0, 0.62, 0, C(200, 240, 255), Enum.Material.Glass)
		for k = 0, 7 do
			local a = k / 8 * math.pi * 2
			local h = (k % 2 == 0) and 0.8 or 0.5
			add("block", Vector3.new(0.16, h, 0.16), CFrame.new(math.cos(a) * 0.6, 0.62 + h / 2, math.sin(a) * 0.6) * CFrame.Angles(math.sin(a) * 0.2, 0, -math.cos(a) * 0.2), ice, Enum.Material.Neon)
		end
		add("ball", Vector3.new(0.3, 0.3, 0.3), CFrame.new(0, 1.0, 0), C(255, 255, 255), Enum.Material.Neon)
	end
	if tint then   -- смена цвета: насыщенные цвета меняют оттенок, белое/чёрное остаётся
		local th = tint:ToHSV()
		for _, p in P do
			local h, sat, v = p.color:ToHSV()
			if sat > 0.12 and v > 0.12 then p.color = Color3.fromHSV(th, math.max(sat, 0.55), v) end
		end
	end
	return P
end

M.Palette = {   -- цвета для выбора
	{ 200, 28, 34 }, { 255, 130, 30 }, { 255, 205, 40 }, { 60, 190, 80 }, { 40, 190, 200 },
	{ 50, 110, 230 }, { 150, 70, 220 }, { 240, 80, 170 },
}
function M.parseColor(str: any): Color3?
	if type(str) ~= "string" then return nil end
	local r, g, b = string.match(str, "^(%d+),(%d+),(%d+)$")
	if not r then return nil end
	if tonumber(r) == 0 and tonumber(g) == 0 and tonumber(b) == 0 then return nil end
	return Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
end

local function makePart(spec, parent: Instance): Part
	local p = Instance.new("Part")
	p.Name = "EvaKSkinPart"
	p.Size = spec.size
	p.Color = spec.color; p.Material = spec.mat
	p.CanCollide = false; p.CanTouch = false; p.CanQuery = false; p.CastShadow = false; p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	if spec.shape == "ball" then
		local m = Instance.new("SpecialMesh"); m.MeshType = Enum.MeshType.Sphere; m.Parent = p
	elseif spec.shape == "cyl" then
		p.Shape = Enum.PartType.Cylinder
	end
	p.Parent = parent
	return p
end

-- на живого персонажа (сервер): детали привариваются к Head
function M.attach(parent: Instance, id: string, head: BasePart, tint: Color3?): Model
	local m = Instance.new("Model")
	m.Name = "EvaKSkin"
	local k = head.Size.Y / 1.2   -- подгонка под размер головы персонажа
	for _, spec in M.specs(id, tint) do
		local s2 = { shape = spec.shape, size = spec.size * k, color = spec.color, mat = spec.mat }
		local p = makePart(s2, m)
		p.CFrame = head.CFrame * (CFrame.new(spec.cf.Position * k) * spec.cf.Rotation)
		local w = Instance.new("Weld")
		w.Part0 = head; w.Part1 = p
		w.C0 = head.CFrame:ToObjectSpace(p.CFrame)
		w.Parent = p
	end
	m.Parent = parent
	return m
end

-- в меню (клиент): якорные детали, positions = pivot * spec.cf. Возвращает {parts, update(headCF)}
function M.build(parent: Instance, id: string, scale: number?, tint: Color3?)
	local sc = scale or 1
	local list = {}
	for _, spec in M.specs(id, tint) do
		local p = makePart({ shape = spec.shape, size = spec.size * sc, color = spec.color, mat = spec.mat }, parent)
		p.Anchored = true
		table.insert(list, { part = p, cf = spec.cf })
	end
	return {
		parts = list,
		update = function(headCF: CFrame)
			for _, r in list do
				r.part.CFrame = headCF * (CFrame.new(r.cf.Position * sc) * r.cf.Rotation)
			end
		end,
		destroy = function()
			for _, r in list do r.part:Destroy() end
			table.clear(list)
		end,
	}
end

return M
