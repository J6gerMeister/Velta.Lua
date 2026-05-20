-- VeltaLibrary.lua
-- Visuals / positions / animations: 100% preserved from original.
-- New: every element returns a real object with .Value, :SetValue(),
--      :GetValue(), :OnChanged(), optional .Callback.
--      win.Options[key] table for SaveManager compatibility.

local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- ============================================================
--  RGB CYCLE
-- ============================================================
local RGBCallbacks = {}
local rgbColor     = Color3.fromRGB(140, 70, 240)

task.spawn(function()
	local t = 0
	while true do
		t = t + task.wait(0.03)
		rgbColor = Color3.fromHSV((t / 4) % 1, 1, 1)
		for _, cb in ipairs(RGBCallbacks) do pcall(cb, rgbColor) end
	end
end)

local function bindRGB(inst, prop)
	local cb = function(c) inst[prop] = c end
	table.insert(RGBCallbacks, cb)
	cb(rgbColor)
	return cb
end
local function removeRGB(cb)
	if not cb then return end
	for i, v in ipairs(RGBCallbacks) do
		if v == cb then table.remove(RGBCallbacks, i); return end
	end
end

-- ============================================================
--  THEME
-- ============================================================
local C = {
	shellLight = Color3.fromRGB(120,120,120),
	shellMid   = Color3.fromRGB(72, 72, 72),
	shellDark  = Color3.fromRGB(40, 40, 40),
	bgTop      = Color3.fromRGB(50, 50, 50),
	bgBot      = Color3.fromRGB(50, 50, 50),
	panel      = Color3.fromRGB(20, 20, 20),
	panelHover = Color3.fromRGB(28, 28, 28),
	border     = Color3.fromRGB(42, 42, 42),
	borderBt   = Color3.fromRGB(62, 62, 62),
	textBright = Color3.fromRGB(245,245,245),
	text       = Color3.fromRGB(190,190,190),
	textDim    = Color3.fromRGB(95, 95, 95),
	textError  = Color3.fromRGB(220, 60, 60),
	header     = Color3.fromRGB(215,215,215),
	tabActive  = Color3.fromRGB(24, 24, 24),
	tabInact   = Color3.fromRGB(14, 14, 14),
	checkOff   = Color3.fromRGB(18, 18, 18),
	dropBg     = Color3.fromRGB(14, 14, 14),
	sliderKnob = Color3.fromRGB(230,230,230),
	yellow     = Color3.fromRGB(230,190, 50),
	sidebarBg  = Color3.fromRGB(12, 12, 12),
	rowBg      = Color3.fromRGB(20, 20, 20),
	rowBgLight = Color3.fromRGB(28, 28, 28),
}

local FONT_REG  = Enum.Font.Code
local FONT_BOLD = Enum.Font.Code
local FONT_SCI  = Enum.Font.SciFi
local FAST = TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local MED  = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SLOW = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local ITEM_H = 21

local function tw(inst, goals, info) return TweenService:Create(inst, info or FAST, goals) end
local function corner(inst, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 1); c.Parent = inst; return c end
local function stroke(inst, col, thick, trans)
	local s = Instance.new("UIStroke"); s.Color = col or C.border; s.Thickness = thick or 1
	s.Transparency = trans or 0; s.Parent = inst; return s
end
local function gradient(inst, c0, c1, rot)
	local g = Instance.new("UIGradient"); g.Color = ColorSequence.new(c0, c1); g.Rotation = rot or 90; g.Parent = inst; return g
end
local function makeRainbowSeq()
	local kps = {}
	for i = 0, 12 do kps[i+1] = ColorSequenceKeypoint.new(i/12, Color3.fromHSV(i/12, 1, 1)) end
	return ColorSequence.new(kps)
end

-- ============================================================
--  ELEMENT OBJECT CONSTRUCTOR
--  Returns a table with the consistent API every element shares.
--  Fields set here:
--    obj.Value        – current value
--    obj.Callback     – optional function set by caller
--    obj:OnChanged(fn)– register a listener (fires immediately)
--    obj:GetValue()   – returns current value
--    obj:SetValue(v)  – set value + fire listeners (subclass overrides)
--    obj:_fire(v)     – internal: update .Value, call Callback + Changed
-- ============================================================
local function newElementObj(defaultValue, callback)
	local obj = {}
	obj.Value    = defaultValue
	obj.Callback = callback  -- may be nil; always safe-called via _fire

	local _changed = nil   -- single OnChanged listener

	function obj:OnChanged(fn)
		_changed = fn
		if fn then fn(self.Value) end
	end

	function obj:GetValue()
		return self.Value
	end

	-- Internal fire: updates .Value, calls Callback then OnChanged listener.
	-- Subclasses call this instead of touching .Value directly.
	function obj:_fire(v)
		self.Value = v
		if self.Callback then pcall(self.Callback, v) end
		if _changed      then pcall(_changed,      v) end
	end

	-- Default SetValue — subclasses override to also update UI,
	-- then call obj:_fire(v) at the end.
	function obj:SetValue(v)
		self:_fire(v)
	end

	return obj
end

-- ============================================================
--  buildColorPicker  (unchanged visuals)
-- ============================================================
local PICKER_PAD  = 5
local PICKER_HUE  = 10
local PICKER_SV   = 58
local PICKER_SL   = 18
local PICKER_PREV = 0.36
local PICKER_H    = PICKER_PAD + PICKER_HUE + PICKER_PAD + PICKER_SV + PICKER_PAD + PICKER_SL + PICKER_PAD + PICKER_SL + PICKER_PAD

local function buildColorPicker(parent, defColor, defOpacity, colorCb)
	defColor   = defColor   or Color3.fromRGB(255, 0, 0)
	defOpacity = defOpacity or 1.0

	local curH, curS, curV = Color3.toHSV(defColor)
	local curOp = math.clamp(defOpacity, 0, 1)

	local PAD   = PICKER_PAD
	local HUE_H = PICKER_HUE
	local SV_H  = PICKER_SV
	local SL_H  = PICKER_SL
	local SV_WF = 1 - PICKER_PREV
	local GAP   = 4

	local panel = Instance.new("Frame")
	panel.Size             = UDim2.new(1, 0, 0, PICKER_H)
	panel.Position         = UDim2.new(0, 0, 0, 0)
	panel.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
	panel.BorderSizePixel  = 0
	panel.ZIndex           = 8
	panel.ClipsDescendants = false
	panel.Visible          = false
	panel.Parent           = parent
	corner(panel, 2)
	stroke(panel, C.borderBt, 1, 0.2)

	local hueBar = Instance.new("Frame")
	hueBar.Size             = UDim2.new(1, -PAD*2, 0, HUE_H)
	hueBar.Position         = UDim2.new(0, PAD, 0, PAD)
	hueBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	hueBar.BorderSizePixel  = 0; hueBar.ZIndex = 9; hueBar.Parent = panel
	corner(hueBar, 2)
	local hg = Instance.new("UIGradient"); hg.Color = makeRainbowSeq(); hg.Rotation = 0; hg.Parent = hueBar

	local hueCursor = Instance.new("Frame")
	hueCursor.Size             = UDim2.new(0, 2, 1, 4)
	hueCursor.Position         = UDim2.new(curH, -1, 0, -2)
	hueCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	hueCursor.BorderSizePixel  = 0; hueCursor.ZIndex = 11; hueCursor.Parent = hueBar
	corner(hueCursor, 1); stroke(hueCursor, Color3.fromRGB(0,0,0), 1, 0)

	local svY = PAD + HUE_H + PAD
	local svBox = Instance.new("Frame")
	svBox.Size             = UDim2.new(SV_WF, -PAD - GAP/2, 0, SV_H)
	svBox.Position         = UDim2.new(0, PAD, 0, svY)
	svBox.BackgroundColor3 = Color3.fromHSV(curH, 1, 1)
	svBox.BorderSizePixel  = 0; svBox.ZIndex = 9
	svBox.ClipsDescendants = true; svBox.Parent = panel
	corner(svBox, 2)

	local svWhite = Instance.new("Frame")
	svWhite.Size = UDim2.fromScale(1,1); svWhite.BackgroundColor3 = Color3.fromRGB(255,255,255)
	svWhite.BorderSizePixel = 0; svWhite.ZIndex = 10; svWhite.Parent = svBox
	do
		local g = Instance.new("UIGradient")
		g.Color = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromRGB(255,255,255))
		g.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1)})
		g.Rotation = 0; g.Parent = svWhite
	end

	local svBlack = Instance.new("Frame")
	svBlack.Size = UDim2.fromScale(1,1); svBlack.BackgroundColor3 = Color3.fromRGB(0,0,0)
	svBlack.BorderSizePixel = 0; svBlack.ZIndex = 10; svBlack.Parent = svBox
	do
		local g = Instance.new("UIGradient")
		g.Color = ColorSequence.new(Color3.fromRGB(0,0,0), Color3.fromRGB(0,0,0))
		g.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0)})
		g.Rotation = 90; g.Parent = svBlack
	end

	local svCursor = Instance.new("Frame")
	svCursor.Size = UDim2.new(0,9,0,9); svCursor.Position = UDim2.new(curS,-4,1-curV,-4)
	svCursor.BackgroundColor3 = Color3.fromRGB(255,255,255); svCursor.BorderSizePixel = 0
	svCursor.ZIndex = 12; svCursor.Parent = svBox
	corner(svCursor, 5); stroke(svCursor, Color3.fromRGB(0,0,0), 1.5, 0)

	local prevFrame = Instance.new("Frame")
	prevFrame.Size     = UDim2.new(1-SV_WF, -PAD-GAP/2, 0, SV_H)
	prevFrame.Position = UDim2.new(SV_WF, GAP/2, 0, svY)
	prevFrame.BackgroundColor3 = Color3.fromRGB(150,150,150)
	prevFrame.BorderSizePixel = 0; prevFrame.ZIndex = 9; prevFrame.Parent = panel
	corner(prevFrame, 2)
	do
		local g = Instance.new("UIGradient")
		g.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0,   Color3.fromRGB(155,155,155)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200,200,200)),
			ColorSequenceKeypoint.new(1,   Color3.fromRGB(155,155,155)),
		}); g.Rotation = 45; g.Parent = prevFrame
	end
	local prevColor = Instance.new("Frame")
	prevColor.Size = UDim2.fromScale(1,1); prevColor.BackgroundColor3 = defColor
	prevColor.BackgroundTransparency = 1-defOpacity
	prevColor.BorderSizePixel = 0; prevColor.ZIndex = 10; prevColor.Parent = prevFrame
	corner(prevColor, 2)

	local brY   = svY + SV_H + PAD
	local brMid = brY + SL_H/2

	local brLbl = Instance.new("TextLabel")
	brLbl.Text = "Brightness"; brLbl.Font = FONT_REG; brLbl.TextSize = 9; brLbl.TextColor3 = C.textDim
	brLbl.BackgroundTransparency = 1
	brLbl.Size = UDim2.new(0, 10, 0, SL_H); brLbl.Position = UDim2.new(0, PAD, 0, brY)
	brLbl.TextXAlignment = Enum.TextXAlignment.Left; brLbl.ZIndex = 9; brLbl.Parent = panel

	local brVal = Instance.new("TextLabel")
	brVal.Text = math.floor(curV*100).."%"; brVal.Font = FONT_REG; brVal.TextSize = 9; brVal.TextColor3 = C.textDim
	brVal.BackgroundTransparency = 1
	brVal.Size = UDim2.new(0, 30, 0, SL_H); brVal.Position = UDim2.new(1, -PAD-30, 0, brY)
	brVal.TextXAlignment = Enum.TextXAlignment.Right; brVal.ZIndex = 9; brVal.Parent = panel

	local brTrack = Instance.new("Frame")
	brTrack.Size     = UDim2.new(1, -(PAD+14 + PAD+32), 0, 4)
	brTrack.Position = UDim2.new(0, PAD+14, 0, brMid-2)
	brTrack.BackgroundColor3 = Color3.fromRGB(0,0,0); brTrack.BorderSizePixel = 0
	brTrack.ZIndex = 9; brTrack.Parent = panel; corner(brTrack, 2)
	do local g = Instance.new("UIGradient"); g.Color = ColorSequence.new(Color3.fromRGB(0,0,0), Color3.fromRGB(255,255,255)); g.Rotation = 0; g.Parent = brTrack end

	local brKnob = Instance.new("TextButton")
	brKnob.Size = UDim2.new(0,9,0,9); brKnob.Position = UDim2.new(curV,-4,0,brMid-4)
	brKnob.BackgroundColor3 = Color3.fromRGB(230,230,230); brKnob.BorderSizePixel = 0
	brKnob.Text = ""; brKnob.AutoButtonColor = false; brKnob.ZIndex = 11; brKnob.Parent = panel
	corner(brKnob, 5); stroke(brKnob, Color3.fromRGB(80,80,80), 1, 0)

	local opY   = brY + SL_H + PAD
	local opMid = opY + SL_H/2

	local opLbl = Instance.new("TextLabel")
	opLbl.Text = "Opacity"; opLbl.Font = FONT_REG; opLbl.TextSize = 9; opLbl.TextColor3 = C.textDim
	opLbl.BackgroundTransparency = 1
	opLbl.Size = UDim2.new(0,10,0,SL_H); opLbl.Position = UDim2.new(0,PAD,0,opY)
	opLbl.TextXAlignment = Enum.TextXAlignment.Left; opLbl.ZIndex = 9; opLbl.Parent = panel

	local opVal = Instance.new("TextLabel")
	opVal.Text = math.floor(curOp*100).."%"; opVal.Font = FONT_REG; opVal.TextSize = 9; opVal.TextColor3 = C.textDim
	opVal.BackgroundTransparency = 1
	opVal.Size = UDim2.new(0,30,0,SL_H); opVal.Position = UDim2.new(1,-PAD-30,0,opY)
	opVal.TextXAlignment = Enum.TextXAlignment.Right; opVal.ZIndex = 9; opVal.Parent = panel

	local opTrack = Instance.new("Frame")
	opTrack.Size     = UDim2.new(1, -(PAD+14 + PAD+32), 0, 4)
	opTrack.Position = UDim2.new(0, PAD+14, 0, opMid-2)
	opTrack.BackgroundColor3 = Color3.fromRGB(0,0,0); opTrack.BorderSizePixel = 0
	opTrack.ZIndex = 9; opTrack.Parent = panel; corner(opTrack, 2)
	local opGrad
	do local g = Instance.new("UIGradient"); g.Color = ColorSequence.new(Color3.fromRGB(60,60,60), defColor); g.Rotation = 0; g.Parent = opTrack; opGrad = g end

	local opKnob = Instance.new("TextButton")
	opKnob.Size = UDim2.new(0,9,0,9); opKnob.Position = UDim2.new(curOp,-4,0,opMid-4)
	opKnob.BackgroundColor3 = Color3.fromRGB(230,230,230); opKnob.BorderSizePixel = 0
	opKnob.Text = ""; opKnob.AutoButtonColor = false; opKnob.ZIndex = 11; opKnob.Parent = panel
	corner(opKnob, 5); stroke(opKnob, Color3.fromRGB(80,80,80), 1, 0)

	local function getColor()   return Color3.fromHSV(curH, curS, curV) end
	local function getOpacity() return curOp end

	local function refreshAll()
		local c = getColor()
		svBox.BackgroundColor3     = Color3.fromHSV(curH, 1, 1)
		svCursor.Position          = UDim2.new(curS, -4, 1-curV, -4)
		hueCursor.Position         = UDim2.new(curH, -1, 0, -2)
		brKnob.Position            = UDim2.new(curV, -4, 0, brMid-4)
		brVal.Text                 = math.floor(curV*100).."%"
		opGrad.Color               = ColorSequence.new(Color3.fromRGB(60,60,60), c)
		opKnob.Position            = UDim2.new(curOp, -4, 0, opMid-4)
		opVal.Text                 = math.floor(curOp*100).."%"
		prevColor.BackgroundColor3 = c
		prevColor.BackgroundTransparency = 1-curOp
		if colorCb then colorCb(c, curOp) end
	end

	local hueDrag, svDrag, brDrag, opDrag = false, false, false, false

	hueBar.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			hueDrag = true
			curH = math.clamp((inp.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
			refreshAll()
		end
	end)
	svBox.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			svDrag = true
			curS = math.clamp((inp.Position.X - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
			curV = 1 - math.clamp((inp.Position.Y - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
			refreshAll()
		end
	end)
	brKnob.MouseButton1Down:Connect(function() brDrag = true end)
	opKnob.MouseButton1Down:Connect(function() opDrag = true end)

	UIS.InputChanged:Connect(function(inp)
		if inp.UserInputType ~= Enum.UserInputType.MouseMovement then return end
		if hueDrag then
			curH = math.clamp((inp.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
			refreshAll()
		end
		if svDrag then
			curS = math.clamp((inp.Position.X - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
			curV = 1 - math.clamp((inp.Position.Y - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
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
			hueDrag = false; svDrag = false; brDrag = false; opDrag = false
		end
	end)

	-- expose setters so the element object can drive the picker
	local function setColorRaw(color, opacity)
		curH, curS, curV = Color3.toHSV(color)
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
				local targetPos = UDim2.new(
					e.frame.Position.X.Scale,
					e.frame.Position.X.Offset,
					0,
					e.baseY + e.extra
				)
				if animate and delta ~= 0 then
					tw(e.frame, {Position = targetPos}, MED):Play()
				else
					e.frame.Position = targetPos
				end
			end
		end
		local maxY = 0
		for _, e in ipairs(registry[sf]) do
			local bottom = e.baseY + e.extra + e.frame.AbsoluteSize.Y
			if bottom > maxY then maxY = bottom end
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
		corner(row, 0); stroke(row, C.border, 1, 0.4); gradient(row, C.rowBgLight, C.rowBg, 180)
		regItem(row, posY); return row
	end

	local col = {_sf = sf, _y = 8}

	function col:Finalise()
		self._sf.CanvasSize = UDim2.new(0, 0, 0, self._y + 20)
	end

	-- ── Header ─────────────────────────────────────────────
	function col:Header(text)
		local posY = self._y
		local wrap = Instance.new("Frame")
		wrap.Size = UDim2.new(1,-10,0,20); wrap.Position = UDim2.new(0,5,0,posY)
		wrap.BackgroundTransparency = 1; wrap.Parent = sf; regItem(wrap, posY)
		local lbl = Instance.new("TextLabel")
		lbl.Text = string.upper(text); lbl.Font = FONT_BOLD; lbl.TextSize = 10; lbl.TextColor3 = C.header
		lbl.BackgroundTransparency = 1; lbl.Size = UDim2.new(1,0,0,14)
		lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 3; lbl.Parent = wrap
		local bar = Instance.new("Frame")
		bar.Size = UDim2.new(1,0,0,1); bar.Position = UDim2.new(0,0,0,15)
		bar.BackgroundColor3 = C.borderBt; bar.BorderSizePixel = 0; bar.ZIndex = 3; bar.Parent = wrap
		self._y = posY + 22; return self
	end

	-- ── Separator ──────────────────────────────────────────
	function col:Separator()
		local posY = self._y
		local f = Instance.new("Frame")
		f.Size = UDim2.new(1,-12,0,1); f.Position = UDim2.new(0,6,0,posY)
		f.BackgroundColor3 = C.border; f.BorderSizePixel = 0; f.ZIndex = 3; f.Parent = sf
		regItem(f, posY); self._y = posY + 8; return self
	end

	-- ── Spacer ─────────────────────────────────────────────
	function col:Spacer(h) self._y = self._y + (h or 8); return self end

	-- ── Label ──────────────────────────────────────────────
	function col:Label(text)
		local posY = self._y
		local wrap = Instance.new("Frame")
		wrap.Size = UDim2.new(1,-12,0,22); wrap.Position = UDim2.new(0,6,0,posY)
		wrap.BackgroundTransparency = 1; wrap.ZIndex = 3; wrap.Parent = sf; regItem(wrap, posY)
		local lbl = Instance.new("TextLabel")
		lbl.Text = text; lbl.Font = FONT_REG; lbl.TextSize = 12; lbl.TextColor3 = C.text
		lbl.BackgroundTransparency = 1; lbl.Size = UDim2.fromScale(1,1)
		lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 4; lbl.Parent = wrap
		self._y = posY + 22; return self
	end

	-- ── KeyDisplay ─────────────────────────────────────────
	function col:KeyDisplay(key)
		local posY = self._y
		local kD = Instance.new("TextButton")
		kD.Size = UDim2.new(1,-12,0,22); kD.Position = UDim2.new(0,6,0,posY)
		kD.BackgroundColor3 = rgbColor; kD.BorderSizePixel = 0; kD.Text = key or "None"
		kD.Font = FONT_BOLD; kD.TextSize = 12; kD.TextColor3 = C.textBright; kD.AutoButtonColor = false
		kD.ZIndex = 3; kD.Parent = sf; corner(kD, 0)
		local kS = stroke(kD, rgbColor, 1, 0.2); bindRGB(kD, "BackgroundColor3"); bindRGB(kS, "Color")
		regItem(kD, posY); self._y = posY + 28; return self
	end

	-- ================================================================
	--  CHECKBOX
	--  Returns: element object
	--    .Value         boolean
	--    :SetValue(v)   updates UI + fires listeners
	--    :GetValue()    returns .Value
	--    :OnChanged(fn) registers listener, called immediately
	--    .Callback      optional function(bool)
	--
	--  col:Checkbox(key, labelText, default, callback)
	-- ================================================================
	function col:Checkbox(key, labelText, default, callback)
		local posY = self._y
		local row  = makeRow(posY, 22)

		local obj = newElementObj(default or false, callback)

		-- UI
		local box = Instance.new("TextButton")
		box.Size = UDim2.new(0,14,0,14); box.Position = UDim2.new(0,0,0.5,-7)
		box.BackgroundColor3 = obj.Value and rgbColor or C.checkOff; box.BorderSizePixel = 0
		box.Text = ""; box.AutoButtonColor = false; box.ZIndex = 4; box.Parent = row; corner(box, 0)
		local bStroke = stroke(box, obj.Value and rgbColor or C.border, 1)
		local bCb, sCb
		local function sRGB() if bCb then return end; bCb = bindRGB(box, "BackgroundColor3"); sCb = bindRGB(bStroke, "Color") end
		local function xRGB() removeRGB(bCb); removeRGB(sCb); bCb = nil; sCb = nil end
		if obj.Value then sRGB() end

		local tick = Instance.new("TextLabel")
		tick.Text = "✓"; tick.Font = FONT_BOLD; tick.TextSize = 9; tick.TextColor3 = C.textBright
		tick.BackgroundTransparency = 1; tick.Size = UDim2.fromScale(1,1)
		tick.TextXAlignment = Enum.TextXAlignment.Center; tick.TextYAlignment = Enum.TextYAlignment.Center
		tick.Visible = obj.Value; tick.ZIndex = 5; tick.Parent = box

		local lbl = Instance.new("TextLabel")
		lbl.Text = labelText; lbl.Font = FONT_REG; lbl.TextSize = 12
		lbl.TextColor3 = obj.Value and rgbColor or C.text; lbl.BackgroundTransparency = 1
		lbl.Size = UDim2.new(1,-20,1,0); lbl.Position = UDim2.new(0,20,0,0)
		lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 4; lbl.Parent = row
		local lCb
		local function slRGB() if lCb then return end; lCb = bindRGB(lbl, "TextColor3") end
		local function xlRGB() removeRGB(lCb); lCb = nil end
		if obj.Value then slRGB() end

		-- SetValue updates both UI and fires listeners
		function obj:SetValue(v)
			v = not not v
			if v then sRGB(); slRGB()
			else xRGB(); xlRGB(); box.BackgroundColor3 = C.checkOff; bStroke.Color = C.border; tw(lbl,{TextColor3=C.text}):Play() end
			tick.Visible = v
			self:_fire(v)
		end

		box.MouseButton1Click:Connect(function() obj:SetValue(not obj.Value) end)
		row.MouseEnter:Connect(function() if not obj.Value then tw(lbl,{TextColor3=C.textBright}):Play() end end)
		row.MouseLeave:Connect(function() if not obj.Value then tw(lbl,{TextColor3=C.text}):Play() end end)

		if key and winOptions then winOptions[key] = obj end
		self._y = posY + 26
		return obj, self
	end

	-- ================================================================
	--  DROPDOWN  (with optional inline color picker)
	--  Returns: element object
	--    .Value         string (selected option text)
	--    :SetValue(v)   selects option by text, updates UI + fires
	--    :GetValue()    returns .Value
	--    :OnChanged(fn) registers listener
	--    .Callback      optional function(text, index)
	--
	--  col:Dropdown(key, labelText, options, default, callback,
	--               doColorPicker, defColor, defOpacity, colorCb)
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

		-- element object
		local selIdx = 1
		for i, v in ipairs(options) do if v == (default or options[1]) then selIdx = i end end
		local obj = newElementObj(options[selIdx], callback)

		-- ── main container
		local container = Instance.new("Frame")
		container.Name             = "DDContainer"
		container.Size             = UDim2.new(1, -12, 0, 22)
		container.Position         = UDim2.new(0, 6, 0, posY)
		container.BackgroundColor3 = C.rowBg
		container.ClipsDescendants = false
		container.ZIndex           = 3
		container.Parent           = sf
		corner(container, 0); stroke(container, C.border, 1, 0.4)
		gradient(container, C.rowBgLight, C.rowBg, 180)
		regItem(container, posY)

		local SWATCH_W = doColorPicker and 18 or 0

		if labelText ~= "" then
			local lbl = Instance.new("TextLabel")
			lbl.Text = labelText; lbl.Font = FONT_REG; lbl.TextSize = 12; lbl.TextColor3 = C.text
			lbl.BackgroundTransparency = 1
			lbl.Size = UDim2.new(0.44, -SWATCH_W, 0, 22)
			lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 4; lbl.Parent = container
		end

		local swatchBtn, swatchStroke, swatchRgbCb

		if doColorPicker then
			defColor   = defColor   or Color3.fromRGB(255, 0, 0)
			defOpacity = defOpacity or 1.0

			swatchBtn = Instance.new("TextButton")
			swatchBtn.Size             = UDim2.new(0, 14, 0, 14)
			swatchBtn.Position         = UDim2.new(0.44, -SWATCH_W, 0, 4)
			swatchBtn.BackgroundColor3 = defColor
			swatchBtn.BorderSizePixel  = 0
			swatchBtn.Text             = ""
			swatchBtn.AutoButtonColor  = false
			swatchBtn.ZIndex           = 60
			swatchBtn.Parent           = container
			corner(swatchBtn, 2)
			swatchStroke = stroke(swatchBtn, C.borderBt, 1.5, 0)
		end

		local btnX = (labelText ~= "") and 0.45 or 0
		local btnW = (labelText ~= "") and 0.54 or 1

		local btn = Instance.new("TextButton")
		btn.Size             = UDim2.new(btnW, 0, 0, 22)
		btn.Position         = UDim2.new(btnX, 0, 0, 0)
		btn.BackgroundColor3 = C.dropBg
		btn.BorderSizePixel  = 0; btn.Text = ""; btn.AutoButtonColor = false
		btn.ZIndex           = 6; btn.Parent = container
		corner(btn, 0)
		local btnStroke = stroke(btn, C.border, 1)
		gradient(btn, Color3.fromRGB(22,22,22), Color3.fromRGB(12,12,12), 180)

		local selLbl = Instance.new("TextLabel")
		selLbl.Text = options[selIdx]; selLbl.Font = FONT_REG; selLbl.TextSize = 11; selLbl.TextColor3 = C.text
		selLbl.BackgroundTransparency = 1; selLbl.Size = UDim2.new(1,-20,1,0); selLbl.Position = UDim2.new(0,6,0,0)
		selLbl.TextXAlignment = Enum.TextXAlignment.Left; selLbl.ZIndex = 7; selLbl.Parent = btn

		local arrow = Instance.new("TextLabel")
		arrow.Text = "▾"; arrow.Font = FONT_BOLD; arrow.TextSize = 10; arrow.TextColor3 = C.textDim
		arrow.BackgroundTransparency = 1; arrow.Size = UDim2.new(0,16,1,0); arrow.Position = UDim2.new(1,-18,0,0)
		arrow.TextXAlignment = Enum.TextXAlignment.Center; arrow.ZIndex = 7; arrow.Parent = btn

		local listFrame = Instance.new("Frame")
		listFrame.Size             = UDim2.new(btnW, 0, 0, 0)
		listFrame.Position         = UDim2.new(btnX, 0, 0, 22)
		listFrame.BackgroundColor3 = Color3.fromRGB(16,16,16)
		listFrame.BorderSizePixel  = 0
		listFrame.ClipsDescendants = true
		listFrame.Visible          = false
		listFrame.ZIndex           = 20
		listFrame.Parent           = container
		corner(listFrame, 0); stroke(listFrame, C.borderBt, 1, 0.2)
		gradient(listFrame, Color3.fromRGB(22,22,22), Color3.fromRGB(12,12,12), 180)

		local pickerPanel, getPColor, getPOpacity, setPickerRaw
		local function pickerY() return 22 + (ddOpen and LIST_H or 0) end
		local function updatePickerPos()
			if pickerPanel then pickerPanel.Position = UDim2.new(0, 0, 0, pickerY()) end
		end

		-- color picker element object (only created if doColorPicker)
		local cpObj
		if doColorPicker then
			pickerPanel, getPColor, getPOpacity, setPickerRaw = buildColorPicker(
				container,
				defColor, defOpacity,
				function(c, op)
					if swatchBtn then swatchBtn.BackgroundColor3 = c end
					if cpObj then cpObj:_fire({Color = c, Opacity = op}) end
					if colorCb then colorCb(c, op) end
				end
			)
			pickerPanel.Position = UDim2.new(0, 0, 0, pickerY())

			-- colorpicker element object registered separately under key.."_Color"
			cpObj = newElementObj({Color = defColor, Opacity = defOpacity}, colorCb)
			function cpObj:SetValue(color, opacity)
				if setPickerRaw then setPickerRaw(color, opacity or 1) end
				-- _fire called by the colorCb above on next drag tick;
				-- call immediately for programmatic set:
				self:_fire({Color = color, Opacity = opacity or 1})
			end
			if key and winOptions then winOptions[key.."_Color"] = cpObj end
		end

		-- open / close helpers
		local arCb
		local function sArRGB() if arCb then return end; arCb = bindRGB(arrow, "TextColor3") end
		local function xArRGB() removeRGB(arCb); arCb = nil; arrow.TextColor3 = C.textDim end

		local function closeDD_internal()
			ddOpen = false; openDD.fn = nil; xArRGB()
			tw(arrow, {Rotation=0}):Play()
			tw(listFrame, {Size=UDim2.new(btnW,0,0,0)}, MED):Play()
			tw(btn, {BackgroundColor3=C.dropBg}):Play()
			tw(btnStroke, {Color=C.border}):Play()
			tw(container, {Size = UDim2.new(1, -12, 0, containerH())}, MED):Play()
			task.delay(0.24, function() listFrame.Visible = false end)
			shiftBelow(posY, -LIST_H, true)
			updatePickerPos()
		end

		local function openDD_internal()
			if openDD.fn then openDD.fn() end
			ddOpen = true; openDD.fn = closeDD_internal
			listFrame.Visible = true; listFrame.Size = UDim2.new(btnW,0,0,0)
			sArRGB()
			tw(arrow, {Rotation=180}):Play()
			tw(listFrame, {Size=UDim2.new(btnW,0,0,LIST_H)}, MED):Play()
			tw(btn, {BackgroundColor3=Color3.fromRGB(22,22,22)}):Play()
			tw(btnStroke, {Color=C.borderBt}):Play()
			tw(container, {Size = UDim2.new(1, -12, 0, containerH())}, MED):Play()
			shiftBelow(posY, LIST_H, true)
			updatePickerPos()
		end

		-- option rows
		local optRgbCbs = {}
		for i, optText in ipairs(options) do
			local optBtn = Instance.new("TextButton")
			optBtn.Size = UDim2.new(1,0,0,ITEM_H); optBtn.Position = UDim2.new(0,0,0,(i-1)*ITEM_H)
			optBtn.BackgroundTransparency = 1; optBtn.BorderSizePixel = 0; optBtn.Text = ""
			optBtn.AutoButtonColor = false; optBtn.ZIndex = 21; optBtn.Parent = listFrame

			local selBar = Instance.new("Frame")
			selBar.Size = UDim2.new(0,2,0.55,0); selBar.Position = UDim2.new(0,2,0.22,0)
			selBar.BackgroundColor3 = rgbColor; selBar.BorderSizePixel = 0
			selBar.Visible = (i==selIdx); selBar.ZIndex = 22; selBar.Parent = optBtn; corner(selBar, 0)
			if i == selIdx then bindRGB(selBar, "BackgroundColor3") end

			local optLbl = Instance.new("TextLabel")
			optLbl.Text = optText; optLbl.Font = FONT_REG; optLbl.TextSize = 11
			optLbl.TextColor3 = (i==selIdx) and rgbColor or C.text
			optLbl.BackgroundTransparency = 1
			optLbl.Size = UDim2.new(1,-14,1,0); optLbl.Position = UDim2.new(0,12,0,0)
			optLbl.TextXAlignment = Enum.TextXAlignment.Left; optLbl.ZIndex = 22; optLbl.Parent = optBtn
			optRgbCbs[i] = nil
			if i == selIdx then optRgbCbs[i] = bindRGB(optLbl, "TextColor3") end

			if i < COUNT then
				local sep = Instance.new("Frame"); sep.Size = UDim2.new(0.88,0,0,1); sep.Position = UDim2.new(0.06,0,1,-1)
				sep.BackgroundColor3 = C.border; sep.BackgroundTransparency = 0.5; sep.BorderSizePixel = 0; sep.ZIndex = 22; sep.Parent = optBtn
			end

			optBtn.MouseEnter:Connect(function()
				if i ~= selIdx then optBtn.BackgroundTransparency = 0; optBtn.BackgroundColor3 = Color3.fromRGB(28,24,38); tw(optLbl,{TextColor3=C.textBright}):Play() end
			end)
			optBtn.MouseLeave:Connect(function()
				if i ~= selIdx then optBtn.BackgroundTransparency = 1; tw(optLbl,{TextColor3=C.text}):Play() end
			end)
			optBtn.MouseButton1Click:Connect(function()
				removeRGB(optRgbCbs[selIdx]); optRgbCbs[selIdx] = nil
				for _, child in ipairs(listFrame:GetChildren()) do
					if child:IsA("TextButton") then
						child.BackgroundTransparency = 1
						local cl = child:FindFirstChildWhichIsA("TextLabel"); if cl then cl.TextColor3 = C.text end
						for _, cc in ipairs(child:GetChildren()) do if cc:IsA("Frame") then cc.Visible = false end end
					end
				end
				selIdx = i; selLbl.Text = optText
				optLbl.TextColor3 = rgbColor; optRgbCbs[i] = bindRGB(optLbl, "TextColor3")
				selBar.Visible = true; bindRGB(selBar, "BackgroundColor3")
				closeDD_internal()
				obj:_fire(optText)  -- fire with text value + index via callback
				if obj.Callback then pcall(obj.Callback, optText, i) end
			end)
		end

		-- SetValue: select by text string programmatically
		function obj:SetValue(v)
			for i, optText in ipairs(options) do
				if optText == v then
					selIdx = i
					selLbl.Text = v
					-- update opt row visuals (clear all, highlight selected)
					for _, child in ipairs(listFrame:GetChildren()) do
						if child:IsA("TextButton") then
							child.BackgroundTransparency = 1
							local cl = child:FindFirstChildWhichIsA("TextLabel"); if cl then cl.TextColor3 = C.text end
							for _, cc in ipairs(child:GetChildren()) do if cc:IsA("Frame") then cc.Visible = false end end
						end
					end
					self:_fire(v)
					return
				end
			end
		end

		btn.MouseButton1Click:Connect(function()
			if ddOpen then closeDD_internal() else openDD_internal() end
		end)
		btn.MouseEnter:Connect(function()
			if not ddOpen then tw(btn,{BackgroundColor3=Color3.fromRGB(22,22,22)}):Play(); tw(btnStroke,{Color=C.borderBt}):Play() end
		end)
		btn.MouseLeave:Connect(function()
			if not ddOpen then tw(btn,{BackgroundColor3=C.dropBg}):Play(); tw(btnStroke,{Color=C.border}):Play() end
		end)

		-- color picker swatch click
		if doColorPicker then
			local function closeCP()
				cpOpen = false
				removeRGB(swatchRgbCb); swatchRgbCb = nil
				tw(pickerPanel, {Size=UDim2.new(1,0,0,0)}, MED):Play()
				tw(swatchStroke, {Color=C.borderBt}):Play()
				tw(container, {Size = UDim2.new(1, -12, 0, containerH())}, MED):Play()
				task.delay(0.24, function() pickerPanel.Visible = false end)
				task.delay(0.24, function() shiftBelow(posY, -(PICKER_H + 2), true) end)
			end
			local function openCP()
				cpOpen = true
				updatePickerPos()
				pickerPanel.Size    = UDim2.new(1, 0, 0, 0)
				pickerPanel.Visible = true
				swatchRgbCb = bindRGB(swatchStroke, "Color")
				tw(pickerPanel, {Size=UDim2.new(1,0,0,PICKER_H)}, MED):Play()
				tw(swatchStroke, {Color=rgbColor}):Play()
				tw(container, {Size = UDim2.new(1, -12, 0, containerH())}, MED):Play()
				shiftBelow(posY, PICKER_H + 2, true)
			end
			swatchBtn.MouseButton1Click:Connect(function()
				if cpOpen then closeCP() else openCP() end
			end)
		end

		if key and winOptions then winOptions[key] = obj end
		self._y = posY + 26
		return obj, self
	end

	-- ================================================================
	--  SLIDER
	--  Returns: element object
	--    .Value         number
	--    :SetValue(v)   clamps, updates UI + fires
	--    :GetValue()    returns .Value
	--    :OnChanged(fn) registers listener
	--    .Callback      optional function(number)
	--
	--  col:Slider(key, labelText, minVal, maxVal, default, callback)
	-- ================================================================
	function col:Slider(key, labelText, minVal, maxVal, default, callback)
		local posY = self._y
		local row  = makeRow(posY, 22)

		local obj = newElementObj(default, callback)

		local lbl = Instance.new("TextLabel")
		lbl.Text = labelText; lbl.Font = FONT_REG; lbl.TextSize = 12; lbl.TextColor3 = C.text
		lbl.BackgroundTransparency = 1; lbl.Size = UDim2.new(0.42,0,1,0)
		lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 4; lbl.Parent = row

		local valLbl = Instance.new("TextLabel")
		valLbl.Text = tostring(default); valLbl.Font = FONT_REG; valLbl.TextSize = 10; valLbl.TextColor3 = rgbColor
		valLbl.BackgroundTransparency = 1; valLbl.Size = UDim2.new(0.13,0,1,0); valLbl.Position = UDim2.new(0.87,0,0,0)
		valLbl.TextXAlignment = Enum.TextXAlignment.Right; valLbl.ZIndex = 4; valLbl.Parent = row
		bindRGB(valLbl, "TextColor3")

		local track = Instance.new("Frame")
		track.Size = UDim2.new(0.42,0,0,4); track.Position = UDim2.new(0.43,0,0.5,-2)
		track.BackgroundColor3 = Color3.fromRGB(24,24,24); track.BorderSizePixel = 0; track.ZIndex = 4; track.Parent = row
		corner(track, 0); stroke(track, C.border, 1, 0.4)

		local pct = (default - minVal) / math.max(maxVal - minVal, 1)
		local fill = Instance.new("Frame")
		fill.Size = UDim2.new(pct,0,1,0); fill.BackgroundColor3 = rgbColor; fill.BorderSizePixel = 0
		fill.ZIndex = 5; fill.Parent = track; corner(fill, 0); bindRGB(fill, "BackgroundColor3")

		local knob = Instance.new("TextButton")
		knob.Size = UDim2.new(0,10,0,10); knob.Position = UDim2.new(pct,-5,0.5,-5)
		knob.BackgroundColor3 = C.sliderKnob; knob.BorderSizePixel = 0; knob.Text = ""
		knob.AutoButtonColor = false; knob.ZIndex = 6; knob.Parent = track; corner(knob, 5)
		local kbS = stroke(knob, rgbColor, 1); bindRGB(kbS, "Color")

		local function applyValue(v)
			v = math.clamp(v, minVal, maxVal)
			local p = (v - minVal) / math.max(maxVal - minVal, 1)
			fill.Size  = UDim2.new(p,0,1,0)
			knob.Position = UDim2.new(p,-5,0.5,-5)
			valLbl.Text = tostring(v)
			obj:_fire(v)
		end

		function obj:SetValue(v)
			v = math.floor(v + 0.5)  -- round to int like original
			applyValue(v)
		end

		local drag = false
		knob.MouseButton1Down:Connect(function() drag = true end)
		UIS.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end)
		UIS.InputChanged:Connect(function(inp)
			if drag and inp.UserInputType == Enum.UserInputType.MouseMovement then
				local p = math.clamp((inp.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
				local v = math.floor(minVal + (maxVal-minVal)*p + 0.5)
				applyValue(v)
			end
		end)

		if key and winOptions then winOptions[key] = obj end
		self._y = posY + 26
		return obj, self
	end

	-- ================================================================
	--  KEYBIND
	--  Returns: element object
	--    .Value         string (key name)
	--    :SetValue(k)   updates label + fires
	--    :GetValue()    returns .Value
	--    :OnChanged(fn) registers listener
	--    .Callback      optional function(keyName)
	--
	--  col:Keybind(key, labelText, defaultKey, callback)
	-- ================================================================
	function col:Keybind(key, labelText, defaultKey, callback)
		local posY = self._y
		local row  = makeRow(posY, 22)

		local obj = newElementObj(defaultKey or "None", callback)

		local lbl = Instance.new("TextLabel")
		lbl.Text = labelText; lbl.Font = FONT_REG; lbl.TextSize = 12; lbl.TextColor3 = C.text
		lbl.BackgroundTransparency = 1; lbl.Size = UDim2.new(0.55,0,1,0)
		lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 4; lbl.Parent = row

		local kBtn = Instance.new("TextButton")
		kBtn.Size = UDim2.new(0.4,0,0.8,0); kBtn.Position = UDim2.new(0.57,0,0.1,0)
		kBtn.BackgroundColor3 = rgbColor; kBtn.BorderSizePixel = 0; kBtn.Text = obj.Value
		kBtn.Font = FONT_BOLD; kBtn.TextSize = 10; kBtn.TextColor3 = C.textBright; kBtn.AutoButtonColor = false
		kBtn.ZIndex = 4; kBtn.Parent = row; corner(kBtn, 0)
		local kS = stroke(kBtn, rgbColor, 1, 0.2); bindRGB(kBtn, "BackgroundColor3"); bindRGB(kS, "Color")

		local picking = false

		function obj:SetValue(k)
			k = k or "None"
			kBtn.Text = k
			self:_fire(k)
		end

		kBtn.MouseButton1Click:Connect(function()
			if picking then return end
			picking = true
			kBtn.Text = "..."
			local conn
			conn = UIS.InputBegan:Connect(function(inp, gp)
				if gp then return end
				local k
				if inp.UserInputType == Enum.UserInputType.Keyboard then
					k = inp.KeyCode.Name
				elseif inp.UserInputType == Enum.UserInputType.MouseButton1 then
					k = "MouseLeft"
				elseif inp.UserInputType == Enum.UserInputType.MouseButton2 then
					k = "MouseRight"
				end
				if k then
					conn:Disconnect()
					picking = false
					obj:SetValue(k)
				end
			end)
		end)

		if key and winOptions then winOptions[key] = obj end
		self._y = posY + 26
		return obj, self
	end

	-- ================================================================
	--  PAIRED CHECKBOX
	--  Returns: two element objects (left, right)
	--
	--  col:PairedCheckbox(keyL, keyR, lL, dL, lR, dR, cbL, cbR)
	-- ================================================================
	function col:PairedCheckbox(keyL, keyR, lL, dL, lR, dR, cbL, cbR)
		local posY = self._y
		local row  = makeRow(posY, 22)

		local objL = newElementObj(dL or false, cbL)
		local objR = newElementObj(dR or false, cbR)

		local function makeMini(text, xScale, obj)
			local box = Instance.new("TextButton")
			box.Size = UDim2.new(0,13,0,13); box.Position = UDim2.new(xScale,0,0.5,-6)
			box.BackgroundColor3 = obj.Value and rgbColor or C.checkOff; box.BorderSizePixel = 0
			box.Text = ""; box.AutoButtonColor = false; box.ZIndex = 4; box.Parent = row; corner(box, 0)
			local bS = stroke(box, obj.Value and rgbColor or C.border, 1)
			local bCb, sCb
			local function sR() if bCb then return end; bCb = bindRGB(box,"BackgroundColor3"); sCb = bindRGB(bS,"Color") end
			local function xR() removeRGB(bCb); removeRGB(sCb); bCb = nil; sCb = nil end
			if obj.Value then sR() end
			local tick = Instance.new("TextLabel")
			tick.Text = "✓"; tick.Font = FONT_BOLD; tick.TextSize = 8; tick.TextColor3 = C.textBright
			tick.BackgroundTransparency = 1; tick.Size = UDim2.fromScale(1,1)
			tick.TextXAlignment = Enum.TextXAlignment.Center; tick.TextYAlignment = Enum.TextYAlignment.Center
			tick.Visible = obj.Value; tick.ZIndex = 5; tick.Parent = box
			local ml = Instance.new("TextLabel")
			ml.Text = text; ml.Font = FONT_REG; ml.TextSize = 11; ml.TextColor3 = obj.Value and rgbColor or C.text
			ml.BackgroundTransparency = 1; ml.Size = UDim2.new(0.44,0,1,0); ml.Position = UDim2.new(xScale+0.04,0,0,0)
			ml.TextXAlignment = Enum.TextXAlignment.Left; ml.ZIndex = 4; ml.Parent = row
			local lCb
			local function slR() if lCb then return end; lCb = bindRGB(ml,"TextColor3") end
			local function xlR() removeRGB(lCb); lCb = nil end
			if obj.Value then slR() end

			function obj:SetValue(v)
				v = not not v
				if v then sR(); slR()
				else xR(); xlR(); box.BackgroundColor3 = C.checkOff; bS.Color = C.border; tw(ml,{TextColor3=C.text}):Play() end
				tick.Visible = v
				self:_fire(v)
			end

			box.MouseButton1Click:Connect(function() obj:SetValue(not obj.Value) end)
		end

		makeMini(lL, 0,   objL)
		makeMini(lR, 0.5, objR)

		if keyL and winOptions then winOptions[keyL] = objL end
		if keyR and winOptions then winOptions[keyR] = objR end
		self._y = posY + 24
		return objL, objR, self
	end

	-- ================================================================
	--  EXPANDABLE CHECKBOX
	--  Returns: element object (same as Checkbox)
	--
	--  col:ExpandableCheckbox(key, labelText, default, callback, subBuilder)
	-- ================================================================
	function col:ExpandableCheckbox(key, labelText, default, callback, subBuilder)
		local posY = self._y
		local row  = makeRow(posY, 22)

		local obj = newElementObj(default or false, callback)

		local box = Instance.new("TextButton")
		box.Size = UDim2.new(0,14,0,14); box.Position = UDim2.new(0,0,0.5,-7)
		box.BackgroundColor3 = obj.Value and rgbColor or C.checkOff; box.BorderSizePixel = 0
		box.Text = ""; box.AutoButtonColor = false; box.ZIndex = 4; box.Parent = row; corner(box, 0)
		local bS = stroke(box, obj.Value and rgbColor or C.border, 1)
		local bCb, sCb
		local function sRGB() if bCb then return end; bCb = bindRGB(box,"BackgroundColor3"); sCb = bindRGB(bS,"Color") end
		local function xRGB() removeRGB(bCb); removeRGB(sCb); bCb = nil; sCb = nil end
		if obj.Value then sRGB() end

		local tick = Instance.new("TextLabel")
		tick.Text = "✓"; tick.Font = FONT_BOLD; tick.TextSize = 9; tick.TextColor3 = C.textBright
		tick.BackgroundTransparency = 1; tick.Size = UDim2.fromScale(1,1)
		tick.TextXAlignment = Enum.TextXAlignment.Center; tick.TextYAlignment = Enum.TextYAlignment.Center
		tick.Visible = obj.Value; tick.ZIndex = 5; tick.Parent = box

		local lbl = Instance.new("TextLabel")
		lbl.Text = labelText; lbl.Font = FONT_REG; lbl.TextSize = 12; lbl.TextColor3 = obj.Value and rgbColor or C.text
		lbl.BackgroundTransparency = 1; lbl.Size = UDim2.new(1,-36,1,0); lbl.Position = UDim2.new(0,20,0,0)
		lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 4; lbl.Parent = row

		local expArrow = Instance.new("TextLabel")
		expArrow.Text = "▾"; expArrow.Font = FONT_BOLD; expArrow.TextSize = 10; expArrow.TextColor3 = C.textDim
		expArrow.BackgroundTransparency = 1; expArrow.Size = UDim2.new(0,16,1,0); expArrow.Position = UDim2.new(1,-18,0,0)
		expArrow.TextXAlignment = Enum.TextXAlignment.Center; expArrow.ZIndex = 4; expArrow.Parent = row

		local lCb
		local function slRGB() if lCb then return end; lCb = bindRGB(lbl,"TextColor3") end
		local function xlRGB() removeRGB(lCb); lCb = nil end
		if obj.Value then slRGB() end

		local subPanel = Instance.new("Frame")
		subPanel.Size = UDim2.new(1,-12,0,0); subPanel.Position = UDim2.new(0,6,0,posY+26)
		subPanel.BackgroundColor3 = Color3.fromRGB(12,12,12); subPanel.BorderSizePixel = 0
		subPanel.ClipsDescendants = true; subPanel.Visible = false; subPanel.ZIndex = 3; subPanel.Parent = sf
		corner(subPanel, 0); stroke(subPanel, C.border, 1, 0.5); regItem(subPanel, posY+26)

		local subSF = Instance.new("ScrollingFrame")
		subSF.Size = UDim2.fromScale(1,1); subSF.BackgroundTransparency = 1; subSF.BorderSizePixel = 0
		subSF.ScrollBarThickness = 2; subSF.ScrollBarImageColor3 = rgbColor
		subSF.CanvasSize = UDim2.new(0,0,0,2000); subSF.ZIndex = 2; subSF.Parent = subPanel
		bindRGB(subSF, "ScrollBarImageColor3")

		local subReg = {}
		local subColObj = makeColumnObj(subSF, subReg, openDD, winOptions)
		if subBuilder then subBuilder(subColObj) end
		subColObj:Finalise()
		local subH = math.min(subColObj._y + 8, 220)
		subSF.CanvasSize = UDim2.new(0,0,0,subColObj._y+8)

		local expanded = false
		local function openSub()
			expanded = true; subPanel.Visible = true; subPanel.Size = UDim2.new(1,-12,0,0)
			tw(subPanel, {Size=UDim2.new(1,-12,0,subH)}, MED):Play()
			tw(expArrow, {Rotation=180}):Play()
			shiftBelow(posY, subH+2)
		end
		local function closeSub()
			expanded = false
			tw(subPanel, {Size=UDim2.new(1,-12,0,0)}, MED):Play()
			tw(expArrow, {Rotation=0}):Play()
			task.delay(0.24, function() subPanel.Visible = false end)
			shiftBelow(posY, -(subH+2))
		end

		function obj:SetValue(v)
			v = not not v
			if v then sRGB(); slRGB(); if not expanded then openSub() end
			else xRGB(); xlRGB(); box.BackgroundColor3 = C.checkOff; bS.Color = C.border
				tw(lbl,{TextColor3=C.text}):Play(); if expanded then closeSub() end end
			tick.Visible = v
			self:_fire(v)
		end

		box.MouseButton1Click:Connect(function() obj:SetValue(not obj.Value) end)

		local arBtn = Instance.new("TextButton")
		arBtn.Size = UDim2.new(0,24,1,0); arBtn.Position = UDim2.new(1,-26,0,0)
		arBtn.BackgroundTransparency = 1; arBtn.Text = ""; arBtn.ZIndex = 6; arBtn.Parent = row
		arBtn.MouseButton1Click:Connect(function()
			if not obj.Value then return end
			if expanded then closeSub() else openSub() end
		end)

		row.MouseEnter:Connect(function() if not obj.Value then tw(lbl,{TextColor3=C.textBright}):Play() end end)
		row.MouseLeave:Connect(function() if not obj.Value then tw(lbl,{TextColor3=C.text}):Play() end end)

		if key and winOptions then winOptions[key] = obj end
		self._y = posY + 28
		return obj, self
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
		sf.ScrollBarThickness = 2; sf.ScrollBarImageColor3 = rgbColor
		sf.CanvasSize = UDim2.new(0,0,0,2000); sf.ZIndex = 2; sf.Parent = panel
		bindRGB(sf, "ScrollBarImageColor3"); return sf
	end
	function tabObj:TwoColumn()
		local lSF = makeScrollCol(UDim2.new(0.5,-1,1,0))
		local rSF = makeScrollCol(UDim2.new(0.5,-1,1,0), UDim2.new(0.5,1,0,0))
		local div = Instance.new("Frame"); div.Size = UDim2.new(0,1,1,0); div.Position = UDim2.new(0.5,0,0,0)
		div.BackgroundColor3 = C.border; div.BorderSizePixel = 0; div.ZIndex = 2; div.Parent = panel
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
	win.Options     = {}   -- ← SaveManager indexes this

	local registry = {}
	local openDD   = {fn = nil}

	local WIN_W    = config.Width  or 880
	local WIN_H    = config.Height or 530
	local BORDER      = 5
	local TITLEBAR_H  = 32
	local SIDEBAR_OW  = 140
	local SIDEBAR_CW  = 36
	local WIN_MIN_W   = 600
	local WIN_MIN_H   = 380
	local sidebarOpen = true
	local menuVisible = true

	local player    = Players.LocalPlayer
	local guiParent = player:WaitForChild("PlayerGui")
	local gui = Instance.new("ScreenGui"); gui.Name = "VeltaGUI"; gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; gui.Parent = guiParent

	local outerFrame = Instance.new("Frame"); outerFrame.Name = "WindowFrame"
	outerFrame.Size     = UDim2.new(0, WIN_W+BORDER*2, 0, WIN_H+BORDER*2)
	outerFrame.Position = UDim2.new(0.5, -(WIN_W+BORDER*2)/2, 0.5, -(WIN_H+BORDER*2)/2)
	outerFrame.BackgroundColor3 = C.shellMid; outerFrame.BorderSizePixel = 0; outerFrame.ZIndex = 1; outerFrame.Parent = gui
	corner(outerFrame, 0)
	local sg = Instance.new("UIGradient"); sg.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0,   C.shellLight),
		ColorSequenceKeypoint.new(0.5, C.shellMid),
		ColorSequenceKeypoint.new(1,   C.shellDark),
	}); sg.Rotation = 135; sg.Parent = outerFrame
	stroke(outerFrame, Color3.fromRGB(80,80,80), 1, 0)

	local main = Instance.new("Frame"); main.Name = "Main"
	main.Size = UDim2.new(1,-BORDER*2,1,-BORDER*2); main.Position = UDim2.new(0,BORDER,0,BORDER)
	main.BackgroundColor3 = C.bgTop; main.BorderSizePixel = 0; main.ZIndex = 2; main.ClipsDescendants = false
	main.Parent = outerFrame
	corner(main, 0); gradient(main, C.bgTop, C.bgBot, 160); stroke(main, C.borderBt, 1, 0)

	local topAccent = Instance.new("Frame"); topAccent.Size = UDim2.new(0,80,0,2)
	topAccent.BackgroundColor3 = rgbColor; topAccent.BorderSizePixel = 0; topAccent.ZIndex = 6; topAccent.Parent = main
	corner(topAccent, 1); bindRGB(topAccent, "BackgroundColor3")

	local titleBar = Instance.new("Frame"); titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1,0,0,TITLEBAR_H); titleBar.BackgroundColor3 = C.panel
	titleBar.BorderSizePixel = 0; titleBar.ZIndex = 4; titleBar.Parent = main
	corner(titleBar, 0); gradient(titleBar, Color3.fromRGB(28,28,28), Color3.fromRGB(14,14,14), 180)
	local tf = Instance.new("Frame"); tf.Size = UDim2.new(1,0,0,8); tf.Position = UDim2.new(0,0,1,-8)
	tf.BackgroundColor3 = C.panel; tf.BorderSizePixel = 0; tf.ZIndex = 4; tf.Parent = titleBar
	gradient(tf, Color3.fromRGB(28,28,28), Color3.fromRGB(14,14,14), 180)
	local tSep = Instance.new("Frame"); tSep.Size = UDim2.new(1,0,0,1); tSep.Position = UDim2.new(0,0,1,-1)
	tSep.BackgroundColor3 = C.borderBt; tSep.BorderSizePixel = 0; tSep.ZIndex = 5; tSep.Parent = titleBar

	local sDot = Instance.new("Frame"); sDot.Size = UDim2.new(0,6,0,6); sDot.Position = UDim2.new(0,12,0.5,-3)
	sDot.BackgroundColor3 = rgbColor; sDot.BorderSizePixel = 0; sDot.ZIndex = 6; sDot.Parent = titleBar
	corner(sDot, 3); bindRGB(sDot, "BackgroundColor3")

	local tLbl = Instance.new("TextLabel"); tLbl.Text = config.Title or "Velta.Lua"; tLbl.Font = FONT_BOLD; tLbl.TextSize = 14
	tLbl.TextColor3 = C.textBright; tLbl.BackgroundTransparency = 1; tLbl.Size = UDim2.new(0,120,1,0); tLbl.Position = UDim2.new(0,24,0,0)
	tLbl.TextXAlignment = Enum.TextXAlignment.Left; tLbl.ZIndex = 6; tLbl.Parent = titleBar

	local vLbl = Instance.new("TextLabel"); vLbl.Text = config.SubTitle or "v1.0"; vLbl.Font = FONT_REG; vLbl.TextSize = 9
	vLbl.TextColor3 = C.textDim; vLbl.BackgroundTransparency = 1; vLbl.Size = UDim2.new(0,160,0,12); vLbl.Position = UDim2.new(0,138,0.5,-6)
	vLbl.TextXAlignment = Enum.TextXAlignment.Left; vLbl.ZIndex = 6; vLbl.Parent = titleBar

	local function makeWinBtn(xOff, glyph, hBg, hTxt)
		local b = Instance.new("TextButton"); b.Size = UDim2.new(0,20,0,20); b.Position = UDim2.new(1,xOff,0.5,-10)
		b.BackgroundColor3 = Color3.fromRGB(22,22,22); b.BorderSizePixel = 0; b.Text = glyph; b.Font = FONT_BOLD; b.TextSize = 14
		b.TextColor3 = C.textDim; b.AutoButtonColor = false; b.ZIndex = 8; b.Parent = titleBar; corner(b, 0)
		local s = stroke(b, C.border, 1, 0.4)
		b.MouseEnter:Connect(function() tw(b,{BackgroundColor3=hBg,TextColor3=hTxt}):Play(); tw(s,{Color=hTxt,Transparency=0}):Play() end)
		b.MouseLeave:Connect(function() tw(b,{BackgroundColor3=Color3.fromRGB(22,22,22),TextColor3=C.textDim}):Play(); tw(s,{Color=C.border,Transparency=0.4}):Play() end)
		return b
	end
	local closeBtn    = makeWinBtn(-28, "×", Color3.fromRGB(50,12,12), C.textError)
	local minimizeBtn = makeWinBtn(-52, "−", Color3.fromRGB(36,32,8),  C.yellow)

	-- restore pill
	local rPill = Instance.new("TextButton"); rPill.Size = UDim2.new(0,120,0,26); rPill.Position = UDim2.new(0.5,-60,0,-40)
	rPill.BackgroundColor3 = Color3.fromRGB(16,16,16); rPill.BorderSizePixel = 0; rPill.Text = ""
	rPill.AutoButtonColor = false; rPill.ZIndex = 50; rPill.Visible = false; rPill.Parent = gui
	corner(rPill, 13); stroke(rPill, C.borderBt, 1); gradient(rPill, Color3.fromRGB(26,26,26), Color3.fromRGB(10,10,10), 180)
	local pDot = Instance.new("Frame"); pDot.Size = UDim2.new(0,6,0,6); pDot.Position = UDim2.new(0,10,0.5,-3)
	pDot.BackgroundColor3 = rgbColor; pDot.BorderSizePixel = 0; pDot.ZIndex = 52; pDot.Parent = rPill; corner(pDot, 3); bindRGB(pDot, "BackgroundColor3")
	local pLbl = Instance.new("TextLabel"); pLbl.Text = string.upper(config.Title or "VELTA.LUA"); pLbl.Font = FONT_BOLD; pLbl.TextSize = 11
	pLbl.TextColor3 = C.textBright; pLbl.BackgroundTransparency = 1; pLbl.Size = UDim2.new(1,-24,1,0); pLbl.Position = UDim2.new(0,22,0,0)
	pLbl.TextXAlignment = Enum.TextXAlignment.Left; pLbl.ZIndex = 52; pLbl.Parent = rPill
	rPill.MouseEnter:Connect(function() tw(rPill,{BackgroundColor3=Color3.fromRGB(26,26,26)}):Play() end)
	rPill.MouseLeave:Connect(function() tw(rPill,{BackgroundColor3=Color3.fromRGB(16,16,16)}):Play() end)

	local pDrag, pDS, pSP = false, nil, nil
	rPill.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then pDrag = true; pDS = inp.Position; pSP = rPill.Position end end)
	UIS.InputChanged:Connect(function(inp)
		if pDrag and inp.UserInputType == Enum.UserInputType.MouseMovement then
			local d = inp.Position - pDS; rPill.Position = UDim2.new(pSP.X.Scale, pSP.X.Offset+d.X, pSP.Y.Scale, pSP.Y.Offset+d.Y)
		end
	end)
	UIS.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then pDrag = false end end)

	-- close dialog overlay
	local bOver = Instance.new("Frame"); bOver.Size = UDim2.fromScale(1,1); bOver.BackgroundColor3 = Color3.fromRGB(0,0,0)
	bOver.BackgroundTransparency = 1; bOver.BorderSizePixel = 0; bOver.ZIndex = 90; bOver.Visible = false; bOver.Parent = gui

	local cDlg = Instance.new("Frame"); cDlg.Size = UDim2.new(0,300,0,158); cDlg.Position = UDim2.new(0.5,-150,0.5,-79)
	cDlg.BackgroundColor3 = Color3.fromRGB(16,16,16); cDlg.BorderSizePixel = 0; cDlg.ZIndex = 92; cDlg.Parent = bOver
	corner(cDlg, 0); gradient(cDlg, Color3.fromRGB(24,24,24), Color3.fromRGB(8,8,8), 160); stroke(cDlg, C.borderBt, 1)
	local dTop = Instance.new("Frame"); dTop.Size = UDim2.new(1,0,0,2); dTop.BackgroundColor3 = rgbColor
	dTop.BorderSizePixel = 0; dTop.ZIndex = 93; dTop.Parent = cDlg; bindRGB(dTop, "BackgroundColor3")
	local dTitle = Instance.new("TextLabel"); dTitle.Size = UDim2.new(1,-36,0,36); dTitle.Position = UDim2.new(0,24,0,10)
	dTitle.BackgroundTransparency = 1; dTitle.Font = FONT_REG; dTitle.TextSize = 18; dTitle.TextColor3 = C.textBright
	dTitle.TextTransparency = 1; dTitle.Text = "CLOSE "..(string.upper(config.Title or "VELTA?"))
	dTitle.TextXAlignment = Enum.TextXAlignment.Left; dTitle.ZIndex = 93; dTitle.Parent = cDlg
	local dMsg = Instance.new("TextLabel"); dMsg.Size = UDim2.new(1,-36,0,46); dMsg.Position = UDim2.new(0,24,0,46)
	dMsg.BackgroundTransparency = 1; dMsg.Font = FONT_REG; dMsg.TextSize = 11; dMsg.TextColor3 = C.text
	dMsg.TextTransparency = 1; dMsg.TextWrapped = true
	dMsg.Text = "Are you sure you want to close the menu?\nRe-execute the script to reopen it."
	dMsg.TextXAlignment = Enum.TextXAlignment.Left; dMsg.ZIndex = 93; dMsg.Parent = cDlg
	local dDiv = Instance.new("Frame"); dDiv.Size = UDim2.new(1,-24,0,1); dDiv.Position = UDim2.new(0,12,0,98)
	dDiv.BackgroundColor3 = C.borderBt; dDiv.BorderSizePixel = 0; dDiv.ZIndex = 93; dDiv.Parent = cDlg

	local function mDB(x, w, t, bg, tc, sc)
		local b = Instance.new("TextButton"); b.Size = UDim2.new(0,w,0,32); b.Position = UDim2.new(0,x,1,-44)
		b.BackgroundColor3 = bg; b.BorderSizePixel = 0; b.Text = t; b.TextColor3 = tc; b.TextTransparency = 1; b.TextSize = 12
		b.Font = FONT_REG; b.AutoButtonColor = false; b.ZIndex = 93; b.Parent = cDlg; corner(b, 0); stroke(b, sc, 1, 0.4); return b
	end
	local cancelBtn  = mDB(14,  120, "CANCEL", Color3.fromRGB(18,18,18), C.text,      C.borderBt)
	local confirmBtn = mDB(166, 120, "CLOSE",  Color3.fromRGB(28,8,8),   C.textError, C.textError)
	cancelBtn.MouseEnter:Connect(function()  tw(cancelBtn, {BackgroundColor3=Color3.fromRGB(30,30,30),TextColor3=C.textBright}):Play() end)
	cancelBtn.MouseLeave:Connect(function()  tw(cancelBtn, {BackgroundColor3=Color3.fromRGB(18,18,18),TextColor3=C.text}):Play() end)
	confirmBtn.MouseEnter:Connect(function() tw(confirmBtn,{BackgroundColor3=Color3.fromRGB(50,10,10)}):Play() end)
	confirmBtn.MouseLeave:Connect(function() tw(confirmBtn,{BackgroundColor3=Color3.fromRGB(28,8,8)}):Play() end)

	local function openDialog()
		if openDD.fn then openDD.fn(); openDD.fn = nil end
		bOver.Visible = true; tw(bOver,{BackgroundTransparency=0.5},MED):Play()
		task.delay(0.04,  function() tw(dTitle, {TextTransparency=0},MED):Play() end)
		task.delay(0.10,  function() tw(dMsg,   {TextTransparency=0},MED):Play() end)
		task.delay(0.16,  function() tw(cancelBtn,{TextTransparency=0},MED):Play(); tw(confirmBtn,{TextTransparency=0},MED):Play() end)
	end
	local function closeDialog()
		tw(bOver,{BackgroundTransparency=1},MED):Play()
		tw(dTitle,{TextTransparency=1},FAST):Play(); tw(dMsg,{TextTransparency=1},FAST):Play()
		tw(cancelBtn,{TextTransparency=1},FAST):Play(); tw(confirmBtn,{TextTransparency=1},FAST):Play()
		task.delay(0.28, function() bOver.Visible = false end)
	end
	cancelBtn.MouseButton1Click:Connect(closeDialog)
	confirmBtn.MouseButton1Click:Connect(function()
		tw(bOver,{BackgroundTransparency=0},TweenInfo.new(0.18)):Play(); task.wait(0.22); gui:Destroy()
	end)
	closeBtn.MouseButton1Click:Connect(openDialog)

	-- minimize / restore
	local function minimize()
		menuVisible = false; tw(outerFrame,{BackgroundTransparency=1},MED):Play()
		task.delay(0.08, function()
			outerFrame.Visible = false
			rPill.Position = UDim2.new(0.5,-60,0,-40); rPill.Visible = true
			tw(rPill,{Position=UDim2.new(0.5,-60,0,10)},SLOW):Play()
		end)
	end
	local function restore()
		tw(rPill,{Position=UDim2.new(rPill.Position.X.Scale,rPill.Position.X.Offset,0,-40)},MED):Play()
		task.delay(0.18, function() rPill.Visible = false end)
		outerFrame.BackgroundTransparency = 0; outerFrame.Visible = true; menuVisible = true
	end
	minimizeBtn.MouseButton1Click:Connect(minimize)
	rPill.MouseButton1Click:Connect(function() if not pDrag then restore() end end)
	UIS.InputBegan:Connect(function(inp, gp)
		if gp then return end
		if inp.KeyCode == Enum.KeyCode.Insert then
			if menuVisible then minimize() else restore() end
		end
	end)

	-- drag titleBar
	local drag, dS, dSP = false, nil, nil
	titleBar.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then drag = true; dS = inp.Position; dSP = outerFrame.Position end end)
	UIS.InputChanged:Connect(function(inp)
		if drag and inp.UserInputType == Enum.UserInputType.MouseMovement then
			local d = inp.Position - dS; outerFrame.Position = UDim2.new(dSP.X.Scale, dSP.X.Offset+d.X, dSP.Y.Scale, dSP.Y.Offset+d.Y)
		end
	end)
	UIS.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end)

	-- resize handle
	local rHandle = Instance.new("TextButton"); rHandle.Size = UDim2.new(0,20,0,20); rHandle.Position = UDim2.new(1,-18,1,-18)
	rHandle.BackgroundColor3 = Color3.fromRGB(40,40,40); rHandle.BackgroundTransparency = 0.5; rHandle.BorderSizePixel = 0
	rHandle.Text = ""; rHandle.AutoButtonColor = false; rHandle.ZIndex = 20; rHandle.Parent = main; corner(rHandle, 0)
	local rGlyph = Instance.new("TextLabel"); rGlyph.Text = "↘"; rGlyph.Font = FONT_BOLD; rGlyph.TextSize = 20
	rGlyph.TextColor3 = C.textDim; rGlyph.BackgroundTransparency = 1; rGlyph.Size = UDim2.fromScale(1,1); rGlyph.ZIndex = 21; rGlyph.Parent = rHandle
	local rz, rDS, rSS = false, nil, nil
	rHandle.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then rz = true; rDS = inp.Position; rSS = outerFrame.AbsoluteSize end end)
	UIS.InputChanged:Connect(function(inp)
		if rz and inp.UserInputType == Enum.UserInputType.MouseMovement then
			local d = inp.Position - rDS
			outerFrame.Size = UDim2.new(0, math.max(WIN_MIN_W,rSS.X+d.X), 0, math.max(WIN_MIN_H,rSS.Y+d.Y))
		end
	end)
	UIS.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then rz = false end end)
	rHandle.MouseEnter:Connect(function() tw(rHandle,{BackgroundTransparency=0.2}):Play(); tw(rGlyph,{TextColor3=C.text}):Play() end)
	rHandle.MouseLeave:Connect(function() tw(rHandle,{BackgroundTransparency=0.5}):Play(); tw(rGlyph,{TextColor3=C.textDim}):Play() end)

	-- sidebar
	local sidebar = Instance.new("Frame"); sidebar.Name = "Sidebar"
	sidebar.Size = UDim2.new(0,SIDEBAR_OW,1,-TITLEBAR_H); sidebar.Position = UDim2.new(0,0,0,TITLEBAR_H)
	sidebar.BackgroundColor3 = C.sidebarBg; sidebar.BorderSizePixel = 0; sidebar.ZIndex = 4; sidebar.ClipsDescendants = true; sidebar.Parent = main
	corner(sidebar, 0); gradient(sidebar, Color3.fromRGB(22,22,22), Color3.fromRGB(10,10,10), 180)
	local sF = Instance.new("Frame"); sF.Size = UDim2.new(0,8,1,0); sF.Position = UDim2.new(1,-8,0,0)
	sF.BackgroundColor3 = C.sidebarBg; sF.BorderSizePixel = 0; sF.ZIndex = 4; sF.Parent = sidebar
	local sB = Instance.new("Frame"); sB.Size = UDim2.new(0,1,1,0); sB.Position = UDim2.new(1,0,0,0)
	sB.BackgroundColor3 = C.borderBt; sB.BorderSizePixel = 0; sB.ZIndex = 5; sB.Parent = sidebar
	local sLA = Instance.new("Frame"); sLA.Size = UDim2.new(1,0,0,40); sLA.BackgroundColor3 = Color3.fromRGB(18,18,18)
	sLA.BorderSizePixel = 0; sLA.ZIndex = 5; sLA.Parent = sidebar; corner(sLA, 0)
	gradient(sLA, Color3.fromRGB(30,30,30), Color3.fromRGB(12,12,12), 170)
	local sLD = Instance.new("Frame"); sLD.Size = UDim2.new(0,7,0,7); sLD.Position = UDim2.new(0,10,0.5,-3)
	sLD.BackgroundColor3 = rgbColor; sLD.BorderSizePixel = 0; sLD.ZIndex = 6; sLD.Parent = sLA; corner(sLD, 3); bindRGB(sLD, "BackgroundColor3")
	local sLT = Instance.new("TextLabel"); sLT.Text = config.Creator or "Velta.Lua"; sLT.Font = FONT_SCI; sLT.TextSize = 11
	sLT.TextColor3 = C.textBright; sLT.BackgroundTransparency = 1; sLT.Size = UDim2.new(1,-28,1,0); sLT.Position = UDim2.new(0,22,0,0)
	sLT.TextXAlignment = Enum.TextXAlignment.Left; sLT.ZIndex = 6; sLT.Parent = sLA
	local sLDiv = Instance.new("Frame"); sLDiv.Size = UDim2.new(1,0,0,1); sLDiv.Position = UDim2.new(0,0,1,-1)
	sLDiv.BackgroundColor3 = C.borderBt; sLDiv.BorderSizePixel = 0; sLDiv.ZIndex = 6; sLDiv.Parent = sLA
	local sTBtn = Instance.new("TextButton"); sTBtn.Size = UDim2.new(1,0,0,28); sTBtn.Position = UDim2.new(0,0,1,-28)
	sTBtn.BackgroundColor3 = Color3.fromRGB(14,14,14); sTBtn.BorderSizePixel = 0; sTBtn.Text = "◀"; sTBtn.Font = FONT_BOLD
	sTBtn.TextSize = 11; sTBtn.TextColor3 = C.textDim; sTBtn.AutoButtonColor = false; sTBtn.ZIndex = 7; sTBtn.Parent = sidebar
	local sTD = Instance.new("Frame"); sTD.Size = UDim2.new(1,0,0,1); sTD.BackgroundColor3 = C.borderBt; sTD.BorderSizePixel = 0; sTD.ZIndex = 6; sTD.Parent = sTBtn
	sTBtn.MouseEnter:Connect(function() tw(sTBtn,{BackgroundColor3=Color3.fromRGB(24,24,24),TextColor3=C.text}):Play() end)
	sTBtn.MouseLeave:Connect(function() tw(sTBtn,{BackgroundColor3=Color3.fromRGB(14,14,14),TextColor3=C.textDim}):Play() end)

	local cArea = Instance.new("Frame"); cArea.Name = "ContentArea"
	cArea.Size = UDim2.new(1,-(SIDEBAR_OW+1),1,-TITLEBAR_H); cArea.Position = UDim2.new(0,SIDEBAR_OW+1,0,TITLEBAR_H)
	cArea.BackgroundTransparency = 1; cArea.BorderSizePixel = 0; cArea.ZIndex = 2; cArea.Parent = main

	local function showTab(name)
		if openDD.fn then openDD.fn(); openDD.fn = nil end
		for _, p in pairs(win._tabPanels) do p.Visible = false end
		if win._tabPanels[name] then win._tabPanels[name].Visible = true end
		for _, d in ipairs(win._tabButtons) do
			local active = d.name == name
			tw(d.btn, {BackgroundColor3 = active and C.tabActive or C.tabInact}):Play()
			if active then
				if not d._iR then d._iR = bindRGB(d.iL, "TextColor3") end
			else
				removeRGB(d._iR); d._iR = nil; d.iL.TextColor3 = C.textDim
			end
			if active then
				if not d._aR then d._aR = bindRGB(d.ac, "BackgroundColor3") end
			else
				removeRGB(d._aR); d._aR = nil; d.ac.BackgroundColor3 = C.border
			end
			d.ac.Visible = active
			tw(d.lbl, {TextColor3 = active and C.textBright or C.textDim}):Play()
		end
		win._activeTab = name
	end

	local function setSidebar(open)
		sidebarOpen = open; local w = open and SIDEBAR_OW or SIDEBAR_CW
		tw(sidebar, {Size=UDim2.new(0,w,1,-TITLEBAR_H)}, MED):Play()
		tw(cArea,   {Size=UDim2.new(1,-(w+1),1,-TITLEBAR_H), Position=UDim2.new(0,w+1,0,TITLEBAR_H)}, MED):Play()
		sTBtn.Text = open and "◀" or "▶"
		for _, d in ipairs(win._tabButtons) do tw(d.lbl, {TextTransparency = open and 0 or 1}, MED):Play() end
		tw(sLT, {TextTransparency = open and 0 or 1}, MED):Play()
	end
	sTBtn.MouseButton1Click:Connect(function() setSidebar(not sidebarOpen) end)

	local TAB_H   = 34
	local tabDefs = config.Tabs or {}
	if #tabDefs > 0 then win._activeTab = tabDefs[1].Name end

	for i, def in ipairs(tabDefs) do
		local yPos = 40 + (i-1) * TAB_H
		local panel = Instance.new("Frame"); panel.Size = UDim2.fromScale(1,1)
		panel.BackgroundTransparency = 1; panel.Visible = false; panel.ZIndex = 2; panel.Parent = cArea
		win._tabPanels[def.Name] = panel

		local btn = Instance.new("TextButton"); btn.Name = def.Name.."Tab"
		btn.Size = UDim2.new(1,0,0,TAB_H); btn.Position = UDim2.new(0,0,0,yPos)
		btn.BackgroundColor3 = (def.Name == win._activeTab) and C.tabActive or C.tabInact
		btn.BorderSizePixel = 0; btn.Text = ""; btn.AutoButtonColor = false; btn.ZIndex = 6; btn.Parent = sidebar

		local ac = Instance.new("Frame"); ac.Size = UDim2.new(0,2,0.55,0); ac.Position = UDim2.new(0,0,0.22,0)
		ac.BackgroundColor3 = rgbColor; ac.BorderSizePixel = 0; ac.Visible = (def.Name == win._activeTab); ac.ZIndex = 7; ac.Parent = btn; corner(ac, 0)
		if def.Name == win._activeTab then bindRGB(ac, "BackgroundColor3") end

		local iL = Instance.new("TextLabel"); iL.Text = def.Icon or "·"; iL.Font = FONT_REG; iL.TextSize = 14
		iL.TextColor3 = (def.Name == win._activeTab) and rgbColor or C.textDim
		iL.BackgroundTransparency = 1; iL.Size = UDim2.new(0,SIDEBAR_CW,1,0)
		iL.TextXAlignment = Enum.TextXAlignment.Center; iL.ZIndex = 7; iL.Parent = btn

		local lbl = Instance.new("TextLabel"); lbl.Text = def.Name; lbl.Font = FONT_BOLD; lbl.TextSize = 12
		lbl.TextColor3 = (def.Name == win._activeTab) and C.textBright or C.textDim
		lbl.TextTransparency = sidebarOpen and 0 or 1; lbl.BackgroundTransparency = 1
		lbl.Size = UDim2.new(1,-(SIDEBAR_CW+2),1,0); lbl.Position = UDim2.new(0,SIDEBAR_CW,0,0)
		lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 7; lbl.Parent = btn

		if i < #tabDefs then
			local sep = Instance.new("Frame"); sep.Size = UDim2.new(0.8,0,0,1); sep.Position = UDim2.new(0.1,0,1,-1)
			sep.BackgroundColor3 = C.border; sep.BackgroundTransparency = 0.3; sep.BorderSizePixel = 0; sep.ZIndex = 6; sep.Parent = btn
		end

		local data = {name=def.Name, btn=btn, iL=iL, lbl=lbl, ac=ac, _iR=nil, _aR=nil}
		if def.Name == win._activeTab then data._iR = bindRGB(iL,"TextColor3"); data._aR = bindRGB(ac,"BackgroundColor3") end
		table.insert(win._tabButtons, data)

		local cn = def.Name
		btn.MouseButton1Click:Connect(function() showTab(cn) end)
		btn.MouseEnter:Connect(function()
			if win._activeTab ~= cn then
				tw(btn,{BackgroundColor3=C.panelHover}):Play(); tw(iL,{TextColor3=C.text}):Play(); tw(lbl,{TextColor3=C.text}):Play()
			end
		end)
		btn.MouseLeave:Connect(function()
			if win._activeTab ~= cn then
				tw(btn,{BackgroundColor3=C.tabInact}):Play(); tw(iL,{TextColor3=C.textDim}):Play(); tw(lbl,{TextColor3=C.textDim}):Play()
			end
		end)
	end

	if win._activeTab then showTab(win._activeTab) end

	function win:GetTab(name)
		local panel = self._tabPanels[name]
		assert(panel, "Tab '"..tostring(name).."' not found.")
		return makeTabObj(panel, registry, openDD, self.Options)
	end

	return win
end

return VeltaLib

--[[
=======================================================================
 USAGE EXAMPLES — consistent API across all elements
=======================================================================

local win = VeltaLib.new({ Title = "My Menu", Tabs = {{Name="Main",Icon="⚡"}} })
local tab = win:GetTab("Main")
local col = tab:SingleColumn()

-- Checkbox
local myToggle, _ = col:Checkbox("espToggle", "ESP", false, function(v)
    print("ESP is now", v)
end)
myToggle:OnChanged(function(v) print("changed:", v) end)
myToggle:SetValue(true)    -- updates UI + fires callback + OnChanged
print(myToggle:GetValue()) -- true

-- Slider
local mySlider, _ = col:Slider("fovSlider", "FOV", 60, 120, 90, function(v)
    Camera.FieldOfView = v
end)
mySlider:SetValue(110)

-- Dropdown
local myDrop, _ = col:Dropdown("weaponDrop", "Weapon", {"AK47","M4","AWP"}, "M4", function(text, idx)
    print("Selected:", text, idx)
end)
myDrop:SetValue("AWP")

-- Keybind
local myKey, _ = col:Keybind("menuKey", "Menu Key", "RightShift", function(k)
    print("New key:", k)
end)

-- ExpandableCheckbox with sub-elements
local myExp, _ = col:ExpandableCheckbox("aimbot", "Aimbot", false, function(v)
    print("Aimbot:", v)
end, function(sub)
    sub:Slider("aimFOV", "FOV", 1, 30, 10)
    sub:Slider("aimSmooth", "Smooth", 1, 10, 5)
end)

-- Dropdown with color picker
col:Dropdown("chams", "Chams", {"Flat","Metallic"}, "Flat", function(text)
    print("Chams style:", text)
end, true, Color3.fromRGB(255,0,0), 1.0, function(color, opacity)
    print("Color:", color, "Opacity:", opacity)
end)

-- SaveManager compat:  win.Options["espToggle"] → myToggle
--                       myToggle.Value  → current bool
--                       myToggle.Type   → "Checkbox" (add if needed for SaveManager)
=======================================================================
]]
