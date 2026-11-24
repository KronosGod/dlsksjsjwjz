-- ============================================================
--  EvaKLike (LocalScript в StarterPlayerScripts)
--  Кнопка «LIKE = 49 BADGES» в меню. Разовая награда (Roblox не позволяет проверить лайк скриптом).
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local shop = ReplicatedStorage:WaitForChild("EvaKShop", 30)
if not shop then return end

local gui = Instance.new("ScreenGui"); gui.Name = "EvaKLikeGui"; gui.ResetOnSpawn = false; gui.DisplayOrder = 122; gui.Parent = playerGui
local b = Instance.new("TextButton")
b.AnchorPoint = Vector2.new(0, 1); b.Position = UDim2.new(0, 16, 1, -16); b.Size = UDim2.fromOffset(250, 44)
b.BackgroundColor3 = Color3.fromRGB(30, 70, 34); b.Text = "LIKE THE GAME = 49 BADGES"; b.Font = Enum.Font.Arcade; b.TextSize = 15
b.TextColor3 = Color3.fromRGB(235, 225, 190); b.Visible = false; b.Parent = gui
local st = Instance.new("UIStroke"); st.Color = Color3.fromRGB(120, 220, 130); st.Thickness = 2; st.Parent = b
local claimed = false

b.MouseButton1Click:Connect(function()
	if claimed then return end
	b.Text = "..."
	local ok, r = pcall(function() return shop:InvokeServer("LikeReward") end)
	if ok and type(r) == "table" and r.ok then
		claimed = true; b.Text = "+49 BADGES! THANK YOU"
		task.delay(2.5, function() b.Visible = false end)
	elseif ok and type(r) == "table" and r.msg == "already claimed" then
		claimed = true; b.Visible = false
	else
		b.Text = "ERROR, TRY AGAIN"
		task.delay(2, function() if not claimed then b.Text = "LIKE THE GAME = 49 BADGES" end end)
	end
end)

task.spawn(function()
	while true do
		local m = playerGui:FindFirstChild("IntroMenu")
		b.Visible = not claimed and m ~= nil and (m :: ScreenGui).Enabled and player:GetAttribute("EvaKInRun") ~= true
		task.wait(0.4)
	end
end)
