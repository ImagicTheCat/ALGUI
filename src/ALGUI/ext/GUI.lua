-- https://github.com/ImagicTheCat/ALGUI
-- MIT license (see LICENSE or src/ALGUI/GUI.lua)

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

-- set GUI focus
-- emit "focus_change" on old/new focused widgets
-- widget: can be nil
function eGUI:setFocus(widget)
  if self.focus ~= widget then
    if self.focus then self.focus:emit("focus-change", false) end
    self.focus = widget
    if widget then widget:emit("focus-change", true) end
  end
end

-- some event emits

-- emit "pointer_click" on all overed widgets
function eGUI:emitPointerClick(id, x, y, code, n)
  local list = {}
  get_overed_widgets(list, self, x, y)
  for _, entry in ipairs(list) do
    entry[1]:emit("pointer-click", id, entry[2], entry[3], code, n)
  end
end

-- emit "pointer_press" on all overed widgets
function eGUI:emitPointerPress(id, x, y, code)
  local list = {}
  get_overed_widgets(list, self, x, y)

  -- update pointer's pressed widgets
  local pressed = {}
  for _, entry in ipairs(list) do pressed[entry[1]] = true end
  self.pointers_pressed[id] = pressed

  -- emit event
  for _, entry in ipairs(list) do
    entry[1]:emit("pointer-press", id, entry[2], entry[3], code)
  end
end

-- emit "pointer_release" on previously pressed widgets
-- also emit "pointer_click" on previously pressed and still overed widgets
function eGUI:emitPointerRelease(id, x, y, code)
  local list = {}
  get_overed_widgets(list, self, x, y)

  local pressed = self.pointers_pressed[id]
  if pressed then
    -- emit release event
    for widget in pairs(pressed) do
      widget:emit("pointer-release", id, code)
    end

    -- emit click event
    for _, entry in ipairs(list) do
      if pressed[entry[1]] then
        entry[1]:emit("pointer-click", id, entry[2], entry[3], code, 1)
      end
    end

    self.pointers_pressed[id] = nil
  end
end

-- emit "pointer_wheel" on all overed widgets
function eGUI:emitPointerWheel(id, x, y, amount)
  local list = {}
  get_overed_widgets(list, self, x, y)
  for _, entry in ipairs(list) do
    entry[1]:emit("pointer-wheel", id, entry[2], entry[3], amount)
  end
end

-- emit "pointer_move" on all overed widgets
-- also emit "pointer_enter" and "pointer_leave"
function eGUI:emitPointerMove(id, x, y, dx, dy)
  local list = {}
  get_overed_widgets(list, self, x, y)

  -- emit move event
  for _, entry in ipairs(list) do
    entry[1]:emit("pointer-move", id, entry[2], entry[3], dx*entry[4], dy*entry[4])
  end

  -- emit enter/leave events
  local old_overed = self.pointers_overed[id] or {}
  local overed = {}
  for _, entry in ipairs(list) do overed[entry[1]] = true end

  --- enter
  for widget in pairs(overed) do
    if not old_overed[widget] then widget:emit("pointer-enter", id) end
  end

  --- leave
  for widget in pairs(old_overed) do
    if not overed[widget] then widget:emit("pointer-leave", id) end
  end

  self.pointers_overed[id] = overed
end

-- emit "key_press" on GUI and focused widget
function eGUI:emitKeyPress(keycode, scancode, repeated)
  local focus = self.focus
  self:emit("key-press", keycode, scancode, repeated)
  if focus then focus:emit("key-press", keycode, scancode, repeated) end
end

-- emit "key_release" on GUI and focused widget
function eGUI:emitKeyRelease(keycode, scancode)
  local focus = self.focus
  self:emit("key-release", keycode, scancode)
  if focus then focus:emit("key-release", keycode, scancode) end
end

-- emit "text_input" on GUI and focused widget
function eGUI:emitTextInput(text)
  local focus = self.focus
  self:emit("text-input", text)
  if focus then focus:emit("text-input", text) end
end

return eGUI
