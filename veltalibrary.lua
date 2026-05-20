-- VeltaLibrary.lua  —  Black & White edition
-- • Zero color anywhere. Pure black / white / grays only.
-- • RGB cycle and all color animations removed.
-- • Profile card in sidebar bottom-left (avatar thumbnail + display name + username).
-- • Upgraded animations: tab slide-in, button press ripple, dropdown spring, etc.
-- • All element objects retain consistent API: .Value / :SetValue / :GetValue / :OnChanged / .Callback
-- • win.Options[key] for SaveManager compatibility.

local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService  = game:GetService("HttpService")

-- ============================================================
--  PALETTE  —  black / white / gray only
-- ============================================================
local C = {
	-- window shell
	shellOuter   = Color3.fromRGB(8,   8,   8),
	shellBorder  = Color3.fromRGB(55,  55,  55),

	-- backgrounds
	bgMain       = Color3.fromRGB(10,  10,  10),
	bgDeep       = Color3.fromRGB(5,   5,   5),
	bgSurface    = Color3.fromRGB(16,  16,  16),
	bgRaised     = Color3.fromRGB(22,  22,  22),
	bgHover      = Color3.fromRGB(30,  30,  30),
	bgPress      = Color3.fromRGB(38,  38,  38),

	-- sidebar
	sidebarBg    = Color3.fromRGB(7,   7,   7),
	sidebarLine  = Color3.fromRGB(28,  28,  28),
	tabActive    = Color3.fromRGB(20,  20,  20),
	tabInact     = Color3.fromRGB(10,  10,  10),
	tabHover     = Color3.fromRGB(18,  18,  18),

	-- accent (white variants — for active indicators, knobs, fills)
	accentBright = Color3.fromRGB(255, 255, 255),
	accentMid    = Color3.fromRGB(200, 200, 200),
	accentDim    = Color3.fromRGB(120, 120, 120),

	-- text
	textBright   = Color3.fromRGB(245, 245, 245),
	textMid      = Color3.fromRGB(185, 185, 185),
	textSub      = Color3.fromRGB(110, 110, 110),
	textDim      = Color3.fromRGB(60,  60,  60),

	-- borders
	borderHard   = Color3.fromRGB(45,  45,  45),
	borderSoft   = Color3.fromRGB(28,  28,  28),
	borderFaint  = Color3.fromRGB(18,  18,  18),

	-- rows / elements
	rowBg        = Color3.fromRGB(15,  15,  15),
	rowBgAlt     = Color3.fromRGB(20,  20,  20),

	-- titlebar
	titleBg      = Color3.fromRGB(8,   8,   8),

	-- dialog
	dialogBg     = Color3.fromRGB(12,  12,  12),

	-- sliders / knobs
	knob         = Color3.fromRGB(220, 220, 220),
	sliderFill   = Color3.fromRGB(190, 190, 190),
	sliderTrack  = Color3.fromRGB(30,  30,  30),

	-- dropdown
	dropBg       = Color3.fromRGB(10,  10,  10),
	dropItem     = Color3.fromRGB(14,  14,  14),
	dropItemSel  = Color3.fromRGB(22,  22,  22),

	-- checkboxes
	checkOff     = Color3.fromRGB(14,  14,  14),

	-- profile card
	profileBg    = Color3.fromRGB(10,  10,  10),
	profileLine  = Color3.fromRGB(26,  26,  26),
}

-- ============================================================
--  TWEEN PRESETS
-- ============================================================
local FONT_REG  = Enum.Font.Code
local FONT_BOLD = Enum.Font.Code
local FONT_SCI  = Enum.Font.SciFi

-- speed tiers
local SNAP  = TweenInfo.new(0.08,  Enum.EasingStyle.Quad,   Enum.EasingDirection.Out)
local FAST  = TweenInfo.new(0.15,  Enum.EasingStyle.Quad,   Enum.EasingDirection.Out)
local MED   = TweenInfo.new(0.25,  Enum.EasingStyle.Quint,  Enum.EasingDirection.Out)
local SLOW  = TweenInfo.new(0.40,  Enum.EasingStyle.Quint,  Enum.EasingDirection.Out)
-- spring-feel for tab selector / dropdown
local SPRING = TweenInfo.new(0.30,  Enum.EasingStyle.Back,   Enum.EasingDirection.Out)
-- smooth fade
local FADE  = TweenInfo.new(0.20,  Enum.EasingStyle.Sine,   Enum.EasingDirection.InOut)

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
-- multi-stop gradient (takes table of {pos, color})
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

-- Ripple effect: brief white flash that fades out on a frame
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
--  ELEMENT OBJECT  (unchanged API)
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
--  COLOR PICKER  (grayscale — hue bar replaced by gray gradient,
--                SV square replaced by black-to-white brightness pick)
-- ============================================================
local PICKER_PAD = 5
local PICKER_SV  = 58
local PICKER_SL  = 18
local PICKER_H   = PICKER_PAD + PICKER_SV + PICKER_PAD + PICKER_SL + PICKER_PAD + PICKER_SL + PICKER_PAD

local function buildColorPicker(parent, defColor, defOpacity, colorCb)
	defColor   = defColor   or Color3.fromRGB(200, 200, 200)
	defOpacity = defOpacity or 1.0

	local _, _, curV = Color3.toHSV(defColor)
	local curOp = math.clamp(defOpacity, 0, 1)

	local PAD   = PICKER_PAD
	local SV_H  = PICKER_SV
	local SL_H  = PICKER_SL
	local GAP   = 4
	local PREV_W = 0.28

	local panel = Instance.new("Frame")
	panel.Size             = UDim2.new(1, 0, 0, PICKER_H)
	panel.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	panel.BorderSizePixel  = 0
	panel.ZIndex           = 8
	panel.ClipsDescendants = false
	panel.Visible          = false
	panel.Parent           = parent
	corner(panel, 3)
	stroke(panel, C.borderHard, 1, 0.1)

	-- brightness picker (left area)
	local svY   = PAD
	local svBox = Instance.new("Frame")
	svBox.Size             = UDim2.new(1 - PREV_W, -PAD - GAP/2, 0, SV_H)
	svBox.Position         = UDim2.new(0, PAD, 0, svY)
	svBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	svBox.BorderSizePixel  = 0; svBox.ZIndex = 9
	svBox.ClipsDescendants = true; svBox.Parent = panel
	corner(svBox, 3)
	-- horizontal: white → black
	do
		local g = Instance.new("UIGradient")
		g.Color = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromRGB(0,0,0))
		g.Rotation = 0; g.Parent = svBox
	end

	local svCursor = Instance.new("Frame")
	svCursor.Size             = UDim2.new(0, 10, 1, 0)
	svCursor.Position         = UDim2.new(1 - curV, -5, 0, 0)
	svCursor.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	svCursor.BackgroundTransparency = 0.3
	svCursor.BorderSizePixel  = 0; svCursor.ZIndex = 12; svCursor.Parent = svBox
	corner(svCursor, 2); stroke(svCursor, Color3.fromRGB(200,200,200), 1, 0)

	-- preview swatch (right area)
	local prevFrame = Instance.new("Frame")
	prevFrame.Size     = UDim2.new(PREV_W, -PAD - GAP/2, 0, SV_H)
	prevFrame.Position = UDim2.new(1 - PREV_W, GAP/2, 0, svY)
	prevFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	prevFrame.BorderSizePixel  = 0; prevFrame.ZIndex = 9; prevFrame.Parent = panel
	corner(prevFrame, 3)
	-- checker-ish background via multi-stop gradient
	gradientN(prevFrame, {
		{0,   Color3.fromRGB(55, 55, 55)},
		{0.5, Color3.fromRGB(35, 35, 35)},
		{1,   Color3.fromRGB(55, 55, 55)},
	}, 45)

	local prevColor = Instance.new("Frame")
	prevColor.Size = UDim2.fromScale(1,1)
	prevColor.BackgroundColor3 = defColor
	prevColor.BackgroundTransparency = 1 - defOpacity
	prevColor.BorderSizePixel = 0; prevColor.ZIndex = 10; prevColor.Parent = prevFrame
	corner(prevColor, 3)

	-- brightness label row
	local brY   = svY + SV_H + PAD
	local brMid = brY + SL_H / 2

	local brLbl = Instance.new("TextLabel")
	brLbl.Text = "Value"; brLbl.Font = FONT_REG; brLbl.TextSize = 9
	brLbl.TextColor3 = C.textDim; brLbl.BackgroundTransparency = 1
	brLbl.Size = UDim2.new(0, 34, 0, SL_H); brLbl.Position = UDim2.new(0, PAD, 0, brY)
	brLbl.TextXAlignment = Enum.TextXAlignment.Left; brLbl.ZIndex = 9; brLbl.Parent = panel

	local brVal = Instance.new("TextLabel")
	brVal.Text = math.floor(curV*100).."%"; brVal.Font = FONT_REG; brVal.TextSize = 9
	brVal.TextColor3 = C.textSub; brVal.BackgroundTransparency = 1
	brVal.Size = UDim2.new(0, 32, 0, SL_H); brVal.Position = UDim2.new(1, -PAD-32, 0, brY)
	brVal.TextXAlignment = Enum.TextXAlignment.Right; brVal.ZIndex = 9; brVal.Parent = panel

	local brTrack = Instance.new("Frame")
	brTrack.Size     = UDim2.new(1, -(PAD+38 + PAD+36), 0, 4)
	brTrack.Position = UDim2.new(0, PAD+38, 0, brMid-2)
	brTrack.BackgroundColor3 = Color3.fromRGB(8, 8, 8); brTrack.BorderSizePixel = 0
	brTrack.ZIndex = 9; brTrack.Parent = panel; corner(brTrack, 2)
	gradient(brTrack, Color3.fromRGB(0,0,0), Color3.fromRGB(255,255,255), 0)

	local brKnob = Instance.new("TextButton")
	brKnob.Size = UDim2.new(0, 10, 0, 10); brKnob.Position = UDim2.new(curV, -5, 0, brMid-5)
	brKnob.BackgroundColor3 = C.knob; brKnob.BorderSizePixel = 0
	brKnob.Text = ""; brKnob.AutoButtonColor = false; brKnob.ZIndex = 11; brKnob.Parent = panel
	corner(brKnob, 5); stroke(brKnob, Color3.fromRGB(60,60,60), 1, 0)

	-- opacity row
	local opY   = brY + SL_H + PAD
	local opMid = opY + SL_H / 2

	local opLbl = Instance.new("TextLabel")
	opLbl.Text = "Opacity"; opLbl.Font = FONT_REG; opLbl.TextSize = 9
	opLbl.TextColor3 = C.textDim; opLbl.BackgroundTransparency = 1
	opLbl.Size = UDim2.new(0, 34, 0, SL_H); opLbl.Position = UDim2.new(0, PAD, 0, opY)
	opLbl.TextXAlignment = Enum.TextXAlignment.Left; opLbl.ZIndex = 9; opLbl.Parent = panel

	local opVal = Instance.new("TextLabel")
	opVal.Text = math.floor(curOp*100).."%"; opVal.Font = FONT_REG; opVal.TextSize = 9
	opVal.TextColor3 = C.textSub; opVal.BackgroundTransparency = 1
	opVal.Size = UDim2.new(0, 32, 0, SL_H); opVal.Position = UDim2.new(1, -PAD-32, 0, opY)
	opVal.TextXAlignment = Enum.TextXAlignment.Right; opVal.ZIndex = 9; opVal.Parent = panel

	local opTrack = Instance.new("Frame")
	opTrack.Size     = UDim2.new(1, -(PAD+38 + PAD+36), 0, 4)
	opTrack.Position = UDim2.new(0, PAD+38, 0, opMid-2)
	opTrack.BackgroundColor3 = Color3.fromRGB(8,8,8); opTrack.BorderSizePixel = 0
	opTrack.ZIndex = 9; opTrack.Parent = panel; corner(opTrack, 2)
	-- transparent → white
	do
		local g = Instance.new("UIGradient")
		g.Color = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromRGB(255,255,255))
		g.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0)})
		g.Rotation = 0; g.Parent = opTrack
	end

	local opKnob = Instance.new("TextButton")
	opKnob.Size = UDim2.new(0,10,0,10); opKnob.Position = UDim2.new(curOp,-5,0,opMid-5)
	opKnob.BackgroundColor3 = C.knob; opKnob.BorderSizePixel = 0
	opKnob.Text = ""; opKnob.AutoButtonColor = false; opKnob.ZIndex = 11; opKnob.Parent = panel
	corner(opKnob, 5); stroke(opKnob, Color3.fromRGB(60,60,60), 1, 0)

	-- state
	local function getColor()   return Color3.fromHSV(0, 0, curV) end
	local function getOpacity() return curOp end

	local function refreshAll()
		local c = getColor()
		svCursor.Position  = UDim2.new(1 - curV, -5, 0, 0)
		brKnob.Position    = UDim2.new(curV, -5, 0, brMid-5)
		brVal.Text         = math.floor(curV*100).."%"
		opKnob.Position    = UDim2.new(curOp, -5, 0, opMid-5)
		opVal.Text         = math.floor(curOp*100).."%"
		prevColor.BackgroundColor3       = c
		prevColor.BackgroundTransparency = 1 - curOp
		if colorCb then colorCb(c, curOp) end
	end

	-- drag
	local svDrag, brDrag, opDrag = false, false, false
	svBox.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			svDrag = true
			curV = 1 - math.clamp((inp.Position.X - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
			refreshAll()
		end
	end)
	brKnob.MouseButton1Down:Connect(function() brDrag = true end)
	opKnob.MouseButton1Down:Connect(function() opDrag = true end)

	UIS.InputChanged:Connect(function(inp)
		if inp.UserInputType ~= Enum.UserInputType.MouseMovement then return end
		if svDrag then
			curV = 1 - math.clamp((inp.Position.X - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
			refreshAll()
		end
		if brDrag then
			curV = math.clamp((inp.Position.X - brTrack.AbsolutePosition.X) / brTrack.AbsoluteSize.X, 0, 1)
			refreshAll()
		end
		if opDrag then
			curOp = math.clamp((inp.Position.X - opTrack.AbsolutePosition.X) / opTrack.AbsoluteSize.X, 0, 1)
			refreshAll()
		end
	end)
	UIS.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			svDrag = false; brDrag = false; opDrag = false
		end
	end)

	local function setColorRaw(color, opacity)
		_, _, curV = Color3.toHSV(color)
		curOp = math.clamp(opacity or curOp, 0, 1)
		refreshAll()
	end

	return panel, getColor, getOpacity, setColorRaw
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
				if animate and delta ~= 0 then
					tw(e.frame, {Position = tp}, MED):Play()
				else
					e.frame.Position = tp
				end
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
		row.Size             = UDim2.new(1, -12, 0, h)
		row.Position         = UDim2.new(0, 6, 0, posY)
		row.BackgroundColor3 = C.rowBg
		row.BorderSizePixel  = 0; row.ZIndex = 3; row.Parent = sf
		corner(row, 2)
		stroke(row, C.borderSoft, 1, 0.5)
		-- subtle top-highlight gradient
		gradientN(row, {
			{0,   C.rowBgAlt},
			{0.4, C.rowBg},
			{1,   C.bgDeep},
		}, 180)
		regItem(row, posY); return row
	end

	local col = {_sf = sf, _y = 8}

	function col:Finalise()
		self._sf.CanvasSize = UDim2.new(0, 0, 0, self._y + 20)
	end

	-- ── Header ──────────────────────────────────────────────
	function col:Header(text)
		local posY = self._y
		local wrap = Instance.new("Frame")
		wrap.Size = UDim2.new(1,-10,0,22); wrap.Position = UDim2.new(0,5,0,posY)
		wrap.BackgroundTransparency = 1; wrap.Parent = sf; regItem(wrap, posY)
		local lbl = Instance.new("TextLabel")
		lbl.Text = string.upper(text); lbl.Font = FONT_BOLD; lbl.TextSize = 10
		lbl.TextColor3 = C.accentDim; lbl.BackgroundTransparency = 1
		lbl.Size = UDim2.new(1,0,0,14)
		lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 3; lbl.Parent = wrap
		local bar = Instance.new("Frame")
		bar.Size = UDim2.new(1,0,0,1); bar.Position = UDim2.new(0,0,0,16)
		bar.BackgroundColor3 = C.borderSoft; bar.BorderSizePixel = 0; bar.ZIndex = 3; bar.Parent = wrap
		-- fade out the header bar
		do local g = Instance.new("UIGradient"); g.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}); g.Rotation=0; g.Parent=bar end
		self._y = posY + 24; return self
	end

	-- ── Separator ───────────────────────────────────────────
	function col:Separator()
		local posY = self._y
		local f = Instance.new("Frame")
		f.Size = UDim2.new(1,-24,0,1); f.Position = UDim2.new(0,12,0,posY)
		f.BackgroundColor3 = C.borderFaint; f.BorderSizePixel = 0; f.ZIndex = 3; f.Parent = sf
		do local g = Instance.new("UIGradient"); g.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.4),NumberSequenceKeypoint.new(0.5,0),NumberSequenceKeypoint.new(1,0.4)}); g.Rotation=0; g.Parent=f end
		regItem(f, posY); self._y = posY + 9; return self
	end

	-- ── Spacer ──────────────────────────────────────────────
	function col:Spacer(h) self._y = self._y + (h or 8); return self end

	-- ── Label ───────────────────────────────────────────────
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

	-- ── KeyDisplay ──────────────────────────────────────────
	function col:KeyDisplay(key)
		local posY = self._y
		local kD = Instance.new("TextButton")
		kD.Size = UDim2.new(1,-12,0,22); kD.Position = UDim2.new(0,6,0,posY)
		kD.BackgroundColor3 = C.bgRaised; kD.BorderSizePixel = 0; kD.Text = key or "None"
		kD.Font = FONT_BOLD; kD.TextSize = 12; kD.TextColor3 = C.textBright; kD.AutoButtonColor = false
		kD.ZIndex = 3; kD.Parent = sf; corner(kD, 2)
		stroke(kD, C.borderHard, 1, 0)
		regItem(kD, posY); self._y = posY + 28; return self
	end

	-- ================================================================
	--  CHECKBOX
	-- ================================================================
	function col:Checkbox(key, labelText, default, callback)
		local posY = self._y
		local row  = makeRow(posY, 22)
		local obj  = newElementObj(default or false, callback)

		local box = Instance.new("TextButton")
		box.Size = UDim2.new(0,13,0,13); box.Position = UDim2.new(0,4,0.5,-6)
		box.BackgroundColor3 = obj.Value and C.accentMid or C.checkOff
		box.BorderSizePixel = 0; box.Text = ""; box.AutoButtonColor = false
		box.ZIndex = 4; box.Parent = row; corner(box, 2)
		local bStroke = stroke(box, obj.Value and C.accentDim or C.borderHard, 1)

		local tick = Instance.new("TextLabel")
		tick.Text = "✓"; tick.Font = FONT_BOLD; tick.TextSize = 9
		tick.TextColor3 = C.bgDeep; tick.BackgroundTransparency = 1
		tick.Size = UDim2.fromScale(1,1)
		tick.TextXAlignment = Enum.TextXAlignment.Center
		tick.TextYAlignment = Enum.TextYAlignment.Center
		tick.Visible = obj.Value; tick.ZIndex = 5; tick.Parent = box

		local lbl = Instance.new("TextLabel")
		lbl.Text = labelText; lbl.Font = FONT_REG; lbl.TextSize = 12
		lbl.TextColor3 = obj.Value and C.textBright or C.textMid
		lbl.BackgroundTransparency = 1
		lbl.Size = UDim2.new(1,-24,1,0); lbl.Position = UDim2.new(0,22,0,0)
		lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 4; lbl.Parent = row

		local function applyState(v)
			tick.Visible = v
			if v then
				tw(box,    {BackgroundColor3 = C.accentMid}, FAST):Play()
				tw(bStroke,{Color = C.accentDim},            FAST):Play()
				tw(lbl,    {TextColor3 = C.textBright},      FAST):Play()
			else
				tw(box,    {BackgroundColor3 = C.checkOff},  FAST):Play()
				tw(bStroke,{Color = C.borderHard},           FAST):Play()
				tw(lbl,    {TextColor3 = C.textMid},         FAST):Play()
			end
		end

		function obj:SetValue(v)
			v = not not v
			applyState(v)
			self:_fire(v)
		end

		box.MouseButton1Click:Connect(function()
			ripple(row)
			obj:SetValue(not obj.Value)
		end)
		row.MouseEnter:Connect(function()
			if not obj.Value then tw(lbl, {TextColor3 = C.textBright}, SNAP):Play() end
			tw(row, {BackgroundColor3 = C.bgHover}, SNAP):Play()
		end)
		row.MouseLeave:Connect(function()
			if not obj.Value then tw(lbl, {TextColor3 = C.textMid}, SNAP):Play() end
			tw(row, {BackgroundColor3 = C.rowBg}, SNAP):Play()
		end)

		if key and winOptions then winOptions[key] = obj end
		self._y = posY + 26; return obj, self
	end

	-- ================================================================
	--  DROPDOWN  (with optional grayscale color picker)
	-- ================================================================
	function col:Dropdown(key, labelText, options, default, callback,
		doColorPicker, defColor, defOpacity, colorCb)
		local posY  = self._y
		local COUNT = #options
		local LIST_H = COUNT * ITEM_H

		local ddOpen = false
		local cpOpen = false

		local function containerH()
			return 22
				+ (ddOpen and LIST_H or 0)
				+ (cpOpen and (PICKER_H + 2) or 0)
		end

		local selIdx = 1
		for i, v in ipairs(options) do if v == (default or options[1]) then selIdx = i end end
		local obj = newElementObj(options[selIdx], callback)

		-- container
		local container = Instance.new("Frame")
		container.Size             = UDim2.new(1, -12, 0, 22)
		container.Position         = UDim2.new(0, 6, 0, posY)
		container.BackgroundColor3 = C.rowBg
		container.ClipsDescendants = false
		container.ZIndex           = 3
		container.Parent           = sf
		corner(container, 2); stroke(container, C.borderSoft, 1, 0.5)
		gradientN(container, {{0,C.rowBgAlt},{0.4,C.rowBg},{1,C.bgDeep}}, 180)
		regItem(container, posY)

		local SWATCH_W = doColorPicker and 18 or 0
		if labelText ~= "" then
			local lbl = Instance.new("TextLabel")
			lbl.Text = labelText; lbl.Font = FONT_REG; lbl.TextSize = 12
			lbl.TextColor3 = C.textMid; lbl.BackgroundTransparency = 1
			lbl.Size = UDim2.new(0.44, -SWATCH_W, 0, 22)
			lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 4; lbl.Parent = container
		end

		local swatchBtn, swatchStroke
		if doColorPicker then
			defColor   = defColor   or Color3.fromRGB(200, 200, 200)
			defOpacity = defOpacity or 1.0
			swatchBtn = Instance.new("TextButton")
			swatchBtn.Size             = UDim2.new(0, 13, 0, 13)
			swatchBtn.Position         = UDim2.new(0.44, -SWATCH_W, 0, 4)
			swatchBtn.BackgroundColor3 = defColor
			swatchBtn.BorderSizePixel  = 0; swatchBtn.Text = ""
			swatchBtn.AutoButtonColor  = false; swatchBtn.ZIndex = 60
			swatchBtn.Parent           = container
			corner(swatchBtn, 2)
			swatchStroke = stroke(swatchBtn, C.borderHard, 1.5, 0)
		end

		local btnX = (labelText ~= "") and 0.45 or 0
		local btnW = (labelText ~= "") and 0.54 or 1

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(btnW, 0, 0, 22); btn.Position = UDim2.new(btnX, 0, 0, 0)
		btn.BackgroundColor3 = C.dropBg; btn.BorderSizePixel = 0
		btn.Text = ""; btn.AutoButtonColor = false; btn.ZIndex = 6; btn.Parent = container
		corner(btn, 2)
		local btnStroke = stroke(btn, C.borderSoft, 1)
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
		listFrame.Size             = UDim2.new(btnW, 0, 0, 0)
		listFrame.Position         = UDim2.new(btnX, 0, 0, 22)
		listFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
		listFrame.BorderSizePixel  = 0; listFrame.ClipsDescendants = true
		listFrame.Visible          = false; listFrame.ZIndex = 20; listFrame.Parent = container
		corner(listFrame, 2); stroke(listFrame, C.borderHard, 1, 0.1)
		gradient(listFrame, Color3.fromRGB(16,16,16), Color3.fromRGB(8,8,8), 180)

		local pickerPanel, getPColor, getPOpacity, setPickerRaw
		local function pickerY() return 22 + (ddOpen and LIST_H or 0) end
		local function updatePickerPos()
			if pickerPanel then pickerPanel.Position = UDim2.new(0,0,0, pickerY()) end
		end

		local cpObj
		if doColorPicker then
			pickerPanel, getPColor, getPOpacity, setPickerRaw = buildColorPicker(
				container, defColor, defOpacity,
				function(c, op)
					if swatchBtn then swatchBtn.BackgroundColor3 = c end
					if cpObj then cpObj:_fire({Color=c, Opacity=op}) end
					if colorCb then colorCb(c, op) end
				end
			)
			pickerPanel.Position = UDim2.new(0, 0, 0, pickerY())
			cpObj = newElementObj({Color=defColor, Opacity=defOpacity}, colorCb)
			function cpObj:SetValue(color, opacity)
				if setPickerRaw then setPickerRaw(color, opacity or 1) end
				self:_fire({Color=color, Opacity=opacity or 1})
			end
			if key and winOptions then winOptions[key.."_Color"] = cpObj end
		end

		-- open / close
		local function closeDD_internal()
			ddOpen = false; openDD.fn = nil
			tw(arrow, {Rotation=0, TextColor3=C.textDim}, MED):Play()
			tw(listFrame, {Size=UDim2.new(btnW,0,0,0)}, MED):Play()
			tw(btn, {BackgroundColor3=C.dropBg}, FAST):Play()
			tw(btnStroke, {Color=C.borderSoft}, FAST):Play()
			tw(selLbl, {TextColor3=C.textMid}, FAST):Play()
			tw(container, {Size=UDim2.new(1,-12,0,containerH())}, MED):Play()
			task.delay(0.26, function() listFrame.Visible = false end)
			shiftBelow(posY, -LIST_H, true)
			updatePickerPos()
		end

		local function openDD_internal()
			if openDD.fn then openDD.fn() end
			ddOpen = true; openDD.fn = closeDD_internal
			listFrame.Visible = true; listFrame.Size = UDim2.new(btnW,0,0,0)
			-- spring-feel open
			tw(arrow, {Rotation=180, TextColor3=C.textBright}, SPRING):Play()
			tw(listFrame, {Size=UDim2.new(btnW,0,0,LIST_H)}, SPRING):Play()
			tw(btn, {BackgroundColor3=Color3.fromRGB(20,20,20)}, FAST):Play()
			tw(btnStroke, {Color=C.borderHard}, FAST):Play()
			tw(selLbl, {TextColor3=C.textBright}, FAST):Play()
			tw(container, {Size=UDim2.new(1,-12,0,containerH())}, MED):Play()
			shiftBelow(posY, LIST_H, true)
			updatePickerPos()
		end

		-- option rows
		local optHighlights = {}
		for i, optText in ipairs(options) do
			local optBtn = Instance.new("TextButton")
			optBtn.Size = UDim2.new(1,0,0,ITEM_H); optBtn.Position = UDim2.new(0,0,0,(i-1)*ITEM_H)
			optBtn.BackgroundColor3 = (i == selIdx) and C.dropItemSel or C.dropItem
			optBtn.BackgroundTransparency = (i == selIdx) and 0 or 1
			optBtn.BorderSizePixel = 0; optBtn.Text = ""
			optBtn.AutoButtonColor = false; optBtn.ZIndex = 21; optBtn.Parent = listFrame

			local selBar = Instance.new("Frame")
			selBar.Size = UDim2.new(0,2,0.55,0); selBar.Position = UDim2.new(0,2,0.22,0)
			selBar.BackgroundColor3 = C.accentMid
			selBar.BorderSizePixel = 0; selBar.Visible = (i==selIdx); selBar.ZIndex = 22; selBar.Parent = optBtn; corner(selBar, 1)

			local optLbl = Instance.new("TextLabel")
			optLbl.Text = optText; optLbl.Font = FONT_REG; optLbl.TextSize = 11
			optLbl.TextColor3 = (i==selIdx) and C.textBright or C.textMid
			optLbl.BackgroundTransparency = 1
			optLbl.Size = UDim2.new(1,-14,1,0); optLbl.Position = UDim2.new(0,12,0,0)
			optLbl.TextXAlignment = Enum.TextXAlignment.Left; optLbl.ZIndex = 22; optLbl.Parent = optBtn
			optHighlights[i] = {btn=optBtn, lbl=optLbl, bar=selBar}

			if i < COUNT then
				local sep = Instance.new("Frame"); sep.Size = UDim2.new(0.88,0,0,1); sep.Position = UDim2.new(0.06,0,1,-1)
				sep.BackgroundColor3 = C.borderFaint; sep.BackgroundTransparency = 0; sep.BorderSizePixel = 0; sep.ZIndex = 22; sep.Parent = optBtn
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
				-- deselect all
				for j, h in ipairs(optHighlights) do
					tw(h.btn, {BackgroundTransparency=1}, SNAP):Play()
					tw(h.lbl, {TextColor3 = (j==i) and C.textBright or C.textMid}, SNAP):Play()
					h.bar.Visible = (j==i)
				end
				tw(optBtn, {BackgroundColor3=C.dropItemSel, BackgroundTransparency=0}, SNAP):Play()
				selIdx = i; selLbl.Text = optText
				closeDD_internal()
				obj:_fire(optText)
				if obj.Callback then pcall(obj.Callback, optText, i) end
			end)
		end

		function obj:SetValue(v)
			for i, optText in ipairs(options) do
				if optText == v then
					selIdx = i; selLbl.Text = v
					for j, h in ipairs(optHighlights) do
						tw(h.btn, {BackgroundTransparency = (j==i) and 0 or 1}, SNAP):Play()
						tw(h.lbl, {TextColor3 = (j==i) and C.textBright or C.textMid}, SNAP):Play()
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
			if not ddOpen then tw(btn,{BackgroundColor3=Color3.fromRGB(18,18,18)},SNAP):Play(); tw(btnStroke,{Color=C.borderHard},SNAP):Play() end
		end)
		btn.MouseLeave:Connect(function()
			if not ddOpen then tw(btn,{BackgroundColor3=C.dropBg},SNAP):Play(); tw(btnStroke,{Color=C.borderSoft},SNAP):Play() end
		end)

		-- color picker toggle
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

	-- ================================================================
	--  SLIDER
	-- ================================================================
	function col:Slider(key, labelText, minVal, maxVal, default, callback)
		local posY = self._y
		local row  = makeRow(posY, 22)
		local obj  = newElementObj(default, callback)

		local lbl = Instance.new("TextLabel")
		lbl.Text = labelText; lbl.Font = FONT_REG; lbl.TextSize = 12; lbl.TextColor3 = C.textMid
		lbl.BackgroundTransparency = 1; lbl.Size = UDim2.new(0.42,0,1,0)
		lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 4; lbl.Parent = row

		local valLbl = Instance.new("TextLabel")
		valLbl.Text = tostring(default); valLbl.Font = FONT_REG; valLbl.TextSize = 10
		valLbl.TextColor3 = C.accentMid; valLbl.BackgroundTransparency = 1
		valLbl.Size = UDim2.new(0.13,0,1,0); valLbl.Position = UDim2.new(0.87,0,0,0)
		valLbl.TextXAlignment = Enum.TextXAlignment.Right; valLbl.ZIndex = 4; valLbl.Parent = row

		local track = Instance.new("Frame")
		track.Size = UDim2.new(0.42,0,0,3); track.Position = UDim2.new(0.43,0,0.5,-1)
		track.BackgroundColor3 = C.sliderTrack; track.BorderSizePixel = 0; track.ZIndex = 4; track.Parent = row
		corner(track, 2); stroke(track, C.borderFaint, 1, 0.3)

		local pct = (default - minVal) / math.max(maxVal - minVal, 1)
		local fill = Instance.new("Frame")
		fill.Size = UDim2.new(pct,0,1,0); fill.BackgroundColor3 = C.sliderFill
		fill.BorderSizePixel = 0; fill.ZIndex = 5; fill.Parent = track; corner(fill, 2)
		-- fill gradient: dim at left, bright at right
		gradient(fill, Color3.fromRGB(100,100,100), Color3.fromRGB(220,220,220), 0)

		local knob = Instance.new("TextButton")
		knob.Size = UDim2.new(0,11,0,11); knob.Position = UDim2.new(pct,-5,0.5,-5)
		knob.BackgroundColor3 = C.knob; knob.BorderSizePixel = 0; knob.Text = ""
		knob.AutoButtonColor = false; knob.ZIndex = 6; knob.Parent = track; corner(knob, 6)
		stroke(knob, C.borderHard, 1.5, 0)

		local function applyValue(v)
			v = math.clamp(v, minVal, maxVal)
			local p = (v - minVal) / math.max(maxVal - minVal, 1)
			tw(fill,  {Size = UDim2.new(p,0,1,0)},   SNAP):Play()
			tw(knob,  {Position = UDim2.new(p,-5,0.5,-5)}, SNAP):Play()
			valLbl.Text = tostring(v)
			obj:_fire(v)
		end

		function obj:SetValue(v)
			applyValue(math.floor(v + 0.5))
		end

		local drag = false
		knob.MouseButton1Down:Connect(function()
			drag = true
			tw(knob, {Size=UDim2.new(0,13,0,13), Position=UDim2.new(pct,-6,0.5,-6)}, SNAP):Play()
		end)
		UIS.InputEnded:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 and drag then
				drag = false
				tw(knob, {Size=UDim2.new(0,11,0,11)}, SNAP):Play()
			end
		end)
		UIS.InputChanged:Connect(function(inp)
			if drag and inp.UserInputType == Enum.UserInputType.MouseMovement then
				local p = math.clamp((inp.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
				local v = math.floor(minVal + (maxVal-minVal)*p + 0.5)
				applyValue(v)
			end
		end)

		row.MouseEnter:Connect(function() tw(row, {BackgroundColor3=C.bgHover}, SNAP):Play() end)
		row.MouseLeave:Connect(function() tw(row, {BackgroundColor3=C.rowBg},   SNAP):Play() end)

		if key and winOptions then winOptions[key] = obj end
		self._y = posY + 26; return obj, self
	end

	-- ================================================================
	--  KEYBIND
	-- ================================================================
	function col:Keybind(key, labelText, defaultKey, callback)
		local posY = self._y
		local row  = makeRow(posY, 22)
		local obj  = newElementObj(defaultKey or "None", callback)

		local lbl = Instance.new("TextLabel")
		lbl.Text = labelText; lbl.Font = FONT_REG; lbl.TextSize = 12; lbl.TextColor3 = C.textMid
		lbl.BackgroundTransparency = 1; lbl.Size = UDim2.new(0.55,0,1,0)
		lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 4; lbl.Parent = row

		local kBtn = Instance.new("TextButton")
		kBtn.Size = UDim2.new(0.4,0,0.72,0); kBtn.Position = UDim2.new(0.57,0,0.14,0)
		kBtn.BackgroundColor3 = C.bgRaised; kBtn.BorderSizePixel = 0; kBtn.Text = obj.Value
		kBtn.Font = FONT_BOLD; kBtn.TextSize = 10; kBtn.TextColor3 = C.textMid; kBtn.AutoButtonColor = false
		kBtn.ZIndex = 4; kBtn.Parent = row; corner(kBtn, 2)
		local kS = stroke(kBtn, C.borderHard, 1, 0.1)

		local picking = false

		function obj:SetValue(k)
			k = k or "None"; kBtn.Text = k
			-- flash the button
			tw(kBtn, {BackgroundColor3=C.bgPress}, SNAP):Play()
			task.delay(0.18, function() tw(kBtn, {BackgroundColor3=C.bgRaised}, FAST):Play() end)
			self:_fire(k)
		end

		kBtn.MouseButton1Click:Connect(function()
			if picking then return end
			picking = true
			kBtn.Text = "..."
			tw(kBtn, {BackgroundColor3=C.bgHover}, SNAP):Play()
			tw(kS, {Color=C.accentDim}, SNAP):Play()
			local conn
			conn = UIS.InputBegan:Connect(function(inp, gp)
				if gp then return end
				local k
				if inp.UserInputType == Enum.UserInputType.Keyboard then k = inp.KeyCode.Name
				elseif inp.UserInputType == Enum.UserInputType.MouseButton1 then k = "MouseLeft"
				elseif inp.UserInputType == Enum.UserInputType.MouseButton2 then k = "MouseRight" end
				if k then conn:Disconnect(); picking = false
					tw(kS, {Color=C.borderHard}, FAST):Play()
					obj:SetValue(k) end
			end)
		end)
		kBtn.MouseEnter:Connect(function() tw(kBtn,{BackgroundColor3=C.bgHover},SNAP):Play() end)
		kBtn.MouseLeave:Connect(function() if not picking then tw(kBtn,{BackgroundColor3=C.bgRaised},SNAP):Play() end end)
		row.MouseEnter:Connect(function() tw(row,{BackgroundColor3=C.bgHover},SNAP):Play() end)
		row.MouseLeave:Connect(function() tw(row,{BackgroundColor3=C.rowBg},SNAP):Play() end)

		if key and winOptions then winOptions[key] = obj end
		self._y = posY + 26; return obj, self
	end

	-- ================================================================
	--  PAIRED CHECKBOX
	-- ================================================================
	function col:PairedCheckbox(keyL, keyR, lL, dL, lR, dR, cbL, cbR)
		local posY = self._y; local row = makeRow(posY, 22)
		local objL = newElementObj(dL or false, cbL)
		local objR = newElementObj(dR or false, cbR)

		local function makeMini(text, xScale, obj)
			local box = Instance.new("TextButton")
			box.Size = UDim2.new(0,12,0,12); box.Position = UDim2.new(xScale,3,0.5,-6)
			box.BackgroundColor3 = obj.Value and C.accentMid or C.checkOff; box.BorderSizePixel = 0
			box.Text = ""; box.AutoButtonColor = false; box.ZIndex = 4; box.Parent = row; corner(box, 2)
			local bS = stroke(box, obj.Value and C.accentDim or C.borderHard, 1)
			local tick = Instance.new("TextLabel")
			tick.Text = "✓"; tick.Font = FONT_BOLD; tick.TextSize = 8; tick.TextColor3 = C.bgDeep
			tick.BackgroundTransparency = 1; tick.Size = UDim2.fromScale(1,1)
			tick.TextXAlignment = Enum.TextXAlignment.Center; tick.TextYAlignment = Enum.TextYAlignment.Center
			tick.Visible = obj.Value; tick.ZIndex = 5; tick.Parent = box
			local ml = Instance.new("TextLabel")
			ml.Text = text; ml.Font = FONT_REG; ml.TextSize = 11
			ml.TextColor3 = obj.Value and C.textBright or C.textMid
			ml.BackgroundTransparency = 1; ml.Size = UDim2.new(0.44,0,1,0); ml.Position = UDim2.new(xScale+0.04,0,0,0)
			ml.TextXAlignment = Enum.TextXAlignment.Left; ml.ZIndex = 4; ml.Parent = row

			function obj:SetValue(v)
				v = not not v; tick.Visible = v
				tw(box, {BackgroundColor3 = v and C.accentMid or C.checkOff}, FAST):Play()
				tw(bS,  {Color = v and C.accentDim or C.borderHard}, FAST):Play()
				tw(ml,  {TextColor3 = v and C.textBright or C.textMid}, FAST):Play()
				self:_fire(v)
			end
			box.MouseButton1Click:Connect(function() ripple(row); obj:SetValue(not obj.Value) end)
		end

		makeMini(lL, 0,   objL)
		makeMini(lR, 0.5, objR)
		row.MouseEnter:Connect(function() tw(row,{BackgroundColor3=C.bgHover},SNAP):Play() end)
		row.MouseLeave:Connect(function() tw(row,{BackgroundColor3=C.rowBg},SNAP):Play() end)

		if keyL and winOptions then winOptions[keyL] = objL end
		if keyR and winOptions then winOptions[keyR] = objR end
		self._y = posY + 24; return objL, objR, self
	end

	-- ================================================================
	--  EXPANDABLE CHECKBOX
	-- ================================================================
	function col:ExpandableCheckbox(key, labelText, default, callback, subBuilder)
		local posY = self._y; local row = makeRow(posY, 22)
		local obj  = newElementObj(default or false, callback)

		local box = Instance.new("TextButton")
		box.Size = UDim2.new(0,13,0,13); box.Position = UDim2.new(0,4,0.5,-6)
		box.BackgroundColor3 = obj.Value and C.accentMid or C.checkOff; box.BorderSizePixel = 0
		box.Text = ""; box.AutoButtonColor = false; box.ZIndex = 4; box.Parent = row; corner(box, 2)
		local bS = stroke(box, obj.Value and C.accentDim or C.borderHard, 1)

		local tick = Instance.new("TextLabel")
		tick.Text = "✓"; tick.Font = FONT_BOLD; tick.TextSize = 9; tick.TextColor3 = C.bgDeep
		tick.BackgroundTransparency = 1; tick.Size = UDim2.fromScale(1,1)
		tick.TextXAlignment = Enum.TextXAlignment.Center; tick.TextYAlignment = Enum.TextYAlignment.Center
		tick.Visible = obj.Value; tick.ZIndex = 5; tick.Parent = box

		local lbl = Instance.new("TextLabel")
		lbl.Text = labelText; lbl.Font = FONT_REG; lbl.TextSize = 12
		lbl.TextColor3 = obj.Value and C.textBright or C.textMid
		lbl.BackgroundTransparency = 1; lbl.Size = UDim2.new(1,-36,1,0); lbl.Position = UDim2.new(0,22,0,0)
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
		subSF.Size = UDim2.fromScale(1,1); subSF.BackgroundTransparency = 1; subSF.BorderSizePixel = 0
		subSF.ScrollBarThickness = 2; subSF.ScrollBarImageColor3 = C.accentDim
		subSF.CanvasSize = UDim2.new(0,0,0,2000); subSF.ZIndex = 2; subSF.Parent = subPanel

		local subReg = {}
		local subColObj = makeColumnObj(subSF, subReg, openDD, winOptions)
		if subBuilder then subBuilder(subColObj) end
		subColObj:Finalise()
		local subH = math.min(subColObj._y + 8, 220)
		subSF.CanvasSize = UDim2.new(0,0,0,subColObj._y+8)

		local expanded = false
		local function openSub()
			expanded = true; subPanel.Visible = true; subPanel.Size = UDim2.new(1,-12,0,0)
			tw(subPanel, {Size=UDim2.new(1,-12,0,subH)}, SPRING):Play()
			tw(expArrow, {Rotation=180}, MED):Play()
			shiftBelow(posY, subH+2)
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
			tw(box, {BackgroundColor3 = v and C.accentMid or C.checkOff}, FAST):Play()
			tw(bS,  {Color = v and C.accentDim or C.borderHard}, FAST):Play()
			tw(lbl, {TextColor3 = v and C.textBright or C.textMid}, FAST):Play()
			if v and not expanded then openSub()
			elseif not v and expanded then closeSub() end
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
		row.MouseEnter:Connect(function() tw(row,{BackgroundColor3=C.bgHover},SNAP):Play() end)
		row.MouseLeave:Connect(function() tw(row,{BackgroundColor3=C.rowBg},SNAP):Play() end)

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
		local div = Instance.new("Frame"); div.Size = UDim2.new(0,1,1,0); div.Position = UDim2.new(0.5,0,0,0)
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
local VeltaLib = {}

function VeltaLib.new(config)
	local win = {}
	win._tabPanels  = {}
	win._tabButtons = {}
	win._activeTab  = nil
	win.Options     = {}

	local registry = {}
	local openDD   = {fn = nil}

	local WIN_W       = config.Width  or 880
	local WIN_H       = config.Height or 530
	local BORDER      = 4
	local TITLEBAR_H  = 30
	local SIDEBAR_OW  = 148
	local SIDEBAR_CW  = 38
	local WIN_MIN_W   = 600
	local WIN_MIN_H   = 380
	local PROFILE_H   = 58   -- profile card height at bottom of sidebar
	local sidebarOpen = true
	local menuVisible = true

	local player    = Players.LocalPlayer
	local guiParent = player:WaitForChild("PlayerGui")

	local gui = Instance.new("ScreenGui")
	gui.Name = "VeltaGUI"; gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; gui.Parent = guiParent

	-- ── outer shell ─────────────────────────────────────────
	local outerFrame = Instance.new("Frame")
	outerFrame.Name = "WindowFrame"
	outerFrame.Size     = UDim2.new(0, WIN_W + BORDER*2, 0, WIN_H + BORDER*2)
	outerFrame.Position = UDim2.new(0.5, -(WIN_W+BORDER*2)/2, 0.5, -(WIN_H+BORDER*2)/2)
	outerFrame.BackgroundColor3 = C.shellOuter
	outerFrame.BorderSizePixel  = 0; outerFrame.ZIndex = 1; outerFrame.Parent = gui
	corner(outerFrame, 3)
	-- multi-stop shell gradient: very dark edges, slightly lighter center band
	gradientN(outerFrame, {
		{0,   Color3.fromRGB(4,  4,  4)},
		{0.3, Color3.fromRGB(18, 18, 18)},
		{0.7, Color3.fromRGB(18, 18, 18)},
		{1,   Color3.fromRGB(4,  4,  4)},
	}, 120)
	stroke(outerFrame, C.shellBorder, 1, 0.3)

	local main = Instance.new("Frame")
	main.Name = "Main"
	main.Size = UDim2.new(1,-BORDER*2,1,-BORDER*2)
	main.Position = UDim2.new(0,BORDER,0,BORDER)
	main.BackgroundColor3 = C.bgMain
	main.BorderSizePixel = 0; main.ZIndex = 2; main.ClipsDescendants = false
	main.Parent = outerFrame
	corner(main, 2)
	-- subtle vignette gradient
	gradientN(main, {
		{0,   C.bgSurface},
		{0.5, C.bgMain},
		{1,   C.bgDeep},
	}, 160)
	stroke(main, C.borderHard, 1, 0.2)

	-- thin top accent line (white, not colored)
	local topAccent = Instance.new("Frame")
	topAccent.Size = UDim2.new(0, 64, 0, 1)
	topAccent.BackgroundColor3 = C.accentDim
	topAccent.BorderSizePixel = 0; topAccent.ZIndex = 6; topAccent.Parent = main
	corner(topAccent, 1)
	do local g = Instance.new("UIGradient"); g.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.2),NumberSequenceKeypoint.new(1,1)}); g.Rotation=0; g.Parent=topAccent end

	-- ── titlebar ────────────────────────────────────────────
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1,0,0,TITLEBAR_H)
	titleBar.BackgroundColor3 = C.titleBg
	titleBar.BorderSizePixel = 0; titleBar.ZIndex = 4; titleBar.Parent = main
	corner(titleBar, 2)
	gradientN(titleBar, {
		{0,   Color3.fromRGB(18, 18, 18)},
		{0.6, Color3.fromRGB(10, 10, 10)},
		{1,   Color3.fromRGB(5,  5,  5)},
	}, 180)
	-- separator under titlebar
	local tSep = Instance.new("Frame")
	tSep.Size = UDim2.new(1,0,0,1); tSep.Position = UDim2.new(0,0,1,-1)
	tSep.BackgroundColor3 = C.borderSoft; tSep.BorderSizePixel = 0; tSep.ZIndex = 5; tSep.Parent = titleBar
	do local g = Instance.new("UIGradient"); g.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.6),NumberSequenceKeypoint.new(0.5,0),NumberSequenceKeypoint.new(1,0.6)}); g.Rotation=0; g.Parent=tSep end

	-- small monochrome dot
	local sDot = Instance.new("Frame")
	sDot.Size = UDim2.new(0,5,0,5); sDot.Position = UDim2.new(0,12,0.5,-2)
	sDot.BackgroundColor3 = C.accentDim; sDot.BorderSizePixel = 0; sDot.ZIndex = 6; sDot.Parent = titleBar
	corner(sDot, 3)

	local tLbl = Instance.new("TextLabel")
	tLbl.Text = config.Title or "Velta.Lua"; tLbl.Font = FONT_BOLD; tLbl.TextSize = 13
	tLbl.TextColor3 = C.textBright; tLbl.BackgroundTransparency = 1
	tLbl.Size = UDim2.new(0,120,1,0); tLbl.Position = UDim2.new(0,22,0,0)
	tLbl.TextXAlignment = Enum.TextXAlignment.Left; tLbl.ZIndex = 6; tLbl.Parent = titleBar

	local vLbl = Instance.new("TextLabel")
	vLbl.Text = config.SubTitle or "v1.0"; vLbl.Font = FONT_REG; vLbl.TextSize = 9
	vLbl.TextColor3 = C.textDim; vLbl.BackgroundTransparency = 1
	vLbl.Size = UDim2.new(0,120,0,12); vLbl.Position = UDim2.new(0,136,0.5,-6)
	vLbl.TextXAlignment = Enum.TextXAlignment.Left; vLbl.ZIndex = 6; vLbl.Parent = titleBar

	-- window buttons
	local function makeWinBtn(xOff, glyph, hBg, hTxt)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0,20,0,20); b.Position = UDim2.new(1,xOff,0.5,-10)
		b.BackgroundColor3 = Color3.fromRGB(16,16,16); b.BorderSizePixel = 0
		b.Text = glyph; b.Font = FONT_BOLD; b.TextSize = 13
		b.TextColor3 = C.textDim; b.AutoButtonColor = false; b.ZIndex = 8; b.Parent = titleBar
		corner(b, 2)
		local s = stroke(b, C.borderFaint, 1, 0.3)
		b.MouseEnter:Connect(function()
			tw(b,{BackgroundColor3=hBg,TextColor3=hTxt},SNAP):Play()
			tw(s,{Color=hTxt,Transparency=0},SNAP):Play()
		end)
		b.MouseLeave:Connect(function()
			tw(b,{BackgroundColor3=Color3.fromRGB(16,16,16),TextColor3=C.textDim},SNAP):Play()
			tw(s,{Color=C.borderFaint,Transparency=0.3},SNAP):Play()
		end)
		b.MouseButton1Down:Connect(function() tw(b,{BackgroundColor3=C.bgPress},SNAP):Play() end)
		return b
	end
	local closeBtn    = makeWinBtn(-28, "×", Color3.fromRGB(38,12,12), Color3.fromRGB(200,80,80))
	local minimizeBtn = makeWinBtn(-52, "−", Color3.fromRGB(28,28,20), Color3.fromRGB(200,200,120))

	-- ── restore pill ─────────────────────────────────────────
	local rPill = Instance.new("TextButton")
	rPill.Size = UDim2.new(0,120,0,24); rPill.Position = UDim2.new(0.5,-60,0,-40)
	rPill.BackgroundColor3 = Color3.fromRGB(12,12,12); rPill.BorderSizePixel = 0; rPill.Text = ""
	rPill.AutoButtonColor = false; rPill.ZIndex = 50; rPill.Visible = false; rPill.Parent = gui
	corner(rPill, 12); stroke(rPill, C.borderHard, 1, 0.1)
	gradient(rPill, Color3.fromRGB(20,20,20), Color3.fromRGB(8,8,8), 180)

	local pDot2 = Instance.new("Frame")
	pDot2.Size = UDim2.new(0,5,0,5); pDot2.Position = UDim2.new(0,10,0.5,-2)
	pDot2.BackgroundColor3 = C.accentDim; pDot2.BorderSizePixel = 0; pDot2.ZIndex = 52; pDot2.Parent = rPill; corner(pDot2, 3)

	local pLbl = Instance.new("TextLabel")
	pLbl.Text = string.upper(config.Title or "VELTA.LUA"); pLbl.Font = FONT_BOLD; pLbl.TextSize = 10
	pLbl.TextColor3 = C.textMid; pLbl.BackgroundTransparency = 1
	pLbl.Size = UDim2.new(1,-22,1,0); pLbl.Position = UDim2.new(0,20,0,0)
	pLbl.TextXAlignment = Enum.TextXAlignment.Left; pLbl.ZIndex = 52; pLbl.Parent = rPill

	rPill.MouseEnter:Connect(function() tw(rPill,{BackgroundColor3=Color3.fromRGB(22,22,22)},SNAP):Play() end)
	rPill.MouseLeave:Connect(function() tw(rPill,{BackgroundColor3=Color3.fromRGB(12,12,12)},SNAP):Play() end)

	local pDrag, pDS, pSP = false, nil, nil
	rPill.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then pDrag=true; pDS=inp.Position; pSP=rPill.Position end
	end)
	UIS.InputChanged:Connect(function(inp)
		if pDrag and inp.UserInputType==Enum.UserInputType.MouseMovement then
			local d=inp.Position-pDS; rPill.Position=UDim2.new(pSP.X.Scale,pSP.X.Offset+d.X,pSP.Y.Scale,pSP.Y.Offset+d.Y)
		end
	end)
	UIS.InputEnded:Connect(function(inp)
		if inp.UserInputType==Enum.UserInputType.MouseButton1 then pDrag=false end
	end)

	-- ── close dialog ─────────────────────────────────────────
	local bOver = Instance.new("Frame")
	bOver.Size = UDim2.fromScale(1,1); bOver.BackgroundColor3 = Color3.fromRGB(0,0,0)
	bOver.BackgroundTransparency = 1; bOver.BorderSizePixel = 0; bOver.ZIndex = 90; bOver.Visible = false; bOver.Parent = gui

	local cDlg = Instance.new("Frame")
	cDlg.Size = UDim2.new(0,280,0,148); cDlg.Position = UDim2.new(0.5,-140,0.5,-74)
	cDlg.BackgroundColor3 = C.dialogBg; cDlg.BorderSizePixel = 0; cDlg.ZIndex = 92; cDlg.Parent = bOver
	corner(cDlg, 3)
	gradientN(cDlg, {{0,Color3.fromRGB(20,20,20)},{1,Color3.fromRGB(6,6,6)}}, 160)
	stroke(cDlg, C.borderHard, 1, 0.1)

	local dTop = Instance.new("Frame"); dTop.Size = UDim2.new(1,0,0,1); dTop.BackgroundColor3 = C.borderSoft
	dTop.BorderSizePixel = 0; dTop.ZIndex = 93; dTop.Parent = cDlg
	do local g=Instance.new("UIGradient"); g.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.4),NumberSequenceKeypoint.new(0.5,0),NumberSequenceKeypoint.new(1,0.4)}); g.Rotation=0; g.Parent=dTop end

	local dTitle = Instance.new("TextLabel")
	dTitle.Size = UDim2.new(1,-32,0,34); dTitle.Position = UDim2.new(0,20,0,8)
	dTitle.BackgroundTransparency=1; dTitle.Font=FONT_BOLD; dTitle.TextSize=16
	dTitle.TextColor3=C.textBright; dTitle.TextTransparency=1
	dTitle.Text="CLOSE "..(string.upper(config.Title or "VELTA?"))
	dTitle.TextXAlignment=Enum.TextXAlignment.Left; dTitle.ZIndex=93; dTitle.Parent=cDlg

	local dMsg = Instance.new("TextLabel")
	dMsg.Size = UDim2.new(1,-32,0,42); dMsg.Position = UDim2.new(0,20,0,42)
	dMsg.BackgroundTransparency=1; dMsg.Font=FONT_REG; dMsg.TextSize=11
	dMsg.TextColor3=C.textSub; dMsg.TextTransparency=1; dMsg.TextWrapped=true
	dMsg.Text="Are you sure you want to close the menu?\nRe-execute the script to reopen it."
	dMsg.TextXAlignment=Enum.TextXAlignment.Left; dMsg.ZIndex=93; dMsg.Parent=cDlg

	local dDiv = Instance.new("Frame")
	dDiv.Size=UDim2.new(1,-24,0,1); dDiv.Position=UDim2.new(0,12,0,90)
	dDiv.BackgroundColor3=C.borderFaint; dDiv.BorderSizePixel=0; dDiv.ZIndex=93; dDiv.Parent=cDlg

	local function mDB(x, w, t, bg, tc, sc)
		local b = Instance.new("TextButton")
		b.Size=UDim2.new(0,w,0,30); b.Position=UDim2.new(0,x,1,-40)
		b.BackgroundColor3=bg; b.BorderSizePixel=0; b.Text=t
		b.TextColor3=tc; b.TextTransparency=1; b.TextSize=11
		b.Font=FONT_REG; b.AutoButtonColor=false; b.ZIndex=93; b.Parent=cDlg
		corner(b,2); stroke(b,sc,1,0.4); return b
	end
	local cancelBtn  = mDB(12, 110, "CANCEL", Color3.fromRGB(16,16,16), C.textMid,      C.borderHard)
	local confirmBtn = mDB(146,110, "CLOSE",  Color3.fromRGB(24,6,6),   Color3.fromRGB(190,70,70), Color3.fromRGB(100,30,30))

	cancelBtn.MouseEnter:Connect(function()  tw(cancelBtn, {BackgroundColor3=C.bgHover,TextColor3=C.textBright},SNAP):Play() end)
	cancelBtn.MouseLeave:Connect(function()  tw(cancelBtn, {BackgroundColor3=Color3.fromRGB(16,16,16),TextColor3=C.textMid},SNAP):Play() end)
	confirmBtn.MouseEnter:Connect(function() tw(confirmBtn,{BackgroundColor3=Color3.fromRGB(38,8,8)},SNAP):Play() end)
	confirmBtn.MouseLeave:Connect(function() tw(confirmBtn,{BackgroundColor3=Color3.fromRGB(24,6,6)},SNAP):Play() end)

	local function openDialog()
		if openDD.fn then openDD.fn(); openDD.fn=nil end
		bOver.Visible=true
		tw(bOver,{BackgroundTransparency=0.55},MED):Play()
		task.delay(0.05, function() tw(dTitle,{TextTransparency=0},MED):Play() end)
		task.delay(0.12, function() tw(dMsg,  {TextTransparency=0},MED):Play() end)
		task.delay(0.18, function()
			tw(cancelBtn, {TextTransparency=0},MED):Play()
			tw(confirmBtn,{TextTransparency=0},MED):Play()
		end)
	end
	local function closeDialog()
		tw(bOver,     {BackgroundTransparency=1},    MED):Play()
		tw(dTitle,    {TextTransparency=1},           FAST):Play()
		tw(dMsg,      {TextTransparency=1},           FAST):Play()
		tw(cancelBtn, {TextTransparency=1},           FAST):Play()
		tw(confirmBtn,{TextTransparency=1},           FAST):Play()
		task.delay(0.28, function() bOver.Visible=false end)
	end
	cancelBtn.MouseButton1Click:Connect(closeDialog)
	confirmBtn.MouseButton1Click:Connect(function()
		tw(bOver,{BackgroundTransparency=0},TweenInfo.new(0.18)):Play()
		task.wait(0.22); gui:Destroy()
	end)
	closeBtn.MouseButton1Click:Connect(openDialog)

	-- ── minimize / restore ────────────────────────────────────
	local function minimize()
		menuVisible=false
		tw(outerFrame,{GroupTransparency=1},MED):Play()
		task.delay(0.10, function()
			outerFrame.Visible=false
			rPill.Position=UDim2.new(0.5,-60,0,-40); rPill.Visible=true
			tw(rPill,{Position=UDim2.new(0.5,-60,0,10)},SLOW):Play()
		end)
	end
	local function restore()
		tw(rPill,{Position=UDim2.new(rPill.Position.X.Scale,rPill.Position.X.Offset,0,-40)},MED):Play()
		task.delay(0.20, function() rPill.Visible=false end)
		outerFrame.BackgroundTransparency=0; outerFrame.Visible=true; menuVisible=true
		tw(outerFrame,{BackgroundTransparency=0},FAST):Play()
	end
	minimizeBtn.MouseButton1Click:Connect(minimize)
	rPill.MouseButton1Click:Connect(function() if not pDrag then restore() end end)
	UIS.InputBegan:Connect(function(inp, gp)
		if gp then return end
		if inp.KeyCode==Enum.KeyCode.Insert then
			if menuVisible then minimize() else restore() end
		end
	end)

	-- ── drag titlebar ─────────────────────────────────────────
	local drag, dS, dSP = false, nil, nil
	titleBar.InputBegan:Connect(function(inp)
		if inp.UserInputType==Enum.UserInputType.MouseButton1 then drag=true; dS=inp.Position; dSP=outerFrame.Position end
	end)
	UIS.InputChanged:Connect(function(inp)
		if drag and inp.UserInputType==Enum.UserInputType.MouseMovement then
			local d=inp.Position-dS
			outerFrame.Position=UDim2.new(dSP.X.Scale,dSP.X.Offset+d.X,dSP.Y.Scale,dSP.Y.Offset+d.Y)
		end
	end)
	UIS.InputEnded:Connect(function(inp)
		if inp.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
	end)

	-- ── resize handle ─────────────────────────────────────────
	local rHandle = Instance.new("TextButton")
	rHandle.Size=UDim2.new(0,18,0,18); rHandle.Position=UDim2.new(1,-16,1,-16)
	rHandle.BackgroundColor3=Color3.fromRGB(30,30,30); rHandle.BackgroundTransparency=0.6
	rHandle.BorderSizePixel=0; rHandle.Text=""; rHandle.AutoButtonColor=false; rHandle.ZIndex=20; rHandle.Parent=main; corner(rHandle,2)
	local rGlyph=Instance.new("TextLabel"); rGlyph.Text="↘"; rGlyph.Font=FONT_BOLD; rGlyph.TextSize=16
	rGlyph.TextColor3=C.textDim; rGlyph.BackgroundTransparency=1; rGlyph.Size=UDim2.fromScale(1,1); rGlyph.ZIndex=21; rGlyph.Parent=rHandle
	local rz,rDS,rSS=false,nil,nil
	rHandle.InputBegan:Connect(function(inp)
		if inp.UserInputType==Enum.UserInputType.MouseButton1 then rz=true; rDS=inp.Position; rSS=outerFrame.AbsoluteSize end
	end)
	UIS.InputChanged:Connect(function(inp)
		if rz and inp.UserInputType==Enum.UserInputType.MouseMovement then
			local d=inp.Position-rDS
			outerFrame.Size=UDim2.new(0,math.max(WIN_MIN_W,rSS.X+d.X),0,math.max(WIN_MIN_H,rSS.Y+d.Y))
		end
	end)
	UIS.InputEnded:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then rz=false end end)
	rHandle.MouseEnter:Connect(function() tw(rHandle,{BackgroundTransparency=0.3},SNAP):Play(); tw(rGlyph,{TextColor3=C.textSub},SNAP):Play() end)
	rHandle.MouseLeave:Connect(function() tw(rHandle,{BackgroundTransparency=0.6},SNAP):Play(); tw(rGlyph,{TextColor3=C.textDim},SNAP):Play() end)

	-- ── sidebar ───────────────────────────────────────────────
	local sidebar = Instance.new("Frame")
	sidebar.Name="Sidebar"
	sidebar.Size=UDim2.new(0,SIDEBAR_OW,1,-TITLEBAR_H); sidebar.Position=UDim2.new(0,0,0,TITLEBAR_H)
	sidebar.BackgroundColor3=C.sidebarBg; sidebar.BorderSizePixel=0; sidebar.ZIndex=4
	sidebar.ClipsDescendants=true; sidebar.Parent=main
	corner(sidebar,2)
	gradientN(sidebar, {
		{0,   Color3.fromRGB(14, 14, 14)},
		{0.5, Color3.fromRGB(8,  8,  8)},
		{1,   Color3.fromRGB(4,  4,  4)},
	}, 180)

	-- sidebar right border
	local sB=Instance.new("Frame"); sB.Size=UDim2.new(0,1,1,0); sB.Position=UDim2.new(1,-1,0,0)
	sB.BackgroundColor3=C.borderSoft; sB.BorderSizePixel=0; sB.ZIndex=5; sB.Parent=sidebar
	do local g=Instance.new("UIGradient"); g.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.7),NumberSequenceKeypoint.new(0.5,0.1),NumberSequenceKeypoint.new(1,0.7)}); g.Rotation=90; g.Parent=sB end

	-- logo area at top of sidebar
	local sLA=Instance.new("Frame"); sLA.Size=UDim2.new(1,0,0,40); sLA.BackgroundColor3=Color3.fromRGB(10,10,10)
	sLA.BorderSizePixel=0; sLA.ZIndex=5; sLA.Parent=sidebar; corner(sLA,2)
	gradientN(sLA,{{0,Color3.fromRGB(20,20,20)},{1,Color3.fromRGB(6,6,6)}},180)
	local sLD=Instance.new("Frame"); sLD.Size=UDim2.new(0,5,0,5); sLD.Position=UDim2.new(0,10,0.5,-2)
	sLD.BackgroundColor3=C.accentDim; sLD.BorderSizePixel=0; sLD.ZIndex=6; sLD.Parent=sLA; corner(sLD,3)
	local sLT=Instance.new("TextLabel"); sLT.Text=config.Creator or "Velta.Lua"; sLT.Font=FONT_SCI; sLT.TextSize=11
	sLT.TextColor3=C.textMid; sLT.BackgroundTransparency=1; sLT.Size=UDim2.new(1,-22,1,0); sLT.Position=UDim2.new(0,20,0,0)
	sLT.TextXAlignment=Enum.TextXAlignment.Left; sLT.ZIndex=6; sLT.Parent=sLA
	local sLDiv=Instance.new("Frame"); sLDiv.Size=UDim2.new(1,0,0,1); sLDiv.Position=UDim2.new(0,0,1,-1)
	sLDiv.BackgroundColor3=C.borderFaint; sLDiv.BorderSizePixel=0; sLDiv.ZIndex=6; sLDiv.Parent=sLA

	-- collapse button at very bottom of sidebar (above profile card)
	local sTBtn=Instance.new("TextButton")
	sTBtn.Size=UDim2.new(1,0,0,24); sTBtn.Position=UDim2.new(0,0,1,-(PROFILE_H+24))
	sTBtn.BackgroundColor3=Color3.fromRGB(10,10,10); sTBtn.BorderSizePixel=0; sTBtn.Text="◀"; sTBtn.Font=FONT_BOLD
	sTBtn.TextSize=10; sTBtn.TextColor3=C.textDim; sTBtn.AutoButtonColor=false; sTBtn.ZIndex=7; sTBtn.Parent=sidebar
	local sTDiv=Instance.new("Frame"); sTDiv.Size=UDim2.new(1,0,0,1); sTDiv.BackgroundColor3=C.borderFaint; sTDiv.BorderSizePixel=0; sTDiv.ZIndex=6; sTDiv.Parent=sTBtn
	sTBtn.MouseEnter:Connect(function() tw(sTBtn,{BackgroundColor3=Color3.fromRGB(18,18,18),TextColor3=C.textSub},SNAP):Play() end)
	sTBtn.MouseLeave:Connect(function() tw(sTBtn,{BackgroundColor3=Color3.fromRGB(10,10,10),TextColor3=C.textDim},SNAP):Play() end)

	-- ── PROFILE CARD ──────────────────────────────────────────
	-- sits at the very bottom of the sidebar
	local profileCard = Instance.new("Frame")
	profileCard.Name = "ProfileCard"
	profileCard.Size = UDim2.new(1,0,0,PROFILE_H)
	profileCard.Position = UDim2.new(0,0,1,-PROFILE_H)
	profileCard.BackgroundColor3 = C.profileBg
	profileCard.BorderSizePixel = 0; profileCard.ZIndex = 6; profileCard.Parent = sidebar
	corner(profileCard, 2)
	gradientN(profileCard,{
		{0,   Color3.fromRGB(18, 18, 18)},
		{0.5, Color3.fromRGB(10, 10, 10)},
		{1,   Color3.fromRGB(5,  5,  5)},
	}, 180)
	-- top border line of card
	local profLine = Instance.new("Frame")
	profLine.Size=UDim2.new(1,0,0,1); profLine.BackgroundColor3=C.profileLine
	profLine.BorderSizePixel=0; profLine.ZIndex=7; profLine.Parent=profileCard
	do local g=Instance.new("UIGradient"); g.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.5),NumberSequenceKeypoint.new(0.5,0),NumberSequenceKeypoint.new(1,0.5)}); g.Rotation=0; g.Parent=profLine end

	-- avatar image (rounded square)
	local avatarFrame = Instance.new("Frame")
	avatarFrame.Size=UDim2.new(0,36,0,36); avatarFrame.Position=UDim2.new(0,10,0.5,-18)
	avatarFrame.BackgroundColor3=Color3.fromRGB(22,22,22); avatarFrame.BorderSizePixel=0; avatarFrame.ZIndex=8; avatarFrame.Parent=profileCard
	corner(avatarFrame, 4)
	stroke(avatarFrame, C.borderSoft, 1, 0.2)

	local avatarImg = Instance.new("ImageLabel")
	avatarImg.Size=UDim2.fromScale(1,1); avatarImg.BackgroundTransparency=1
	avatarImg.Image="rbxthumb://type=AvatarHeadShot&id="..tostring(player.UserId).."&w=150&h=150"
	avatarImg.ZIndex=9; avatarImg.Parent=avatarFrame
	corner(avatarImg, 4)

	-- display name (brighter)
	local profName = Instance.new("TextLabel")
	profName.Size=UDim2.new(1,-56,0,16); profName.Position=UDim2.new(0,52,0,10)
	profName.BackgroundTransparency=1; profName.Font=FONT_BOLD; profName.TextSize=12
	profName.TextColor3=C.textBright; profName.TextXAlignment=Enum.TextXAlignment.Left
	profName.TextTruncate=Enum.TextTruncate.AtEnd; profName.ZIndex=8; profName.Parent=profileCard
	profName.Text = player.DisplayName

	-- username (grayer)
	local profUser = Instance.new("TextLabel")
	profUser.Size=UDim2.new(1,-56,0,13); profUser.Position=UDim2.new(0,52,0,28)
	profUser.BackgroundTransparency=1; profUser.Font=FONT_REG; profUser.TextSize=10
	profUser.TextColor3=C.textSub; profUser.TextXAlignment=Enum.TextXAlignment.Left
	profUser.TextTruncate=Enum.TextTruncate.AtEnd; profUser.ZIndex=8; profUser.Parent=profileCard
	profUser.Text="@"..player.Name

	-- keep names live (display name can change mid-session)
	player:GetPropertyChangedSignal("DisplayName"):Connect(function()
		profName.Text = player.DisplayName
	end)

	-- ── content area ──────────────────────────────────────────
	local cArea=Instance.new("Frame"); cArea.Name="ContentArea"
	cArea.Size=UDim2.new(1,-(SIDEBAR_OW+1),1,-TITLEBAR_H); cArea.Position=UDim2.new(0,SIDEBAR_OW+1,0,TITLEBAR_H)
	cArea.BackgroundTransparency=1; cArea.BorderSizePixel=0; cArea.ZIndex=2; cArea.Parent=main

	-- ── tab selector bar (the sliding white indicator) ────────
	local tabSelector = Instance.new("Frame")
	tabSelector.Size = UDim2.new(0,2,0,14)
	tabSelector.BackgroundColor3 = C.accentMid
	tabSelector.BorderSizePixel = 0; tabSelector.ZIndex = 8
	tabSelector.Parent = sidebar
	corner(tabSelector, 1)

	-- ── showTab (with content fade+slide animation) ───────────
	local function showTab(name)
		if openDD.fn then openDD.fn(); openDD.fn=nil end

		-- animate out old content
		for tabName, p in pairs(win._tabPanels) do
			if p.Visible and tabName ~= name then
				tw(p, {GroupTransparency=1}, FAST):Play()
				task.delay(0.18, function() p.Visible=false; if p:IsA("CanvasGroup") then p.GroupTransparency=0 end end)
			end
		end

		-- animate in new content
		local newPanel = win._tabPanels[name]
		if newPanel then
			newPanel.Visible = true
			if newPanel:IsA("CanvasGroup") then
				newPanel.GroupTransparency = 1
				tw(newPanel, {GroupTransparency=0}, MED):Play()
			end
		end

		-- update tab button states
		for _, d in ipairs(win._tabButtons) do
			local active = d.name == name
			if active then
				tw(d.btn, {BackgroundColor3=C.tabActive},  MED):Play()
				tw(d.iL,  {TextColor3=C.textBright},        MED):Play()
				tw(d.lbl, {TextColor3=C.textBright},        MED):Play()
				-- slide the selector to this tab's position
				tw(tabSelector, {Position=UDim2.new(0,0,0,d.btn.Position.Y.Offset + (34-14)/2), Size=UDim2.new(0,2,0,14)}, SPRING):Play()
				d.ac.Visible = true
			else
				tw(d.btn, {BackgroundColor3=C.tabInact},  FAST):Play()
				tw(d.iL,  {TextColor3=C.textDim},          FAST):Play()
				tw(d.lbl, {TextColor3=C.textDim},          FAST):Play()
				d.ac.Visible = false
			end
		end
		win._activeTab = name
	end

	local function setSidebar(open)
		sidebarOpen=open; local w=open and SIDEBAR_OW or SIDEBAR_CW
		tw(sidebar, {Size=UDim2.new(0,w,1,-TITLEBAR_H)}, MED):Play()
		tw(cArea,   {Size=UDim2.new(1,-(w+1),1,-TITLEBAR_H), Position=UDim2.new(0,w+1,0,TITLEBAR_H)}, MED):Play()
		sTBtn.Text = open and "◀" or "▶"
		for _, d in ipairs(win._tabButtons) do
			tw(d.lbl, {TextTransparency = open and 0 or 1}, MED):Play()
		end
		tw(sLT,     {TextTransparency = open and 0 or 1}, MED):Play()
		tw(profName, {TextTransparency = open and 0 or 1}, MED):Play()
		tw(profUser, {TextTransparency = open and 0 or 1}, MED):Play()
		-- fade avatar out when collapsed
		tw(avatarFrame, {BackgroundTransparency = open and 0 or 1}, MED):Play()
		tw(avatarImg,   {ImageTransparency = open and 0 or 1}, MED):Play()
	end
	sTBtn.MouseButton1Click:Connect(function() setSidebar(not sidebarOpen) end)

	-- ── build tabs ────────────────────────────────────────────
	local TAB_H   = 34
	local tabDefs = config.Tabs or {}
	if #tabDefs > 0 then win._activeTab = tabDefs[1].Name end

	for i, def in ipairs(tabDefs) do
		local yPos = 40 + (i-1) * TAB_H

		-- wrap each tab's content in a CanvasGroup so we can fade it
		local panel = Instance.new("CanvasGroup")
		panel.Size = UDim2.fromScale(1,1)
		panel.BackgroundTransparency = 1; panel.Visible = false
		panel.GroupTransparency = 0; panel.ZIndex = 2; panel.Parent = cArea
		win._tabPanels[def.Name] = panel

		local btn = Instance.new("TextButton"); btn.Name=def.Name.."Tab"
		btn.Size=UDim2.new(1,0,0,TAB_H); btn.Position=UDim2.new(0,0,0,yPos)
		btn.BackgroundColor3=(def.Name==win._activeTab) and C.tabActive or C.tabInact
		btn.BorderSizePixel=0; btn.Text=""; btn.AutoButtonColor=false; btn.ZIndex=6; btn.Parent=sidebar

		-- active indicator stub (hidden; selector bar does the visual work)
		local ac=Instance.new("Frame"); ac.Size=UDim2.new(0,0,0,0)
		ac.BackgroundTransparency=1; ac.Visible=false; ac.Parent=btn

		local iL=Instance.new("TextLabel"); iL.Text=def.Icon or "·"; iL.Font=FONT_REG; iL.TextSize=14
		iL.TextColor3=(def.Name==win._activeTab) and C.textBright or C.textDim
		iL.BackgroundTransparency=1; iL.Size=UDim2.new(0,SIDEBAR_CW,1,0)
		iL.TextXAlignment=Enum.TextXAlignment.Center; iL.ZIndex=7; iL.Parent=btn

		local lbl=Instance.new("TextLabel"); lbl.Text=def.Name; lbl.Font=FONT_BOLD; lbl.TextSize=12
		lbl.TextColor3=(def.Name==win._activeTab) and C.textBright or C.textDim
		lbl.TextTransparency=sidebarOpen and 0 or 1; lbl.BackgroundTransparency=1
		lbl.Size=UDim2.new(1,-(SIDEBAR_CW+2),1,0); lbl.Position=UDim2.new(0,SIDEBAR_CW,0,0)
		lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=7; lbl.Parent=btn

		if i < #tabDefs then
			local sep=Instance.new("Frame"); sep.Size=UDim2.new(0.7,0,0,1); sep.Position=UDim2.new(0.15,0,1,-1)
			sep.BackgroundColor3=C.borderFaint; sep.BackgroundTransparency=0.2; sep.BorderSizePixel=0; sep.ZIndex=6; sep.Parent=btn
		end

		local data={name=def.Name, btn=btn, iL=iL, lbl=lbl, ac=ac}
		table.insert(win._tabButtons, data)

		local cn=def.Name
		btn.MouseButton1Click:Connect(function()
			ripple(btn)
			showTab(cn)
		end)
		btn.MouseEnter:Connect(function()
			if win._activeTab~=cn then
				tw(btn,{BackgroundColor3=C.tabHover},SNAP):Play()
				tw(iL, {TextColor3=C.textSub},        SNAP):Play()
				tw(lbl,{TextColor3=C.textSub},         SNAP):Play()
			end
		end)
		btn.MouseLeave:Connect(function()
			if win._activeTab~=cn then
				tw(btn,{BackgroundColor3=C.tabInact},SNAP):Play()
				tw(iL, {TextColor3=C.textDim},        SNAP):Play()
				tw(lbl,{TextColor3=C.textDim},         SNAP):Play()
			end
		end)
	end

	if win._activeTab then showTab(win._activeTab) end

	function win:GetTab(name)
		local panel=self._tabPanels[name]
		assert(panel,"Tab '"..tostring(name).."' not found.")
		return makeTabObj(panel, registry, openDD, self.Options)
	end

	return win
end

return VeltaLib

--[[
=======================================================================
 USAGE  (API unchanged)
=======================================================================
local VeltaLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/.../veltalibrary.lua"))()

local win = VeltaLib.new({
    Title    = "My Menu",
    SubTitle = "v2.0",
    Creator  = "You",
    Tabs     = {
        {Name="Combat",  Icon="⚔"},
        {Name="Visual",  Icon="◈"},
        {Name="Misc",    Icon="≡"},
    }
})

local tab = win:GetTab("Combat")
local col = tab:SingleColumn()

local esp, _ = col:Checkbox("espToggle", "ESP", false, function(v) print("ESP", v) end)
esp:OnChanged(function(v) print("changed", v) end)
esp:SetValue(true)

local fov, _ = col:Slider("fovSlider", "FOV", 60, 120, 90, function(v) print("FOV", v) end)

local wpn, _ = col:Dropdown("weapon", "Weapon", {"AK47","M4","AWP"}, "M4", function(t,i) print(t,i) end)
wpn:SetValue("AWP")

local bind, _ = col:Keybind("menuBind", "Menu Key", "Insert", function(k) print(k) end)

-- SaveManager compat:
-- win.Options["espToggle"]  → esp object  (.Value, :SetValue, :GetValue)
=======================================================================
]]
