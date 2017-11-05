local pkg = {}

local function cloneFrame(frame)
    local f = hs.geometry({x = frame.x, y= frame.y, w= frame.w, h = frame.h})
    return f
end

pkg.cloneFrame = cloneFrame

-- rounding up the coordinates in a grid of 10 pixels
local function grid(frame)
    local new = cloneFrame(frame)
    new.x = math.ceil(frame.x / 10) * 10
    new.y = math.ceil(frame.y / 10) * 10
    new.w = math.floor(frame.w / 10) * 10
    new.h = math.floor(frame.h / 10) * 10
    return new
end

pkg.grid = grid

-- for debug 
local function dump(o)
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

pkg.dump = dump

return pkg

