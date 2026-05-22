-- onyxlibrary.lua  —  Black & White edition  (fixed + 1.25x scale + image bg)
-- Changes:
--   • Checkbox now supports color picker (same swatch button as Dropdown).
--   • Background is now a tiled mirrored image (assetId hardcoded or passed via config.BackgroundImage).
--   • buildBackground called automatically inside OnyxiteLib.new.
--   • main panel made semi-transparent so bg shows through.

local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")

-- ============================================================
--  PALETTE  —  black / white / gray only
-- ============================================================
local C = {
	shellOuter   = Color3.fromRGB(8,   8,   8),
	shellBorder  = Color3.fromRGB(55,  55,  55),
	bgMain       = Color3.fromRGB(10,  10,  10),
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
}

-- ============================================================
--  TWEEN PRESETS
-- ============================================================
local FONT_REG  = Enum.Font.Code
local FONT_BOLD = Enum.Font.Code
local FONT_SCI  = Enum.Font.SciFi

local SNAP   = TweenInfo.new(0.08, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local FAST   = TweenInfo.new(0.15, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local MED    = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local SLOW   = TweenInfo.new(0.40, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local SPRING = TweenInfo.new(0.30, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)

local ITEM_H = 21

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

-- ============================================================
--  ARG NORMALISER
-- ============================================================
local function normaliseDropArgs(a1, a2, a3, a4, a5, a6, a7, a8, a9)
	if type(a1) == "string" and type(a2) == "string" then
		return a1, a2, a3, a4, a5, a6, a7, a8, a9
	else
		return nil, a1, a2, a3, a4, a5, a6, a7, a8
	end
end

local function normalisePaired(a1,a2,a3,a4,a5,a6,a7,a8)
	if type(a1)=="string" and type(a2)=="string" and type(a3)=="string" then
		return a1,a2,a3,a4,a5,a6,a7,a8
	else
		return nil,nil,a1,a2,a3,a4,a5,a6
	end
end

-- ============================================================
--  ELEMENT OBJECT
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
--  COLOR PICKER  (Full HSV spectrum with RGB/Hex inputs)
-- ============================================================
local PICKER_H = 280

local function buildColorPicker(parent, defColor, defOpacity, colorCb)
	defColor   = defColor   or Color3.fromRGB(200, 200, 200)
	defOpacity = defOpacity or 1.0

	local curH, curS, curV = Color3.toHSV(defColor)
	local curOp = math.clamp(defOpacity, 0, 1)

	local panel = Instance.new("Frame")
	panel.Size = UDim2.new(1, 0, 0, PICKER_H)
	panel.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	panel.BorderSizePixel = 0; panel.ZIndex = 8
	panel.ClipsDescendants = false; panel.Visible = false
	panel.Parent = parent
	corner(panel, 3); stroke(panel, C.borderHard, 1, 0.1)

	local svBox = Instance.new("Frame")
	svBox.Size = UDim2.new(0, 180, 0, 160)
	svBox.Position = UDim2.new(0, 20, 0, 15)
	svBox.BackgroundColor3 = Color3.fromHSV(curH, 1, 1)
	svBox.BorderSizePixel = 0; svBox.ZIndex = 9
	svBox.ClipsDescendants = true; svBox.Parent = panel; corner(svBox, 4)
	
	local satOverlay = Instance.new("Frame")
	satOverlay.Size = UDim2.fromScale(1, 1)
	satOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	satOverlay.BorderSizePixel = 0; satOverlay.ZIndex = 10; satOverlay.Parent = svBox
	local satGrad = Instance.new("UIGradient")
	satGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
	})
	satGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1)
	})
	satGrad.Rotation = 0; satGrad.Parent = satOverlay

	local valOverlay = Instance.new("Frame")
	valOverlay.Size = UDim2.fromScale(1, 1)
	valOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	valOverlay.BorderSizePixel = 0; valOverlay.ZIndex = 11; valOverlay.Parent = svBox
	local valGrad = Instance.new("UIGradient")
	valGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
	})
	valGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0)
	})
	valGrad.Rotation = 90; valGrad.Parent = valOverlay
	
	local svCursor = Instance.new("Frame")
	svCursor.Size = UDim2.new(0, 12, 0, 12)
	svCursor.Position = UDim2.new(curS, -6, 1-curV, -6)
	svCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	svCursor.BorderSizePixel = 0; svCursor.ZIndex = 12; svCursor.Parent = svBox; corner(svCursor, 6)
	stroke(svCursor, Color3.fromRGB(50, 50, 50), 2, 0)

	local hueBar = Instance.new("Frame")
	hueBar.Size = UDim2.new(0, 20, 0, 160)
	hueBar.Position = UDim2.new(0, 205, 0, 15)
	hueBar.BorderSizePixel = 0; hueBar.ZIndex = 9; hueBar.Parent = panel; corner(hueBar, 4)
	
	local hueBkgd = Instance.new("Frame")
	hueBkgd.Size = UDim2.new(1, 0, 1, 0)
	hueBkgd.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	hueBkgd.BorderSizePixel = 0; hueBkgd.ZIndex = 10; hueBkgd.Parent = hueBar
	
	local hueGrad = Instance.new("UIGradient")
	hueGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0,   Color3.fromHSV(0,   1, 1)),
		ColorSequenceKeypoint.new(1/6, Color3.fromHSV(1/6, 1, 1)),
		ColorSequenceKeypoint.new(2/6, Color3.fromHSV(2/6, 1, 1)),
		ColorSequenceKeypoint.new(3/6, Color3.fromHSV(3/6, 1, 1)),
		ColorSequenceKeypoint.new(4/6, Color3.fromHSV(4/6, 1, 1)),
		ColorSequenceKeypoint.new(5/6, Color3.fromHSV(5/6, 1, 1)),
		ColorSequenceKeypoint.new(1,   Color3.fromHSV(1,   1, 1))
	})
	hueGrad.Rotation = 90; hueGrad.Parent = hueBkgd
	
	local hueCursor = Instance.new("Frame")
	hueCursor.Size = UDim2.new(1, 0, 0, 6)
	hueCursor.Position = UDim2.new(0, 0, curH, -3)
	hueCursor.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	hueCursor.BorderSizePixel = 0; hueCursor.ZIndex = 13; hueCursor.Parent = hueBar

	local opTrack = Instance.new("Frame")
	opTrack.Size = UDim2.new(0, 20, 0, 160)
	opTrack.Position = UDim2.new(0, 230, 0, 15)
	opTrack.BorderSizePixel = 0; opTrack.ZIndex = 9; opTrack.Parent = panel; corner(opTrack, 4)
	
	local opBkgd = Instance.new("ImageLabel")
	opBkgd.Image = "http://www.roblox.com/asset/?id=14204231522"
	opBkgd.ImageTransparency = 0.45
	opBkgd.ScaleType = Enum.ScaleType.Tile
	opBkgd.TileSize = UDim2.fromOffset(10, 10)
	opBkgd.Size = UDim2.new(1, 0, 1, 0)
	opBkgd.BorderSizePixel = 0; opBkgd.ZIndex = 10; opBkgd.Parent = opTrack
	
	local opGrad = Instance.new("UIGradient")
	opGrad.Color = ColorSequence.new(defColor, defColor)
	opGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0)
	})
	opGrad.Rotation = 90; opGrad.Parent = opBkgd
	
	local opCursor = Instance.new("Frame")
	opCursor.Size = UDim2.new(1, 0, 0, 6)
	opCursor.Position = UDim2.new(0, 0, 1-curOp, -3)
	opCursor.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
	opCursor.BorderSizePixel = 0; opCursor.ZIndex = 13; opCursor.Parent = opTrack

	local rgbY = 185
	local hexInput = Instance.new("TextBox")
	hexInput.Size = UDim2.new(0, 60, 0, 20)
	hexInput.Position = UDim2.new(0, 20, 0, rgbY)
	hexInput.BackgroundColor3 = C.bgRaised
	hexInput.BorderSizePixel = 0; hexInput.TextSize = 11
	hexInput.TextColor3 = C.textBright
	hexInput.Font = FONT_REG; hexInput.ZIndex = 10; hexInput.Parent = panel; corner(hexInput, 2)
	hexInput.PlaceholderText = "#RRGGBB"
	hexInput.Text = "#" .. Color3.fromHSV(curH, curS, curV):ToHex()

	local redInput = Instance.new("TextBox")
	redInput.Size = UDim2.new(0, 50, 0, 20)
	redInput.Position = UDim2.new(0, 85, 0, rgbY)
	redInput.BackgroundColor3 = C.bgRaised
	redInput.BorderSizePixel = 0; redInput.TextSize = 11
	redInput.TextColor3 = C.textBright
	redInput.Font = FONT_REG; redInput.ZIndex = 10; redInput.Parent = panel; corner(redInput, 2)
	redInput.PlaceholderText = "R"

	local greenInput = Instance.new("TextBox")
	greenInput.Size = UDim2.new(0, 50, 0, 20)
	greenInput.Position = UDim2.new(0, 140, 0, rgbY)
	greenInput.BackgroundColor3 = C.bgRaised
	greenInput.BorderSizePixel = 0; greenInput.TextSize = 11
	greenInput.TextColor3 = C.textBright
	greenInput.Font = FONT_REG; greenInput.ZIndex = 10; greenInput.Parent = panel; corner(greenInput, 2)
	greenInput.PlaceholderText = "G"

	local blueInput = Instance.new("TextBox")
	blueInput.Size = UDim2.new(0, 50, 0, 20)
	blueInput.Position = UDim2.new(0, 195, 0, rgbY)
	blueInput.BackgroundColor3 = C.bgRaised
	blueInput.BorderSizePixel = 0; blueInput.TextSize = 11
	blueInput.TextColor3 = C.textBright
	blueInput.Font = FONT_REG; blueInput.ZIndex = 10; blueInput.Parent = panel; corner(blueInput, 2)
	blueInput.PlaceholderText = "B"

	local previewBox = Instance.new("Frame")
	previewBox.Size = UDim2.new(0, 60, 0, 30)
	previewBox.Position = UDim2.new(0, 260, 0, 185)
	previewBox.BackgroundColor3 = defColor
	previewBox.BackgroundTransparency = 1 - curOp
	previewBox.BorderSizePixel = 0; previewBox.ZIndex = 10; previewBox.Parent = panel; corner(previewBox, 2)
	stroke(previewBox, C.borderHard, 1, 0)

	local function getColor()   return Color3.fromHSV(curH, curS, curV) end
	local function getOpacity() return curOp end
	
	local function updateInputs()
		local c = getColor()
		local r = math.floor(c.r * 255)
		local g = math.floor(c.g * 255)
		local b = math.floor(c.b * 255)
		hexInput.Text = "#" .. c:ToHex()
		redInput.Text = tostring(r)
		greenInput.Text = tostring(g)
		blueInput.Text = tostring(b)
	end

	local function refreshAll()
		local c = getColor()
		svBox.BackgroundColor3 = Color3.fromHSV(curH, 1, 1)
		svCursor.Position = UDim2.new(curS, -6, 1-curV, -6)
		hueCursor.Position = UDim2.new(0, 0, curH, -3)
		opGrad.Color = ColorSequence.new(c, c)
		opCursor.Position = UDim2.new(0, 0, 1-curOp, -3)
		previewBox.BackgroundColor3 = c
		previewBox.BackgroundTransparency = 1 - curOp
		updateInputs()
		if colorCb then colorCb(c, curOp) end
	end

	local svDrag, hueDrag, opDrag = false, false, false
	
	svBox.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			svDrag = true
			curS = math.clamp((inp.Position.X - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
			curV = 1 - math.clamp((inp.Position.Y - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
			refreshAll()
		end
	end)
	hueBar.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			hueDrag = true
			curH = math.clamp((inp.Position.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
			refreshAll()
		end
	end)
	opTrack.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			opDrag = true
			curOp = 1 - math.clamp((inp.Position.Y - opTrack.AbsolutePosition.Y) / opTrack.AbsoluteSize.Y, 0, 1)
			refreshAll()
		end
	end)
	UIS.InputChanged:Connect(function(inp)
		if inp.UserInputType ~= Enum.UserInputType.MouseMovement then return end
		if svDrag then
			curS = math.clamp((inp.Position.X - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
			curV = 1 - math.clamp((inp.Position.Y - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
			refreshAll()
		end
		if hueDrag then
			curH = math.clamp((inp.Position.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
			refreshAll()
		end
		if opDrag then
			curOp = 1 - math.clamp((inp.Position.Y - opTrack.AbsolutePosition.Y) / opTrack.AbsoluteSize.Y, 0, 1)
			refreshAll()
		end
	end)
	UIS.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			svDrag = false; hueDrag = false; opDrag = false
		end
	end)

	local function normalizeHexInput(s)
		local cleaned = string.upper((s or ""):gsub("%s+", ""))
		if cleaned:sub(1, 1) ~= "#" then cleaned = "#" .. cleaned end
		local body = cleaned:sub(2):gsub("[^0-9A-F]", "")
		if #body > 6 then body = body:sub(1, 6) end
		return "#" .. body
	end

	hexInput:GetPropertyChangedSignal("Text"):Connect(function()
		local normalized = normalizeHexInput(hexInput.Text)
		if hexInput.Text ~= normalized then hexInput.Text = normalized end
	end)
	hexInput.FocusLost:Connect(function(enter)
		if not enter then return end
		local normalized = normalizeHexInput(hexInput.Text)
		if #normalized ~= 7 then updateInputs(); return end
		local success, result = pcall(Color3.fromHex, normalized:sub(2))
		if success and typeof(result) == "Color3" then
			curH, curS, curV = Color3.toHSV(result); refreshAll()
		else
			updateInputs()
		end
	end)

	local function applyRGB()
		local r = tonumber(redInput.Text) or 0
		local g = tonumber(greenInput.Text) or 0
		local b = tonumber(blueInput.Text) or 0
		if r >= 0 and r <= 255 and g >= 0 and g <= 255 and b >= 0 and b <= 255 then
			curH, curS, curV = Color3.toHSV(Color3.fromRGB(r, g, b)); refreshAll()
		end
	end
	redInput.FocusLost:Connect(function(enter) if enter then applyRGB() end end)
	greenInput.FocusLost:Connect(function(enter) if enter then applyRGB() end end)
	blueInput.FocusLost:Connect(function(enter) if enter then applyRGB() end end)

	local function setColorRaw(color, opacity)
		curH, curS, curV = Color3.toHSV(color)
		curOp = math.clamp(opacity or curOp, 0, 1)
		refreshAll()
	end

	refreshAll()
	return panel, getColor, getOpacity, setColorRaw
end

-- ============================================================
--  TILED MIRRORED BACKGROUND
-- ============================================================
local TILE_PX = 768

local function buildBackground(win, assetId)
	local outerFrame = win._outerFrame
	local gui        = win._gui
	assert(outerFrame, "buildBackground: win._outerFrame is nil")
	assert(gui,        "buildBackground: win._gui is nil")

	local bgHolder = Instance.new("Frame")
	bgHolder.Name = "BG_Holder"
	bgHolder.BackgroundTransparency = 1
	bgHolder.BorderSizePixel = 0
	bgHolder.ZIndex = 0
	bgHolder.ClipsDescendants = true
	bgHolder.Parent = gui

	-- Dark tint so UI stays readable
	local tint = Instance.new("Frame")
	tint.Size = UDim2.fromScale(1, 1)
	tint.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	tint.BackgroundTransparency = 0.45
	tint.BorderSizePixel = 0
	tint.ZIndex = 1
	tint.Parent = bgHolder

	local tileContainer = Instance.new("Frame")
	tileContainer.Name = "TileContainer"
	tileContainer.Size = UDim2.fromScale(1, 1)
	tileContainer.BackgroundTransparency = 1
	tileContainer.BorderSizePixel = 0
	tileContainer.ZIndex = 0
	tileContainer.ClipsDescendants = false
	tileContainer.Parent = bgHolder

	local tiles = {}

	local function clearTiles()
		for _, t in ipairs(tiles) do if t and t.Parent then t:Destroy() end end
		tiles = {}
	end

	local function buildTiles(winW, winH)
		clearTiles()
		local numCols = math.ceil(winW / TILE_PX) + 1
		local numRows = math.ceil(winH / TILE_PX) + 1
		for r = 0, numRows - 1 do
			for c = 0, numCols - 1 do
				local flipX = (c % 2 == 1)
				local flipY = (r % 2 == 1)
				if flipX or flipY then
					local wrapper = Instance.new("Frame")
					wrapper.Size = UDim2.new(0, TILE_PX, 0, TILE_PX)
					wrapper.Position = UDim2.new(0, c * TILE_PX, 0, r * TILE_PX)
					wrapper.BackgroundTransparency = 1
					wrapper.BorderSizePixel = 0
					wrapper.ClipsDescendants = true
					wrapper.ZIndex = 0
					wrapper.Parent = tileContainer
					local innerImg = Instance.new("ImageLabel")
					innerImg.Image = assetId
					innerImg.BackgroundTransparency = 1
					innerImg.BorderSizePixel = 0
					innerImg.ScaleType = Enum.ScaleType.Stretch
					innerImg.ZIndex = 0
					if flipX and flipY then
						innerImg.Size = UDim2.new(0, -TILE_PX, 0, -TILE_PX)
						innerImg.Position = UDim2.new(0, TILE_PX, 0, TILE_PX)
					elseif flipX then
						innerImg.Size = UDim2.new(0, -TILE_PX, 0, TILE_PX)
						innerImg.Position = UDim2.new(0, TILE_PX, 0, 0)
					else
						innerImg.Size = UDim2.new(0, TILE_PX, 0, -TILE_PX)
						innerImg.Position = UDim2.new(0, 0, 0, TILE_PX)
					end
					innerImg.Parent = wrapper
					table.insert(tiles, wrapper)
				else
					local img = Instance.new("ImageLabel")
					img.Image = assetId
					img.Size = UDim2.new(0, TILE_PX, 0, TILE_PX)
					img.Position = UDim2.new(0, c * TILE_PX, 0, r * TILE_PX)
					img.BackgroundTransparency = 1
					img.BorderSizePixel = 0
					img.ScaleType = Enum.ScaleType.Stretch
					img.ZIndex = 0
					img.Parent = tileContainer
					table.insert(tiles, img)
				end
			end
		end
	end

	local lastSize = Vector2.new(0, 0)
	local syncConn = RunService.RenderStepped:Connect(function()
		if not outerFrame or not outerFrame.Parent then return end
		local absPos  = outerFrame.AbsolutePosition
		local absSize = outerFrame.AbsoluteSize
		bgHolder.Position = UDim2.new(0, absPos.X, 0, absPos.Y)
		bgHolder.Size = UDim2.new(0, absSize.X, 0, absSize.Y)
		if absSize ~= lastSize then
			lastSize = absSize
			buildTiles(absSize.X, absSize.Y)
		end
	end)

	gui.AncestryChanged:Connect(function()
		if not gui.Parent then syncConn:Disconnect(); clearTiles() end
	end)

	local initSize = outerFrame.AbsoluteSize
	if initSize.X > 0 and initSize.Y > 0 then
		bgHolder.Position = UDim2.new(0, outerFrame.AbsolutePosition.X, 0, outerFrame.AbsolutePosition.Y)
		bgHolder.Size = UDim2.new(0, initSize.X, 0, initSize.Y)
		buildTiles(initSize.X, initSize.Y)
		lastSize = initSize
	end

	return bgHolder
end

-- ============================================================
--  COLUMN OBJECT
-- ============================================================
local function makeColumnObj(sf, registry, openDD, winOptions)
	if not registry[sf] then registry[sf] = {} end

	local function regItem(frame, baseY)
		table.insert(registry[sf], {frame=frame, baseY=baseY, extra=0})
	end
	local function shiftBelow(afterY, delta, animate)
		if animate == nil then animate = true end
		for _, e in ipairs(registry[sf]) do
			if e.baseY > afterY then
				e.extra = e.extra + delta
				local tp = UDim2.new(e.frame.Position.X.Scale, e.frame.Position.X.Offset, 0, e.baseY + e.extra)
				if animate and delta ~= 0 then tw(e.frame, {Position=tp}, MED):Play() else e.frame.Position = tp end
			end
		end
		local maxY = 0
		for _, e in ipairs(registry[sf]) do
			local bot = e.baseY + e.extra + e.frame.AbsoluteSize.Y
			if bot > maxY then maxY = bot end
		end
		sf.CanvasSize = UDim2.new(0, 0, 0, maxY + 20)
	end
	local function makeRow(posY, h)
		h = h or 22
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -12, 0, h)
		row.Position = UDim2.new(0, 6, 0, posY)
		row.BackgroundColor3 = C.rowBg
		row.BorderSizePixel = 0; row.ZIndex = 3; row.Parent = sf
		corner(row, 2); stroke(row, C.borderSoft, 1, 0.5)
		gradientN(row, {{0,C.rowBgAlt},{0.4,C.rowBg},{1,C.bgDeep}}, 180)
		regItem(row, posY); return row
	end

	local col = {_sf=sf, _y=8}
	function col:Finalise() self._sf.CanvasSize = UDim2.new(0, 0, 0, self._y + 20) end

	function col:Header(text)
		local posY = self._y
		local wrap = Instance.new("Frame")
		wrap.Size = UDim2.new(1,-10,0,22); wrap.Position = UDim2.new(0,5,0,posY)
		wrap.BackgroundTransparency = 1; wrap.Parent = sf; regItem(wrap, posY)
		local lbl = Instance.new("TextLabel")
		lbl.Text = string.upper(text); lbl.Font = FONT_BOLD; lbl.TextSize = 10
		lbl.TextColor3 = C.accentDim; lbl.BackgroundTransparency = 1
		lbl.Size = UDim2.new(1,0,0,14); lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.ZIndex = 3; lbl.Parent = wrap
		local bar = Instance.new("Frame")
		bar.Size = UDim2.new(1,0,0,1); bar.Position = UDim2.new(0,0,0,16)
		bar.BackgroundColor3 = C.borderSoft; bar.BorderSizePixel = 0; bar.ZIndex = 3; bar.Parent = wrap
		do local g = Instance.new("UIGradient"); g.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}); g.Rotation = 0; g.Parent = bar end
		self._y = posY + 24; return self
	end

	function col:Separator()
		local posY = self._y
		local f = Instance.new("Frame")
		f.Size = UDim2.new(1,-24,0,1); f.Position = UDim2.new(0,12,0,posY)
		f.BackgroundColor3 = C.borderFaint; f.BorderSizePixel = 0; f.ZIndex = 3; f.Parent = sf
		do local g = Instance.new("UIGradient"); g.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.4),NumberSequenceKeypoint.new(0.5,0),NumberSequenceKeypoint.new(1,0.4)}); g.Rotation = 0; g.Parent = f end
		regItem(f, posY); self._y = posY + 9; return self
	end

	function col:Spacer(h) self._y = self._y + (h or 8); return self end

	function col:Label(text)
		local posY = self._y
		local wrap = Instance.new("Frame")
		wrap.Size = UDim2.new(1,-12,0,22); wrap.Position = UDim2.new(0,6,0,posY)
		wrap.BackgroundTransparency = 1; wrap.ZIndex = 3; wrap.Parent = sf; regItem(wrap, posY)
		local lbl = Instance.new("TextLabel")
		lbl.Text = text; lbl.Font = FONT_REG; lbl.TextSize = 12; lbl.TextColor3 = C.textSub
		lbl.BackgroundTransparency = 1; lbl.Size = UDim2.fromScale(1,1)
		lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 4; lbl.Parent = wrap
		self._y = posY + 22; return self
	end

	function col:KeyDisplay(key)
		local posY = self._y
		local kD = Instance.new("TextButton")
		kD.Size = UDim2.new(1,-12,0,22); kD.Position = UDim2.new(0,6,0,posY)
		kD.BackgroundColor3 = C.bgRaised; kD.BorderSizePixel = 0
		kD.Text = key or "None"; kD.Font = FONT_BOLD; kD.TextSize = 12
		kD.TextColor3 = C.textBright; kD.AutoButtonColor = false; kD.ZIndex = 3; kD.Parent = sf
		corner(kD, 2); stroke(kD, C.borderHard, 1, 0)
		regItem(kD, posY); self._y = posY + 28; return self
	end

	-- ──────────────────────────────────────────────────────────
	--  CHECKBOX  (optional color picker — same swatch logic as Dropdown)
	-- ──────────────────────────────────────────────────────────
	-- Signature: col:Checkbox([key,] label, default [, callback [, doColorPicker, defColor, defOpacity, colorCb]])
	function col:Checkbox(a1, a2, a3, a4, a5, a6, a7, a8)
		local key, labelText, default, callback, doColorPicker, defColor, defOpacity, colorCb
		if type(a1) == "string" and type(a2) == "string" then
			key, labelText, default, callback, doColorPicker, defColor, defOpacity, colorCb = a1, a2, a3, a4, a5, a6, a7, a8
		else
			key, labelText, default, callback, doColorPicker, defColor, defOpacity, colorCb = nil, a1, a2, a3, a4, a5, a6, a7
		end

		local posY = self._y
		local cpOpen = false
		local function containerH() return 22 + (cpOpen and (PICKER_H + 2) or 0) end

		-- Use a resizable container (like Dropdown) so it can expand for the picker
		local container = Instance.new("Frame")
		container.Size = UDim2.new(1,-12,0,22); container.Position = UDim2.new(0,6,0,posY)
		container.BackgroundColor3 = C.rowBg; container.BorderSizePixel = 0
		container.ClipsDescendants = false; container.ZIndex = 3; container.Parent = sf
		corner(container, 2); stroke(container, C.borderSoft, 1, 0.5)
		gradientN(container, {{0,C.rowBgAlt},{0.4,C.rowBg},{1,C.bgDeep}}, 180)
		regItem(container, posY)

		local obj = newElementObj(default or false, callback)

		-- Checkbox box
		local box = Instance.new("TextButton")
		box.Size = UDim2.new(0,13,0,13); box.Position = UDim2.new(0,4,0.5,-6)
		box.BackgroundColor3 = obj.Value and C.accentMid or C.checkOff
		box.BorderSizePixel = 0; box.Text = ""; box.AutoButtonColor = false
		box.ZIndex = 4; box.Parent = container; corner(box, 2)
		local bStroke = stroke(box, obj.Value and C.accentDim or C.borderHard, 1)

		local tick = Instance.new("TextLabel")
		tick.Text = "✓"; tick.Font = FONT_BOLD; tick.TextSize = 9
		tick.TextColor3 = C.bgDeep; tick.BackgroundTransparency = 1
		tick.Size = UDim2.fromScale(1,1)
		tick.TextXAlignment = Enum.TextXAlignment.Center
		tick.TextYAlignment = Enum.TextYAlignment.Center
		tick.Visible = obj.Value; tick.ZIndex = 5; tick.Parent = box

		-- Label — shrink if color picker swatch present
		local lblW = doColorPicker and -44 or -24
		local lbl = Instance.new("TextLabel")
		lbl.Text = tostring(labelText); lbl.Font = FONT_REG; lbl.TextSize = 12
		lbl.TextColor3 = obj.Value and C.textBright or C.textMid
		lbl.BackgroundTransparency = 1
		lbl.Size = UDim2.new(1, lblW, 1, 0); lbl.Position = UDim2.new(0, 22, 0, 0)
		lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 4; lbl.Parent = container

		-- ── Color picker swatch (identical logic to Dropdown swatch) ──
		local swatchBtn, swatchStroke, pickerPanel, cpObj, setPickerRaw
		if doColorPicker then
			defColor   = defColor   or Color3.fromRGB(200, 200, 200)
			defOpacity = defOpacity or 1.0

			-- Swatch button — right side of row, same position as dropdown
			swatchBtn = Instance.new("TextButton")
			swatchBtn.Size = UDim2.new(0,13,0,13)
			swatchBtn.Position = UDim2.new(1,-18,0.5,-6)  -- right-aligned, vertically centred
			swatchBtn.BackgroundColor3 = defColor
			swatchBtn.BackgroundTransparency = 1 - math.clamp(defOpacity, 0, 1)
			swatchBtn.BorderSizePixel = 0; swatchBtn.Text = ""
			swatchBtn.AutoButtonColor = false; swatchBtn.ZIndex = 60
			swatchBtn.Parent = container; corner(swatchBtn, 2)
			swatchStroke = stroke(swatchBtn, C.borderHard, 1.5, 0)

			-- Checkerboard bg on swatch (for opacity preview)
			local swatchBg = Instance.new("ImageLabel")
			swatchBg.Size = UDim2.fromScale(1,1)
			swatchBg.Image = "http://www.roblox.com/asset/?id=14204231522"
			swatchBg.ImageTransparency = 0.45
			swatchBg.ScaleType = Enum.ScaleType.Tile
			swatchBg.TileSize = UDim2.fromOffset(6,6)
			swatchBg.BackgroundTransparency = 1; swatchBg.BorderSizePixel = 0
			swatchBg.ZIndex = 59; swatchBg.Parent = swatchBtn

			-- Build picker panel parented to the container (same as dropdown)
			pickerPanel, _, _, setPickerRaw = buildColorPicker(container, defColor, defOpacity, function(c, op)
				if swatchBtn then
					swatchBtn.BackgroundColor3 = c
					swatchBtn.BackgroundTransparency = 1 - math.clamp(op or 1, 0, 1)
				end
				if cpObj then cpObj:_fire({Color=c, Opacity=op}) end
				if colorCb then colorCb(c, op) end
			end)
			pickerPanel.Position = UDim2.new(0, 0, 0, 22)

			cpObj = newElementObj({Color=defColor, Opacity=defOpacity}, colorCb)
			function cpObj:SetValue(color, opacity)
				if setPickerRaw then setPickerRaw(color, opacity or 1) end
				self:_fire({Color=color, Opacity=opacity or 1})
			end
			if key and winOptions then winOptions[key.."_Color"] = cpObj end

			-- Open/close picker (identical animation to dropdown)
			local function closeCP()
				cpOpen = false
				tw(pickerPanel, {Size=UDim2.new(1,0,0,0)}, MED):Play()
				tw(swatchStroke, {Color=C.borderHard}, FAST):Play()
				tw(container, {Size=UDim2.new(1,-12,0,containerH())}, MED):Play()
				task.delay(0.26, function() pickerPanel.Visible = false end)
				task.delay(0.26, function() shiftBelow(posY, -(PICKER_H+2), true) end)
			end
			local function openCP()
				cpOpen = true
				pickerPanel.Size = UDim2.new(1,0,0,0); pickerPanel.Visible = true
				tw(swatchStroke, {Color=C.accentMid}, FAST):Play()
				tw(pickerPanel, {Size=UDim2.new(1,0,0,PICKER_H)}, SPRING):Play()
				tw(container, {Size=UDim2.new(1,-12,0,containerH())}, MED):Play()
				shiftBelow(posY, PICKER_H+2, true)
			end
			swatchBtn.MouseButton1Click:Connect(function()
				if cpOpen then closeCP() else openCP() end
			end)
		end

		-- Checkbox state logic
		local function applyState(v)
			tick.Visible = v
			if v then
				tw(box,       {BackgroundColor3=C.accentMid},  FAST):Play()
				tw(bStroke,   {Color=C.accentDim},             FAST):Play()
				tw(lbl,       {TextColor3=C.textBright},       FAST):Play()
			else
				tw(box,       {BackgroundColor3=C.checkOff},   FAST):Play()
				tw(bStroke,   {Color=C.borderHard},            FAST):Play()
				tw(lbl,       {TextColor3=C.textMid},          FAST):Play()
			end
		end
		function obj:SetValue(v)
			v = not not v; applyState(v); self:_fire(v)
		end
		box.MouseButton1Click:Connect(function() ripple(container); obj:SetValue(not obj.Value) end)
		container.MouseEnter:Connect(function()
			if not obj.Value then tw(lbl, {TextColor3=C.textBright}, SNAP):Play() end
			tw(container, {BackgroundColor3=C.bgHover}, SNAP):Play()
		end)
		container.MouseLeave:Connect(function()
			if not obj.Value then tw(lbl, {TextColor3=C.textMid}, SNAP):Play() end
			tw(container, {BackgroundColor3=C.rowBg}, SNAP):Play()
		end)

		if key and winOptions then winOptions[key] = obj end
		self._y = posY + 26; return obj, self
	end

	-- ──────────────────────────────────────────────────────────
	--  DROPDOWN
	-- ──────────────────────────────────────────────────────────
	function col:Dropdown(a1,a2,a3,a4,a5,a6,a7,a8,a9)
		local key, labelText, options, default, callback, doColorPicker, defColor, defOpacity, colorCb
		    = normaliseDropArgs(a1,a2,a3,a4,a5,a6,a7,a8,a9)

		local posY = self._y; local COUNT = #options; local LIST_H = COUNT * ITEM_H
		local ddOpen = false; local cpOpen = false
		local function containerH() return 22 + (ddOpen and LIST_H or 0) + (cpOpen and (PICKER_H+2) or 0) end

		local selIdx = 1
		for i, v in ipairs(options) do if v == (default or options[1]) then selIdx = i end end
		local obj = newElementObj(options[selIdx], callback)

		local container = Instance.new("Frame")
		container.Size = UDim2.new(1,-12,0,22); container.Position = UDim2.new(0,6,0,posY)
		container.BackgroundColor3 = C.rowBg; container.ClipsDescendants = false
		container.ZIndex = 3; container.Parent = sf
		corner(container, 2); stroke(container, C.borderSoft, 1, 0.5)
		gradientN(container, {{0,C.rowBgAlt},{0.4,C.rowBg},{1,C.bgDeep}}, 180)
		regItem(container, posY)

		local SWATCH_W = doColorPicker and 18 or 0
		if labelText ~= "" then
			local lbl = Instance.new("TextLabel")
			lbl.Text = tostring(labelText); lbl.Font = FONT_REG; lbl.TextSize = 12
			lbl.TextColor3 = C.textMid; lbl.BackgroundTransparency = 1
			lbl.Size = UDim2.new(0.44,-SWATCH_W,0,22)
			lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 4; lbl.Parent = container
		end

		local swatchBtn, swatchStroke
		if doColorPicker then
			defColor = defColor or Color3.fromRGB(200,200,200); defOpacity = defOpacity or 1.0
			swatchBtn = Instance.new("TextButton")
			swatchBtn.Size = UDim2.new(0,13,0,13); swatchBtn.Position = UDim2.new(0.44,-SWATCH_W,0,4)
			swatchBtn.BackgroundColor3 = defColor
			swatchBtn.BackgroundTransparency = 1 - math.clamp(defOpacity,0,1)
			swatchBtn.BorderSizePixel = 0; swatchBtn.Text = ""; swatchBtn.AutoButtonColor = false
			swatchBtn.ZIndex = 60; swatchBtn.Parent = container; corner(swatchBtn, 2)
			swatchStroke = stroke(swatchBtn, C.borderHard, 1.5, 0)
			local swatchBg = Instance.new("ImageLabel")
			swatchBg.Size = UDim2.fromScale(1,1)
			swatchBg.Image = "http://www.roblox.com/asset/?id=14204231522"
			swatchBg.ImageTransparency = 0.45; swatchBg.ScaleType = Enum.ScaleType.Tile
			swatchBg.TileSize = UDim2.fromOffset(6,6); swatchBg.BackgroundTransparency = 1
			swatchBg.BorderSizePixel = 0; swatchBg.ZIndex = 59; swatchBg.Parent = swatchBtn
		end

		local btnX = (labelText ~= "") and 0.45 or 0
		local btnW = (labelText ~= "") and 0.54 or 1
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(btnW,0,0,22); btn.Position = UDim2.new(btnX,0,0,0)
		btn.BackgroundColor3 = C.dropBg; btn.BorderSizePixel = 0
		btn.Text = ""; btn.AutoButtonColor = false; btn.ZIndex = 6; btn.Parent = container
		corner(btn, 2); local btnStroke = stroke(btn, C.borderSoft, 1)
		gradient(btn, Color3.fromRGB(18,18,18), Color3.fromRGB(8,8,8), 180)

		local selLbl = Instance.new("TextLabel")
		selLbl.Text = options[selIdx]; selLbl.Font = FONT_REG; selLbl.TextSize = 11
		selLbl.TextColor3 = C.textMid; selLbl.BackgroundTransparency = 1
		selLbl.Size = UDim2.new(1,-20,1,0); selLbl.Position = UDim2.new(0,6,0,0)
		selLbl.TextXAlignment = Enum.TextXAlignment.Left; selLbl.ZIndex = 7; selLbl.Parent = btn

		local arrow = Instance.new("TextLabel")
		arrow.Text = "▾"; arrow.Font = FONT_BOLD; arrow.TextSize = 10
		arrow.TextColor3 = C.textDim; arrow.BackgroundTransparency = 1
		arrow.Size = UDim2.new(0,16,1,0); arrow.Position = UDim2.new(1,-18,0,0)
		arrow.TextXAlignment = Enum.TextXAlignment.Center; arrow.ZIndex = 7; arrow.Parent = btn

		local listFrame = Instance.new("Frame")
		listFrame.Size = UDim2.new(btnW,0,0,0); listFrame.Position = UDim2.new(btnX,0,0,22)
		listFrame.BackgroundColor3 = Color3.fromRGB(10,10,10); listFrame.BorderSizePixel = 0
		listFrame.ClipsDescendants = true; listFrame.Visible = false; listFrame.ZIndex = 20
		listFrame.Parent = container
		corner(listFrame, 2); stroke(listFrame, C.borderHard, 1, 0.1)
		gradient(listFrame, Color3.fromRGB(16,16,16), Color3.fromRGB(8,8,8), 180)

		local pickerPanel, getPColor, getPOpacity, setPickerRaw
		local function pickerY() return 22 + (ddOpen and LIST_H or 0) end
		local function updatePickerPos() if pickerPanel then pickerPanel.Position = UDim2.new(0,0,0,pickerY()) end end

		local cpObj
		if doColorPicker then
			pickerPanel, getPColor, getPOpacity, setPickerRaw = buildColorPicker(container, defColor, defOpacity, function(c, op)
				if swatchBtn then
					swatchBtn.BackgroundColor3 = c
					swatchBtn.BackgroundTransparency = 1 - math.clamp(op or 1, 0, 1)
				end
				if cpObj then cpObj:_fire({Color=c, Opacity=op}) end
				if colorCb then colorCb(c, op) end
			end)
			pickerPanel.Position = UDim2.new(0,0,0,pickerY())
			cpObj = newElementObj({Color=defColor, Opacity=defOpacity}, colorCb)
			function cpObj:SetValue(color, opacity)
				if setPickerRaw then setPickerRaw(color, opacity or 1) end
				self:_fire({Color=color, Opacity=opacity or 1})
			end
			if key and winOptions then winOptions[key.."_Color"] = cpObj end
		end

		local function closeDD_internal()
			ddOpen = false; openDD.fn = nil
			tw(arrow,    {Rotation=0, TextColor3=C.textDim}, MED):Play()
			tw(listFrame,{Size=UDim2.new(btnW,0,0,0)},       MED):Play()
			tw(btn,      {BackgroundColor3=C.dropBg},         FAST):Play()
			tw(btnStroke,{Color=C.borderSoft},                FAST):Play()
			tw(selLbl,   {TextColor3=C.textMid},              FAST):Play()
			tw(container,{Size=UDim2.new(1,-12,0,containerH())}, MED):Play()
			task.delay(0.26, function() listFrame.Visible = false end)
			shiftBelow(posY, -LIST_H, true); updatePickerPos()
		end
		local function openDD_internal()
			if openDD.fn then openDD.fn() end
			ddOpen = true; openDD.fn = closeDD_internal
			listFrame.Visible = true; listFrame.Size = UDim2.new(btnW,0,0,0)
			tw(arrow,    {Rotation=180, TextColor3=C.textBright}, SPRING):Play()
			tw(listFrame,{Size=UDim2.new(btnW,0,0,LIST_H)},       SPRING):Play()
			tw(btn,      {BackgroundColor3=Color3.fromRGB(20,20,20)}, FAST):Play()
			tw(btnStroke,{Color=C.borderHard},                     FAST):Play()
			tw(selLbl,   {TextColor3=C.textBright},                FAST):Play()
			tw(container,{Size=UDim2.new(1,-12,0,containerH())},   MED):Play()
			shiftBelow(posY, LIST_H, true); updatePickerPos()
		end

		local optHighlights = {}
		for i, optText in ipairs(options) do
			local optBtn = Instance.new("TextButton")
			optBtn.Size = UDim2.new(1,0,0,ITEM_H); optBtn.Position = UDim2.new(0,0,0,(i-1)*ITEM_H)
			optBtn.BackgroundColor3 = (i==selIdx) and C.dropItemSel or C.dropItem
			optBtn.BackgroundTransparency = (i==selIdx) and 0 or 1
			optBtn.BorderSizePixel = 0; optBtn.Text = ""; optBtn.AutoButtonColor = false
			optBtn.ZIndex = 21; optBtn.Parent = listFrame

			local selBar = Instance.new("Frame")
			selBar.Size = UDim2.new(0,2,0.55,0); selBar.Position = UDim2.new(0,2,0.22,0)
			selBar.BackgroundColor3 = C.accentMid; selBar.BorderSizePixel = 0
			selBar.Visible = (i==selIdx); selBar.ZIndex = 22; selBar.Parent = optBtn; corner(selBar, 1)

			local optLbl = Instance.new("TextLabel")
			optLbl.Text = optText; optLbl.Font = FONT_REG; optLbl.TextSize = 11
			optLbl.TextColor3 = (i==selIdx) and C.textBright or C.textMid
			optLbl.BackgroundTransparency = 1
			optLbl.Size = UDim2.new(1,-14,1,0); optLbl.Position = UDim2.new(0,12,0,0)
			optLbl.TextXAlignment = Enum.TextXAlignment.Left; optLbl.ZIndex = 22; optLbl.Parent = optBtn
			optHighlights[i] = {btn=optBtn, lbl=optLbl, bar=selBar}

			if i < COUNT then
				local sep = Instance.new("Frame")
				sep.Size = UDim2.new(0.88,0,0,1); sep.Position = UDim2.new(0.06,0,1,-1)
				sep.BackgroundColor3 = C.borderFaint; sep.BackgroundTransparency = 0
				sep.BorderSizePixel = 0; sep.ZIndex = 22; sep.Parent = optBtn
			end

			optBtn.MouseEnter:Connect(function()
				if i ~= selIdx then
					tw(optBtn, {BackgroundColor3=C.bgHover, BackgroundTransparency=0}, SNAP):Play()
					tw(optLbl, {TextColor3=C.textBright}, SNAP):Play()
				end
			end)
			optBtn.MouseLeave:Connect(function()
				if i ~= selIdx then
					tw(optBtn, {BackgroundTransparency=1}, SNAP):Play()
					tw(optLbl, {TextColor3=C.textMid}, SNAP):Play()
				end
			end)
			optBtn.MouseButton1Click:Connect(function()
				for j, h in ipairs(optHighlights) do
					tw(h.btn, {BackgroundTransparency=1}, SNAP):Play()
					tw(h.lbl, {TextColor3=(j==i) and C.textBright or C.textMid}, SNAP):Play()
					h.bar.Visible = (j==i)
				end
				tw(optBtn, {BackgroundColor3=C.dropItemSel, BackgroundTransparency=0}, SNAP):Play()
				selIdx = i; selLbl.Text = optText; closeDD_internal()
				obj:_fire(optText)
				if obj.Callback then pcall(obj.Callback, optText, i) end
			end)
		end

		function obj:SetValue(v)
			for i, optText in ipairs(options) do
				if optText == v then
					selIdx = i; selLbl.Text = v
					for j, h in ipairs(optHighlights) do
						tw(h.btn, {BackgroundTransparency=(j==i) and 0 or 1}, SNAP):Play()
						tw(h.lbl, {TextColor3=(j==i) and C.textBright or C.textMid}, SNAP):Play()
						h.bar.Visible = (j==i)
					end
					self:_fire(v); return
				end
			end
		end

		btn.MouseButton1Click:Connect(function()
			ripple(container)
			if ddOpen then closeDD_internal() else openDD_internal() end
		end)
		btn.MouseEnter:Connect(function()
			if not ddOpen then
				tw(btn, {BackgroundColor3=Color3.fromRGB(18,18,18)}, SNAP):Play()
				tw(btnStroke, {Color=C.borderHard}, SNAP):Play()
			end
		end)
		btn.MouseLeave:Connect(function()
			if not ddOpen then
				tw(btn, {BackgroundColor3=C.dropBg}, SNAP):Play()
				tw(btnStroke, {Color=C.borderSoft}, SNAP):Play()
			end
		end)

		if doColorPicker then
			local function closeCP()
				cpOpen = false
				tw(pickerPanel, {Size=UDim2.new(1,0,0,0)}, MED):Play()
				tw(swatchStroke, {Color=C.borderHard}, FAST):Play()
				tw(container, {Size=UDim2.new(1,-12,0,containerH())}, MED):Play()
				task.delay(0.26, function() pickerPanel.Visible = false end)
				task.delay(0.26, function() shiftBelow(posY, -(PICKER_H+2), true) end)
			end
			local function openCP()
				cpOpen = true; updatePickerPos()
				pickerPanel.Size = UDim2.new(1,0,0,0); pickerPanel.Visible = true
				tw(swatchStroke, {Color=C.accentMid}, FAST):Play()
				tw(pickerPanel, {Size=UDim2.new(1,0,0,PICKER_H)}, SPRING):Play()
				tw(container, {Size=UDim2.new(1,-12,0,containerH())}, MED):Play()
				shiftBelow(posY, PICKER_H+2, true)
			end
			swatchBtn.MouseButton1Click:Connect(function()
				if cpOpen then closeCP() else openCP() end
			end)
		end

		if key and winOptions then winOptions[key] = obj end
		self._y = posY + 26; return obj, self
	end

	-- ──────────────────────────────────────────────────────────
	--  SLIDER
	-- ──────────────────────────────────────────────────────────
	function col:Slider(a1,a2,a3,a4,a5,a6)
		local key, labelText, minVal, maxVal, default, callback
		if type(a1) == "string" and type(a2) == "string" then
			key, labelText, minVal, maxVal, default, callback = a1, a2, a3, a4, a5, a6
		else
			key, labelText, minVal, maxVal, default, callback = nil, a1, a2, a3, a4, a5
		end

		local posY = self._y; local row = makeRow(posY, 22)
		local obj = newElementObj(default, callback)

		local lbl = Instance.new("TextLabel")
		lbl.Text = tostring(labelText); lbl.Font = FONT_REG; lbl.TextSize = 12; lbl.TextColor3 = C.textMid
		lbl.BackgroundTransparency = 1; lbl.Size = UDim2.new(0.42,0,1,0)
		lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 4; lbl.Parent = row

		local valLbl = Instance.new("TextLabel")
		valLbl.Text = tostring(default); valLbl.Font = FONT_REG; valLbl.TextSize = 10; valLbl.TextColor3 = C.accentMid
		valLbl.BackgroundTransparency = 1; valLbl.Size = UDim2.new(0.13,0,1,0); valLbl.Position = UDim2.new(0.87,0,0,0)
		valLbl.TextXAlignment = Enum.TextXAlignment.Right; valLbl.ZIndex = 4; valLbl.Parent = row

		local track = Instance.new("Frame")
		track.Size = UDim2.new(0.42,0,0,3); track.Position = UDim2.new(0.43,0,0.5,-1)
		track.BackgroundColor3 = C.sliderTrack; track.BorderSizePixel = 0; track.ZIndex = 4; track.Parent = row
		corner(track, 2); stroke(track, C.borderFaint, 1, 0.3)

		local pct = (default - minVal) / math.max(maxVal - minVal, 1)
		local fill = Instance.new("Frame")
		fill.Size = UDim2.new(pct,0,1,0); fill.BackgroundColor3 = C.sliderFill
		fill.BorderSizePixel = 0; fill.ZIndex = 5; fill.Parent = track; corner(fill, 2)
		gradient(fill, Color3.fromRGB(100,100,100), Color3.fromRGB(220,220,220), 0)

		local knob = Instance.new("TextButton")
		knob.Size = UDim2.new(0,11,0,11); knob.Position = UDim2.new(pct,-5,0.5,-5)
		knob.BackgroundColor3 = C.knob; knob.BorderSizePixel = 0
		knob.Text = ""; knob.AutoButtonColor = false; knob.ZIndex = 6; knob.Parent = track; corner(knob, 6)
		stroke(knob, C.borderHard, 1.5, 0)

		local function applyValue(v)
			v = math.clamp(v, minVal, maxVal)
			local p = (v - minVal) / math.max(maxVal - minVal, 1)
			tw(fill, {Size=UDim2.new(p,0,1,0)}, SNAP):Play()
			tw(knob, {Position=UDim2.new(p,-5,0.5,-5)}, SNAP):Play()
			valLbl.Text = tostring(v); obj:_fire(v)
		end
		function obj:SetValue(v) applyValue(math.floor(v + 0.5)) end

		local drag = false; local dragStarted = false
		knob.MouseButton1Down:Connect(function() drag = true; dragStarted = false end)
		UIS.InputEnded:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 and drag then
				drag = false; dragStarted = false
				tw(knob, {Size=UDim2.new(0,11,0,11)}, SNAP):Play()
			end
		end)
		UIS.InputChanged:Connect(function(inp)
			if drag and inp.UserInputType == Enum.UserInputType.MouseMovement then
				if not dragStarted then
					dragStarted = true
					tw(knob, {Size=UDim2.new(0,13,0,13), Position=UDim2.new(pct,-6,0.5,-6)}, SNAP):Play()
				end
				local p = math.clamp((inp.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
				applyValue(math.floor(minVal + (maxVal - minVal) * p + 0.5))
			end
		end)
		row.MouseEnter:Connect(function() tw(row, {BackgroundColor3=C.bgHover}, SNAP):Play() end)
		row.MouseLeave:Connect(function() tw(row, {BackgroundColor3=C.rowBg}, SNAP):Play() end)

		if key and winOptions then winOptions[key] = obj end
		self._y = posY + 26; return obj, self
	end

	-- ──────────────────────────────────────────────────────────
	--  KEYBIND
	-- ──────────────────────────────────────────────────────────
	function col:Keybind(a1,a2,a3,a4)
		local key, labelText, defaultKey, callback
		if type(a4) == "function" or (type(a3) == "function" and type(a2) == "string" and type(a1) == "string") then
			key, labelText, defaultKey, callback = a1, a2, a3, a4
		elseif type(a3) == "function" or a3 == nil then
			key, labelText, defaultKey, callback = nil, a1, a2, a3
		else
			key, labelText, defaultKey, callback = a1, a2, a3, a4
		end

		local posY = self._y; local row = makeRow(posY, 22)
		local obj = newElementObj(defaultKey or "None", callback)

		local lbl = Instance.new("TextLabel")
		lbl.Text = tostring(labelText); lbl.Font = FONT_REG; lbl.TextSize = 12; lbl.TextColor3 = C.textMid
		lbl.BackgroundTransparency = 1; lbl.Size = UDim2.new(0.55,0,1,0)
		lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 4; lbl.Parent = row

		local kBtn = Instance.new("TextButton")
		kBtn.Size = UDim2.new(0.4,0,0.72,0); kBtn.Position = UDim2.new(0.57,0,0.14,0)
		kBtn.BackgroundColor3 = C.bgRaised; kBtn.BorderSizePixel = 0
		kBtn.Text = obj.Value; kBtn.Font = FONT_BOLD; kBtn.TextSize = 10
		kBtn.TextColor3 = C.textMid; kBtn.AutoButtonColor = false; kBtn.ZIndex = 4; kBtn.Parent = row; corner(kBtn, 2)
		local kS = stroke(kBtn, C.borderHard, 1, 0.1)

		local picking = false
		function obj:SetValue(k)
			k = k or "None"; kBtn.Text = k
			tw(kBtn, {BackgroundColor3=C.bgPress}, SNAP):Play()
			task.delay(0.18, function() tw(kBtn, {BackgroundColor3=C.bgRaised}, FAST):Play() end)
			self:_fire(k)
		end
		kBtn.MouseButton1Click:Connect(function()
			if picking then return end; picking = true; kBtn.Text = "..."
			tw(kBtn, {BackgroundColor3=C.bgHover}, SNAP):Play()
			tw(kS, {Color=C.accentDim}, SNAP):Play()
			local conn; conn = UIS.InputBegan:Connect(function(inp, gp)
				if gp then return end
				local k
				if inp.UserInputType == Enum.UserInputType.Keyboard then k = inp.KeyCode.Name
				elseif inp.UserInputType == Enum.UserInputType.MouseButton1 then k = "MouseLeft"
				elseif inp.UserInputType == Enum.UserInputType.MouseButton2 then k = "MouseRight" end
				if k then conn:Disconnect(); picking = false; tw(kS, {Color=C.borderHard}, FAST):Play(); obj:SetValue(k) end
			end)
		end)
		kBtn.MouseEnter:Connect(function() tw(kBtn, {BackgroundColor3=C.bgHover}, SNAP):Play() end)
		kBtn.MouseLeave:Connect(function() if not picking then tw(kBtn, {BackgroundColor3=C.bgRaised}, SNAP):Play() end end)
		row.MouseEnter:Connect(function() tw(row, {BackgroundColor3=C.bgHover}, SNAP):Play() end)
		row.MouseLeave:Connect(function() tw(row, {BackgroundColor3=C.rowBg}, SNAP):Play() end)

		if key and winOptions then winOptions[key] = obj end
		self._y = posY + 26; return obj, self
	end

	-- ──────────────────────────────────────────────────────────
	--  PAIRED CHECKBOX
	-- ──────────────────────────────────────────────────────────
	function col:PairedCheckbox(a1,a2,a3,a4,a5,a6,a7,a8)
		local keyL, keyR, lL, dL, lR, dR, cbL, cbR = normalisePaired(a1,a2,a3,a4,a5,a6,a7,a8)
		local posY = self._y; local row = makeRow(posY, 22)
		local objL = newElementObj(dL or false, cbL)
		local objR = newElementObj(dR or false, cbR)

		local function makeMini(text, xScale, obj)
			local box = Instance.new("TextButton")
			box.Size = UDim2.new(0,12,0,12); box.Position = UDim2.new(xScale,3,0.5,-6)
			box.BackgroundColor3 = obj.Value and C.accentMid or C.checkOff
			box.BorderSizePixel = 0; box.Text = ""; box.AutoButtonColor = false
			box.ZIndex = 4; box.Parent = row; corner(box, 2)
			local bS = stroke(box, obj.Value and C.accentDim or C.borderHard, 1)
			local tick = Instance.new("TextLabel")
			tick.Text = "✓"; tick.Font = FONT_BOLD; tick.TextSize = 8; tick.TextColor3 = C.bgDeep
			tick.BackgroundTransparency = 1; tick.Size = UDim2.fromScale(1,1)
			tick.TextXAlignment = Enum.TextXAlignment.Center
			tick.TextYAlignment = Enum.TextYAlignment.Center
			tick.Visible = obj.Value; tick.ZIndex = 5; tick.Parent = box
			local ml = Instance.new("TextLabel")
			ml.Text = tostring(text); ml.Font = FONT_REG; ml.TextSize = 11
			ml.TextColor3 = obj.Value and C.textBright or C.textMid
			ml.BackgroundTransparency = 1
			ml.Size = UDim2.new(0.44,0,1,0); ml.Position = UDim2.new(xScale+0.04,0,0,0)
			ml.TextXAlignment = Enum.TextXAlignment.Left; ml.ZIndex = 4; ml.Parent = row
			function obj:SetValue(v)
				v = not not v; tick.Visible = v
				tw(box, {BackgroundColor3=v and C.accentMid or C.checkOff}, FAST):Play()
				tw(bS,  {Color=v and C.accentDim or C.borderHard}, FAST):Play()
				tw(ml,  {TextColor3=v and C.textBright or C.textMid}, FAST):Play()
				self:_fire(v)
			end
			box.MouseButton1Click:Connect(function() ripple(row); obj:SetValue(not obj.Value) end)
		end

		makeMini(lL, 0, objL); makeMini(lR, 0.5, objR)
		row.MouseEnter:Connect(function() tw(row, {BackgroundColor3=C.bgHover}, SNAP):Play() end)
		row.MouseLeave:Connect(function() tw(row, {BackgroundColor3=C.rowBg}, SNAP):Play() end)

		if keyL and winOptions then winOptions[keyL] = objL end
		if keyR and winOptions then winOptions[keyR] = objR end
		self._y = posY + 24; return objL, objR, self
	end

	-- ──────────────────────────────────────────────────────────
	--  EXPANDABLE CHECKBOX
	-- ──────────────────────────────────────────────────────────
	function col:ExpandableCheckbox(a1,a2,a3,a4,a5)
		local key, labelText, default, callback, subBuilder
		if type(a1) == "string" and type(a2) == "string" then
			key, labelText, default, callback, subBuilder = a1, a2, a3, a4, a5
		else
			key, labelText, default, callback, subBuilder = nil, a1, a2, a3, a4
		end

		local posY = self._y; local row = makeRow(posY, 22)
		local obj = newElementObj(default or false, callback)

		local box = Instance.new("TextButton")
		box.Size = UDim2.new(0,13,0,13); box.Position = UDim2.new(0,4,0.5,-6)
		box.BackgroundColor3 = obj.Value and C.accentMid or C.checkOff
		box.BorderSizePixel = 0; box.Text = ""; box.AutoButtonColor = false
		box.ZIndex = 4; box.Parent = row; corner(box, 2)
		local bS = stroke(box, obj.Value and C.accentDim or C.borderHard, 1)

		local tick = Instance.new("TextLabel")
		tick.Text = "✓"; tick.Font = FONT_BOLD; tick.TextSize = 9; tick.TextColor3 = C.bgDeep
		tick.BackgroundTransparency = 1; tick.Size = UDim2.fromScale(1,1)
		tick.TextXAlignment = Enum.TextXAlignment.Center
		tick.TextYAlignment = Enum.TextYAlignment.Center
		tick.Visible = obj.Value; tick.ZIndex = 5; tick.Parent = box

		local lbl = Instance.new("TextLabel")
		lbl.Text = tostring(labelText); lbl.Font = FONT_REG; lbl.TextSize = 12
		lbl.TextColor3 = obj.Value and C.textBright or C.textMid
		lbl.BackgroundTransparency = 1
		lbl.Size = UDim2.new(1,-36,1,0); lbl.Position = UDim2.new(0,22,0,0)
		lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 4; lbl.Parent = row

		local expArrow = Instance.new("TextLabel")
		expArrow.Text = "▾"; expArrow.Font = FONT_BOLD; expArrow.TextSize = 10
		expArrow.TextColor3 = C.textDim; expArrow.BackgroundTransparency = 1
		expArrow.Size = UDim2.new(0,16,1,0); expArrow.Position = UDim2.new(1,-18,0,0)
		expArrow.TextXAlignment = Enum.TextXAlignment.Center; expArrow.ZIndex = 4; expArrow.Parent = row

		local subPanel = Instance.new("Frame")
		subPanel.Size = UDim2.new(1,-12,0,0); subPanel.Position = UDim2.new(0,6,0,posY+26)
		subPanel.BackgroundColor3 = Color3.fromRGB(8,8,8); subPanel.BorderSizePixel = 0
		subPanel.ClipsDescendants = true; subPanel.Visible = false; subPanel.ZIndex = 3; subPanel.Parent = sf
		corner(subPanel, 2); stroke(subPanel, C.borderFaint, 1, 0.4); regItem(subPanel, posY+26)

		local subSF = Instance.new("ScrollingFrame")
		subSF.Size = UDim2.fromScale(1,1); subSF.BackgroundTransparency = 1
		subSF.BorderSizePixel = 0; subSF.ScrollBarThickness = 2
		subSF.ScrollBarImageColor3 = C.accentDim; subSF.CanvasSize = UDim2.new(0,0,0,2000)
		subSF.ZIndex = 2; subSF.Parent = subPanel

		local subReg = {}; local subColObj = makeColumnObj(subSF, subReg, openDD, winOptions)
		if subBuilder then subBuilder(subColObj) end; subColObj:Finalise()
		local subH = math.min(subColObj._y + 8, 220)
		subSF.CanvasSize = UDim2.new(0,0,0,subColObj._y + 8)

		local expanded = false
		local function openSub()
			expanded = true; subPanel.Visible = true; subPanel.Size = UDim2.new(1,-12,0,0)
			tw(subPanel, {Size=UDim2.new(1,-12,0,subH)}, SPRING):Play()
			tw(expArrow, {Rotation=180}, MED):Play(); shiftBelow(posY, subH+2)
		end
		local function closeSub()
			expanded = false
			tw(subPanel, {Size=UDim2.new(1,-12,0,0)}, MED):Play()
			tw(expArrow, {Rotation=0}, MED):Play()
			task.delay(0.26, function() subPanel.Visible = false end)
			shiftBelow(posY, -(subH+2))
		end

		function obj:SetValue(v)
			v = not not v; tick.Visible = v
			tw(box, {BackgroundColor3=v and C.accentMid or C.checkOff}, FAST):Play()
			tw(bS,  {Color=v and C.accentDim or C.borderHard}, FAST):Play()
			tw(lbl, {TextColor3=v and C.textBright or C.textMid}, FAST):Play()
			if v and not expanded then openSub() elseif not v and expanded then closeSub() end
			self:_fire(v)
		end

		box.MouseButton1Click:Connect(function() ripple(row); obj:SetValue(not obj.Value) end)
		local arBtn = Instance.new("TextButton")
		arBtn.Size = UDim2.new(0,24,1,0); arBtn.Position = UDim2.new(1,-26,0,0)
		arBtn.BackgroundTransparency = 1; arBtn.Text = ""; arBtn.ZIndex = 6; arBtn.Parent = row
		arBtn.MouseButton1Click:Connect(function()
			if not obj.Value then return end
			if expanded then closeSub() else openSub() end
		end)
		row.MouseEnter:Connect(function() tw(row, {BackgroundColor3=C.bgHover}, SNAP):Play() end)
		row.MouseLeave:Connect(function() tw(row, {BackgroundColor3=C.rowBg}, SNAP):Play() end)

		if key and winOptions then winOptions[key] = obj end
		self._y = posY + 28; return obj, self
	end

	return col
end

-- ============================================================
--  TAB OBJECT FACTORY
-- ============================================================
local function makeTabObj(panel, registry, openDD, winOptions)
	local tabObj = {}
	local function makeScrollCol(size, pos)
		local sf = Instance.new("ScrollingFrame")
		sf.Size = size; sf.Position = pos or UDim2.new(0,0,0,0)
		sf.BackgroundTransparency = 1; sf.BorderSizePixel = 0
		sf.ScrollBarThickness = 2; sf.ScrollBarImageColor3 = C.accentDim
		sf.CanvasSize = UDim2.new(0,0,0,2000); sf.ZIndex = 2; sf.Parent = panel
		return sf
	end
	function tabObj:TwoColumn()
		local lSF = makeScrollCol(UDim2.new(0.5,-1,1,0))
		local rSF = makeScrollCol(UDim2.new(0.5,-1,1,0), UDim2.new(0.5,1,0,0))
		local div = Instance.new("Frame")
		div.Size = UDim2.new(0,1,1,0); div.Position = UDim2.new(0.5,0,0,0)
		div.BackgroundColor3 = C.borderFaint; div.BorderSizePixel = 0; div.ZIndex = 2; div.Parent = panel
		return makeColumnObj(lSF, registry, openDD, winOptions),
		       makeColumnObj(rSF, registry, openDD, winOptions)
	end
	function tabObj:SingleColumn()
		local sf = makeScrollCol(UDim2.fromScale(1,1))
		return makeColumnObj(sf, registry, openDD, winOptions)
	end
	return tabObj
end

-- ============================================================
--  PUBLIC API
-- ============================================================
local OnyxiteLib = {}
OnyxiteLib.buildBackground = buildBackground

function OnyxiteLib.new(config)
	local win = {}; win._tabPanels = {}; win._tabButtons = {}; win._activeTab = nil; win.Options = {}
	local registry = {}; local openDD = {fn=nil}

	local WIN_W      = config.Width  or 1100
	local WIN_H      = config.Height or 662
	local BORDER     = 5
	local TITLEBAR_H = 36
	local SIDEBAR_OW = 200
	local SIDEBAR_CW = 50
	local WIN_MIN_W  = 700
	local WIN_MIN_H  = 440
	local PROFILE_H  = 66
	local sidebarOpen = true; local menuVisible = true

	local player    = Players.LocalPlayer
	local guiParent = player:WaitForChild("PlayerGui")
	local gui = Instance.new("ScreenGui"); gui.Name = "OnyxiteGUI"; gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; gui.Parent = guiParent

	local outerFrame = Instance.new("Frame"); outerFrame.Name = "WindowFrame"
	outerFrame.Size = UDim2.new(0, WIN_W+BORDER*2, 0, WIN_H+BORDER*2)
	outerFrame.Position = UDim2.new(0.5, -(WIN_W+BORDER*2)/2, 0.5, -(WIN_H+BORDER*2)/2)
	outerFrame.BackgroundColor3 = C.shellOuter; outerFrame.BorderSizePixel = 0; outerFrame.ZIndex = 1; outerFrame.Parent = gui
	corner(outerFrame, 3)
	gradientN(outerFrame, {{0,Color3.fromRGB(4,4,4)},{0.3,Color3.fromRGB(18,18,18)},{0.7,Color3.fromRGB(18,18,18)},{1,Color3.fromRGB(4,4,4)}}, 120)
	stroke(outerFrame, C.shellBorder, 1, 0.3)

	-- Expose for buildBackground
	win._outerFrame = outerFrame
	win._gui = gui

	-- ── Build tiled image background automatically ──────────
	local bgAsset = config.BackgroundImage or "rbxassetid://75303397735790"
	buildBackground(win, bgAsset)

	local main = Instance.new("Frame"); main.Name = "Main"
	main.Size = UDim2.new(1,-BORDER*2,1,-BORDER*2); main.Position = UDim2.new(0,BORDER,0,BORDER)
	main.BackgroundColor3 = C.bgMain; main.BorderSizePixel = 0; main.ZIndex = 2
	main.ClipsDescendants = false; main.Parent = outerFrame
	corner(main, 2)
	gradientN(main, {{0,C.bgSurface},{0.5,C.bgMain},{1,C.bgDeep}}, 160)
	stroke(main, C.borderHard, 1, 0.2)
	-- Semi-transparent so background image shows through
	main.BackgroundTransparency = 0.25

	local topAccent = Instance.new("Frame")
	topAccent.Size = UDim2.new(0,64,0,1)
	topAccent.BackgroundColor3 = C.accentDim; topAccent.BorderSizePixel = 0; topAccent.ZIndex = 6; topAccent.Parent = main; corner(topAccent, 1)
	do local g = Instance.new("UIGradient"); g.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.2),NumberSequenceKeypoint.new(1,1)}); g.Rotation = 0; g.Parent = topAccent end

	local titleBar = Instance.new("Frame"); titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1,0,0,TITLEBAR_H); titleBar.BackgroundColor3 = C.titleBg
	titleBar.BorderSizePixel = 0; titleBar.ZIndex = 4; titleBar.Parent = main
	corner(titleBar, 2)
	gradientN(titleBar, {{0,Color3.fromRGB(18,18,18)},{0.6,Color3.fromRGB(10,10,10)},{1,Color3.fromRGB(5,5,5)}}, 180)
	local tSep = Instance.new("Frame")
	tSep.Size = UDim2.new(1,0,0,1); tSep.Position = UDim2.new(0,0,1,-1)
	tSep.BackgroundColor3 = C.borderSoft; tSep.BorderSizePixel = 0; tSep.ZIndex = 5; tSep.Parent = titleBar
	do local g = Instance.new("UIGradient"); g.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.6),NumberSequenceKeypoint.new(0.5,0),NumberSequenceKeypoint.new(1,0.6)}); g.Rotation = 0; g.Parent = tSep end

	local sDot = Instance.new("Frame")
	sDot.Size = UDim2.new(0,5,0,5); sDot.Position = UDim2.new(0,14,0.5,-2)
	sDot.BackgroundColor3 = C.accentDim; sDot.BorderSizePixel = 0; sDot.ZIndex = 6; sDot.Parent = titleBar; corner(sDot, 3)

	local tLbl = Instance.new("TextLabel")
	tLbl.Text = config.Title or "Onyxite"; tLbl.Font = FONT_BOLD; tLbl.TextSize = 14
	tLbl.TextColor3 = C.textBright; tLbl.BackgroundTransparency = 1
	tLbl.Size = UDim2.new(0,140,1,0); tLbl.Position = UDim2.new(0,26,0,0)
	tLbl.TextXAlignment = Enum.TextXAlignment.Left; tLbl.ZIndex = 6; tLbl.Parent = titleBar

	local vLbl = Instance.new("TextLabel")
	vLbl.Text = config.SubTitle or "v1.0"; vLbl.Font = FONT_REG; vLbl.TextSize = 9
	vLbl.TextColor3 = C.textDim; vLbl.BackgroundTransparency = 1
	vLbl.Size = UDim2.new(0,200,0,12); vLbl.Position = UDim2.new(0,168,0.5,-6)
	vLbl.TextXAlignment = Enum.TextXAlignment.Left; vLbl.ZIndex = 6; vLbl.Parent = titleBar

	local function makeWinBtn(xOff, glyph, hBg, hTxt)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0,22,0,22); b.Position = UDim2.new(1,xOff,0.5,-11)
		b.BackgroundColor3 = Color3.fromRGB(16,16,16); b.BorderSizePixel = 0
		b.Text = glyph; b.Font = FONT_BOLD; b.TextSize = 14
		b.TextColor3 = C.textDim; b.AutoButtonColor = false; b.ZIndex = 8; b.Parent = titleBar; corner(b, 2)
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
	rPill.Size = UDim2.new(0,130,0,26); rPill.Position = UDim2.new(0.5,-65,0,-50)
	rPill.BackgroundColor3 = Color3.fromRGB(12,12,12); rPill.BorderSizePixel = 0; rPill.Text = ""
	rPill.AutoButtonColor = false; rPill.ZIndex = 50; rPill.Visible = false; rPill.Parent = gui
	corner(rPill, 13); stroke(rPill, C.borderHard, 1, 0.1); gradient(rPill, Color3.fromRGB(20,20,20), Color3.fromRGB(8,8,8), 180)
	local pDot2 = Instance.new("Frame")
	pDot2.Size = UDim2.new(0,5,0,5); pDot2.Position = UDim2.new(0,11,0.5,-2)
	pDot2.BackgroundColor3 = C.accentDim; pDot2.BorderSizePixel = 0; pDot2.ZIndex = 52; pDot2.Parent = rPill; corner(pDot2, 3)
	local pLbl = Instance.new("TextLabel")
	pLbl.Text = string.upper(config.Title or "ONYXITE"); pLbl.Font = FONT_BOLD; pLbl.TextSize = 10
	pLbl.TextColor3 = C.textMid; pLbl.BackgroundTransparency = 1
	pLbl.Size = UDim2.new(1,-24,1,0); pLbl.Position = UDim2.new(0,22,0,0)
	pLbl.TextXAlignment = Enum.TextXAlignment.Left; pLbl.ZIndex = 52; pLbl.Parent = rPill
	rPill.MouseEnter:Connect(function() tw(rPill, {BackgroundColor3=Color3.fromRGB(22,22,22)}, SNAP):Play() end)
	rPill.MouseLeave:Connect(function() tw(rPill, {BackgroundColor3=Color3.fromRGB(12,12,12)}, SNAP):Play() end)
	local pDrag, pDS, pSP = false, nil, nil
	rPill.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then pDrag = true; pDS = inp.Position; pSP = rPill.Position end end)
	UIS.InputChanged:Connect(function(inp) if pDrag and inp.UserInputType == Enum.UserInputType.MouseMovement then local d = inp.Position - pDS; rPill.Position = UDim2.new(pSP.X.Scale, pSP.X.Offset+d.X, pSP.Y.Scale, pSP.Y.Offset+d.Y) end end)
	UIS.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then pDrag = false end end)

	-- Close dialog
	local bOver = Instance.new("Frame")
	bOver.Size = UDim2.fromScale(1,1); bOver.BackgroundColor3 = Color3.fromRGB(0,0,0)
	bOver.BackgroundTransparency = 1; bOver.BorderSizePixel = 0; bOver.ZIndex = 90; bOver.Visible = false; bOver.Parent = gui
	local cDlg = Instance.new("Frame")
	cDlg.Size = UDim2.new(0,300,0,158); cDlg.Position = UDim2.new(0.5,-150,0.5,-79)
	cDlg.BackgroundColor3 = C.dialogBg; cDlg.BorderSizePixel = 0; cDlg.ZIndex = 92; cDlg.Parent = bOver
	corner(cDlg, 3); gradientN(cDlg, {{0,Color3.fromRGB(20,20,20)},{1,Color3.fromRGB(6,6,6)}}, 160); stroke(cDlg, C.borderHard, 1, 0.1)
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
		if openDD.fn then openDD.fn(); openDD.fn = nil end
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
	sidebar.BackgroundColor3 = C.sidebarBg; sidebar.BorderSizePixel = 0; sidebar.ZIndex = 4; sidebar.ClipsDescendants = true; sidebar.Parent = main; corner(sidebar, 2)
	gradientN(sidebar, {{0,Color3.fromRGB(14,14,14)},{0.5,Color3.fromRGB(8,8,8)},{1,Color3.fromRGB(4,4,4)}}, 180)
	local sB = Instance.new("Frame")
	sB.Size = UDim2.new(0,1,1,0); sB.Position = UDim2.new(1,-1,0,0)
	sB.BackgroundColor3 = C.borderSoft; sB.BorderSizePixel = 0; sB.ZIndex = 5; sB.Parent = sidebar
	do local g = Instance.new("UIGradient"); g.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.7),NumberSequenceKeypoint.new(0.5,0.1),NumberSequenceKeypoint.new(1,0.7)}); g.Rotation = 90; g.Parent = sB end

	local sLA = Instance.new("Frame")
	sLA.Size = UDim2.new(1,0,0,44); sLA.BackgroundColor3 = Color3.fromRGB(10,10,10); sLA.BorderSizePixel = 0; sLA.ZIndex = 5; sLA.Parent = sidebar; corner(sLA, 2)
	gradientN(sLA, {{0,Color3.fromRGB(20,20,20)},{1,Color3.fromRGB(6,6,6)}}, 180)
	local sLD = Instance.new("Frame")
	sLD.Size = UDim2.new(0,5,0,5); sLD.Position = UDim2.new(0,12,0.5,-2)
	sLD.BackgroundColor3 = C.accentDim; sLD.BorderSizePixel = 0; sLD.ZIndex = 6; sLD.Parent = sLA; corner(sLD, 3)
	local sLT = Instance.new("TextLabel")
	sLT.Text = config.Creator or "Onyxite"; sLT.Font = FONT_SCI; sLT.TextSize = 11
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
		if openDD.fn then openDD.fn(); openDD.fn = nil end
		for tabName, p in pairs(win._tabPanels) do
			if p.Visible and tabName ~= name then
				if p:IsA("CanvasGroup") then tw(p, {GroupTransparency=1}, FAST):Play() end
				task.delay(0.18, function() p.Visible = false; if p:IsA("CanvasGroup") then p.GroupTransparency = 0 end end)
			end
		end
		local newPanel = win._tabPanels[name]
		if newPanel then
			newPanel.Visible = true
			if newPanel:IsA("CanvasGroup") then newPanel.GroupTransparency = 1; tw(newPanel, {GroupTransparency=0}, MED):Play() end
		end
		for _, d in ipairs(win._tabButtons) do
			local active = d.name == name
			if active then
				tw(d.btn, {BackgroundColor3=C.tabActive}, MED):Play()
				tw(d.iL,  {TextColor3=C.textBright},     MED):Play()
				tw(d.lbl, {TextColor3=C.textBright},     MED):Play()
				tw(tabSelector, {Position=UDim2.new(0,0,0,d.btn.Position.Y.Offset+(TAB_H-16)/2), Size=UDim2.new(0,2,0,16)}, SPRING):Play()
			else
				tw(d.btn, {BackgroundColor3=C.tabInact}, FAST):Play()
				tw(d.iL,  {TextColor3=C.textDim},        FAST):Play()
				tw(d.lbl, {TextColor3=C.textDim},        FAST):Play()
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
		local panel = Instance.new("CanvasGroup")
		panel.Size = UDim2.fromScale(1,1); panel.BackgroundTransparency = 1
		panel.Visible = false; panel.GroupTransparency = 0; panel.ZIndex = 2; panel.Parent = cArea
		win._tabPanels[def.Name] = panel

		local btn = Instance.new("TextButton"); btn.Name = def.Name .. "Tab"
		btn.Size = UDim2.new(1,0,0,TAB_H); btn.Position = UDim2.new(0,0,0,yPos)
		btn.BackgroundColor3 = (def.Name == win._activeTab) and C.tabActive or C.tabInact
		btn.BorderSizePixel = 0; btn.Text = ""; btn.AutoButtonColor = false; btn.ZIndex = 6; btn.Parent = sidebar

		local iL = Instance.new("TextLabel")
		iL.Text = def.Icon or "·"; iL.Font = FONT_REG; iL.TextSize = 15
		iL.TextColor3 = (def.Name == win._activeTab) and C.textBright or C.textDim
		iL.BackgroundTransparency = 1; iL.Size = UDim2.new(0,SIDEBAR_CW,1,0)
		iL.TextXAlignment = Enum.TextXAlignment.Center; iL.ZIndex = 7; iL.Parent = btn

		local lbl = Instance.new("TextLabel")
		lbl.Text = def.Name; lbl.Font = FONT_BOLD; lbl.TextSize = 12
		lbl.TextColor3 = (def.Name == win._activeTab) and C.textBright or C.textDim
		lbl.TextTransparency = sidebarOpen and 0 or 1; lbl.BackgroundTransparency = 1
		lbl.Size = UDim2.new(1,-(SIDEBAR_CW+4),1,0); lbl.Position = UDim2.new(0,SIDEBAR_CW,0,0)
		lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 7; lbl.Parent = btn

		if i < #tabDefs then
			local sep = Instance.new("Frame")
			sep.Size = UDim2.new(0.7,0,0,1); sep.Position = UDim2.new(0.15,0,1,-1)
			sep.BackgroundColor3 = C.borderFaint; sep.BackgroundTransparency = 0.2; sep.BorderSizePixel = 0; sep.ZIndex = 6; sep.Parent = btn
		end

		local data = {name=def.Name, btn=btn, iL=iL, lbl=lbl}
		table.insert(win._tabButtons, data)
		local cn = def.Name
		btn.MouseButton1Click:Connect(function() ripple(btn); showTab(cn) end)
		btn.MouseEnter:Connect(function()
			if win._activeTab ~= cn then
				tw(btn, {BackgroundColor3=C.tabHover}, SNAP):Play()
				tw(iL,  {TextColor3=C.textSub},        SNAP):Play()
				tw(lbl, {TextColor3=C.textSub},        SNAP):Play()
			end
		end)
		btn.MouseLeave:Connect(function()
			if win._activeTab ~= cn then
				tw(btn, {BackgroundColor3=C.tabInact}, SNAP):Play()
				tw(iL,  {TextColor3=C.textDim},        SNAP):Play()
				tw(lbl, {TextColor3=C.textDim},        SNAP):Play()
			end
		end)
	end

	if win._activeTab then showTab(win._activeTab) end

	function win:GetTab(name)
		local panel = self._tabPanels[name]; assert(panel, "Tab '" .. tostring(name) .. "' not found.")
		return makeTabObj(panel, registry, openDD, self.Options)
	end

	return win
end

return OnyxiteLib
