-- https://github.com/ImagicTheCat/ALGUI
-- MIT license (see LICENSE or src/ALGUI/GUI.lua)
--[[
MIT License

Copyright (c) 2019 ImagicTheCat

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

local table_unpack = table.unpack or unpack

local class = require("Luaoop").class
local Widget = require("ALGUI.Widget")

local GUI = class("GUI", Widget)

function GUI:__construct()
  Widget.__construct(self)

  self.gui = self
  -- sets of dirty widgets
  self.dirties = {layout = {}, view = {}, drawlist = {}, transform = {}}
  self.events = {} -- event queue, list of {widget, event, ...} (packed)
  self.all_listeners = {} -- set of callbacks
  self.renderers = {} -- set of bound renderers
end

function GUI:bind(renderer)
  self.renderers[renderer] = true
  renderer:bind(self)
end

function GUI:unbind(renderer)
  self.renderers[renderer] = nil
  renderer:unbind(self)
end

-- Listen to all widget events.
function GUI:listenAll(callback)
  self.all_listeners[callback] = true
end

function GUI:unlistenAll(callback)
  self.all_listeners[callback] = nil
end

local function sort_dirties(a, b) return a.depth < b.depth end

-- Process events and update GUI data (render, layout, etc).
-- To be integrated into an existing app loop.
--
-- To ensure consistency of computed data between the GUI and Renderer, the
-- state of the GUI should not be modified between the end of a tick and the
-- rendering (emitting events is fine).
function GUI:tick()
  -- process events
  for _, event in ipairs(self.events) do
    local widget, eid = table_unpack(event, 1, 2)
    if widget.gui == self then
      -- all listeners
      for callback in pairs(self.all_listeners) do
        callback(table_unpack(event, 1, event.n))
      end
      -- any listeners
      for callback in pairs(widget.any_listeners) do
        callback(table_unpack(event, 1, event.n))
      end
      -- specific listeners
      local listeners = widget.events_listeners[eid]
      if listeners then
        for callback in pairs(listeners) do
          callback(table_unpack(event, 1, event.n))
        end
      end
    end
  end
  self.events = {} -- clear
  -- process dirties
  --- layout
  while next(self.dirties.layout) do -- process until stable
    -- sort layout dirties by depth
    local s_dirties = {}
    for widget in pairs(self.dirties.layout) do table.insert(s_dirties, widget) end
    table.sort(s_dirties, sort_dirties)
    local next_layout_dirties = {}
    for _, widget in ipairs(s_dirties) do
      self.dirties.layout = {} -- capture dirties
      -- recursive layout update, pass current widget size
      widget:updateLayout(widget.w, widget.h)
      -- only allow up in-chain layout update (depth < current depth)
      for dirty in pairs(self.dirties.layout) do
        if dirty.depth < widget.depth then next_layout_dirties[dirty] = true end
      end
    end
    self.dirties.layout = next_layout_dirties
  end
  --- transform
  if next(self.dirties.transform) then
    -- sort transform dirties by depth
    local s_dirties = {}
    for widget in pairs(self.dirties.transform) do table.insert(s_dirties, widget) end
    table.sort(s_dirties, sort_dirties)
    for _, widget in ipairs(s_dirties) do
      if self.dirties.transform[widget] then widget:updateTransform() end
    end
  end
  --- view
  if next(self.dirties.view) then
    -- sort view dirties by depth
    local s_dirties = {}
    for widget in pairs(self.dirties.view) do table.insert(s_dirties, widget) end
    table.sort(s_dirties, sort_dirties)
    for _, widget in ipairs(s_dirties) do
      if self.dirties.view[widget] then widget:updateView() end
    end
  end
  --- drawlist
  for widget in pairs(self.dirties.drawlist) do widget:updateDrawlist() end
end

return GUI
