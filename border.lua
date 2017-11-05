local pkg = {}

local tools = dofile( os.getenv("HOME") .. "/.hammerspoon/tools.lua")

local function cloneBorder(frame)
    local f = {x = frame.x, y= frame.y, w= frame.w, h = frame.h}
    return f
end

pkg.cloneBorder = cloneBorder

local function create_canvas_border(frame)
    local border = {}
    border.action = "stroke"
    border.strokeColor = {alpha = 1, red = 1.0, green = 1.0}
    border.fillColor = { alpha = 1 }
    border.antialias = false
    border.arcRadii = false
    border.canvasAlpha = 1.0
    border.imageAlpha = 1.0
    border.strokeWidth = 4
    border.frame = cloneBorder(frame)
    border.type = "rectangle"

    return border
end
pkg.create_canvas_border = create_canvas_border

local function init_border()
    local Border = hs.drawing.rectangle(hs.geometry.rect(0,0,0,0))
    Border:setFill(false)
    Border:setStrokeWidth(3)
    Border:setStrokeColor({["red"]=1,["blue"]=0,["green"]=0,["alpha"]=0.8})
    return Border
end

pkg.init_border = init_border

local function convertFromBorderToFrame(root)
    if root == nil then 
        return 
    end

    if root.canvas ~= nil then
        root.canvas:delete()
        root.canvas = nil
    end

    if root.border_ ~= nil then
        root.frame = tools.cloneFrame(root.border_)
        root.border_ = nil
    end

    convertFromBorderToFrame(root.left)
    convertFromBorderToFrame(root.right)
end

pkg.convertFromBorderToFrame = convertFromBorderToFrame

local function travelAndAppendToCanvas(root, canvas)
    if root == nil then 
        return
    end

    if root.windowID ~= nil and root.border_ ~= nil then
        canvas:appendElements( create_canvas_border(root.border_) )

        return
    end

    if root.left ~= nil then
        travelAndAppendToCanvas(root.left, canvas)
    end

    if root.right ~= nil then
        travelAndAppendToCanvas(root.right, canvas)
    end
end

pkg.travelAndAppendToCanvas = travelAndAppendToCanvas

local function create_window_border(frame)
    local border = hs.drawing.rectangle(hs.geometry.rect(frame))

    border:setFill(false)
    border:setStrokeWidth(5)
    border:setStrokeColor({["red"]=1,["blue"]=0,["green"]=1,["alpha"]=0.9})
    border = border:wantsLayer(true)
    return border
end

local function rescaleBorder(node, canvas)
    if node == nil then 
        return 
    end

    if node.windowID then
        return
    end

    node.left.border_ = tools.cloneFrame(node.left.frame)
    node.right.border_ = tools.cloneFrame(node.right.frame)

    local f1 = node.left.border_
    local f2 = node.right.border_

    if node.isDividedHorizontal then

        local H = f1.h + f2.h
        local r = f1.h / f2.h
        local delta = node.border_.h - H
        local h2 = delta / (r + 1.0)
        local h1 = (delta - h2)
        f1.h = f1.h + h1
        f1.w = node.border_.w
        f1.x = node.border_.x
        f1.y = node.border_.y

        f2.x = f1.x
        f2.y = f1.y + f1.h
        f2.h = node.border_.h - f1.h
        f2.w = f1.w
    else
        local W = f1.w + f2.w
        local r = f1.w / f2.w
        local delta = node.border_.w - W
        local w2 = delta / (r + 1)
        local w1 = delta - w2

        f1.w = f1.w + w1
        f1.h = node.border_.h
        f1.x = node.border_.x
        f1.y = node.border_.y

        f2.x = f1.x + f1.w
        f2.y = f1.y
        f2.w = node.border_.w  - f1.w
        f2.h = f1.h
    end

    f1 = tools.grid(f1)
    f2 = tools.grid(f2)

    node.left.border_ = tools.cloneFrame(f1)
    node.right.border_ = tools.cloneFrame(f2)
    rescaleBorder(node.left, canvas)
    rescaleBorder(node.right, canvas)
end

pkg.rescaleBorder = rescaleBorder


return pkg
