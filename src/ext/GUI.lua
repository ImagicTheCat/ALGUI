local class = require("Luaoop").class
local GUI = require("ALGUI.GUI")

local table_insert = table.insert

-- A basic GUI implementation with events/widget focus/etc.
local eGUI = class("GUI", GUI)

-- overed widgets are the last pointer matching widgets displayed in a widget's content
-- x,y: inner content coordinates of widget's parent
-- scale: (optional) absolute scale for current widget
-- return true if the widget is a match
local function get_overed_widgets(list, widget, x, y, scale)
  if not scale then scale = 1 end

  if x >= widget.x and y >= widget.y and x <= widget.x+widget.w and y <= widget.y+widget.h then
    -- append widget's relative x,y and absolute scale
    table_insert(list, {widget, x-widget.x, y-widget.y, scale})

    if widget.draw_list then
      -- compute widget's inner content absolute scale and x,y coordinates
      x,y,scale = (x-widget.x)/widget.zoom-widget.ix, (y-widget.y)/widget.zoom-widget.iy, scale*widget.zoom
      for i=#widget.draw_list,1,-1 do
        if get_overed_widgets(list, widget.draw_list[i], x, y, scale) then break end -- stop on first match
      end
    end

    return true
  else
    return false
  end
end

-- METHODS

function eGUI:__construct()
  GUI.__construct(self)
  -- self.focus

  self.pointers_pressed = {} -- map of id => map of widgets
  self.pointers_overed = {} -- map of id => map of widgets
end

-- should return time since an arbitrary referential
function eGUI:getTime()
  return 0
end

-- set GUI focus
-- trigger "focus_change" on old/new focused widgets
-- widget: can be nil
function eGUI:setFocus(widget)
  if self.focus ~= widget then
    if self.focus then self.focus:trigger("focus_change", false) end
    self.focus = widget
    if widget then widget:trigger("focus_change", true) end
  end
end

-- some event triggers

-- trigger "tick" on GUI
function eGUI:triggerTick(dt)
  self:trigger("tick", dt)
end

-- trigger "pointer_click" on all overed widgets
function eGUI:triggerPointerClick(id, x, y, code, n)
  self:update()
  local list = {}
  get_overed_widgets(list, self, x, y)
  for _, entry in ipairs(list) do
    entry[1]:trigger("pointer_click", id, entry[2], entry[3], code, n)
  end
end

-- trigger "pointer_press" on all overed widgets
function eGUI:triggerPointerPress(id, x, y, code)
  self:update()
  local list = {}
  get_overed_widgets(list, self, x, y)

  -- update pointer's pressed widgets
  local pressed = {}
  for _, entry in ipairs(list) do pressed[entry[1]] = true end
  self.pointers_pressed[id] = pressed

  -- trigger event
  for _, entry in ipairs(list) do
    entry[1]:trigger("pointer_press", id, entry[2], entry[3], code)
  end
end

-- trigger "pointer_release" on previously pressed widgets
-- also trigger "pointer_click" on previously pressed and still overed widgets
function eGUI:triggerPointerRelease(id, x, y, code)
  self:update()
  local list = {}
  get_overed_widgets(list, self, x, y)

  local pressed = self.pointers_pressed[id]
  if pressed then
    -- trigger release event
    for widget in pairs(pressed) do
      widget:trigger("pointer_release", id, code)
    end

    -- trigger click event
    for _, entry in ipairs(list) do
      if pressed[entry[1]] then
        entry[1]:trigger("pointer_click", id, entry[2], entry[3], code, 1)
      end
    end

    self.pointers_pressed[id] = nil
  end
end

-- trigger "pointer_wheel" on all overed widgets
function eGUI:triggerPointerWheel(id, x, y, amount)
  self:update()
  local list = {}
  get_overed_widgets(list, self, x, y)
  for _, entry in ipairs(list) do
    entry[1]:trigger("pointer_wheel", id, entry[2], entry[3], amount)
  end
end

-- trigger "pointer_move" on all overed widgets
-- also trigger "pointer_enter" and "pointer_leave"
function eGUI:triggerPointerMove(id, x, y, dx, dy)
  self:update()
  local list = {}
  get_overed_widgets(list, self, x, y)

  -- trigger move event
  for _, entry in ipairs(list) do
    entry[1]:trigger("pointer_move", id, entry[2], entry[3], dx*entry[4], dy*entry[4])
  end

  -- trigger enter/leave events
  local old_overed = self.pointers_overed[id] or {}
  local overed = {}
  for _, entry in ipairs(list) do overed[entry[1]] = true end

  --- enter
  for widget in pairs(overed) do
    if not old_overed[widget] then widget:trigger("pointer_enter", id) end
  end

  --- leave
  for widget in pairs(old_overed) do
    if not overed[widget] then widget:trigger("pointer_leave", id) end
  end

  self.pointers_overed[id] = overed
end

-- trigger "key_press" on GUI and focused widget
function eGUI:triggerKeyPress(keycode, scancode, repeated)
  self:trigger("key_press", keycode, scancode, repeated)
  if self.focus then self.focus:trigger("key_press", keycode, scancode, repeated) end
end

-- trigger "key_release" on GUI and focused widget
function eGUI:triggerKeyRelease(keycode, scancode)
  self:trigger("key_release", keycode, scancode)
  if self.focus then self.focus:trigger("key_release", keycode, scancode) end
end

-- trigger "text_input" on GUI and focused widget
function eGUI:triggerTextInput(text)
  self:trigger("text_input", text)
  if self.focus then self.focus:trigger("text_input", text) end
end

return eGUI
