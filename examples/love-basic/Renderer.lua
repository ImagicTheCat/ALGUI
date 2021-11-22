local widgets = require("widgets")

local Renderer = class("LÖVE Renderer")
local wrenders = {}

wrenders[widgets.Button] = function(self, widget)
  if not widget.overed then
    love.graphics.setColor(1,1,1)
    love.graphics.rectangle("line",1,1,widget.w-2,widget.h-2)
    love.graphics.draw(widget.text, widget.w/2-widget.text:getWidth()/2, widget.h/2-widget.text:getHeight()/2)
  else
    love.graphics.setColor(1,1,1)
    love.graphics.rectangle("fill",1,1,widget.w-2,widget.h-2)
    love.graphics.setColor(0,0,0)
    love.graphics.draw(widget.text, widget.w/2-widget.text:getWidth()/2, widget.h/2-widget.text:getHeight()/2)
  end
end

function Renderer:bind(gui) self.gui = gui end

local function recursive_render(self, widget)
  local wr = wrenders[xtype.get(widget)]
  if wr then
    local x, y, scale = widget.tx, widget.ty, widget.tscale
    love.graphics.push()
    love.graphics.translate(x,y)
    love.graphics.scale(scale)
    love.graphics.setScissor(widget.vx*scale+x, widget.vy*scale+y,
      widget.vw*scale, widget.vh*scale)
    wr(self, widget)
    love.graphics.pop()
  end
  -- recursion
  for _, child in ipairs(widget.draw_list) do recursive_render(self, child) end
end

function Renderer:render()
  recursive_render(self, self.gui)
  love.graphics.setScissor()
end

return Renderer
