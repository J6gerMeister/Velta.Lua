-- VeltaLibrary.lua
-- Reusable GUI library for Velta-style mod menu UIs.
-- Educational / cosmetic demonstration only — no functional game hooks.
--
-- NEW in this version:
--   col:ColorPicker(labelText, defaultColor, defaultOpacity, callback)
--       Shows a hue wheel, brightness slider, opacity slider, and live preview.
--       callback(color3, opacity)  where opacity is 0-1
--
--   col:ExpandableCheckbox(labelText, default, callback, subBuilder)
--       A normal checkbox that, when checked, expands a sub-section below it.
--       subBuilder is a function(subCol) where subCol is a column object you
--       can call :ColorPicker() / :Slider() / :Dropdown() etc. on.
--       Example:
--           vL:ExpandableCheckbox("Enemies", false, nil, function(s)
--               s:ColorPicker("Color", Color3.fromRGB(255,60,60), 1)
--           end)

local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local RGBCallbacks = {}
local rgbColor     = Color3.fromRGB(140, 70, 240)

task.spawn(function()
	local t = 0
	while true do
		t = t + task.wait(0.03)
		local hue = (t / 4) % 1
		rgbColor = Color3.fromHSV(hue, 1, 1)
		for _, cb in ipairs(RGBCallbacks) do pcall(cb, rgbColor) end
	end
end)

local function bindRGB(instance, prop)
	local cb = function(c) instance[prop] = c end
	table.insert(RGBCallbacks, cb)
	return cb
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
	violet     = Color3.fromRGB(140, 70, 240),
	violetDim  = Color3.fromRGB(90,  45, 160),
	violetGlow = Color3.fromRGB(175,110, 255),
	border     = Color3.fromRGB(42, 42, 42),
	borderBt   = Color3.fromRGB(62, 62, 62),
	textBright = Color3.fromRGB(245,245,245),
	text       = Color3.fromRGB(190,190,190),
	textDim    = Color3.fromRGB(95, 95, 95),
	textError  = Color3.fromRGB(220, 60, 60),
	header     = Color3.fromRGB(215,215,215),
	tabActive  = Color3.fromRGB(24, 24, 24),
	tabInact   = Color3.fromRGB(14, 14, 14),
	checkOn    = Color3.fromRGB(130, 60, 230),
	checkOff   = Color3.fromRGB(18, 18, 18),
	dropBg     = Color3.fromRGB(14, 14, 14),
	sliderFill = Color3.fromRGB(130, 60, 230),
	sliderKnob = Color3.fromRGB(230,230,230),
	keyBg      = Color3.fromRGB(100, 40, 200),
	yellow     = Color3.fromRGB(230,190, 50),
	sidebarBg  = Color3.fromRGB(12, 12, 12),
	rowBg      = Color3.fromRGB(20, 20, 20),
	rowBgLight = Color3.fromRGB(28, 28, 28),
}

local FONT_REG  = Enum.Font.Code
local FONT_BOLD = Enum.Font.Code
local FONT_SCI  = Enum.Font.SciFi
local FAST  = TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local MED   = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SLOW  = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local ITEM_H = 21

-- ============================================================
--  PURE HELPERS
-- ============================================================
local function tw(inst, goals, info)
	return TweenService:Create(inst, info or FAST, goals)
end
local function corner(inst, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 1)
	c.Parent = inst
	return c
end
local function stroke(inst, col, thick, trans)
	local s = Instance.new("UIStroke")
	s.Color        = col   or C.border
	s.Thickness    = thick or 1
	s.Transparency = trans or 0
	s.Parent       = inst
	return s
end
local function gradient(inst, c0, c1, rot)
	local g = Instance.new("UIGradient")
	g.Color    = ColorSequence.new(c0, c1)
	g.Rotation = rot or 90
	g.Parent   = inst
	return g
end

-- ============================================================
--  COLOR MATH HELPERS
-- ============================================================
-- Draw a hue ring on an ImageLabel using a UIGradient trick
-- (full rainbow ColorSequence)
local function makeRainbowSequence()
	local keys = {}
	local steps = 12
	for i = 0, steps do
		local t = i / steps
		keys[i+1] = ColorSequenceKeypoint.new(t, Color3.fromHSV(t, 1, 1))
	end
	return ColorSequence.new(keys)
end

-- Returns H,S,V from Color3
local function colorToHSV(c)
	return Color3.toHSV(c)
end

-- ============================================================
--  COLUMN OBJECT
-- ============================================================
local function makeColumnObj(sf, registry, openDD)
	if not registry[sf] then registry[sf] = {} end

	local function regItem(frame, baseY)
		table.insert(registry[sf], {frame=frame, baseY=baseY, extra=0})
	end

	local function shiftBelow(afterY, delta)
		for _, e in ipairs(registry[sf]) do
			if e.baseY > afterY then
				e.extra = e.extra + delta
				e.frame.Position = UDim2.new(
					e.frame.Position.X.Scale, e.frame.Position.X.Offset,
					0, e.baseY + e.extra)
			end
		end
	end

	local function makeRow(posY, h)
		h = h or 22
		local row = Instance.new("Frame")
		row.Size             = UDim2.new(1,-12,0,h)
		row.Position         = UDim2.new(0,6,0,posY)
		row.BackgroundColor3 = C.rowBg
		row.BorderSizePixel  = 0
		row.ZIndex           = 3
		row.Parent           = sf
		corner(row, 0)
		stroke(row, C.border, 1, 0.4)
		gradient(row, C.rowBgLight, C.rowBg, 180)
		regItem(row, posY)
		return row
	end

	local col = { _sf = sf, _y = 8 }

	function col:Finalise()
		self._sf.CanvasSize = UDim2.new(0, 0, 0, self._y + 20)
	end

	-- ── Header ─────────────────────────────────────────────
	function col:Header(text)
		local posY = self._y
		local wrap = Instance.new("Frame")
		wrap.Size                   = UDim2.new(1,-10,0,20)
		wrap.Position               = UDim2.new(0,5,0,posY)
		wrap.BackgroundTransparency = 1
		wrap.Parent                 = sf
		regItem(wrap, posY)

		local lbl = Instance.new("TextLabel")
		lbl.Text                   = string.upper(text)
		lbl.Font                   = FONT_BOLD
		lbl.TextSize               = 10
		lbl.TextColor3             = C.header
		lbl.BackgroundTransparency = 1
		lbl.Size                   = UDim2.new(1,0,0,14)
		lbl.TextXAlignment         = Enum.TextXAlignment.Left
		lbl.ZIndex                 = 3
		lbl.Parent                 = wrap

		local bar = Instance.new("Frame")
		bar.Size             = UDim2.new(1,0,0,1)
		bar.Position         = UDim2.new(0,0,0,15)
		bar.BackgroundColor3 = C.borderBt
		bar.BorderSizePixel  = 0
		bar.ZIndex           = 3
		bar.Parent           = wrap

		self._y = posY + 22
		return self
	end

	-- ── Separator ──────────────────────────────────────────
	function col:Separator()
		local posY = self._y
		local f = Instance.new("Frame")
		f.Size             = UDim2.new(1,-12,0,1)
		f.Position         = UDim2.new(0,6,0,posY)
		f.BackgroundColor3 = C.border
		f.BorderSizePixel  = 0
		f.ZIndex           = 3
		f.Parent           = sf
		regItem(f, posY)
		self._y = posY + 8
		return self
	end

	-- ── Checkbox ───────────────────────────────────────────
	function col:Checkbox(labelText, default, callback)
		local posY = self._y
		local row  = makeRow(posY, 22)

		local box = Instance.new("TextButton")
		box.Size             = UDim2.new(0,14,0,14)
		box.Position         = UDim2.new(0,0,0.5,-7)
		box.BackgroundColor3 = default and rgbColor or C.checkOff
		box.BorderSizePixel  = 0
		box.Text             = ""
		box.AutoButtonColor  = false
		box.ZIndex           = 4
		box.Parent           = row
		corner(box, 0)
		local boxStroke = stroke(box, default and rgbColor or C.border, 1)

		local boxRgbCb, strokeRgbCb
		local function startRGB()
			if boxRgbCb then return end
			boxRgbCb   = bindRGB(box,       "BackgroundColor3")
			strokeRgbCb = bindRGB(boxStroke, "Color")
		end
		local function stopRGB()
			if boxRgbCb then
				for i, cb in ipairs(RGBCallbacks) do
					if cb == boxRgbCb or cb == strokeRgbCb then
						table.remove(RGBCallbacks, i)
					end
				end
				boxRgbCb    = nil
				strokeRgbCb = nil
			end
		end
		if default then startRGB() end

		local tick = Instance.new("TextLabel")
		tick.Text                   = "✓"
		tick.Font                   = FONT_BOLD
		tick.TextSize               = 9
		tick.TextColor3             = C.textBright
		tick.BackgroundTransparency = 1
		tick.Size                   = UDim2.fromScale(1,1)
		tick.TextXAlignment         = Enum.TextXAlignment.Center
		tick.TextYAlignment         = Enum.TextYAlignment.Center
		tick.Visible                = default or false
		tick.ZIndex                 = 5
		tick.Parent                 = box

		local lbl = Instance.new("TextLabel")
		lbl.Text                   = labelText
		lbl.Font                   = FONT_REG
		lbl.TextSize               = 12
		lbl.TextColor3             = default and rgbColor or C.text
		lbl.BackgroundTransparency = 1
		lbl.Size                   = UDim2.new(1,-20,1,0)
		lbl.Position               = UDim2.new(0,20,0,0)
		lbl.TextXAlignment         = Enum.TextXAlignment.Left
		lbl.ZIndex                 = 4
		lbl.Parent                 = row

		local lblRgbCb
		local function startLblRGB()
			if lblRgbCb then return end
			lblRgbCb = bindRGB(lbl, "TextColor3")
		end
		local function stopLblRGB()
			if lblRgbCb then
				for i, cb in ipairs(RGBCallbacks) do
					if cb == lblRgbCb then table.remove(RGBCallbacks, i) break end
				end
				lblRgbCb = nil
			end
		end
		if default then startLblRGB() end

		local checked = default or false
		box.MouseButton1Click:Connect(function()
			checked = not checked
			tick.Visible = checked
			if checked then
				startRGB()
				startLblRGB()
			else
				stopRGB()
				stopLblRGB()
				box.BackgroundColor3 = C.checkOff
				boxStroke.Color      = C.border
				tw(lbl, {TextColor3=C.text}):Play()
			end
			if callback then callback(checked) end
		end)
		row.MouseEnter:Connect(function()
			if not checked then tw(lbl,{TextColor3=C.textBright}):Play() end
		end)
		row.MouseLeave:Connect(function()
			if not checked then tw(lbl,{TextColor3=C.text}):Play() end
		end)

		self._y = posY + 26
		return self
	end

	-- ── Dropdown ───────────────────────────────────────────
	function col:Dropdown(labelText, options, default, callback)
		local posY   = self._y
		local COUNT  = #options
		local LIST_H = COUNT * ITEM_H
		local isOpen = false

		local container = Instance.new("Frame")
		container.Name             = "DDContainer"
		container.Size             = UDim2.new(1,-12,0,22)
		container.Position         = UDim2.new(0,6,0,posY)
		container.BackgroundColor3 = C.rowBg
		container.ClipsDescendants = false
		container.ZIndex           = 3
		container.Parent           = sf
		corner(container, 0)
		stroke(container, C.border, 1, 0.4)
		gradient(container, C.rowBgLight, C.rowBg, 180)
		regItem(container, posY)

		if labelText ~= "" then
			local lbl = Instance.new("TextLabel")
			lbl.Text                   = labelText
			lbl.Font                   = FONT_REG
			lbl.TextSize               = 12
			lbl.TextColor3             = C.text
			lbl.BackgroundTransparency = 1
			lbl.Size                   = UDim2.new(0.44,0,0,22)
			lbl.TextXAlignment         = Enum.TextXAlignment.Left
			lbl.ZIndex                 = 4
			lbl.Parent                 = container
		end

		local btnX = labelText ~= "" and 0.45 or 0
		local btnW = labelText ~= "" and 0.54 or 1

		local btn = Instance.new("TextButton")
		btn.Size             = UDim2.new(btnW,0,0,22)
		btn.Position         = UDim2.new(btnX,0,0,0)
		btn.BackgroundColor3 = C.dropBg
		btn.BorderSizePixel  = 0
		btn.Text             = ""
		btn.AutoButtonColor  = false
		btn.ZIndex           = 6
		btn.Parent           = container
		corner(btn, 0)
		local btnStroke = stroke(btn, C.border, 1)
		gradient(btn, Color3.fromRGB(22,22,22), Color3.fromRGB(12,12,12), 180)

		local selIdx = 1
		for i, v in ipairs(options) do
			if v == (default or options[1]) then selIdx = i end
		end

		local selLbl = Instance.new("TextLabel")
		selLbl.Text                   = options[selIdx]
		selLbl.Font                   = FONT_REG
		selLbl.TextSize               = 11
		selLbl.TextColor3             = C.text
		selLbl.BackgroundTransparency = 1
		selLbl.Size                   = UDim2.new(1,-20,1,0)
		selLbl.Position               = UDim2.new(0,6,0,0)
		selLbl.TextXAlignment         = Enum.TextXAlignment.Left
		selLbl.ZIndex                 = 7
		selLbl.Parent                 = btn

		local arrow = Instance.new("TextLabel")
		arrow.Text                   = "▾"
		arrow.Font                   = FONT_BOLD
		arrow.TextSize               = 10
		arrow.TextColor3             = C.textDim
		arrow.BackgroundTransparency = 1
		arrow.Size                   = UDim2.new(0,16,1,0)
		arrow.Position               = UDim2.new(1,-18,0,0)
		arrow.TextXAlignment         = Enum.TextXAlignment.Center
		arrow.ZIndex                 = 7
		arrow.Parent                 = btn

		local listFrame = Instance.new("Frame")
		listFrame.Size             = UDim2.new(btnW,0,0,0)
		listFrame.Position         = UDim2.new(btnX,0,0,24)
		listFrame.BackgroundColor3 = Color3.fromRGB(16,16,16)
		listFrame.BorderSizePixel  = 0
		listFrame.ClipsDescendants = true
		listFrame.Visible          = false
		listFrame.ZIndex           = 20
		listFrame.Parent           = container
		corner(listFrame, 0)
		stroke(listFrame, C.borderBt, 1, 0.2)
		gradient(listFrame, Color3.fromRGB(22,22,22), Color3.fromRGB(12,12,12), 180)

		local arrowRgbCb
		local function startArrowRGB()
			if arrowRgbCb then return end
			arrowRgbCb = bindRGB(arrow, "TextColor3")
		end
		local function stopArrowRGB()
			if arrowRgbCb then
				for i, cb in ipairs(RGBCallbacks) do
					if cb == arrowRgbCb then table.remove(RGBCallbacks, i) break end
				end
				arrowRgbCb = nil
				arrow.TextColor3 = C.textDim
			end
		end

		local function closeDD()
			isOpen    = false
			openDD.fn = nil
			stopArrowRGB()
			tw(arrow,     {Rotation=0}):Play()
			tw(listFrame, {Size=UDim2.new(btnW,0,0,0)}, MED):Play()
			tw(btn,       {BackgroundColor3=C.dropBg}):Play()
			tw(btnStroke, {Color=C.border}):Play()
			task.delay(0.24, function() listFrame.Visible = false end)
			container.Size = UDim2.new(1,-12,0,22)
			shiftBelow(posY, -LIST_H)
		end

		local function openDD_fn()
			if openDD.fn then openDD.fn() end
			isOpen    = true
			openDD.fn = closeDD
			listFrame.Visible = true
			listFrame.Size    = UDim2.new(btnW,0,0,0)
			startArrowRGB()
			tw(arrow,     {Rotation=180}):Play()
			tw(listFrame, {Size=UDim2.new(btnW,0,0,LIST_H)}, MED):Play()
			tw(btn,       {BackgroundColor3=Color3.fromRGB(22,22,22)}):Play()
			tw(btnStroke, {Color=C.borderBt}):Play()
			container.Size = UDim2.new(1,-12,0,22+LIST_H)
			shiftBelow(posY, LIST_H)
		end

		local optButtons = {}
		local optionRgbCallbacks = {}
		for i, optText in ipairs(options) do
			local optBtn = Instance.new("TextButton")
			optBtn.Size                   = UDim2.new(1,0,0,ITEM_H)
			optBtn.Position               = UDim2.new(0,0,0,(i-1)*ITEM_H)
			optBtn.BackgroundTransparency = 1
			optBtn.BorderSizePixel        = 0
			optBtn.Text                   = ""
			optBtn.AutoButtonColor        = false
			optBtn.ZIndex                 = 21
			optBtn.Parent                 = listFrame
			table.insert(optButtons, optBtn)

			local selBar = Instance.new("Frame")
			selBar.Size             = UDim2.new(0,2,0.55,0)
			selBar.Position         = UDim2.new(0,2,0.22,0)
			selBar.BackgroundColor3 = rgbColor
			selBar.BorderSizePixel  = 0
			selBar.Visible          = (i == selIdx)
			selBar.ZIndex           = 22
			selBar.Parent           = optBtn
			corner(selBar, 0)
			if i == selIdx then bindRGB(selBar, "BackgroundColor3") end

			local optLbl = Instance.new("TextLabel")
			optLbl.Text                   = optText
			optLbl.Font                   = FONT_REG
			optLbl.TextSize               = 11
			optLbl.TextColor3             = (i == selIdx) and rgbColor or C.text
			optLbl.BackgroundTransparency = 1
			optLbl.Size                   = UDim2.new(1,-14,1,0)
			optLbl.Position               = UDim2.new(0,12,0,0)
			optLbl.TextXAlignment         = Enum.TextXAlignment.Left
			optLbl.ZIndex                 = 22
			optLbl.Parent                 = optBtn
			optionRgbCallbacks[i] = nil
			if i == selIdx then
				optionRgbCallbacks[i] = bindRGB(optLbl, "TextColor3")
			end

			if i < COUNT then
				local sep = Instance.new("Frame")
				sep.Size                   = UDim2.new(0.88,0,0,1)
				sep.Position               = UDim2.new(0.06,0,1,-1)
				sep.BackgroundColor3       = C.border
				sep.BackgroundTransparency = 0.5
				sep.BorderSizePixel        = 0
				sep.ZIndex                 = 22
				sep.Parent                 = optBtn
			end

			optBtn.MouseEnter:Connect(function()
				if i ~= selIdx then
					optBtn.BackgroundTransparency = 0
					optBtn.BackgroundColor3       = Color3.fromRGB(28,24,38)
					tw(optLbl, {TextColor3=C.textBright}):Play()
				end
			end)
			optBtn.MouseLeave:Connect(function()
				if i ~= selIdx then
					optBtn.BackgroundTransparency = 1
					tw(optLbl, {TextColor3=C.text}):Play()
				end
			end)

			optBtn.MouseButton1Click:Connect(function()
				if optionRgbCallbacks[selIdx] then
					for i2, cb in ipairs(RGBCallbacks) do
						if cb == optionRgbCallbacks[selIdx] then
							table.remove(RGBCallbacks, i2)
							break
						end
					end
					optionRgbCallbacks[selIdx] = nil
				end
				for _, child in ipairs(listFrame:GetChildren()) do
					if child:IsA("TextButton") then
						child.BackgroundTransparency = 1
						local cLbl = child:FindFirstChildWhichIsA("TextLabel")
						if cLbl then cLbl.TextColor3 = C.text end
						for _, cc in ipairs(child:GetChildren()) do
							if cc:IsA("Frame") then cc.Visible = false end
						end
					end
				end
				selIdx            = i
				selLbl.Text       = optText
				optLbl.TextColor3 = rgbColor
				optionRgbCallbacks[i] = bindRGB(optLbl, "TextColor3")
				selBar.Visible    = true
				bindRGB(selBar, "BackgroundColor3")
				closeDD()
				if callback then callback(optText, i) end
			end)
		end

		btn.MouseButton1Click:Connect(function()
			if isOpen then closeDD() else openDD_fn() end
		end)
		btn.MouseEnter:Connect(function()
			if not isOpen then
				tw(btn,       {BackgroundColor3=Color3.fromRGB(22,22,22)}):Play()
				tw(btnStroke, {Color=C.borderBt}):Play()
			end
		end)
		btn.MouseLeave:Connect(function()
			if not isOpen then
				tw(btn,       {BackgroundColor3=C.dropBg}):Play()
				tw(btnStroke, {Color=C.border}):Play()
			end
		end)

		self._y = posY + 26
		return self
	end

	-- ── Slider ─────────────────────────────────────────────
	function col:Slider(labelText, minVal, maxVal, default, callback)
		local posY = self._y
		local row  = makeRow(posY, 22)

		local lbl = Instance.new("TextLabel")
		lbl.Text                   = labelText
		lbl.Font                   = FONT_REG
		lbl.TextSize               = 12
		lbl.TextColor3             = C.text
		lbl.BackgroundTransparency = 1
		lbl.Size                   = UDim2.new(0.42,0,1,0)
		lbl.TextXAlignment         = Enum.TextXAlignment.Left
		lbl.ZIndex                 = 4
		lbl.Parent                 = row

		local valLbl = Instance.new("TextLabel")
		valLbl.Text                   = tostring(default)
		valLbl.Font                   = FONT_REG
		valLbl.TextSize               = 10
		valLbl.TextColor3             = rgbColor
		valLbl.BackgroundTransparency = 1
		valLbl.Size                   = UDim2.new(0.13,0,1,0)
		valLbl.Position               = UDim2.new(0.87,0,0,0)
		valLbl.TextXAlignment         = Enum.TextXAlignment.Right
		valLbl.ZIndex                 = 4
		valLbl.Parent                 = row
		bindRGB(valLbl, "TextColor3")

		local track = Instance.new("Frame")
		track.Size             = UDim2.new(0.42,0,0,4)
		track.Position         = UDim2.new(0.43,0,0.5,-2)
		track.BackgroundColor3 = Color3.fromRGB(24,24,24)
		track.BorderSizePixel  = 0
		track.ZIndex           = 4
		track.Parent           = row
		corner(track, 0)
		stroke(track, C.border, 1, 0.4)

		local pct = (default - minVal) / math.max(maxVal - minVal, 1)

		local fill = Instance.new("Frame")
		fill.Size             = UDim2.new(pct,0,1,0)
		fill.BackgroundColor3 = rgbColor
		fill.BorderSizePixel  = 0
		fill.ZIndex           = 5
		fill.Parent           = track
		corner(fill, 0)
		bindRGB(fill, "BackgroundColor3")

		local knob = Instance.new("TextButton")
		knob.Size             = UDim2.new(0,10,0,10)
		knob.Position         = UDim2.new(pct,-5,0.5,-5)
		knob.BackgroundColor3 = C.sliderKnob
		knob.BorderSizePixel  = 0
		knob.Text             = ""
		knob.AutoButtonColor  = false
		knob.ZIndex           = 6
		knob.Parent           = track
		corner(knob, 5)
		local knobStroke = stroke(knob, rgbColor, 1)
		bindRGB(knobStroke, "Color")

		local dragging = false
		knob.MouseButton1Down:Connect(function() dragging = true end)
		UIS.InputEnded:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
		end)
		UIS.InputChanged:Connect(function(inp)
			if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
				local mouse = UIS:GetMouseLocation()
				local tp    = track.AbsolutePosition
				local ts    = track.AbsoluteSize
				local p     = math.clamp((mouse.X - tp.X) / ts.X, 0, 1)
				local val   = math.floor(minVal + (maxVal - minVal) * p + 0.5)
				fill.Size     = UDim2.new(p,0,1,0)
				knob.Position = UDim2.new(p,-5,0.5,-5)
				valLbl.Text   = tostring(val)
				if callback then callback(val) end
			end
		end)

		self._y = posY + 26
		return self
	end

	-- ── Keybind ────────────────────────────────────────────
	function col:Keybind(labelText, key)
		local posY = self._y
		local row  = makeRow(posY, 22)

		local lbl = Instance.new("TextLabel")
		lbl.Text                   = labelText
		lbl.Font                   = FONT_REG
		lbl.TextSize               = 12
		lbl.TextColor3             = C.text
		lbl.BackgroundTransparency = 1
		lbl.Size                   = UDim2.new(0.55,0,1,0)
		lbl.TextXAlignment         = Enum.TextXAlignment.Left
		lbl.ZIndex                 = 4
		lbl.Parent                 = row

		local keyBtn = Instance.new("TextButton")
		keyBtn.Size             = UDim2.new(0.4,0,0.8,0)
		keyBtn.Position         = UDim2.new(0.57,0,0.1,0)
		keyBtn.BackgroundColor3 = rgbColor
		keyBtn.BorderSizePixel  = 0
		keyBtn.Text             = key or "None"
		keyBtn.Font             = FONT_BOLD
		keyBtn.TextSize         = 10
		keyBtn.TextColor3       = C.textBright
		keyBtn.AutoButtonColor  = false
		keyBtn.ZIndex           = 4
		keyBtn.Parent           = row
		corner(keyBtn, 0)
		local kbStroke = stroke(keyBtn, rgbColor, 1, 0.2)
		bindRGB(keyBtn, "BackgroundColor3")
		bindRGB(kbStroke, "Color")

		self._y = posY + 26
		return self
	end

	-- ── KeyDisplay ──────────────────────────────────────────
	function col:KeyDisplay(key)
		local posY = self._y
		local keyD = Instance.new("TextButton")
		keyD.Size             = UDim2.new(1,-12,0,22)
		keyD.Position         = UDim2.new(0,6,0,posY)
		keyD.BackgroundColor3 = rgbColor
		keyD.BorderSizePixel  = 0
		keyD.Text             = key or "None"
		keyD.Font             = FONT_BOLD
		keyD.TextSize         = 12
		keyD.TextColor3       = C.textBright
		keyD.AutoButtonColor  = false
		keyD.ZIndex           = 3
		keyD.Parent           = sf
		corner(keyD, 0)
		local kdStroke = stroke(keyD, rgbColor, 1, 0.2)
		bindRGB(keyD,    "BackgroundColor3")
		bindRGB(kdStroke,"Color")
		regItem(keyD, posY)
		self._y = posY + 28
		return self
	end

	-- ── Label ──────────────────────────────────────────────
	function col:Label(text)
		local posY = self._y
		local wrap = Instance.new("Frame")
		wrap.Size                   = UDim2.new(1,-12,0,22)
		wrap.Position               = UDim2.new(0,6,0,posY)
		wrap.BackgroundTransparency = 1
		wrap.ZIndex                 = 3
		wrap.Parent                 = sf
		regItem(wrap, posY)

		local lbl = Instance.new("TextLabel")
		lbl.Text                   = text
		lbl.Font                   = FONT_REG
		lbl.TextSize               = 12
		lbl.TextColor3             = C.text
		lbl.BackgroundTransparency = 1
		lbl.Size                   = UDim2.fromScale(1,1)
		lbl.TextXAlignment         = Enum.TextXAlignment.Left
		lbl.ZIndex                 = 4
		lbl.Parent                 = wrap

		self._y = posY + 22
		return self
	end

	-- ── PairedCheckbox ─────────────────────────────────────
	function col:PairedCheckbox(lL, dL, lR, dR, cbL, cbR)
		local posY = self._y
		local row  = makeRow(posY, 22)

		local function makeMini(text, xScale, default, cb)
			local box = Instance.new("TextButton")
			box.Size             = UDim2.new(0,13,0,13)
			box.Position         = UDim2.new(xScale,0,0.5,-6)
			box.BackgroundColor3 = default and rgbColor or C.checkOff
			box.BorderSizePixel  = 0
			box.Text             = ""
			box.AutoButtonColor  = false
			box.ZIndex           = 4
			box.Parent           = row
			corner(box, 0)
			local boxStroke = stroke(box, default and rgbColor or C.border, 1)

			local boxRgbCb, strokeRgbCb
			local function startRGB()
				if boxRgbCb then return end
				boxRgbCb    = bindRGB(box,       "BackgroundColor3")
				strokeRgbCb = bindRGB(boxStroke, "Color")
			end
			local function stopRGB()
				if boxRgbCb then
					for i, c in ipairs(RGBCallbacks) do
						if c == boxRgbCb or c == strokeRgbCb then
							table.remove(RGBCallbacks, i)
						end
					end
					boxRgbCb = nil; strokeRgbCb = nil
				end
			end
			if default then startRGB() end

			local tick = Instance.new("TextLabel")
			tick.Text                   = "✓"
			tick.Font                   = FONT_BOLD
			tick.TextSize               = 8
			tick.TextColor3             = C.textBright
			tick.BackgroundTransparency = 1
			tick.Size                   = UDim2.fromScale(1,1)
			tick.TextXAlignment         = Enum.TextXAlignment.Center
			tick.TextYAlignment         = Enum.TextYAlignment.Center
			tick.Visible                = default
			tick.ZIndex                 = 5
			tick.Parent                 = box

			local minilbl = Instance.new("TextLabel")
			minilbl.Text                   = text
			minilbl.Font                   = FONT_REG
			minilbl.TextSize               = 11
			minilbl.TextColor3             = default and rgbColor or C.text
			minilbl.BackgroundTransparency = 1
			minilbl.Size                   = UDim2.new(0.44,0,1,0)
			minilbl.Position               = UDim2.new(xScale + 0.04, 0, 0, 0)
			minilbl.TextXAlignment         = Enum.TextXAlignment.Left
			minilbl.ZIndex                 = 4
			minilbl.Parent                 = row

			local lblRgbCb
			local function startLblRGB()
				if lblRgbCb then return end
				lblRgbCb = bindRGB(minilbl, "TextColor3")
			end
			local function stopLblRGB()
				if lblRgbCb then
					for i, c in ipairs(RGBCallbacks) do
						if c == lblRgbCb then table.remove(RGBCallbacks, i) break end
					end
					lblRgbCb = nil
				end
			end
			if default then startLblRGB() end

			local checked = default
			box.MouseButton1Click:Connect(function()
				checked = not checked
				tick.Visible = checked
				if checked then
					startRGB(); startLblRGB()
				else
					stopRGB(); stopLblRGB()
					box.BackgroundColor3 = C.checkOff
					boxStroke.Color      = C.border
					tw(minilbl, {TextColor3=C.text}):Play()
				end
				if cb then cb(checked) end
			end)
		end

		makeMini(lL, 0,   dL, cbL)
		makeMini(lR, 0.5, dR, cbR)
		self._y = posY + 24
		return self
	end

	-- ── Spacer ─────────────────────────────────────────────
	function col:Spacer(h)
		self._y = self._y + (h or 8)
		return self
	end

	-- ================================================================
	--  ColorPicker  ── NEW COMPONENT
	-- ================================================================
	-- Usage: col:ColorPicker(labelText, defaultColor, defaultOpacity, callback)
	--   labelText      : string shown on the header row
	--   defaultColor   : Color3 (default Color3.fromRGB(255,255,255))
	--   defaultOpacity : number 0-1 (default 1.0)
	--   callback       : function(Color3, opacity)  called on every change
	--
	-- Layout (collapsed = 22px header-row):
	--   Expanded (+130px):
	--     [Hue bar: full width]         12px tall
	--     [SV square: left ~60%]        60px tall
	--       [Preview swatch: right 35%] sits next to SV square
	--     [Brightness label + slider]   22px
	--     [Opacity    label + slider]   22px
	-- ================================================================
	function col:ColorPicker(labelText, defaultColor, defaultOpacity, callback)
		-- ── tuneable layout constants ──────────────────────────────
		-- All sizes are in pixels. Edit these to reposition things.
		local PANEL_H       = 134    -- total expanded height (excluding the 22px header row)
		local HUE_H         = 12     -- height of the hue bar
		local HUE_MARGIN_T  = 6      -- gap above hue bar
		local SV_W_FRAC     = 0.60   -- fraction of container width used by SV square
		local SV_H          = 60     -- height of SV square
		local SV_TOP        = HUE_MARGIN_T + HUE_H + 6
		local PREV_TOP      = SV_TOP
		local PREV_H        = SV_H
		local BR_TOP        = SV_TOP + SV_H + 6
		local OP_TOP        = BR_TOP + 26
		-- ──────────────────────────────────────────────────────────

		defaultColor   = defaultColor   or Color3.fromRGB(255, 255, 255)
		defaultOpacity = defaultOpacity or 1.0

		local curH, curS, curV = colorToHSV(defaultColor)
		local curOpacity        = defaultOpacity
		local isOpen            = false

		-- Header row (always visible, acts as toggle button)
		local posY   = self._y
		local headerH = 22
		local headerRow = Instance.new("Frame")
		headerRow.Size             = UDim2.new(1,-12,0,headerH)
		headerRow.Position         = UDim2.new(0,6,0,posY)
		headerRow.BackgroundColor3 = C.rowBg
		headerRow.BorderSizePixel  = 0
		headerRow.ZIndex           = 3
		headerRow.Parent           = sf
		corner(headerRow, 0)
		stroke(headerRow, C.border, 1, 0.4)
		gradient(headerRow, C.rowBgLight, C.rowBg, 180)
		regItem(headerRow, posY)

		-- Small color swatch inside header
		local swatchPreview = Instance.new("Frame")
		swatchPreview.Size             = UDim2.new(0,14,0,14)
		swatchPreview.Position         = UDim2.new(0,0,0.5,-7)
		swatchPreview.BackgroundColor3 = defaultColor
		swatchPreview.BorderSizePixel  = 0
		swatchPreview.ZIndex           = 5
		swatchPreview.Parent           = headerRow
		corner(swatchPreview, 2)
		stroke(swatchPreview, C.borderBt, 1, 0)

		local headerLbl = Instance.new("TextLabel")
		headerLbl.Text                   = labelText
		headerLbl.Font                   = FONT_REG
		headerLbl.TextSize               = 12
		headerLbl.TextColor3             = C.text
		headerLbl.BackgroundTransparency = 1
		headerLbl.Size                   = UDim2.new(1,-60,1,0)
		headerLbl.Position               = UDim2.new(0,20,0,0)
		headerLbl.TextXAlignment         = Enum.TextXAlignment.Left
		headerLbl.ZIndex                 = 4
		headerLbl.Parent                 = headerRow

		local cpArrow = Instance.new("TextLabel")
		cpArrow.Text                   = "▾"
		cpArrow.Font                   = FONT_BOLD
		cpArrow.TextSize               = 10
		cpArrow.TextColor3             = C.textDim
		cpArrow.BackgroundTransparency = 1
		cpArrow.Size                   = UDim2.new(0,16,1,0)
		cpArrow.Position               = UDim2.new(1,-18,0,0)
		cpArrow.TextXAlignment         = Enum.TextXAlignment.Center
		cpArrow.ZIndex                 = 4
		cpArrow.Parent                 = headerRow

		-- Expandable panel
		local panel = Instance.new("Frame")
		panel.Size             = UDim2.new(1,-12,0,0)
		panel.Position         = UDim2.new(0,6,0,posY + headerH + 2)
		panel.BackgroundColor3 = Color3.fromRGB(15,15,15)
		panel.BorderSizePixel  = 0
		panel.ClipsDescendants = true
		panel.ZIndex           = 3
		panel.Visible          = false
		panel.Parent           = sf
		corner(panel, 0)
		stroke(panel, C.border, 1, 0.3)
		regItem(panel, posY + headerH + 2)

		-- ── build the inner color picker ─────────────────────────

		-- Helper: build a 1px gradient frame representing the full hue rainbow
		local hueBar = Instance.new("Frame")
		hueBar.Size             = UDim2.new(1,-10,0,HUE_H)
		hueBar.Position         = UDim2.new(0,5,0,HUE_MARGIN_T)
		hueBar.BackgroundColor3 = Color3.fromRGB(255,0,0)
		hueBar.BorderSizePixel  = 0
		hueBar.ZIndex           = 4
		hueBar.Parent           = panel
		corner(hueBar, 2)
		do
			local g = Instance.new("UIGradient")
			g.Color    = makeRainbowSequence()
			g.Rotation = 0
			g.Parent   = hueBar
		end

		-- Hue cursor (vertical bar inside hueBar)
		local hueCursor = Instance.new("Frame")
		hueCursor.Size             = UDim2.new(0,2,1,4)
		hueCursor.Position         = UDim2.new(curH,-1,0,-2)
		hueCursor.BackgroundColor3 = Color3.fromRGB(255,255,255)
		hueCursor.BorderSizePixel  = 0
		hueCursor.ZIndex           = 6
		hueCursor.Parent           = hueBar
		corner(hueCursor, 1)
		stroke(hueCursor, Color3.fromRGB(0,0,0), 1, 0)

		-- SV (saturation-value) square
		-- We simulate it with two overlaid gradients: white→hue and transparent→black
		local svBox = Instance.new("Frame")
		svBox.Size             = UDim2.new(SV_W_FRAC,-6,0,SV_H)
		svBox.Position         = UDim2.new(0,5,0,SV_TOP)
		svBox.BackgroundColor3 = Color3.fromHSV(curH,1,1)
		svBox.BorderSizePixel  = 0
		svBox.ZIndex           = 4
		svBox.Parent           = panel
		corner(svBox, 2)

		local svWhiteGrad = Instance.new("UIGradient")
		svWhiteGrad.Color    = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.new(1,1,1))
		-- white (opaque) left  →  hue color right
		svWhiteGrad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
		svWhiteGrad.Rotation = 0
		svWhiteGrad.Parent   = svBox
		-- Actually we just set BackgroundColor3 to white and overlay the hue;
		-- easier approach: left column = white→hue (horizontal), then vertical black overlay
		-- Re-implement cleanly:
		svWhiteGrad:Destroy()

		-- Layer 1: horizontal white→pure hue
		do
			local g = Instance.new("UIGradient")
			g.Color    = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromHSV(curH,1,1))
			g.Rotation = 0
			g.Parent   = svBox
		end

		-- Layer 2: vertical transparent→black overlay (Frame on top)
		local svDark = Instance.new("Frame")
		svDark.Size             = UDim2.fromScale(1,1)
		svDark.BackgroundColor3 = Color3.fromRGB(0,0,0)
		svDark.BorderSizePixel  = 0
		svDark.ZIndex           = 5
		svDark.Parent           = svBox
		corner(svDark, 2)
		do
			local g = Instance.new("UIGradient")
			g.Color    = ColorSequence.new(Color3.fromRGB(0,0,0), Color3.fromRGB(0,0,0))
			g.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(1, 0),
			})
			g.Rotation = 90
			g.Parent   = svDark
		end

		-- SV cursor circle
		local svCursor = Instance.new("Frame")
		svCursor.Size             = UDim2.new(0,8,0,8)
		svCursor.Position         = UDim2.new(curS,-4,1-curV,-4)
		svCursor.BackgroundColor3 = Color3.fromRGB(255,255,255)
		svCursor.BorderSizePixel  = 0
		svCursor.ZIndex           = 7
		svCursor.Parent           = svBox
		corner(svCursor, 4)
		stroke(svCursor, Color3.fromRGB(0,0,0), 1, 0)

		-- Preview swatch (right side, same height as svBox)
		local prevW = 1 - SV_W_FRAC
		local preview = Instance.new("Frame")
		preview.Size             = UDim2.new(prevW,-10,0,PREV_H)
		preview.Position         = UDim2.new(SV_W_FRAC,3,0,PREV_TOP)
		preview.BackgroundColor3 = defaultColor
		preview.BorderSizePixel  = 0
		preview.ZIndex           = 4
		preview.Parent           = panel
		corner(preview, 3)
		stroke(preview, C.borderBt, 1, 0)

		-- Checkerboard pattern under preview (shows opacity)
		-- We approximate with a UIGradient on a background frame
		local checkBg = Instance.new("Frame")
		checkBg.Size             = UDim2.fromScale(1,1)
		checkBg.BackgroundColor3 = Color3.fromRGB(180,180,180)
		checkBg.BorderSizePixel  = 0
		checkBg.ZIndex           = 3
		checkBg.Parent           = preview
		corner(checkBg, 3)
		do
			local g = Instance.new("UIGradient")
			g.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0,   Color3.fromRGB(160,160,160)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200,200,200)),
				ColorSequenceKeypoint.new(1,   Color3.fromRGB(160,160,160)),
			})
			g.Rotation = 45
			g.Parent   = checkBg
		end

		-- The actual color overlay on top of checkBg
		local prevColor = Instance.new("Frame")
		prevColor.Size             = UDim2.fromScale(1,1)
		prevColor.BackgroundColor3 = defaultColor
		prevColor.BackgroundTransparency = 1 - defaultOpacity
		prevColor.BorderSizePixel  = 0
		prevColor.ZIndex           = 4
		prevColor.Parent           = preview
		corner(prevColor, 3)

		-- Hex label under preview
		local hexLbl = Instance.new("TextLabel")
		hexLbl.Size                   = UDim2.new(prevW,-10,0,12)
		hexLbl.Position               = UDim2.new(SV_W_FRAC,3,0,PREV_TOP+PREV_H+2)
		hexLbl.BackgroundTransparency = 1
		hexLbl.Font                   = FONT_REG
		hexLbl.TextSize               = 9
		hexLbl.TextColor3             = C.textDim
		hexLbl.Text                   = ""
		hexLbl.ZIndex                 = 4
		hexLbl.Parent                 = panel

		-- Brightness slider row
		local brRow = Instance.new("Frame")
		brRow.Size             = UDim2.new(1,-10,0,20)
		brRow.Position         = UDim2.new(0,5,0,BR_TOP)
		brRow.BackgroundTransparency = 1
		brRow.ZIndex           = 4
		brRow.Parent           = panel

		local brLbl = Instance.new("TextLabel")
		brLbl.Text                   = "Brightness"
		brLbl.Font                   = FONT_REG
		brLbl.TextSize               = 10
		brLbl.TextColor3             = C.textDim
		brLbl.BackgroundTransparency = 1
		brLbl.Size                   = UDim2.new(0.38,0,1,0)
		brLbl.TextXAlignment         = Enum.TextXAlignment.Left
		brLbl.ZIndex                 = 4
		brLbl.Parent                 = brRow

		local brTrack = Instance.new("Frame")
		brTrack.Size             = UDim2.new(0.58,0,0,4)
		brTrack.Position         = UDim2.new(0.38,0,0.5,-2)
		brTrack.BackgroundColor3 = Color3.fromRGB(24,24,24)
		brTrack.BorderSizePixel  = 0
		brTrack.ZIndex           = 4
		brTrack.Parent           = brRow
		corner(brTrack, 2)
		do
			local g = Instance.new("UIGradient")
			g.Color    = ColorSequence.new(Color3.fromRGB(0,0,0), Color3.fromRGB(255,255,255))
			g.Rotation = 0
			g.Parent   = brTrack
		end

		local brKnob = Instance.new("TextButton")
		brKnob.Size             = UDim2.new(0,9,0,9)
		brKnob.Position         = UDim2.new(curV,-4,0.5,-4)
		brKnob.BackgroundColor3 = Color3.fromRGB(230,230,230)
		brKnob.BorderSizePixel  = 0
		brKnob.Text             = ""
		brKnob.AutoButtonColor  = false
		brKnob.ZIndex           = 6
		brKnob.Parent           = brTrack
		corner(brKnob, 4)
		stroke(brKnob, Color3.fromRGB(80,80,80), 1, 0)

		local brValLbl = Instance.new("TextLabel")
		brValLbl.Text                   = math.floor(curV*100).."%"
		brValLbl.Font                   = FONT_REG
		brValLbl.TextSize               = 9
		brValLbl.TextColor3             = C.textDim
		brValLbl.BackgroundTransparency = 1
		brValLbl.Size                   = UDim2.new(0,28,1,0)
		brValLbl.Position               = UDim2.new(1,-28,0,0)
		brValLbl.TextXAlignment         = Enum.TextXAlignment.Right
		brValLbl.ZIndex                 = 4
		brValLbl.Parent                 = brRow

		-- Opacity slider row
		local opRow = Instance.new("Frame")
		opRow.Size             = UDim2.new(1,-10,0,20)
		opRow.Position         = UDim2.new(0,5,0,OP_TOP)
		opRow.BackgroundTransparency = 1
		opRow.ZIndex           = 4
		opRow.Parent           = panel

		local opLbl = Instance.new("TextLabel")
		opLbl.Text                   = "Opacity"
		opLbl.Font                   = FONT_REG
		opLbl.TextSize               = 10
		opLbl.TextColor3             = C.textDim
		opLbl.BackgroundTransparency = 1
		opLbl.Size                   = UDim2.new(0.38,0,1,0)
		opLbl.TextXAlignment         = Enum.TextXAlignment.Left
		opLbl.ZIndex                 = 4
		opLbl.Parent                 = opRow

		local opTrack = Instance.new("Frame")
		opTrack.Size             = UDim2.new(0.58,0,0,4)
		opTrack.Position         = UDim2.new(0.38,0,0.5,-2)
		opTrack.BackgroundColor3 = Color3.fromRGB(24,24,24)
		opTrack.BorderSizePixel  = 0
		opTrack.ZIndex           = 4
		opTrack.Parent           = opRow
		corner(opTrack, 2)
		do
			-- Checkerboard→color gradient (transparent→opaque of current color)
			local g = Instance.new("UIGradient")
			g.Color = ColorSequence.new(Color3.fromRGB(60,60,60), defaultColor)
			g.Rotation = 0
			g.Parent   = opTrack
		end

		local opKnob = Instance.new("TextButton")
		opKnob.Size             = UDim2.new(0,9,0,9)
		opKnob.Position         = UDim2.new(curOpacity,-4,0.5,-4)
		opKnob.BackgroundColor3 = Color3.fromRGB(230,230,230)
		opKnob.BorderSizePixel  = 0
		opKnob.Text             = ""
		opKnob.AutoButtonColor  = false
		opKnob.ZIndex           = 6
		opKnob.Parent           = opTrack
		corner(opKnob, 4)
		stroke(opKnob, Color3.fromRGB(80,80,80), 1, 0)

		local opValLbl = Instance.new("TextLabel")
		opValLbl.Text                   = math.floor(curOpacity*100).."%"
		opValLbl.Font                   = FONT_REG
		opValLbl.TextSize               = 9
		opValLbl.TextColor3             = C.textDim
		opValLbl.BackgroundTransparency = 1
		opValLbl.Size                   = UDim2.new(0,28,1,0)
		opValLbl.Position               = UDim2.new(1,-28,0,0)
		opValLbl.TextXAlignment         = Enum.TextXAlignment.Right
		opValLbl.ZIndex                 = 4
		opValLbl.Parent                 = opRow

		-- ── state update helpers ────────────────────────────────
		local function getColor()
			return Color3.fromHSV(curH, curS, curV)
		end

		local function refreshAll()
			local c = getColor()
			-- Update SV box hue
			svBox.BackgroundColor3 = Color3.fromHSV(curH,1,1)
			for _, child in ipairs(svBox:GetChildren()) do
				if child:IsA("UIGradient") then
					child.Color = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromHSV(curH,1,1))
				end
			end
			-- Update SV cursor
			svCursor.Position = UDim2.new(curS,-4,1-curV,-4)
			-- Update hue cursor
			hueCursor.Position = UDim2.new(curH,-1,0,-2)
			-- Update brightness knob & label
			brKnob.Position = UDim2.new(curV,-4,0.5,-4)
			brValLbl.Text   = math.floor(curV*100).."%"
			-- Update opacity knob & label
			opKnob.Position = UDim2.new(curOpacity,-4,0.5,-4)
			opValLbl.Text   = math.floor(curOpacity*100).."%"
			-- Update opacity track gradient color
			for _, child in ipairs(opTrack:GetChildren()) do
				if child:IsA("UIGradient") then
					child.Color = ColorSequence.new(Color3.fromRGB(60,60,60), c)
				end
			end
			-- Update previews
			prevColor.BackgroundColor3       = c
			prevColor.BackgroundTransparency = 1 - curOpacity
			swatchPreview.BackgroundColor3   = c
			-- Callback
			if callback then callback(c, curOpacity) end
		end

		-- ── interaction: hue bar ───────────────────────────────
		local hueDrag = false
		hueBar.InputBegan:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 then
				hueDrag = true
				local p = math.clamp((inp.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
				curH = p
				refreshAll()
			end
		end)
		UIS.InputChanged:Connect(function(inp)
			if hueDrag and inp.UserInputType == Enum.UserInputType.MouseMovement then
				local p = math.clamp((inp.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
				curH = p
				refreshAll()
			end
		end)
		UIS.InputEnded:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 then hueDrag = false end
		end)

		-- ── interaction: SV square ────────────────────────────
		local svDrag = false
		svBox.InputBegan:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 then
				svDrag = true
				curS = math.clamp((inp.Position.X - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
				curV = 1 - math.clamp((inp.Position.Y - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
				refreshAll()
			end
		end)
		UIS.InputChanged:Connect(function(inp)
			if svDrag and inp.UserInputType == Enum.UserInputType.MouseMovement then
				curS = math.clamp((inp.Position.X - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
				curV = 1 - math.clamp((inp.Position.Y - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
				refreshAll()
			end
		end)
		UIS.InputEnded:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 then svDrag = false end
		end)

		-- ── interaction: brightness knob ──────────────────────
		local brDrag = false
		brKnob.MouseButton1Down:Connect(function() brDrag = true end)
		UIS.InputChanged:Connect(function(inp)
			if brDrag and inp.UserInputType == Enum.UserInputType.MouseMovement then
				curV = math.clamp((inp.Position.X - brTrack.AbsolutePosition.X) / brTrack.AbsoluteSize.X, 0, 1)
				refreshAll()
			end
		end)
		UIS.InputEnded:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 then brDrag = false end
		end)

		-- ── interaction: opacity knob ─────────────────────────
		local opDrag = false
		opKnob.MouseButton1Down:Connect(function() opDrag = true end)
		UIS.InputChanged:Connect(function(inp)
			if opDrag and inp.UserInputType == Enum.UserInputType.MouseMovement then
				curOpacity = math.clamp((inp.Position.X - opTrack.AbsolutePosition.X) / opTrack.AbsoluteSize.X, 0, 1)
				refreshAll()
			end
		end)
		UIS.InputEnded:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 then opDrag = false end
		end)

		-- ── open / close panel ────────────────────────────────
		local function openCP()
			isOpen = true
			panel.Visible = true
			panel.Size    = UDim2.new(1,-12,0,0)
			tw(panel,     {Size=UDim2.new(1,-12,0,PANEL_H)}, MED):Play()
			tw(cpArrow,   {Rotation=180}):Play()
			shiftBelow(posY, PANEL_H + 4)
		end

		local function closeCP()
			isOpen = false
			tw(panel,   {Size=UDim2.new(1,-12,0,0)}, MED):Play()
			tw(cpArrow, {Rotation=0}):Play()
			task.delay(0.24, function() panel.Visible = false end)
			shiftBelow(posY, -(PANEL_H + 4))
		end

		local toggleBtn = Instance.new("TextButton")
		toggleBtn.Size             = UDim2.fromScale(1,1)
		toggleBtn.BackgroundTransparency = 1
		toggleBtn.Text             = ""
		toggleBtn.ZIndex           = 5
		toggleBtn.Parent           = headerRow
		toggleBtn.MouseButton1Click:Connect(function()
			if isOpen then closeCP() else openCP() end
		end)

		self._y = posY + headerH + 4
		return self
	end

	-- ================================================================
	--  ExpandableCheckbox  ── NEW COMPONENT
	-- ================================================================
	-- A checkbox that, when turned ON, expands a sub-panel beneath it.
	-- The sub-panel is built using a nested column object.
	--
	-- Usage:
	--   col:ExpandableCheckbox("Enemies", false, nil, function(subCol)
	--       subCol:ColorPicker("Color",  Color3.fromRGB(255,60,60),  1.0)
	--       subCol:Slider("Thickness",   1, 10, 2)
	--   end)
	--
	-- subBuilder : function(subCol)   — called ONCE to populate the panel.
	-- callback   : function(checked) — called when the toggle changes.
	-- ================================================================
	function col:ExpandableCheckbox(labelText, default, callback, subBuilder)
		-- ── checkbox row (always visible) ─────────────────────
		local posY = self._y
		local row  = makeRow(posY, 22)

		local box = Instance.new("TextButton")
		box.Size             = UDim2.new(0,14,0,14)
		box.Position         = UDim2.new(0,0,0.5,-7)
		box.BackgroundColor3 = default and rgbColor or C.checkOff
		box.BorderSizePixel  = 0
		box.Text             = ""
		box.AutoButtonColor  = false
		box.ZIndex           = 4
		box.Parent           = row
		corner(box, 0)
		local boxStroke = stroke(box, default and rgbColor or C.border, 1)

		local boxRgbCb, strokeRgbCb
		local function startRGB()
			if boxRgbCb then return end
			boxRgbCb    = bindRGB(box,       "BackgroundColor3")
			strokeRgbCb = bindRGB(boxStroke, "Color")
		end
		local function stopRGB()
			if boxRgbCb then
				for i, cb in ipairs(RGBCallbacks) do
					if cb == boxRgbCb or cb == strokeRgbCb then
						table.remove(RGBCallbacks, i)
					end
				end
				boxRgbCb = nil; strokeRgbCb = nil
			end
		end
		if default then startRGB() end

		local tick = Instance.new("TextLabel")
		tick.Text                   = "✓"
		tick.Font                   = FONT_BOLD
		tick.TextSize               = 9
		tick.TextColor3             = C.textBright
		tick.BackgroundTransparency = 1
		tick.Size                   = UDim2.fromScale(1,1)
		tick.TextXAlignment         = Enum.TextXAlignment.Center
		tick.TextYAlignment         = Enum.TextYAlignment.Center
		tick.Visible                = default or false
		tick.ZIndex                 = 5
		tick.Parent                 = box

		local lbl = Instance.new("TextLabel")
		lbl.Text                   = labelText
		lbl.Font                   = FONT_REG
		lbl.TextSize               = 12
		lbl.TextColor3             = default and rgbColor or C.text
		lbl.BackgroundTransparency = 1
		lbl.Size                   = UDim2.new(1,-36,1,0)
		lbl.Position               = UDim2.new(0,20,0,0)
		lbl.TextXAlignment         = Enum.TextXAlignment.Left
		lbl.ZIndex                 = 4
		lbl.Parent                 = row

		-- Expand arrow (right side)
		local expArrow = Instance.new("TextLabel")
		expArrow.Text                   = "▾"
		expArrow.Font                   = FONT_BOLD
		expArrow.TextSize               = 10
		expArrow.TextColor3             = C.textDim
		expArrow.BackgroundTransparency = 1
		expArrow.Size                   = UDim2.new(0,16,1,0)
		expArrow.Position               = UDim2.new(1,-18,0,0)
		expArrow.TextXAlignment         = Enum.TextXAlignment.Center
		expArrow.ZIndex                 = 4
		expArrow.Parent                 = row

		local lblRgbCb
		local function startLblRGB()
			if lblRgbCb then return end
			lblRgbCb = bindRGB(lbl, "TextColor3")
		end
		local function stopLblRGB()
			if lblRgbCb then
				for i, cb in ipairs(RGBCallbacks) do
					if cb == lblRgbCb then table.remove(RGBCallbacks, i) break end
				end
				lblRgbCb = nil
			end
		end
		if default then startLblRGB() end

		-- ── sub-panel (hidden until checked) ──────────────────
		local subPanel = Instance.new("Frame")
		subPanel.Size             = UDim2.new(1,-12,0,0)
		subPanel.Position         = UDim2.new(0,6,0,posY + 26)
		subPanel.BackgroundColor3 = Color3.fromRGB(12,12,12)
		subPanel.BorderSizePixel  = 0
		subPanel.ClipsDescendants = true
		subPanel.Visible          = false
		subPanel.ZIndex           = 3
		subPanel.Parent           = sf
		corner(subPanel, 0)
		stroke(subPanel, C.border, 1, 0.5)
		regItem(subPanel, posY + 26)

		-- Build a mini ScrollingFrame inside the sub-panel
		local subSF = Instance.new("ScrollingFrame")
		subSF.Size                   = UDim2.fromScale(1,1)
		subSF.BackgroundTransparency = 1
		subSF.BorderSizePixel        = 0
		subSF.ScrollBarThickness     = 2
		subSF.ScrollBarImageColor3   = rgbColor
		subSF.CanvasSize             = UDim2.new(0,0,0,2000)
		subSF.ZIndex                 = 2
		subSF.Parent                 = subPanel
		bindRGB(subSF, "ScrollBarImageColor3")

		-- Build a column object for the sub-panel
		local subReg   = {}
		local subColObj = makeColumnObj(subSF, subReg, openDD)

		-- Let caller populate the sub-panel
		if subBuilder then subBuilder(subColObj) end
		subColObj:Finalise()

		-- Measure how tall the sub-panel content is
		local subContentH = subColObj._y + 8
		-- Clamp to a max so the UI doesn't explode
		local MAX_SUB_H = 200
		local panelH    = math.min(subContentH, MAX_SUB_H)
		subSF.CanvasSize = UDim2.new(0,0,0,subContentH)

		local expanded = false

		local function openSub()
			expanded = true
			subPanel.Visible = true
			subPanel.Size    = UDim2.new(1,-12,0,0)
			tw(subPanel, {Size=UDim2.new(1,-12,0,panelH)}, MED):Play()
			tw(expArrow, {Rotation=180}):Play()
			shiftBelow(posY, panelH + 2)
		end

		local function closeSub()
			expanded = false
			tw(subPanel, {Size=UDim2.new(1,-12,0,0)}, MED):Play()
			tw(expArrow, {Rotation=0}):Play()
			task.delay(0.24, function() subPanel.Visible = false end)
			shiftBelow(posY, -(panelH + 2))
		end

		local checked = default or false

		box.MouseButton1Click:Connect(function()
			checked = not checked
			tick.Visible = checked
			if checked then
				startRGB()
				startLblRGB()
				openSub()
			else
				stopRGB()
				stopLblRGB()
				box.BackgroundColor3 = C.checkOff
				boxStroke.Color      = C.border
				tw(lbl, {TextColor3=C.text}):Play()
				if expanded then closeSub() end
			end
			if callback then callback(checked) end
		end)

		-- Arrow also toggles expand/collapse independently of the checkbox
		-- (so you can collapse the panel without unchecking)
		expArrow.InputBegan:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 then
				if not checked then return end
				if expanded then closeSub() else openSub() end
			end
		end)

		row.MouseEnter:Connect(function()
			if not checked then tw(lbl,{TextColor3=C.textBright}):Play() end
		end)
		row.MouseLeave:Connect(function()
			if not checked then tw(lbl,{TextColor3=C.text}):Play() end
		end)

		self._y = posY + 28
		return self
	end

	return col
end

-- ============================================================
--  TAB OBJECT FACTORY
-- ============================================================
local function makeTabObj(panel, registry, openDD)
	local tabObj = {}

	local function makeScrollCol(size, pos)
		local sf = Instance.new("ScrollingFrame")
		sf.Size                   = size
		sf.Position               = pos or UDim2.new(0,0,0,0)
		sf.BackgroundTransparency = 1
		sf.BorderSizePixel        = 0
		sf.ScrollBarThickness     = 2
		sf.ScrollBarImageColor3   = rgbColor
		sf.CanvasSize             = UDim2.new(0,0,0,2000)
		sf.ZIndex                 = 2
		sf.Parent                 = panel
		bindRGB(sf, "ScrollBarImageColor3")
		return sf
	end

	function tabObj:TwoColumn()
		local leftSF  = makeScrollCol(UDim2.new(0.5,-1,1,0))
		local rightSF = makeScrollCol(UDim2.new(0.5,-1,1,0), UDim2.new(0.5,1,0,0))

		local div = Instance.new("Frame")
		div.Size             = UDim2.new(0,1,1,0)
		div.Position         = UDim2.new(0.5,0,0,0)
		div.BackgroundColor3 = C.border
		div.BorderSizePixel  = 0
		div.ZIndex           = 2
		div.Parent           = panel

		return makeColumnObj(leftSF, registry, openDD),
		       makeColumnObj(rightSF, registry, openDD)
	end

	function tabObj:SingleColumn()
		local sf = makeScrollCol(UDim2.fromScale(1,1))
		return makeColumnObj(sf, registry, openDD)
	end

	return tabObj
end

-- ============================================================
--  PUBLIC API — VeltaLib.new(config)
-- ============================================================
local VeltaLib = {}

function VeltaLib.new(config)
	local win         = {}
	win._tabPanels    = {}
	win._tabButtons   = {}
	win._activeTab    = nil
	local registry    = {}
	local openDD      = {fn=nil}

	local WIN_W      = config.Width  or 880
	local WIN_H      = config.Height or 530
	local BORDER     = 5
	local TITLEBAR_H = 32
	local SIDEBAR_OW = 140
	local SIDEBAR_CW = 36
	local WIN_MIN_W  = 600
	local WIN_MIN_H  = 380
	local sidebarOpen = true
	local menuVisible = true

	local player    = Players.LocalPlayer
	local guiParent = player:WaitForChild("PlayerGui")
	local gui = Instance.new("ScreenGui")
	gui.Name           = "VeltaGUI"
	gui.ResetOnSpawn   = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent         = guiParent

	local outerFrame = Instance.new("Frame")
	outerFrame.Name             = "WindowFrame"
	outerFrame.Size             = UDim2.new(0, WIN_W+BORDER*2, 0, WIN_H+BORDER*2)
	outerFrame.Position         = UDim2.new(0.5,-(WIN_W+BORDER*2)/2, 0.5,-(WIN_H+BORDER*2)/2)
	outerFrame.BackgroundColor3 = C.shellMid
	outerFrame.BorderSizePixel  = 0
	outerFrame.ZIndex           = 1
	outerFrame.Parent           = gui
	corner(outerFrame, 0)
	local shellGrad = Instance.new("UIGradient")
	shellGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0,   C.shellLight),
		ColorSequenceKeypoint.new(0.5, C.shellMid),
		ColorSequenceKeypoint.new(1,   C.shellDark),
	})
	shellGrad.Rotation = 135
	shellGrad.Parent   = outerFrame
	stroke(outerFrame, Color3.fromRGB(80,80,80), 1, 0)

	local main = Instance.new("Frame")
	main.Name             = "Main"
	main.Size             = UDim2.new(1,-BORDER*2, 1,-BORDER*2)
	main.Position         = UDim2.new(0,BORDER, 0,BORDER)
	main.BackgroundColor3 = C.bgTop
	main.BorderSizePixel  = 0
	main.ZIndex           = 2
	main.ClipsDescendants = false
	main.Parent           = outerFrame
	corner(main, 0)
	gradient(main, C.bgTop, C.bgBot, 160)
	stroke(main, C.borderBt, 1, 0)

	local topAccent = Instance.new("Frame")
	topAccent.Size             = UDim2.new(0,80,0,2)
	topAccent.BackgroundColor3 = rgbColor
	topAccent.BorderSizePixel  = 0
	topAccent.ZIndex           = 6
	topAccent.Parent           = main
	corner(topAccent, 1)
	bindRGB(topAccent, "BackgroundColor3")

	local titleBar = Instance.new("Frame")
	titleBar.Name             = "TitleBar"
	titleBar.Size             = UDim2.new(1,0,0,TITLEBAR_H)
	titleBar.BackgroundColor3 = C.panel
	titleBar.BorderSizePixel  = 0
	titleBar.ZIndex           = 4
	titleBar.Parent           = main
	corner(titleBar, 0)
	gradient(titleBar, Color3.fromRGB(28,28,28), Color3.fromRGB(14,14,14), 180)

	local titleFlush = Instance.new("Frame")
	titleFlush.Size             = UDim2.new(1,0,0,8)
	titleFlush.Position         = UDim2.new(0,0,1,-8)
	titleFlush.BackgroundColor3 = C.panel
	titleFlush.BorderSizePixel  = 0
	titleFlush.ZIndex           = 4
	titleFlush.Parent           = titleBar
	gradient(titleFlush, Color3.fromRGB(28,28,28), Color3.fromRGB(14,14,14), 180)

	local titleSep = Instance.new("Frame")
	titleSep.Size             = UDim2.new(1,0,0,1)
	titleSep.Position         = UDim2.new(0,0,1,-1)
	titleSep.BackgroundColor3 = C.borderBt
	titleSep.BorderSizePixel  = 0
	titleSep.ZIndex           = 5
	titleSep.Parent           = titleBar

	local statusDot = Instance.new("Frame")
	statusDot.Size             = UDim2.new(0,6,0,6)
	statusDot.Position         = UDim2.new(0,12,0.5,-3)
	statusDot.BackgroundColor3 = rgbColor
	statusDot.BorderSizePixel  = 0
	statusDot.ZIndex           = 6
	statusDot.Parent           = titleBar
	corner(statusDot, 3)
	bindRGB(statusDot, "BackgroundColor3")

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Text                   = config.Title or "Velta.Lua"
	titleLabel.Font                   = FONT_BOLD
	titleLabel.TextSize               = 14
	titleLabel.TextColor3             = C.textBright
	titleLabel.BackgroundTransparency = 1
	titleLabel.Size                   = UDim2.new(0,120,1,0)
	titleLabel.Position               = UDim2.new(0,24,0,0)
	titleLabel.TextXAlignment         = Enum.TextXAlignment.Left
	titleLabel.ZIndex                 = 6
	titleLabel.Parent                 = titleBar

	local verLabel = Instance.new("TextLabel")
	verLabel.Text                   = config.SubTitle or "v1.0  ·  mod menu"
	verLabel.Font                   = FONT_REG
	verLabel.TextSize               = 9
	verLabel.TextColor3             = C.textDim
	verLabel.BackgroundTransparency = 1
	verLabel.Size                   = UDim2.new(0,160,0,12)
	verLabel.Position               = UDim2.new(0,138,0.5,-6)
	verLabel.TextXAlignment         = Enum.TextXAlignment.Left
	verLabel.ZIndex                 = 6
	verLabel.Parent                 = titleBar

	local function makeWinBtn(xOff, glyph, hoverBg, hoverTxt)
		local b = Instance.new("TextButton")
		b.Size             = UDim2.new(0,20,0,20)
		b.Position         = UDim2.new(1,xOff,0.5,-10)
		b.BackgroundColor3 = Color3.fromRGB(22,22,22)
		b.BorderSizePixel  = 0
		b.Text             = glyph
		b.Font             = FONT_BOLD
		b.TextSize         = 14
		b.TextColor3       = C.textDim
		b.AutoButtonColor  = false
		b.ZIndex           = 8
		b.Parent           = titleBar
		corner(b, 0)
		local s = stroke(b, C.border, 1, 0.4)
		b.MouseEnter:Connect(function()
			tw(b,{BackgroundColor3=hoverBg,  TextColor3=hoverTxt}):Play()
			tw(s,{Color=hoverTxt, Transparency=0}):Play()
		end)
		b.MouseLeave:Connect(function()
			tw(b,{BackgroundColor3=Color3.fromRGB(22,22,22), TextColor3=C.textDim}):Play()
			tw(s,{Color=C.border, Transparency=0.4}):Play()
		end)
		return b
	end

	local closeBtn    = makeWinBtn(-28, "×", Color3.fromRGB(50,12,12), C.textError)
	local minimizeBtn = makeWinBtn(-52, "−", Color3.fromRGB(36,32,8),  C.yellow)

	local restorePill = Instance.new("TextButton")
	restorePill.Size             = UDim2.new(0,120,0,26)
	restorePill.Position         = UDim2.new(0.5,-60,0,-40)
	restorePill.BackgroundColor3 = Color3.fromRGB(16,16,16)
	restorePill.BorderSizePixel  = 0
	restorePill.Text             = ""
	restorePill.AutoButtonColor  = false
	restorePill.ZIndex           = 50
	restorePill.Visible          = false
	restorePill.Parent           = gui
	corner(restorePill, 13)
	stroke(restorePill, C.borderBt, 1)
	gradient(restorePill, Color3.fromRGB(26,26,26), Color3.fromRGB(10,10,10), 180)

	local pillDot = Instance.new("Frame")
	pillDot.Size             = UDim2.new(0,6,0,6)
	pillDot.Position         = UDim2.new(0,10,0.5,-3)
	pillDot.BackgroundColor3 = rgbColor
	pillDot.BorderSizePixel  = 0
	pillDot.ZIndex           = 52
	pillDot.Parent           = restorePill
	corner(pillDot, 3)
	bindRGB(pillDot, "BackgroundColor3")

	local pillLabel = Instance.new("TextLabel")
	pillLabel.Text                   = string.upper(config.Title or "VELTA.LUA")
	pillLabel.Font                   = FONT_BOLD
	pillLabel.TextSize               = 11
	pillLabel.TextColor3             = C.textBright
	pillLabel.BackgroundTransparency = 1
	pillLabel.Size                   = UDim2.new(1,-24,1,0)
	pillLabel.Position               = UDim2.new(0,22,0,0)
	pillLabel.TextXAlignment         = Enum.TextXAlignment.Left
	pillLabel.ZIndex                 = 52
	pillLabel.Parent                 = restorePill

	restorePill.MouseEnter:Connect(function()
		tw(restorePill,{BackgroundColor3=Color3.fromRGB(26,26,26)}):Play()
	end)
	restorePill.MouseLeave:Connect(function()
		tw(restorePill,{BackgroundColor3=Color3.fromRGB(16,16,16)}):Play()
	end)

	local pillDragging, pillDragStart, pillStartPos = false, nil, nil
	restorePill.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			pillDragging  = true
			pillDragStart = inp.Position
			pillStartPos  = restorePill.Position
		end
	end)
	UIS.InputChanged:Connect(function(inp)
		if pillDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
			local d = inp.Position - pillDragStart
			restorePill.Position = UDim2.new(
				pillStartPos.X.Scale, pillStartPos.X.Offset + d.X,
				pillStartPos.Y.Scale, pillStartPos.Y.Offset + d.Y)
		end
	end)
	UIS.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then pillDragging = false end
	end)

	local blurOverlay = Instance.new("Frame")
	blurOverlay.Size                   = UDim2.fromScale(1,1)
	blurOverlay.BackgroundColor3       = Color3.fromRGB(0,0,0)
	blurOverlay.BackgroundTransparency = 1
	blurOverlay.BorderSizePixel        = 0
	blurOverlay.ZIndex                 = 90
	blurOverlay.Visible                = false
	blurOverlay.Parent                 = gui

	local confirmDialog = Instance.new("Frame")
	confirmDialog.Size             = UDim2.new(0,300,0,158)
	confirmDialog.Position         = UDim2.new(0.5,-150,0.5,-79)
	confirmDialog.BackgroundColor3 = Color3.fromRGB(16,16,16)
	confirmDialog.BorderSizePixel  = 0
	confirmDialog.ZIndex           = 92
	confirmDialog.Parent           = blurOverlay
	corner(confirmDialog, 0)
	gradient(confirmDialog, Color3.fromRGB(24,24,24), Color3.fromRGB(8,8,8), 160)
	stroke(confirmDialog, C.borderBt, 1)

	local dlgTop = Instance.new("Frame")
	dlgTop.Size             = UDim2.new(1,0,0,2)
	dlgTop.BackgroundColor3 = rgbColor
	dlgTop.BorderSizePixel  = 0
	dlgTop.ZIndex           = 93
	dlgTop.Parent           = confirmDialog
	bindRGB(dlgTop, "BackgroundColor3")

	local dlgTitle = Instance.new("TextLabel")
	dlgTitle.Size                   = UDim2.new(1,-36,0,36)
	dlgTitle.Position               = UDim2.new(0,24,0,10)
	dlgTitle.BackgroundTransparency = 1
	dlgTitle.Font                   = FONT_REG
	dlgTitle.TextSize               = 18
	dlgTitle.TextColor3             = C.textBright
	dlgTitle.TextTransparency       = 1
	dlgTitle.Text                   = "CLOSE " .. string.upper(config.Title or "VELTA?")
	dlgTitle.TextXAlignment         = Enum.TextXAlignment.Left
	dlgTitle.ZIndex                 = 93
	dlgTitle.Parent                 = confirmDialog

	local dlgMsg = Instance.new("TextLabel")
	dlgMsg.Size                   = UDim2.new(1,-36,0,46)
	dlgMsg.Position               = UDim2.new(0,24,0,46)
	dlgMsg.BackgroundTransparency = 1
	dlgMsg.Font                   = FONT_REG
	dlgMsg.TextSize               = 11
	dlgMsg.TextColor3             = C.text
	dlgMsg.TextTransparency       = 1
	dlgMsg.TextWrapped            = true
	dlgMsg.Text                   = "Are you sure you want to close the menu?\nRe-execute the script to reopen it."
	dlgMsg.TextXAlignment         = Enum.TextXAlignment.Left
	dlgMsg.ZIndex                 = 93
	dlgMsg.Parent                 = confirmDialog

	local dlgDiv = Instance.new("Frame")
	dlgDiv.Size             = UDim2.new(1,-24,0,1)
	dlgDiv.Position         = UDim2.new(0,12,0,98)
	dlgDiv.BackgroundColor3 = C.borderBt
	dlgDiv.BorderSizePixel  = 0
	dlgDiv.ZIndex           = 93
	dlgDiv.Parent           = confirmDialog

	local function makeDialogBtn(xPos, w, text, bg, textCol, strokeCol)
		local b = Instance.new("TextButton")
		b.Size             = UDim2.new(0,w,0,32)
		b.Position         = UDim2.new(0,xPos,1,-44)
		b.BackgroundColor3 = bg
		b.BorderSizePixel  = 0
		b.Text             = text
		b.TextColor3       = textCol
		b.TextTransparency = 1
		b.TextSize         = 12
		b.Font             = FONT_REG
		b.AutoButtonColor  = false
		b.ZIndex           = 93
		b.Parent           = confirmDialog
		corner(b, 0)
		stroke(b, strokeCol, 1, 0.4)
		return b
	end

	local cancelBtn  = makeDialogBtn(14,  120, "CANCEL", Color3.fromRGB(18,18,18), C.text,      C.borderBt)
	local confirmBtn = makeDialogBtn(166, 120, "CLOSE",  Color3.fromRGB(28,8,8),   C.textError, C.textError)

	cancelBtn.MouseEnter:Connect(function()
		tw(cancelBtn, {BackgroundColor3=Color3.fromRGB(30,30,30),TextColor3=C.textBright}):Play()
	end)
	cancelBtn.MouseLeave:Connect(function()
		tw(cancelBtn, {BackgroundColor3=Color3.fromRGB(18,18,18),TextColor3=C.text}):Play()
	end)
	confirmBtn.MouseEnter:Connect(function()
		tw(confirmBtn,{BackgroundColor3=Color3.fromRGB(50,10,10)}):Play()
	end)
	confirmBtn.MouseLeave:Connect(function()
		tw(confirmBtn,{BackgroundColor3=Color3.fromRGB(28,8,8)}):Play()
	end)

	local function openDialog()
		blurOverlay.Visible = true
		tw(blurOverlay,{BackgroundTransparency=0.5},MED):Play()
		task.delay(0.04,function() tw(dlgTitle,{TextTransparency=0},MED):Play() end)
		task.delay(0.10,function() tw(dlgMsg,  {TextTransparency=0},MED):Play() end)
		task.delay(0.16,function()
			tw(cancelBtn, {TextTransparency=0},MED):Play()
			tw(confirmBtn,{TextTransparency=0},MED):Play()
		end)
	end
	local function closeDialog()
		tw(blurOverlay,{BackgroundTransparency=1},MED):Play()
		tw(dlgTitle,   {TextTransparency=1},FAST):Play()
		tw(dlgMsg,     {TextTransparency=1},FAST):Play()
		tw(cancelBtn,  {TextTransparency=1},FAST):Play()
		tw(confirmBtn, {TextTransparency=1},FAST):Play()
		task.delay(0.28,function() blurOverlay.Visible = false end)
	end

	cancelBtn.MouseButton1Click:Connect(closeDialog)
	confirmBtn.MouseButton1Click:Connect(function()
		tw(blurOverlay,{BackgroundTransparency=0},TweenInfo.new(0.18)):Play()
		task.wait(0.22)
		gui:Destroy()
	end)
	closeBtn.MouseButton1Click:Connect(openDialog)

	local function minimize()
		menuVisible = false
		tw(outerFrame,{BackgroundTransparency=1},MED):Play()
		task.delay(0.08,function()
			outerFrame.Visible   = false
			restorePill.Position = UDim2.new(0.5,-60,0,-40)
			restorePill.Visible  = true
			tw(restorePill,{Position=UDim2.new(0.5,-60,0,10)},SLOW):Play()
		end)
	end
	local function restore()
		tw(restorePill,{Position=UDim2.new(
			restorePill.Position.X.Scale, restorePill.Position.X.Offset, 0,-40
		)},MED):Play()
		task.delay(0.18,function() restorePill.Visible = false end)
		outerFrame.BackgroundTransparency = 0
		outerFrame.Visible = true
		menuVisible = true
	end

	minimizeBtn.MouseButton1Click:Connect(minimize)
	restorePill.MouseButton1Click:Connect(function()
		if not pillDragging then restore() end
	end)
	UIS.InputBegan:Connect(function(inp, gp)
		if gp then return end
		if inp.KeyCode == Enum.KeyCode.Insert then
			if menuVisible then minimize() else restore() end
		end
	end)

	local dragging, dragStart, dragStartPos = false, nil, nil
	titleBar.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging     = true
			dragStart    = inp.Position
			dragStartPos = outerFrame.Position
		end
	end)
	UIS.InputChanged:Connect(function(inp)
		if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
			local d = inp.Position - dragStart
			outerFrame.Position = UDim2.new(
				dragStartPos.X.Scale, dragStartPos.X.Offset + d.X,
				dragStartPos.Y.Scale, dragStartPos.Y.Offset + d.Y)
		end
	end)
	UIS.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)

	local resizeHandle = Instance.new("TextButton")
	resizeHandle.Size                   = UDim2.new(0,20,0,20)
	resizeHandle.Position               = UDim2.new(1,-18,1,-18)
	resizeHandle.BackgroundColor3       = Color3.fromRGB(40,40,40)
	resizeHandle.BackgroundTransparency = 0.5
	resizeHandle.BorderSizePixel        = 0
	resizeHandle.Text                   = ""
	resizeHandle.AutoButtonColor        = false
	resizeHandle.ZIndex                 = 20
	resizeHandle.Parent                 = main
	corner(resizeHandle, 0)

	local resizeGlyph = Instance.new("TextLabel")
	resizeGlyph.Text                   = "↘"
	resizeGlyph.Font                   = FONT_BOLD
	resizeGlyph.TextSize               = 20
	resizeGlyph.TextColor3             = C.textDim
	resizeGlyph.BackgroundTransparency = 1
	resizeGlyph.Size                   = UDim2.fromScale(1,1)
	resizeGlyph.ZIndex                 = 21
	resizeGlyph.Parent                 = resizeHandle

	local resizing, resizeDragStart, resizeStartSize = false, nil, nil
	resizeHandle.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing        = true
			resizeDragStart = inp.Position
			resizeStartSize = outerFrame.AbsoluteSize
		end
	end)
	UIS.InputChanged:Connect(function(inp)
		if resizing and inp.UserInputType == Enum.UserInputType.MouseMovement then
			local d  = inp.Position - resizeDragStart
			local nW = math.max(WIN_MIN_W, resizeStartSize.X + d.X)
			local nH = math.max(WIN_MIN_H, resizeStartSize.Y + d.Y)
			outerFrame.Size = UDim2.new(0,nW,0,nH)
		end
	end)
	UIS.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then resizing = false end
	end)
	resizeHandle.MouseEnter:Connect(function()
		tw(resizeHandle,{BackgroundTransparency=0.2}):Play()
		tw(resizeGlyph, {TextColor3=C.text}):Play()
	end)
	resizeHandle.MouseLeave:Connect(function()
		tw(resizeHandle,{BackgroundTransparency=0.5}):Play()
		tw(resizeGlyph, {TextColor3=C.textDim}):Play()
	end)

	local sidebar = Instance.new("Frame")
	sidebar.Name             = "Sidebar"
	sidebar.Size             = UDim2.new(0,SIDEBAR_OW,1,-TITLEBAR_H)
	sidebar.Position         = UDim2.new(0,0,0,TITLEBAR_H)
	sidebar.BackgroundColor3 = C.sidebarBg
	sidebar.BorderSizePixel  = 0
	sidebar.ZIndex           = 4
	sidebar.ClipsDescendants = true
	sidebar.Parent           = main
	corner(sidebar, 0)
	gradient(sidebar, Color3.fromRGB(22,22,22), Color3.fromRGB(10,10,10), 180)

	local sideFlush = Instance.new("Frame")
	sideFlush.Size             = UDim2.new(0,8,1,0)
	sideFlush.Position         = UDim2.new(1,-8,0,0)
	sideFlush.BackgroundColor3 = C.sidebarBg
	sideFlush.BorderSizePixel  = 0
	sideFlush.ZIndex           = 4
	sideFlush.Parent           = sidebar

	local sideBorder = Instance.new("Frame")
	sideBorder.Size             = UDim2.new(0,1,1,0)
	sideBorder.Position         = UDim2.new(1,0,0,0)
	sideBorder.BackgroundColor3 = C.borderBt
	sideBorder.BorderSizePixel  = 0
	sideBorder.ZIndex           = 5
	sideBorder.Parent           = sidebar

	local sideLogoArea = Instance.new("Frame")
	sideLogoArea.Size             = UDim2.new(1,0,0,40)
	sideLogoArea.BackgroundColor3 = Color3.fromRGB(18,18,18)
	sideLogoArea.BorderSizePixel  = 0
	sideLogoArea.ZIndex           = 5
	sideLogoArea.Parent           = sidebar
	corner(sideLogoArea, 0)
	gradient(sideLogoArea, Color3.fromRGB(30,30,30), Color3.fromRGB(12,12,12), 170)

	local sideLogoDot = Instance.new("Frame")
	sideLogoDot.Size             = UDim2.new(0,7,0,7)
	sideLogoDot.Position         = UDim2.new(0,10,0.5,-3)
	sideLogoDot.BackgroundColor3 = rgbColor
	sideLogoDot.BorderSizePixel  = 0
	sideLogoDot.ZIndex           = 6
	sideLogoDot.Parent           = sideLogoArea
	corner(sideLogoDot, 3)
	bindRGB(sideLogoDot, "BackgroundColor3")

	local sideLogoText = Instance.new("TextLabel")
	sideLogoText.Text                   = config.Creator or "Velta.Lua"
	sideLogoText.Font                   = FONT_SCI
	sideLogoText.TextSize               = 11
	sideLogoText.TextColor3             = C.textBright
	sideLogoText.BackgroundTransparency = 1
	sideLogoText.Size                   = UDim2.new(1,-28,1,0)
	sideLogoText.Position               = UDim2.new(0,22,0,0)
	sideLogoText.TextXAlignment         = Enum.TextXAlignment.Left
	sideLogoText.ZIndex                 = 6
	sideLogoText.Parent                 = sideLogoArea

	local sideLogoDivider = Instance.new("Frame")
	sideLogoDivider.Size             = UDim2.new(1,0,0,1)
	sideLogoDivider.Position         = UDim2.new(0,0,1,-1)
	sideLogoDivider.BackgroundColor3 = C.borderBt
	sideLogoDivider.BorderSizePixel  = 0
	sideLogoDivider.ZIndex           = 6
	sideLogoDivider.Parent           = sideLogoArea

	local sideToggleBtn = Instance.new("TextButton")
	sideToggleBtn.Size             = UDim2.new(1,0,0,28)
	sideToggleBtn.Position         = UDim2.new(0,0,1,-28)
	sideToggleBtn.BackgroundColor3 = Color3.fromRGB(14,14,14)
	sideToggleBtn.BorderSizePixel  = 0
	sideToggleBtn.Text             = "◀"
	sideToggleBtn.Font             = FONT_BOLD
	sideToggleBtn.TextSize         = 11
	sideToggleBtn.TextColor3       = C.textDim
	sideToggleBtn.AutoButtonColor  = false
	sideToggleBtn.ZIndex           = 7
	sideToggleBtn.Parent           = sidebar

	local stDiv = Instance.new("Frame")
	stDiv.Size             = UDim2.new(1,0,0,1)
	stDiv.BackgroundColor3 = C.borderBt
	stDiv.BorderSizePixel  = 0
	stDiv.ZIndex           = 6
	stDiv.Parent           = sideToggleBtn

	sideToggleBtn.MouseEnter:Connect(function()
		tw(sideToggleBtn,{BackgroundColor3=Color3.fromRGB(24,24,24), TextColor3=C.text}):Play()
	end)
	sideToggleBtn.MouseLeave:Connect(function()
		tw(sideToggleBtn,{BackgroundColor3=Color3.fromRGB(14,14,14), TextColor3=C.textDim}):Play()
	end)

	local contentArea = Instance.new("Frame")
	contentArea.Name                   = "ContentArea"
	contentArea.Size                   = UDim2.new(1,-(SIDEBAR_OW+1),1,-TITLEBAR_H)
	contentArea.Position               = UDim2.new(0,SIDEBAR_OW+1,0,TITLEBAR_H)
	contentArea.BackgroundTransparency = 1
	contentArea.BorderSizePixel        = 0
	contentArea.ZIndex                 = 2
	contentArea.Parent                 = main

	local function showTab(name)
		if openDD.fn then openDD.fn(); openDD.fn = nil end
		for _, p in pairs(win._tabPanels) do p.Visible = false end
		if win._tabPanels[name] then win._tabPanels[name].Visible = true end
		for _, d in ipairs(win._tabButtons) do
			local active = d.name == name
			tw(d.btn,     {BackgroundColor3 = active and C.tabActive or C.tabInact}):Play()
			if active then
				if not d._iconRgb then
					d._iconRgb = bindRGB(d.iconLbl, "TextColor3")
				end
			else
				if d._iconRgb then
					for i, cb in ipairs(RGBCallbacks) do
						if cb == d._iconRgb then table.remove(RGBCallbacks, i) break end
					end
					d._iconRgb = nil
					d.iconLbl.TextColor3 = C.textDim
				end
			end
			if active then
				if not d._accentRgb then
					d._accentRgb = bindRGB(d.accent, "BackgroundColor3")
				end
			else
				if d._accentRgb then
					for i, cb in ipairs(RGBCallbacks) do
						if cb == d._accentRgb then table.remove(RGBCallbacks, i) break end
					end
					d._accentRgb = nil
					d.accent.BackgroundColor3 = C.border
				end
			end
			d.accent.Visible = active
			tw(d.lbl, {TextColor3 = active and C.textBright or C.textDim}):Play()
		end
		win._activeTab = name
	end

	local function setSidebar(open)
		sidebarOpen = open
		local w = open and SIDEBAR_OW or SIDEBAR_CW
		tw(sidebar,     {Size=UDim2.new(0,w,1,-TITLEBAR_H)},MED):Play()
		tw(contentArea, {
			Size     = UDim2.new(1,-(w+1),1,-TITLEBAR_H),
			Position = UDim2.new(0,w+1,0,TITLEBAR_H),
		},MED):Play()
		sideToggleBtn.Text = open and "◀" or "▶"
		for _, d in ipairs(win._tabButtons) do
			tw(d.lbl,{TextTransparency = open and 0 or 1},MED):Play()
		end
		tw(sideLogoText,{TextTransparency = open and 0 or 1},MED):Play()
	end

	sideToggleBtn.MouseButton1Click:Connect(function() setSidebar(not sidebarOpen) end)

	local TAB_BTN_H = 34
	local tabDefs   = config.Tabs or {}
	if #tabDefs > 0 then win._activeTab = tabDefs[1].Name end

	for i, def in ipairs(tabDefs) do
		local yPos = 40 + (i-1)*TAB_BTN_H

		local panel = Instance.new("Frame")
		panel.Size                   = UDim2.fromScale(1,1)
		panel.BackgroundTransparency = 1
		panel.Visible                = false
		panel.ZIndex                 = 2
		panel.Parent                 = contentArea
		win._tabPanels[def.Name]     = panel

		local btn = Instance.new("TextButton")
		btn.Name             = def.Name.."Tab"
		btn.Size             = UDim2.new(1,0,0,TAB_BTN_H)
		btn.Position         = UDim2.new(0,0,0,yPos)
		btn.BackgroundColor3 = (def.Name == win._activeTab) and C.tabActive or C.tabInact
		btn.BorderSizePixel  = 0
		btn.Text             = ""
		btn.AutoButtonColor  = false
		btn.ZIndex           = 6
		btn.Parent           = sidebar

		local accent = Instance.new("Frame")
		accent.Size             = UDim2.new(0,2,0.55,0)
		accent.Position         = UDim2.new(0,0,0.22,0)
		accent.BackgroundColor3 = rgbColor
		accent.BorderSizePixel  = 0
		accent.Visible          = (def.Name == win._activeTab)
		accent.ZIndex           = 7
		accent.Parent           = btn
		corner(accent, 0)
		if def.Name == win._activeTab then
			bindRGB(accent, "BackgroundColor3")
		end

		local iconLbl = Instance.new("TextLabel")
		iconLbl.Text                   = def.Icon or "·"
		iconLbl.Font                   = FONT_REG
		iconLbl.TextSize               = 14
		iconLbl.TextColor3             = (def.Name == win._activeTab) and rgbColor or C.textDim
		iconLbl.BackgroundTransparency = 1
		iconLbl.Size                   = UDim2.new(0,SIDEBAR_CW,1,0)
		iconLbl.TextXAlignment         = Enum.TextXAlignment.Center
		iconLbl.ZIndex                 = 7
		iconLbl.Parent                 = btn

		local lbl = Instance.new("TextLabel")
		lbl.Text                   = def.Name
		lbl.Font                   = FONT_BOLD
		lbl.TextSize               = 12
		lbl.TextColor3             = (def.Name == win._activeTab) and C.textBright or C.textDim
		lbl.TextTransparency       = sidebarOpen and 0 or 1
		lbl.BackgroundTransparency = 1
		lbl.Size                   = UDim2.new(1,-(SIDEBAR_CW+2),1,0)
		lbl.Position               = UDim2.new(0,SIDEBAR_CW,0,0)
		lbl.TextXAlignment         = Enum.TextXAlignment.Left
		lbl.ZIndex                 = 7
		lbl.Parent                 = btn

		if i < #tabDefs then
			local sep = Instance.new("Frame")
			sep.Size                   = UDim2.new(0.8,0,0,1)
			sep.Position               = UDim2.new(0.1,0,1,-1)
			sep.BackgroundColor3       = C.border
			sep.BackgroundTransparency = 0.3
			sep.BorderSizePixel        = 0
			sep.ZIndex                 = 6
			sep.Parent                 = btn
		end

		local data = {
			name=def.Name, btn=btn, iconLbl=iconLbl, lbl=lbl, accent=accent,
			_iconRgb=nil, _accentRgb=nil
		}
		if def.Name == win._activeTab then
			data._iconRgb   = bindRGB(iconLbl, "TextColor3")
			data._accentRgb = bindRGB(accent,  "BackgroundColor3")
		end
		table.insert(win._tabButtons, data)

		local capturedName = def.Name
		btn.MouseButton1Click:Connect(function() showTab(capturedName) end)
		btn.MouseEnter:Connect(function()
			if win._activeTab ~= capturedName then
				tw(btn,    {BackgroundColor3=C.panelHover}):Play()
				tw(iconLbl,{TextColor3=C.text}):Play()
				tw(lbl,    {TextColor3=C.text}):Play()
			end
		end)
		btn.MouseLeave:Connect(function()
			if win._activeTab ~= capturedName then
				tw(btn,    {BackgroundColor3=C.tabInact}):Play()
				tw(iconLbl,{TextColor3=C.textDim}):Play()
				tw(lbl,    {TextColor3=C.textDim}):Play()
			end
		end)
	end

	if win._activeTab then showTab(win._activeTab) end

	function win:GetTab(name)
		local panel = self._tabPanels[name]
		assert(panel, "Tab '" .. tostring(name) .. "' not found. Check config.Tabs.")
		return makeTabObj(panel, registry, openDD)
	end

	return win
end

return VeltaLib
