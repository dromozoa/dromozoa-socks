-- Copyright (C) 2016 Tomoyuki Fujimori <moyu@dromozoa.com>
--
-- This file is part of dromozoa-socks.
--
-- dromozoa-socks is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- dromozoa-socks is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with dromozoa-socks.  If not, see <http://www.gnu.org/licenses/>.

local sequence = require "dromozoa.commons.sequence"
local translate_range = require "dromozoa.commons.translate_range"

local class = {}

function class.new()
  return class.reset({ eof = false })
end

function class:reset()
  self.strings = {}
  self.indices = {}
  self.min = 1
  self.max = 0
  return self
end

function class:write(s)
  local max = self.max + 1
  self.strings[max] = tostring(s)
  self.indices[max] = 1
  self.max = max
  return self
end

function class:read(count)
  local strings = self.strings
  local indices = self.indices
  local buffer = sequence()
  local min = self.min
  for min = min, self.max do
    local s = strings[min]
    local i = indices[min]
    local j = #s
    local n = j - i + 1
    if n < count then
      if i == 1 then
        buffer:push(s)
      else
        local s = s:sub(i)
        buffer:push(s)
        strings[min] = s
        indices[min] = 1
      end
      count = count - n
    else
      if n == count then
        if i == 1 then
          buffer:push(s)
        else
          buffer:push(s:sub(i))
        end
        self.min = min + 1
      else
        local k = i + count
        buffer:push(s:sub(i, k - 1))
        indices[min] = k
        self.min = min
      end
      count = 0
      break
    end
  end
  if count == 0 then
    for min = min, self.min - 1 do
      strings[min] = nil
      indices[min] = nil
    end
    return buffer:concat()
  elseif self.eof then
    self:reset()
    return buffer:concat()
  else
    return nil
  end
end

function class:close()
  self.eof = true
  return self
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function ()
    return setmetatable(class.new(), metatable)
  end;
})
