-- https://github.com/ImagicTheCat/ALGUI
-- MIT license (see LICENSE or src/ALGUI/GUI.lua)

local class = require("Luaoop").class
local bGUI = require("ALGUI.GUI")

-- A basic GUI implementation with events, widget focus, etc.
local GUI = class("GUI", bGUI)

-- Get overed widgets, i.e. widgets crossed at the pointer position.
-- (recursive)
--
-- list: output list of widgets
-- x,y: absolute pointer position
-- return true if the widget is a match
local function getOveredWidgets(list, widget, x, y)
  if x >= widget.tx and y >= widget.ty and
      x <= widget.tx+widget.w*widget.tscale and
      y <= widget.ty+widget.h*widget.tscale then
    table.insert(list, widget)
      for i=#widget.draw_list,1,-1 do
        -- stop on first match
        if getOveredWidgets(list, widget.draw_list[i], x, y) then break end
      end
    return true
  else
    return false
  end
end

function GUI:__construct()
  bGUI.__construct(self)
  self.pointers_pressed = {} -- map of id => set of widgets
  self.pointers_overed = {} -- map of id => set of widgets
  -- self.focus
end

-- Set GUI focus.
-- Emits "focus-change" on old/new focused widgets.
-- widget: (optional)
function GUI:setFocus(widget)
  if self.focus ~= widget then
    if self.focus then self.focus:emit("focus-change", false) end
    self.focus = widget
    if widget then widget:emit("focus-change", true) end
  end
end

-- Common events interface

-- Emit "pointer-click" on all overed widgets.
function GUI:emitPointerClick(id, x, y, code, n)
  local list = {}; getOveredWidgets(list, self, x, y)
  for _, widget in ipairs(list) do
    widget:emit("pointer-click", id, x-widget.tx, y-widget.ty, code, n)
  end
end

-- Emit "pointer-press" on all overed widgets.
function GUI:emitPointerPress(id, x, y, code)
  local list = {}; getOveredWidgets(list, self, x, y)
  -- Update pointer's pressed widgets and emit event.
  local pressed = self.pointers_pressed[id]
  if not pressed then pressed = {}; self.pointers_pressed[id] = pressed end
  for _, widget in ipairs(list) do
    pressed[widget] = true
    widget:emit("pointer-press", id, x-widget.tx, y-widget.ty, code)
  end
end

-- Emit "pointer-release" on previously pressed widgets and emit
-- "pointer-click" on previously pressed and still overed widgets.
function GUI:emitPointerRelease(id, x, y, code)
  local list = {}; getOveredWidgets(list, self, x, y)
  local pressed = self.pointers_pressed[id]
  if pressed then
    -- emit release event
    for widget in pairs(pressed) do widget:emit("pointer-release", id, code) end
    -- emit click event
    for _, widget in ipairs(list) do
      if pressed[widget] then
        widget:emit("pointer-click", id, x-widget.tx, y-widget.ty, code, 1)
      end
    end
    self.pointers_pressed[id] = nil
  end
end

-- Emit "pointer-wheel" on all overed widgets.
function GUI:emitPointerWheel(id, x, y, amount)
  local list = {}; getOveredWidgets(list, self, x, y)
  for _, widget in ipairs(list) do
    widget:emit("pointer-wheel", id, x-widget.tx, y-widget.ty, amount)
  end
end

-- Emit "pointer-move" on all overed widgets.
-- Also emits "pointer-enter" and "pointer-leave".
function GUI:emitPointerMove(id, x, y, dx, dy)
  local list = {}; getOveredWidgets(list, self, x, y)
  -- emit move event
  for _, widget in ipairs(list) do
    widget:emit("pointer-move", id, x-widget.tx, y-widget.ty,
      dx*widget.tscale, dy*widget.tscale)
  end
  -- emit enter/leave events
  local old_overed = self.pointers_overed[id] or {}
  local overed = {}; for _, widget in ipairs(list) do overed[widget] = true end
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

-- Emit "key-press" on GUI and focused widget.
function GUI:emitKeyPress(keycode, scancode, repeated)
  self:emit("key-press", keycode, scancode, repeated)
  if self.focus then self.focus:emit("key-press", keycode, scancode, repeated) end
end

-- Emit "key-release" on GUI and focused widget.
function GUI:emitKeyRelease(keycode, scancode)
  self:emit("key-release", keycode, scancode)
  if self.focus then self.focus:emit("key-release", keycode, scancode) end
end

-- Emit "text-input" on GUI and focused widget.
function GUI:emitTextInput(text)
  self:emit("text-input", text)
  if self.focus then self.focus:emit("text-input", text) end
end

return GUI
