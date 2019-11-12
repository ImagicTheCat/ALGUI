local class = require("Luaoop").class

local Renderer = class("Renderer")

function Renderer:render(gui)
  gui:preRender()
end

function Renderer:renderWidget(widget)
end

return Renderer
