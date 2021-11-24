package.path = "src/?.lua;"..package.path

class = require("Luaoop").class
xtype = require("xtype")

local GUI = require("ALGUI.ext.GUI")
local Renderer = require("Renderer")
local widgets = require("widgets")

local gui, renderer

local function button_click(widget, self, id, x, y, button, n)
  widget:setText("B"..tostring(button))
end

function love.load()
  gui = GUI()
  gui:setSize(love.graphics.getDimensions())
  renderer = Renderer()
  gui:bind(renderer)
  -- events
  gui:listenAll(print)
  local gui_drag = false
  gui:listen("pointer-press", function() gui_drag = true end)
  gui:listen("pointer-release", function() gui_drag = false end)
  gui:listen("pointer-move", function(self, event, id, x, y, dx, dy)
    if gui_drag then
      self:setInnerShift(self.ix+dx/self.zoom, self.iy+dy/self.zoom)
    end
  end)
  gui:listen("pointer-wheel", function(self, event, id, x, y, wx, wy)
    gui:setInnerZoom(gui.zoom*math.pow(1.25, wy))
  end)
  -- layout
  local flow = widgets.FlowLayout()
  flow:setSize(gui.w, 0)
  flow:setMargin(5)
  for i=1,1500 do
    local button = widgets.Button({{1,1,1}, i})
    button:setSize(100+math.random(-20,20), 25+math.random(-5,5))
    button:listen("pointer-click", button_click)
    flow:add(button)
  end
  gui:add(flow)
end

function love.update(dt)
  gui:tick()
end

function love.draw()
  renderer:render()
end

function love.keypressed(kcode, scode, isrepeat)
  gui:emitKeyPress(kcode, scode, isrepeat)
end

function love.keyreleased(kcode, scode)
  gui:emitKeyRelease(kcode, scode)
end

function love.textinput(text)
  gui:emitTextInput(text)
end

function love.mousepressed(x, y, button, istouch, presses)
  gui:emitPointerPress((istouch and 1 or 0), x, y, button, presses)
end

function love.mousereleased(x, y, button, istouch)
  gui:emitPointerRelease((istouch and 1 or 0), x, y, button)
end

function love.mousemoved(x, y, dx, dy, istouch)
  gui:emitPointerMove((istouch and 1 or 0), x, y, dx, dy)
end

function love.wheelmoved(x,y)
  local mx, my = love.mouse.getPosition()
  gui:emitPointerWheel(0, mx, my, x, y)
end
