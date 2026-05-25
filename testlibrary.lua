-- onyxlibrary.lua  —  Black & White edition  (Linoria-style tab content)
-- Changes:
--   • Tab content now mirrors LinoriaLib layout exactly (left/right groupboxes, tabboxes)
--   • Added all Linoria-style elements: Toggle, Slider, Dropdown, Button, Input, Label, Divider, ColorPicker, KeyPicker
--   • Font changed to Enum.Font.Code throughout
--   • Black & white color scheme preserved
--   • Other features (sidebar, dragging, resize, profile) remain unchanged

local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local TextService  = game:GetService("TextService")
local CoreGui      = game:GetService("CoreGui")
local Teams        = game:GetService("Teams")

-- ============================================================
--  PALETTE  —  black / white / gray only
-- ============================================================
local C = {
	shellOuter   = Color3.fromRGB(8,   8,   8),
	shellBorder  = Color3.fromRGB(55,  55,  55),
	bgMain       = Color3.fromRGB(100, 100, 100),
	bgDeep       = Color3.fromRGB(5,   5,   5),
	bgSurface    = Color3.fromRGB(16,  16,  16),
	bgRaised     = Color3.fromRGB(22,  22,  22),
	bgHover      = Color3.fromRGB(30,  30,  30),
	bgPress      = Color3.fromRGB(38,  38,  38),
	sidebarBg    = Color3.fromRGB(7,   7,   7),
	sidebarLine  = Color3.fromRGB(28,  28,  28),
	tabActive    = Color3.fromRGB(20,  20,  20),
	tabInact     = Color3.fromRGB(10,  10,  10),
	tabHover     = Color3.fromRGB(18,  18,  18),
	accentBright = Color3.fromRGB(255, 255, 255),
	accentMid    = Color3.fromRGB(200, 200, 200),
	accentDim    = Color3.fromRGB(120, 120, 120),
	textBright   = Color3.fromRGB(245, 245, 245),
	textMid      = Color3.fromRGB(185, 185, 185),
	textSub      = Color3.fromRGB(110, 110, 110),
	textDim      = Color3.fromRGB(60,  60,  60),
	borderHard   = Color3.fromRGB(45,  45,  45),
	borderSoft   = Color3.fromRGB(28,  28,  28),
	borderFaint  = Color3.fromRGB(18,  18,  18),
	rowBg        = Color3.fromRGB(15,  15,  15),
	rowBgAlt     = Color3.fromRGB(20,  20,  20),
	titleBg      = Color3.fromRGB(8,   8,   8),
	dialogBg     = Color3.fromRGB(12,  12,  12),
	knob         = Color3.fromRGB(220, 220, 220),
	sliderFill   = Color3.fromRGB(190, 190, 190),
	sliderTrack  = Color3.fromRGB(30,  30,  30),
	dropBg       = Color3.fromRGB(10,  10,  10),
	dropItem     = Color3.fromRGB(14,  14,  14),
	dropItemSel  = Color3.fromRGB(22,  22,  22),
	checkOff     = Color3.fromRGB(14,  14,  14),
	profileBg    = Color3.fromRGB(10,  10,  10),
	profileLine  = Color3.fromRGB(26,  26,  26),
	riskColor    = Color3.fromRGB(255, 50,  50),
	black        = Color3.new(0, 0, 0),
}

-- ============================================================
--  TWEEN PRESETS
-- ============================================================
local FONT_REG  = Enum.Font.Code
local FONT_BOLD = Enum.Font.Code
local FONT_SCI  = Enum.Font.Code

local SNAP   = TweenInfo.new(0.08, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local FAST   = TweenInfo.new(0.15, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local MED    = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local SLOW   = TweenInfo.new(0.40, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local SPRING = TweenInfo.new(0.30, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)

local ITEM_H = 20

-- ============================================================
--  HELPERS
-- ============================================================
local function tw(inst, goals, info)
	return TweenService:Create(inst, info or FAST, goals)
end
local function corner(inst, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 2)
	c.Parent = inst; return c
end
local function stroke(inst, col, thick, trans)
	local s = Instance.new("UIStroke")
	s.Color = col or C.borderHard
	s.Thickness = thick or 1
	s.Transparency = trans or 0
	s.Parent = inst; return s
end
local function gradient(inst, c0, c1, rot)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(c0, c1)
	g.Rotation = rot or 90
	g.Parent = inst; return g
end
local function gradientN(inst, stops, rot)
	local kps = {}
	for _, s in ipairs(stops) do
		table.insert(kps, ColorSequenceKeypoint.new(s[1], s[2]))
	end
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(kps)
	g.Rotation = rot or 90
	g.Parent = inst; return g
end
local function ripple(frame)
	local r = Instance.new("Frame")
	r.Size = UDim2.fromScale(1, 1)
	r.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	r.BackgroundTransparency = 0.88
	r.BorderSizePixel = 0
	r.ZIndex = frame.ZIndex + 10
	r.Parent = frame
	corner(r, 3)
	tw(r, {BackgroundTransparency = 1}, MED):Play()
	game:GetService("Debris"):AddItem(r, 0.3)
end
local function getTextBounds(text, font, size)
	return TextService:GetTextSize(text, size or 14, font or FONT_REG, Vector2.new(1920, 1080))
end
local function getDarkerColor(color)
	local h, s, v = color:ToHSV()
	return Color3.fromHSV(h, s, v / 1.5)
end
local function mapValue(value, minA, maxA, minB, maxB)
	return (1 - ((value - minA) / (maxA - minA))) * minB + ((value - minA) / (maxA - minA)) * maxB
end

-- ============================================================
--  REGISTRY (for dynamic color updates)
-- ============================================================
local Registry = {}
local RegistryMap = {}

local function addToRegistry(instance, properties)
	local data = { Instance = instance, Properties = properties }
	table.insert(Registry, data)
	RegistryMap[instance] = data
end

local function removeFromRegistry(instance)
	local data = RegistryMap[instance]
	if data then
		for i = #Registry, 1, -1 do
			if Registry[i] == data then
				table.remove(Registry, i)
			end
		end
		RegistryMap[instance] = nil
	end
end

local function updateRegistryColors()
	for _, obj in ipairs(Registry) do
		for prop, colorIdx in pairs(obj.Properties) do
			if type(colorIdx) == "string" then
				obj.Instance[prop] = C[colorIdx] or C.textBright
			end
		end
	end
end

-- ============================================================
--  NEW ELEMENT OBJECT (Linoria-style)
-- ============================================================
local function newElementObj(defaultValue, callback)
	local obj   = {}
	obj.Value    = defaultValue
	obj.Callback = callback
	local _changed = nil

	function obj:OnChanged(fn)
		_changed = fn
		if fn then fn(self.Value) end
	end
	function obj:GetValue() return self.Value end
	function obj:_fire(v)
		self.Value = v
		if self.Callback then pcall(self.Callback, v) end
		if _changed      then pcall(_changed,      v) end
	end
	function obj:SetValue(v) self:_fire(v) end
	return obj
end

-- ============================================================
--  COLOR PICKER (Linoria-style)
-- ============================================================
local function buildColorPickerLinoria(parent, defColor, defTransparency, callback)
	defColor = defColor or Color3.fromRGB(200, 200, 200)
	defTransparency = defTransparency or 0

	local picker = {}
	local h, s, v = defColor:ToHSV()
	picker.Hue = h
	picker.Sat = s
	picker.Vib = v
	picker.Transparency = defTransparency
	picker.Value = defColor
	picker.Callback = callback or function() end

	-- Outer frame (black border)
	local PickerFrameOuter = Instance.new("Frame")
	PickerFrameOuter.Name = "Color"
	PickerFrameOuter.BackgroundColor3 = C.black
	PickerFrameOuter.BorderColor3 = C.black
	PickerFrameOuter.Size = UDim2.fromOffset(230, picker.Transparency and 271 or 253)
	PickerFrameOuter.Visible = false
	PickerFrameOuter.ZIndex = 15
	PickerFrameOuter.Parent = parent

	local PickerFrameInner = Instance.new("Frame")
	PickerFrameInner.BackgroundColor3 = C.bgDeep
	PickerFrameInner.BorderColor3 = C.borderHard
	PickerFrameInner.BorderMode = Enum.BorderMode.Inset
	PickerFrameInner.Size = UDim2.new(1, 0, 1, 0)
	PickerFrameInner.ZIndex = 16
	PickerFrameInner.Parent = PickerFrameOuter
	addToRegistry(PickerFrameInner, { BackgroundColor3 = "bgDeep", BorderColor3 = "borderHard" })

	local Highlight = Instance.new("Frame")
	Highlight.BackgroundColor3 = C.accentMid
	Highlight.BorderSizePixel = 0
	Highlight.Size = UDim2.new(1, 0, 0, 2)
	Highlight.ZIndex = 17
	Highlight.Parent = PickerFrameInner
	addToRegistry(Highlight, { BackgroundColor3 = "accentMid" })

	-- Sat/Vib map
	local SatVibMapOuter = Instance.new("Frame")
	SatVibMapOuter.BorderColor3 = C.black
	SatVibMapOuter.Position = UDim2.new(0, 4, 0, 25)
	SatVibMapOuter.Size = UDim2.new(0, 200, 0, 200)
	SatVibMapOuter.ZIndex = 17
	SatVibMapOuter.Parent = PickerFrameInner

	local SatVibMapInner = Instance.new("Frame")
	SatVibMapInner.BackgroundColor3 = C.bgDeep
	SatVibMapInner.BorderColor3 = C.borderHard
	SatVibMapInner.BorderMode = Enum.BorderMode.Inset
	SatVibMapInner.Size = UDim2.new(1, 0, 1, 0)
	SatVibMapInner.ZIndex = 18
	SatVibMapInner.Parent = SatVibMapOuter
	addToRegistry(SatVibMapInner, { BackgroundColor3 = "bgDeep", BorderColor3 = "borderHard" })

	local SatVibMap = Instance.new("ImageLabel")
	SatVibMap.BorderSizePixel = 0
	SatVibMap.Size = UDim2.new(1, 0, 1, 0)
	SatVibMap.ZIndex = 18
	SatVibMap.Image = "rbxassetid://4155801252"
	SatVibMap.Parent = SatVibMapInner

	local CursorOuter = Instance.new("ImageLabel")
	CursorOuter.AnchorPoint = Vector2.new(0.5, 0.5)
	CursorOuter.Size = UDim2.new(0, 6, 0, 6)
	CursorOuter.BackgroundTransparency = 1
	CursorOuter.Image = "http://www.roblox.com/asset/?id=9619665977"
	CursorOuter.ImageColor3 = C.black
	CursorOuter.ZIndex = 19
	CursorOuter.Parent = SatVibMap

	local CursorInner = Instance.new("ImageLabel")
	CursorInner.Size = UDim2.new(0, CursorOuter.Size.X.Offset - 2, 0, CursorOuter.Size.Y.Offset - 2)
	CursorInner.Position = UDim2.new(0, 1, 0, 1)
	CursorInner.BackgroundTransparency = 1
	CursorInner.Image = "http://www.roblox.com/asset/?id=9619665977"
	CursorInner.ImageColor3 = C.textBright
	CursorInner.ZIndex = 20
	CursorInner.Parent = CursorOuter

	-- Hue selector
	local HueSelectorOuter = Instance.new("Frame")
	HueSelectorOuter.BorderColor3 = C.black
	HueSelectorOuter.Position = UDim2.new(0, 208, 0, 25)
	HueSelectorOuter.Size = UDim2.new(0, 15, 0, 200)
	HueSelectorOuter.ZIndex = 17
	HueSelectorOuter.Parent = PickerFrameInner

	local HueSelectorInner = Instance.new("Frame")
	HueSelectorInner.BackgroundColor3 = Color3.new(1, 1, 1)
	HueSelectorInner.BorderSizePixel = 0
	HueSelectorInner.Size = UDim2.new(1, 0, 1, 0)
	HueSelectorInner.ZIndex = 18
	HueSelectorInner.Parent = HueSelectorOuter

	local sequenceTable = {}
	for hue = 0, 1, 0.1 do
		table.insert(sequenceTable, ColorSequenceKeypoint.new(hue, Color3.fromHSV(hue, 1, 1)))
	end
	local HueSelectorGradient = Instance.new("UIGradient")
	HueSelectorGradient.Color = ColorSequence.new(sequenceTable)
	HueSelectorGradient.Rotation = 90
	HueSelectorGradient.Parent = HueSelectorInner

	local HueCursor = Instance.new("Frame")
	HueCursor.BackgroundColor3 = Color3.new(1, 1, 1)
	HueCursor.AnchorPoint = Vector2.new(0, 0.5)
	HueCursor.BorderColor3 = C.black
	HueCursor.Size = UDim2.new(1, 0, 0, 1)
	HueCursor.ZIndex = 18
	HueCursor.Parent = HueSelectorInner

	-- Hex input
	local HueBoxOuter = Instance.new("Frame")
	HueBoxOuter.BorderColor3 = C.black
	HueBoxOuter.Position = UDim2.fromOffset(4, 228)
	HueBoxOuter.Size = UDim2.new(0.5, -6, 0, 20)
	HueBoxOuter.ZIndex = 18
	HueBoxOuter.Parent = PickerFrameInner

	local HueBoxInner = Instance.new("Frame")
	HueBoxInner.BackgroundColor3 = C.bgRaised
	HueBoxInner.BorderColor3 = C.borderHard
	HueBoxInner.BorderMode = Enum.BorderMode.Inset
	HueBoxInner.Size = UDim2.new(1, 0, 1, 0)
	HueBoxInner.ZIndex = 18
	HueBoxInner.Parent = HueBoxOuter
	addToRegistry(HueBoxInner, { BackgroundColor3 = "bgRaised", BorderColor3 = "borderHard" })

	local hueGrad = Instance.new("UIGradient")
	hueGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
	})
	hueGrad.Rotation = 90
	hueGrad.Parent = HueBoxInner

	local HueBox = Instance.new("TextBox")
	HueBox.BackgroundTransparency = 1
	HueBox.Position = UDim2.new(0, 5, 0, 0)
	HueBox.Size = UDim2.new(1, -5, 1, 0)
	HueBox.Font = FONT_REG
	HueBox.PlaceholderColor3 = Color3.fromRGB(190, 190, 190)
	HueBox.PlaceholderText = "Hex color"
	HueBox.Text = "#" .. defColor:ToHex()
	HueBox.TextColor3 = C.textBright
	HueBox.TextSize = 14
	HueBox.TextXAlignment = Enum.TextXAlignment.Left
	HueBox.ZIndex = 20
	HueBox.Parent = HueBoxInner
	addToRegistry(HueBox, { TextColor3 = "textBright" })

	-- RGB input
	local RgbBoxBase = HueBoxOuter:Clone()
	RgbBoxBase.Position = UDim2.new(0.5, 2, 0, 228)
	RgbBoxBase.Parent = PickerFrameInner

	local RgbBox = RgbBoxBase.Frame:FindFirstChild("TextBox")
	if RgbBox then
		RgbBox.Text = string.format("%d, %d, %d", math.floor(defColor.R * 255), math.floor(defColor.G * 255), math.floor(defColor.B * 255))
		RgbBox.PlaceholderText = "RGB color"
		RgbBox.TextColor3 = C.textBright
		addToRegistry(RgbBox, { TextColor3 = "textBright" })
	end
	addToRegistry(RgbBoxBase.Frame, { BackgroundColor3 = "bgRaised", BorderColor3 = "borderHard" })

	-- Transparency slider (if needed)
	local TransparencyBoxInner, TransparencyCursor
	if picker.Transparency then
		local TransparencyBoxOuter = Instance.new("Frame")
		TransparencyBoxOuter.BorderColor3 = C.black
		TransparencyBoxOuter.Position = UDim2.fromOffset(4, 251)
		TransparencyBoxOuter.Size = UDim2.new(1, -8, 0, 15)
		TransparencyBoxOuter.ZIndex = 19
		TransparencyBoxOuter.Parent = PickerFrameInner

		TransparencyBoxInner = Instance.new("Frame")
		TransparencyBoxInner.BackgroundColor3 = picker.Value
		TransparencyBoxInner.BorderColor3 = C.borderHard
		TransparencyBoxInner.BorderMode = Enum.BorderMode.Inset
		TransparencyBoxInner.Size = UDim2.new(1, 0, 1, 0)
		TransparencyBoxInner.ZIndex = 19
		TransparencyBoxInner.Parent = TransparencyBoxOuter
		addToRegistry(TransparencyBoxInner, { BorderColor3 = "borderHard" })

		local checkerImg = Instance.new("ImageLabel")
		checkerImg.BackgroundTransparency = 1
		checkerImg.Size = UDim2.new(1, 0, 1, 0)
		checkerImg.Image = "http://www.roblox.com/asset/?id=12978095818"
		checkerImg.ZIndex = 20
		checkerImg.Parent = TransparencyBoxInner

		TransparencyCursor = Instance.new("Frame")
		TransparencyCursor.BackgroundColor3 = Color3.new(1, 1, 1)
		TransparencyCursor.AnchorPoint = Vector2.new(0.5, 0)
		TransparencyCursor.BorderColor3 = C.black
		TransparencyCursor.Size = UDim2.new(0, 1, 1, 0)
		TransparencyCursor.ZIndex = 21
		TransparencyCursor.Parent = TransparencyBoxInner
	end

	-- Display label
	local DisplayLabel = Instance.new("TextLabel")
	DisplayLabel.Size = UDim2.new(1, 0, 0, 14)
	DisplayLabel.Position = UDim2.fromOffset(5, 5)
	DisplayLabel.BackgroundTransparency = 1
	DisplayLabel.Font = FONT_REG
	DisplayLabel.TextSize = 14
	DisplayLabel.TextColor3 = C.textBright
	DisplayLabel.TextXAlignment = Enum.TextXAlignment.Left
	DisplayLabel.Text = "Color Picker"
	DisplayLabel.TextWrapped = false
	DisplayLabel.ZIndex = 16
	DisplayLabel.Parent = PickerFrameInner

	-- Display function
	function picker:Display()
		picker.Value = Color3.fromHSV(picker.Hue, picker.Sat, picker.Vib)
		SatVibMap.BackgroundColor3 = Color3.fromHSV(picker.Hue, 1, 1)
		picker.Value = picker.Value
		picker.Transparency = picker.Transparency or 0

		if TransparencyBoxInner then
			TransparencyBoxInner.BackgroundColor3 = picker.Value
			TransparencyCursor.Position = UDim2.new(1 - picker.Transparency, 0, 0, 0)
		end

		CursorOuter.Position = UDim2.new(picker.Sat, 0, 1 - picker.Vib, 0)
		HueCursor.Position = UDim2.new(0, 0, picker.Hue, 0)

		HueBox.Text = "#" .. picker.Value:ToHex()
		if RgbBox then
			RgbBox.Text = string.format("%d, %d, %d", math.floor(picker.Value.R * 255), math.floor(picker.Value.G * 255), math.floor(picker.Value.B * 255))
		end

		if picker.Callback then
			pcall(picker.Callback, picker.Value, picker.Transparency)
		end
		if picker.Changed then
			pcall(picker.Changed, picker.Value, picker.Transparency)
		end
	end

	function picker:SetValueRGB(color, transparency)
		picker.Transparency = transparency or 0
		picker.Hue, picker.Sat, picker.Vib = color:ToHSV()
		picker:Display()
	end

	function picker:OnChanged(fn)
		picker.Changed = fn
		fn(picker.Value, picker.Transparency)
	end

	-- Input handling
	local mouse = Players.LocalPlayer:GetMouse()

	SatVibMap.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			while UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
				local minX = SatVibMap.AbsolutePosition.X
				local maxX = minX + SatVibMap.AbsoluteSize.X
				local mouseX = math.clamp(mouse.X, minX, maxX)
				local minY = SatVibMap.AbsolutePosition.Y
				local maxY = minY + SatVibMap.AbsoluteSize.Y
				local mouseY = math.clamp(mouse.Y, minY, maxY)
				picker.Sat = (mouseX - minX) / (maxX - minX)
				picker.Vib = 1 - ((mouseY - minY) / (maxY - minY))
				picker:Display()
				RunService.RenderStepped:Wait()
			end
		end
	end)

	HueSelectorInner.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			while UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
				local minY = HueSelectorInner.AbsolutePosition.Y
				local maxY = minY + HueSelectorInner.AbsoluteSize.Y
				local mouseY = math.clamp(mouse.Y, minY, maxY)
				picker.Hue = ((mouseY - minY) / (maxY - minY))
				picker:Display()
				RunService.RenderStepped:Wait()
			end
		end
	end)

	if TransparencyBoxInner then
		TransparencyBoxInner.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				while UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
					local minX = TransparencyBoxInner.AbsolutePosition.X
					local maxX = minX + TransparencyBoxInner.AbsoluteSize.X
					local mouseX = math.clamp(mouse.X, minX, maxX)
					picker.Transparency = 1 - ((mouseX - minX) / (maxX - minX))
					picker:Display()
					RunService.RenderStepped:Wait()
				end
			end
		end)
	end

	HueBox.FocusLost:Connect(function(enter)
		if enter then
			local success, result = pcall(Color3.fromHex, HueBox.Text)
			if success and typeof(result) == "Color3" then
				picker.Hue, picker.Sat, picker.Vib = result:ToHSV()
			end
		end
		picker:Display()
	end)

	if RgbBox then
		RgbBox.FocusLost:Connect(function(enter)
			if enter then
				local r, g, b = RgbBox.Text:match("(%d+),%s*(%d+),%s*(%d+)")
				if r and g and b then
					picker.Hue, picker.Sat, picker.Vib = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b)):ToHSV()
				end
			end
			picker:Display()
		end)
	end

	picker:Display()
	picker.Frame = PickerFrameOuter

	return picker
end

-- ============================================================
--  LINORIA-STYLE GROUPBOX / TABBOX CONTENT BUILDER
-- ============================================================

local BaseGroupbox = {}
do
	local Funcs = {}

	function Funcs:AddBlank(size)
		local groupbox = self
		local container = groupbox.Container
		local blank = Instance.new("Frame")
		blank.BackgroundTransparency = 1
		blank.Size = UDim2.new(1, 0, 0, size or 5)
		blank.ZIndex = 1
		blank.Parent = container
	end

	function Funcs:AddLabel(text, doesWrap)
		local groupbox = self
		local container = groupbox.Container

		local textLabel = Instance.new("TextLabel")
		textLabel.Size = UDim2.new(1, -4, 0, 15)
		textLabel.BackgroundTransparency = 1
		textLabel.Font = FONT_REG
		textLabel.TextSize = 14
		textLabel.TextColor3 = C.textBright
		textLabel.Text = text
		textLabel.TextWrapped = doesWrap or false
		textLabel.TextXAlignment = Enum.TextXAlignment.Left
		textLabel.ZIndex = 5
		textLabel.Parent = container

		if doesWrap then
			local _, y = getTextBounds(text, FONT_REG, 14)
			textLabel.Size = UDim2.new(1, -4, 0, y)
		end

		local label = { TextLabel = textLabel, Container = container }
		function label:SetText(newText)
			textLabel.Text = newText
			if doesWrap then
				local _, y = getTextBounds(newText, FONT_REG, 14)
				textLabel.Size = UDim2.new(1, -4, 0, y)
			end
			groupbox:Resize()
		end

		groupbox:AddBlank(5)
		groupbox:Resize()
		return label
	end

	function Funcs:AddButton(text, callback)
		local groupbox = self
		local container = groupbox.Container

		local outer = Instance.new("Frame")
		outer.BackgroundColor3 = C.black
		outer.BorderColor3 = C.black
		outer.Size = UDim2.new(1, -4, 0, 20)
		outer.ZIndex = 5
		outer.Parent = container

		local inner = Instance.new("Frame")
		inner.BackgroundColor3 = C.bgRaised
		inner.BorderColor3 = C.borderHard
		inner.BorderMode = Enum.BorderMode.Inset
		inner.Size = UDim2.new(1, 0, 1, 0)
		inner.ZIndex = 6
		inner.Parent = outer

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Font = FONT_REG
		label.TextSize = 14
		label.TextColor3 = C.textBright
		label.Text = text
		label.ZIndex = 6
		label.Parent = inner

		local btnGrad = Instance.new("UIGradient")
		btnGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
		})
		btnGrad.Rotation = 90
		btnGrad.Parent = inner

		addToRegistry(inner, { BackgroundColor3 = "bgRaised", BorderColor3 = "borderHard" })

		outer.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				if callback then pcall(callback) end
			end
		end)

		outer.MouseEnter:Connect(function()
			tw(outer, { BorderColor3 = C.accentMid }, SNAP):Play()
		end)
		outer.MouseLeave:Connect(function()
			tw(outer, { BorderColor3 = C.black }, SNAP):Play()
		end)

		groupbox:AddBlank(5)
		groupbox:Resize()

		return { Outer = outer, Inner = inner, Label = label, SetText = function(self, t) label.Text = t end }
	end

	function Funcs:AddDivider()
		local groupbox = self
		local container = groupbox.Container

		groupbox:AddBlank(2)

		local outer = Instance.new("Frame")
		outer.BackgroundColor3 = C.black
		outer.BorderColor3 = C.black
		outer.Size = UDim2.new(1, -4, 0, 5)
		outer.ZIndex = 5
		outer.Parent = container

		local inner = Instance.new("Frame")
		inner.BackgroundColor3 = C.bgRaised
		inner.BorderColor3 = C.borderHard
		inner.BorderMode = Enum.BorderMode.Inset
		inner.Size = UDim2.new(1, 0, 1, 0)
		inner.ZIndex = 6
		inner.Parent = outer

		addToRegistry(inner, { BackgroundColor3 = "bgRaised", BorderColor3 = "borderHard" })

		groupbox:AddBlank(9)
		groupbox:Resize()
	end

	function Funcs:AddInput(info)
		local groupbox = self
		local container = groupbox.Container

		info = info or {}
		local textbox = {
			Value = info.Default or "",
			Numeric = info.Numeric or false,
			Finished = info.Finished or false,
			Callback = info.Callback or function() end,
		}

		-- Label
		local inputLabel = Instance.new("TextLabel")
		inputLabel.Size = UDim2.new(1, 0, 0, 15)
		inputLabel.BackgroundTransparency = 1
		inputLabel.Font = FONT_REG
		inputLabel.TextSize = 14
		inputLabel.TextColor3 = C.textBright
		inputLabel.Text = info.Text or ""
		inputLabel.TextXAlignment = Enum.TextXAlignment.Left
		inputLabel.ZIndex = 5
		inputLabel.Parent = container

		groupbox:AddBlank(1)

		-- Text box
		local outer = Instance.new("Frame")
		outer.BackgroundColor3 = C.black
		outer.BorderColor3 = C.black
		outer.Size = UDim2.new(1, -4, 0, 20)
		outer.ZIndex = 5
		outer.Parent = container

		local inner = Instance.new("Frame")
		inner.BackgroundColor3 = C.bgRaised
		inner.BorderColor3 = C.borderHard
		inner.BorderMode = Enum.BorderMode.Inset
		inner.Size = UDim2.new(1, 0, 1, 0)
		inner.ZIndex = 6
		inner.Parent = outer
		addToRegistry(inner, { BackgroundColor3 = "bgRaised", BorderColor3 = "borderHard" })

		local btnGrad = Instance.new("UIGradient")
		btnGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
		})
		btnGrad.Rotation = 90
		btnGrad.Parent = inner

		local clipContainer = Instance.new("Frame")
		clipContainer.BackgroundTransparency = 1
		clipContainer.ClipsDescendants = true
		clipContainer.Position = UDim2.new(0, 5, 0, 0)
		clipContainer.Size = UDim2.new(1, -5, 1, 0)
		clipContainer.ZIndex = 7
		clipContainer.Parent = inner

		local box = Instance.new("TextBox")
		box.BackgroundTransparency = 1
		box.Position = UDim2.fromOffset(0, 0)
		box.Size = UDim2.fromScale(5, 1)
		box.Font = FONT_REG
		box.PlaceholderColor3 = Color3.fromRGB(190, 190, 190)
		box.PlaceholderText = info.Placeholder or ""
		box.Text = info.Default or ""
		box.TextColor3 = C.textBright
		box.TextSize = 14
		box.TextXAlignment = Enum.TextXAlignment.Left
		box.ZIndex = 7
		box.Parent = clipContainer
		addToRegistry(box, { TextColor3 = "textBright" })

		function textbox:SetValue(txt)
			if info.MaxLength and #txt > info.MaxLength then
				txt = txt:sub(1, info.MaxLength)
			end
			if textbox.Numeric then
				if not tonumber(txt) and txt:len() > 0 then
					txt = textbox.Value
				end
			end
			textbox.Value = txt
			box.Text = txt
			if textbox.Callback then pcall(textbox.Callback, textbox.Value) end
			if textbox.Changed then pcall(textbox.Changed, textbox.Value) end
		end

		function textbox:OnChanged(fn)
			textbox.Changed = fn
			fn(textbox.Value)
		end

		if textbox.Finished then
			box.FocusLost:Connect(function(enter)
				if not enter then return end
				textbox:SetValue(box.Text)
			end)
		else
			box:GetPropertyChangedSignal("Text"):Connect(function()
				textbox:SetValue(box.Text)
			end)
		end

		outer.MouseEnter:Connect(function() tw(outer, { BorderColor3 = C.accentMid }, SNAP):Play() end)
		outer.MouseLeave:Connect(function() tw(outer, { BorderColor3 = C.black }, SNAP):Play() end)

		groupbox:AddBlank(5)
		groupbox:Resize()
		return textbox
	end

	function Funcs:AddToggle(info)
		info = info or {}
		local groupbox = self
		local container = groupbox.Container

		local toggle = {
			Value = info.Default or false,
			Callback = info.Callback or function() end,
			Addons = {},
			Risky = info.Risky,
		}

		local outer = Instance.new("Frame")
		outer.BackgroundColor3 = C.black
		outer.BorderColor3 = C.black
		outer.Size = UDim2.new(0, 13, 0, 13)
		outer.ZIndex = 5
		outer.Parent = container

		local inner = Instance.new("Frame")
		inner.BackgroundColor3 = C.bgRaised
		inner.BorderColor3 = C.borderHard
		inner.BorderMode = Enum.BorderMode.Inset
		inner.Size = UDim2.new(1, 0, 1, 0)
		inner.ZIndex = 6
		inner.Parent = outer
		addToRegistry(inner, { BackgroundColor3 = "bgRaised", BorderColor3 = "borderHard" })

		local toggleLabel = Instance.new("TextLabel")
		toggleLabel.Size = UDim2.new(0, 216, 1, 0)
		toggleLabel.Position = UDim2.new(1, 6, 0, 0)
		toggleLabel.BackgroundTransparency = 1
		toggleLabel.Font = FONT_REG
		toggleLabel.TextSize = 14
		toggleLabel.TextColor3 = toggle.Risky and C.riskColor or C.textBright
		toggleLabel.Text = info.Text or ""
		toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
		toggleLabel.ZIndex = 6
		toggleLabel.Parent = inner

		if toggle.Risky then
			addToRegistry(toggleLabel, { TextColor3 = "riskColor" })
		else
			addToRegistry(toggleLabel, { TextColor3 = "textBright" })
		end

		local toggleRegion = Instance.new("Frame")
		toggleRegion.BackgroundTransparency = 1
		toggleRegion.Size = UDim2.new(0, 170, 1, 0)
		toggleRegion.ZIndex = 8
		toggleRegion.Parent = outer

		function toggle:Display()
			if toggle.Value then
				inner.BackgroundColor3 = C.accentMid
				inner.BorderColor3 = getDarkerColor(C.accentMid)
				RegistryMap[inner].Properties.BackgroundColor3 = "accentMid"
				RegistryMap[inner].Properties.BorderColor3 = function() return getDarkerColor(C.accentMid) end
			else
				inner.BackgroundColor3 = C.bgRaised
				inner.BorderColor3 = C.borderHard
				RegistryMap[inner].Properties.BackgroundColor3 = "bgRaised"
				RegistryMap[inner].Properties.BorderColor3 = "borderHard"
			end
		end

		function toggle:SetValue(bool)
			bool = not not bool
			toggle.Value = bool
			toggle:Display()
			if toggle.Callback then pcall(toggle.Callback, toggle.Value) end
			if toggle.Changed then pcall(toggle.Changed, toggle.Value) end
		end

		function toggle:OnChanged(fn)
			toggle.Changed = fn
			fn(toggle.Value)
		end

		function toggle:AddColorPicker(info)
			-- Linoria-style color picker addon
			local cpInfo = info or {}
			local picker = buildColorPickerLinoria(groupbox.Container:FindFirstChildWhichIsA("Frame") or groupbox.Container.Parent,
				cpInfo.Default or Color3.fromRGB(200, 200, 200),
				cpInfo.Transparency or 0,
				function(color, transparency)
					if cpInfo.Callback then cpInfo.Callback(color, transparency) end
				end)

			-- Add display swatch
			local displayFrame = Instance.new("Frame")
			displayFrame.BackgroundColor3 = cpInfo.Default or Color3.fromRGB(200, 200, 200)
			displayFrame.BorderColor3 = C.borderHard
			displayFrame.Size = UDim2.new(0, 28, 0, 14)
			displayFrame.ZIndex = 6
			displayFrame.Parent = toggleLabel

			local uiListLayout = Instance.new("UIListLayout")
			uiListLayout.Padding = UDim.new(0, 4)
			uiListLayout.FillDirection = Enum.FillDirection.Horizontal
			uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
			uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
			uiListLayout.Parent = toggleLabel

			picker.DisplayFrame = displayFrame
			picker.Frame.Position = UDim2.fromOffset(
				displayFrame.AbsolutePosition.X,
				displayFrame.AbsolutePosition.Y + 18
			)

			displayFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
				picker.Frame.Position = UDim2.fromOffset(
					displayFrame.AbsolutePosition.X,
					displayFrame.AbsolutePosition.Y + 18
				)
			end)

			local pickerOpen = false
			displayFrame.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					if pickerOpen then
						picker.Frame.Visible = false
						pickerOpen = false
					else
						picker.Frame.Visible = true
						pickerOpen = true
					end
				end
			end)

			UIS.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 and pickerOpen then
					local absPos = picker.Frame.AbsolutePosition
					local absSize = picker.Frame.AbsoluteSize
					local mouse = Players.LocalPlayer:GetMouse()
					if mouse.X < absPos.X or mouse.X > absPos.X + absSize.X
						or mouse.Y < absPos.Y - 20 or mouse.Y > absPos.Y + absSize.Y then
						picker.Frame.Visible = false
						pickerOpen = false
					end
				end
			end)

			table.insert(toggle.Addons, picker)
			return toggle
		end

		function toggle:AddKeyPicker(info)
			info = info or {}
			local keyPicker = {
				Value = info.Default or "None",
				Toggled = false,
				Mode = info.Mode or "Toggle",
				SyncToggleState = info.SyncToggleState or false,
				Callback = info.Callback or function() end,
			}

			local pickOuter = Instance.new("Frame")
			pickOuter.BackgroundColor3 = C.black
			pickOuter.BorderColor3 = C.black
			pickOuter.Size = UDim2.new(0, 28, 0, 15)
			pickOuter.ZIndex = 6
			pickOuter.Parent = toggleLabel

			local pickInner = Instance.new("Frame")
			pickInner.BackgroundColor3 = C.bgDeep
			pickInner.BorderColor3 = C.borderHard
			pickInner.BorderMode = Enum.BorderMode.Inset
			pickInner.Size = UDim2.new(1, 0, 1, 0)
			pickInner.ZIndex = 7
			pickInner.Parent = pickOuter
			addToRegistry(pickInner, { BackgroundColor3 = "bgDeep", BorderColor3 = "borderHard" })

			local displayLabel = Instance.new("TextLabel")
			displayLabel.Size = UDim2.new(1, 0, 1, 0)
			displayLabel.BackgroundTransparency = 1
			displayLabel.Font = FONT_REG
			displayLabel.TextSize = 13
			displayLabel.TextColor3 = C.textBright
			displayLabel.Text = info.Default or "None"
			displayLabel.TextWrapped = true
			displayLabel.ZIndex = 8
			displayLabel.Parent = pickInner

			local picking = false
			pickOuter.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					picking = true
					displayLabel.Text = "..."
					local conn
					conn = UIS.InputBegan:Connect(function(inp, gp)
						if gp then return end
						local key
						if inp.UserInputType == Enum.UserInputType.Keyboard then
							key = inp.KeyCode.Name
						elseif inp.UserInputType == Enum.UserInputType.MouseButton1 then
							key = "MB1"
						elseif inp.UserInputType == Enum.UserInputType.MouseButton2 then
							key = "MB2"
						end
						if key then
							conn:Disconnect()
							picking = false
							keyPicker.Value = key
							displayLabel.Text = key
							if keyPicker.ChangedCallback then pcall(keyPicker.ChangedCallback, key) end
							if keyPicker.Changed then pcall(keyPicker.Changed, key) end
						end
					end)
				end
			end)

			function keyPicker:GetState()
				if keyPicker.Mode == "Always" then return true
				elseif keyPicker.Mode == "Hold" then
					if keyPicker.Value == "MB1" then return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
					elseif keyPicker.Value == "MB2" then return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
					else return UIS:IsKeyDown(Enum.KeyCode[keyPicker.Value]) end
				else return keyPicker.Toggled end
			end

			UIS.InputBegan:Connect(function(input, gp)
				if gp or picking then return end
				if keyPicker.Mode == "Toggle" then
					local match = false
					if keyPicker.Value == "MB1" and input.UserInputType == Enum.UserInputType.MouseButton1 then match = true
					elseif keyPicker.Value == "MB2" and input.UserInputType == Enum.UserInputType.MouseButton2 then match = true
					elseif input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == keyPicker.Value then match = true end
					if match then
						keyPicker.Toggled = not keyPicker.Toggled
						if keyPicker.SyncToggleState then toggle:SetValue(keyPicker.Toggled) end
						if keyPicker.Callback then pcall(keyPicker.Callback, keyPicker.Toggled) end
					end
				end
			end)

			table.insert(toggle.Addons, keyPicker)
			return toggle
		end

		toggleRegion.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				toggle:SetValue(not toggle.Value)
			end
		end)

		toggle.TextLabel = toggleLabel
		toggle.Container = container
		toggle:Display()
		groupbox:AddBlank(7)
		groupbox:Resize()
		return toggle
	end

	function Funcs:AddSlider(info)
		info = info or {}
		local groupbox = self
		local container = groupbox.Container

		local slider = {
			Value = info.Default or 0,
			Min = info.Min or 0,
			Max = info.Max or 100,
			Rounding = info.Rounding or 0,
			MaxSize = 232,
			Callback = info.Callback or function() end,
		}

		if not info.Compact then
			local sliderLabel = Instance.new("TextLabel")
			sliderLabel.Size = UDim2.new(1, 0, 0, 10)
			sliderLabel.BackgroundTransparency = 1
			sliderLabel.Font = FONT_REG
			sliderLabel.TextSize = 14
			sliderLabel.TextColor3 = C.textBright
			sliderLabel.Text = info.Text or ""
			sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
			sliderLabel.TextYAlignment = Enum.TextYAlignment.Bottom
			sliderLabel.ZIndex = 5
			sliderLabel.Parent = container
			groupbox:AddBlank(3)
		end

		local outer = Instance.new("Frame")
		outer.BackgroundColor3 = C.black
		outer.BorderColor3 = C.black
		outer.Size = UDim2.new(1, -4, 0, 13)
		outer.ZIndex = 5
		outer.Parent = container

		local inner = Instance.new("Frame")
		inner.BackgroundColor3 = C.bgRaised
		inner.BorderColor3 = C.borderHard
		inner.BorderMode = Enum.BorderMode.Inset
		inner.Size = UDim2.new(1, 0, 1, 0)
		inner.ZIndex = 6
		inner.Parent = outer
		addToRegistry(inner, { BackgroundColor3 = "bgRaised", BorderColor3 = "borderHard" })

		local fill = Instance.new("Frame")
		fill.BackgroundColor3 = C.accentMid
		fill.BorderColor3 = getDarkerColor(C.accentMid)
		fill.Size = UDim2.new(0, 0, 1, 0)
		fill.ZIndex = 7
		fill.Parent = inner
		addToRegistry(fill, { BackgroundColor3 = "accentMid", BorderColor3 = function() return getDarkerColor(C.accentMid) end })

		local hideBorderRight = Instance.new("Frame")
		hideBorderRight.BackgroundColor3 = C.accentMid
		hideBorderRight.BorderSizePixel = 0
		hideBorderRight.Position = UDim2.new(1, 0, 0, 0)
		hideBorderRight.Size = UDim2.new(0, 1, 1, 0)
		hideBorderRight.ZIndex = 8
		hideBorderRight.Parent = fill
		addToRegistry(hideBorderRight, { BackgroundColor3 = "accentMid" })

		local displayLabel = Instance.new("TextLabel")
		displayLabel.Size = UDim2.new(1, 0, 1, 0)
		displayLabel.BackgroundTransparency = 1
		displayLabel.Font = FONT_REG
		displayLabel.TextSize = 14
		displayLabel.TextColor3 = C.textBright
		displayLabel.Text = ""
		displayLabel.ZIndex = 9
		displayLabel.Parent = inner

		local function round(value)
			if slider.Rounding == 0 then return math.floor(value) end
			return tonumber(string.format("%." .. slider.Rounding .. "f", value))
		end

		function slider:Display()
			local suffix = info.Suffix or ""
			if info.Compact then
				displayLabel.Text = (info.Text or "") .. ": " .. slider.Value .. suffix
			elseif info.HideMax then
				displayLabel.Text = tostring(slider.Value) .. suffix
			else
				displayLabel.Text = string.format("%s/%s", slider.Value .. suffix, slider.Max .. suffix)
			end

			local x = math.ceil(mapValue(slider.Value, slider.Min, slider.Max, 0, slider.MaxSize))
			fill.Size = UDim2.new(0, x, 1, 0)
			hideBorderRight.Visible = not (x == slider.MaxSize or x == 0)
		end

		function slider:SetValue(str)
			local num = tonumber(str)
			if not num then return end
			num = math.clamp(num, slider.Min, slider.Max)
			slider.Value = num
			slider:Display()
			if slider.Callback then pcall(slider.Callback, slider.Value) end
			if slider.Changed then pcall(slider.Changed, slider.Value) end
		end

		function slider:OnChanged(fn)
			slider.Changed = fn
			fn(slider.Value)
		end

		local mouse = Players.LocalPlayer:GetMouse()
		inner.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				local mPos = mouse.X
				local gPos = fill.Size.X.Offset
				local diff = mPos - (fill.AbsolutePosition.X + gPos)
				while UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
					local nMPos = mouse.X
					local nX = math.clamp(gPos + (nMPos - mPos) + diff, 0, slider.MaxSize)
					local nValue = round(mapValue(nX, 0, slider.MaxSize, slider.Min, slider.Max))
					local oldValue = slider.Value
					slider.Value = nValue
					slider:Display()
					if nValue ~= oldValue then
						if slider.Callback then pcall(slider.Callback, slider.Value) end
						if slider.Changed then pcall(slider.Changed, slider.Value) end
					end
					RunService.RenderStepped:Wait()
				end
			end
		end)

		outer.MouseEnter:Connect(function() tw(outer, { BorderColor3 = C.accentMid }, SNAP):Play() end)
		outer.MouseLeave:Connect(function() tw(outer, { BorderColor3 = C.black }, SNAP):Play() end)

		slider:Display()
		groupbox:AddBlank(6)
		groupbox:Resize()
		return slider
	end

	function Funcs:AddDropdown(info)
		info = info or {}
		local groupbox = self
		local container = groupbox.Container

		if info.SpecialType == "Player" then
			info.Values = {}
			for _, p in ipairs(Players:GetPlayers()) do
				table.insert(info.Values, p.Name)
			end
			table.sort(info.Values)
			info.AllowNull = true
		elseif info.SpecialType == "Team" then
			info.Values = {}
			for _, t in ipairs(Teams:GetTeams()) do
				table.insert(info.Values, t.Name)
			end
			table.sort(info.Values)
			info.AllowNull = true
		end

		local dropdown = {
			Values = info.Values or {},
			Value = info.Multi and {},
			Multi = info.Multi,
			Callback = info.Callback or function() end,
		}

		if not info.Compact then
			local dropdownLabel = Instance.new("TextLabel")
			dropdownLabel.Size = UDim2.new(1, 0, 0, 10)
			dropdownLabel.BackgroundTransparency = 1
			dropdownLabel.Font = FONT_REG
			dropdownLabel.TextSize = 14
			dropdownLabel.TextColor3 = C.textBright
			dropdownLabel.Text = info.Text or ""
			dropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
			dropdownLabel.TextYAlignment = Enum.TextYAlignment.Bottom
			dropdownLabel.ZIndex = 5
			dropdownLabel.Parent = container
			groupbox:AddBlank(3)
		end

		local outer = Instance.new("Frame")
		outer.BackgroundColor3 = C.black
		outer.BorderColor3 = C.black
		outer.Size = UDim2.new(1, -4, 0, 20)
		outer.ZIndex = 5
		outer.Parent = container

		local inner = Instance.new("Frame")
		inner.BackgroundColor3 = C.bgRaised
		inner.BorderColor3 = C.borderHard
		inner.BorderMode = Enum.BorderMode.Inset
		inner.Size = UDim2.new(1, 0, 1, 0)
		inner.ZIndex = 6
		inner.Parent = outer
		addToRegistry(inner, { BackgroundColor3 = "bgRaised", BorderColor3 = "borderHard" })

		local btnGrad = Instance.new("UIGradient")
		btnGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
		})
		btnGrad.Rotation = 90
		btnGrad.Parent = inner

		local arrow = Instance.new("ImageLabel")
		arrow.AnchorPoint = Vector2.new(0, 0.5)
		arrow.BackgroundTransparency = 1
		arrow.Position = UDim2.new(1, -16, 0.5, 0)
		arrow.Size = UDim2.new(0, 12, 0, 12)
		arrow.Image = "http://www.roblox.com/asset/?id=6282522798"
		arrow.ZIndex = 8
		arrow.Parent = inner

		local itemList = Instance.new("TextLabel")
		itemList.Position = UDim2.new(0, 5, 0, 0)
		itemList.Size = UDim2.new(1, -5, 1, 0)
		itemList.BackgroundTransparency = 1
		itemList.Font = FONT_REG
		itemList.TextSize = 14
		itemList.TextColor3 = C.textBright
		itemList.Text = "--"
		itemList.TextXAlignment = Enum.TextXAlignment.Left
		itemList.TextWrapped = true
		itemList.ZIndex = 7
		itemList.Parent = inner

		local MAX_ITEMS = 8
		local ListOuter = Instance.new("Frame")
		ListOuter.BackgroundColor3 = C.black
		ListOuter.BorderColor3 = C.black
		ListOuter.ZIndex = 20
		ListOuter.Visible = false
		ListOuter.Parent = groupbox._parentGui or container

		outer:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
			ListOuter.Position = UDim2.fromOffset(outer.AbsolutePosition.X, outer.AbsolutePosition.Y + outer.Size.Y.Offset + 1)
		end)

		ListOuter.Size = UDim2.fromOffset(outer.AbsoluteSize.X, MAX_ITEMS * 20 + 2)

		local ListInner = Instance.new("Frame")
		ListInner.BackgroundColor3 = C.bgRaised
		ListInner.BorderColor3 = C.borderHard
		ListInner.BorderMode = Enum.BorderMode.Inset
		ListInner.BorderSizePixel = 0
		ListInner.Size = UDim2.new(1, 0, 1, 0)
		ListInner.ZIndex = 21
		ListInner.Parent = ListOuter
		addToRegistry(ListInner, { BackgroundColor3 = "bgRaised", BorderColor3 = "borderHard" })

		local Scrolling = Instance.new("ScrollingFrame")
		Scrolling.BackgroundTransparency = 1
		Scrolling.BorderSizePixel = 0
		Scrolling.CanvasSize = UDim2.new(0, 0, 0, 0)
		Scrolling.Size = UDim2.new(1, 0, 1, 0)
		Scrolling.ZIndex = 21
		Scrolling.Parent = ListInner
		Scrolling.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
		Scrolling.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
		Scrolling.ScrollBarThickness = 3
		Scrolling.ScrollBarImageColor3 = C.accentMid
		addToRegistry(Scrolling, { ScrollBarImageColor3 = "accentMid" })

		local Layout = Instance.new("UIListLayout")
		Layout.Padding = UDim.new(0, 0)
		Layout.FillDirection = Enum.FillDirection.Vertical
		Layout.SortOrder = Enum.SortOrder.LayoutOrder
		Layout.Parent = Scrolling

		function dropdown:Display()
			local str = ""
			if info.Multi then
				for _, value in ipairs(dropdown.Values) do
					if dropdown.Value[value] then
						str = str .. value .. ", "
					end
				end
				str = str:sub(1, #str - 2)
			else
				str = dropdown.Value or ""
			end
			itemList.Text = (str == "" and "--" or str)
		end

		function dropdown:GetActiveValues()
			if info.Multi then
				local t = {}
				for value, bool in pairs(dropdown.Value) do
					table.insert(t, value)
				end
				return t
			else
				return dropdown.Value and 1 or 0
			end
		end

		function dropdown:BuildDropdownList()
			for _, elem in ipairs(Scrolling:GetChildren()) do
				if not elem:IsA("UIListLayout") then elem:Destroy() end
			end

			local count = 0
			for _, value in ipairs(dropdown.Values) do
				count = count + 1
				local button = Instance.new("Frame")
				button.BackgroundColor3 = C.bgRaised
				button.BorderColor3 = C.borderHard
				button.BorderMode = Enum.BorderMode.Middle
				button.Size = UDim2.new(1, -1, 0, 20)
				button.ZIndex = 23
				button.Active = true
				button.Parent = Scrolling
				addToRegistry(button, { BackgroundColor3 = "bgRaised", BorderColor3 = "borderHard" })

				local buttonLabel = Instance.new("TextLabel")
				buttonLabel.Active = false
				buttonLabel.Size = UDim2.new(1, -6, 1, 0)
				buttonLabel.Position = UDim2.new(0, 6, 0, 0)
				buttonLabel.BackgroundTransparency = 1
				buttonLabel.Font = FONT_REG
				buttonLabel.TextSize = 14
				buttonLabel.TextColor3 = C.textBright
				buttonLabel.Text = value
				buttonLabel.TextXAlignment = Enum.TextXAlignment.Left
				buttonLabel.ZIndex = 25
				buttonLabel.Parent = button

				local selected
				if info.Multi then
					selected = dropdown.Value[value]
				else
					selected = dropdown.Value == value
				end

			addToRegistry(buttonLabel, { TextColor3 = "textBright" })

			local function updateButton()
				if info.Multi then
					selected = dropdown.Value[value]
				else
					selected = dropdown.Value == value
				end
				if selected then
					buttonLabel.TextColor3 = C.accentMid
					RegistryMap[buttonLabel].Properties.TextColor3 = "accentMid"
				else
					buttonLabel.TextColor3 = C.textBright
					RegistryMap[buttonLabel].Properties.TextColor3 = "textBright"
				end
			end

			button.InputBegan:Connect(function(inp)
				if inp.UserInputType == Enum.UserInputType.MouseButton1 then
					local try = not selected
					if dropdown:GetActiveValues() == 1 and not try and not info.AllowNull then
						-- Do nothing
						else
							if info.Multi then
								selected = try
								if selected then
									dropdown.Value[value] = true
								else
									dropdown.Value[value] = nil
								end
							else
								selected = try
								if selected then
									dropdown.Value = value
								else
									dropdown.Value = nil
								end
								for _, otherBtn in ipairs(Scrolling:GetChildren()) do
									if otherBtn:IsA("Frame") and otherBtn ~= button then
										-- Update other buttons (simplified)
									end
								end
							end
							updateButton()
							dropdown:Display()
							if dropdown.Callback then pcall(dropdown.Callback, dropdown.Value) end
							if dropdown.Changed then pcall(dropdown.Changed, dropdown.Value) end
						end
					end
				end)

				button.MouseEnter:Connect(function()
					if not selected then
						tw(button, { BorderColor3 = C.accentMid, ZIndex = 24 }, SNAP):Play()
					end
				end)
				button.MouseLeave:Connect(function()
					if not selected then
						tw(button, { BorderColor3 = C.borderHard, ZIndex = 23 }, SNAP):Play()
					end
				end)

				updateButton()
			end

			Scrolling.CanvasSize = UDim2.fromOffset(0, (count * 20) + 1)
			local y = math.clamp(count * 20, 0, MAX_ITEMS * 20) + 1
			ListOuter.Size = UDim2.fromOffset(outer.AbsoluteSize.X, y)
		end

		function dropdown:SetValues(newValues)
			if newValues then dropdown.Values = newValues end
			dropdown:BuildDropdownList()
		end

		function dropdown:SetValue(val)
			if dropdown.Multi then
				local nTable = {}
				for value, bool in pairs(val) do
					if table.find(dropdown.Values, value) then
						nTable[value] = true
					end
				end
				dropdown.Value = nTable
			else
				if not val then
					dropdown.Value = nil
				elseif table.find(dropdown.Values, val) then
					dropdown.Value = val
				end
			end
			dropdown:BuildDropdownList()
			if dropdown.Callback then pcall(dropdown.Callback, dropdown.Value) end
			if dropdown.Changed then pcall(dropdown.Changed, dropdown.Value) end
		end

		function dropdown:OnChanged(fn)
			dropdown.Changed = fn
			fn(dropdown.Value)
		end

		outer.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				if ListOuter.Visible then
					ListOuter.Visible = false
					arrow.Rotation = 0
				else
					ListOuter.Visible = true
					arrow.Rotation = 180
				end
			end
		end)

		UIS.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 and ListOuter.Visible then
				local absPos = ListOuter.AbsolutePosition
				local absSize = ListOuter.AbsoluteSize
				local mouse = Players.LocalPlayer:GetMouse()
				if mouse.X < absPos.X or mouse.X > absPos.X + absSize.X
					or mouse.Y < absPos.Y - 20 or mouse.Y > absPos.Y + absSize.Y then
					ListOuter.Visible = false
					arrow.Rotation = 0
				end
			end
		end)

		outer.MouseEnter:Connect(function() tw(outer, { BorderColor3 = C.accentMid }, SNAP):Play() end)
		outer.MouseLeave:Connect(function() tw(outer, { BorderColor3 = C.black }, SNAP):Play() end)

		dropdown:BuildDropdownList()
		dropdown:Display()

		if info.Default then
			if info.Multi and type(info.Default) == "table" then
				for _, v in ipairs(info.Default) do
					if table.find(dropdown.Values, v) then
						dropdown.Value[v] = true
					end
				end
			elseif not info.Multi and type(info.Default) == "string" then
				if table.find(dropdown.Values, info.Default) then
					dropdown.Value = info.Default
				end
			end
			dropdown:BuildDropdownList()
			dropdown:Display()
		end

		groupbox:AddBlank(5)
		groupbox:Resize()
		return dropdown
	end

	BaseGroupbox.__index = Funcs
end

-- ============================================================
--  TAB OBJECT FACTORY (Linoria-style with left/right groupboxes)
-- ============================================================
local function makeTabObj(panel, parentGui)
	local tabObj = {}
	tabObj._panel = panel
	tabObj._parentGui = parentGui
	tabObj.Groupboxes = {}

	-- Create left and right scrolling frames
	local LeftSide = Instance.new("ScrollingFrame")
	LeftSide.BackgroundTransparency = 1
	LeftSide.BorderSizePixel = 0
	LeftSide.Position = UDim2.new(0, 8, 0, 8)
	LeftSide.Size = UDim2.new(0.5, -12, 1, -16)
	LeftSide.CanvasSize = UDim2.new(0, 0, 0, 0)
	LeftSide.BottomImage = ""
	LeftSide.TopImage = ""
	LeftSide.ScrollBarThickness = 0
	LeftSide.ZIndex = 2
	LeftSide.Parent = panel

	local RightSide = Instance.new("ScrollingFrame")
	RightSide.BackgroundTransparency = 1
	RightSide.BorderSizePixel = 0
	RightSide.Position = UDim2.new(0.5, 4, 0, 8)
	RightSide.Size = UDim2.new(0.5, -12, 1, -16)
	RightSide.CanvasSize = UDim2.new(0, 0, 0, 0)
	RightSide.BottomImage = ""
	RightSide.TopImage = ""
	RightSide.ScrollBarThickness = 0
	RightSide.ZIndex = 2
	RightSide.Parent = panel

	local LeftLayout = Instance.new("UIListLayout")
	LeftLayout.Padding = UDim.new(0, 8)
	LeftLayout.FillDirection = Enum.FillDirection.Vertical
	LeftLayout.SortOrder = Enum.SortOrder.LayoutOrder
	LeftLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	LeftLayout.Parent = LeftSide

	local RightLayout = Instance.new("UIListLayout")
	RightLayout.Padding = UDim.new(0, 8)
	RightLayout.FillDirection = Enum.FillDirection.Vertical
	RightLayout.SortOrder = Enum.SortOrder.LayoutOrder
	RightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	RightLayout.Parent = RightSide

	LeftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		LeftSide.CanvasSize = UDim2.fromOffset(0, LeftLayout.AbsoluteContentSize.Y)
	end)
	RightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		RightSide.CanvasSize = UDim2.fromOffset(0, RightLayout.AbsoluteContentSize.Y)
	end)

	local function createGroupbox(name, side)
		local groupbox = {}
		groupbox._parentGui = parentGui

		local boxOuter = Instance.new("Frame")
		boxOuter.BackgroundColor3 = C.bgDeep
		boxOuter.BorderColor3 = C.borderHard
		boxOuter.BorderMode = Enum.BorderMode.Inset
		boxOuter.Size = UDim2.new(1, 0, 0, 200)
		boxOuter.ZIndex = 2
		boxOuter.Parent = (side == 1) and LeftSide or RightSide
		addToRegistry(boxOuter, { BackgroundColor3 = "bgDeep", BorderColor3 = "borderHard" })

		local boxInner = Instance.new("Frame")
		boxInner.BackgroundColor3 = C.bgDeep
		boxInner.BorderColor3 = C.black
		boxInner.Size = UDim2.new(1, -2, 1, -2)
		boxInner.Position = UDim2.new(0, 1, 0, 1)
		boxInner.ZIndex = 4
		boxInner.Parent = boxOuter
		addToRegistry(boxInner, { BackgroundColor3 = "bgDeep" })

		local highlight = Instance.new("Frame")
		highlight.BackgroundColor3 = C.accentMid
		highlight.BorderSizePixel = 0
		highlight.Size = UDim2.new(1, 0, 0, 2)
		highlight.ZIndex = 5
		highlight.Parent = boxInner
		addToRegistry(highlight, { BackgroundColor3 = "accentMid" })

		local groupboxLabel = Instance.new("TextLabel")
		groupboxLabel.Size = UDim2.new(1, 0, 0, 18)
		groupboxLabel.Position = UDim2.new(0, 4, 0, 2)
		groupboxLabel.BackgroundTransparency = 1
		groupboxLabel.Font = FONT_REG
		groupboxLabel.TextSize = 14
		groupboxLabel.TextColor3 = C.textBright
		groupboxLabel.Text = name
		groupboxLabel.TextXAlignment = Enum.TextXAlignment.Left
		groupboxLabel.ZIndex = 5
		groupboxLabel.Parent = boxInner

		local container = Instance.new("Frame")
		container.BackgroundTransparency = 1
		container.Position = UDim2.new(0, 4, 0, 20)
		container.Size = UDim2.new(1, -4, 1, -20)
		container.ZIndex = 1
		container.Parent = boxInner

		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Vertical
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = container

		function groupbox:Resize()
			local size = 0
			for _, elem in ipairs(container:GetChildren()) do
				if not elem:IsA("UIListLayout") and elem.Visible then
					size = size + elem.Size.Y.Offset
				end
			end
			boxOuter.Size = UDim2.new(1, 0, 0, 20 + size + 2 + 2)
		end

		groupbox.Container = container
		setmetatable(groupbox, BaseGroupbox)

		groupbox:AddBlank(3)
		groupbox:Resize()

		return groupbox
	end

	function tabObj:AddLeftGroupbox(name)
		local gb = createGroupbox(name, 1)
		tabObj.Groupboxes[name] = gb
		return gb
	end

	function tabObj:AddRightGroupbox(name)
		local gb = createGroupbox(name, 2)
		tabObj.Groupboxes[name] = gb
		return gb
	end

	return tabObj
end

-- ============================================================
--  PUBLIC API
-- ============================================================
local OnyxiteLib = {}

function OnyxiteLib.new(config)
	local win = {}
	win._tabPanels = {}
	win._tabButtons = {}
	win._activeTab = nil
	win.Options = {}

	local WIN_W      = config.Width  or 550
	local WIN_H      = config.Height or 600
	local BORDER     = 5
	local TITLEBAR_H = 36
	local SIDEBAR_OW = 200
	local SIDEBAR_CW = 50
	local WIN_MIN_W  = 500
	local WIN_MIN_H  = 400
	local PROFILE_H  = 66
	local sidebarOpen = true
	local menuVisible = true

	local player    = Players.LocalPlayer
	local guiParent = player:WaitForChild("PlayerGui")
	local gui = Instance.new("ScreenGui")
	gui.Name = "OnyxiteGUI"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = guiParent

	local outerFrame = Instance.new("Frame")
	outerFrame.Name = "WindowFrame"
	outerFrame.Size = UDim2.new(0, WIN_W+BORDER*2, 0, WIN_H+BORDER*2)
	outerFrame.Position = UDim2.new(0.5, -(WIN_W+BORDER*2)/2, 0.5, -(WIN_H+BORDER*2)/2)
	outerFrame.BackgroundColor3 = C.shellOuter
	outerFrame.BorderSizePixel = 0
	outerFrame.ZIndex = 1
	outerFrame.Parent = gui
	corner(outerFrame, 3)
	gradientN(outerFrame, {{0,Color3.fromRGB(4,4,4)},{0.3,Color3.fromRGB(18,18,18)},{0.7,Color3.fromRGB(18,18,18)},{1,Color3.fromRGB(4,4,4)}}, 120)
	stroke(outerFrame, C.shellBorder, 1, 0.3)

	win._outerFrame = outerFrame
	win._gui = gui

	local main = Instance.new("Frame")
	main.Name = "Main"
	main.Size = UDim2.new(1,-BORDER*2,1,-BORDER*2)
	main.Position = UDim2.new(0,BORDER,0,BORDER)
	main.BackgroundColor3 = C.bgMain
	main.BorderSizePixel = 0
	main.ZIndex = 2
	main.ClipsDescendants = false
	main.Parent = outerFrame
	corner(main, 2)
	main.BackgroundTransparency = 0

	local topAccent = Instance.new("Frame")
	topAccent.Size = UDim2.new(0,64,0,1)
	topAccent.BackgroundColor3 = C.accentDim
	topAccent.BorderSizePixel = 0
	topAccent.ZIndex = 6
	topAccent.Parent = main
	corner(topAccent, 1)
	do local g = Instance.new("UIGradient"); g.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.2),NumberSequenceKeypoint.new(1,1)}); g.Rotation = 0; g.Parent = topAccent end

	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1,0,0,TITLEBAR_H)
	titleBar.BackgroundColor3 = C.titleBg
	titleBar.BorderSizePixel = 0
	titleBar.BorderColor3 = C.borderHard
	titleBar.ZIndex = 4
	titleBar.Parent = main
	corner(titleBar, 2)
	local tSep = Instance.new("Frame")
	tSep.Size = UDim2.new(1,0,0,1)
	tSep.Position = UDim2.new(0,0,1,-1)
	tSep.BackgroundColor3 = C.borderSoft
	tSep.BorderSizePixel = 0
	tSep.ZIndex = 5
	tSep.Parent = titleBar

	local sDot = Instance.new("Frame")
	sDot.Size = UDim2.new(0,5,0,5)
	sDot.Position = UDim2.new(0,14,0.5,-2)
	sDot.BackgroundColor3 = C.accentDim
	sDot.BorderSizePixel = 0
	sDot.ZIndex = 6
	sDot.Parent = titleBar
	corner(sDot, 3)

	local tLbl = Instance.new("TextLabel")
	tLbl.Text = config.Title or "Onyxite"
	tLbl.Font = FONT_BOLD
	tLbl.TextSize = 14
	tLbl.TextColor3 = C.textBright
	tLbl.BackgroundTransparency = 1
	tLbl.Size = UDim2.new(0,140,1,0)
	tLbl.Position = UDim2.new(0,26,0,0)
	tLbl.TextXAlignment = Enum.TextXAlignment.Left
	tLbl.ZIndex = 6
	tLbl.Parent = titleBar

	local vLbl = Instance.new("TextLabel")
	vLbl.Text = config.SubTitle or "v1.0"
	vLbl.Font = FONT_REG
	vLbl.TextSize = 9
	vLbl.TextColor3 = C.textDim
	vLbl.BackgroundTransparency = 1
	vLbl.Size = UDim2.new(0,200,0,12)
	vLbl.Position = UDim2.new(0,168,0.5,-6)
	vLbl.TextXAlignment = Enum.TextXAlignment.Left
	vLbl.ZIndex = 6
	vLbl.Parent = titleBar

	local function makeWinBtn(xOff, glyph, hBg, hTxt)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0,22,0,22)
		b.Position = UDim2.new(1,xOff,0.5,-11)
		b.BackgroundColor3 = Color3.fromRGB(16,16,16)
		b.BorderSizePixel = 0
		b.Text = glyph
		b.Font = FONT_BOLD
		b.TextSize = 14
		b.TextColor3 = C.textDim
		b.AutoButtonColor = false
		b.ZIndex = 8
		b.Parent = titleBar
		corner(b, 2)
		local s = stroke(b, C.borderFaint, 1, 0.3)
		b.MouseEnter:Connect(function() tw(b, {BackgroundColor3=hBg, TextColor3=hTxt}, SNAP):Play(); tw(s, {Color=hTxt, Transparency=0}, SNAP):Play() end)
		b.MouseLeave:Connect(function() tw(b, {BackgroundColor3=Color3.fromRGB(16,16,16), TextColor3=C.textDim}, SNAP):Play(); tw(s, {Color=C.borderFaint, Transparency=0.3}, SNAP):Play() end)
		b.MouseButton1Down:Connect(function() tw(b, {BackgroundColor3=C.bgPress}, SNAP):Play() end)
		return b
	end
	local closeBtn    = makeWinBtn(-30, "×", Color3.fromRGB(38,12,12), Color3.fromRGB(200,80,80))
	local minimizeBtn = makeWinBtn(-56, "−", Color3.fromRGB(28,28,20), Color3.fromRGB(200,200,120))

	-- Restore pill
	local rPill = Instance.new("TextButton")
	rPill.Size = UDim2.new(0,130,0,26)
	rPill.Position = UDim2.new(0.5,-65,0,-50)
	rPill.BackgroundColor3 = Color3.fromRGB(12,12,12)
	rPill.BorderSizePixel = 0
	rPill.Text = ""
	rPill.AutoButtonColor = false
	rPill.ZIndex = 50
	rPill.Visible = false
	rPill.Parent = gui
	corner(rPill, 13)
	stroke(rPill, C.borderHard, 1, 0.1)
	gradient(rPill, Color3.fromRGB(20,20,20), Color3.fromRGB(8,8,8), 180)
	local pDot2 = Instance.new("Frame")
	pDot2.Size = UDim2.new(0,5,0,5)
	pDot2.Position = UDim2.new(0,11,0.5,-2)
	pDot2.BackgroundColor3 = C.accentDim
	pDot2.BorderSizePixel = 0
	pDot2.ZIndex = 52
	pDot2.Parent = rPill
	corner(pDot2, 3)
	local pLbl = Instance.new("TextLabel")
	pLbl.Text = string.upper(config.Title or "ONYXITE")
	pLbl.Font = FONT_BOLD
	pLbl.TextSize = 10
	pLbl.TextColor3 = C.textMid
	pLbl.BackgroundTransparency = 1
	pLbl.Size = UDim2.new(1,-24,1,0)
	pLbl.Position = UDim2.new(0,22,0,0)
	pLbl.TextXAlignment = Enum.TextXAlignment.Left
	pLbl.ZIndex = 52
	pLbl.Parent = rPill
	rPill.MouseEnter:Connect(function() tw(rPill, {BackgroundColor3=Color3.fromRGB(22,22,22)}, SNAP):Play() end)
	rPill.MouseLeave:Connect(function() tw(rPill, {BackgroundColor3=Color3.fromRGB(12,12,12)}, SNAP):Play() end)
	local pDrag, pDS, pSP = false, nil, nil
	rPill.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then pDrag = true; pDS = inp.Position; pSP = rPill.Position end end)
	UIS.InputChanged:Connect(function(inp) if pDrag and inp.UserInputType == Enum.UserInputType.MouseMovement then local d = inp.Position - pDS; rPill.Position = UDim2.new(pSP.X.Scale, pSP.X.Offset+d.X, pSP.Y.Scale, pSP.Y.Offset+d.Y) end end)
	UIS.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then pDrag = false end end)

	-- Close dialog
	local bOver = Instance.new("Frame")
	bOver.Size = UDim2.fromScale(1,1)
	bOver.BackgroundColor3 = Color3.fromRGB(0,0,0)
	bOver.BackgroundTransparency = 1
	bOver.BorderSizePixel = 0
	bOver.ZIndex = 90
	bOver.Visible = false
	bOver.Parent = gui
	local cDlg = Instance.new("Frame")
	cDlg.Size = UDim2.new(0,300,0,158)
	cDlg.Position = UDim2.new(0.5,-150,0.5,-79)
	cDlg.BackgroundColor3 = C.dialogBg
	cDlg.BorderSizePixel = 0
	cDlg.ZIndex = 92
	cDlg.Parent = bOver
	corner(cDlg, 3)
	gradientN(cDlg, {{0,Color3.fromRGB(20,20,20)},{1,Color3.fromRGB(6,6,6)}}, 160)
	stroke(cDlg, C.borderHard, 1, 0.1)
	local dTop = Instance.new("Frame"); dTop.Size = UDim2.new(1,0,0,1); dTop.BackgroundColor3 = C.borderSoft; dTop.BorderSizePixel = 0; dTop.ZIndex = 93; dTop.Parent = cDlg
	do local g = Instance.new("UIGradient"); g.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.4),NumberSequenceKeypoint.new(0.5,0),NumberSequenceKeypoint.new(1,0.4)}); g.Rotation = 0; g.Parent = dTop end
	local dTitle = Instance.new("TextLabel")
	dTitle.Size = UDim2.new(1,-32,0,36); dTitle.Position = UDim2.new(0,22,0,8)
	dTitle.BackgroundTransparency = 1; dTitle.Font = FONT_BOLD; dTitle.TextSize = 16
	dTitle.TextColor3 = C.textBright; dTitle.TextTransparency = 1
	dTitle.Text = "CLOSE " .. string.upper(config.Title or "ONYXITE?")
	dTitle.TextXAlignment = Enum.TextXAlignment.Left; dTitle.ZIndex = 93; dTitle.Parent = cDlg
	local dMsg = Instance.new("TextLabel")
	dMsg.Size = UDim2.new(1,-32,0,44); dMsg.Position = UDim2.new(0,22,0,44)
	dMsg.BackgroundTransparency = 1; dMsg.Font = FONT_REG; dMsg.TextSize = 11
	dMsg.TextColor3 = C.textSub; dMsg.TextTransparency = 1; dMsg.TextWrapped = true
	dMsg.Text = "Are you sure you want to close the menu?\nRe-execute the script to reopen it."
	dMsg.TextXAlignment = Enum.TextXAlignment.Left; dMsg.ZIndex = 93; dMsg.Parent = cDlg
	local dDiv = Instance.new("Frame")
	dDiv.Size = UDim2.new(1,-24,0,1); dDiv.Position = UDim2.new(0,12,0,96)
	dDiv.BackgroundColor3 = C.borderFaint; dDiv.BorderSizePixel = 0; dDiv.ZIndex = 93; dDiv.Parent = cDlg
	local function mDB(x, w, t, bg, tc, sc)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0,w,0,32); b.Position = UDim2.new(0,x,1,-44)
		b.BackgroundColor3 = bg; b.BorderSizePixel = 0; b.Text = t; b.TextColor3 = tc
		b.TextTransparency = 1; b.TextSize = 11; b.Font = FONT_REG
		b.AutoButtonColor = false; b.ZIndex = 93; b.Parent = cDlg; corner(b, 2); stroke(b, sc, 1, 0.4); return b
	end
	local cancelBtn  = mDB(14,  120, "CANCEL", Color3.fromRGB(16,16,16),  C.textMid,              C.borderHard)
	local confirmBtn = mDB(148, 120, "CLOSE",  Color3.fromRGB(24,6,6),    Color3.fromRGB(190,70,70), Color3.fromRGB(100,30,30))
	cancelBtn.MouseEnter:Connect(function()  tw(cancelBtn,  {BackgroundColor3=C.bgHover, TextColor3=C.textBright}, SNAP):Play() end)
	cancelBtn.MouseLeave:Connect(function()  tw(cancelBtn,  {BackgroundColor3=Color3.fromRGB(16,16,16), TextColor3=C.textMid}, SNAP):Play() end)
	confirmBtn.MouseEnter:Connect(function() tw(confirmBtn, {BackgroundColor3=Color3.fromRGB(38,8,8)}, SNAP):Play() end)
	confirmBtn.MouseLeave:Connect(function() tw(confirmBtn, {BackgroundColor3=Color3.fromRGB(24,6,6)}, SNAP):Play() end)

	local function openDialog()
		bOver.Visible = true; tw(bOver, {BackgroundTransparency=0.55}, MED):Play()
		task.delay(0.05,  function() tw(dTitle,   {TextTransparency=0}, MED):Play() end)
		task.delay(0.12,  function() tw(dMsg,     {TextTransparency=0}, MED):Play() end)
		task.delay(0.18,  function() tw(cancelBtn,{TextTransparency=0}, MED):Play(); tw(confirmBtn,{TextTransparency=0}, MED):Play() end)
	end
	local function closeDialog()
		tw(bOver, {BackgroundTransparency=1}, MED):Play()
		tw(dTitle,    {TextTransparency=1}, FAST):Play()
		tw(dMsg,      {TextTransparency=1}, FAST):Play()
		tw(cancelBtn, {TextTransparency=1}, FAST):Play()
		tw(confirmBtn,{TextTransparency=1}, FAST):Play()
		task.delay(0.28, function() bOver.Visible = false end)
	end
	cancelBtn.MouseButton1Click:Connect(closeDialog)
	confirmBtn.MouseButton1Click:Connect(function()
		tw(bOver, {BackgroundTransparency=0}, TweenInfo.new(0.18)):Play()
		task.wait(0.22); gui:Destroy()
	end)
	closeBtn.MouseButton1Click:Connect(openDialog)

	local function minimize()
		menuVisible = false
		tw(main, {BackgroundTransparency=1}, FAST):Play()
		task.delay(0.18, function()
			outerFrame.Visible = false; main.BackgroundTransparency = 0.25
			rPill.Position = UDim2.new(0.5,-65,0,-50); rPill.Visible = true
			tw(rPill, {Position=UDim2.new(0.5,-65,0,12)}, SLOW):Play()
		end)
	end
	local function restore()
		tw(rPill, {Position=UDim2.new(rPill.Position.X.Scale, rPill.Position.X.Offset, 0, -50)}, MED):Play()
		task.delay(0.20, function() rPill.Visible = false end)
		outerFrame.Visible = true; menuVisible = true
	end
	minimizeBtn.MouseButton1Click:Connect(minimize)
	rPill.MouseButton1Click:Connect(function() if not pDrag then restore() end end)
	UIS.InputBegan:Connect(function(inp, gp)
		if gp then return end
		if inp.KeyCode == Enum.KeyCode.Insert then
			if menuVisible then minimize() else restore() end
		end
	end)

	-- Dragging
	local drag, dS, dSP = false, nil, nil
	titleBar.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then drag = true; dS = inp.Position; dSP = outerFrame.Position end end)
	UIS.InputChanged:Connect(function(inp) if drag and inp.UserInputType == Enum.UserInputType.MouseMovement then local d = inp.Position - dS; outerFrame.Position = UDim2.new(dSP.X.Scale, dSP.X.Offset+d.X, dSP.Y.Scale, dSP.Y.Offset+d.Y) end end)
	UIS.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end)

	-- Resize handle
	local rHandle = Instance.new("TextButton")
	rHandle.Size = UDim2.new(0,20,0,20); rHandle.Position = UDim2.new(1,-18,1,-18)
	rHandle.BackgroundColor3 = Color3.fromRGB(30,30,30); rHandle.BackgroundTransparency = 0.6
	rHandle.BorderSizePixel = 0; rHandle.Text = ""; rHandle.AutoButtonColor = false; rHandle.ZIndex = 20; rHandle.Parent = main; corner(rHandle, 2)
	local rGlyph = Instance.new("TextLabel")
	rGlyph.Text = "↘"; rGlyph.Font = FONT_BOLD; rGlyph.TextSize = 16
	rGlyph.TextColor3 = C.textDim; rGlyph.BackgroundTransparency = 1; rGlyph.Size = UDim2.fromScale(1,1); rGlyph.ZIndex = 21; rGlyph.Parent = rHandle
	local rz, rDS, rSS = false, nil, nil
	rHandle.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then rz = true; rDS = inp.Position; rSS = outerFrame.AbsoluteSize end end)
	UIS.InputChanged:Connect(function(inp) if rz and inp.UserInputType == Enum.UserInputType.MouseMovement then local d = inp.Position - rDS; outerFrame.Size = UDim2.new(0, math.max(WIN_MIN_W, rSS.X+d.X), 0, math.max(WIN_MIN_H, rSS.Y+d.Y)) end end)
	UIS.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then rz = false end end)
	rHandle.MouseEnter:Connect(function() tw(rHandle, {BackgroundTransparency=0.3}, SNAP):Play(); tw(rGlyph, {TextColor3=C.textSub}, SNAP):Play() end)
	rHandle.MouseLeave:Connect(function() tw(rHandle, {BackgroundTransparency=0.6}, SNAP):Play(); tw(rGlyph, {TextColor3=C.textDim}, SNAP):Play() end)

	-- Sidebar
	local sidebar = Instance.new("Frame"); sidebar.Name = "Sidebar"
	sidebar.Size = UDim2.new(0,SIDEBAR_OW,1,-TITLEBAR_H); sidebar.Position = UDim2.new(0,0,0,TITLEBAR_H)
	sidebar.BackgroundColor3 = C.sidebarBg; sidebar.BorderSizePixel = 0; sidebar.BorderColor3 = C.borderHard; sidebar.ZIndex = 4; sidebar.ClipsDescendants = true; sidebar.Parent = main; corner(sidebar, 2)
	local sB = Instance.new("Frame")
	sB.Size = UDim2.new(0,1,1,0); sB.Position = UDim2.new(1,-1,0,0)
	sB.BackgroundColor3 = C.borderSoft; sB.BorderSizePixel = 0; sB.ZIndex = 5; sB.Parent = sidebar
	do local g = Instance.new("UIGradient"); g.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.7),NumberSequenceKeypoint.new(0.5,0.1),NumberSequenceKeypoint.new(1,0.7)}); g.Rotation = 90; g.Parent = sB end

	local sLA = Instance.new("Frame")
	sLA.Size = UDim2.new(1,0,0,44); sLA.BackgroundColor3 = C.bgRaised; sLA.BorderSizePixel = 0; sLA.BorderColor3 = C.borderHard; sLA.ZIndex = 5; sLA.Parent = sidebar; corner(sLA, 2)
	local sLD = Instance.new("Frame")
	sLD.Size = UDim2.new(0,5,0,5); sLD.Position = UDim2.new(0,12,0.5,-2)
	sLD.BackgroundColor3 = C.accentDim; sLD.BorderSizePixel = 0; sLD.ZIndex = 6; sLD.Parent = sLA; corner(sLD, 3)
	local sLT = Instance.new("TextLabel")
	sLT.Text = config.Creator or "Onyxite"; sLT.Font = FONT_BOLD; sLT.TextSize = 11
	sLT.TextColor3 = C.textMid; sLT.BackgroundTransparency = 1
	sLT.Size = UDim2.new(1,-24,1,0); sLT.Position = UDim2.new(0,22,0,0)
	sLT.TextXAlignment = Enum.TextXAlignment.Left; sLT.ZIndex = 6; sLT.Parent = sLA
	local sLDiv = Instance.new("Frame")
	sLDiv.Size = UDim2.new(1,0,0,1); sLDiv.Position = UDim2.new(0,0,1,-1)
	sLDiv.BackgroundColor3 = C.borderFaint; sLDiv.BorderSizePixel = 0; sLDiv.ZIndex = 6; sLDiv.Parent = sLA

	local sTBtn = Instance.new("TextButton")
	sTBtn.Size = UDim2.new(1,0,0,26); sTBtn.Position = UDim2.new(0,0,1,-(PROFILE_H+26))
	sTBtn.BackgroundColor3 = Color3.fromRGB(10,10,10); sTBtn.BorderSizePixel = 0
	sTBtn.Text = "◀"; sTBtn.Font = FONT_BOLD; sTBtn.TextSize = 10
	sTBtn.TextColor3 = C.textDim; sTBtn.AutoButtonColor = false; sTBtn.ZIndex = 7; sTBtn.Parent = sidebar
	local sTDiv = Instance.new("Frame")
	sTDiv.Size = UDim2.new(1,0,0,1); sTDiv.BackgroundColor3 = C.borderFaint; sTDiv.BorderSizePixel = 0; sTDiv.ZIndex = 6; sTDiv.Parent = sTBtn
	sTBtn.MouseEnter:Connect(function() tw(sTBtn, {BackgroundColor3=Color3.fromRGB(18,18,18), TextColor3=C.textSub}, SNAP):Play() end)
	sTBtn.MouseLeave:Connect(function() tw(sTBtn, {BackgroundColor3=Color3.fromRGB(10,10,10), TextColor3=C.textDim}, SNAP):Play() end)

	local profileCard = Instance.new("Frame"); profileCard.Name = "ProfileCard"
	profileCard.Size = UDim2.new(1,0,0,PROFILE_H); profileCard.Position = UDim2.new(0,0,1,-PROFILE_H)
	profileCard.BackgroundColor3 = C.profileBg; profileCard.BorderSizePixel = 0; profileCard.ZIndex = 6; profileCard.Parent = sidebar; corner(profileCard, 2)
	gradientN(profileCard, {{0,Color3.fromRGB(18,18,18)},{0.5,Color3.fromRGB(10,10,10)},{1,Color3.fromRGB(5,5,5)}}, 180)
	local profLine = Instance.new("Frame")
	profLine.Size = UDim2.new(1,0,0,1); profLine.BackgroundColor3 = C.profileLine; profLine.BorderSizePixel = 0; profLine.ZIndex = 7; profLine.Parent = profileCard
	do local g = Instance.new("UIGradient"); g.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.5),NumberSequenceKeypoint.new(0.5,0),NumberSequenceKeypoint.new(1,0.5)}); g.Rotation = 0; g.Parent = profLine end

	local avatarFrame = Instance.new("Frame")
	avatarFrame.Size = UDim2.new(0,40,0,40); avatarFrame.Position = UDim2.new(0,12,0.5,-20)
	avatarFrame.BackgroundColor3 = Color3.fromRGB(22,22,22); avatarFrame.BorderSizePixel = 0; avatarFrame.ZIndex = 8; avatarFrame.Parent = profileCard; corner(avatarFrame, 5)
	stroke(avatarFrame, C.borderSoft, 1, 0.2)
	local avatarImg = Instance.new("ImageLabel")
	avatarImg.Size = UDim2.fromScale(1,1); avatarImg.BackgroundTransparency = 1
	avatarImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(player.UserId) .. "&w=150&h=150"
	avatarImg.ZIndex = 9; avatarImg.Parent = avatarFrame; corner(avatarImg, 5)

	local profName = Instance.new("TextLabel")
	profName.Size = UDim2.new(1,-62,0,18); profName.Position = UDim2.new(0,58,0,12)
	profName.BackgroundTransparency = 1; profName.Font = FONT_BOLD; profName.TextSize = 13; profName.TextColor3 = C.textBright
	profName.TextXAlignment = Enum.TextXAlignment.Left; profName.TextTruncate = Enum.TextTruncate.AtEnd; profName.ZIndex = 8; profName.Parent = profileCard
	profName.Text = player.DisplayName

	local profUser = Instance.new("TextLabel")
	profUser.Size = UDim2.new(1,-62,0,14); profUser.Position = UDim2.new(0,58,0,32)
	profUser.BackgroundTransparency = 1; profUser.Font = FONT_REG; profUser.TextSize = 11; profUser.TextColor3 = C.textSub
	profUser.TextXAlignment = Enum.TextXAlignment.Left; profUser.TextTruncate = Enum.TextTruncate.AtEnd; profUser.ZIndex = 8; profUser.Parent = profileCard
	profUser.Text = "@" .. player.Name
	player:GetPropertyChangedSignal("DisplayName"):Connect(function() profName.Text = player.DisplayName end)

	local cArea = Instance.new("Frame"); cArea.Name = "ContentArea"
	cArea.Size = UDim2.new(1,-(SIDEBAR_OW+1),1,-TITLEBAR_H); cArea.Position = UDim2.new(0,SIDEBAR_OW+1,0,TITLEBAR_H)
	cArea.BackgroundTransparency = 1; cArea.BorderSizePixel = 0; cArea.ZIndex = 2; cArea.Parent = main

	local tabSelector = Instance.new("Frame")
	tabSelector.Size = UDim2.new(0,2,0,16)
	tabSelector.BackgroundColor3 = C.accentMid; tabSelector.BorderSizePixel = 0; tabSelector.ZIndex = 8; tabSelector.Parent = sidebar; corner(tabSelector, 1)

	local TAB_H = 38
	local function showTab(name)
		for tabName, p in pairs(win._tabPanels) do
			if p.Visible and tabName ~= name then
				p.Visible = false
			end
		end
		local newPanel = win._tabPanels[name]
		if newPanel then
			newPanel.Visible = true
		end
		for _, d in ipairs(win._tabButtons) do
			local active = d.name == name
			if active then
				tw(d.btn, {BackgroundColor3=C.bgMain, BorderColor3=C.accentMid}, MED):Play()
			else
				tw(d.btn, {BackgroundColor3=C.bgRaised, BorderColor3=C.borderHard}, FAST):Play()
			end
		end
		win._activeTab = name
	end

	local function setSidebar(open)
		sidebarOpen = open; local w = open and SIDEBAR_OW or SIDEBAR_CW
		tw(sidebar, {Size=UDim2.new(0,w,1,-TITLEBAR_H)}, MED):Play()
		tw(cArea, {Size=UDim2.new(1,-(w+1),1,-TITLEBAR_H), Position=UDim2.new(0,w+1,0,TITLEBAR_H)}, MED):Play()
		sTBtn.Text = open and "◀" or "▶"
		for _, d in ipairs(win._tabButtons) do tw(d.lbl, {TextTransparency=open and 0 or 1}, MED):Play() end
		tw(sLT,        {TextTransparency=open and 0 or 1}, MED):Play()
		tw(profName,   {TextTransparency=open and 0 or 1}, MED):Play()
		tw(profUser,   {TextTransparency=open and 0 or 1}, MED):Play()
		tw(avatarFrame,{BackgroundTransparency=open and 0 or 1}, MED):Play()
		tw(avatarImg,  {ImageTransparency=open and 0 or 1},      MED):Play()
	end
	sTBtn.MouseButton1Click:Connect(function() setSidebar(not sidebarOpen) end)

	local tabDefs = config.Tabs or {}
	if #tabDefs > 0 then win._activeTab = tabDefs[1].Name end

	for i, def in ipairs(tabDefs) do
		local yPos = 44 + (i-1) * TAB_H
		local panel = Instance.new("Frame")
		panel.Size = UDim2.fromScale(1,1)
		panel.BackgroundColor3 = C.bgRaised
		panel.BorderColor3 = C.borderHard
		panel.BorderMode = Enum.BorderMode.Inset
		panel.Visible = false
		panel.ZIndex = 2
		panel.Parent = cArea
		win._tabPanels[def.Name] = panel

		local btn = Instance.new("Frame"); btn.Name = def.Name .. "Tab"
		btn.Size = UDim2.new(1,0,0,TAB_H); btn.Position = UDim2.new(0,0,0,yPos)
		btn.BackgroundColor3 = C.bgRaised
		btn.BorderColor3 = C.borderHard; btn.BorderSizePixel = 1; btn.ZIndex = 6; btn.Parent = sidebar; corner(btn, 2)

		local iL = Instance.new("TextLabel")
		iL.Text = def.Icon or "·"; iL.Font = FONT_REG; iL.TextSize = 14
		iL.TextColor3 = C.textBright
		iL.BackgroundTransparency = 1; iL.Size = UDim2.new(0,8,1,0); iL.Position = UDim2.new(0,8,0,0)
		iL.TextXAlignment = Enum.TextXAlignment.Left; iL.ZIndex = 7; iL.Parent = btn; addToRegistry(iL, {TextColor3 = "textBright"})

		local lbl = Instance.new("TextLabel")
		lbl.Text = def.Name; lbl.Font = FONT_REG; lbl.TextSize = 12
		lbl.TextColor3 = C.textBright
		lbl.TextTransparency = sidebarOpen and 0 or 1; lbl.BackgroundTransparency = 1
		lbl.Size = UDim2.new(1,-20,1,0); lbl.Position = UDim2.new(0,20,0,0)
		lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 7; lbl.Parent = btn; addToRegistry(lbl, {TextColor3 = "textBright"})

		local data = {name=def.Name, btn=btn, iL=iL, lbl=lbl}
		table.insert(win._tabButtons, data)
		local cn = def.Name
		btn.InputBegan:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 then
				showTab(cn)
			end
		end)
		btn.MouseEnter:Connect(function()
			if win._activeTab ~= cn then
				tw(btn, {BackgroundColor3=C.tabHover, BorderColor3=C.accentMid}, SNAP):Play()
			end
		end)
		btn.MouseLeave:Connect(function()
			if win._activeTab ~= cn then
				tw(btn, {BackgroundColor3=C.bgRaised, BorderColor3=C.borderHard}, SNAP):Play()
			end
		end)
	end

	if win._activeTab then showTab(win._activeTab) end

	function win:GetTab(name)
		local panel = self._tabPanels[name]
		assert(panel, "Tab '" .. tostring(name) .. "' not found.")
		return makeTabObj(panel, gui)
	end

	return win
end

return OnyxiteLib
