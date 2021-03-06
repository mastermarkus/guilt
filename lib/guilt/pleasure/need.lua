local subpath = (...):match("(.-)[^%.]+$")
local is                      = require (subpath.."is")

local need = {}

local function ensure(condition, specific, id)
  if condition then return end
  error(("Property `%s` must be %s."):format(id, specific), 3)
end

function need.number(value, id)
  ensure(is.number(value), "a number", id)
end

function need.positive_number(value, id)
  ensure(is.positive_number(value), "a positive number", id)
end

function need.non_negative_number(value, id)
  ensure(is.non_negative_number(value), "a non-negative number", id)
end

function need.non_positive_number(value, id)
  ensure(is.non_positive_number(value), "a non-positive number", id)
end

function need.negative_number(value, id)
  ensure(is.negative_number(value), "a negative number", id)
end

function need.string(value, id)
  ensure(is.string(value), "a string", id)
end

function need.table(value, id)
  ensure(is.table(value), "a table", id)
end

return need
