class = require("Luaoop").class
local GUI = require("ALGUI.ext.GUI")
local Renderer = require("Renderer")
local widgets = require("widgets")

local gui, renderer

local function button_click(button, id, x, y, code, n)
  print("clicked", button, id, x, y, code, n)
  button:setText(code == 1 and "left" or code == 3 and "middle" or code == 2 and "right")
end

function love.load()
  gui = GUI()
  gui:setSize(love.graphics.getDimensions())
  renderer = Renderer()

  local gui_drag = false
  gui:listen("pointer-press", function(self, id, x, y, code)
    gui_drag = true
  end)

  gui:listen("pointer-release", function(self, id, x, y, code)
    gui_drag = false
  end)

  gui:listen("pointer-move", function(self, id, x, y, dx, dy)
    if gui_drag then
      self:setInnerShift(self.ix+dx/self.zoom, self.iy+dy/self.zoom)
    end
  end)

  gui:listen("pointer-wheel", function(self, id, x, y, amount)
    gui:setInnerZoom(gui.zoom*math.pow(1.25,amount))
  end)

  local flow = widgets.FlowLayout()
  flow:setSize(gui.w, 0)
  flow:setMargin(5)

  for i=1,1500 do
    local button = widgets.Button({{1,1,1}, i})
    button:setSize(100+math.random(-20,20),25+math.random(-5,5))
    button:listen("pointer-click", button_click)

    flow:add(button)
  end

  gui:add(flow)
end

function love.draw()
  renderer:render(gui)
end

function love.keypressed(kcode, scode, isrepeat)
  gui:triggerKeyPress(kcode, scode, isrepeat)
end

function love.keyreleased(kcode, scode)
  gui:triggerKeyRelease(kcode, scode)
end

function love.textinput(text)
  gui:triggerTextInput(text)
end

function love.mousepressed(x, y, button, istouch, presses)
  gui:triggerPointerPress((istouch and 1 or 0),x,y,button)
end

function love.mousereleased(x, y, button, istouch, presses)
  gui:triggerPointerRelease((istouch and 1 or 0),x,y,button)
end

function love.mousemoved(x, y, dx, dy, istouch)
  gui:triggerPointerMove((istouch and 1 or 0),x,y,dx,dy)
end

function love.wheelmoved(x,y)
  local mx, my = love.mouse.getPosition()
  gui:triggerPointerWheel(0,mx,my,y)
end
