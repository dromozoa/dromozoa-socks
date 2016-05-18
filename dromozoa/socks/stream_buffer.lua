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

local COMPACTION_LIMIT = 256

local function reset(self)
  self.index = 1
  self.min = 1
  self.max = 0
  self.size = 0
  return self
end

local function clear(self)
  for min = self.min, self.max do
    self[min] = nil
  end
  reset(self)
end

local function concat(self)
  local min = self.min
  local max = self.max
  self.max = min
  self[min] = table.concat(self, "", min, max)
  for min = min + 1, max do
    self[min] = nil
  end
  return self
end

local function read(self, count, some)
  local min = self.min
  local s = self[min]
  if s ~= nil then
    local index = self.index
    local max = self.max
    local n = #s - index + 1
    if count > n and min < max then
      concat(self)
      index = self.index
      min = self.min
      max = self.max
      s = self[min]
      n = #s - index + 1
    end
    if count < n then
      local k = index + count
      if k < COMPACTION_LIMIT then
        self.index = k
      else
        self.index = 1
        self[min] = s:sub(k)
      end
      self.size = self.size - count
      return s:sub(index, k - 1)
    elseif count == n then
      self.index = 1
      self.min = min + 1
      self.size = self.size - count
      self[min] = nil
      if index > 1 then
        return s:sub(index)
      else
        return s
      end
    end
    if some then
      clear(self)
      if index > 1 then
        return s:sub(index)
      else
        return s
      end
    end
  else
    if some then
      return ""
    end
  end
end

local class = {}

function class.new()
  return reset({})
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

function class:read(count)
  return read(self, count, self.closed)
end

function class:read_some(count)
  return read(self, count, true)
end

function class:read_until(pattern)
  local min = self.min
  local s = self[min]
  if s ~= nil then
    local index = self.index
    local max = self.max
    local i, j, capture = s:find(pattern, index)
    if i == nil and min < max then
      concat(self)
      index = self.index
      min = self.min
      max = self.max
      s = self[min]
      i, j, capture = s:find(pattern, index)
    end
    if i ~= nil then
      local k = j + 1
      if j < #s then
        if k < COMPACTION_LIMIT then
          self.index = k
        else
          self.index = 1
          self[min] = s:sub(k)
        end
      else
        self.index = 1
        self.min = min + 1
        self[min] = nil
      end
      self.size = self.size - (k - index)
      return s:sub(index, i - 1), capture
    end
    if self.closed then
      clear(self)
      if index > 1 then
        return s:sub(index)
      else
        return s
      end
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
