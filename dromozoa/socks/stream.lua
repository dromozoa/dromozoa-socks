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

local class = {}

function class.new()
  return class.reset({ closed = false })
end

function class:reset()
  self.index = 1
  self.min = 1
  self.max = 0
  self.size = 0
  return self
end

function class:clear()
  for m = self.min, self.max do
    self[m] = nil
  end
  return self:reset()
end

function class:write(s)
  local s = tostring(s)
  local max = self.max + 1
  self.max = max
  self.size = self.size + #s
  self[max] = s
  return self
end

function class:close()
  self.closed = true
  return self
end

function class:concat()
  local min = self.min
  local max = self.max
  if min < max then
    local index = self.index
    if index > 1 then
      self[min] = self[min]:sub(index)
    end
    local s = table.concat(self, "", min, max)
    self:clear()
    self:write(s)
  end
  return self
end

function class:read(count)
  local index = self.index
  local min = self.min
  local max = self.max
  local s = self[min]
  if s ~= nil then
    local n = #s - index + 1
    if count > n then
      if min < max then
        self:concat()
        index = self.index
        min = self.min
        max = self.max
        s = self[min]
        n = #s - index + 1
      end
    end
    if count <= n then
      local j = index + count
      if count == n then
        self.index = 1
        self.min = min + 1
        self[min] = nil
      else
        self.index = j
      end
      self.size = self.size - count
      return s:sub(index, j - 1)
    end
    if self.closed then
      self:clear()
      return s:sub(index)
    end
  else
    if self.closed then
      return ""
    end
  end
end

function class:read_until(pattern)
  local index = self.index
  local min = self.min
  local max = self.max
  local s = self[min]
  if s ~= nil then
    local i, j, capture = s:find(pattern, index)
    if i == nil then
      if min < max then
        self:concat()
        index = self.index
        min = self.min
        max = self.max
        s = self[min]
        i, j, capture = s:find(pattern, index)
      end
    end
    if i ~= nil then
      if j == #s then
        self.index = 1
        self.min = min + 1
        self[min] = nil
      else
        self.index = j + 1
      end
      self.size = self.size - (j - index + 1)
      return s:sub(index, i - 1), capture
    end
    if self.closed then
      self:clear()
      return s:sub(index)
    end
  else
    if self.closed then
      return ""
    end
  end
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function ()
    return setmetatable(class.new(), metatable)
  end;
})
