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

local function read(self, count, some)
  local strings = self.strings
  local indices = self.indices
  local min = self.min
  local buffer = sequence()
  for m = min, self.max do
    local s = strings[m]
    local i = indices[m]
    local j = #s
    local n = j - i + 1
    if n < count then
      if i == 1 then
        buffer:push(s)
      else
        local s = s:sub(i)
        buffer:push(s)
        strings[m] = s
        indices[m] = 1
      end
      count = count - n
    else
      if n == count then
        if i == 1 then
          buffer:push(s)
        else
          buffer:push(s:sub(i))
        end
        m = m + 1
      else
        local k = i + count
        buffer:push(s:sub(i, k - 1))
        indices[m] = k
      end
      for m = min, m - 1 do
        strings[m] = nil
        indices[m] = nil
      end
      self.min = m
      return buffer:concat()
    end
  end
  if some then
    self:reset()
    return buffer:concat()
  end
end

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
  local m = self.max + 1
  self.strings[m] = tostring(s)
  self.indices[m] = 1
  self.max = m
  return self
end

function class:close()
  self.eof = true
  return self
end

function class:read(count)
  return read(self, count, self.eof)
end

function class:read_some(count)
  return read(self, count, true)
end

function class:read_until(delim)
  local delim_char = delim:sub(1, 1)
  local delim_count = #delim

  local strings = self.strings
  local indices = self.indices
  local min = self.min
  local max = self.max

  for m = min, max do
    local s = strings[m]
    local i = indices[m]
    local j = s:find(delim_char, i, true)
    if j ~= nil then
      local count = delim_count
      local n = #s - j + 1

      if count <= n then
        if s:sub(j, j + count - 1) == delim then
          -- found
        end
      else
        local buffer = sequence()
        buffer:push(s:sub(j))
        count = count - n
        for m = m + 1, max do
          local s = strings[m]
          local i = indices[i]
          local j = #s
          local n = j - i + 1
          if count <= n then
            buffer:push(s:sub(i, i + count - 1))
            if buffer:concat() == delim then
              -- found
            end
          else
            buffer:push(s:sub(i))
            count = count - n
          end
        end
      end


      local count = #delim
      local s = s:sub(j)
      local count = count - #s
      local buffer = sequence()
      buffer:push(s)
      for m = m + 1, max do
        local s = strings[m]
        local i = indices[m]
        local n = #s - i - 1
        buffer:push(s:sub(i))
        count = count - n
        if count <= 0 then
          break
        end
      end
      if buffer:concat():sub(1, #delim) == delim then
        -- found
      end

    end
  end
end

--[[
local function next_char(self, min, index, distance)
  local strings = self.strings
  local indices = self.indices
  local max = self.max
  for m = min, max do
    local s = strings[m]
    local i
    if index == nil then
      i = indices[m]
    else
      i = index
      index = nil
    end
    local j = #s
    local k = i + distance
    if k <= j then
      return m, k
    else
      distance = k - j - 1
    end
  end
  return max + 1, 1
end

function class:lookahead(count, min, index)
  local strings = self.strings
  local indices = self.indices
  if min == nil then
    min = self.min
  end
  local buffer = sequence()
  for m = min, self.max do
    local s = strings[m]
    local i
    if index == nil then
      i = indices[m]
    else
      i = index
      index = nil
    end
    local j = #s
    local n = j - i + 1
    if count < n then
      local j = i + count - 1
      buffer:push(s:sub(i, j))
      count = 0
    else
      if i == 1 then
        buffer:push(s)
      else
        buffer:push(s:sub(i))
      end
      count = count - n
    end
    if count == 0 then
      break
    end
  end
  return buffer:concat()
end

local function find_char(self, min, index, char)
  local strings = self.strings
  local indices = self.indices
  local max = self.max
  for m = min, max do
    local s = strings[m]
    local i
    if index == nil then
      i = indices[m]
    else
      i = index
      index = nil
    end
    local j = s:find(char, i, true)
    if j ~= nil then
      return m, j
    end
  end
  return max, 1
end

local function fill_buffer(self, min, max, i, j)
end

local function read_buffer(self, min, index, count)
  local strings = self.strings
  local indices = self.indices
  local max = self.max
  local buffer = sequence()
  for m = min, max do
    local s = strings[m]
    local i
    if index == nil then
      i = indices[m]
    else
      i = index
      index = nil
    end
    local j = #s
    local n = j - i + 1
    if n < count then
      buffer:push(s:sub(i))
      count = count - n
    elseif n == count then
      buffer:push(s:sub(i))
      return m + 1, 1, buffer
    else
      local k = i + count
      buffer:push(s:sub(i, k - 1))
      return m, k, buffer
    end
  end
  return max + 1, 1, buffer
end

function class:read_until(delim)
  local head
  local tail
  if #delim == 1 then
    head = delim
  else
    head = delim:sub(1, 1)
    tail = delim:sub(2)
  end
  local strings = self.strings
  local indices = self.indices

  while true do
    local m, j = find(strings, indices, head, self.min, self.max)
    if m ~= nil then
      if lookahead(strings, indices, m, j, tail) then
      end
    end
  end
end

]]

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function ()
    return setmetatable(class.new(), metatable)
  end;
})
