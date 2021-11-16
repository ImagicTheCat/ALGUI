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

-- PRIVATE STATICS

local function sort_dirties(a, b)
  return a.depth < b.depth
end

-- METHODS

function GUI:__construct()
  Widget.__construct(self)

  self.gui = self
  self.layout_dirties = {} -- map of widget
  self.view_dirties = {} -- map of widget
  self.draw_dirties = {} -- map of widget
  self.events = {} -- event queue, list of {widget, event, ...} (packed)
  self.all_listeners = {} -- set of callbacks
end

-- Listen to all widget events.
function GUI:listenAll(callback)
  self.all_listeners[callback] = true
end

function GUI:unlistenAll(callback)
  self.all_listeners[callback] = nil
end

-- override
function GUI:setSize(w,h)
  Widget.setSize(self, w,h)
  self.vw, self.vh = w,h
end

-- Process events and update GUI data (render, layout, etc).
-- To be integrated into an existing app loop.
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
  -- layout dirties
  while next(self.layout_dirties) do -- process until stable
    -- sort layout dirties by depth
    local s_dirties = {}
    for widget in pairs(self.layout_dirties) do table.insert(s_dirties, widget) end
    table.sort(s_dirties, sort_dirties)
    local next_layout_dirties = {}
    for _, widget in ipairs(s_dirties) do
      self.layout_dirties = {} -- capture dirties
      -- recursive layout update, pass current widget size
      widget:updateLayout(widget.w, widget.h)
      -- only allow up in-chain layout update (depth < current depth)
      for dirty in pairs(self.layout_dirties) do
        if dirty.depth < widget.depth then next_layout_dirties[dirty] = true end
      end
    end
    self.layout_dirties = next_layout_dirties
  end
  -- view dirties
  if next(self.view_dirties) then
    -- sort view dirties by depth
    local s_dirties = {}
    for widget in pairs(self.view_dirties) do table.insert(s_dirties, widget) end
    table.sort(s_dirties, sort_dirties)
    for _, widget in ipairs(s_dirties) do
      if self.view_dirties[widget] then widget:updateView() end
    end
  end
  -- draw dirties
  for widget in pairs(self.draw_dirties) do widget:updateDraw() end
end

return GUI
