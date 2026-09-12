--[[
	ABA HUB-style menu (UI only)
	Place this LocalScript in StarterPlayer > StarterPlayerScripts.
	RightShift toggles the window. All controls update the Settings table only.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local oldGui = playerGui:FindFirstChild("ABAHubMenu")
if oldGui then oldGui:Destroy() end

local Settings = {
	PingCompensation = 100,
	MaxAnimationLength = 850,
	GuardBreakGuard = true,
	SkipAboveGuard = 70,
	FaceCheck = false,
	WalkSpeedPreview = 16,
	ShowNames = false,
	AutoFarmPreview = false,
	Notifications = true,
}

local Theme = {
	background = Color3.fromRGB(9, 10, 13),
	sidebar = Color3.fromRGB(12, 13, 17),
	panel = Color3.fromRGB(18, 19, 24),
	panelHover = Color3.fromRGB(25, 26, 32),
	border = Color3.fromRGB(42, 44, 52),
	text = Color3.fromRGB(241, 242, 246),
	muted = Color3.fromRGB(139, 143, 157),
	accent = Color3.fromRGB(244, 48, 62),
	accentDark = Color3.fromRGB(103, 24, 32),
	track = Color3.fromRGB(47, 49, 58),
}

local function make(className, properties, parent)
	local object = Instance.new(className)
	for property, value in pairs(properties or {}) do object[property] = value end
	object.Parent = parent
	return object
end

local function round(parent, radius)
	return make("UICorner", {CornerRadius = UDim.new(0, radius or 8)}, parent)
end

local function outline(parent, color)
	return make("UIStroke", {Color = color or Theme.border, Thickness = 1}, parent)
end

local function animate(object, goal, duration)
	TweenService:Create(object, TweenInfo.new(duration or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()
end

local gui = make("ScreenGui", {
	Name = "ABAHubMenu",
	ResetOnSpawn = false,
	IgnoreGuiInset = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local main = make("Frame", {
	Name = "Window",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(900, 540),
	BackgroundColor3 = Theme.background,
	BorderSizePixel = 0,
	ClipsDescendants = true,
}, gui)
round(main, 13); outline(main)
make("UISizeConstraint", {MinSize = Vector2.new(650, 400), MaxSize = Vector2.new(900, 540)}, main)

local top = make("Frame", {
	Name = "TopBar", Size = UDim2.new(1, 0, 0, 76),
	BackgroundColor3 = Theme.background, BorderSizePixel = 0,
}, main)
make("Frame", {Position = UDim2.new(0, 16, 1, -1), Size = UDim2.new(1, -32, 0, 1), BackgroundColor3 = Theme.border, BorderSizePixel = 0}, top)

local title = make("TextLabel", {
	Position = UDim2.fromOffset(24, 13), Size = UDim2.fromOffset(260, 34),
	BackgroundTransparency = 1, Text = "ABA HUB", RichText = true,
	TextColor3 = Theme.text, TextSize = 27, Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
}, top)
title.Text = '<font color="rgb(244,48,62)">ABA</font> HUB'
make("TextLabel", {
	Position = UDim2.fromOffset(25, 44), Size = UDim2.fromOffset(250, 20),
	BackgroundTransparency = 1, Text = "Anime Battle Arena", TextColor3 = Theme.muted,
	TextSize = 13, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left,
}, top)

local close = make("TextButton", {
	Position = UDim2.new(1, -57, 0, 16), Size = UDim2.fromOffset(40, 40),
	BackgroundColor3 = Theme.panel, BorderSizePixel = 0, Text = "×",
	TextColor3 = Theme.muted, TextSize = 27, Font = Enum.Font.GothamMedium, AutoButtonColor = false,
}, top)
round(close, 9); outline(close)
close.MouseEnter:Connect(function() animate(close, {BackgroundColor3 = Theme.panelHover, TextColor3 = Theme.text}) end)
close.MouseLeave:Connect(function() animate(close, {BackgroundColor3 = Theme.panel, TextColor3 = Theme.muted}) end)
close.Activated:Connect(function() main.Visible = false end)

-- Drag with mouse or touch.
local dragging, dragOrigin, windowOrigin = false, nil, nil
top.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging, dragOrigin, windowOrigin = true, input.Position, main.Position
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragOrigin
		main.Position = UDim2.new(windowOrigin.X.Scale, windowOrigin.X.Offset + delta.X, windowOrigin.Y.Scale, windowOrigin.Y.Offset + delta.Y)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

local sidebar = make("Frame", {
	Position = UDim2.fromOffset(0, 76), Size = UDim2.new(0, 205, 1, -76),
	BackgroundColor3 = Theme.sidebar, BorderSizePixel = 0,
}, main)
make("UIPadding", {PaddingTop = UDim.new(0, 16), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14)}, sidebar)
make("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, sidebar)

local contentHost = make("Frame", {
	Position = UDim2.fromOffset(205, 76), Size = UDim2.new(1, -205, 1, -76),
	BackgroundTransparency = 1, BorderSizePixel = 0,
}, main)

local pages, navButtons = {}, {}

local function createPage(name)
	local page = make("ScrollingFrame", {
		Name = name .. "Page", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.accent,
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Visible = false,
	}, contentHost)
	make("UIPadding", {PaddingTop = UDim.new(0, 16), PaddingBottom = UDim.new(0, 16), PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16)}, page)
	make("UIListLayout", {Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder}, page)
	pages[name] = page
	return page
end

local function section(page, heading, height)
	local card = make("Frame", {Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = Theme.panel, BorderSizePixel = 0}, page)
	round(card, 10); outline(card)
	make("TextLabel", {
		Position = UDim2.fromOffset(18, 12), Size = UDim2.new(1, -36, 0, 25), BackgroundTransparency = 1,
		Text = heading, TextColor3 = Theme.text, TextSize = 15, Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, card)
	return card
end

local function addToggle(parent, y, label, description, initial, callback)
	local state = initial
	make("TextLabel", {Position = UDim2.fromOffset(18, y), Size = UDim2.new(1, -105, 0, 21), BackgroundTransparency = 1, Text = label, TextColor3 = Theme.text, TextSize = 13, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left}, parent)
	if description then make("TextLabel", {Position = UDim2.fromOffset(18, y + 21), Size = UDim2.new(1, -105, 0, 17), BackgroundTransparency = 1, Text = description, TextColor3 = Theme.muted, TextSize = 10, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left}, parent) end
	local button = make("TextButton", {Position = UDim2.new(1, -68, 0, y + 3), Size = UDim2.fromOffset(50, 27), BackgroundColor3 = state and Theme.accent or Theme.track, BorderSizePixel = 0, Text = "", AutoButtonColor = false}, parent)
	round(button, 14)
	local knob = make("Frame", {Position = state and UDim2.new(1, -24, 0.5, -10) or UDim2.new(0, 3, 0.5, -10), Size = UDim2.fromOffset(21, 21), BackgroundColor3 = Theme.text, BorderSizePixel = 0}, button)
	round(knob, 11)
	button.Activated:Connect(function()
		state = not state
		animate(button, {BackgroundColor3 = state and Theme.accent or Theme.track})
		animate(knob, {Position = state and UDim2.new(1, -24, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)})
		callback(state)
	end)
end

local function addSlider(parent, y, label, minimum, maximum, initial, callback)
	local value = math.clamp(initial, minimum, maximum)
	make("TextLabel", {Position = UDim2.fromOffset(18, y), Size = UDim2.new(0.7, 0, 0, 20), BackgroundTransparency = 1, Text = label, TextColor3 = Theme.text, TextSize = 13, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left}, parent)
	local valueLabel = make("TextLabel", {Position = UDim2.new(1, -88, 0, y), Size = UDim2.fromOffset(70, 20), BackgroundTransparency = 1, Text = tostring(value), TextColor3 = Theme.text, TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Right}, parent)
	local track = make("Frame", {Position = UDim2.fromOffset(18, y + 33), Size = UDim2.new(1, -36, 0, 5), BackgroundColor3 = Theme.track, BorderSizePixel = 0}, parent)
	round(track, 3)
	local ratio = (value - minimum) / (maximum - minimum)
	local fill = make("Frame", {Size = UDim2.new(ratio, 0, 1, 0), BackgroundColor3 = Theme.accent, BorderSizePixel = 0}, track); round(fill, 3)
	local knob = make("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(ratio, 0, 0.5, 0), Size = UDim2.fromOffset(15, 15), BackgroundColor3 = Theme.text, BorderSizePixel = 0, ZIndex = 3}, track); round(knob, 8)
	local hitbox = make("TextButton", {Position = UDim2.new(0, 0, 0.5, -14), Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Text = "", ZIndex = 4}, track)
	local sliding = false
	local function update(x)
		local newRatio = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		value = math.floor(minimum + (maximum - minimum) * newRatio + 0.5)
		fill.Size, knob.Position, valueLabel.Text = UDim2.new(newRatio, 0, 1, 0), UDim2.new(newRatio, 0, 0.5, 0), tostring(value)
		callback(value)
	end
	hitbox.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then sliding = true; update(input.Position.X) end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then update(input.Position.X) end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then sliding = false end
	end)
end

local function placeholder(page, message)
	local card = section(page, "Coming Soon", 145)
	make("TextLabel", {Position = UDim2.fromOffset(18, 47), Size = UDim2.new(1, -36, 0, 70), BackgroundTransparency = 1, Text = message, TextWrapped = true, TextColor3 = Theme.muted, TextSize = 13, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top}, card)
end

local combat = createPage("Combat")
local network = section(combat, "Networking", 170)
addSlider(network, 49, "Ping Compensation", 0, 250, Settings.PingCompensation, function(v) Settings.PingCompensation = v end)
addSlider(network, 108, "Max Anim Length (ms)", 100, 1500, Settings.MaxAnimationLength, function(v) Settings.MaxAnimationLength = v end)
local safety = section(combat, "Safety & Checks", 235)
addToggle(safety, 48, "Guard Break Guard", "UI configuration option", Settings.GuardBreakGuard, function(v) Settings.GuardBreakGuard = v end)
addSlider(safety, 108, "Skip Above Guard %", 0, 100, Settings.SkipAboveGuard, function(v) Settings.SkipAboveGuard = v end)
addToggle(safety, 174, "Face Check", "UI configuration option", Settings.FaceCheck, function(v) Settings.FaceCheck = v end)

local playerPage = createPage("Player")
local movement = section(playerPage, "Movement Preview", 110)
addSlider(movement, 48, "Walk Speed Value", 8, 32, Settings.WalkSpeedPreview, function(v) Settings.WalkSpeedPreview = v end)
local visuals = createPage("Visuals")
local visualCard = section(visuals, "Interface", 105)
addToggle(visualCard, 49, "Show Player Names", "UI configuration option", Settings.ShowNames, function(v) Settings.ShowNames = v end)
local farm = createPage("Farm")
local farmCard = section(farm, "Training", 105)
addToggle(farmCard, 49, "Auto Farm Preview", "UI only; no automation is included", Settings.AutoFarmPreview, function(v) Settings.AutoFarmPreview = v end)
local misc = createPage("Misc"); placeholder(misc, "Add legitimate game-specific controls for your own Roblox experience here.")
local settingsPage = createPage("Settings")
local settingsCard = section(settingsPage, "Menu Settings", 105)
addToggle(settingsCard, 49, "Notifications", "Enable menu notifications", Settings.Notifications, function(v) Settings.Notifications = v end)

local function selectPage(name)
	for pageName, page in pairs(pages) do page.Visible = pageName == name end
	for buttonName, button in pairs(navButtons) do
		local selected = buttonName == name
		animate(button, {BackgroundColor3 = selected and Theme.accentDark or Theme.panel, TextColor3 = selected and Theme.text or Theme.muted})
	end
end

local navOrder = {"Combat", "Player", "Visuals", "Farm", "Misc", "Settings"}
for index, name in ipairs(navOrder) do
	local button = make("TextButton", {
		Name = name .. "Button", LayoutOrder = index, Size = UDim2.new(1, 0, 0, 43),
		BackgroundColor3 = Theme.panel, BorderSizePixel = 0, Text = string.upper(name) .. "        ›",
		TextColor3 = Theme.muted, TextSize = 13, Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false,
	}, sidebar)
	round(button, 8)
	make("UIPadding", {PaddingLeft = UDim.new(0, 14)}, button)
	button.MouseEnter:Connect(function() if pages[name] and not pages[name].Visible then animate(button, {BackgroundColor3 = Theme.panelHover}) end end)
	button.MouseLeave:Connect(function() if pages[name] and not pages[name].Visible then animate(button, {BackgroundColor3 = Theme.panel}) end end)
	button.Activated:Connect(function() selectPage(name) end)
	navButtons[name] = button
end

UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.RightShift then main.Visible = not main.Visible end
end)

selectPage("Combat")

-- Expose current UI values to other LocalScripts in the same environment if needed.
gui:SetAttribute("Ready", true)
