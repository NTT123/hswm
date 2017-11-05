local pkg = {}

local tools = dofile( os.getenv("HOME") .. "/.hammerspoon/tools.lua")
local border = dofile( os.getenv("HOME") .. "/.hammerspoon/border.lua")


local function copyNode(fromA, toB)
    toB.frame = fromA.frame
    toB.left  = fromA.left
    toB.right = fromA.right
    toB.isDividedHorizontal = fromA.isDividedHorizontal
    toB.isAvailable = fromA.isAvailable
    toB.windowID = fromA.windowID
end

local function createNode(father)
    local node = {}
    node.left = nil
    node.right = nil
    node.isDividedHorizontal = false
    node.isAvailable = true
    node.windowID = nil
    node.frame = hs.geometry.rect(0, 0, 0, 0)
    node.floating = false
    node.father = father

    return node
end

local function initTreeforWorkSpace(padding)
    local tree = createNode()
    local f = hs.screen.mainScreen():frame()
    
    tree.frame = hs.geometry.rect(f.x + padding, f.y + padding, f.w - 2 * padding, f.h - 2*padding)


    return tree
end

pkg.initTreeforWorkSpace = initTreeforWorkSpace

local function splitVertical(node, window)
    local leftNode = createNode(node)
    local rightNode = createNode(node)

    leftNode.frame = hs.geometry(node.frame.x, node.frame.y, 0.7*node.frame.w, node.frame.h)

    leftNode.windowID = node.windowID
    leftNode.isAvailable = false
    leftNode.isDividedHorizontal = true

    rightNode.frame = hs.geometry(node.frame.x + 0.7*node.frame.w , node.frame.y, 0.3*node.frame.w, node.frame.h)
    rightNode.isAvailable = false
    rightNode.windowID = window:id()
    rightNode.isDividedHorizontal = true

    node.left = leftNode
    node.right = rightNode
    node.windowID = nil
    node.splitHorizontal = false
end

local function splitHorizontal(node, window)
    local leftNode = createNode(node)
    local rightNode = createNode(node)
    leftNode.frame = hs.geometry(node.frame.x, node.frame.y, node.frame.w, 0.7*node.frame.h)
    leftNode.windowID = node.windowID
    leftNode.isAvailable = false
    leftNode.isDividedHorizontal = false


    rightNode.frame = hs.geometry(node.frame.x, node.frame.y + 0.7*node.frame.h, node.frame.w, 0.3*node.frame.h )
    rightNode.isAvailable = false
    rightNode.windowID = window:id()
    rightNode.isDividedHorizontal = false

    node.left = leftNode
    node.right = rightNode
    node.windowID = nil
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

    if node.frame.w > node.frame.h then
        node.isDividedHorizontal = false
    else
        node.isDividedHorizontal = true
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
        root.windowID = window:id()
        root.isAvailable = false
    else
        if root.windowID then
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
        if root.windowID then
            dic[root.windowID] = 1
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
        root.frame = tools.grid(root.frame)
        if root.windowID then
            local f = root.frame
            local ff = tools.cloneFrame(root.frame)
            ff.x = ff.x + pad
            ff.y = ff.y + pad
            ff.w = ff.w - 2*pad
            ff.h = ff.h - 2*pad
            dic[root.windowID] = ff
        else
            travelTreeAndTiling(root.left, dic, pad)
            travelTreeAndTiling(root.right, dic, pad)
        end
    end
end

pkg.travelTreeAndTiling = travelTreeAndTiling


local function findFatherOfNode(root, ID)
    if root == nil then
        return nil
    end

    if root.left ~= nil then
        if root.left.windowID == ID then
            return root
        end
    end

    if root.right ~= nil then
        if root.right.windowID == ID then
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

    node.frame = tools.cloneFrame(frame)
    if not node.windowID then
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

pkg.deleteWindowFromTree = function(root, windowID, global_padding)
    if root == nil then
        return
    end
    if root.windowID == windowID then
        root = initTreeforWorkSpace(global_padding)
    else
        local father = findFatherOfNode(root, windowID)
        if father == nil then
            return
        end

        local frame = tools.cloneFrame(father.frame)

        if father.left.windowID == windowID then
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

    if root.windowID then 
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

local function resizeNode(root, node, dx, dy)


    if root == nil or node == nil then
        return
    end

    local father = node.father

    if father == nil then 
        return
    end

    local grandpa = father.father

    if grandpa ~= nil and grandpa.isDividedHorizontal ~= father.isDividedHorizontal then

        local f1 = tools.cloneFrame(grandpa.left.frame)
        local f2 = tools.cloneFrame(grandpa.right.frame)


        if not grandpa.isDividedHorizontal then
            f1.w = f1.w + dx
            f2.w = grandpa.frame.w - f1.w

            if f2.w < 50 then 
                f2.w = 50
                f1.w = grandpa.frame.w - f2.w
            end

            f2.x = f1.x + f1.w
        else
            f1.h = f1.h + dy
            f2.h = grandpa.frame.h - f1.h

            if f2.h < 50 then
                f2.h = 50
                f1.h = grandpa.frame.h - f2.h
            end

            f2.y = f1.y + f1.h
        end

        grandpa.left.border_ = tools.cloneFrame(f1)
        grandpa.right.border_ = tools.cloneFrame(f2)

        border.rescaleBorder(grandpa.left, root.canvas)
        border.rescaleBorder(grandpa.right, root.canvas)
    end


    local f1 = tools.cloneFrame(father.left.frame)
    local f2 = tools.cloneFrame(father.right.frame)

    if grandpa ~= nil and grandpa.isDividedHorizontal ~= father.isDividedHorizontal then
        f1 = tools.cloneFrame(father.left.border_)
        f2 = tools.cloneFrame(father.right.border_)
    end

    if not father.isDividedHorizontal then
        f1.w = f1.w + dx
        f2.w = father.frame.w - f1.w
        if f2.w < 100 then
            f2.w = 100
            f1.w = father.frame.w - f2.w
        end
        f2.x = f1.x + f1.w
    else
        f1.h = f1.h + dy
        f2.h = father.frame.h - f1.h
        if f2.h < 100 then
            f2.h = 100
            f1.h = father.frame.h - f2.h
        end
        f2.y = f1.y + f1.h
    end

    
    father.left.border_ = tools.cloneFrame(f1)
    father.right.border_ = tools.cloneFrame(f2)

    border.rescaleBorder(father.left, root.canvas)
    border.rescaleBorder(father.right, root.canvas)

end

pkg.resizeNode = resizeNode


local function deleteZombies(root, winmap) 

    if root == nil then
        return
    end

    if root.left == nil and root.right == nil and not root.windowID then
        root.windowID = -1
    end

    if root.left == nil and root.right == nil then
        return 
    end

    if root.left ~= nil then
        if root.left.windowID and (not winmap[root.left.windowID]) then
            pkg.deleteWindowFromTree(root, root.left.windowID)
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
        if root.right.windowID and (not winmap[root.right.windowID]) then
            pkg.deleteWindowFromTree(root, root.right.windowID)
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




pkg.deleteZombies = deleteZombies

local function findWindow(root)
    if root == nil then
        return nil
    end

    if root.windowID ~= nil and root.windowID ~= -1 then
        return root.windowID
    end

    if root.windowID == -1 then
        return nil
    end


    if root.left.windowID ~= nil then 
        return root.left.windowID
    end

    if root.right.windowID ~= nil then 
        return root.right.windowID
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

    local father = node.father

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

    if root.windowID == id then
        return root
    end

    local rl = getNodeFromWindowID(root.left, id)
    if rl ~= nil then
        return rl
    end

    return getNodeFromWindowID(root.right, id)
end

pkg.getNodeFromWindowID = getNodeFromWindowID

local function swap(father)
    local left_frame = nil
    local right_frame = nil
    
    if father.left ~= nil then
        left_frame = tools.cloneFrame(father.left.frame)
    end

    if father.right ~= nil then
        right_frame = tools.cloneFrame(father.right.frame)
    end

    retilingNodeWithFrame(father.right, left_frame)
    retilingNodeWithFrame(father.left, right_frame)

    local tmp = father.left
    father.left = father.right
    father.right = tmp

    local t = father.left.border
    father.left.border = father.right.border
    father.right.border = t
end

local function swap_hv(root)

    local fw = hs.window.focusedWindow()

    local focusedWindowID = nil

    if fw ~= nil then
        focusedWindowID = fw:id()
    else
        return
    end

    if focusedWindowID == nil then 
        return
    end

    local father = findFatherOfNode(root, focusedWindowID)

    if father == nil then
        return
    end

    father.isDividedHorizontal = not father.isDividedHorizontal
    retilingNodeWithFrame(father, tools.cloneFrame(father.frame))
end
pkg.swap_hv = swap_hv

local function swap_x(root)
    local fw = hs.window.focusedWindow()

    local focusedWindowID = nil

    if fw ~= nil then
        focusedWindowID = fw:id()
    else
        return
    end

    if focusedWindowID == nil then 
        return
    end

    local father = findFatherOfNode(root, focusedWindowID)

    if father == nil then 
        return
    end

    if father.isDividedHorizontal == true then
        swap(father)
    else
        local grandpa = fatherOfNode(root, father)
        if grandpa == nil then
            return 
        end
        if grandpa.isDividedHorizontal == true then
            swap(grandpa)
        end
    end
end
pkg.swap_x = swap_x

local function swap_y(root)

    local fw = hs.window.focusedWindow()

    local focusedWindowID = nil

    if fw ~= nil then
        focusedWindowID = fw:id()
    else
        return
    end
    
    if focusedWindowID == nil then 
        return
    end
    
    local father = findFatherOfNode(root, focusedWindowID)
    if father == nil then
        return
    end

    if father.isDividedHorizontal == false then
        swap(father)
    else
        local grandpa = fatherOfNode(root, father)
        if grandpa == nil then
            return 
        end
        if grandpa.isDividedHorizontal == false then
            swap(grandpa)
        end
    end
end

pkg.swap_y = swap_y

pkg.init = function(GLOBAL)
    pkg.GLOBAL = GLOBAL
end


return pkg
