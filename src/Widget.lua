local class = require("Luaoop").class

local Widget = class("Widget")

function Widget:__construct()
  self.x, self.y, self.w, self.h = 0, 0, 0, 0
  self.widgets = {}
  self.draw_list = {} -- widgets list
  self.events_listeners = {}
end

function Widget:add(widget)
  self.widgets[widget] = true
end

function Widget:remove(widget)
  self.widgets[widget] = nil
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

    if not next(listeners) then -- empty, remove event entry
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

-- update widget render data (sparse recursive)
--
-- This function is called by renderers and will update rendering data like
-- visibility, widget boundaries, etc. It may be manually called to update
-- those data without rendering.
function Widget:preRender()
end

return Widget
