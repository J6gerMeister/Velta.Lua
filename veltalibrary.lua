-- VeltaLibrary.lua
-- Reusable GUI library for Velta-style mod menu UIs.
-- Educational / cosmetic demonstration only — no functional game hooks.
-- Usage: local Velta = loadstring(game:HttpGet("YOUR_RAW_GITHUB_URL"))()

local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

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
	violet     = Color3.fromRGB(140,70, 240),
	violetDim  = Color3.fromRGB(90, 45, 160),
	violetGlow = Color3.fromRGB(175,110,255),
	border     = Color3.fromRGB(42, 42, 42),
	borderBt   = Color3.fromRGB(62, 62, 62),
	textBright = Color3.fromRGB(245,245,245),
	text       = Color3.fromRGB(190,190,190),
	textDim    = Color3.fromRGB(95, 95, 95),
	textError  = Color3.fromRGB(220,60, 60),
	header     = Color3.fromRGB(215,215,215),
	tabActive  = Color3.fromRGB(24, 24, 24),
	tabInact   = Color3.fromRGB(14, 14, 14),
	checkOn    = Color3.fromRGB(130,60, 230),
	checkOff   = Color3.fromRGB(18, 18, 18),
	dropBg     = Color3.fromRGB(14, 14, 14),
	sliderFill = Color3.fromRGB(130,60, 230),
	sliderKnob = Color3.fromRGB(230,230,230),
	keyBg      = Color3.fromRGB(100,40, 200),
	yellow     = Color3.fromRGB(230,190,50),
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
--  COLUMN OBJECT
--  registry : plain table shared across a whole window
--             registry[sf] = { {frame, baseY, extra}, ... }
--  openDD   : {fn = nil}  shared ref to current open-dropdown closer
-- ============================================================
local function makeColumnObj(sf, registry, openDD)
	-- ensure this scrolling frame has a registry slot
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

	-- public column object
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
		box.BackgroundColor3 = default and C.checkOn or C.checkOff
		box.BorderSizePixel  = 0
		box.Text             = ""
		box.AutoButtonColor  = false
		box.ZIndex           = 4
		box.Parent           = row
		corner(box, 0)
		local boxStroke = stroke(box, default and C.violet or C.border, 1)
		if default then gradient(box, C.violet, C.violetDim, 135) end

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
		lbl.TextColor3             = default and C.violetGlow or C.text
		lbl.BackgroundTransparency = 1
		lbl.Size                   = UDim2.new(1,-20,1,0)
		lbl.Position               = UDim2.new(0,20,0,0)
		lbl.TextXAlignment         = Enum.TextXAlignment.Left
		lbl.ZIndex                 = 4
		lbl.Parent                 = row

		local checked = default or false
		box.MouseButton1Click:Connect(function()
			checked = not checked
			tick.Visible = checked
			if checked then
				box.BackgroundColor3 = C.checkOn
				boxStroke.Color = C.violet
				if not box:FindFirstChildWhichIsA("UIGradient") then
					gradient(box, C.violet, C.violetDim, 135)
				end
				tw(lbl, {TextColor3=C.violetGlow}):Play()
			else
				box.BackgroundColor3 = C.checkOff
				boxStroke.Color = C.border
				local g = box:FindFirstChildWhichIsA("UIGradient")
				if g then g:Destroy() end
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
	-- Pass "" as labelText for a full-width dropdown
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

		local function closeDD()
			isOpen       = false
			openDD.fn    = nil
			tw(arrow,     {Rotation=0,   TextColor3=C.textDim}):Play()
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
			tw(arrow,     {Rotation=180, TextColor3=C.violet}):Play()
			tw(listFrame, {Size=UDim2.new(btnW,0,0,LIST_H)}, MED):Play()
			tw(btn,       {BackgroundColor3=Color3.fromRGB(22,22,22)}):Play()
			tw(btnStroke, {Color=C.borderBt}):Play()
			container.Size = UDim2.new(1,-12,0,22+LIST_H)
			shiftBelow(posY, LIST_H)
		end

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

			local selBar = Instance.new("Frame")
			selBar.Size             = UDim2.new(0,2,0.55,0)
			selBar.Position         = UDim2.new(0,2,0.22,0)
			selBar.BackgroundColor3 = C.violet
			selBar.BorderSizePixel  = 0
			selBar.Visible          = (i == selIdx)
			selBar.ZIndex           = 22
			selBar.Parent           = optBtn
			corner(selBar, 0)

			local optLbl = Instance.new("TextLabel")
			optLbl.Text                   = optText
			optLbl.Font                   = FONT_REG
			optLbl.TextSize               = 11
			optLbl.TextColor3             = (i == selIdx) and C.violetGlow or C.text
			optLbl.BackgroundTransparency = 1
			optLbl.Size                   = UDim2.new(1,-14,1,0)
			optLbl.Position               = UDim2.new(0,12,0,0)
			optLbl.TextXAlignment         = Enum.TextXAlignment.Left
			optLbl.ZIndex                 = 22
			optLbl.Parent                 = optBtn

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
				-- reset all rows
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
				optLbl.TextColor3 = C.violetGlow
				selBar.Visible    = true
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
		valLbl.TextColor3             = C.violetGlow
		valLbl.BackgroundTransparency = 1
		valLbl.Size                   = UDim2.new(0.13,0,1,0)
		valLbl.Position               = UDim2.new(0.87,0,0,0)
		valLbl.TextXAlignment         = Enum.TextXAlignment.Right
		valLbl.ZIndex                 = 4
		valLbl.Parent                 = row

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
		fill.BackgroundColor3 = C.sliderFill
		fill.BorderSizePixel  = 0
		fill.ZIndex           = 5
		fill.Parent           = track
		corner(fill, 0)
		gradient(fill, C.violetGlow, C.violet, 0)

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
		stroke(knob, C.violetDim, 1)

		local dragging = false
		knob.MouseButton1Down:Connect(function() dragging = true end)
		UIS.InputEnded:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
			end
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
		keyBtn.BackgroundColor3 = C.keyBg
		keyBtn.BorderSizePixel  = 0
		keyBtn.Text             = key or "None"
		keyBtn.Font             = FONT_BOLD
		keyBtn.TextSize         = 10
		keyBtn.TextColor3       = C.textBright
		keyBtn.AutoButtonColor  = false
		keyBtn.ZIndex           = 4
		keyBtn.Parent           = row
		corner(keyBtn, 0)
		stroke(keyBtn, C.violetDim, 1, 0.2)
		gradient(keyBtn, C.violet, C.violetDim, 135)

		self._y = posY + 26
		return self
	end

	-- ── KeyDisplay (standalone full-width key badge) ────────
	function col:KeyDisplay(key)
		local posY = self._y
		local keyD = Instance.new("TextButton")
		keyD.Size             = UDim2.new(1,-12,0,22)
		keyD.Position         = UDim2.new(0,6,0,posY)
		keyD.BackgroundColor3 = C.keyBg
		keyD.BorderSizePixel  = 0
		keyD.Text             = key or "None"
		keyD.Font             = FONT_BOLD
		keyD.TextSize         = 12
		keyD.TextColor3       = C.textBright
		keyD.AutoButtonColor  = false
		keyD.ZIndex           = 3
		keyD.Parent           = sf
		corner(keyD, 0)
		stroke(keyD, C.violetDim, 1, 0.2)
		gradient(keyD, C.violet, C.violetDim, 135)
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
			box.BackgroundColor3 = default and C.checkOn or C.checkOff
			box.BorderSizePixel  = 0
			box.Text             = ""
			box.AutoButtonColor  = false
			box.ZIndex           = 4
			box.Parent           = row
			corner(box, 0)
			local boxStroke = stroke(box, default and C.violet or C.border, 1)
			if default then gradient(box, C.violet, C.violetDim, 135) end

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
			minilbl.TextColor3             = default and C.violetGlow or C.text
			minilbl.BackgroundTransparency = 1
			minilbl.Size                   = UDim2.new(0.44,0,1,0)
			minilbl.Position               = UDim2.new(xScale + 0.04, 0, 0, 0)
			minilbl.TextXAlignment         = Enum.TextXAlignment.Left
			minilbl.ZIndex                 = 4
			minilbl.Parent                 = row

			local checked = default
			box.MouseButton1Click:Connect(function()
				checked = not checked
				tick.Visible = checked
				if checked then
					box.BackgroundColor3 = C.checkOn
					boxStroke.Color = C.violet
					if not box:FindFirstChildWhichIsA("UIGradient") then
						gradient(box, C.violet, C.violetDim, 135)
					end
					tw(minilbl, {TextColor3=C.violetGlow}):Play()
				else
					box.BackgroundColor3 = C.checkOff
					boxStroke.Color = C.border
					local g = box:FindFirstChildWhichIsA("UIGradient")
					if g then g:Destroy() end
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
		sf.ScrollBarImageColor3   = C.violet
		sf.CanvasSize             = UDim2.new(0,0,0,2000)
		sf.ZIndex                 = 2
		sf.Parent                 = panel
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
	-- Per-window state — no class methods, everything is a plain table + closures
	local win         = {}
	win._tabPanels    = {}
	win._tabButtons   = {}
	win._activeTab    = nil
	local registry    = {}       -- shared across all columns in this window
	local openDD      = {fn=nil} -- shared open-dropdown reference

	local WIN_W      = config.Width  or 880
	local WIN_H      = config.Height or 530
	local BORDER     = 5
	local TITLEBAR_H = 32
	local SIDEBAR_OW = 140   -- open width
	local SIDEBAR_CW = 36    -- collapsed width
	local WIN_MIN_W  = 600
	local WIN_MIN_H  = 380
	local sidebarOpen = true
	local menuVisible = true

	-- ── ScreenGui ────────────────────────────────────────
	local player    = Players.LocalPlayer
	local guiParent = player:WaitForChild("PlayerGui")
	local gui = Instance.new("ScreenGui")
	gui.Name           = "VeltaGUI"
	gui.ResetOnSpawn   = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent         = guiParent

	-- ── Outer shell ──────────────────────────────────────
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

	-- ── Inner main ───────────────────────────────────────
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
	topAccent.BackgroundColor3 = C.violet
	topAccent.BorderSizePixel  = 0
	topAccent.ZIndex           = 6
	topAccent.Parent           = main
	corner(topAccent, 1)
	gradient(topAccent, C.violetGlow, Color3.fromRGB(20,10,40), 0)

	-- ── Title bar ────────────────────────────────────────
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
	statusDot.BackgroundColor3 = C.violet
	statusDot.BorderSizePixel  = 0
	statusDot.ZIndex           = 6
	statusDot.Parent           = titleBar
	corner(statusDot, 3)
	task.spawn(function()
		local t = 0
		while gui.Parent do
			t = t + task.wait(0.05)
			local p = (math.sin(t*1.4)+1)/2
			statusDot.BackgroundColor3 = Color3.fromRGB(
				math.floor(100+70*p), math.floor(40+30*p), math.floor(200+55*p))
		end
	end)

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

	-- ── Restore pill ─────────────────────────────────────
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
	pillDot.BackgroundColor3 = C.violet
	pillDot.BorderSizePixel  = 0
	pillDot.ZIndex           = 52
	pillDot.Parent           = restorePill
	corner(pillDot, 3)

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
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			pillDragging = false
		end
	end)

	-- ── Confirm dialog ───────────────────────────────────
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
	dlgTop.BackgroundColor3 = C.violet
	dlgTop.BorderSizePixel  = 0
	dlgTop.ZIndex           = 93
	dlgTop.Parent           = confirmDialog

	local dlgTitle = Instance.new("TextLabel")
	dlgTitle.Size                   = UDim2.new(1,-36,0,36)
	dlgTitle.Position               = UDim2.new(0,24,0,10)
	dlgTitle.BackgroundTransparency = 1
	dlgTitle.Font                   = FONT_SCI
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
		b.Font             = FONT_SCI
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

	-- ── Minimize / Restore ───────────────────────────────
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

	-- ── Title bar drag ───────────────────────────────────
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

	-- ── Resize handle ────────────────────────────────────
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

	-- ── Sidebar ──────────────────────────────────────────
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
	sideLogoDot.BackgroundColor3 = C.violet
	sideLogoDot.BorderSizePixel  = 0
	sideLogoDot.ZIndex           = 6
	sideLogoDot.Parent           = sideLogoArea
	corner(sideLogoDot, 3)

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

	-- Content area
	local contentArea = Instance.new("Frame")
	contentArea.Name                   = "ContentArea"
	contentArea.Size                   = UDim2.new(1,-(SIDEBAR_OW+1),1,-TITLEBAR_H)
	contentArea.Position               = UDim2.new(0,SIDEBAR_OW+1,0,TITLEBAR_H)
	contentArea.BackgroundTransparency = 1
	contentArea.BorderSizePixel        = 0
	contentArea.ZIndex                 = 2
	contentArea.Parent                 = main

	-- showTab (forward-declared so tab buttons can reference it)
	local function showTab(name)
		if openDD.fn then openDD.fn(); openDD.fn = nil end
		for _, p in pairs(win._tabPanels) do p.Visible = false end
		if win._tabPanels[name] then win._tabPanels[name].Visible = true end
		for _, d in ipairs(win._tabButtons) do
			local active = d.name == name
			tw(d.btn,     {BackgroundColor3 = active and C.tabActive  or C.tabInact}):Play()
			tw(d.iconLbl, {TextColor3       = active and C.violetGlow or C.textDim}):Play()
			tw(d.lbl,     {TextColor3       = active and C.textBright  or C.textDim}):Play()
			d.accent.Visible = active
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

	-- ── Tab buttons ──────────────────────────────────────
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
		accent.BackgroundColor3 = C.violet
		accent.BorderSizePixel  = 0
		accent.Visible          = (def.Name == win._activeTab)
		accent.ZIndex           = 7
		accent.Parent           = btn
		corner(accent, 0)

		local iconLbl = Instance.new("TextLabel")
		iconLbl.Text                   = def.Icon or "·"
		iconLbl.Font                   = FONT_SCI
		iconLbl.TextSize               = 14
		iconLbl.TextColor3             = (def.Name == win._activeTab) and C.violetGlow or C.textDim
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

		local data = {name=def.Name, btn=btn, iconLbl=iconLbl, lbl=lbl, accent=accent}
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

	-- Show the first tab on load
	if win._activeTab then showTab(win._activeTab) end

	-- ── Public method ────────────────────────────────────
	function win:GetTab(name)
		local panel = self._tabPanels[name]
		assert(panel, "Tab '" .. tostring(name) .. "' not found. Check config.Tabs.")
		-- pass the per-window registry and openDD by reference
		return makeTabObj(panel, registry, openDD)
	end

	return win
end

return VeltaLib
