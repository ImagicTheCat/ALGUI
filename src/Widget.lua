local class = require("Luaoop").class
local utils = require("ALGUI.utils")

local Widget = class("Widget")

local function sort_draw_list(a,b) -- sort by z,iz
  return (a.z < b.z or (a.z == b.z and a.iz < b.iz))
end

-- PRIVATE METHODS

-- recursive parent update
-- parent: can be nil
local function update_parent(self, parent)
  -- set iz (widget implicit z)
  if parent then
    if parent ~= self.parent then -- update if parent changed
      self.iz = parent.z_counter
      parent.z_counter = self.iz+1 -- simple increment, will probably never "overflow"
    end
  else
    self.iz = nil
  end

  local old_parent = self.parent
  self.parent = parent
  self.depth = (parent and parent.depth+1 or 0)

  if self.gui then -- unmark dirties
    self.gui.layout_dirties[self] = nil
    self.gui.view_dirties[self] = nil
    self.gui.inner_dirties[self] = nil
    self.gui.draw_dirties[self] = nil
  end

  local old_gui = self.gui
  self.gui = (parent and parent.gui) -- new GUI

  if not self.gui then
    -- cleanup GUI related data
    self.draw_list = nil
  end

  if self.parent ~= old_parent then self:trigger("parent_change", old_parent) end
  if self.gui ~= old_gui then self:trigger("gui_change", old_gui) end

  for child in pairs(self.widgets) do update_parent(child, self) end
end

-- METHODS

function Widget:__construct()
  self.x, self.y, self.w, self.h = 0, 0, 0, 0 -- boundaries
  self.z = 0 -- explicit weight display order
  self.visible = true
  self.vx, self.vy, self.vw, self.vh = 0, 0, 0, 0 -- view (visible relative area of the widget)
  self.ivx, self.ivy, self.ivw, self.ivh = 0, 0, 0, 0 -- inner view (visible relative area of the widget)
  self.iw, self.ih = 0, 0 -- inner content width/height
  self.ix, self.iy = 0, 0 -- inner content shift (inner space)
  self.zoom = 1 -- inner content zoom
  self.z_counter = 0
  self.depth = 0
  self.widgets = {}
  self.events_listeners = {}
end

function Widget:add(widget)
  if widget.parent then
    widget.parent:remove(self)
  end

  self.widgets[widget] = true
  update_parent(widget, self) -- set parent
  if self.gui then -- mark dirty
    self.gui.layout_dirties[self] = true
    self.gui.inner_dirties[self] = true
    self.gui.draw_dirties[self] = true
    self.gui.view_dirties[widget] = true
    self.gui.layout_dirties[widget] = true
  end
end

function Widget:remove(widget)
  if self.widgets[widget] then
    self.widgets[widget] = nil
    update_parent(widget) -- remove parent

    if self.gui then -- mark dirty
      self.gui.layout_dirties[self] = true
      self.gui.inner_dirties[self] = true
      self.gui.draw_dirties[self] = true
    end
  end
end

-- listen widget event
-- callback(widget, ...)
--- ...: event args
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

-- trigger widget event
-- ...: event args
function Widget:trigger(event, ...)
  local listeners = self.events_listeners[event]
  if listeners then
    for callback in pairs(listeners) do
      callback(self, ...)
    end
  end
end

function Widget:setPosition(x,y)
  if self.gui and (self.x ~= x or self.y ~= y) then -- changed
    self.gui.view_dirties[self] = true
    if self.parent then
      self.gui.layout_dirties[self.parent] = true
      self.gui.inner_dirties[self.parent] = true
      self.gui.draw_dirties[self.parent] = true
    end
  end

  self.x, self.y = x,y
end

function Widget:setSize(w,h)
  if self.gui and (self.w ~= w or self.h ~= h) then -- changed
    self.gui.view_dirties[self] = true
    self.gui.layout_dirties[self] = true
    if self.parent then
      self.gui.layout_dirties[self.parent] = true
      self.gui.inner_dirties[self.parent] = true
      self.gui.draw_dirties[self.parent] = true
    end
  end

  self.w, self.h = w,h
end

function Widget:setZ(z)
  if self.gui and self.z ~= z and self.parent then -- changed
    self.gui.draw_dirties[self.parent] = true
  end

  self.z = z
end

function Widget:setVisible(visible)
  if self.gui and self.visible ~= visible and self.parent then -- changed
    self.gui.draw_dirties[self.parent] = true
  end

  self.visible = visible
end

function Widget:setInnerZoom(zoom)
  if self.gui and self.zoom ~= zoom then -- changed
    self.gui.view_dirties[self] = true
  end

  self.zoom = zoom
end

function Widget:setInnerShift(x,y)
  if self.gui and (self.ix ~= x or self.iy ~= y) then -- changed
    self.gui.view_dirties[self] = true
  end

  self.ix, self.iy = x,y
end

-- mark layout for update
function Widget:markLayoutDirty()
  if self.gui then self.gui.layout_dirties[self] = true end
end

-- called when the widget layout should be updated
--
-- this function should organize children by using the same function on them
-- and/or set its own size when done
--
-- it shouldn't set its own position
-- can call Widget:updateLayout() instead of Widget:setSize() and use the final widget size
-- can call Widget:setPosition()
-- can call self:setSize()
--
-- w,h: requested size
function Widget:updateLayout(w,h)
end

-- update view data (pre-render step #1)
-- (internal)
-- (sparse recursion)
function Widget:updateView()
  self.gui.view_dirties[self] = nil -- unmark dirty

  local ivx, ivy, ivw, ivh = self.ivx, self.ivy, self.ivw, self.ivh -- old inner view
  local parent = self.parent

  if parent then -- compute view based on parent
    -- compute new view
    --- intersection of boundaries and parent inner view
    self.vx, self.vy, self.vw, self.vh = utils.intersect(
      self.x, self.y, self.w, self.h,
      parent.ivx, parent.ivy, parent.ivw, parent.ivh
    )

    --- move to widget space
    self.vx = self.vx-self.x
    self.vy = self.vy-self.y
  end

  -- compute inner view
  self.ivx, self.ivy, self.ivw, self.ivh = self.vx/self.zoom-self.ix, self.vy/self.zoom-self.iy, self.vw/self.zoom, self.vh/self.zoom

  if self.ivx ~= ivx or self.ivy ~= ivy or self.ivw ~= ivw or self.ivh ~= ivh then -- changed
    self.gui.draw_dirties[self] = true
    for child in pairs(self.widgets) do child:updateView() end
  end
end

-- update inner data (pre-render step #2)
-- (internal)
function Widget:updateInner()
  self.gui.inner_dirties[self] = nil -- unmark dirty

  -- compute inner data
  --- width/height
  local iw, ih = 0, 0
  for child in pairs(self.widgets) do
    iw = math.max(iw, child.x+child.w)
    ih = math.max(ih, child.y+child.h)
  end
  self.iw, self.ih = iw, ih
end

-- update draw data (pre-render step #3)
-- (internal)
function Widget:updateDraw()
  self.gui.draw_dirties[self] = nil -- unmark dirty

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

  self.draw_list = (draw_list[1] and draw_list or nil) -- draw_list or nil if empty
end

return Widget
