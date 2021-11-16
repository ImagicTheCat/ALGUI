-- https://github.com/ImagicTheCat/ALGUI
-- MIT license (see LICENSE or src/ALGUI/GUI.lua)

local class = require("Luaoop").class
local Renderer = require("ALGUI.Renderer")

-- A basic renderer.
local eRenderer = class("Renderer", Renderer)

-- PRIVATE METHODS

-- recursive call
local function render_widget(self,widget,x,y,scale)
  self:renderWidget(widget,x,y,scale)

  if widget.draw_list then -- children
    scale = scale*widget.zoom
    x,y = x+widget.ix*scale, y+widget.iy*scale
    for _, child in ipairs(widget.draw_list) do
      render_widget(
        self,
        child,
        x+scale*child.x,
        y+scale*child.y,
        scale
      )
    end
  end
end

-- METHODS

-- override
-- render widgets in draw order/recursive
function eRenderer:render(gui)
  render_widget(self,gui,gui.x,gui.y,1)
end

-- render a single widget (called in draw order/recursive)
-- x,y: widget absolute GUI position
-- scale: widget absolute GUI scale
function eRenderer:renderWidget(widget,x,y,scale)
end

return eRenderer
