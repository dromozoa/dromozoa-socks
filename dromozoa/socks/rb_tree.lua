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

local COLOR = 1
local PARENT = 2
local LEFT = 3
local RIGHT = 4
local KEY = 5
local VALUE = 6
local ROOT = 7
local HANDLE = 8

local function search(T, x, k)
  local left = T[LEFT]
  local right = T[RIGHT]
  local key = T[KEY]

  if x == NIL or k == key[x] then
    return x
  end
  if k < key[x] then
    return search(T, left[x], k)
  else
    return search(T, right[x], k)
  end
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
  local p = T[PARENT]
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
  local p = T[PARENT]
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
  local p = T[PARENT]
  local left = T[LEFT]
  local right = T[RIGHT]

  local y = right[x]
  right[x] = left[y]
  if left[y] ~= NIL then
    p[left[y]] = x
  end
  p[y] = p[x]
  if p[x] == NIL then
    T[ROOT] = y
  elseif x == left[p[x]] then
    left[p[x]] = y
  else
    right[p[x]] = y
  end
  left[y] = x
  p[x] = y
end

local function right_rotate(T, x)
  local p = T[PARENT]
  local left = T[LEFT]
  local right = T[RIGHT]

  local y = left[x]
  left[x] = right[y]
  if right[y] ~= NIL then
    p[right[y]] = x
  end
  p[y] = p[x]
  if p[x] == NIL then
    T[ROOT] = y
  elseif x == right[p[x]] then
    right[p[x]] = y
  else
    left[p[x]] = y
  end
  right[y] = x
  p[x] = y
end

local function insert_fixup(T, z)
  local color = T[COLOR]
  local p = T[PARENT]
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
  color[T[ROOT]] = BLACK
end

local function insert(T, z)
  local color = T[COLOR]
  local p = T[PARENT]
  local left = T[LEFT]
  local right = T[RIGHT]
  local key = T[KEY]

  local y = NIL
  local x = T[ROOT]
  while x ~= NIL do
    y = x
    if key[z] < key[x] then
      x = left[x]
    else
      x = right[x]
    end
  end
  p[z] = y
  if y == NIL then
    T[ROOT] = z
  elseif key[z] < key[y] then
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
  local p = T[PARENT]
  local left = T[LEFT]
  local right = T[RIGHT]

  if p[u] == NIL then
    T[ROOT] = v
  elseif u == left[p[u]] then
    left[p[u]] = v
  else
    right[p[u]] = v
  end
  p[v] = p[u]
end

local function delete_fixup(T, x)
  local color = T[COLOR]
  local p = T[PARENT]
  local left = T[LEFT]
  local right = T[RIGHT]

  while x ~= T[ROOT] and color[x] == BLACK do
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
        x = T[ROOT]
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
        x = T[ROOT]
      end
    end
  end
  color[x] = BLACK
end

local function delete(T, z)
  local color = T[COLOR]
  local p = T[PARENT]
  local left = T[LEFT]
  local right = T[RIGHT]
  local key = T[KEY]

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

local class = {
  NIL = NIL;
}

function class.new()
  return {
    { [NIL] = BLACK }; -- COLOR
    {}; -- PARENT
    {}; -- LEFT
    {}; -- RIGHT
    {}; -- KEY
    {}; -- VALUE
    NIL; -- ROOT
    NIL; -- HANDLE
  }
end

function class:search(k)
  local h = search(self, self[ROOT], k)
  if h == NIL then
    return nil
  else
    return h
  end
end

function class:minimum()
  local h = self[ROOT]
  if h == NIL then
    return nil
  else
    return minimum(self, h)
  end
end

function class:maximum()
  local h = self[ROOT]
  if h == NIL then
    return nil
  else
    return maximum(self, h)
  end
end

function class:successor(h)
  return successor(self, h)
end

function class:predecessor(h)
  return predecessor(self, h)
end

function class:insert(k, v)
  local key = self[KEY]
  local value = self[VALUE]

  local h = self[HANDLE] + 1
  key[h] = k
  value[h] = v
  self[HANDLE] = h
  insert(self, h)
  return h
end

function class:delete(h)
  local color = self[COLOR]
  local p = self[PARENT]
  local left = self[LEFT]
  local right = self[RIGHT]
  local key = self[KEY]
  local value = self[VALUE]

  local k = key[h]
  local v = value[h]
  delete(self, h)
  color[h] = nil
  p[h] = nil
  left[h] = nil
  right[h] = nil
  key[h] = nil
  value[h] = nil
  return k, v
end

function class:key(h)
  local key = self[KEY]
  return key[h]
end

function class:get(h)
  local value = self[VALUE]
  return value[h]
end

function class:set(h, v)
  local value = self[VALUE]
  value[h] = v
end

--------------------------------------------------------------------------------
-- k以上の最初の要素を返す
local function lower_bound(T, x, k)
  local left = T[LEFT]
  local right = T[RIGHT]
  local key = T[KEY]

  local y = NIL
  while x ~= NIL do
    if not (key[x] < k) then
      y = x
      x = left[x]
    else
      x = right[x]
    end
  end
  return y
end

local function upper_bound(T, x, k)
  local left = T[LEFT]
  local right = T[RIGHT]
  local key = T[KEY]

  local y = NIL
  while x ~= NIL do
    if k < key[x] then
      y = x
      x = left[x]
    else
      x = right[x]
    end
  end
  return y
end

function class:lower_bound(k)
  local h = lower_bound(self, self[ROOT], k)
  return rb_tree_iterator(self, h)
end

function class:upper_bound(k)
  local h = upper_bound(self, self[ROOT], k)
  return rb_tree_iterator(self, h)
end

--------------------------------------------------------------------------------

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function ()
    return setmetatable(class.new(), metatable)
  end;
})
