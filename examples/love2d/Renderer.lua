local ALGUI_Renderer = require("ALGUI.ext.Renderer")
local widgets = require("widgets")

local Renderer = class("LÖVE Renderer", ALGUI_Renderer)

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

-- overload
function Renderer:render(gui)
  ALGUI_Renderer.render(self, gui)
  love.graphics.setScissor()
end

-- overload
function Renderer:renderWidget(widget,x,y,scale)
  -- render widget
  local wr = wrenders[class.type(widget)]
  if wr then
    love.graphics.push()
    love.graphics.translate(x,y)
    love.graphics.scale(scale)
    love.graphics.setScissor(widget.vx*scale+x,widget.vy*scale+y,widget.vw*scale,widget.vh*scale)
    wr(self, widget)
    love.graphics.pop()
  end
end

return Renderer
