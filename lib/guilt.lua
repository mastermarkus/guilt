local path = (...)
local pleasure                = require (path..".pleasure")
local is                      = require (path..".pleasure.is")
local invoker                 = require (path..".pleasure.invoker")
local clone                   = require (path..".pleasure.clone")

local function insist(condition, message, a)
  if condition then return end
  error(message:format(a), 3)
end

local function enforce(needs, props)
  for need, enforcer in pairs(needs) do
    local prop = props[need]
    enforcer(prop, need)
  end
end

local function add_child(self, child)
  table.insert(self.children, child)
  child._parent = self
end

local function add_children(self, ...)
  for i = 1, select("#", ...) do
    local child = select(i, ...)
    table.insert(self.children, child)
    child._parent = self
  end
end

local function element_bounds(self)
  local parent = self._parent
  local parent_width, parent_height = parent.width, parent.height
  local x, y, width, height = self.x, self.y, self.width, self.height
  return x + (self.anchor_x or 0)*parent.width  - (self.align_x or 0)*width
       , y + (self.anchor_y or 0)*parent.height - (self.align_y or 0)*height
       , width
       , height
end

local Template = {}
function Template.__index(template, key)
  local value = rawget(Template, key)
  if not value then
    value = invoker()
    rawset(template, key, value)
  end
  return value
end

local guilt = {}
local _templates = {}
local _needs = {}

local function _new(template, props)
  local self = props or {}
  for k, v in pairs(template) do
    if not (is.string(k) and k:find("^__"))
    and not props[k] then
      self[k] = clone(v)
    end
  end
  setmetatable(self, template)
  self:init()
  return self
end

local basic_needs = {
  x      = pleasure.need.number;
  y      = pleasure.need.number;
  width  = pleasure.need.non_negative_number;
  height = pleasure.need.non_negative_number;
}

local GUI = {}
GUI.__index = GUI

function guilt.gui(props)
  insist(is.table(props), "GUI needs property table on creation.")
  enforce(basic_needs, props)

  props.tags = {}
  props._guilt_gui_ = props

  if props.children then
    insist(is.table (props.children), "GUI property `children` must be a table.")
  else
    props.children = {}
  end
  return setmetatable(props, GUI)
end

function GUI:new(template_id, props)
  insist(is.string(template_id), "Template id must be a string.")
  local template = _templates[template_id]
  insist(is.table(template), "No template named %q exist.", template_id)
  insist(getmetatable(template) ~= Template, "Template %q must be finalized before use.", template_id)

  local needs = _needs[template_id]
  if needs then
    insist(is.table (props), "Template `%s` needs property table on creation.", template_id)
    enforce(needs, props)
  end

  local instance = _new(template, props)
  enforce(basic_needs, instance)

  instance._guilt_gui_ = self

  return instance
end

function GUI:draw ()
  pleasure.push_region(self:bounds())
  for i, child in ipairs(self.children) do
    pleasure.try.invoke(child, "draw")
  end
  pleasure.pop_region()
end

function GUI:bounds()
  return self.x, self.y, self.width, self.height
end
GUI.add_child     = add_child
GUI.add_children  = add_children
GUI.mousepressed  = require "lib.guilt.delegate.mousepressed"
GUI.mousemoved    = require "lib.guilt.delegate.mousemoved"
GUI.mousereleased = require "lib.guilt.delegate.mousereleased"
GUI.textinput     = require "lib.guilt.delegate.textinput"
GUI.keypressed    = require "lib.guilt.delegate.keypressed"
GUI.keyreleased   = require "lib.guilt.delegate.keyreleased"

function guilt.template(template_id)
  insist(is.string(template_id), "Template id must be a string.")

  local template = setmetatable({}, Template)

  _templates[template_id] = template
  _templates[template] = template_id

  return template
end

-- TODO more code to finalize template?
function guilt.finalize_template(template)
  insist(is.table(template) and getmetatable(template) == Template, "Template provided must be an actual guilt Template.")
  setmetatable(template, nil)
  insist(template.bounds    == nil, "Template must not override internal `bounds` function.")
  insist(template.add_child == nil, "Template must not override internal `add_child` function.")

  template.anchor_x = template.anchor_x or 0
  template.anchor_y = template.anchor_y or 0
  template.align_x  = template.align_x  or 0
  template.align_y  = template.align_y  or 0
  template.x        = template.x        or 0
  template.y        = template.y        or 0

  template.add_child = add_child
  template.add_children = add_children
  template.bounds    = element_bounds
  template.__index = template
end

function Template:from(parent)
  -- TODO extend self with parent
  return self
end

function Template:needs(props)
  insist(is.table(props), "Argument to `Template:needs` must be a table.")

  for need, enforcer in pairs(props) do
    insist(is.string(need), "Name of need must be a string.")
    insist(is.callable(enforcer), "Enforcer of need `%s` must callable.", need)
  end

  local name = _templates[self]
  _needs[name] = props

  return self
end

return guilt
