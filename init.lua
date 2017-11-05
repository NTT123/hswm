local hswm = {} 

local GLOBAL = {}

GLOBAL.root = nil
GLOBAL.global_padding = 40
GLOBAL.window_padding = 5

hs.window.animationDuration = 0.0

-- local tree = dofile( os.getenv("HOME") .. "/.hammerspoon/tree.lua")
-- local border = dofile( os.getenv("HOME") .. "/.hammerspoon/border.lua")
-- local tools = dofile( os.getenv("HOME") .. "/.hammerspoon/tools.lua")

hswm.window_handlers = dofile( os.getenv("HOME") .. "/.hammerspoon/window.lua")
hswm.window_handlers.init(GLOBAL)

hswm.keyboard_handlers = dofile( os.getenv("HOME") .. "/.hammerspoon/keyboard.lua")
hswm.keyboard_handlers.init(GLOBAL, hswm.window_handlers.window_manager)

hswm.GLOBAL = GLOBAL

return hswm
