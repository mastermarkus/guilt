local is = {}

function is.callable(x)
  if type(x) == "function" then return true end
  local meta = getmetatable(x)
  return meta and type(meta.__call) == "function"
end

function is.number(value)
  return type(value) == "number" and value == value
end

function is.positive_number(value)
  return type(value) == "number" and value > 0
end

function is.non_negative_number(value)
  return type(value) == "number" and value >= 0
end

function is.non_positive_number(value)
  return type(value) == "number" and value <= 0
end

function is.negative_number(value)
  return type(value) == "number" and value < 0
end

function is.string(value)
  return type(value) == "string"
end

function is.table(value)
  return type(value) == "table"
end

return is
