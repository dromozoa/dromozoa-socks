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

-- return an handle to the first element that is grater than key or equal to key.
local function lower_bound(T, x, key)
  local left = T.left
  local right = T.right
  local keys = T.keys
  local compare = T.compare

  local y = NIL
  while x ~= NIL do
    if compare(keys[x], key) then
      x = right[x]
    else
      y = x
      x = left[x]
    end
  end
  return y
end

-- return an handle to the last element that is less than key or equal to key.
local function upper_bound(T, x, key)
  local left = T.left
  local right = T.right
  local keys = T.keys
  local compare = T.compare

  local y = NIL
  while x ~= NIL do
    if compare(key, keys[x]) then
      x = left[x]
    else
      y = x
      x = right[x]
    end
  end
  return y
end

local function minimum(T, x)
  local left = T.left

  while left[x] ~= NIL do
    x = left[x]
  end
  return x
end

local function maximum(T, x)
  local right = T.right

  while right[x] ~= NIL do
    x = right[x]
  end
  return x
end

local function successor(T, x)
  local parent = T.parent
  local right = T.right

  if right[x] ~= NIL then
    return minimum(T, right[x])
  end
  local y = parent[x]
  while y ~= NIL and x == right[y] do
    x = y
    y = parent[y]
  end
  return y
end

local function predecessor(T, x)
  local parent = T.parent
  local left = T.left

  if left[x] ~= NIL then
    return maximum(T, left[x])
  end
  local y = parent[x]
  while y ~= NIL and x == left[y] do
    x = y
    y = parent[y]
  end
  return y
end

local function left_rotate(T, x)
  local parent = T.parent
  local left = T.left
  local right = T.right

  local y = right[x]
  right[x] = left[y]
  if left[y] ~= NIL then
    parent[left[y]] = x
  end
  parent[y] = parent[x]
  if parent[x] == NIL then
    T.root = y
  elseif x == left[parent[x]] then
    left[parent[x]] = y
  else
    right[parent[x]] = y
  end
  left[y] = x
  parent[x] = y
end

local function right_rotate(T, x)
  local parent = T.parent
  local left = T.left
  local right = T.right

  local y = left[x]
  left[x] = right[y]
  if right[y] ~= NIL then
    parent[right[y]] = x
  end
  parent[y] = parent[x]
  if parent[x] == NIL then
    T.root = y
  elseif x == right[parent[x]] then
    right[parent[x]] = y
  else
    left[parent[x]] = y
  end
  right[y] = x
  parent[x] = y
end

local function insert_fixup(T, z)
  local color = T.color
  local parent = T.parent
  local left = T.left
  local right = T.right

  while color[parent[z]] == RED do
    if parent[z] == left[parent[parent[z]]] then
      local y = right[parent[parent[z]]]
      if color[y] == RED then
        color[parent[z]] = BLACK
        color[y] = BLACK
        color[parent[parent[z]]] = RED
        z = parent[parent[z]]
      else
        if z == right[parent[z]] then
          z = parent[z]
          left_rotate(T, z)
        end
        color[parent[z]] = BLACK
        color[parent[parent[z]]] = RED
        right_rotate(T, parent[parent[z]])
      end
    else
      local y = left[parent[parent[z]]]
      if color[y] == RED then
        color[parent[z]] = BLACK
        color[y] = BLACK
        color[parent[parent[z]]] = RED
        z = parent[parent[z]]
      else
        if z == left[parent[z]] then
          z = parent[z]
          right_rotate(T, z)
        end
        color[parent[z]] = BLACK
        color[parent[parent[z]]] = RED
        left_rotate(T, parent[parent[z]])
      end
    end
  end
  color[T.root] = BLACK
end

local function insert(T, z)
  local color = T.color
  local parent = T.parent
  local left = T.left
  local right = T.right
  local keys = T.keys
  local compare = T.compare

  local kz = keys[z]

  local y = NIL
  local x = T.root
  while x ~= NIL do
    y = x
    if compare(kz, keys[x]) then
      x = left[x]
    else
      x = right[x]
    end
  end
  parent[z] = y
  if y == NIL then
    T.root = z
  elseif compare(kz, keys[y]) then
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
  local parent = T.parent
  local left = T.left
  local right = T.right

  local pu = parent[u]

  if pu == NIL then
    T.root = v
  elseif u == left[pu] then
    left[pu] = v
  else
    right[pu] = v
  end
  parent[v] = pu
end

local function delete_fixup(T, x)
  local color = T.color
  local parent = T.parent
  local left = T.left
  local right = T.right

  while x ~= T.root and color[x] == BLACK do
    if x == left[parent[x]] then
      local w = right[parent[x]]
      if color[w] == RED then
        color[w] = BLACK
        color[parent[x]] = RED
        left_rotate(T, parent[x])
        w = right[parent[x]]
      end
      if color[left[w]] == BLACK and color[right[w]] == BLACK then
        color[w] = RED
        x = parent[x]
      else
        if color[right[w]] == BLACK then
          color[left[w]] = BLACK
          color[w] = RED
          right_rotate(T, w)
          w = right[parent[x]]
        end
        color[w] = color[parent[x]]
        color[parent[x]] = BLACK
        color[right[w]] = BLACK
        left_rotate(T, parent[x])
        x = T.root
      end
    else
      local w = left[parent[x]]
      if color[w] == RED then
        color[w] = BLACK
        color[parent[x]] = RED
        right_rotate(T, parent[x])
        w = left[parent[x]]
      end
      if color[right[w]] == BLACK and color[left[w]] == BLACK then
        color[w] = RED
        x = parent[x]
      else
        if color[left[w]] == BLACK then
          color[right[w]] = BLACK
          color[w] = RED
          left_rotate(T, w)
          w = left[parent[x]]
        end
        color[w] = color[parent[x]]
        color[parent[x]] = BLACK
        color[left[w]] = BLACK
        right_rotate(T, parent[x])
        x = T.root
      end
    end
  end
  color[x] = BLACK
end

local function delete(T, z)
  local color = T.color
  local parent = T.parent
  local left = T.left
  local right = T.right
  local keys = T.keys

  local lz = left[z]
  local rz = right[z]

  local x
  local y = z
  local y_original_color = color[y]
  if lz == NIL then
    x = rz
    transplant(T, z, rz)
  elseif rz == NIL then
    x = lz
    transplant(T, z, lz)
  else
    y = minimum(T, rz)
    y_original_color = color[y]
    x = right[y]
    if parent[y] == z then
      parent[x] = y
    else
      transplant(T, y, x)
      right[y] = right[z]
      parent[right[y]] = y
    end
    transplant(T, z, y)
    left[y] = left[z]
    parent[left[y]] = y
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
    left = {};
    right = {};
    keys = {};
    values = {};
    compare = compare;
    root = NIL;
    handle = NIL;
  }
end

function class:lower_bound(key)
  local h = lower_bound(self, self.root, key)
  if h == NIL then
    return nil
  else
    return h
  end
end

function class:upper_bound(key)
  local h = upper_bound(self, self.root, key)
  if h == NIL then
    return nil
  else
    return h
  end
end

function class:upper_bound(key)
  local h = upper_bound(self, self.root, key)
  if h == NIL then
    return nil
  else
    return h
  end
end

function class:search(key)
  local keys = self.keys
  local compare = self.compare

  local h = lower_bound(self, self.root, key)
  if h == NIL or compare(key, keys[h]) then
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

function class:insert(key, value)
  local keys = self.keys
  local values = self.values

  local h = self.handle + 1
  keys[h] = key
  values[h] = value
  self.handle = h
  insert(self, h)
  return h
end

function class:delete(h)
  local color = self.color
  local parent = self.parent
  local left = self.left
  local right = self.right
  local keys = self.keys
  local values = self.values

  local key = keys[h]
  local value = values[h]
  delete(self, h)
  color[h] = nil
  parent[h] = nil
  left[h] = nil
  right[h] = nil
  keys[h] = nil
  values[h] = nil
  if self.root == NIL then
    self.handle = NIL
  end
  return key, value
end

function class:get(h)
  local keys = self.keys
  local values = self.values
  return keys[h], values[h]
end

function class:set(h, value)
  local values = self.values
  values[h] = value
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
