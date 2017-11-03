
local pkg = {}

local function cloneFrame(frame)
    local f = hs.geometry({x = frame.x, y= frame.y, w= frame.w, h = frame.h})
    return f
end

pkg.cloneFrame = cloneFrame

local function grid(frame)
    local new = cloneFrame(frame)
    new.x = math.ceil(frame.x / 5) * 5
    new.y = math.ceil(frame.y / 5) * 5
    new.w = math.floor(frame.w / 5) * 5
    new.h = math.floor(frame.h / 5) * 5
    return new
end


local function copyNode(fromA, toB)
    toB.frame = fromA.frame
    toB.left  = fromA.left
    toB.right = fromA.right
    toB.isDividedHorizontal = fromA.isDividedHorizontal
    toB.isAvailable = fromA.isAvailable
    toB.windowId = fromA.windowId
end


local function createNode()
    local node = {}
    node.left = nil
    node.right = nil
    node.isDividedHorizontal = false
    node.isAvailable = true
    node.windowId = nil
    node.frame = hs.geometry.rect(0, 0, 0, 0)
    node.floating = false

    return node
end

local function initTreeforWorkSpace(padding)
    local tree = createNode()
    local f = hs.screen.mainScreen():frame()
    
    tree.frame = hs.geometry(f.x + padding, f.y + padding, f.w - 2 * padding, f.h - 2*padding)

    return tree
end

pkg.initTreeforWorkSpace = initTreeforWorkSpace

local function computeWindowFrame(nodeFrame) 
    return nodeFrame
end

local function splitVertical(node, window)
    local leftNode = createNode()
    local rightNode = createNode()

    leftNode.frame = hs.geometry(node.frame.x, node.frame.y, 0.7*node.frame.w, node.frame.h)

    leftNode.windowId = node.windowId
    leftNode.isAvailable = false
    leftNode.isDividedHorizontal = true

    rightNode.frame = hs.geometry(node.frame.x + 0.7*node.frame.w , node.frame.y, 0.3*node.frame.w, node.frame.h)
    rightNode.isAvailable = false
    rightNode.windowId = window:id()
    rightNode.isDividedHorizontal = true

    node.left = leftNode
    node.right = rightNode
    node.windowId = nil
    node.splitHorizontal = false
end

local function splitHorizontal(node, window)
    local leftNode = createNode()
    local rightNode = createNode()
    leftNode.frame = hs.geometry(node.frame.x, node.frame.y, node.frame.w, 0.7*node.frame.h)
    leftNode.windowId = node.windowId
    leftNode.isAvailable = false
    leftNode.isDividedHorizontal = false


    rightNode.frame = hs.geometry(node.frame.x, node.frame.y + 0.7*node.frame.h, node.frame.w, 0.3*node.frame.h )
    rightNode.isAvailable = false
    rightNode.windowId = window:id()
    rightNode.isDividedHorizontal = false

    node.left = leftNode
    node.right = rightNode
    node.windowId = nil
    node.splitHorizontal = true
end

local function heightOfNode(node)
    if node == nil then
        return 0
    else
        local h1 = heightOfNode(node.left)
        local h2 = heightOfNode(node.right)
        if h1 > h2 then
            return h1
        else
            return h2
        end
    end
end

local function insertToNode(node, win)
    if node == nil then 
        return
    end

    if node.isDividedHorizontal then
        splitHorizontal(node, win)
    else
        splitVertical(node, win)
    end
end

pkg.insertToNode = insertToNode


local function insertToTree(root, window) 
    if root.isAvailable then
        root.windowId = window:id()
        root.isAvailable = false
    else
        if root.windowId then
            if root.isDividedHorizontal then
                splitHorizontal(root, window)
            else
                splitVertical(root, window)
            end
        else
            local h1 = heightOfNode(root.left)
            local h2 = heightOfNode(root.right)

            if h1 > h2 then
                insertToTree(root.right, window)
            else
                insertToTree(root.left, window)
            end
        end
    end
end

pkg.insertToTree = insertToTree

local function travelTree(root, dic)
    if root == nil or dic == nil then
        return 
    else
        if root.windowId then
            dic[root.windowId] = 1
        else
            travelTree(root.left, dic)
            travelTree(root.right, dic)
        end
    end
end

pkg.travelTree = travelTree

local function travelTreeAndTiling(root, dic, pad)
    if root == nil then
        return 
    else
        root.frame = grid(root.frame)
        if root.windowId then
            local f = root.frame
            local ff = cloneFrame(root.frame)
            ff.x = ff.x + pad
            ff.y = ff.y + pad
            ff.w = ff.w - 2*pad
            ff.h = ff.h - 2*pad
            dic[root.windowId] = ff
        else
            travelTreeAndTiling(root.left, dic, pad)
            travelTreeAndTiling(root.right, dic, pad)
        end
    end
end

pkg.travelTreeAndTiling = travelTreeAndTiling

local function findFather(root, node)
    if root == nil then
        return nil
    end

    if root.left ~= nil then
        if root.left == node then
            return root
        end
    end

    if root.right ~= nil then
        if root.right == node then
            return root
        end
    end

    local rl = findFather(root.left, node)
    if rl ~= nil then
        return rl
    end

    rl = findFather(root.right, node)
    if rl ~= nil then
        return rl
    end

    return nil
end


local function findFatherOfNode(root, ID)
    if root == nil then
        return nil
    end

    if root.left ~= nil then
        if root.left.windowId == ID then
            return root
        end
    end

    if root.right ~= nil then
        if root.right.windowId == ID then
            return root
        end
    end

    local rl = findFatherOfNode(root.left, ID)
    if rl ~= nil then
        return rl
    end

    rl = findFatherOfNode(root.right, ID)
    if rl ~= nil then
        return rl
    end

    return nil
end

pkg.findFatherOfNode = findFatherOfNode

local function divideFrameHorizontal(frame)
    local rl = {}

    rl[1] = hs.geometry(frame.x, frame.y, frame.w, frame.h *0.7)
    rl[2] = hs.geometry(frame.x, frame.y + frame.h* 0.7, frame.w, frame.h * 0.3)

    return rl
end

local function divideFrameVerical(frame)
    local rl = {}

    rl[1] = hs.geometry(frame.x, frame.y, frame.w *0.7, frame.h)
    rl[2] = hs.geometry(frame.x + frame.w *0.7, frame.y, frame.w * 0.3, frame.h)

    return rl
end

local function retilingNodeWithFrame(node, frame)
    if node == nil then
        return 
    end

    node.frame = cloneFrame(frame)
    if not node.windowId then
        local rl = 1
        if node.isDividedHorizontal then
            rl = divideFrameHorizontal(frame)
        else
            rl = divideFrameVerical(frame)
        end

        retilingNodeWithFrame(node.left, rl[1])
        retilingNodeWithFrame(node.right, rl[2])
    end
end

local function fatherOfNode(root, node)
    if root == nil then 
        return nil
    end

    if root.left == node then
        return root
    end

    if root.right == node then
        return root
    end

    local rl = fatherOfNode(root.left, node)
    if rl ~= nil then
        return rl
    end

    rl = fatherOfNode(root.right, node)
    if rl ~= nil then
        return rl
    end

    return nil
end


pkg.fatherOfNode = fatherOfNode

pkg.retilingNodeWithFrame = retilingNodeWithFrame

pkg.deleteWindowFromTree = function(root, windowID)
    if root.windowId == windowID then
        root = initTreeforWorkSpace(global_padding)
    else
        local father = findFatherOfNode(root, windowID)
        if father == nil then
            return
        end

        local frame = cloneFrame(father.frame)

        if father.left.windowId == windowID then
            father.right.isDividedHorizontal = father.isDividedHorizontal
            retilingNodeWithFrame(father.right, frame)
            copyNode(father.right, father)
        else
            father.left.isDividedHorizontal = father.isDividedHorizontal
            retilingNodeWithFrame(father.left, frame)
            copyNode(father.left, father)
        end
    end
end

local function isInSideFrame(frame, point)
    if frame == nil or point == nil then
        return false
    end

    local dx = point.x - frame.x
    local dy = point.y - frame.y

    if dx > 0 and dx < frame.w and dy > 0 and dy < frame.h then
        return true
    else 
        return false
    end

    return false
end

local function findNodewithPointer(root, point)
    if root == nil then
        return nil
    end

    if not isInSideFrame(root.frame, point) then
        return nil
    end

    if root.windowId then 
        return root
    else
        local rl = findNodewithPointer(root.left, point)
        if rl ~= nil then
            return rl
        end

        rl = findNodewithPointer(root.right, point)
        if rl ~= nil then
            return rl
        end
    end

    return nil
end


pkg.findNodewithPointer = findNodewithPointer

local function rescaleBorder(node) 
    if node == nil then 
        return 
    end
    if node.windowId then
        node.border:show()
        return
    end

    node.left.border:setFrame(node.left.frame)
    node.right.border:setFrame(node.right.frame)

    local f1 = node.left.border:frame()
    local f2 = node.right.border:frame()

    if node.isDividedHorizontal then

        local H = f1.h + f2.h
        local r = f1.h / f2.h
        local delta = node.border:frame().h - H
        local h2 = delta / 2
        local h1 = delta / 2
        f1.h = f1.h + h1
        f1.w = node.border:frame().w
        f1.x = node.border:frame().x
        f1.y = node.border:frame().y

        f2.x = f1.x
        f2.y = f1.y + f1.h
        f2.h = node.border:frame().h - f1.h
        f2.w = f1.w
    else
        local W = f1.w + f2.w
        local r = f1.w / f2.w
        local delta = node.border:frame().w - W
        local w2 = delta / 2
        local w1 = delta / 2

        f1.w = f1.w + w1
        f1.h = node.border:frame().h
        f1.x = node.border:frame().x
        f1.y = node.border:frame().y

        f2.x = f1.x + f1.w
        f2.y = f1.y
        f2.w = node.border:frame().w  - f1.w
        f2.h = f1.h
    end

    f1 = grid(f1)
    f2 = grid(f2)

    node.left.border:setFrame(f1)
    node.right.border:setFrame(f2)
    rescaleBorder(node.left)
    rescaleBorder(node.right)
end

local function resizeNode(root, node, dx, dy)
    if root == nil or node == nil then
        return
    end

    local father = findFather(root, node)

    if father == nil then 
        return
    end

    local f1 = cloneFrame(father.left.frame)
    local f2 = cloneFrame(father.right.frame)


    if not father.isDividedHorizontal then
        f1.w = f1.w + dx
        f2.w = father.frame.w - f1.w
        f2.x = f1.x + f1.w
    else
        f1.h = f1.h + dy
        f2.h = father.frame.h - f1.h
        f2.y = f1.y + f1.h
    end

    
    f1 = grid(f1)
    f2 = grid(f2)

    father.left.border:setFrame(f1)
    father.right.border:setFrame(f2)

    rescaleBorder(father.left)
    rescaleBorder(father.right)
end

pkg.resizeNode = resizeNode


local function deleteZombies(root, winmap) 

    if root == nil then
        return
    end

    if root.left == nil and root.right == nil and not root.windowId then
        root.windowId = -1
    end

    if root.left == nil and root.right == nil then
        return 
    end

    if root.left ~= nil then
        if root.left.windowId and (not winmap[root.left.windowId]) then
            pkg.deleteWindowFromTree(root, root.left.windowId)
        else 
            deleteZombies(root.left, winmap)
        end
    else
        retilingNodeWithFrame(root.right, root.frame)
        if root.right ~= nil then
            root.left = root.right.left
            root.isDividedHorizontal = root.right.isDividedHorizontal
            root.isAvailable = root.right.isAvailable
            root.right = root.right.right
        end
    end

    if root.right ~= nil then
        if root.right.windowId and (not winmap[root.right.windowId]) then
            pkg.deleteWindowFromTree(root, root.right.windowId)
        else 
            deleteZombies(root.right, winmap)
        end
    else
        retilingNodeWithFrame(root.left, root.frame)
        if root.left ~= nil then
            root.right = root.left.right
            root.isDividedHorizontal = root.left.isDividedHorizontal
            root.isAvailable = root.left.isAvailable
            root.left = root.left.left
        end
    end
end


local function convertFromBorderToFrame(root)

    if root == nil then 
        return 
    end

    if root.border ~= nil then
        root.frame = cloneFrame(root.border:frame())
        root.border:delete()
        root.border = nil
    end

    convertFromBorderToFrame(root.left)
    convertFromBorderToFrame(root.right)
end

pkg.convertFromBorderToFrame = convertFromBorderToFrame

local function travelAndShowBorder(root, create_border)
    if root == nil then 
        return
    end

    if not root.border then 
        root.border = create_border(root.frame)
    end

    if root.windowId ~= nil then
        root.border:setFrame(root.frame)
        return
    end

    if root.left ~= nil then
        travelAndShowBorder(root.left, create_border)
    end

    if root.right ~= nil then
        travelAndShowBorder(root.right, create_border)
    end
end

local function travelAndHideBorder(root)
    if root == nil then 
        return
    end

    if root.border ~= nil then
        root.border:delete()
        root.border = nil
        return
    end

    if root.left ~= nil then
        travelAndHideBorder(root.left)
    end

    if root.right ~= nil then
        travelAndHideBorder(root.right)
    end
end

pkg.travelAndShowBorder = travelAndShowBorder
pkg.travelAndHideBorder = travelAndHideBorder

pkg.deleteZombies = deleteZombies

local function findWindow(root)
    if root == nil then
        return nil
    end

    if root.windowId ~= nil and root.windowId ~= -1 then
        return root.windowId
    end

    if root.windowId == -1 then
        return nil
    end


    if root.left.windowId ~= nil then 
        return root.left.windowId
    end

    if root.right.windowId ~= nil then 
        return root.right.windowId
    end

    local rl = findWindow(root.left)
    if rl ~= nil then
        return rl
    end

    rl = findWindow(root.right)
    return rl
end

local function getNextToNode(root, node, direction)
    if root == node then
        return nil
    end

    local father = findFather(root, node)

    if father == nil then
        return
    end
    if father.isDividedHorizontal then
        if direction == "up" and father.right == node then
            return findWindow(father.left)
        end

        if direction == "down" and father.left == node then
            return findWindow(father.right)
        end

    end

    if not father.isDividedHorizontal then
        if direction == "left" and father.right == node then
            return findWindow(father.left)
        end

        if direction == "right" and father.left == node then
            return findWindow(father.right)
        end

    end

    return getNextToNode(root, father, direction)
end
pkg.getNextToNode = getNextToNode

local function getNodeFromWindowID(root, id)
    if root == nil then 
        return nil
    end

    if root.windowId == id then
        return root
    end

    local rl = getNodeFromWindowID(root.left, id)
    if rl ~= nil then
        return rl
    end

    return getNodeFromWindowID(root.right, id)
end

pkg.getNodeFromWindowID = getNodeFromWindowID


return pkg
