-- https://github.com/ImagicTheCat/ALGUI
-- MIT license (see LICENSE or src/ALGUI/GUI.lua)

local utils = {}

-- Return intersection of two rectangles.
function utils.intersect(x1,y1,w1,h1, x2,y2,w2,h2)
  local x,y = math.max(x1,x2), math.max(y1,y2)
  local w,h = math.min(x1+w1,x2+w2)-x, math.min(y1+h1,y2+h2)-y
  if w > 0 and h > 0 then return x,y,w,h else return 0,0,0,0 end
end

return utils
