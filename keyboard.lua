local pkg = {}

local tree = dofile( os.getenv("HOME") .. "/.hammerspoon/tree.lua")

local function moveFocuses(root, direction)
    local fw = hs.window.focusedWindow()
    if fw ~= nil then
        focusedWindowID = fw:id()
    else
        return
    end
    
    if fw:isStandard() then
        local node = tree.getNodeFromWindowID(root, focusedWindowID)
        if node == nil then
            return
        end

        local id = tree.getNextToNode(root, node, direction)
        if id ~= nil then
            local w = hs.window.get(id)
            if w ~= nil then
                hs.window.focus(w)
            end
        end
        
    end
end


local function init(GLOBAL, window_manager_callback)

    pkg.GLOBAL = GLOBAL

    pkg.right = hs.hotkey.bind({"shift"}, "Right", function()
        hs.timer.doAfter(0, function () 
            moveFocuses(pkg.GLOBAL.root, "right") 
        end)
    end )

    pkg.left = hs.hotkey.bind({"shift"}, "Left", function()
        hs.timer.doAfter(0, function() 
            moveFocuses(pkg.GLOBAL.root, "left") 
        end)
    end )

    pkg.down = hs.hotkey.bind({"shift"}, "Down", function()
        hs.timer.doAfter(0, function() 
            moveFocuses(pkg.GLOBAL.root, "down") 
        end)
    end )

    pkg.up = hs.hotkey.bind({"shift"}, "Up", function()
        hs.timer.doAfter(0, function() 
            moveFocuses(pkg.GLOBAL.root, "up") 
        end)
    end )

    pkg.swapy = hs.hotkey.bind({"alt"}, "y", function()
        hs.timer.doAfter(0, function() 
            tree.swap_y(pkg.GLOBAL.root) 
            window_manager_callback()
        end )
    end )

    pkg.swapx = hs.hotkey.bind({"alt"}, "x", function()
        hs.timer.doAfter(0, function() 
            tree.swap_x(pkg.GLOBAL.root) 
            window_manager_callback()
        end )
    end )

    pkg.swaphv = hs.hotkey.bind({"alt"}, "e", function()
        hs.timer.doAfter(0, function() 
            tree.swap_hv(pkg.GLOBAL.root) 
            window_manager_callback()
        end )
    end )

end

pkg.init = init

return pkg

