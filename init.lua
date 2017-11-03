local events = hs.uielement.watcher
local eventtap = require("hs.eventtap")

tree = dofile( os.getenv("HOME") .. "/.hammerspoon/tree.lua")


windowList = {}
focusedWindowID = -1
borderList = {}

draw_border = function ()
end

local gBorder = nil

local function create_window_border(frame)
    local border = hs.drawing.rectangle(hs.geometry.rect(frame))
    border:setFill(false)
    border:setStrokeWidth(5)
    border:setStrokeColor({["red"]=1,["blue"]=0,["green"]=1,["alpha"]=0.9})

    return border
end

local function init_border()
    gBorder = hs.drawing.rectangle(hs.geometry.rect(0,0,0,0))
    gBorder:setFill(false)
    gBorder:setStrokeWidth(3)
    gBorder:setStrokeColor({["red"]=1,["blue"]=0,["green"]=0,["alpha"]=0.3})
end

init_border()

lock = 0


local events = hs.uielement.watcher

watchers = {}

function init()
  appsWatcher = hs.application.watcher.new(handleGlobalAppEvent)
  appsWatcher:start()

  -- Watch any apps that already exist
  local apps = hs.application.runningApplications()
  for i = 1, #apps do
      if apps[i]:name() ~= "Hammerspoon" then
          watchApp(apps[i], true)
      end
  end
end

function handleGlobalAppEvent(name, event, app)
  if  event == hs.application.watcher.launched then
    watchApp(app)
  elseif event == hs.application.watcher.terminated then
    -- Clean up
    local appWatcher = watchers[app:pid()]
    if appWatcher then
      appWatcher.watcher:stop()

      for id, watcher in pairs(appWatcher.windows) do
        watcher:stop()
      end
      watchers[app:pid()] = nil
    end
  end
  hs.timer.doAfter(0, draw_border)
  return false
end

function watchApp(app, initializing)
  if watchers[app:pid()] then return end

  local watcher = app:newWatcher(handleAppEvent)
  watchers[app:pid()] = {watcher = watcher, windows = {}}

  watcher:start({events.windowCreated, events.focusedWindowChanged, events.mainWindowChanged, events.titleChanged})

  -- Watch any windows that already exist
  for i, window in pairs(app:allWindows()) do
    watchWindow(window, initializing)
  end
end

function handleAppEvent(element, event)
  if event == events.windowCreated then
    watchWindow(element)
  elseif event == events.focusedWindowChanged then
    -- Handle window change
  end
  hs.timer.doAfter(0, draw_border)
  return false
end

function watchWindow(win, initializing)
  local appWindows = watchers[win:application():pid()].windows
  if  win:isStandard() and not appWindows[win:id()] and win:application():name() ~= "Hammerspoon" then
    local watcher = win:newWatcher(handleWindowEvent, {pid=win:pid(), id=win:id()})
    appWindows[win:id()] = watcher

    watcher:start({events.elementDestroyed})

    if not initializing then
    end
  end
end

function handleWindowEvent(win, event, watcher, info)
  if event == events.elementDestroyed then
    watcher:stop()
    watchers[info.pid].windows[info.id] = nil
    local funt = function ()
        tree.deleteWindowFromTree(root, win:id())
        hs.timer.doAfter(0, window_manager)
    end
    hs.timer.doAfter(0, funt)
  else
    -- Handle other events...
  end
  hs.timer.doAfter(0, draw_border)
  return false
end

init()


function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end


function space_manager() 
    gBorder:delete()
    init_border()
    hs.timer.doAfter(0, draw_border)
    return false
end

local spaceWatcher = hs.spaces.watcher.new(space_manager)
spaceWatcher:start()

root = tree.initTreeforWorkSpace(30)


function window_manager(t) 

    if t == "timer" then
        local tm = function ()
            window_manager("timer")
        end
        hs.timer.doAfter(10, tm)
    end

    local function compare(a,b)
        return a:id() < b:id()
    end
	local ws = hs.window.visibleWindows()

    table.sort(ws, compare)

    local mmm = {}
    tree.travelTree(root, mmm)

    local father = tree.findFatherOfNode(root, focusedWindowID)

    local mm = {}
    for i = 1, #ws do
        local w = ws[i]
        if w:application():name() ~= "Hammerspoon" and w:isStandard() then
            if not mmm[w:id()] then
                if father == nil then
                    tree.insertToTree(root, w)
                else
                    if father.left.windowId == focusedWindowID then
                        tree.insertToNode(father.left, w)
                    else
                        tree.insertToNode(father.right, w)
                    end

                    if father.left == nil then
                    end
                end
            end
            mm[w:id()] = ws[i]
        end
    end


    tree.deleteZombies(root, mm)
    tree.deleteWindowFromTree(root, -1)


    local dic = {}
    tree.travelTreeAndTiling(root, dic, 10)

    local screen = hs.screen.allScreens()[1]:name()

    for i  = 1, #ws do 
        local w = ws[i]
        if dic[w:id()] then
            local f = function()
                w:setFrame(dic[w:id()])
            end
            hs.timer.doAfter(0, f)
        end
    end

    local fw = hs.window.focusedWindow()
    if fw ~= nil then
        focusedWindowID = fw:id()
    else
        focusedWindowID = -1
    end

    local f = function()
        if (not fw) or (not fw:isStandard()) then
            gBorder:hide()
        else
            local frame = fw:frame()
            gBorder:setFrame(frame)
            gBorder:show()
        end
    end
    hs.timer.doAfter(0, f)
end

draw_border = function()
    hs.timer.doAfter(0, window_manager)
end

hs.window.animationDuration = 0.0

draw_border()

local function swap(father)
    local left_frame = nil
    local right_frame = nil
    
    if father.left ~= nil then
        left_frame = tree.cloneFrame(father.left.frame)
    end

    if father.right ~= nil then
        right_frame = tree.cloneFrame(father.right.frame)
    end

    tree.retilingNodeWithFrame(father.right, left_frame)
    tree.retilingNodeWithFrame(father.left, right_frame)

    local tmp = father.left
    father.left = father.right
    father.right = tmp
    hs.timer.doAfter(0, window_manager)

    local t = father.left.border
    father.left.border = father.right.border
    father.right.border = t
end

function swap_hv()
    if focusedWindowID == nil then 
        return
    end
    local father = tree.findFatherOfNode(root, focusedWindowID)

    if father == nil then
        return
    end

    father.isDividedHorizontal = not father.isDividedHorizontal
    tree.retilingNodeWithFrame(father, tree.cloneFrame(father.frame))
    hs.timer.doAfter(0, window_manager)
end

function swap_x()
    if focusedWindowID == nil then 
        return
    end
    local father = tree.findFatherOfNode(root, focusedWindowID)
    if father.isDividedHorizontal == true then
        swap(father)
    else
        local grandpa = tree.fatherOfNode(root, father)
        if grandpa == nil then
            return 
        end
        if grandpa.isDividedHorizontal == true then
            swap(grandpa)
        end
    end
end

function swap_y()
    if focusedWindowID == nil then 
        return
    end
    local father = tree.findFatherOfNode(root, focusedWindowID)
    if father.isDividedHorizontal == false then
        swap(father)
    else
        local grandpa = tree.fatherOfNode(root, father)
        if grandpa == nil then
            return 
        end
        if grandpa.isDividedHorizontal == false then
            swap(grandpa)
        end
    end
end


hs.hotkey.bind({"alt"}, "y", function()
    hs.timer.doAfter(0, swap_y)
end )

hs.hotkey.bind({"alt"}, "x", function()
    hs.timer.doAfter(0, swap_x)
end )

hs.hotkey.bind({"alt"}, "r", function()
    hs.timer.doAfter(0, swap_hv)
end )


mouseCircle = nil
mouseCircleTimer = nil

function mouseHighlight()
    -- Delete an existing highlight if it exists
    if mouseCircle then
        mouseCircle:delete()
        if mouseCircleTimer then
            mouseCircleTimer:stop()
        end
    end
    -- Get the current co-ordinates of the mouse pointer
    mousepoint = hs.mouse.getAbsolutePosition()
    -- Prepare a big red circle around the mouse pointer
    mouseCircle = hs.drawing.circle(hs.geometry.rect(mousepoint.x-40, mousepoint.y-40, 80, 80))
    mouseCircle:setStrokeColor({["red"]=1,["blue"]=0,["green"]=0,["alpha"]=1})
    mouseCircle:setFill(false)
    mouseCircle:setStrokeWidth(5)
    mouseCircle:show()

    -- Set a timer to delete the circle after 3 seconds
    mouseCircleTimer = hs.timer.doAfter(3, function() mouseCircle:delete() end)
end

window_manager("timer")


mouse_loc = nil
cur_node = nil
new_node = nil


disableClick = false
isSwap = false
isResize = false

local ppp = function(ev)
    local result = ev:getFlags().ctrl
    for k,v in pairs(ev:getFlags()) do
        if k ~= "ctrl" and v then
            result = false
            break
        end
    end

    if result then
        disableClick = true
    end

    if (ev:getType() == hs.eventtap.event.types.flagsChanged and not result) or
        ev:getType() == hs.eventtap.event.types.leftMouseUp or 
        ev:getType() == hs.eventtap.event.types.rightMouseUp then

        disableClick = false

        if isSwap then
            isSwap = false
            tree.travelAndHideBorder(root)

            if cur_node ~= nil and new_node ~= nil and cur_node ~= new_node then
                local t = cur_node.windowId
                cur_node.windowId = new_node.windowId
                new_node.windowId = t
                hs.timer.doAfter(0, window_manager)
            end

            cur_node = nil
            new_node = nil
        end

        if isResize then
            isResize = false
            tree.convertFromBorderToFrame(root)
            hs.timer.doAfter(0, window_manager)
            cur_node = nil
            new_node = nil
        end
    end

    if result then
        if ev:getType() == hs.eventtap.event.types.rightMouseDown then
            isResize = true
            tree.travelAndShowBorder(root, create_window_border)
            mouse_loc = hs.mouse.getAbsolutePosition()
            -- tree.travelAndShowBorder(root, create_window_border)
            cur_node = tree.findNodewithPointer(root, mouse_loc)


            for i, appWatcher in pairs(watchers) do
               if appWatcher then
                  for id, watcher in pairs(appWatcher.windows) do
                    watcher:stop()
                  end
               end
            end

            return true
        end

    end


    if result then
        if ev:getType() == hs.eventtap.event.types.leftMouseDown then
            isSwap = true
            mouse_loc = hs.mouse.getAbsolutePosition()
            -- tree.travelAndShowBorder(root, create_window_border)
            cur_node = tree.findNodewithPointer(root, mouse_loc)
            if cur_node ~= nil then
                cur_node.border = create_window_border(cur_node.frame)
                cur_node.border:show()
            end

            return true
        else
            if ev:getType() == hs.eventtap.event.types.rightMouseDragged then
                local ml = hs.mouse.getAbsolutePosition()
                local dx = ml.x - mouse_loc.x
                local dy = ml.y - mouse_loc.y
                tree.resizeNode(root, cur_node, dx, dy)
                return false
            end

            if ev:getType() == hs.eventtap.event.types.leftMouseDragged then
            local ml = hs.mouse.getAbsolutePosition()
            local temp_new_node = new_node
            new_node = tree.findNodewithPointer(root, ml)
            if new_node == cur_node and temp_new_node ~= cur_node and temp_new_node ~= nil and temp_new_node.border ~= nil then
                temp_new_node.border:delete()
                temp_new_node.border = nil
            end
            if new_node ~= nil and new_node ~= cur_node then
                if temp_new_node ~= nil and temp_new_node.border ~= nil and temp_new_node ~= new_node and temp_new_node ~= cur_node then
                    temp_new_node.border:delete()
                    temp_new_node.border = nil
                end

                if new_node.border ~= nil then
                    new_node.border:setFrame(new_node.frame)
                else
                    new_node.border = create_window_border(new_node.frame)
                end
                new_node.border:show()
            end
            local dx = ml.x - mouse_loc.x
            local dy = ml.y - mouse_loc.y
            return false
            end
        end
        return false
    end

    return false
end
--
-- verify that *only* the ctrl key flag is being pressed
function onlyShiftCmd(ev)

    hs.timer.doAfter(0, function()
        ppp(ev)
    end)

    if disableClick then
        if ev:getType() == hs.eventtap.event.types.leftMouseDown or
        ev:getType() == hs.eventtap.event.types.rightMouseDown then
            return true
        end
    end
    return false 
end


ttt = hs.eventtap.event.types
resizeWatcher = hs.eventtap.new({ttt.flagsChanged, ttt.keyDown, ttt.keyUp, ttt.leftMouseDown, ttt.leftMouseDragged, ttt.rightMouseDragged, ttt.leftMouseUp, ttt.rightMouseDown, ttt.rightMouseUp}, onlyShiftCmd)

resizeWatcher:start()

function moveFocuses(direction)
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

hs.hotkey.bind({"shift"}, "Right", function()
    hs.timer.doAfter(0, function () moveFocuses("right") end)
end )

hs.hotkey.bind({"shift"}, "Left", function()
    hs.timer.doAfter(0, function() moveFocuses("left") end)
end )

hs.hotkey.bind({"shift"}, "Down", function()
    hs.timer.doAfter(0, function() moveFocuses("down") end)
end )

hs.hotkey.bind({"shift"}, "Up", function()
    hs.timer.doAfter(0, function() moveFocuses("up") end)
end )
