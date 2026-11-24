-- ============================================================
--  EvaKPasses (LocalScript в StarterPlayerScripts)
--  Кнопки геймпассов "x2 SPEED" и "x2 BADGES" в меню (ID задаются в EvaKServer: CONFIG.Passes).
-- ============================================================
-- кнопки x2 теперь живут во вкладках магазина (GraceIntro); этот скрипт больше не нужен
if true then return end
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui"); gui.Name = "EvaKPassesGui"; gui.ResetOnSpawn = false; gui.DisplayOrder = 121; gui.Parent = playerGui
local function mk(label: string, y: number, attr: string, idAttr: string)
	local b = Instance.new("TextButton")
	b.AnchorPoint = Vector2.new(0, 1); b.Position = UDim2.new(0, 24, 1, y); b.Size = UDim2.fromOffset(200, 40)
	b.BackgroundColor3 = Color3.fromRGB(70, 40, 12); b.Font = Enum.Font.Arcade; b.TextSize = 16; b.TextColor3 = Color3.fromRGB(255, 225, 150); b.Visible = false; b.Parent = gui
	local st = Instance.new("UIStroke"); st.Color = Color3.fromRGB(235, 190, 80); st.Thickness = 2; st.Parent = b
	local function refresh()
		local id = workspace:GetAttribute(idAttr) or 0
		local owned = player:GetAttribute(attr) == true
		local m = playerGui:FindFirstChild("IntroMenu")
		b.Visible = m ~= nil and (m :: ScreenGui).Enabled and player:GetAttribute("EvaKInRun") ~= true
		b.Text = owned and (label .. "  OWNED") or (id > 0 and label or (label .. " (SET ID)"))
		b.BackgroundColor3 = owned and Color3.fromRGB(30, 70, 34) or Color3.fromRGB(70, 40, 12)
	end
	b.MouseButton1Click:Connect(function()
		local id = workspace:GetAttribute(idAttr) or 0
		if id > 0 and player:GetAttribute(attr) ~= true then pcall(function() MarketplaceService:PromptGamePassPurchase(player, id) end) end
	end)
	task.spawn(function() while true do refresh(); task.wait(0.5) end end)
end
mk("x2 SPEED", -66, "PassSpeed2", "PassSpeed2Id")
mk("x2 BADGES", -112, "PassBadge2", "PassBadge2Id")
