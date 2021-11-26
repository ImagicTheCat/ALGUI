-- https://github.com/ImagicTheCat/ALGUI
-- MIT license (see LICENSE or src/ALGUI/GUI.lua)

local class = require("Luaoop").class
local bGUI = require("ALGUI.GUI")

-- A basic GUI implementation with events, widget focus, etc.
local GUI = class("GUI", bGUI)

-- Get overed widgets, i.e. widgets crossed at the pointer position.
-- (recursive)
--
-- list: output list of crossed widgets (from shallowest to deepest)
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
-- Emits "focus-transition" on GUI and "focus-update" on old/new focused widgets.
-- widget: (optional) nil to clear focus
-- focus-transition: old, new
-- focus-update: boolean state
function GUI:setFocus(widget)
  if self.focus ~= widget then
    self:emit("focus-transition", self.focus, widget)
    if self.focus then self.focus:emit("focus-update", false) end
    if widget then widget:emit("focus-update", true) end
    self.focus = widget
  end
end

-- Common events interface

-- Dispatch spatial event with down -> target (up) -> up traversal.
-- callback(widget, phase): called for each crossed widget
--- phase: "up", "down"
-- return list of overed widgets
local function dispatchSpatialEvent(widget, x, y, callback)
  local overeds = {}; getOveredWidgets(overeds, widget, x, y)
  -- down phase
  for i=1, #overeds-1 do callback(overeds[i], "down") end
  -- up phase
  for i=#overeds, 1, -1 do callback(overeds[i], "up") end
  return overeds
end

-- A spatial event is propagated by crossing widgets at a specific position,
-- from the shallowest to the deepest widget, known as the down phase, then
-- backwards, known as the up phase.
--
-- The deepest widget, also known as the target, only receives the up phase event.
--
-- Down phase events have the ":down" suffix to their identifier.
--
-- A unique state is shared among the events to implement a capture behavior by
-- checking/setting the `captured` field flag.

-- Emit "pointer-click" spatial event.
-- pointer-click: id, x, y, button, n, state
function GUI:emitPointerClick(id, x, y, button, n)
  local state = {}
  dispatchSpatialEvent(self, x, y, function(widget, phase)
    widget:emit(phase == "up" and "pointer-click" or "pointer-click:down",
      id, x-widget.tx, y-widget.ty, button, n, state)
  end)
end

-- Emit "pointer-press" spatial event.
-- pointer-press: id, x, y, button, n, state
function GUI:emitPointerPress(id, x, y, button, n)
  -- Update pointer's pressed widgets and emit event.
  local pressed = self.pointers_pressed[id]
  if not pressed then pressed = {}; self.pointers_pressed[id] = pressed end
  local state = {}
  local overeds = dispatchSpatialEvent(self, x, y, function(widget, phase)
    widget:emit(phase == "up" and "pointer-press" or "pointer-press:down",
      id, x-widget.tx, y-widget.ty, button, n, state)
  end)
  for _, widget in ipairs(overeds) do pressed[widget] = true end
end

-- Emit "pointer-release" and "pointer-click" (on previously pressed widgets) spatial events.
-- pointer-release: id, x, y, button, state
-- pointer-click: id, x, y, button, n, state
function GUI:emitPointerRelease(id, x, y, button)
  local list = {}; getOveredWidgets(list, self, x, y)
  local pressed = self.pointers_pressed[id]
  local release_state, click_state = {}, {}
  dispatchSpatialEvent(self, x, y, function(widget, phase)
    -- release event
    widget:emit(phase == "up" and "pointer-release" or "pointer-release:down",
      id, x-widget.tx, y-widget.ty, button, release_state)
    -- pressed event
    if pressed and pressed[widget] then
      widget:emit(phase == "up" and "pointer-click" or "pointer-click:down",
        id, x-widget.tx, y-widget.ty, button, 1, click_state)
    end
  end)
  self.pointers_pressed[id] = nil
end

-- Emit "pointer-wheel" spatial event.
-- pointer-wheel: id, x, y, wx, wy, state
function GUI:emitPointerWheel(id, x, y, wx, wy)
  local state = {}
  dispatchSpatialEvent(self, x, y, function(widget, phase)
    widget:emit(phase == "up" and "pointer-wheel" or "pointer-wheel:down",
      id, x-widget.tx, y-widget.ty, wx, wy, state)
  end)
end

-- Emit "pointer-move" spatial event.
-- Also emits "pointer-enter" and "pointer-leave".
--
-- pointer-move: id, x, y, dx, dy, state
-- pointer-enter/leave: id
function GUI:emitPointerMove(id, x, y, dx, dy)
  -- emit move event
  local state = {}
  local overeds = dispatchSpatialEvent(self, x, y, function(widget, phase)
    widget:emit(phase == "up" and "pointer-move" or "pointer-move:down",
      id, x-widget.tx, y-widget.ty, dx*widget.tscale, dy*widget.tscale, state)
  end)
  -- emit enter/leave events
  local old_set = self.pointers_overed[id] or {}
  local set = {}; for _, widget in ipairs(overeds) do set[widget] = true end
  --- enter
  for widget in pairs(set) do
    if not old_set[widget] then widget:emit("pointer-enter", id) end
  end
  --- leave
  for widget in pairs(old_set) do
    if not set[widget] then widget:emit("pointer-leave", id) end
  end
  self.pointers_overed[id] = set
end

-- Emit "key-press" on GUI and focused widget.
-- key-press: keycode, scancode, repeated
function GUI:emitKeyPress(keycode, scancode, repeated)
  self:emit("key-press", keycode, scancode, repeated)
  if self.focus then self.focus:emit("key-press", keycode, scancode, repeated) end
end

-- Emit "key-release" on GUI and focused widget.
-- key-release: keycode, scancode
function GUI:emitKeyRelease(keycode, scancode)
  self:emit("key-release", keycode, scancode)
  if self.focus then self.focus:emit("key-release", keycode, scancode) end
end

-- Emit "text-input" on GUI and focused widget.
-- text-input: text
function GUI:emitTextInput(text)
  self:emit("text-input", text)
  if self.focus then self.focus:emit("text-input", text) end
end

return GUI
