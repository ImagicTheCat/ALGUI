-- https://github.com/ImagicTheCat/ALGUI
-- MIT license (see LICENSE or src/ALGUI/GUI.lua)

local table_pack = table.pack or function(...) return {n = select("#", ...), ...} end

local class = require("Luaoop").class
local utils = require("ALGUI.utils")

local Widget = class("Widget")

-- Recursive widget tree binding.
-- parent: may be nil
local function bindParent(self, parent)
  -- unbind
  if self.gui then
    self:preUnbind()
    self:unmarkDirty("layout", "view", "drawlist", "transform")
    self.gui:emit("unbind", self)
  end
  -- update
  self.parent = parent
  self.depth = parent and parent.depth+1 or 0
  self.gui = parent and parent.gui
  -- bind
  if self.gui then
    self:postBind()
    self:markDirty("layout", "view", "drawlist", "transform")
    self.gui:emit("bind", self)
  end
  -- recursion
  for child in pairs(self.widgets) do bindParent(child, self) end
end

function Widget:__construct()
  self.x, self.y, self.w, self.h = 0, 0, 0, 0 -- boundaries
  self.tx, self.ty, self.tscale = 0, 0, 1 -- absolute transform
  self.z = 0 -- explicit weight display order
  self.visible = true
  -- view (visible relative area of the widget)
  self.vx, self.vy, self.vw, self.vh = 0, 0, 0, 0
  -- inner view (visible relative area of the widget)
  self.ivx, self.ivy, self.ivw, self.ivh = 0, 0, 0, 0
  self.ix, self.iy = 0, 0 -- inner content shift (inner space)
  self.zoom = 1 -- inner content zoom
  self.z_counter = 0 -- used to compute implicit widget z
  self.depth = 0
  self.widgets = {} -- children
  self.draw_list = {} -- list of children to draw in order
  self.events_listeners = {} -- map of event id => set of callbacks
  self.any_listeners = {} -- set of callbacks
  -- self.iz (widget implicit z)
  -- self.parent
  -- self.gui
end

-- Mark dirty.
-- ...: list of flags, see GUI.dirties
function Widget:markDirty(...)
  if not self.gui then return end
  for _, id in ipairs{...} do self.gui.dirties[id][self] = true end
end

-- Un-mark dirty.
-- ...: list of flags, see GUI.dirties
function Widget:unmarkDirty(...)
  if not self.gui then return end
  for _, id in ipairs{...} do self.gui.dirties[id][self] = nil end
end

function Widget:add(widget)
  if widget.parent then widget.parent:remove(self) end
  self.widgets[widget] = true
  self:markDirty("layout", "drawlist")
  -- update child
  widget.iz = self.z_counter
  self.z_counter = widget.iz+1 -- simple increment, will probably never "overflow"
  bindParent(widget, self)
end

function Widget:remove(widget)
  if self.widgets[widget] then
    self.widgets[widget] = nil
    self:markDirty("layout", "drawlist")
    -- update child
    bindParent(widget, nil)
  end
end

-- Event handler.
-- callback(widget, event, ...)
--- widget: event target
--- event: event identifier (any value as key)
--- ...: event arguments

-- Listen to specific widget events.
-- event: event identifier (any value as key)
function Widget:listen(event, callback)
  -- get/create event entry
  local listeners = self.events_listeners[event]
  if not listeners then
    listeners = {}
    self.events_listeners[event] = listeners
  end
  listeners[callback] = true
end

function Widget:unlisten(event, callback)
  local listeners = self.events_listeners[event]
  if listeners then
    listeners[callback] = nil
    if not next(listeners) then -- if empty, remove event entry
      self.events_listeners[event] = nil
    end
  end
end

-- Listen to any widget events.
function Widget:listenAny(callback)
  self.any_listeners[callback] = true
end

function Widget:unlistenAny(callback)
  self.any_listeners[callback] = nil
end

-- Emit widget event.
-- Deferred to the event loop.
--
-- event: event identifier (any value as key)
-- ...: event arguments
function Widget:emit(event, ...)
  if self.gui then table.insert(self.gui.events, table_pack(self, event, ...)) end
end

function Widget:setPosition(x,y)
  if self.parent and (self.x ~= x or self.y ~= y) then -- changed
    self:markDirty("view", "transform")
    self.parent:markDirty("layout", "drawlist")
  end
  self.x, self.y = x,y
end

function Widget:setSize(w,h)
  if self.w ~= w or self.h ~= h then -- changed
    self:markDirty("layout", "view")
    if self.parent then self.parent:markDirty("layout", "drawlist") end
  end
  self.w, self.h = w,h
end

function Widget:setZ(z)
  if self.parent and self.z ~= z then -- changed
    self.parent:markDirty("drawlist")
  end
  self.z = z
end

function Widget:setVisible(visible)
  if self.parent and self.visible ~= visible then -- changed
    self.parent:markDirty("drawlist")
  end
  self.visible = visible
end

function Widget:setInnerZoom(zoom)
  if self.zoom ~= zoom then -- changed
    self:markDirty("view")
    for child in pairs(self.widgets) do child:markDirty("transform") end
  end
  self.zoom = zoom
end

function Widget:setInnerShift(x,y)
  if self.ix ~= x or self.iy ~= y then -- changed
    self:markDirty("view")
    for child in pairs(self.widgets) do child:markDirty("transform") end
  end
  self.ix, self.iy = x,y
end

-- Called after the widget is bound to a GUI.
-- Allow listening of GUI events.
function Widget:postBind() end

-- Called before the widget is unbound from a GUI.
-- Allow un-listening of GUI events.
function Widget:preUnbind() end

-- Called when the widget layout should be updated.
-- This function should organize children by using the same function on them
-- and/or set its own size when done.
--
-- It shouldn't set its own position.
-- Can call Widget:updateLayout() instead of Widget:setSize() and use the final widget size.
-- Can call Widget:setPosition().
-- Can call self:setSize().
--
-- w,h: requested size
function Widget:updateLayout(w,h)
end

-- Update transform data.
-- (internal, recursion)
function Widget:updateTransform()
  self:unmarkDirty("transform")
  -- compute transform
  local parent = self.parent
  if parent then
    self.tx = parent.tx+(parent.ix+self.x)*parent.tscale*parent.zoom
    self.ty = parent.ty+(parent.iy+self.y)*parent.tscale*parent.zoom
    self.tscale = parent.tscale*parent.zoom
  else
    self.tx, self.ty, self.tscale = self.x, self.y, 1
  end
  -- recursion
  for child in pairs(self.widgets) do child:updateTransform() end
end

-- Update view data.
-- (internal, sparse recursion)
function Widget:updateView()
  self:unmarkDirty("view")
  -- old inner view
  local ivx, ivy, ivw, ivh = self.ivx, self.ivy, self.ivw, self.ivh
  local parent = self.parent
  if parent then -- compute view based on parent
    -- compute new view
    --- intersection of boundaries and parent inner view
    self.vx, self.vy, self.vw, self.vh = utils.intersect(
      self.x, self.y, self.w, self.h, parent.ivx, parent.ivy, parent.ivw, parent.ivh)
    --- move to widget space
    self.vx = self.vx-self.x
    self.vy = self.vy-self.y
  else
    self.vx, self.vy, self.vw, self.vh = 0, 0, self.w, self.h
  end
  -- compute inner view
  self.ivx, self.ivy, self.ivw, self.ivh =
    self.vx/self.zoom-self.ix, self.vy/self.zoom-self.iy,
    self.vw/self.zoom, self.vh/self.zoom
  -- check changed
  if self.ivx ~= ivx or self.ivy ~= ivy or self.ivw ~= ivw or self.ivh ~= ivh then
    self:markDirty("drawlist")
    for child in pairs(self.widgets) do child:updateView() end
  end
end

local function sort_draw_list(a,b) -- sort by z,iz
  return (a.z < b.z or (a.z == b.z and a.iz < b.iz))
end

-- Update draw data.
-- (internal)
function Widget:updateDrawlist()
  self:unmarkDirty("drawlist")
  -- build draw list
  --- add visible widgets
  local draw_list = {}
  for child in pairs(self.widgets) do
    if child.visible and child.vw > 0 and child.vh > 0 then -- check visibility
      table.insert(draw_list, child)
    end
  end
  --- sort in draw order
  table.sort(draw_list, sort_draw_list)
  self.draw_list = draw_list
end

return Widget
