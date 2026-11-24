-- ============================================================
--  EvaKLobbyLight (LocalScript в StarterPlayerScripts)
--  В лобби чёрный персонаж был не виден: подсвечиваем его тёплым светом спереди и холодным контровым сзади.
--  В катке (InMap) подсветка выключается.
-- ============================================================
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local function build(char: Model)
	local root = char:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	if not root then return end
	local function mkLight(name: string, offset: Vector3, color: Color3, bright: number, range: number)
		local old = root:FindFirstChild(name)
		if old then old:Destroy() end
		local at = Instance.new("Attachment"); at.Name = name; at.Position = offset; at.Parent = root
		local l = Instance.new("PointLight"); l.Color = color; l.Brightness = bright; l.Range = range; l.Shadows = false; l.Parent = at
		return at
	end
	local front = mkLight("EvaKLobbyFront", Vector3.new(0, 1.5, -6), Color3.fromRGB(255, 205, 150), 2.2, 18)
	local rim = mkLight("EvaKLobbyRim", Vector3.new(0, 4, 6), Color3.fromRGB(150, 175, 255), 1.4, 16)
	local function refresh()
		local on = player:GetAttribute("InMap") ~= true
		for _, a in { front, rim } do
			local l = a:FindFirstChildOfClass("PointLight")
			if l then l.Enabled = on end
		end
	end
	player:GetAttributeChangedSignal("InMap"):Connect(refresh)
	refresh()
end

player.CharacterAdded:Connect(build)
if player.Character then task.spawn(build, player.Character) end
