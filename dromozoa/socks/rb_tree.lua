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

local RED = 0
local BLACK = 1
local NIL = 0

local LEFT = 3
local RIGHT = 4

-- return an handle to the first element that is grater than k or equal to k.
local function lower_bound(T, x, k)
  local left = T[LEFT]
  local right = T[RIGHT]
  local key = T.key
  local compare = T.compare

  local y = NIL
  while x ~= NIL do
    if compare(key[x], k) then
      x = right[x]
    else
      y = x
      x = left[x]
    end
  end
  return y
end

-- return an handle to the last element that is less than k or equal to k.
local function upper_bound(T, x, k)
  local left = T[LEFT]
  local right = T[RIGHT]
  local key = T.key
  local compare = T.compare

  local y = NIL
  while x ~= NIL do
    if compare(k, key[x]) then
      x = left[x]
    else
      y = x
      x = right[x]
    end
  end
  return y
end

local function minimum(T, x)
  local left = T[LEFT]

  while left[x] ~= NIL do
    x = left[x]
  end
  return x
end

local function maximum(T, x)
  local right = T[RIGHT]

  while right[x] ~= NIL do
    x = right[x]
  end
  return x
end

local function successor(T, x)
  local p = T.parent
  local right = T[RIGHT]

  if right[x] ~= NIL then
    return minimum(T, right[x])
  end
  local y = p[x]
  while y ~= NIL and x == right[y] do
    x = y
    y = p[y]
  end
  return y
end

local function predecessor(T, x)
  local p = T.parent
  local left = T[LEFT]

  if left[x] ~= NIL then
    return maximum(T, left[x])
  end
  local y = p[x]
  while y ~= NIL and x == left[y] do
    x = y
    y = p[y]
  end
  return y
end

local function left_rotate(T, x)
  local p = T.parent
  local left = T[LEFT]
  local right = T[RIGHT]

  local y = right[x]
  right[x] = left[y]
  if left[y] ~= NIL then
    p[left[y]] = x
  end
  p[y] = p[x]
  if p[x] == NIL then
    T.root = y
  elseif x == left[p[x]] then
    left[p[x]] = y
  else
    right[p[x]] = y
  end
  left[y] = x
  p[x] = y
end

local function right_rotate(T, x)
  local p = T.parent
  local left = T[LEFT]
  local right = T[RIGHT]

  local y = left[x]
  left[x] = right[y]
  if right[y] ~= NIL then
    p[right[y]] = x
  end
  p[y] = p[x]
  if p[x] == NIL then
    T.root = y
  elseif x == right[p[x]] then
    right[p[x]] = y
  else
    left[p[x]] = y
  end
  right[y] = x
  p[x] = y
end

local function insert_fixup(T, z)
  local color = T.color
  local p = T.parent
  local left = T[LEFT]
  local right = T[RIGHT]

  while color[p[z]] == RED do
    if p[z] == left[p[p[z]]] then
      local y = right[p[p[z]]]
      if color[y] == RED then
        color[p[z]] = BLACK
        color[y] = BLACK
        color[p[p[z]]] = RED
        z = p[p[z]]
      else
        if z == right[p[z]] then
          z = p[z]
          left_rotate(T, z)
        end
        color[p[z]] = BLACK
        color[p[p[z]]] = RED
        right_rotate(T, p[p[z]])
      end
    else
      local y = left[p[p[z]]]
      if color[y] == RED then
        color[p[z]] = BLACK
        color[y] = BLACK
        color[p[p[z]]] = RED
        z = p[p[z]]
      else
        if z == left[p[z]] then
          z = p[z]
          right_rotate(T, z)
        end
        color[p[z]] = BLACK
        color[p[p[z]]] = RED
        left_rotate(T, p[p[z]])
      end
    end
  end
  color[T.root] = BLACK
end

local function insert(T, z)
  local color = T.color
  local p = T.parent
  local left = T[LEFT]
  local right = T[RIGHT]
  local key = T.key
  local compare = T.compare

  local y = NIL
  local x = T.root
  while x ~= NIL do
    y = x
    if compare(key[z], key[x]) then
      x = left[x]
    else
      x = right[x]
    end
  end
  p[z] = y
  if y == NIL then
    T.root = z
  elseif compare(key[z], key[y]) then
    left[y] = z
  else
    right[y] = z
  end
  left[z] = NIL
  right[z] = NIL
  color[z] = RED
  insert_fixup(T, z)
end

local function transplant(T, u, v)
  local p = T.parent
  local left = T[LEFT]
  local right = T[RIGHT]

  if p[u] == NIL then
    T.root = v
  elseif u == left[p[u]] then
    left[p[u]] = v
  else
    right[p[u]] = v
  end
  p[v] = p[u]
end

local function delete_fixup(T, x)
  local color = T.color
  local p = T.parent
  local left = T[LEFT]
  local right = T[RIGHT]

  while x ~= T.root and color[x] == BLACK do
    if x == left[p[x]] then
      local w = right[p[x]]
      if color[w] == RED then
        color[w] = BLACK
        color[p[x]] = RED
        left_rotate(T, p[x])
        w = right[p[x]]
      end
      if color[left[w]] == BLACK and color[right[w]] == BLACK then
        color[w] = RED
        x = p[x]
      else
        if color[right[w]] == BLACK then
          color[left[w]] = BLACK
          color[w] = RED
          right_rotate(T, w)
          w = right[p[x]]
        end
        color[w] = color[p[x]]
        color[p[x]] = BLACK
        color[right[w]] = BLACK
        left_rotate(T, p[x])
        x = T.root
      end
    else
      local w = left[p[x]]
      if color[w] == RED then
        color[w] = BLACK
        color[p[x]] = RED
        right_rotate(T, p[x])
        w = left[p[x]]
      end
      if color[right[w]] == BLACK and color[left[w]] == BLACK then
        color[w] = RED
        x = p[x]
      else
        if color[left[w]] == BLACK then
          color[right[w]] = BLACK
          color[w] = RED
          left_rotate(T, w)
          w = left[p[x]]
        end
        color[w] = color[p[x]]
        color[p[x]] = BLACK
        color[left[w]] = BLACK
        right_rotate(T, p[x])
        x = T.root
      end
    end
  end
  color[x] = BLACK
end

local function delete(T, z)
  local color = T.color
  local p = T.parent
  local left = T[LEFT]
  local right = T[RIGHT]
  local key = T.key

  local y = z
  local y_original_color = color[y]
  if left[z] == NIL then
    x = right[z]
    transplant(T, z, right[z])
  elseif right[z] == NIL then
    x = left[z]
    transplant(T, z, left[z])
  else
    y = minimum(T, right[z])
    y_original_color = color[y]
    x = right[y]
    if p[y] == z then
      p[x] = y
    else
      transplant(T, y, right[y])
      right[y] = right[z]
      p[right[y]] = y
    end
    transplant(T, z, y)
    left[y] = left[z]
    p[left[y]] = y
    color[y] = color[z]
  end
  if y_original_color == BLACK then
    delete_fixup(T, x)
  end
end

local function default_compare(a, b)
  return a < b
end

local class = {}

function class.new(compare)
  if compare == nil then
    compare = default_compare
  end
  return {
    color = { [NIL] = BLACK };
    parent = { [NIL] = NIL };
    [LEFT] = {};
    [RIGHT] = {};
    key = {};
    value = {};
    compare = compare;
    root = NIL;
    handle = NIL;
  }
end

function class:lower_bound(k)
  local h = lower_bound(self, self.root, k)
  if h == NIL then
    return nil
  else
    return h
  end
end

function class:upper_bound(k)
  local h = upper_bound(self, self.root, k)
  if h == NIL then
    return nil
  else
    return h
  end
end

function class:upper_bound(k)
  local h = upper_bound(self, self.root, k)
  if h == NIL then
    return nil
  else
    return h
  end
end

function class:search(k)
  local key = self.key
  local compare = self.compare

  local h = lower_bound(self, self.root, k)
  if h == NIL or compare(k, key[h]) then
    return nil
  else
    return h
  end
end

function class:minimum()
  local h = self.root
  if h == NIL then
    return nil
  else
    return minimum(self, h)
  end
end

function class:maximum()
  local h = self.root
  if h == NIL then
    return nil
  else
    return maximum(self, h)
  end
end

function class:successor(h)
  h = successor(self, h)
  if h == NIL then
    return nil
  else
    return h
  end
end

function class:predecessor(h)
  h = predecessor(self, h)
  if h == NIL then
    return nil
  else
    return h
  end
end

function class:insert(k, v)
  local key = self.key
  local value = self.value

  local h = self.handle + 1
  key[h] = k
  value[h] = v
  self.handle = h
  insert(self, h)
  return h
end

function class:delete(h)
  local color = self.color
  local p = self.parent
  local left = self[LEFT]
  local right = self[RIGHT]
  local key = self.key
  local value = self.value

  local k = key[h]
  local v = value[h]
  delete(self, h)
  color[h] = nil
  p[h] = nil
  left[h] = nil
  right[h] = nil
  key[h] = nil
  value[h] = nil
  if self.root == NIL then
    self.handle = NIL
  end
  return k, v
end

function class:key(h)
  local key = self.key
  return key[h]
end

function class:get(h)
  local key = self.key
  local value = self.value
  return key[h], value[h]
end

function class:set(h, v)
  local value = self.value
  value[h] = v
end

function class:empty()
  return self.root == NIL
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, compare)
    return setmetatable(class.new(compare), metatable)
  end;
})
