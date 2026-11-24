-- EvaKTaco (LocalScript в StarterPlayerScripts): ТАКО-ивент - с неба падают смайлики тако + музыка
-- Включается админ-панелью (кнопка "ТАКО: падают с неба") через атрибут workspace.EvaKTaco
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local MUSIC_ID = "rbxassetid://142376088"
local rng = Random.new()

local gui = Instance.new("ScreenGui")
gui.Name = "EvaKTaco"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 110
gui.Parent = playerGui

local snd = Instance.new("Sound")
snd.Name = "EvaKTacoMusic"; snd.SoundId = MUSIC_ID; snd.Looped = true; snd.Volume = 0.22
snd.Parent = gui

local running = false
local function spawnTaco()
	local size = rng:NextInteger(22, 40)
	local x = (rng:NextNumber() < 0.5) and rng:NextNumber(0.01, 0.1) or rng:NextNumber(0.9, 0.99)   -- только по краям экрана
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = "🌮"
	l.TextSize = size
	l.Size = UDim2.fromOffset(size + 10, size + 10)
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Position = UDim2.fromScale(x, -0.08)
	l.Rotation = rng:NextNumber(-40, 40)
	l.TextTransparency = 0.35
	l.ZIndex = 1
	l.Parent = gui
	local dur = rng:NextNumber(6, 9)
	local tw = TweenService:Create(l, TweenInfo.new(dur, Enum.EasingStyle.Linear), {
		Position = UDim2.fromScale(math.clamp(x + rng:NextNumber(-0.03, 0.03), 0, 1), 1.1),
		Rotation = l.Rotation + rng:NextNumber(-360, 360),
	})
	tw:Play()
	tw.Completed:Once(function() l:Destroy() end)
end

local function setRunning(on: boolean)
	if on == running then return end
	running = on
	if on then
		snd:Play()
		task.spawn(function()
			while running do
				spawnTaco()
				task.wait(rng:NextNumber(0.7, 1.5))
			end
		end)
	else
		snd:Stop()
	end
end

workspace:GetAttributeChangedSignal("EvaKTaco"):Connect(function()
	setRunning(workspace:GetAttribute("EvaKTaco") == true)
end)
setRunning(workspace:GetAttribute("EvaKTaco") == true)
