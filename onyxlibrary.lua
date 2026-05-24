-- onyxlibrary.lua  —  Black & White edition + Full Feature Parity with LinoriaLib
-- Features added from LinoriaLib:
--   • Save/Load system hooks (AttemptSave / SaveManager interface)
--   • Watermark (draggable, SetWatermark / SetWatermarkVisibility)
--   • Notifications (Notify with tween-in/out)
--   • Keybind system: Always/Toggle/Hold modes, SyncToggleState, HUD overlay
--   • Dependency Boxes (auto show/hide based on toggle state)
--   • Toggle Risky flag (red label warning)
--   • Dropdown Multi-select, SpecialType = 'Player' / 'Team'
--   • Color Picker: context menu (copy/paste/hex/rgb), transparency, clipboard
--   • Input: Finished mode, Numeric validation, MaxLength, cursor-scroll
--   • Global error handling (NotifyOnError + SafeCallback)
--   • Full live registry recolor (UpdateColorsUsingRegistry, rainbow cycle)
--   • AddDivider, AddLabel wrappable, Tooltips everywhere
--   • Unload with signal cleanup + OnUnload callback
--   • SetLayoutOrder on tabs
--   • All original Onyx positions, colors, theme preserved

local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local TextService  = game:GetService("TextService")
local Teams        = game:GetService("Teams")
local CoreGui      = game:GetService("CoreGui")

-- ============================================================
--  PALETTE  (original Onyx black/white/gray)
-- ============================================================
local C = {
    shellOuter   = Color3.fromRGB(8,   8,   8),
    shellBorder  = Color3.fromRGB(55,  55,  55),
    bgMain       = Color3.fromRGB(100, 100, 100),
    bgDeep       = Color3.fromRGB(0,   0,   0),
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
    notifyAccent = Color3.fromRGB(200, 200, 200),
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

local ITEM_H  = 21
local PICKER_H = 280

-- ============================================================
--  GLOBAL STATE
-- ============================================================
local Toggles  = {}
local Options  = {}
local Signals  = {}

getgenv().Toggles = Toggles
getgenv().Options = Options

-- ============================================================
--  RAINBOW CYCLE
-- ============================================================
local RainbowStep = 0
local Hue = 0
local CurrentRainbowColor = Color3.fromRGB(255,255,255)

table.insert(Signals, RunService.RenderStepped:Connect(function(Delta)
    RainbowStep = RainbowStep + Delta
    if RainbowStep >= (1/60) then
        RainbowStep = 0
        Hue = Hue + (1/400)
        if Hue > 1 then Hue = 0 end
        CurrentRainbowColor = Color3.fromHSV(Hue, 0.8, 1)
    end
end))

-- ============================================================
--  COLOR REGISTRY (live recolor)
-- ============================================================
local Registry    = {}
local RegistryMap = {}
local HudRegistry = {}

local function AddToRegistry(inst, props, isHud)
    local data = {Instance=inst, Properties=props}
    table.insert(Registry, data)
    RegistryMap[inst] = data
    if isHud then table.insert(HudRegistry, data) end
end

local function RemoveFromRegistry(inst)
    local data = RegistryMap[inst]
    if not data then return end
    for i = #Registry, 1, -1 do
        if Registry[i] == data then table.remove(Registry, i) end
    end
    for i = #HudRegistry, 1, -1 do
        if HudRegistry[i] == data then table.remove(HudRegistry, i) end
    end
    RegistryMap[inst] = nil
end

local function UpdateColorsUsingRegistry()
    for _, obj in next, Registry do
        for prop, colorIdx in next, obj.Properties do
            if type(colorIdx) == "string" then
                obj.Instance[prop] = C[colorIdx] or colorIdx
            elseif type(colorIdx) == "function" then
                obj.Instance[prop] = colorIdx()
            end
        end
    end
end

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
    r.Size = UDim2.fromScale(1,1)
    r.BackgroundColor3 = Color3.fromRGB(255,255,255)
    r.BackgroundTransparency = 0.88
    r.BorderSizePixel = 0
    r.ZIndex = frame.ZIndex + 10
    r.Parent = frame
    corner(r, 3)
    tw(r, {BackgroundTransparency=1}, MED):Play()
    game:GetService("Debris"):AddItem(r, 0.3)
end

local function GetTextBounds(text, font, size, resolution)
    local b = TextService:GetTextSize(text, size, font, resolution or Vector2.new(1920,1080))
    return b.X, b.Y
end

local function GetDarkerColor(color)
    local h, s, v = Color3.toHSV(color)
    return Color3.fromHSV(h, s, v/1.5)
end

local function GetPlayersString()
    local list = Players:GetPlayers()
    for i=1,#list do list[i] = list[i].Name end
    table.sort(list, function(a,b) return a < b end)
    return list
end

local function GetTeamsString()
    local list = Teams:GetTeams()
    for i=1,#list do list[i] = list[i].Name end
    table.sort(list, function(a,b) return a < b end)
    return list
end

-- ============================================================
--  SCREENGUI  (protected)
-- ============================================================
local ProtectGui = (protectgui) or (syn and syn.protect_gui) or (function() end)
local ScreenGui = Instance.new("ScreenGui")
ProtectGui(ScreenGui)
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.Parent = CoreGui

-- ============================================================
--  SAFE CALLBACK
-- ============================================================
local NotifyOnError = false

local function SafeCallback(f, ...)
    if not f then return end
    if not NotifyOnError then return f(...) end
    local ok, err = pcall(f, ...)
    if not ok then
        local _, i = err:find(":%d+: ")
        OnyxLib.Notify(i and err:sub(i+1) or err, 3)
    end
end

-- ============================================================
--  ATTEMPT SAVE
-- ============================================================
local SaveManager = nil
local function AttemptSave()
    if SaveManager then SaveManager:Save() end
end

-- ============================================================
--  OPENED FRAMES + TOOLTIP + DEPENDENCY TRACKING
-- ============================================================
local OpenedFrames   = {}
local DependencyBoxes = {}

local function MouseIsOverOpenedFrame(mouse)
    for frame in next, OpenedFrames do
        local ap, as = frame.AbsolutePosition, frame.AbsoluteSize
        if mouse.X >= ap.X and mouse.X <= ap.X+as.X
        and mouse.Y >= ap.Y and mouse.Y <= ap.Y+as.Y then
            return true
        end
    end
end

local function IsMouseOverFrame(frame, mouse)
    local ap, as = frame.AbsolutePosition, frame.AbsoluteSize
    return mouse.X >= ap.X and mouse.X <= ap.X+as.X
       and mouse.Y >= ap.Y and mouse.Y <= ap.Y+as.Y
end

local function UpdateDependencyBoxes()
    for _, depbox in next, DependencyBoxes do
        depbox:Update()
    end
end

local function AddToolTip(infoStr, hoverInst, mouse)
    local x, y = GetTextBounds(infoStr, FONT_REG, 14)
    local tooltip = Instance.new("Frame")
    tooltip.BackgroundColor3 = C.bgRaised
    tooltip.BorderColor3 = C.borderHard
    tooltip.Size = UDim2.fromOffset(x+5, y+4)
    tooltip.ZIndex = 100
    tooltip.Parent = ScreenGui
    tooltip.Visible = false
    corner(tooltip, 2)

    local lbl = Instance.new("TextLabel")
    lbl.Position = UDim2.fromOffset(3,1)
    lbl.Size = UDim2.fromOffset(x,y)
    lbl.TextSize = 14
    lbl.Text = infoStr
    lbl.TextColor3 = C.textBright
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.BackgroundTransparency = 1
    lbl.Font = FONT_REG
    lbl.ZIndex = tooltip.ZIndex + 1
    lbl.Parent = tooltip

    local hovering = false
    hoverInst.MouseEnter:Connect(function()
        if mouse and MouseIsOverOpenedFrame(mouse) then return end
        hovering = true
        tooltip.Position = UDim2.fromOffset(mouse and mouse.X+15 or 0, mouse and mouse.Y+12 or 0)
        tooltip.Visible = true
        while hovering do
            RunService.Heartbeat:Wait()
            tooltip.Position = UDim2.fromOffset(mouse and mouse.X+15 or 0, mouse and mouse.Y+12 or 0)
        end
    end)
    hoverInst.MouseLeave:Connect(function()
        hovering = false
        tooltip.Visible = false
    end)
end

-- ============================================================
--  NOTIFICATION SYSTEM
-- ============================================================
local NotificationArea = Instance.new("Frame")
NotificationArea.BackgroundTransparency = 1
NotificationArea.Position = UDim2.new(0, 0, 0, 40)
NotificationArea.Size = UDim2.new(0, 300, 0, 800)
NotificationArea.ZIndex = 100
NotificationArea.Parent = ScreenGui

do
    local ll = Instance.new("UIListLayout")
    ll.Padding = UDim.new(0, 4)
    ll.FillDirection = Enum.FillDirection.Vertical
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    ll.Parent = NotificationArea
end

local function Notify(text, time)
    local xSize, ySize = GetTextBounds(text, FONT_REG, 14)
    ySize = ySize + 7

    local notifyOuter = Instance.new("Frame")
    notifyOuter.BorderColor3 = Color3.new(0,0,0)
    notifyOuter.Position = UDim2.new(0, 100, 0, 10)
    notifyOuter.Size = UDim2.new(0, 0, 0, ySize)
    notifyOuter.ClipsDescendants = true
    notifyOuter.ZIndex = 100
    notifyOuter.Parent = NotificationArea
    corner(notifyOuter, 2)

    local notifyInner = Instance.new("Frame")
    notifyInner.BackgroundColor3 = C.bgRaised
    notifyInner.BorderSizePixel = 0
    notifyInner.Size = UDim2.fromScale(1,1)
    notifyInner.ZIndex = 101
    notifyInner.Parent = notifyOuter
    corner(notifyInner, 2)
    gradientN(notifyInner, {{0,C.bgSurface},{1,C.bgRaised}}, -90)

    local notifyLabel = Instance.new("TextLabel")
    notifyLabel.Position = UDim2.new(0, 8, 0, 0)
    notifyLabel.Size = UDim2.new(1, -8, 1, 0)
    notifyLabel.Text = text
    notifyLabel.TextXAlignment = Enum.TextXAlignment.Left
    notifyLabel.TextSize = 14
    notifyLabel.Font = FONT_REG
    notifyLabel.TextColor3 = C.textBright
    notifyLabel.BackgroundTransparency = 1
    notifyLabel.ZIndex = 103
    notifyLabel.Parent = notifyInner

    local leftColor = Instance.new("Frame")
    leftColor.BackgroundColor3 = C.notifyAccent
    leftColor.BorderSizePixel = 0
    leftColor.Position = UDim2.new(0,-1,0,-1)
    leftColor.Size = UDim2.new(0,3,1,2)
    leftColor.ZIndex = 104
    leftColor.Parent = notifyOuter
    corner(leftColor, 1)

    notifyOuter:TweenSize(UDim2.new(0, xSize+16, 0, ySize), "Out", "Quad", 0.4, true)

    task.spawn(function()
        task.wait(time or 5)
        notifyOuter:TweenSize(UDim2.new(0,0,0,ySize), "Out", "Quad", 0.4, true)
        task.wait(0.4)
        notifyOuter:Destroy()
    end)
end

-- ============================================================
--  WATERMARK
-- ============================================================
local WatermarkFrame, WatermarkLabel

do
    local wmOuter = Instance.new("Frame")
    wmOuter.BorderColor3 = Color3.new(0,0,0)
    wmOuter.Position = UDim2.new(0, 100, 0, -25)
    wmOuter.Size = UDim2.new(0, 213, 0, 20)
    wmOuter.ZIndex = 200
    wmOuter.Visible = false
    wmOuter.Parent = ScreenGui
    corner(wmOuter, 2)

    local wmInner = Instance.new("Frame")
    wmInner.BackgroundColor3 = C.bgRaised
    wmInner.BorderSizePixel = 0
    wmInner.Size = UDim2.fromScale(1,1)
    wmInner.ZIndex = 201
    wmInner.Parent = wmOuter
    corner(wmInner, 2)
    stroke(wmInner, C.accentDim, 1, 0)
    gradientN(wmInner, {{0, GetDarkerColor(C.bgRaised)},{1,C.bgRaised}}, -90)

    local wmLabel = Instance.new("TextLabel")
    wmLabel.Position = UDim2.new(0,5,0,0)
    wmLabel.Size = UDim2.new(1,-4,1,0)
    wmLabel.TextSize = 14
    wmLabel.TextXAlignment = Enum.TextXAlignment.Left
    wmLabel.Font = FONT_REG
    wmLabel.TextColor3 = C.textBright
    wmLabel.BackgroundTransparency = 1
    wmLabel.ZIndex = 203
    wmLabel.Parent = wmInner

    WatermarkFrame = wmOuter
    WatermarkLabel = wmLabel

    -- Draggable watermark
    local drag, ds, dsp = false, nil, nil
    wmOuter.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = true; ds = inp.Position; dsp = wmOuter.Position
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if drag and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local d = inp.Position - ds
            wmOuter.Position = UDim2.new(dsp.X.Scale, dsp.X.Offset+d.X, dsp.Y.Scale, dsp.Y.Offset+d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
    end)
end

local function SetWatermark(text)
    local x = GetTextBounds(text, FONT_REG, 14)
    WatermarkFrame.Size = UDim2.new(0, x+15, 0, 22)
    WatermarkLabel.Text = text
    WatermarkFrame.Visible = true
end

local function SetWatermarkVisibility(bool)
    WatermarkFrame.Visible = bool
end

-- ============================================================
--  KEYBIND HUD
-- ============================================================
local KeybindFrame, KeybindContainer

do
    local kbOuter = Instance.new("Frame")
    kbOuter.AnchorPoint = Vector2.new(0,0.5)
    kbOuter.BorderColor3 = Color3.new(0,0,0)
    kbOuter.Position = UDim2.new(0,10,0.5,0)
    kbOuter.Size = UDim2.new(0,210,0,20)
    kbOuter.Visible = false
    kbOuter.ZIndex = 100
    kbOuter.Parent = ScreenGui
    corner(kbOuter, 2)

    local kbInner = Instance.new("Frame")
    kbInner.BackgroundColor3 = C.bgRaised
    kbInner.BorderSizePixel = 0
    kbInner.Size = UDim2.fromScale(1,1)
    kbInner.ZIndex = 101
    kbInner.Parent = kbOuter
    corner(kbInner, 2)
    stroke(kbInner, C.borderSoft, 1, 0)

    local colorBar = Instance.new("Frame")
    colorBar.BackgroundColor3 = C.accentMid
    colorBar.BorderSizePixel = 0
    colorBar.Size = UDim2.new(1,0,0,2)
    colorBar.ZIndex = 102
    colorBar.Parent = kbInner

    local kbLabel = Instance.new("TextLabel")
    kbLabel.Size = UDim2.new(1,0,0,20)
    kbLabel.Position = UDim2.fromOffset(5,2)
    kbLabel.TextXAlignment = Enum.TextXAlignment.Left
    kbLabel.Text = "Keybinds"
    kbLabel.Font = FONT_BOLD
    kbLabel.TextSize = 13
    kbLabel.TextColor3 = C.textBright
    kbLabel.BackgroundTransparency = 1
    kbLabel.ZIndex = 104
    kbLabel.Parent = kbInner

    local kbContainer = Instance.new("Frame")
    kbContainer.BackgroundTransparency = 1
    kbContainer.Size = UDim2.new(1,0,1,-20)
    kbContainer.Position = UDim2.new(0,0,0,20)
    kbContainer.ZIndex = 1
    kbContainer.Parent = kbInner

    local kbLayout = Instance.new("UIListLayout")
    kbLayout.FillDirection = Enum.FillDirection.Vertical
    kbLayout.SortOrder = Enum.SortOrder.LayoutOrder
    kbLayout.Parent = kbContainer

    local kbPad = Instance.new("UIPadding")
    kbPad.PaddingLeft = UDim.new(0,5)
    kbPad.Parent = kbContainer

    KeybindFrame = kbOuter
    KeybindContainer = kbContainer

    -- Draggable
    local drag, ds, dsp = false, nil, nil
    kbOuter.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            drag=true; ds=inp.Position; dsp=kbOuter.Position
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if drag and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local d=inp.Position-ds
            kbOuter.Position=UDim2.new(dsp.X.Scale,dsp.X.Offset+d.X,dsp.Y.Scale,dsp.Y.Offset+d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
    end)
end

-- ============================================================
--  COLOR PICKER  (Full HSV + transparency + context menu)
-- ============================================================
local ColorClipboard = nil

local function buildColorPicker(parent, defColor, defOpacity, colorCb)
    defColor   = defColor   or Color3.fromRGB(200,200,200)
    defOpacity = defOpacity or 1.0

    local curH, curS, curV = defColor:ToHSV()
    local curOp = math.clamp(defOpacity, 0, 1)

    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(1,0,0,PICKER_H)
    panel.BackgroundColor3 = Color3.fromRGB(10,10,10)
    panel.BorderSizePixel = 0; panel.ZIndex = 8
    panel.ClipsDescendants = true; panel.Visible = false
    panel.Parent = parent
    corner(panel, 3); stroke(panel, C.borderHard, 1, 0.1)

    -- SV Box
    local svBox = Instance.new("Frame")
    svBox.Size = UDim2.new(0,180,0,160)
    svBox.Position = UDim2.new(0,20,0,15)
    svBox.BackgroundColor3 = Color3.fromHSV(curH,1,1)
    svBox.BorderSizePixel = 0; svBox.ZIndex = 9
    svBox.ClipsDescendants = true; svBox.Parent = panel; corner(svBox,4)

    local satOverlay = Instance.new("Frame")
    satOverlay.Size = UDim2.fromScale(1,1)
    satOverlay.BackgroundColor3 = Color3.fromRGB(255,255,255)
    satOverlay.BorderSizePixel = 0; satOverlay.ZIndex = 10; satOverlay.Parent = svBox
    local satGrad = Instance.new("UIGradient")
    satGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0,0),
        NumberSequenceKeypoint.new(1,1)
    })
    satGrad.Rotation = 0; satGrad.Parent = satOverlay

    local valOverlay = Instance.new("Frame")
    valOverlay.Size = UDim2.fromScale(1,1)
    valOverlay.BackgroundColor3 = Color3.fromRGB(0,0,0)
    valOverlay.BorderSizePixel = 0; valOverlay.ZIndex = 11; valOverlay.Parent = svBox
    local valGrad = Instance.new("UIGradient")
    valGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0,1),
        NumberSequenceKeypoint.new(1,0)
    })
    valGrad.Rotation = 90; valGrad.Parent = valOverlay

    local svCursor = Instance.new("Frame")
    svCursor.Size = UDim2.new(0,12,0,12)
    svCursor.Position = UDim2.new(curS,-6,1-curV,-6)
    svCursor.BackgroundColor3 = Color3.fromRGB(255,255,255)
    svCursor.BorderSizePixel = 0; svCursor.ZIndex = 12; svCursor.Parent = svBox; corner(svCursor,6)
    stroke(svCursor, Color3.fromRGB(50,50,50), 2, 0)

    -- Hue bar
    local hueBar = Instance.new("Frame")
    hueBar.Size = UDim2.new(0,20,0,160)
    hueBar.Position = UDim2.new(0,205,0,15)
    hueBar.BorderSizePixel = 0; hueBar.ZIndex = 9; hueBar.Parent = panel; corner(hueBar,4)

    local hueBkgd = Instance.new("Frame")
    hueBkgd.Size = UDim2.fromScale(1,1)
    hueBkgd.BackgroundColor3 = Color3.fromRGB(255,255,255)
    hueBkgd.BorderSizePixel = 0; hueBkgd.ZIndex = 10; hueBkgd.Parent = hueBar

    local hueGrad = Instance.new("UIGradient")
    hueGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromHSV(0,   1,1)),
        ColorSequenceKeypoint.new(1/6, Color3.fromHSV(1/6, 1,1)),
        ColorSequenceKeypoint.new(2/6, Color3.fromHSV(2/6, 1,1)),
        ColorSequenceKeypoint.new(3/6, Color3.fromHSV(3/6, 1,1)),
        ColorSequenceKeypoint.new(4/6, Color3.fromHSV(4/6, 1,1)),
        ColorSequenceKeypoint.new(5/6, Color3.fromHSV(5/6, 1,1)),
        ColorSequenceKeypoint.new(1,   Color3.fromHSV(1,   1,1)),
    })
    hueGrad.Rotation = 90; hueGrad.Parent = hueBkgd

    local hueCursor = Instance.new("Frame")
    hueCursor.Size = UDim2.new(1,0,0,6)
    hueCursor.Position = UDim2.new(0,0,curH,-3)
    hueCursor.BackgroundColor3 = Color3.fromRGB(100,100,100)
    hueCursor.BorderSizePixel = 0; hueCursor.ZIndex = 13; hueCursor.Parent = hueBar

    -- Opacity/transparency bar
    local opTrack = Instance.new("Frame")
    opTrack.Size = UDim2.new(0,20,0,160)
    opTrack.Position = UDim2.new(0,230,0,15)
    opTrack.BorderSizePixel = 0; opTrack.ZIndex = 9; opTrack.Parent = panel; corner(opTrack,4)

    local opBkgd = Instance.new("ImageLabel")
    opBkgd.Image = "http://www.roblox.com/asset/?id=14204231522"
    opBkgd.ImageTransparency = 0.45
    opBkgd.ScaleType = Enum.ScaleType.Tile
    opBkgd.TileSize = UDim2.fromOffset(10,10)
    opBkgd.Size = UDim2.fromScale(1,1)
    opBkgd.BorderSizePixel = 0; opBkgd.ZIndex = 10; opBkgd.Parent = opTrack

    local opGrad = Instance.new("UIGradient")
    opGrad.Color = ColorSequence.new(defColor, defColor)
    opGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0,1),
        NumberSequenceKeypoint.new(1,0),
    })
    opGrad.Rotation = 90; opGrad.Parent = opBkgd

    local opCursor = Instance.new("Frame")
    opCursor.Size = UDim2.new(1,0,0,6)
    opCursor.Position = UDim2.new(0,0,1-curOp,-3)
    opCursor.BackgroundColor3 = Color3.fromRGB(200,200,200)
    opCursor.BorderSizePixel = 0; opCursor.ZIndex = 13; opCursor.Parent = opTrack

    -- Hex / RGB inputs
    local rgbY = 185

    local hexInput = Instance.new("TextBox")
    hexInput.Size = UDim2.new(0,60,0,20)
    hexInput.Position = UDim2.new(0,20,0,rgbY)
    hexInput.BackgroundColor3 = C.bgRaised
    hexInput.BorderSizePixel = 0; hexInput.TextSize = 11
    hexInput.TextColor3 = C.textBright
    hexInput.Font = FONT_REG; hexInput.ZIndex = 10; hexInput.Parent = panel; corner(hexInput,2)
    hexInput.PlaceholderText = "#RRGGBB"
    hexInput.Text = "#" .. Color3.fromHSV(curH,curS,curV):ToHex()

    local redInput = Instance.new("TextBox")
    redInput.Size = UDim2.new(0,50,0,20)
    redInput.Position = UDim2.new(0,85,0,rgbY)
    redInput.BackgroundColor3 = C.bgRaised
    redInput.BorderSizePixel = 0; redInput.TextSize = 11
    redInput.TextColor3 = C.textBright
    redInput.Font = FONT_REG; redInput.ZIndex = 10; redInput.Parent = panel; corner(redInput,2)
    redInput.PlaceholderText = "R"

    local greenInput = Instance.new("TextBox")
    greenInput.Size = UDim2.new(0,50,0,20)
    greenInput.Position = UDim2.new(0,140,0,rgbY)
    greenInput.BackgroundColor3 = C.bgRaised
    greenInput.BorderSizePixel = 0; greenInput.TextSize = 11
    greenInput.TextColor3 = C.textBright
    greenInput.Font = FONT_REG; greenInput.ZIndex = 10; greenInput.Parent = panel; corner(greenInput,2)
    greenInput.PlaceholderText = "G"

    local blueInput = Instance.new("TextBox")
    blueInput.Size = UDim2.new(0,50,0,20)
    blueInput.Position = UDim2.new(0,195,0,rgbY)
    blueInput.BackgroundColor3 = C.bgRaised
    blueInput.BorderSizePixel = 0; blueInput.TextSize = 11
    blueInput.TextColor3 = C.textBright
    blueInput.Font = FONT_REG; blueInput.ZIndex = 10; blueInput.Parent = panel; corner(blueInput,2)
    blueInput.PlaceholderText = "B"

    local previewBox = Instance.new("Frame")
    previewBox.Size = UDim2.new(0,60,0,30)
    previewBox.Position = UDim2.new(0,258,0,185)
    previewBox.BackgroundColor3 = defColor
    previewBox.BackgroundTransparency = 1 - curOp
    previewBox.BorderSizePixel = 0; previewBox.ZIndex = 10; previewBox.Parent = panel; corner(previewBox,2)
    stroke(previewBox, C.borderHard, 1, 0)

    -- Context menu
    local ctxMenu = Instance.new("Frame")
    ctxMenu.BackgroundColor3 = C.bgDeep
    ctxMenu.BorderSizePixel = 0
    ctxMenu.ZIndex = 50
    ctxMenu.Visible = false
    ctxMenu.Parent = ScreenGui
    corner(ctxMenu, 2)
    stroke(ctxMenu, C.borderHard, 1, 0)

    local ctxInner = Instance.new("Frame")
    ctxInner.BackgroundColor3 = C.bgSurface
    ctxInner.BorderSizePixel = 0
    ctxInner.Size = UDim2.fromScale(1,1)
    ctxInner.ZIndex = 51
    ctxInner.Parent = ctxMenu
    corner(ctxInner, 2)

    local ctxLayout = Instance.new("UIListLayout")
    ctxLayout.FillDirection = Enum.FillDirection.Vertical
    ctxLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ctxLayout.Parent = ctxInner

    local ctxPad = Instance.new("UIPadding")
    ctxPad.PaddingLeft = UDim.new(0,4)
    ctxPad.Parent = ctxInner

    local function addCtxOption(str, cb)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,0,0,16)
        btn.BackgroundTransparency = 1
        btn.Text = str
        btn.Font = FONT_REG
        btn.TextSize = 13
        btn.TextColor3 = C.textMid
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.ZIndex = 52
        btn.Parent = ctxInner
        btn.MouseEnter:Connect(function() tw(btn,{TextColor3=C.accentMid},SNAP):Play() end)
        btn.MouseLeave:Connect(function() tw(btn,{TextColor3=C.textMid},SNAP):Play() end)
        btn.MouseButton1Click:Connect(function() ctxMenu.Visible=false; SafeCallback(cb) end)
    end

    local getColor, getOpacity, setColorRaw -- forward declared below

    addCtxOption("Copy color",  function() ColorClipboard = getColor(); Notify("Copied color!", 2) end)
    addCtxOption("Paste color", function()
        if not ColorClipboard then Notify("No color copied!", 2); return end
        setColorRaw(ColorClipboard, getOpacity()); SafeCallback(colorCb, ColorClipboard, getOpacity())
    end)
    addCtxOption("Copy HEX", function()
        pcall(setclipboard, getColor():ToHex())
        Notify("Copied hex to clipboard!", 2)
    end)
    addCtxOption("Copy RGB", function()
        local col = getColor()
        pcall(setclipboard, table.concat({
            math.floor(col.R*255), math.floor(col.G*255), math.floor(col.B*255)
        }, ", "))
        Notify("Copied RGB to clipboard!", 2)
    end)

    -- Resize context menu to content
    ctxLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        local menuW = 80
        for _, ch in next, ctxInner:GetChildren() do
            if ch:IsA("TextButton") then
                menuW = math.max(menuW, ch.TextBounds.X + 12)
            end
        end
        ctxMenu.Size = UDim2.fromOffset(menuW, ctxLayout.AbsoluteContentSize.Y + 4)
    end)

    local function updateInputs()
        local col = Color3.fromHSV(curH,curS,curV)
        hexInput.Text = "#" .. col:ToHex()
        redInput.Text   = tostring(math.floor(col.R*255))
        greenInput.Text = tostring(math.floor(col.G*255))
        blueInput.Text  = tostring(math.floor(col.B*255))
    end

    local function refreshAll()
        local col = Color3.fromHSV(curH,curS,curV)
        svBox.BackgroundColor3 = Color3.fromHSV(curH,1,1)
        svCursor.Position = UDim2.new(curS,-6,1-curV,-6)
        hueCursor.Position = UDim2.new(0,0,curH,-3)
        opGrad.Color = ColorSequence.new(col,col)
        opCursor.Position = UDim2.new(0,0,1-curOp,-3)
        previewBox.BackgroundColor3 = col
        previewBox.BackgroundTransparency = 1 - curOp
        updateInputs()
        SafeCallback(colorCb, col, curOp)
    end

    getColor   = function() return Color3.fromHSV(curH,curS,curV) end
    getOpacity = function() return curOp end
    setColorRaw = function(color, opacity)
        curH,curS,curV = color:ToHSV()
        curOp = math.clamp(opacity or curOp, 0, 1)
        refreshAll()
    end

    -- Drag events
    local svDrag, hueDrag, opDrag = false,false,false
    svBox.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then
            svDrag=true
            curS = math.clamp((inp.Position.X-svBox.AbsolutePosition.X)/svBox.AbsoluteSize.X, 0,1)
            curV = 1-math.clamp((inp.Position.Y-svBox.AbsolutePosition.Y)/svBox.AbsoluteSize.Y, 0,1)
            refreshAll()
        end
    end)
    hueBar.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then
            hueDrag=true
            curH = math.clamp((inp.Position.Y-hueBar.AbsolutePosition.Y)/hueBar.AbsoluteSize.Y, 0,1)
            refreshAll()
        end
    end)
    opTrack.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then
            opDrag=true
            curOp = 1-math.clamp((inp.Position.Y-opTrack.AbsolutePosition.Y)/opTrack.AbsoluteSize.Y, 0,1)
            refreshAll()
        end
    end)
    table.insert(Signals, UIS.InputChanged:Connect(function(inp)
        if inp.UserInputType~=Enum.UserInputType.MouseMovement then return end
        if svDrag then
            curS = math.clamp((inp.Position.X-svBox.AbsolutePosition.X)/svBox.AbsoluteSize.X, 0,1)
            curV = 1-math.clamp((inp.Position.Y-svBox.AbsolutePosition.Y)/svBox.AbsoluteSize.Y, 0,1)
            refreshAll()
        end
        if hueDrag then
            curH = math.clamp((inp.Position.Y-hueBar.AbsolutePosition.Y)/hueBar.AbsoluteSize.Y, 0,1)
            refreshAll()
        end
        if opDrag then
            curOp = 1-math.clamp((inp.Position.Y-opTrack.AbsolutePosition.Y)/opTrack.AbsoluteSize.Y, 0,1)
            refreshAll()
        end
    end))
    table.insert(Signals, UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then
            svDrag=false; hueDrag=false; opDrag=false
        end
    end))

    -- Hex input
    hexInput.FocusLost:Connect(function(enter)
        if not enter then return end
        local s = hexInput.Text:gsub("%s",""):upper()
        if s:sub(1,1)~="#" then s="#"..s end
        if #s==7 then
            local ok, col = pcall(Color3.fromHex, s:sub(2))
            if ok then curH,curS,curV=col:ToHSV(); refreshAll(); return end
        end
        updateInputs()
    end)

    local function applyRGB()
        local r=tonumber(redInput.Text) or 0
        local g=tonumber(greenInput.Text) or 0
        local b=tonumber(blueInput.Text) or 0
        if r>=0 and r<=255 and g>=0 and g<=255 and b>=0 and b<=255 then
            curH,curS,curV = Color3.fromRGB(r,g,b):ToHSV(); refreshAll()
        end
    end
    redInput.FocusLost:Connect(function(e) if e then applyRGB() end end)
    greenInput.FocusLost:Connect(function(e) if e then applyRGB() end end)
    blueInput.FocusLost:Connect(function(e) if e then applyRGB() end end)

    refreshAll()
    return panel, getColor, getOpacity, setColorRaw, ctxMenu
end

-- ============================================================
--  ARG NORMALISERS (same as original Onyx)
-- ============================================================
local function normaliseDropArgs(a1,a2,a3,a4,a5,a6,a7,a8,a9)
    if type(a1)=="string" and type(a2)=="string" then
        return a1,a2,a3,a4,a5,a6,a7,a8,a9
    else
        return nil,a1,a2,a3,a4,a5,a6,a7,a8
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
    local obj = {}
    obj.Value    = defaultValue
    obj.Callback = callback
    local _changed = nil
    function obj:OnChanged(fn) _changed=fn; if fn then fn(self.Value) end end
    function obj:GetValue() return self.Value end
    function obj:_fire(v)
        self.Value = v
        if self.Callback then SafeCallback(self.Callback, v) end
        if _changed      then SafeCallback(_changed, v)      end
    end
    function obj:SetValue(v) self:_fire(v) end
    return obj
end

-- ============================================================
--  COLUMN BUILDER
-- ============================================================
local function makeColumnObj(sf, registry, openDD, winOptions, mouse)
    if not registry[sf] then registry[sf] = {} end
    local regList = registry[sf]

    local function regItem(frame, baseY)
        table.insert(regList, {frame=frame, baseY=baseY, extra=0})
    end

    local function shiftBelow(afterY, delta, animate)
        if animate==nil then animate=true end
        for _, e in ipairs(regList) do
            if e.baseY > afterY then
                e.extra = e.extra + delta
                local tp = UDim2.new(e.frame.Position.X.Scale, e.frame.Position.X.Offset, 0, e.baseY+e.extra)
                if animate and delta~=0 then tw(e.frame,{Position=tp},MED):Play() else e.frame.Position=tp end
            end
        end
        local maxY = 0
        for _, e in ipairs(regList) do
            local bot = e.baseY + e.extra + e.frame.AbsoluteSize.Y
            if bot > maxY then maxY = bot end
        end
        sf.CanvasSize = UDim2.new(0,0,0,maxY+20)
    end

    local function makeRow(posY, h)
        h = h or 22
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1,-12,0,h)
        row.Position = UDim2.new(0,6,0,posY)
        row.BackgroundColor3 = C.rowBg
        row.BorderSizePixel = 0; row.ZIndex = 3; row.Parent = sf
        corner(row, 2); stroke(row, C.borderSoft, 1, 0.5)
        gradientN(row, {{0,C.rowBgAlt},{0.4,C.rowBg},{1,C.bgDeep}}, 180)
        regItem(row, posY); return row
    end

    local col = {_sf=sf, _y=8}

    function col:Finalise()
        self._sf.CanvasSize = UDim2.new(0,0,0,self._y+20)
    end

    -- ── Header ──
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
        do local g=Instance.new("UIGradient"); g.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}); g.Rotation=0; g.Parent=bar end
        self._y = posY+24; return self
    end

    -- ── Separator / Divider ──
    function col:Separator()
        local posY = self._y
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1,-24,0,1); f.Position = UDim2.new(0,12,0,posY)
        f.BackgroundColor3 = C.borderFaint; f.BorderSizePixel = 0; f.ZIndex = 3; f.Parent = sf
        do local g=Instance.new("UIGradient"); g.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.4),NumberSequenceKeypoint.new(0.5,0),NumberSequenceKeypoint.new(1,0.4)}); g.Rotation=0; g.Parent=f end
        regItem(f, posY); self._y = posY+9; return self
    end
    col.AddDivider = col.Separator  -- alias

    -- ── Spacer ──
    function col:Spacer(h) self._y = self._y + (h or 8); return self end
    col.AddBlank = col.Spacer

    -- ── Label ──
    function col:Label(text, doesWrap)
        local posY = self._y
        local h = doesWrap and (select(2, GetTextBounds(text, FONT_REG, 12, Vector2.new(sf.AbsoluteSize.X - 20, math.huge))) + 4) or 22
        local wrap = Instance.new("Frame")
        wrap.Size = UDim2.new(1,-12,0,h); wrap.Position = UDim2.new(0,6,0,posY)
        wrap.BackgroundTransparency = 1; wrap.ZIndex = 3; wrap.Parent = sf; regItem(wrap, posY)
        local lbl = Instance.new("TextLabel")
        lbl.Text = text; lbl.Font = FONT_REG; lbl.TextSize = 12; lbl.TextColor3 = C.textSub
        lbl.BackgroundTransparency = 1; lbl.Size = UDim2.fromScale(1,1)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextWrapped = doesWrap or false
        lbl.ZIndex = 4; lbl.Parent = wrap
        local labelObj = {TextLabel = lbl}
        function labelObj:SetText(t)
            lbl.Text = t
        end
        self._y = posY + h + 4; return labelObj, self
    end
    col.AddLabel = col.Label

    -- ── Button ──
    function col:Button(text, func, tooltip)
        local posY = self._y
        local outer = Instance.new("Frame")
        outer.Size = UDim2.new(1,-12,0,22); outer.Position = UDim2.new(0,6,0,posY)
        outer.BackgroundColor3 = C.bgDeep; outer.BorderSizePixel = 0; outer.ZIndex = 3; outer.Parent = sf
        corner(outer, 2); stroke(outer, C.borderSoft, 1, 0.3)
        gradientN(outer, {{0,C.bgRaised},{1,C.bgDeep}}, 180)
        regItem(outer, posY)

        local lbl = Instance.new("TextButton")
        lbl.Size = UDim2.fromScale(1,1)
        lbl.BackgroundTransparency = 1
        lbl.Text = text; lbl.Font = FONT_BOLD; lbl.TextSize = 12
        lbl.TextColor3 = C.textMid; lbl.AutoButtonColor = false
        lbl.ZIndex = 4; lbl.Parent = outer

        local buttonObj = {Outer=outer, Label=lbl, Text=text, Func=func}

        outer.MouseEnter:Connect(function()
            tw(outer, {BackgroundColor3=C.bgHover}, SNAP):Play()
            tw(lbl,   {TextColor3=C.textBright},    SNAP):Play()
        end)
        outer.MouseLeave:Connect(function()
            tw(outer, {BackgroundColor3=C.bgDeep}, SNAP):Play()
            tw(lbl,   {TextColor3=C.textMid},      SNAP):Play()
        end)
        lbl.MouseButton1Click:Connect(function()
            ripple(outer)
            SafeCallback(func)
            AttemptSave()
        end)

        if tooltip then AddToolTip(tooltip, outer, mouse) end

        function buttonObj:AddButton(text2, func2, tip2)
            outer.Size = UDim2.new(0.5,-8,0,22)
            local sub = Instance.new("Frame")
            sub.Size = UDim2.new(0,outer.AbsoluteSize.X,0,22)
            sub.Position = UDim2.new(0,outer.AbsoluteSize.X+4,0,0)
            sub.BackgroundColor3 = C.bgDeep; sub.BorderSizePixel = 0; sub.ZIndex = 3; sub.Parent = outer
            corner(sub, 2); stroke(sub, C.borderSoft, 1, 0.3)
            gradientN(sub, {{0,C.bgRaised},{1,C.bgDeep}}, 180)
            local sLbl = Instance.new("TextButton")
            sLbl.Size = UDim2.fromScale(1,1)
            sLbl.BackgroundTransparency = 1
            sLbl.Text = text2; sLbl.Font = FONT_BOLD; sLbl.TextSize = 12
            sLbl.TextColor3 = C.textMid; sLbl.AutoButtonColor = false
            sLbl.ZIndex = 4; sLbl.Parent = sub
            sub.MouseEnter:Connect(function() tw(sub,{BackgroundColor3=C.bgHover},SNAP):Play(); tw(sLbl,{TextColor3=C.textBright},SNAP):Play() end)
            sub.MouseLeave:Connect(function() tw(sub,{BackgroundColor3=C.bgDeep},SNAP):Play(); tw(sLbl,{TextColor3=C.textMid},SNAP):Play() end)
            sLbl.MouseButton1Click:Connect(function() ripple(sub); SafeCallback(func2); AttemptSave() end)
            if tip2 then AddToolTip(tip2, sub, mouse) end
            return {Outer=sub, Label=sLbl}
        end

        self._y = posY+26; return buttonObj, self
    end
    col.AddButton = col.Button

    -- ── Checkbox / Toggle ──
    function col:Checkbox(a1,a2,a3,a4,a5,a6,a7,a8)
        local key, labelText, default, callback, doColorPicker, defColor, defOpacity, colorCb
        if type(a1)=="string" and type(a2)=="string" then
            key,labelText,default,callback,doColorPicker,defColor,defOpacity,colorCb = a1,a2,a3,a4,a5,a6,a7,a8
        else
            key,labelText,default,callback,doColorPicker,defColor,defOpacity,colorCb = nil,a1,a2,a3,a4,a5,a6,a7
        end

        local posY = self._y
        local cpOpen = false
        local function containerH() return 22+(cpOpen and (PICKER_H+2) or 0) end

        local container = Instance.new("Frame")
        container.Size = UDim2.new(1,-12,0,22); container.Position = UDim2.new(0,6,0,posY)
        container.BackgroundColor3 = C.rowBg; container.BorderSizePixel = 0
        container.ClipsDescendants = false; container.ZIndex = 3; container.Parent = sf
        corner(container, 2); stroke(container, C.borderSoft, 1, 0.5)
        gradientN(container, {{0,C.rowBgAlt},{0.4,C.rowBg},{1,C.bgDeep}}, 180)
        regItem(container, posY)

        local obj = newElementObj(default or false, callback)
        obj.Type = "Toggle"
        obj.Addons = {}

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

        local lblW = doColorPicker and -44 or -24
        local lbl = Instance.new("TextLabel")
        lbl.Text = tostring(labelText); lbl.Font = FONT_REG; lbl.TextSize = 12
        lbl.TextColor3 = obj.Value and C.textBright or C.textMid
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.new(1,lblW,1,0); lbl.Position = UDim2.new(0,22,0,0)
        lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 4; lbl.Parent = container

        -- Risky flag
        if a8 == true or (type(callback)=="boolean" and callback==true) then
            -- If explicitly passed Risky as last arg (convenience)
        end

        -- Color picker swatch
        local swatchBtn, swatchStroke, pickerPanel, cpObj, setPickerRaw
        if doColorPicker then
            defColor   = defColor   or Color3.fromRGB(200,200,200)
            defOpacity = defOpacity or 1.0
            swatchBtn = Instance.new("TextButton")
            swatchBtn.Size = UDim2.new(0,13,0,13)
            swatchBtn.AnchorPoint = Vector2.new(1,0.5)
            swatchBtn.Position = UDim2.new(1,-12,0.5,0)
            swatchBtn.BackgroundColor3 = defColor
            swatchBtn.BackgroundTransparency = 1 - math.clamp(defOpacity,0,1)
            swatchBtn.BorderSizePixel = 0; swatchBtn.Text = ""
            swatchBtn.AutoButtonColor = false; swatchBtn.ZIndex = 60
            swatchBtn.Parent = container; corner(swatchBtn, 2)
            swatchStroke = stroke(swatchBtn, C.borderHard, 1.5, 0)

            local swBg = Instance.new("ImageLabel")
            swBg.Size = UDim2.fromScale(1,1)
            swBg.Image = "http://www.roblox.com/asset/?id=14204231522"
            swBg.ImageTransparency = 0.45; swBg.ScaleType = Enum.ScaleType.Tile
            swBg.TileSize = UDim2.fromOffset(6,6)
            swBg.BackgroundTransparency = 1; swBg.BorderSizePixel = 0
            swBg.ZIndex = 59; swBg.Parent = swatchBtn

            local ctxMenu
            pickerPanel, _, _, setPickerRaw, ctxMenu = buildColorPicker(container, defColor, defOpacity, function(c, op)
                if swatchBtn then
                    swatchBtn.BackgroundColor3 = c
                    swatchBtn.BackgroundTransparency = 1-math.clamp(op or 1, 0,1)
                end
                if cpObj then cpObj:_fire({Color=c, Opacity=op}) end
                SafeCallback(colorCb, c, op)
            end)
            pickerPanel.Position = UDim2.new(0,0,0,22)

            cpObj = newElementObj({Color=defColor, Opacity=defOpacity}, colorCb)
            function cpObj:SetValue(color, opacity)
                if setPickerRaw then setPickerRaw(color, opacity or 1) end
                self:_fire({Color=color, Opacity=opacity or 1})
            end
            if key and winOptions then winOptions[key.."_Color"] = cpObj end

            local function closeCP()
                cpOpen = false
                tw(pickerPanel,{Size=UDim2.new(1,0,0,0)},MED):Play()
                tw(swatchStroke,{Color=C.borderHard},FAST):Play()
                tw(container,{Size=UDim2.new(1,-12,0,containerH())},MED):Play()
                task.delay(0.26, function()
                    if not cpOpen then
                        pickerPanel.Visible = false
                        shiftBelow(posY, -(PICKER_H+2), true)
                    end
                end)
            end
            local function openCP()
                cpOpen = true
                pickerPanel.Size = UDim2.new(1,0,0,0); pickerPanel.Visible = true
                tw(swatchStroke,{Color=C.accentMid},FAST):Play()
                tw(pickerPanel,{Size=UDim2.new(1,0,0,PICKER_H)},SPRING):Play()
                tw(container,{Size=UDim2.new(1,-12,0,containerH())},MED):Play()
                shiftBelow(posY, PICKER_H+2, true)
            end
            swatchBtn.MouseButton1Click:Connect(function()
                if cpOpen then closeCP() else openCP() end
            end)
            -- Right-click context menu
            swatchBtn.MouseButton2Click:Connect(function()
                if mouse then
                    ctxMenu.Position = UDim2.fromOffset(mouse.X+4, mouse.Y+4)
                end
                ctxMenu.Visible = not ctxMenu.Visible
            end)
        end

        -- State logic
        local function applyState(v)
            tick.Visible = v
            tw(box,     {BackgroundColor3=v and C.accentMid or C.checkOff}, FAST):Play()
            tw(bStroke, {Color=v and C.accentDim or C.borderHard},          FAST):Play()
            tw(lbl,     {TextColor3=v and C.textBright or C.textMid},       FAST):Play()
        end

        function obj:SetValue(v)
            v = not not v
            applyState(v)
            -- Sync keypicker addons
            for _, addon in next, self.Addons do
                if addon.Type=="KeyPicker" and addon.SyncToggleState then
                    addon.Toggled = v
                    addon:Update()
                end
            end
            self:_fire(v)
            UpdateDependencyBoxes()
            AttemptSave()
        end

        function obj:Display() applyState(self.Value) end

        -- Risky colour override
        if type(a5)=="boolean" and a5==true and not doColorPicker then
            -- Risky = 5th positional when no color picker
            AddToRegistry(lbl, {TextColor3 = "riskColor"})
            lbl.TextColor3 = C.riskColor
        end

        box.MouseButton1Click:Connect(function() ripple(container); obj:SetValue(not obj.Value) end)
        container.MouseEnter:Connect(function()
            if not obj.Value then tw(lbl,{TextColor3=C.textBright},SNAP):Play() end
            tw(container,{BackgroundColor3=C.bgHover},SNAP):Play()
        end)
        container.MouseLeave:Connect(function()
            if not obj.Value then tw(lbl,{TextColor3=C.textMid},SNAP):Play() end
            tw(container,{BackgroundColor3=C.rowBg},SNAP):Play()
        end)

        if key and winOptions then winOptions[key] = obj end
        if key then Toggles[key] = obj end

        obj.TextLabel = lbl
        obj.Container = container

        self._y = posY+26; return obj, self
    end
    col.AddToggle = col.Checkbox

    -- ── ColorPicker standalone ──
    function col:ColorPicker(key, info)
        -- info: {Default, Transparency, Title, Callback}
        local posY = self._y
        local defColor   = (info and info.Default)      or Color3.fromRGB(200,200,200)
        local defOpacity = (info and info.Transparency) and (1 - info.Transparency) or 1.0
        local title      = (info and info.Title)        or "Color"
        local callback   = (info and info.Callback)     or nil

        local cpOpen = false
        local function containerH() return 22+(cpOpen and (PICKER_H+2) or 0) end

        local container = Instance.new("Frame")
        container.Size = UDim2.new(1,-12,0,22); container.Position = UDim2.new(0,6,0,posY)
        container.BackgroundColor3 = C.rowBg; container.BorderSizePixel = 0
        container.ClipsDescendants = false; container.ZIndex = 3; container.Parent = sf
        corner(container, 2); stroke(container, C.borderSoft, 1, 0.5)
        gradientN(container, {{0,C.rowBgAlt},{0.4,C.rowBg},{1,C.bgDeep}}, 180)
        regItem(container, posY)

        local lbl = Instance.new("TextLabel")
        lbl.Text = title; lbl.Font = FONT_REG; lbl.TextSize = 12
        lbl.TextColor3 = C.textMid; lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.new(1,-30,1,0); lbl.Position = UDim2.new(0,6,0,0)
        lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 4; lbl.Parent = container

        local swatchBtn = Instance.new("TextButton")
        swatchBtn.Size = UDim2.new(0,13,0,13)
        swatchBtn.AnchorPoint = Vector2.new(1,0.5)
        swatchBtn.Position = UDim2.new(1,-6,0.5,0)
        swatchBtn.BackgroundColor3 = defColor
        swatchBtn.BackgroundTransparency = 1-defOpacity
        swatchBtn.BorderSizePixel = 0; swatchBtn.Text = ""
        swatchBtn.AutoButtonColor = false; swatchBtn.ZIndex = 60
        swatchBtn.Parent = container; corner(swatchBtn, 2)
        local swStroke = stroke(swatchBtn, C.borderHard, 1.5, 0)

        local cpObj = newElementObj({Color=defColor, Opacity=defOpacity}, callback)
        cpObj.Type = "ColorPicker"
        cpObj.Value = defColor  -- also expose .Value as Color3 directly for compatibility

        local pickerPanel, _, _, setPickerRaw, ctxMenu = buildColorPicker(container, defColor, defOpacity, function(c, op)
            swatchBtn.BackgroundColor3 = c
            swatchBtn.BackgroundTransparency = 1-math.clamp(op or 1,0,1)
            cpObj.Value = c
            cpObj:_fire(c)
            SafeCallback(callback, c)
            AttemptSave()
        end)
        pickerPanel.Position = UDim2.new(0,0,0,22)

        function cpObj:SetValue(color, opacity)
            if setPickerRaw then setPickerRaw(color, opacity or 1) end
            self.Value = color
            self:_fire(color)
        end
        -- Linoria compat: SetValue({h,s,v}, transparency)
        function cpObj:SetValueHSV(hsv, trans)
            local c = Color3.fromHSV(hsv[1],hsv[2],hsv[3])
            self:SetValue(c, trans and (1-trans) or 1)
        end

        local function closeCP()
            cpOpen = false
            tw(pickerPanel,{Size=UDim2.new(1,0,0,0)},MED):Play()
            tw(swStroke,{Color=C.borderHard},FAST):Play()
            tw(container,{Size=UDim2.new(1,-12,0,containerH())},MED):Play()
            task.delay(0.26, function()
                if not cpOpen then
                    pickerPanel.Visible = false
                    shiftBelow(posY, -(PICKER_H+2), true)
                end
            end)
        end
        local function openCP()
            for frame in next, OpenedFrames do
                if frame.Name=="ColorPicker" then
                    frame.Visible = false
                    OpenedFrames[frame] = nil
                end
            end
            cpOpen = true
            pickerPanel.Name = "ColorPicker"
            pickerPanel.Size = UDim2.new(1,0,0,0); pickerPanel.Visible = true
            OpenedFrames[pickerPanel] = true
            tw(swStroke,{Color=C.accentMid},FAST):Play()
            tw(pickerPanel,{Size=UDim2.new(1,0,0,PICKER_H)},SPRING):Play()
            tw(container,{Size=UDim2.new(1,-12,0,containerH())},MED):Play()
            shiftBelow(posY, PICKER_H+2, true)
        end

        swatchBtn.MouseButton1Click:Connect(function()
            if cpOpen then closeCP() else openCP() end
        end)
        swatchBtn.MouseButton2Click:Connect(function()
            if mouse then ctxMenu.Position = UDim2.fromOffset(mouse.X+4, mouse.Y+4) end
            ctxMenu.Visible = not ctxMenu.Visible
        end)

        if key and winOptions then winOptions[key] = cpObj end
        if key then Options[key] = cpObj end

        self._y = posY+26; return cpObj, self
    end
    col.AddColorPicker = col.ColorPicker

    -- ── Keybind / KeyPicker ──
    function col:Keybind(a1,a2,a3,a4,a5)
        local key, labelText, defaultKey, modes, callback
        if type(a1)=="string" and type(a2)=="string" then
            key,labelText,defaultKey,modes,callback = a1,a2,a3,a4,a5
        else
            key,labelText,defaultKey,modes,callback = nil,a1,a2,a3,a4
        end
        if type(modes)=="function" then callback=modes; modes=nil end

        local posY = self._y
        local row = makeRow(posY, 22)

        local availModes = modes or {"Always","Toggle","Hold"}
        local obj = {
            Value   = defaultKey or "None",
            Toggled = false,
            Mode    = availModes[2] or "Toggle",
            Type    = "KeyPicker",
            Callback = callback,
            SyncToggleState = false,
            Addons = {},
        }
        local _changed = nil
        function obj:OnChanged(fn) _changed=fn; if fn then fn(self.Value) end end
        function obj:GetValue() return self.Value end

        local lbl = Instance.new("TextLabel")
        lbl.Text = tostring(labelText); lbl.Font = FONT_REG; lbl.TextSize = 12; lbl.TextColor3 = C.textMid
        lbl.BackgroundTransparency = 1; lbl.Size = UDim2.new(0.55,0,1,0)
        lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 4; lbl.Parent = row

        local kBtn = Instance.new("TextButton")
        kBtn.Size = UDim2.new(0.4,0,0.72,0); kBtn.Position = UDim2.new(0.57,0,0.14,0)
        kBtn.BackgroundColor3 = C.bgRaised; kBtn.BorderSizePixel = 0
        kBtn.Text = obj.Value; kBtn.Font = FONT_BOLD; kBtn.TextSize = 10
        kBtn.TextColor3 = C.textMid; kBtn.AutoButtonColor = false; kBtn.ZIndex = 4; kBtn.Parent = row; corner(kBtn,2)
        local kS = stroke(kBtn, C.borderHard, 1, 0.1)

        -- Mode select popup
        local modeOuter = Instance.new("Frame")
        modeOuter.BorderColor3 = Color3.new(0,0,0)
        modeOuter.Size = UDim2.new(0,60,0,#availModes*15+2)
        modeOuter.Visible = false; modeOuter.ZIndex = 14; modeOuter.Parent = ScreenGui
        corner(modeOuter, 2)

        local modeInner = Instance.new("Frame")
        modeInner.BackgroundColor3 = C.bgSurface
        modeInner.BorderSizePixel = 0; modeInner.Size = UDim2.fromScale(1,1)
        modeInner.ZIndex = 15; modeInner.Parent = modeOuter
        corner(modeInner, 2); stroke(modeInner, C.borderSoft, 1, 0)

        Instance.new("UIListLayout").Parent = modeInner

        local modeButtons = {}
        for _, mode in next, availModes do
            local mb = {}
            local mLbl = Instance.new("TextButton")
            mLbl.Size = UDim2.new(1,0,0,15)
            mLbl.BackgroundTransparency = 1
            mLbl.Text = mode; mLbl.Font = FONT_REG; mLbl.TextSize = 13
            mLbl.TextColor3 = C.textMid; mLbl.ZIndex = 16; mLbl.Parent = modeInner
            function mb:Select()
                for _, b in next, modeButtons do b:Deselect() end
                obj.Mode = mode
                tw(mLbl,{TextColor3=C.accentMid},SNAP):Play()
                modeOuter.Visible = false
            end
            function mb:Deselect()
                tw(mLbl,{TextColor3=C.textMid},SNAP):Play()
            end
            mLbl.MouseButton1Click:Connect(function() mb:Select(); AttemptSave() end)
            if mode == obj.Mode then mb:Select() end
            modeButtons[mode] = mb
        end

        -- Container label in keybind HUD
        local containerLabel = Instance.new("TextLabel")
        containerLabel.Size = UDim2.new(1,0,0,18)
        containerLabel.Font = FONT_REG; containerLabel.TextSize = 13
        containerLabel.TextColor3 = C.textMid; containerLabel.BackgroundTransparency = 1
        containerLabel.TextXAlignment = Enum.TextXAlignment.Left
        containerLabel.Visible = false; containerLabel.ZIndex = 110
        containerLabel.Parent = KeybindContainer

        function obj:Update()
            local state = self:GetState()
            containerLabel.Text = string.format("[%s] %s (%s)", self.Value, labelText, self.Mode)
            containerLabel.Visible = true
            tw(containerLabel, {TextColor3 = state and C.accentMid or C.textMid}, SNAP):Play()

            local ySize, xSize = 0, 0
            for _, ch in next, KeybindContainer:GetChildren() do
                if ch:IsA("TextLabel") and ch.Visible then
                    ySize = ySize + 18
                    if ch.TextBounds.X > xSize then xSize = ch.TextBounds.X end
                end
            end
            KeybindFrame.Size = UDim2.new(0, math.max(xSize+10,210), 0, ySize+23)
            KeybindFrame.Visible = ySize > 0
        end

        function obj:GetState()
            if self.Mode=="Always" then return true
            elseif self.Mode=="Hold" then
                if self.Value=="None" then return false end
                if self.Value=="MB1" then return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
                elseif self.Value=="MB2" then return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
                else return UIS:IsKeyDown(Enum.KeyCode[self.Value]) end
            else
                return self.Toggled
            end
        end

        function obj:DoClick()
            SafeCallback(self.Callback, self.Toggled)
        end

        function obj:SetValue(data)
            local k, m = data[1], data[2]
            kBtn.Text = k; self.Value = k
            if modeButtons[m] then modeButtons[m]:Select() end
            self:Update()
        end

        -- Position mode popup near button
        local function updateModePos()
            modeOuter.Position = UDim2.fromOffset(
                row.AbsolutePosition.X + row.AbsoluteSize.X + 4,
                row.AbsolutePosition.Y + 1
            )
        end
        row:GetPropertyChangedSignal("AbsolutePosition"):Connect(updateModePos)
        task.spawn(updateModePos)

        -- Picking
        local picking = false
        kBtn.MouseButton1Click:Connect(function()
            if picking then return end
            picking = true; kBtn.Text = "..."
            tw(kBtn,{BackgroundColor3=C.bgHover},SNAP):Play()
            tw(kS,{Color=C.accentDim},SNAP):Play()
            local conn; conn = UIS.InputBegan:Connect(function(inp, gp)
                if gp then return end
                local k
                if inp.UserInputType==Enum.UserInputType.Keyboard then k=inp.KeyCode.Name
                elseif inp.UserInputType==Enum.UserInputType.MouseButton1 then k="MB1"
                elseif inp.UserInputType==Enum.UserInputType.MouseButton2 then k="MB2" end
                if k then
                    conn:Disconnect(); picking=false
                    kBtn.Text=k; obj.Value=k
                    tw(kS,{Color=C.borderHard},FAST):Play()
                    tw(kBtn,{BackgroundColor3=C.bgRaised},FAST):Play()
                    SafeCallback(obj.ChangedCallback, inp.KeyCode or inp.UserInputType)
                    if _changed then SafeCallback(_changed, inp.KeyCode or inp.UserInputType) end
                    obj:Update(); AttemptSave()
                end
            end)
        end)
        kBtn.MouseButton2Click:Connect(function()
            modeOuter.Visible = not modeOuter.Visible
        end)
        kBtn.MouseEnter:Connect(function() if not picking then tw(kBtn,{BackgroundColor3=C.bgHover},SNAP):Play() end end)
        kBtn.MouseLeave:Connect(function() if not picking then tw(kBtn,{BackgroundColor3=C.bgRaised},SNAP):Play() end end)
        row.MouseEnter:Connect(function() tw(row,{BackgroundColor3=C.bgHover},SNAP):Play() end)
        row.MouseLeave:Connect(function() tw(row,{BackgroundColor3=C.rowBg},SNAP):Play() end)

        -- Global input handling (toggle/hold)
        table.insert(Signals, UIS.InputBegan:Connect(function(inp, gp)
            if gp or picking then return end
            if obj.Mode=="Toggle" then
                local k = obj.Value
                if (k=="MB1" and inp.UserInputType==Enum.UserInputType.MouseButton1)
                or (k=="MB2" and inp.UserInputType==Enum.UserInputType.MouseButton2)
                or (inp.UserInputType==Enum.UserInputType.Keyboard and inp.KeyCode.Name==k) then
                    obj.Toggled = not obj.Toggled
                    obj:DoClick(); obj:Update()
                end
            end
            -- Close mode popup on outside click
            if inp.UserInputType==Enum.UserInputType.MouseButton1 then
                local ap,as = modeOuter.AbsolutePosition, modeOuter.AbsoluteSize
                if mouse and (mouse.X<ap.X or mouse.X>ap.X+as.X or mouse.Y<(ap.Y-20-1) or mouse.Y>ap.Y+as.Y) then
                    modeOuter.Visible = false
                end
            end
        end))
        table.insert(Signals, UIS.InputEnded:Connect(function(inp)
            if not picking then obj:Update() end
        end))

        obj:Update()
        if key and winOptions then winOptions[key] = obj end
        if key then Options[key] = obj end

        self._y = posY+26; return obj, self
    end
    col.AddKeyPicker = col.Keybind

    -- ── Slider ──
    function col:Slider(a1,a2,a3,a4,a5,a6,a7,a8)
        local key, labelText, minVal, maxVal, default, rounding, suffix, callback
        if type(a1)=="string" and type(a2)=="string" then
            key,labelText,minVal,maxVal,default,rounding,suffix,callback = a1,a2,a3,a4,a5,a6,a7,a8
        else
            key,labelText,minVal,maxVal,default,rounding,suffix,callback = nil,a1,a2,a3,a4,a5,a6,a7
        end
        if type(suffix)=="function" then callback=suffix; suffix=nil end

        local posY = self._y
        local row = makeRow(posY, 22)

        local obj = newElementObj(default, callback)
        obj.Type = "Slider"
        obj.Min = minVal; obj.Max = maxVal; obj.Rounding = rounding or 0

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

        local pct = (default-minVal)/math.max(maxVal-minVal,1)
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(pct,0,1,0); fill.BackgroundColor3 = C.sliderFill
        fill.BorderSizePixel = 0; fill.ZIndex = 5; fill.Parent = track; corner(fill,2)
        gradient(fill, Color3.fromRGB(100,100,100), Color3.fromRGB(220,220,220), 0)

        local knob = Instance.new("TextButton")
        knob.Size = UDim2.new(0,11,0,11); knob.Position = UDim2.new(pct,-5,0.5,-5)
        knob.BackgroundColor3 = C.knob; knob.BorderSizePixel = 0
        knob.Text = ""; knob.AutoButtonColor = false; knob.ZIndex = 6; knob.Parent = track; corner(knob,6)
        stroke(knob, C.borderHard, 1.5, 0)

        local suf = suffix or ""
        local function roundVal(v)
            if (rounding or 0)==0 then return math.floor(v+0.5) end
            return tonumber(string.format("%."..rounding.."f", v))
        end

        local function applyValue(v)
            v = math.clamp(v, minVal, maxVal)
            v = roundVal(v)
            local p = (v-minVal)/math.max(maxVal-minVal,1)
            tw(fill,{Size=UDim2.new(p,0,1,0)},SNAP):Play()
            tw(knob,{Position=UDim2.new(p,-5,0.5,-5)},SNAP):Play()
            valLbl.Text = tostring(v)..suf
            obj:_fire(v)
            AttemptSave()
        end

        function obj:SetValue(v) applyValue(v) end
        function obj:Display() applyValue(self.Value) end

        local drag = false
        knob.MouseButton1Down:Connect(function() drag=true end)
        table.insert(Signals, UIS.InputEnded:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1 then drag=false
                tw(knob,{Size=UDim2.new(0,11,0,11)},SNAP):Play()
            end
        end))
        table.insert(Signals, UIS.InputChanged:Connect(function(inp)
            if drag and inp.UserInputType==Enum.UserInputType.MouseMovement then
                tw(knob,{Size=UDim2.new(0,13,0,13)},SNAP):Play()
                local p = math.clamp((inp.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X, 0,1)
                applyValue(minVal+(maxVal-minVal)*p)
            end
        end))
        row.MouseEnter:Connect(function() tw(row,{BackgroundColor3=C.bgHover},SNAP):Play() end)
        row.MouseLeave:Connect(function() tw(row,{BackgroundColor3=C.rowBg},SNAP):Play() end)

        if key and winOptions then winOptions[key] = obj end
        if key then Options[key] = obj end

        self._y = posY+26; return obj, self
    end
    col.AddSlider = col.Slider

    -- ── Input (textbox) ──
    function col:Input(a1,a2,a3,a4)
        -- signature: ([key,] labelText, info_table_or_placeholder, callback)
        local key, labelText, info, callback
        if type(a1)=="string" and type(a2)=="string" then
            key,labelText,info,callback = a1,a2,a3,a4
        else
            key,labelText,info,callback = nil,a1,a2,a3
        end
        if type(info)=="function" then callback=info; info={} end
        info = info or {}

        local posY = self._y

        local topLbl = Instance.new("TextLabel")
        topLbl.Size = UDim2.new(1,-12,0,14)
        topLbl.Position = UDim2.new(0,6,0,posY)
        topLbl.Text = tostring(labelText)
        topLbl.Font = FONT_REG; topLbl.TextSize = 12; topLbl.TextColor3 = C.textSub
        topLbl.BackgroundTransparency = 1; topLbl.TextXAlignment = Enum.TextXAlignment.Left
        topLbl.ZIndex = 3; topLbl.Parent = sf
        regItem(topLbl, posY)

        local boxY = posY+16
        local boxOuter = Instance.new("Frame")
        boxOuter.Size = UDim2.new(1,-12,0,22); boxOuter.Position = UDim2.new(0,6,0,boxY)
        boxOuter.BackgroundColor3 = C.bgDeep; boxOuter.BorderSizePixel = 0; boxOuter.ZIndex = 3; boxOuter.Parent = sf
        corner(boxOuter, 2); stroke(boxOuter, C.borderSoft, 1, 0.4)
        gradientN(boxOuter, {{0,C.bgRaised},{1,C.bgDeep}}, 180)
        regItem(boxOuter, boxY)

        local clipper = Instance.new("Frame")
        clipper.BackgroundTransparency = 1; clipper.ClipsDescendants = true
        clipper.Position = UDim2.new(0,5,0,0); clipper.Size = UDim2.new(1,-5,1,0)
        clipper.ZIndex = 4; clipper.Parent = boxOuter

        local box = Instance.new("TextBox")
        box.BackgroundTransparency = 1
        box.Position = UDim2.fromOffset(0,0)
        box.Size = UDim2.fromScale(5,1)
        box.Font = FONT_REG
        box.PlaceholderText = info.Placeholder or ""
        box.PlaceholderColor3 = C.textDim
        box.Text = info.Default or ""
        box.TextColor3 = C.textBright
        box.TextSize = 13
        box.TextXAlignment = Enum.TextXAlignment.Left
        box.ZIndex = 5; box.Parent = clipper

        local obj = newElementObj(info.Default or "", callback)
        obj.Type = "Input"
        obj.Numeric  = info.Numeric  or false
        obj.Finished = info.Finished or false

        local function applyText(t)
            if info.MaxLength and #t > info.MaxLength then t = t:sub(1, info.MaxLength) end
            if obj.Numeric then
                if not tonumber(t) and #t > 0 then t = obj.Value end
            end
            obj.Value = t; box.Text = t
            obj:_fire(t); AttemptSave()
        end

        function obj:SetValue(t) applyText(t) end
        function obj:Display() box.Text = self.Value end

        if obj.Finished then
            box.FocusLost:Connect(function(enter) if enter then applyText(box.Text) end end)
        else
            box:GetPropertyChangedSignal("Text"):Connect(function() applyText(box.Text) end)
        end

        -- Cursor-following scroll
        local function scrollUpdate()
            local PADDING = 2
            local reveal = clipper.AbsoluteSize.X
            if not box:IsFocused() or box.TextBounds.X <= reveal-2*PADDING then
                box.Position = UDim2.new(0,PADDING,0,0)
            else
                local cur = box.CursorPosition
                if cur ~= -1 then
                    local sub = string.sub(box.Text, 1, cur-1)
                    local w = TextService:GetTextSize(sub, box.TextSize, box.Font, Vector2.new(math.huge,math.huge)).X
                    local curPos = box.Position.X.Offset + w
                    if curPos < PADDING then
                        box.Position = UDim2.fromOffset(PADDING-w, 0)
                    elseif curPos > reveal-PADDING-1 then
                        box.Position = UDim2.fromOffset(reveal-w-PADDING-1, 0)
                    end
                end
            end
        end
        task.spawn(scrollUpdate)
        box:GetPropertyChangedSignal("Text"):Connect(scrollUpdate)
        box:GetPropertyChangedSignal("CursorPosition"):Connect(scrollUpdate)
        box.FocusLost:Connect(scrollUpdate); box.Focused:Connect(scrollUpdate)

        boxOuter.MouseEnter:Connect(function() tw(boxOuter,{BackgroundColor3=C.bgHover},SNAP):Play(); stroke(boxOuter, C.accentDim, 1, 0) end)
        boxOuter.MouseLeave:Connect(function() tw(boxOuter,{BackgroundColor3=C.bgDeep},SNAP):Play() end)

        if info.Tooltip then AddToolTip(info.Tooltip, boxOuter, mouse) end

        if key and winOptions then winOptions[key] = obj end
        if key then Options[key] = obj end

        self._y = posY+42; return obj, self
    end
    col.AddInput = col.Input

    -- ── Dropdown ──
    function col:Dropdown(a1,a2,a3,a4,a5,a6,a7,a8,a9)
        local key, labelText, opts, default, callback, doColorPicker, defColor, defOpacity, colorCb
            = normaliseDropArgs(a1,a2,a3,a4,a5,a6,a7,a8,a9)

        -- SpecialType support
        if type(opts)=="string" then
            if opts=="Player" then opts=GetPlayersString(); default=nil
            elseif opts=="Team" then opts=GetTeamsString(); default=nil end
        end

        local isMulti   = type(default)=="table"
        local allowNull = default==nil
        local selVal    = isMulti and {} or nil

        if not isMulti and not allowNull and default then
            selVal = default
        end

        local posY = self._y
        local COUNT = #opts; local LIST_H = COUNT * ITEM_H
        local ddOpen = false; local cpOpen = false
        local function containerH() return 22+(ddOpen and LIST_H or 0)+(cpOpen and (PICKER_H+2) or 0) end

        local container = Instance.new("Frame")
        container.Size = UDim2.new(1,-12,0,22); container.Position = UDim2.new(0,6,0,posY)
        container.BackgroundColor3 = C.rowBg; container.ClipsDescendants = false
        container.ZIndex = 3; container.Parent = sf
        corner(container, 2); stroke(container, C.borderSoft, 1, 0.5)
        gradientN(container, {{0,C.rowBgAlt},{0.4,C.rowBg},{1,C.bgDeep}}, 180)
        regItem(container, posY)

        local SWATCH_W = doColorPicker and 18 or 0
        local obj = newElementObj(selVal, callback)
        obj.Type   = "Dropdown"
        obj.Values = opts
        obj.Multi  = isMulti

        if labelText and labelText ~= "" then
            local ll = Instance.new("TextLabel")
            ll.Text = tostring(labelText); ll.Font = FONT_REG; ll.TextSize = 12
            ll.TextColor3 = C.textMid; ll.BackgroundTransparency = 1
            ll.Size = UDim2.new(0.44,-SWATCH_W,0,22)
            ll.TextXAlignment = Enum.TextXAlignment.Left; ll.ZIndex = 4; ll.Parent = container
        end

        local swatchBtn, swatchStroke, cpObj2, setPickerRaw2
        if doColorPicker then
            defColor = defColor or Color3.fromRGB(200,200,200); defOpacity = defOpacity or 1.0
            swatchBtn = Instance.new("TextButton")
            swatchBtn.Size = UDim2.new(0,13,0,13)
            swatchBtn.AnchorPoint = Vector2.new(1,0.5)
            swatchBtn.Position = UDim2.new(1,-12,0.5,0)
            swatchBtn.BackgroundColor3 = defColor
            swatchBtn.BackgroundTransparency = 1-math.clamp(defOpacity,0,1)
            swatchBtn.BorderSizePixel = 0; swatchBtn.Text = ""; swatchBtn.AutoButtonColor = false
            swatchBtn.ZIndex = 60; swatchBtn.Parent = container; corner(swatchBtn, 2)
            swatchStroke = stroke(swatchBtn, C.borderHard, 1.5, 0)
            local swBg = Instance.new("ImageLabel")
            swBg.Size = UDim2.fromScale(1,1)
            swBg.Image = "http://www.roblox.com/asset/?id=14204231522"
            swBg.ImageTransparency = 0.45; swBg.ScaleType = Enum.ScaleType.Tile
            swBg.TileSize = UDim2.fromOffset(6,6); swBg.BackgroundTransparency = 1
            swBg.BorderSizePixel = 0; swBg.ZIndex = 59; swBg.Parent = swatchBtn
        end

        local hasLabel = labelText and labelText ~= ""
        local btnX = hasLabel and 0.45 or 0
        local btnW = hasLabel and 0.54 or 1
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(btnW,0,0,22); btn.Position = UDim2.new(btnX,0,0,0)
        btn.BackgroundColor3 = C.dropBg; btn.BorderSizePixel = 0
        btn.Text = ""; btn.AutoButtonColor = false; btn.ZIndex = 6; btn.Parent = container
        corner(btn, 2); local btnStroke = stroke(btn, C.borderSoft, 1)
        gradient(btn, Color3.fromRGB(18,18,18), Color3.fromRGB(8,8,8), 180)

        local function getDisplayText()
            if isMulti then
                local parts = {}
                for v in next, obj.Value do table.insert(parts, v) end
                return #parts>0 and table.concat(parts, ", ") or "--"
            end
            return obj.Value or "--"
        end

        local selLbl = Instance.new("TextLabel")
        selLbl.Text = getDisplayText(); selLbl.Font = FONT_REG; selLbl.TextSize = 11
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

        local pickerPanel2, ctxMenu2
        local function pickerY() return 22+(ddOpen and LIST_H or 0) end
        local function updatePickerPos() if pickerPanel2 then pickerPanel2.Position=UDim2.new(0,0,0,pickerY()) end end

        if doColorPicker then
            pickerPanel2, _, _, setPickerRaw2, ctxMenu2 = buildColorPicker(container, defColor, defOpacity, function(c,op)
                if swatchBtn then
                    swatchBtn.BackgroundColor3 = c
                    swatchBtn.BackgroundTransparency = 1-math.clamp(op or 1,0,1)
                end
                if cpObj2 then cpObj2:_fire({Color=c,Opacity=op}) end
                SafeCallback(colorCb, c, op)
            end)
            pickerPanel2.Position = UDim2.new(0,0,0,pickerY())
            cpObj2 = newElementObj({Color=defColor,Opacity=defOpacity}, colorCb)
            function cpObj2:SetValue(color, opacity)
                if setPickerRaw2 then setPickerRaw2(color, opacity or 1) end
                self:_fire({Color=color,Opacity=opacity or 1})
            end
            if key and winOptions then winOptions[key.."_Color"] = cpObj2 end
        end

        local function closeDD()
            ddOpen = false; openDD.fn = nil
            tw(arrow,    {Rotation=0, TextColor3=C.textDim}, MED):Play()
            tw(listFrame,{Size=UDim2.new(btnW,0,0,0)}, MED):Play()
            tw(btn,      {BackgroundColor3=C.dropBg},    FAST):Play()
            tw(btnStroke,{Color=C.borderSoft},           FAST):Play()
            tw(selLbl,   {TextColor3=C.textMid},         FAST):Play()
            tw(container,{Size=UDim2.new(1,-12,0,containerH())}, MED):Play()
            task.delay(0.26, function() if not ddOpen then listFrame.Visible=false end end)
            shiftBelow(posY, -LIST_H, true); updatePickerPos()
        end
        local function openDDFn()
            if openDD.fn then openDD.fn() end
            ddOpen = true; openDD.fn = closeDD
            listFrame.Visible = true; listFrame.Size = UDim2.new(btnW,0,0,0)
            tw(arrow,    {Rotation=180, TextColor3=C.textBright}, SPRING):Play()
            tw(listFrame,{Size=UDim2.new(btnW,0,0,LIST_H)},       SPRING):Play()
            tw(btn,      {BackgroundColor3=Color3.fromRGB(20,20,20)}, FAST):Play()
            tw(btnStroke,{Color=C.borderHard},  FAST):Play()
            tw(selLbl,   {TextColor3=C.textBright}, FAST):Play()
            tw(container,{Size=UDim2.new(1,-12,0,containerH())}, MED):Play()
            shiftBelow(posY, LIST_H, true); updatePickerPos()
        end

        -- Build option list
        local optHighlights = {}
        for i, optText in ipairs(opts) do
            local isSelected = isMulti and (obj.Value[optText]==true) or (optText==selVal)
            local optBtn = Instance.new("TextButton")
            optBtn.Size = UDim2.new(1,0,0,ITEM_H); optBtn.Position = UDim2.new(0,0,0,(i-1)*ITEM_H)
            optBtn.BackgroundColor3 = isSelected and C.dropItemSel or C.dropItem
            optBtn.BackgroundTransparency = isSelected and 0 or 1
            optBtn.BorderSizePixel = 0; optBtn.Text = ""; optBtn.AutoButtonColor = false
            optBtn.ZIndex = 21; optBtn.Parent = listFrame

            local selBar = Instance.new("Frame")
            selBar.Size = UDim2.new(0,2,0.55,0); selBar.Position = UDim2.new(0,2,0.22,0)
            selBar.BackgroundColor3 = C.accentMid; selBar.BorderSizePixel = 0
            selBar.Visible = isSelected; selBar.ZIndex = 22; selBar.Parent = optBtn; corner(selBar,1)

            local optLbl = Instance.new("TextLabel")
            optLbl.Text = optText; optLbl.Font = FONT_REG; optLbl.TextSize = 11
            optLbl.TextColor3 = isSelected and C.textBright or C.textMid
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
                local sel = isMulti and obj.Value[optText] or (obj.Value==optText)
                if not sel then
                    tw(optBtn,{BackgroundColor3=C.bgHover,BackgroundTransparency=0},SNAP):Play()
                    tw(optLbl,{TextColor3=C.textBright},SNAP):Play()
                end
            end)
            optBtn.MouseLeave:Connect(function()
                local sel = isMulti and obj.Value[optText] or (obj.Value==optText)
                if not sel then
                    tw(optBtn,{BackgroundTransparency=1},SNAP):Play()
                    tw(optLbl,{TextColor3=C.textMid},SNAP):Play()
                end
            end)
            optBtn.MouseButton1Click:Connect(function()
                if isMulti then
                    local cur = obj.Value[optText]
                    obj.Value[optText] = cur and nil or true
                    local sel2 = not cur
                    selBar.Visible = sel2
                    tw(optLbl,{TextColor3=sel2 and C.textBright or C.textMid},SNAP):Play()
                    tw(optBtn,{BackgroundTransparency=sel2 and 0 or 1},SNAP):Play()
                    selLbl.Text = getDisplayText()
                    obj:_fire(obj.Value); AttemptSave()
                else
                    for j, h in ipairs(optHighlights) do
                        tw(h.btn,{BackgroundTransparency=1},SNAP):Play()
                        tw(h.lbl,{TextColor3=(j==i) and C.textBright or C.textMid},SNAP):Play()
                        h.bar.Visible = (j==i)
                    end
                    tw(optBtn,{BackgroundColor3=C.dropItemSel,BackgroundTransparency=0},SNAP):Play()
                    if not allowNull or obj.Value~=optText then
                        obj.Value = optText
                    else
                        obj.Value = nil
                    end
                    selLbl.Text = getDisplayText()
                    if not isMulti then closeDD() end
                    obj:_fire(obj.Value); AttemptSave()
                end
            end)
        end

        function obj:SetValue(v)
            if isMulti then
                local nt = {}
                for val in next, (type(v)=="table" and v or {}) do
                    if table.find(opts, val) then nt[val]=true end
                end
                obj.Value = nt
            else
                if v==nil then obj.Value=nil
                elseif table.find(opts, v) then obj.Value=v end
            end
            -- Rebuild highlights
            for i, h in ipairs(optHighlights) do
                local sel = isMulti and (obj.Value[opts[i]]==true) or (obj.Value==opts[i])
                h.bar.Visible = sel
                tw(h.lbl,{TextColor3=sel and C.textBright or C.textMid},SNAP):Play()
                tw(h.btn,{BackgroundTransparency=sel and 0 or 1},SNAP):Play()
            end
            selLbl.Text = getDisplayText()
            obj:_fire(obj.Value)
        end

        function obj:SetValues(newOpts)
            obj.Values = newOpts
            -- Rebuild list (simplified — remove children and re-add)
            for _, ch in next, listFrame:GetChildren() do ch:Destroy() end
            opts = newOpts; optHighlights = {}
            -- Rebuild
            local newCount = #opts; LIST_H = newCount*ITEM_H
            listFrame.Size = UDim2.new(btnW,0,0,ddOpen and LIST_H or 0)
            for i2, oText in ipairs(opts) do
                local ob2 = Instance.new("TextButton")
                ob2.Size = UDim2.new(1,0,0,ITEM_H); ob2.Position = UDim2.new(0,0,0,(i2-1)*ITEM_H)
                ob2.BackgroundTransparency = 1; ob2.BorderSizePixel = 0; ob2.Text=""
                ob2.AutoButtonColor = false; ob2.ZIndex = 21; ob2.Parent = listFrame
                local ob2Lbl = Instance.new("TextLabel")
                ob2Lbl.Text = oText; ob2Lbl.Font = FONT_REG; ob2Lbl.TextSize = 11
                ob2Lbl.TextColor3 = C.textMid; ob2Lbl.BackgroundTransparency = 1
                ob2Lbl.Size = UDim2.new(1,-14,1,0); ob2Lbl.Position = UDim2.new(0,12,0,0)
                ob2Lbl.TextXAlignment = Enum.TextXAlignment.Left; ob2Lbl.ZIndex = 22; ob2Lbl.Parent = ob2
                local ob2Bar = Instance.new("Frame")
                ob2Bar.Size = UDim2.new(0,2,0.55,0); ob2Bar.Position = UDim2.new(0,2,0.22,0)
                ob2Bar.BackgroundColor3 = C.accentMid; ob2Bar.BorderSizePixel = 0
                ob2Bar.Visible = false; ob2Bar.ZIndex = 22; ob2Bar.Parent = ob2; corner(ob2Bar,1)
                optHighlights[i2] = {btn=ob2,lbl=ob2Lbl,bar=ob2Bar}
                ob2.MouseButton1Click:Connect(function()
                    for j2,h2 in ipairs(optHighlights) do
                        h2.bar.Visible=(j2==i2)
                        tw(h2.lbl,{TextColor3=(j2==i2) and C.textBright or C.textMid},SNAP):Play()
                        tw(h2.btn,{BackgroundTransparency=(j2==i2) and 0 or 1},SNAP):Play()
                    end
                    tw(ob2,{BackgroundColor3=C.dropItemSel,BackgroundTransparency=0},SNAP):Play()
                    obj.Value = oText; selLbl.Text=oText; closeDD()
                    obj:_fire(obj.Value); AttemptSave()
                end)
                ob2.MouseEnter:Connect(function()
                    if obj.Value~=oText then tw(ob2,{BackgroundColor3=C.bgHover,BackgroundTransparency=0},SNAP):Play(); tw(ob2Lbl,{TextColor3=C.textBright},SNAP):Play() end
                end)
                ob2.MouseLeave:Connect(function()
                    if obj.Value~=oText then tw(ob2,{BackgroundTransparency=1},SNAP):Play(); tw(ob2Lbl,{TextColor3=C.textMid},SNAP):Play() end
                end)
            end
        end

        -- Color picker for dropdown
        if doColorPicker then
            local function closeCP2()
                cpOpen=false
                tw(pickerPanel2,{Size=UDim2.new(1,0,0,0)},MED):Play()
                tw(swatchStroke,{Color=C.borderHard},FAST):Play()
                tw(container,{Size=UDim2.new(1,-12,0,containerH())},MED):Play()
                task.delay(0.26, function()
                    if not cpOpen then pickerPanel2.Visible=false; shiftBelow(posY,-(PICKER_H+2),true) end
                end)
            end
            local function openCP2()
                cpOpen=true; updatePickerPos()
                pickerPanel2.Size=UDim2.new(1,0,0,0); pickerPanel2.Visible=true
                tw(swatchStroke,{Color=C.accentMid},FAST):Play()
                tw(pickerPanel2,{Size=UDim2.new(1,0,0,PICKER_H)},SPRING):Play()
                tw(container,{Size=UDim2.new(1,-12,0,containerH())},MED):Play()
                shiftBelow(posY, PICKER_H+2, true)
            end
            swatchBtn.MouseButton1Click:Connect(function() if cpOpen then closeCP2() else openCP2() end end)
            swatchBtn.MouseButton2Click:Connect(function()
                if mouse and ctxMenu2 then ctxMenu2.Position=UDim2.fromOffset(mouse.X+4,mouse.Y+4) end
                if ctxMenu2 then ctxMenu2.Visible=not ctxMenu2.Visible end
            end)
        end

        btn.MouseButton1Click:Connect(function()
            ripple(container)
            if ddOpen then closeDD() else openDDFn() end
        end)
        btn.MouseEnter:Connect(function()
            if not ddOpen then tw(btn,{BackgroundColor3=Color3.fromRGB(18,18,18)},SNAP):Play(); tw(btnStroke,{Color=C.borderHard},SNAP):Play() end
        end)
        btn.MouseLeave:Connect(function()
            if not ddOpen then tw(btn,{BackgroundColor3=C.dropBg},SNAP):Play(); tw(btnStroke,{Color=C.borderSoft},SNAP):Play() end
        end)

        -- Close on outside click
        table.insert(Signals, UIS.InputBegan:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1 and ddOpen then
                local ap,as = listFrame.AbsolutePosition, listFrame.AbsoluteSize
                if mouse and (mouse.X<ap.X or mouse.X>ap.X+as.X or mouse.Y<(ap.Y-22) or mouse.Y>ap.Y+as.Y) then
                    closeDD()
                end
            end
        end))

        if key and winOptions then winOptions[key] = obj end
        if key then Options[key] = obj end

        self._y = posY+26; return obj, self
    end
    col.AddDropdown = col.Dropdown

    -- ── Paired Checkbox ──
    function col:PairedCheckbox(a1,a2,a3,a4,a5,a6,a7,a8)
        local keyL,keyR,lL,dL,lR,dR,cbL,cbR = normalisePaired(a1,a2,a3,a4,a5,a6,a7,a8)
        local posY = self._y; local row = makeRow(posY, 22)
        local objL = newElementObj(dL or false, cbL)
        local objR = newElementObj(dR or false, cbR)
        objL.Type = "Toggle"; objR.Type = "Toggle"

        local function makeMini(text, xScale, obj2)
            local box2 = Instance.new("TextButton")
            box2.Size = UDim2.new(0,12,0,12); box2.Position = UDim2.new(xScale,3,0.5,-6)
            box2.BackgroundColor3 = obj2.Value and C.accentMid or C.checkOff
            box2.BorderSizePixel = 0; box2.Text = ""; box2.AutoButtonColor = false
            box2.ZIndex = 4; box2.Parent = row; corner(box2, 2)
            local bS2 = stroke(box2, obj2.Value and C.accentDim or C.borderHard, 1)
            local tick2 = Instance.new("TextLabel")
            tick2.Text="✓"; tick2.Font=FONT_BOLD; tick2.TextSize=8; tick2.TextColor3=C.bgDeep
            tick2.BackgroundTransparency=1; tick2.Size=UDim2.fromScale(1,1)
            tick2.TextXAlignment=Enum.TextXAlignment.Center; tick2.TextYAlignment=Enum.TextYAlignment.Center
            tick2.Visible=obj2.Value; tick2.ZIndex=5; tick2.Parent=box2
            local ml2 = Instance.new("TextLabel")
            ml2.Text=tostring(text); ml2.Font=FONT_REG; ml2.TextSize=11
            ml2.TextColor3=obj2.Value and C.textBright or C.textMid
            ml2.BackgroundTransparency=1
            ml2.Size=UDim2.new(0.44,0,1,0); ml2.Position=UDim2.new(xScale+0.04,0,0,0)
            ml2.TextXAlignment=Enum.TextXAlignment.Left; ml2.ZIndex=4; ml2.Parent=row
            function obj2:SetValue(v)
                v=not not v; tick2.Visible=v
                tw(box2,{BackgroundColor3=v and C.accentMid or C.checkOff},FAST):Play()
                tw(bS2, {Color=v and C.accentDim or C.borderHard},FAST):Play()
                tw(ml2, {TextColor3=v and C.textBright or C.textMid},FAST):Play()
                self:_fire(v); AttemptSave(); UpdateDependencyBoxes()
            end
            box2.MouseButton1Click:Connect(function() ripple(row); obj2:SetValue(not obj2.Value) end)
        end
        makeMini(lL, 0, objL); makeMini(lR, 0.5, objR)
        row.MouseEnter:Connect(function() tw(row,{BackgroundColor3=C.bgHover},SNAP):Play() end)
        row.MouseLeave:Connect(function() tw(row,{BackgroundColor3=C.rowBg},SNAP):Play() end)
        if keyL and winOptions then winOptions[keyL]=objL; Toggles[keyL]=objL end
        if keyR and winOptions then winOptions[keyR]=objR; Toggles[keyR]=objR end
        self._y = posY+24; return objL, objR, self
    end

    -- ── Expandable Checkbox ──
    function col:ExpandableCheckbox(a1,a2,a3,a4,a5)
        local key, labelText, default, callback, subBuilder
        if type(a1)=="string" and type(a2)=="string" then
            key,labelText,default,callback,subBuilder=a1,a2,a3,a4,a5
        else
            key,labelText,default,callback,subBuilder=nil,a1,a2,a3,a4
        end

        local posY = self._y; local row = makeRow(posY, 22)
        local obj = newElementObj(default or false, callback)
        obj.Type = "Toggle"

        local box3 = Instance.new("TextButton")
        box3.Size=UDim2.new(0,13,0,13); box3.Position=UDim2.new(0,4,0.5,-6)
        box3.BackgroundColor3=obj.Value and C.accentMid or C.checkOff
        box3.BorderSizePixel=0; box3.Text=""; box3.AutoButtonColor=false
        box3.ZIndex=4; box3.Parent=row; corner(box3,2)
        local bS3 = stroke(box3, obj.Value and C.accentDim or C.borderHard, 1)
        local tick3 = Instance.new("TextLabel")
        tick3.Text="✓"; tick3.Font=FONT_BOLD; tick3.TextSize=9; tick3.TextColor3=C.bgDeep
        tick3.BackgroundTransparency=1; tick3.Size=UDim2.fromScale(1,1)
        tick3.TextXAlignment=Enum.TextXAlignment.Center; tick3.TextYAlignment=Enum.TextYAlignment.Center
        tick3.Visible=obj.Value; tick3.ZIndex=5; tick3.Parent=box3
        local lbl3 = Instance.new("TextLabel")
        lbl3.Text=tostring(labelText); lbl3.Font=FONT_REG; lbl3.TextSize=12
        lbl3.TextColor3=obj.Value and C.textBright or C.textMid
        lbl3.BackgroundTransparency=1
        lbl3.Size=UDim2.new(1,-36,1,0); lbl3.Position=UDim2.new(0,22,0,0)
        lbl3.TextXAlignment=Enum.TextXAlignment.Left; lbl3.ZIndex=4; lbl3.Parent=row
        local expArrow = Instance.new("TextLabel")
        expArrow.Text="▾"; expArrow.Font=FONT_BOLD; expArrow.TextSize=10
        expArrow.TextColor3=C.textDim; expArrow.BackgroundTransparency=1
        expArrow.Size=UDim2.new(0,16,1,0); expArrow.Position=UDim2.new(1,-18,0,0)
        expArrow.TextXAlignment=Enum.TextXAlignment.Center; expArrow.ZIndex=4; expArrow.Parent=row

        local subPanel = Instance.new("Frame")
        subPanel.Size=UDim2.new(1,-12,0,0); subPanel.Position=UDim2.new(0,6,0,posY+26)
        subPanel.BackgroundColor3=Color3.fromRGB(8,8,8); subPanel.BorderSizePixel=0
        subPanel.ClipsDescendants=true; subPanel.Visible=false; subPanel.ZIndex=3; subPanel.Parent=sf
        corner(subPanel,2); stroke(subPanel, C.borderFaint, 1, 0.4); regItem(subPanel, posY+26)

        local subSF = Instance.new("ScrollingFrame")
        subSF.Size=UDim2.fromScale(1,1); subSF.BackgroundTransparency=1
        subSF.BorderSizePixel=0; subSF.ScrollBarThickness=2
        subSF.ScrollBarImageColor3=C.accentDim; subSF.CanvasSize=UDim2.new(0,0,0,2000)
        subSF.ZIndex=2; subSF.Parent=subPanel

        local subReg={}; local subColObj=makeColumnObj(subSF,subReg,openDD,winOptions,mouse)
        if subBuilder then subBuilder(subColObj) end; subColObj:Finalise()
        local subH = math.min(subColObj._y+8, 220)
        subSF.CanvasSize = UDim2.new(0,0,0,subColObj._y+8)

        local expanded=false
        local function openSub()
            expanded=true; subPanel.Visible=true; subPanel.Size=UDim2.new(1,-12,0,0)
            tw(subPanel,{Size=UDim2.new(1,-12,0,subH)},SPRING):Play()
            tw(expArrow,{Rotation=180},MED):Play(); shiftBelow(posY, subH+2)
        end
        local function closeSub()
            expanded=false
            tw(subPanel,{Size=UDim2.new(1,-12,0,0)},MED):Play()
            tw(expArrow,{Rotation=0},MED):Play()
            task.delay(0.26, function() subPanel.Visible=false end)
            shiftBelow(posY, -(subH+2))
        end

        function obj:SetValue(v)
            v=not not v; tick3.Visible=v
            tw(box3,{BackgroundColor3=v and C.accentMid or C.checkOff},FAST):Play()
            tw(bS3, {Color=v and C.accentDim or C.borderHard},FAST):Play()
            tw(lbl3,{TextColor3=v and C.textBright or C.textMid},FAST):Play()
            if v and not expanded then openSub() elseif not v and expanded then closeSub() end
            self:_fire(v); AttemptSave(); UpdateDependencyBoxes()
        end

        box3.MouseButton1Click:Connect(function() ripple(row); obj:SetValue(not obj.Value) end)
        local arBtn=Instance.new("TextButton")
        arBtn.Size=UDim2.new(0,24,1,0); arBtn.Position=UDim2.new(1,-26,0,0)
        arBtn.BackgroundTransparency=1; arBtn.Text=""; arBtn.ZIndex=6; arBtn.Parent=row
        arBtn.MouseButton1Click:Connect(function()
            if not obj.Value then return end
            if expanded then closeSub() else openSub() end
        end)
        row.MouseEnter:Connect(function() tw(row,{BackgroundColor3=C.bgHover},SNAP):Play() end)
        row.MouseLeave:Connect(function() tw(row,{BackgroundColor3=C.rowBg},SNAP):Play() end)

        if key and winOptions then winOptions[key]=obj; Toggles[key]=obj end
        self._y=posY+28; return obj, self
    end

    -- ── Dependency Box ──
    function col:DependencyBox()
        local depbox = { Dependencies={} }
        local posY = self._y

        local holder = Instance.new("Frame")
        holder.BackgroundTransparency = 1
        holder.Size = UDim2.new(1,0,0,0)
        holder.Position = UDim2.new(0,0,0,posY)
        holder.Visible = false
        holder.Parent = sf
        regItem(holder, posY)

        local frame = Instance.new("Frame")
        frame.BackgroundTransparency = 1
        frame.Size = UDim2.fromScale(1,1)
        frame.Visible = true
        frame.Parent = holder

        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = frame

        -- Inner col that writes into frame
        local innerSF = Instance.new("ScrollingFrame")
        innerSF.Size = UDim2.fromScale(1,1)
        innerSF.BackgroundTransparency = 1
        innerSF.BorderSizePixel = 0
        innerSF.ScrollBarThickness = 0
        innerSF.CanvasSize = UDim2.new(0,0,0,2000)
        innerSF.ZIndex = 2; innerSF.Parent = frame

        local innerReg = {}
        local innerCol = makeColumnObj(innerSF, innerReg, openDD, winOptions, mouse)

        function depbox:Resize()
            local h = layout.AbsoluteContentSize.Y
            holder.Size = UDim2.new(1,0,0,h)
            shiftBelow(posY, 0, false) -- recompute canvas
        end

        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() depbox:Resize() end)
        holder:GetPropertyChangedSignal("Visible"):Connect(function() depbox:Resize() end)

        function depbox:Update()
            for _, dep in next, self.Dependencies do
                local elem = dep[1]; local val = dep[2]
                if elem.Type=="Toggle" and elem.Value~=val then
                    holder.Visible=false; self:Resize(); return
                end
            end
            holder.Visible=true; self:Resize()
        end

        function depbox:SetupDependencies(deps)
            self.Dependencies = deps; self:Update()
        end

        depbox.Container = innerCol
        depbox._col = innerCol

        table.insert(DependencyBoxes, depbox)
        return depbox, self
    end
    col.AddDependencyBox = col.DependencyBox

    return col
end

-- ============================================================
--  TAB OBJECT FACTORY
-- ============================================================
local function makeTabObj(panel, registry, openDD, winOptions, mouse)
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
        div.Size=UDim2.new(0,1,1,0); div.Position=UDim2.new(0.5,0,0,0)
        div.BackgroundColor3=C.borderFaint; div.BorderSizePixel=0; div.ZIndex=2; div.Parent=panel
        return makeColumnObj(lSF,registry,openDD,winOptions,mouse),
               makeColumnObj(rSF,registry,openDD,winOptions,mouse)
    end

    function tabObj:SingleColumn()
        local sf = makeScrollCol(UDim2.fromScale(1,1))
        return makeColumnObj(sf, registry, openDD, winOptions, mouse)
    end

    -- Linoria-style groupbox shim (left/right)
    function tabObj:AddLeftGroupbox(name)
        local lSF = makeScrollCol(UDim2.new(0.5,-1,1,0))
        local col = makeColumnObj(lSF, registry, openDD, winOptions, mouse)
        col:Header(name)
        return col
    end

    function tabObj:AddRightGroupbox(name)
        local rSF = makeScrollCol(UDim2.new(0.5,-1,1,0), UDim2.new(0.5,1,0,0))
        local col = makeColumnObj(rSF, registry, openDD, winOptions, mouse)
        col:Header(name)
        return col
    end

    return tabObj
end

-- ============================================================
--  UNLOAD
-- ============================================================
local OnUnloadCallback = nil

local function Unload()
    for i = #Signals, 1, -1 do
        local conn = table.remove(Signals, i)
        conn:Disconnect()
    end
    if OnUnloadCallback then SafeCallback(OnUnloadCallback) end
    ScreenGui:Destroy()
end

local function OnUnload(cb) OnUnloadCallback = cb end

-- Clean up registry when instances are destroyed
table.insert(Signals, ScreenGui.DescendantRemoving:Connect(function(inst)
    if RegistryMap[inst] then RemoveFromRegistry(inst) end
end))

-- ============================================================
--  PLAYER LIST UPDATER  (SpecialType = 'Player')
-- ============================================================
local function onPlayerChange()
    local playerList = GetPlayersString()
    for _, v in next, Options do
        if v.Type=="Dropdown" and v.SpecialType=="Player" then
            v:SetValues(playerList)
        end
    end
end
Players.PlayerAdded:Connect(onPlayerChange)
Players.PlayerRemoving:Connect(onPlayerChange)

-- ============================================================
--  MAIN WINDOW BUILDER
-- ============================================================
local OnyxiteLib = {}

function OnyxiteLib.new(config)
    local win = {}
    win._tabPanels  = {}
    win._tabButtons = {}
    win._activeTab  = nil
    win.Options     = {}
    win.Toggles     = Toggles

    local registry = {}
    local openDD   = {fn=nil}

    -- expose global helpers on win
    win.Notify                  = Notify
    win.SetWatermark            = SetWatermark
    win.SetWatermarkVisibility  = SetWatermarkVisibility
    win.Unload                  = Unload
    win.OnUnload                = OnUnload
    win.AttemptSave             = AttemptSave
    win.UpdateColorsUsingRegistry = UpdateColorsUsingRegistry
    win.NotifyOnError           = function(v) NotifyOnError = v end

    function win:SetSaveManager(sm) SaveManager = sm end

    local WIN_W      = config.Width  or 1100
    local WIN_H      = config.Height or 662
    local BORDER     = 5
    local TITLEBAR_H = 36
    local SIDEBAR_OW = 200
    local SIDEBAR_CW = 50
    local WIN_MIN_W  = 700
    local WIN_MIN_H  = 440
    local PROFILE_H  = 66
    local sidebarOpen = true
    local menuVisible = true

    local player    = Players.LocalPlayer
    local guiParent = player:WaitForChild("PlayerGui")

    local gui = Instance.new("ScreenGui")
    gui.Name = "OnyxiteGUI"; gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = guiParent

    -- Mouse reference for tooltips/pickers
    local mouse = player:GetMouse()

    local outerFrame = Instance.new("Frame"); outerFrame.Name = "WindowFrame"
    outerFrame.Size = UDim2.new(0, WIN_W+BORDER*2, 0, WIN_H+BORDER*2)
    outerFrame.Position = UDim2.new(0.5,-(WIN_W+BORDER*2)/2, 0.5,-(WIN_H+BORDER*2)/2)
    outerFrame.BackgroundColor3 = C.shellOuter; outerFrame.BorderSizePixel = 0
    outerFrame.ZIndex = 1; outerFrame.Parent = gui
    corner(outerFrame, 3)
    gradientN(outerFrame, {{0,Color3.fromRGB(4,4,4)},{0.3,Color3.fromRGB(18,18,18)},{0.7,Color3.fromRGB(18,18,18)},{1,Color3.fromRGB(4,4,4)}}, 120)
    stroke(outerFrame, C.shellBorder, 1, 0.3)

    win._outerFrame = outerFrame
    win._gui        = gui

    local main = Instance.new("Frame"); main.Name = "Main"
    main.Size = UDim2.new(1,-BORDER*2,1,-BORDER*2); main.Position = UDim2.new(0,BORDER,0,BORDER)
    main.BackgroundColor3 = C.bgMain; main.BorderSizePixel = 0; main.ZIndex = 2
    main.ClipsDescendants = false; main.Parent = outerFrame
    corner(main, 2)
    gradientN(main, {{0,C.bgSurface},{0.5,C.bgMain},{1,C.bgDeep}}, 160)
    stroke(main, C.borderHard, 1, 0.2)
    main.BackgroundTransparency = 0.25

    local topAccent = Instance.new("Frame")
    topAccent.Size = UDim2.new(0,64,0,1)
    topAccent.BackgroundColor3 = C.accentDim; topAccent.BorderSizePixel = 0
    topAccent.ZIndex = 6; topAccent.Parent = main; corner(topAccent, 1)
    do local g=Instance.new("UIGradient"); g.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.2),NumberSequenceKeypoint.new(1,1)}); g.Rotation=0; g.Parent=topAccent end

    -- Title bar
    local titleBar = Instance.new("Frame"); titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1,0,0,TITLEBAR_H); titleBar.BackgroundColor3 = C.titleBg
    titleBar.BorderSizePixel = 0; titleBar.ZIndex = 4; titleBar.Parent = main
    corner(titleBar, 2)
    gradientN(titleBar, {{0,Color3.fromRGB(18,18,18)},{0.6,Color3.fromRGB(10,10,10)},{1,Color3.fromRGB(5,5,5)}}, 180)
    local tSep = Instance.new("Frame")
    tSep.Size=UDim2.new(1,0,0,1); tSep.Position=UDim2.new(0,0,1,-1)
    tSep.BackgroundColor3=C.borderSoft; tSep.BorderSizePixel=0; tSep.ZIndex=5; tSep.Parent=titleBar
    do local g=Instance.new("UIGradient"); g.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.6),NumberSequenceKeypoint.new(0.5,0),NumberSequenceKeypoint.new(1,0.6)}); g.Rotation=0; g.Parent=tSep end

    local sDot = Instance.new("Frame")
    sDot.Size=UDim2.new(0,5,0,5); sDot.Position=UDim2.new(0,14,0.5,-2)
    sDot.BackgroundColor3=C.accentDim; sDot.BorderSizePixel=0; sDot.ZIndex=6; sDot.Parent=titleBar; corner(sDot,3)

    local tLbl = Instance.new("TextLabel")
    tLbl.Text=config.Title or "Onyxite"; tLbl.Font=FONT_BOLD; tLbl.TextSize=14
    tLbl.TextColor3=C.textBright; tLbl.BackgroundTransparency=1
    tLbl.Size=UDim2.new(0,140,1,0); tLbl.Position=UDim2.new(0,26,0,0)
    tLbl.TextXAlignment=Enum.TextXAlignment.Left; tLbl.ZIndex=6; tLbl.Parent=titleBar

    local vLbl = Instance.new("TextLabel")
    vLbl.Text=config.SubTitle or "v1.0"; vLbl.Font=FONT_REG; vLbl.TextSize=9
    vLbl.TextColor3=C.textDim; vLbl.BackgroundTransparency=1
    vLbl.Size=UDim2.new(0,200,0,12); vLbl.Position=UDim2.new(0,168,0.5,-6)
    vLbl.TextXAlignment=Enum.TextXAlignment.Left; vLbl.ZIndex=6; vLbl.Parent=titleBar

    function win:SetWindowTitle(title) tLbl.Text=title end

    local function makeWinBtn(xOff, glyph, hBg, hTxt)
        local b=Instance.new("TextButton")
        b.Size=UDim2.new(0,22,0,22); b.Position=UDim2.new(1,xOff,0.5,-11)
        b.BackgroundColor3=Color3.fromRGB(16,16,16); b.BorderSizePixel=0
        b.Text=glyph; b.Font=FONT_BOLD; b.TextSize=14
        b.TextColor3=C.textDim; b.AutoButtonColor=false; b.ZIndex=8; b.Parent=titleBar; corner(b,2)
        local s=stroke(b, C.borderFaint, 1, 0.3)
        b.MouseEnter:Connect(function() tw(b,{BackgroundColor3=hBg,TextColor3=hTxt},SNAP):Play(); tw(s,{Color=hTxt,Transparency=0},SNAP):Play() end)
        b.MouseLeave:Connect(function() tw(b,{BackgroundColor3=Color3.fromRGB(16,16,16),TextColor3=C.textDim},SNAP):Play(); tw(s,{Color=C.borderFaint,Transparency=0.3},SNAP):Play() end)
        b.MouseButton1Down:Connect(function() tw(b,{BackgroundColor3=C.bgPress},SNAP):Play() end)
        return b
    end
    local closeBtn    = makeWinBtn(-30, "×", Color3.fromRGB(38,12,12), Color3.fromRGB(200,80,80))
    local minimizeBtn = makeWinBtn(-56, "−", Color3.fromRGB(28,28,20), Color3.fromRGB(200,200,120))

    -- Restore pill
    local rPill=Instance.new("TextButton")
    rPill.Size=UDim2.new(0,130,0,26); rPill.Position=UDim2.new(0.5,-65,0,-50)
    rPill.BackgroundColor3=Color3.fromRGB(12,12,12); rPill.BorderSizePixel=0; rPill.Text=""
    rPill.AutoButtonColor=false; rPill.ZIndex=50; rPill.Visible=false; rPill.Parent=gui
    corner(rPill,13); stroke(rPill,C.borderHard,1,0.1); gradient(rPill,Color3.fromRGB(20,20,20),Color3.fromRGB(8,8,8),180)
    local pDot2=Instance.new("Frame")
    pDot2.Size=UDim2.new(0,5,0,5); pDot2.Position=UDim2.new(0,11,0.5,-2)
    pDot2.BackgroundColor3=C.accentDim; pDot2.BorderSizePixel=0; pDot2.ZIndex=52; pDot2.Parent=rPill; corner(pDot2,3)
    local pLbl=Instance.new("TextLabel")
    pLbl.Text=string.upper(config.Title or "ONYXITE"); pLbl.Font=FONT_BOLD; pLbl.TextSize=10
    pLbl.TextColor3=C.textMid; pLbl.BackgroundTransparency=1
    pLbl.Size=UDim2.new(1,-24,1,0); pLbl.Position=UDim2.new(0,22,0,0)
    pLbl.TextXAlignment=Enum.TextXAlignment.Left; pLbl.ZIndex=52; pLbl.Parent=rPill
    rPill.MouseEnter:Connect(function() tw(rPill,{BackgroundColor3=Color3.fromRGB(22,22,22)},SNAP):Play() end)
    rPill.MouseLeave:Connect(function() tw(rPill,{BackgroundColor3=Color3.fromRGB(12,12,12)},SNAP):Play() end)

    -- Pill drag
    local pDrag,pDS,pSP=false,nil,nil
    rPill.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then pDrag=true;pDS=inp.Position;pSP=rPill.Position end end)
    table.insert(Signals, UIS.InputChanged:Connect(function(inp) if pDrag and inp.UserInputType==Enum.UserInputType.MouseMovement then local d=inp.Position-pDS; rPill.Position=UDim2.new(pSP.X.Scale,pSP.X.Offset+d.X,pSP.Y.Scale,pSP.Y.Offset+d.Y) end end))
    table.insert(Signals, UIS.InputEnded:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then pDrag=false end end))

    -- Close dialog
    local bOver=Instance.new("Frame")
    bOver.Size=UDim2.fromScale(1,1); bOver.BackgroundColor3=Color3.fromRGB(0,0,0)
    bOver.BackgroundTransparency=1; bOver.BorderSizePixel=0; bOver.ZIndex=90; bOver.Visible=false; bOver.Parent=gui

    local cDlg=Instance.new("Frame")
    cDlg.Size=UDim2.new(0,300,0,158); cDlg.Position=UDim2.new(0.5,-150,0.5,-79)
    cDlg.BackgroundColor3=C.dialogBg; cDlg.BorderSizePixel=0; cDlg.ZIndex=92; cDlg.Parent=bOver
    corner(cDlg,3); gradientN(cDlg,{{0,Color3.fromRGB(20,20,20)},{1,Color3.fromRGB(6,6,6)}},160); stroke(cDlg,C.borderHard,1,0.1)

    local dTop=Instance.new("Frame"); dTop.Size=UDim2.new(1,0,0,1); dTop.BackgroundColor3=C.borderSoft; dTop.BorderSizePixel=0; dTop.ZIndex=93; dTop.Parent=cDlg
    do local g=Instance.new("UIGradient"); g.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.4),NumberSequenceKeypoint.new(0.5,0),NumberSequenceKeypoint.new(1,0.4)}); g.Rotation=0; g.Parent=dTop end

    local dTitle=Instance.new("TextLabel")
    dTitle.Size=UDim2.new(1,-32,0,36); dTitle.Position=UDim2.new(0,22,0,8)
    dTitle.BackgroundTransparency=1; dTitle.Font=FONT_BOLD; dTitle.TextSize=16
    dTitle.TextColor3=C.textBright; dTitle.TextTransparency=1
    dTitle.Text="CLOSE "..string.upper(config.Title or "ONYXITE?")
    dTitle.TextXAlignment=Enum.TextXAlignment.Left; dTitle.ZIndex=93; dTitle.Parent=cDlg

    local dMsg=Instance.new("TextLabel")
    dMsg.Size=UDim2.new(1,-32,0,44); dMsg.Position=UDim2.new(0,22,0,44)
    dMsg.BackgroundTransparency=1; dMsg.Font=FONT_REG; dMsg.TextSize=11
    dMsg.TextColor3=C.textSub; dMsg.TextTransparency=1; dMsg.TextWrapped=true
    dMsg.Text="Are you sure you want to close the menu?\nRe-execute the script to reopen it."
    dMsg.TextXAlignment=Enum.TextXAlignment.Left; dMsg.ZIndex=93; dMsg.Parent=cDlg

    local dDiv=Instance.new("Frame")
    dDiv.Size=UDim2.new(1,-24,0,1); dDiv.Position=UDim2.new(0,12,0,96)
    dDiv.BackgroundColor3=C.borderFaint; dDiv.BorderSizePixel=0; dDiv.ZIndex=93; dDiv.Parent=cDlg

    local function mDB(x,w,t,bg,tc,sc)
        local b=Instance.new("TextButton")
        b.Size=UDim2.new(0,w,0,32); b.Position=UDim2.new(0,x,1,-44)
        b.BackgroundColor3=bg; b.BorderSizePixel=0; b.Text=t; b.TextColor3=tc
        b.TextTransparency=1; b.TextSize=11; b.Font=FONT_REG
        b.AutoButtonColor=false; b.ZIndex=93; b.Parent=cDlg; corner(b,2); stroke(b,sc,1,0.4); return b
    end
    local cancelBtn  = mDB(14, 120,"CANCEL",Color3.fromRGB(16,16,16), C.textMid,             C.borderHard)
    local confirmBtn = mDB(148,120,"CLOSE", Color3.fromRGB(24,6,6),   Color3.fromRGB(190,70,70), Color3.fromRGB(100,30,30))
    cancelBtn.MouseEnter:Connect(function()  tw(cancelBtn, {BackgroundColor3=C.bgHover,TextColor3=C.textBright},SNAP):Play() end)
    cancelBtn.MouseLeave:Connect(function()  tw(cancelBtn, {BackgroundColor3=Color3.fromRGB(16,16,16),TextColor3=C.textMid},SNAP):Play() end)
    confirmBtn.MouseEnter:Connect(function() tw(confirmBtn,{BackgroundColor3=Color3.fromRGB(38,8,8)},SNAP):Play() end)
    confirmBtn.MouseLeave:Connect(function() tw(confirmBtn,{BackgroundColor3=Color3.fromRGB(24,6,6)},SNAP):Play() end)

    local function openDialog()
        if openDD.fn then openDD.fn(); openDD.fn=nil end
        bOver.Visible=true; tw(bOver,{BackgroundTransparency=0.55},MED):Play()
        task.delay(0.05,  function() tw(dTitle,{TextTransparency=0},MED):Play() end)
        task.delay(0.12,  function() tw(dMsg,  {TextTransparency=0},MED):Play() end)
        task.delay(0.18,  function() tw(cancelBtn,{TextTransparency=0},MED):Play(); tw(confirmBtn,{TextTransparency=0},MED):Play() end)
    end
    local function closeDialog()
        tw(bOver,{BackgroundTransparency=1},MED):Play()
        tw(dTitle,{TextTransparency=1},FAST):Play(); tw(dMsg,{TextTransparency=1},FAST):Play()
        tw(cancelBtn,{TextTransparency=1},FAST):Play(); tw(confirmBtn,{TextTransparency=1},FAST):Play()
        task.delay(0.28, function() bOver.Visible=false end)
    end
    cancelBtn.MouseButton1Click:Connect(closeDialog)
    confirmBtn.MouseButton1Click:Connect(function()
        tw(bOver,{BackgroundTransparency=0},TweenInfo.new(0.18)):Play()
        task.wait(0.22); gui:Destroy()
    end)
    closeBtn.MouseButton1Click:Connect(openDialog)

    -- Minimize / Restore
    local function minimize()
        menuVisible=false
        tw(main,{BackgroundTransparency=1},FAST):Play()
        task.delay(0.18, function()
            outerFrame.Visible=false; main.BackgroundTransparency=0.25
            rPill.Position=UDim2.new(0.5,-65,0,-50); rPill.Visible=true
            tw(rPill,{Position=UDim2.new(0.5,-65,0,12)},SLOW):Play()
        end)
    end
    local function restore()
        tw(rPill,{Position=UDim2.new(rPill.Position.X.Scale,rPill.Position.X.Offset,0,-50)},MED):Play()
        task.delay(0.20, function() rPill.Visible=false end)
        outerFrame.Visible=true; menuVisible=true
    end
    minimizeBtn.MouseButton1Click:Connect(minimize)
    rPill.MouseButton1Click:Connect(function() if not pDrag then restore() end end)

    -- Toggle keybind (Insert or configurable)
    table.insert(Signals, UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        local toggleKey = config.ToggleKey or Enum.KeyCode.Insert
        if type(win.ToggleKeybind)=="table" and win.ToggleKeybind.Type=="KeyPicker" then
            if inp.UserInputType==Enum.UserInputType.Keyboard and inp.KeyCode.Name==win.ToggleKeybind.Value then
                if menuVisible then minimize() else restore() end
            end
        elseif inp.KeyCode==toggleKey or inp.KeyCode==Enum.KeyCode.RightShift then
            if menuVisible then minimize() else restore() end
        end
    end))

    -- Title bar drag
    local drag,dS,dSP=false,nil,nil
    titleBar.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then drag=true;dS=inp.Position;dSP=outerFrame.Position end end)
    table.insert(Signals, UIS.InputChanged:Connect(function(inp) if drag and inp.UserInputType==Enum.UserInputType.MouseMovement then local d=inp.Position-dS; outerFrame.Position=UDim2.new(dSP.X.Scale,dSP.X.Offset+d.X,dSP.Y.Scale,dSP.Y.Offset+d.Y) end end))
    table.insert(Signals, UIS.InputEnded:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end))

    -- Resize handle
    local rHandle=Instance.new("TextButton")
    rHandle.Size=UDim2.new(0,20,0,20); rHandle.Position=UDim2.new(1,-18,1,-18)
    rHandle.BackgroundColor3=Color3.fromRGB(30,30,30); rHandle.BackgroundTransparency=0.6
    rHandle.BorderSizePixel=0; rHandle.Text=""; rHandle.AutoButtonColor=false; rHandle.ZIndex=20; rHandle.Parent=main; corner(rHandle,2)
    local rGlyph=Instance.new("TextLabel")
    rGlyph.Text="↘"; rGlyph.Font=FONT_BOLD; rGlyph.TextSize=16
    rGlyph.TextColor3=C.textDim; rGlyph.BackgroundTransparency=1; rGlyph.Size=UDim2.fromScale(1,1); rGlyph.ZIndex=21; rGlyph.Parent=rHandle
    local rz,rDS,rSS=false,nil,nil
    rHandle.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then rz=true;rDS=inp.Position;rSS=outerFrame.AbsoluteSize end end)
    table.insert(Signals, UIS.InputChanged:Connect(function(inp) if rz and inp.UserInputType==Enum.UserInputType.MouseMovement then local d=inp.Position-rDS; outerFrame.Size=UDim2.new(0,math.max(WIN_MIN_W,rSS.X+d.X),0,math.max(WIN_MIN_H,rSS.Y+d.Y)) end end))
    table.insert(Signals, UIS.InputEnded:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then rz=false end end))
    rHandle.MouseEnter:Connect(function() tw(rHandle,{BackgroundTransparency=0.3},SNAP):Play(); tw(rGlyph,{TextColor3=C.textSub},SNAP):Play() end)
    rHandle.MouseLeave:Connect(function() tw(rHandle,{BackgroundTransparency=0.6},SNAP):Play(); tw(rGlyph,{TextColor3=C.textDim},SNAP):Play() end)

    -- Sidebar
    local sidebar=Instance.new("Frame"); sidebar.Name="Sidebar"
    sidebar.Size=UDim2.new(0,SIDEBAR_OW,1,-TITLEBAR_H); sidebar.Position=UDim2.new(0,0,0,TITLEBAR_H)
    sidebar.BackgroundColor3=C.sidebarBg; sidebar.BorderSizePixel=0; sidebar.ZIndex=4; sidebar.ClipsDescendants=true; sidebar.Parent=main; corner(sidebar,2)
    gradientN(sidebar,{{0,Color3.fromRGB(14,14,14)},{0.5,Color3.fromRGB(8,8,8)},{1,Color3.fromRGB(4,4,4)}},180)
    local sB=Instance.new("Frame")
    sB.Size=UDim2.new(0,1,1,0); sB.Position=UDim2.new(1,-1,0,0)
    sB.BackgroundColor3=C.borderSoft; sB.BorderSizePixel=0; sB.ZIndex=5; sB.Parent=sidebar
    do local g=Instance.new("UIGradient"); g.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.7),NumberSequenceKeypoint.new(0.5,0.1),NumberSequenceKeypoint.new(1,0.7)}); g.Rotation=90; g.Parent=sB end

    local sLA=Instance.new("Frame")
    sLA.Size=UDim2.new(1,0,0,44); sLA.BackgroundColor3=Color3.fromRGB(10,10,10); sLA.BorderSizePixel=0; sLA.ZIndex=5; sLA.Parent=sidebar; corner(sLA,2)
    gradientN(sLA,{{0,Color3.fromRGB(20,20,20)},{1,Color3.fromRGB(6,6,6)}},180)
    local sLD=Instance.new("Frame")
    sLD.Size=UDim2.new(0,5,0,5); sLD.Position=UDim2.new(0,12,0.5,-2)
    sLD.BackgroundColor3=C.accentDim; sLD.BorderSizePixel=0; sLD.ZIndex=6; sLD.Parent=sLA; corner(sLD,3)
    local sLT=Instance.new("TextLabel")
    sLT.Text=config.Creator or "Onyxite"; sLT.Font=FONT_SCI; sLT.TextSize=11
    sLT.TextColor3=C.textMid; sLT.BackgroundTransparency=1
    sLT.Size=UDim2.new(1,-24,1,0); sLT.Position=UDim2.new(0,22,0,0)
    sLT.TextXAlignment=Enum.TextXAlignment.Left; sLT.ZIndex=6; sLT.Parent=sLA
    local sLDiv=Instance.new("Frame")
    sLDiv.Size=UDim2.new(1,0,0,1); sLDiv.Position=UDim2.new(0,0,1,-1)
    sLDiv.BackgroundColor3=C.borderFaint; sLDiv.BorderSizePixel=0; sLDiv.ZIndex=6; sLDiv.Parent=sLA

    local sTBtn=Instance.new("TextButton")
    sTBtn.Size=UDim2.new(1,0,0,26); sTBtn.Position=UDim2.new(0,0,1,-(PROFILE_H+26))
    sTBtn.BackgroundColor3=Color3.fromRGB(10,10,10); sTBtn.BorderSizePixel=0
    sTBtn.Text="◀"; sTBtn.Font=FONT_BOLD; sTBtn.TextSize=10
    sTBtn.TextColor3=C.textDim; sTBtn.AutoButtonColor=false; sTBtn.ZIndex=7; sTBtn.Parent=sidebar
    sTBtn.MouseEnter:Connect(function() tw(sTBtn,{BackgroundColor3=Color3.fromRGB(18,18,18),TextColor3=C.textSub},SNAP):Play() end)
    sTBtn.MouseLeave:Connect(function() tw(sTBtn,{BackgroundColor3=Color3.fromRGB(10,10,10),TextColor3=C.textDim},SNAP):Play() end)

    -- Profile card
    local profileCard=Instance.new("Frame"); profileCard.Name="ProfileCard"
    profileCard.Size=UDim2.new(1,0,0,PROFILE_H); profileCard.Position=UDim2.new(0,0,1,-PROFILE_H)
    profileCard.BackgroundColor3=C.profileBg; profileCard.BorderSizePixel=0; profileCard.ZIndex=6; profileCard.Parent=sidebar; corner(profileCard,2)
    gradientN(profileCard,{{0,Color3.fromRGB(18,18,18)},{0.5,Color3.fromRGB(10,10,10)},{1,Color3.fromRGB(5,5,5)}},180)
    local profLine=Instance.new("Frame")
    profLine.Size=UDim2.new(1,0,0,1); profLine.BackgroundColor3=C.profileLine; profLine.BorderSizePixel=0; profLine.ZIndex=7; profLine.Parent=profileCard
    do local g=Instance.new("UIGradient"); g.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.5),NumberSequenceKeypoint.new(0.5,0),NumberSequenceKeypoint.new(1,0.5)}); g.Rotation=0; g.Parent=profLine end

    local avatarFrame=Instance.new("Frame")
    avatarFrame.Size=UDim2.new(0,40,0,40); avatarFrame.Position=UDim2.new(0,12,0.5,-20)
    avatarFrame.BackgroundColor3=Color3.fromRGB(22,22,22); avatarFrame.BorderSizePixel=0; avatarFrame.ZIndex=8; avatarFrame.Parent=profileCard; corner(avatarFrame,5)
    stroke(avatarFrame,C.borderSoft,1,0.2)
    local avatarImg=Instance.new("ImageLabel")
    avatarImg.Size=UDim2.fromScale(1,1); avatarImg.BackgroundTransparency=1
    avatarImg.Image="rbxthumb://type=AvatarHeadShot&id="..tostring(player.UserId).."&w=150&h=150"
    avatarImg.ZIndex=9; avatarImg.Parent=avatarFrame; corner(avatarImg,5)

    local profName=Instance.new("TextLabel")
    profName.Size=UDim2.new(1,-62,0,18); profName.Position=UDim2.new(0,58,0,12)
    profName.BackgroundTransparency=1; profName.Font=FONT_BOLD; profName.TextSize=13; profName.TextColor3=C.textBright
    profName.TextXAlignment=Enum.TextXAlignment.Left; profName.TextTruncate=Enum.TextTruncate.AtEnd; profName.ZIndex=8; profName.Parent=profileCard
    profName.Text=player.DisplayName

    local profUser=Instance.new("TextLabel")
    profUser.Size=UDim2.new(1,-62,0,14); profUser.Position=UDim2.new(0,58,0,32)
    profUser.BackgroundTransparency=1; profUser.Font=FONT_REG; profUser.TextSize=11; profUser.TextColor3=C.textSub
    profUser.TextXAlignment=Enum.TextXAlignment.Left; profUser.TextTruncate=Enum.TextTruncate.AtEnd; profUser.ZIndex=8; profUser.Parent=profileCard
    profUser.Text="@"..player.Name
    player:GetPropertyChangedSignal("DisplayName"):Connect(function() profName.Text=player.DisplayName end)

    local cArea=Instance.new("Frame"); cArea.Name="ContentArea"
    cArea.Size=UDim2.new(1,-(SIDEBAR_OW+1),1,-TITLEBAR_H); cArea.Position=UDim2.new(0,SIDEBAR_OW+1,0,TITLEBAR_H)
    cArea.BackgroundTransparency=1; cArea.BorderSizePixel=0; cArea.ZIndex=2; cArea.Parent=main

    local tabSelector=Instance.new("Frame")
    tabSelector.Size=UDim2.new(0,2,0,16)
    tabSelector.BackgroundColor3=C.accentMid; tabSelector.BorderSizePixel=0; tabSelector.ZIndex=8; tabSelector.Parent=sidebar; corner(tabSelector,1)

    local TAB_H = 38

    local function showTab(name)
        if openDD.fn then openDD.fn(); openDD.fn=nil end
        for tabName, p in pairs(win._tabPanels) do
            if p.Visible and tabName~=name then
                if p:IsA("CanvasGroup") then tw(p,{GroupTransparency=1},FAST):Play() end
                task.delay(0.18, function() p.Visible=false; if p:IsA("CanvasGroup") then p.GroupTransparency=0 end end)
            end
        end
        local newPanel=win._tabPanels[name]
        if newPanel then
            newPanel.Visible=true
            if newPanel:IsA("CanvasGroup") then newPanel.GroupTransparency=1; tw(newPanel,{GroupTransparency=0},MED):Play() end
        end
        for _, d in ipairs(win._tabButtons) do
            local active=d.name==name
            if active then
                tw(d.btn,{BackgroundColor3=C.tabActive},MED):Play()
                tw(d.iL, {TextColor3=C.textBright},MED):Play()
                tw(d.lbl,{TextColor3=C.textBright},MED):Play()
                tw(tabSelector,{Position=UDim2.new(0,0,0,d.btn.Position.Y.Offset+(TAB_H-16)/2),Size=UDim2.new(0,2,0,16)},SPRING):Play()
            else
                tw(d.btn,{BackgroundColor3=C.tabInact},FAST):Play()
                tw(d.iL, {TextColor3=C.textDim},FAST):Play()
                tw(d.lbl,{TextColor3=C.textDim},FAST):Play()
            end
        end
        win._activeTab=name
    end

    local function setSidebar(open)
        sidebarOpen=open; local w=open and SIDEBAR_OW or SIDEBAR_CW
        tw(sidebar,{Size=UDim2.new(0,w,1,-TITLEBAR_H)},MED):Play()
        tw(cArea,{Size=UDim2.new(1,-(w+1),1,-TITLEBAR_H),Position=UDim2.new(0,w+1,0,TITLEBAR_H)},MED):Play()
        sTBtn.Text=open and "◀" or "▶"
        for _, d in ipairs(win._tabButtons) do tw(d.lbl,{TextTransparency=open and 0 or 1},MED):Play() end
        tw(sLT,        {TextTransparency=open and 0 or 1},MED):Play()
        tw(profName,   {TextTransparency=open and 0 or 1},MED):Play()
        tw(profUser,   {TextTransparency=open and 0 or 1},MED):Play()
        tw(avatarFrame,{BackgroundTransparency=open and 0 or 1},MED):Play()
        tw(avatarImg,  {ImageTransparency=open and 0 or 1},MED):Play()
    end
    sTBtn.MouseButton1Click:Connect(function() setSidebar(not sidebarOpen) end)

    -- Build tabs from config
    local tabDefs = config.Tabs or {}
    if #tabDefs>0 then win._activeTab=tabDefs[1].Name end

    for i, def in ipairs(tabDefs) do
        local yPos = 44+(i-1)*TAB_H
        local panel=Instance.new("CanvasGroup")
        panel.Size=UDim2.fromScale(1,1); panel.BackgroundTransparency=1
        panel.Visible=false; panel.GroupTransparency=0; panel.ZIndex=2; panel.Parent=cArea
        win._tabPanels[def.Name]=panel

        local btn=Instance.new("TextButton"); btn.Name=def.Name.."Tab"
        btn.Size=UDim2.new(1,0,0,TAB_H); btn.Position=UDim2.new(0,0,0,yPos)
        btn.BackgroundColor3=(def.Name==win._activeTab) and C.tabActive or C.tabInact
        btn.BorderSizePixel=0; btn.Text=""; btn.AutoButtonColor=false; btn.ZIndex=6; btn.Parent=sidebar

        local iL=Instance.new("TextLabel")
        iL.Text=def.Icon or "·"; iL.Font=FONT_REG; iL.TextSize=15
        iL.TextColor3=(def.Name==win._activeTab) and C.textBright or C.textDim
        iL.BackgroundTransparency=1; iL.Size=UDim2.new(0,SIDEBAR_CW,1,0)
        iL.TextXAlignment=Enum.TextXAlignment.Center; iL.ZIndex=7; iL.Parent=btn

        local lbl=Instance.new("TextLabel")
        lbl.Text=def.Name; lbl.Font=FONT_BOLD; lbl.TextSize=12
        lbl.TextColor3=(def.Name==win._activeTab) and C.textBright or C.textDim
        lbl.TextTransparency=sidebarOpen and 0 or 1; lbl.BackgroundTransparency=1
        lbl.Size=UDim2.new(1,-(SIDEBAR_CW+4),1,0); lbl.Position=UDim2.new(0,SIDEBAR_CW,0,0)
        lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=7; lbl.Parent=btn

        if i<#tabDefs then
            local sep=Instance.new("Frame")
            sep.Size=UDim2.new(0.7,0,0,1); sep.Position=UDim2.new(0.15,0,1,-1)
            sep.BackgroundColor3=C.borderFaint; sep.BackgroundTransparency=0.2; sep.BorderSizePixel=0; sep.ZIndex=6; sep.Parent=btn
        end

        local data={name=def.Name,btn=btn,iL=iL,lbl=lbl}
        table.insert(win._tabButtons, data)

        local cn=def.Name
        btn.MouseButton1Click:Connect(function() ripple(btn); showTab(cn) end)
        btn.MouseEnter:Connect(function()
            if win._activeTab~=cn then
                tw(btn,{BackgroundColor3=C.tabHover},SNAP):Play()
                tw(iL, {TextColor3=C.textSub},SNAP):Play()
                tw(lbl,{TextColor3=C.textSub},SNAP):Play()
            end
        end)
        btn.MouseLeave:Connect(function()
            if win._activeTab~=cn then
                tw(btn,{BackgroundColor3=C.tabInact},SNAP):Play()
                tw(iL, {TextColor3=C.textDim},SNAP):Play()
                tw(lbl,{TextColor3=C.textDim},SNAP):Play()
            end
        end)

        -- SetLayoutOrder support
        function data:SetLayoutOrder(pos)
            btn.LayoutOrder = pos
        end
    end

    if win._activeTab then showTab(win._activeTab) end

    -- Also allow AddTab dynamically (Linoria style)
    function win:AddTab(name, icon)
        local i = #self._tabButtons + 1
        local yPos = 44+(i-1)*TAB_H
        local panel=Instance.new("CanvasGroup")
        panel.Size=UDim2.fromScale(1,1); panel.BackgroundTransparency=1
        panel.Visible=false; panel.GroupTransparency=0; panel.ZIndex=2; panel.Parent=cArea
        self._tabPanels[name]=panel

        local btn=Instance.new("TextButton"); btn.Name=name.."Tab"
        btn.Size=UDim2.new(1,0,0,TAB_H); btn.Position=UDim2.new(0,0,0,yPos)
        btn.BackgroundColor3=C.tabInact
        btn.BorderSizePixel=0; btn.Text=""; btn.AutoButtonColor=false; btn.ZIndex=6; btn.Parent=sidebar

        local iL=Instance.new("TextLabel")
        iL.Text=icon or "·"; iL.Font=FONT_REG; iL.TextSize=15
        iL.TextColor3=C.textDim
        iL.BackgroundTransparency=1; iL.Size=UDim2.new(0,SIDEBAR_CW,1,0)
        iL.TextXAlignment=Enum.TextXAlignment.Center; iL.ZIndex=7; iL.Parent=btn

        local lbl=Instance.new("TextLabel")
        lbl.Text=name; lbl.Font=FONT_BOLD; lbl.TextSize=12
        lbl.TextColor3=C.textDim; lbl.TextTransparency=sidebarOpen and 0 or 1
        lbl.BackgroundTransparency=1
        lbl.Size=UDim2.new(1,-(SIDEBAR_CW+4),1,0); lbl.Position=UDim2.new(0,SIDEBAR_CW,0,0)
        lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=7; lbl.Parent=btn

        local data={name=name, btn=btn, iL=iL, lbl=lbl}
        table.insert(self._tabButtons, data)

        local cn=name
        btn.MouseButton1Click:Connect(function() ripple(btn); showTab(cn) end)
        btn.MouseEnter:Connect(function()
            if self._activeTab~=cn then
                tw(btn,{BackgroundColor3=C.tabHover},SNAP):Play()
                tw(iL, {TextColor3=C.textSub},SNAP):Play()
                tw(lbl,{TextColor3=C.textSub},SNAP):Play()
            end
        end)
        btn.MouseLeave:Connect(function()
            if self._activeTab~=cn then
                tw(btn,{BackgroundColor3=C.tabInact},SNAP):Play()
                tw(iL, {TextColor3=C.textDim},SNAP):Play()
                tw(lbl,{TextColor3=C.textDim},SNAP):Play()
            end
        end)

        if not self._activeTab then showTab(name) end

        return makeTabObj(panel, registry, openDD, self.Options, mouse)
    end

    function win:GetTab(name)
        local panel=self._tabPanels[name]
        assert(panel, "Tab '"..tostring(name).."' not found.")
        return makeTabObj(panel, registry, openDD, self.Options, mouse)
    end

    function win:ShowTab(name) showTab(name) end

    return win
end

-- ============================================================
--  GLOBAL EXPORTS
-- ============================================================
getgenv().OnyxiteLib = OnyxiteLib

-- Expose helpers at top level for compatibility
OnyxiteLib.Notify                  = Notify
OnyxiteLib.SetWatermark            = SetWatermark
OnyxiteLib.SetWatermarkVisibility  = SetWatermarkVisibility
OnyxiteLib.Unload                  = Unload
OnyxiteLib.OnUnload                = OnUnload
OnyxiteLib.UpdateColorsUsingRegistry = UpdateColorsUsingRegistry
OnyxiteLib.Toggles                 = Toggles
OnyxiteLib.Options                 = Options
OnyxiteLib.CurrentRainbowColor     = function() return CurrentRainbowColor end
OnyxiteLib.SafeCallback            = SafeCallback
OnyxiteLib.AttemptSave             = AttemptSave
OnyxiteLib.KeybindFrame            = KeybindFrame
OnyxiteLib.WatermarkFrame          = WatermarkFrame

return OnyxiteLib
