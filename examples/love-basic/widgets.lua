local Widget = require("ALGUI.Widget")

-- Button
local Button = class("Button", Widget)

local function e_button_pointer_enter(self, event, id) self.overed = true end
local function e_button_pointer_leave(self, event, id) self.overed = false end

function Button:__construct(coloredtext)
  Widget.__construct(self)
  self.text = love.graphics.newText(love.graphics.getFont())
  self:setText(coloredtext)
  self:listen("pointer-enter", e_button_pointer_enter)
  self:listen("pointer-leave", e_button_pointer_leave)
end

function Button:setText(coloredtext) self.text:set(coloredtext) end

-- FlowLayout
local FlowLayout = class("FlowLayout", Widget)

local function sort_flowlayout(a,b) return a.iz < b.iz end

function FlowLayout:__construct()
  Widget.__construct(self)
  self.flow_margin = 0
end

function FlowLayout:setMargin(v)
  self.flow_margin = v
  self:markDirty("layout")
end

function FlowLayout:updateLayout(w,h)
  local widgets = {}
  for widget in pairs(self.widgets) do table.insert(widgets, widget) end
  table.sort(widgets, sort_flowlayout) -- sort by implicit z (added order)
  -- set positions
  local x,y,max_h = self.flow_margin, self.flow_margin, 0
  for _, widget in ipairs(widgets) do
    -- line break
    if x+widget.w >= w then x, max_h, y = self.flow_margin, 0, y+max_h+self.flow_margin end
    widget:setPosition(x,y)
    -- next
    x = x+widget.w+self.flow_margin
    max_h = math.max(max_h, widget.h)
  end
  self:setSize(w,y+(max_h > 0 and max_h+self.flow_margin or 0))
end

return {
  Button = Button,
  FlowLayout = FlowLayout
}
