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

local rb_tree_iterator = require "dromozoa.socks.rb_tree_iterator"
local rb_tree_range = require "dromozoa.socks.rb_tree_range"

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

local function inorder_tree_walk(T, x, fn)
  local left = T[LEFT]
  local right = T[RIGHT]
  local key = T[KEY]

  if x ~= NIL then
    inorder_tree_walk(T, left[x], fn)
    fn(key[x])
    inorder_tree_walk(T, right[x], fn)
  end
end

local function tree_search(T, x, k)
  local left = T[LEFT]
  local right = T[RIGHT]
  local key = T[KEY]

  if x == NIL or k == key[x] then
    return x
  end
  if k < key[x] then
    return tree_search(T, left[x], k)
  else
    return tree_search(T, right[x], k)
  end
end

local function tree_minimum(T, x)
  local left = T[LEFT]

  while left[x] ~= NIL do
    x = left[x]
  end
  return x
end


local function tree_maximum(T, x)
  local right = T[RIGHT]

  while right[x] ~= NIL do
    x = right[x]
  end
  return x
end

local function tree_successor(T, x)
  local p = T[PARENT]
  local right = T[RIGHT]

  if right[x] ~= NIL then
    return tree_minimum(T, right[x])
  end
  local y = p[x]
  while y ~= NIL and x == right[y] do
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

local function rb_insert_fixup(T, z)
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

local function rb_insert(T, z)
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
  rb_insert_fixup(T, z)
end

local function rb_transplant(T, u, v)
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

local function rb_delete_fixup(T, x)
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

local function rb_delete(T, z)
  local color = T[COLOR]
  local p = T[PARENT]
  local left = T[LEFT]
  local right = T[RIGHT]
  local key = T[KEY]

  local y = z
  local y_original_color = color[y]
  if left[z] == NIL then
    x = right[z]
    rb_transplant(T, z, right[z])
  elseif right[z] == NIL then
    x = left[z]
    rb_transplant(T, z, left[z])
  else
    y = tree_minimum(T, right[z])
    y_original_color = color[y]
    x = right[y]
    if p[y] == z then
      p[x] = y
    else
      rb_transplant(T, y, right[y])
      right[y] = right[z]
      p[right[y]] = y
    end
    rb_transplant(T, z, y)
    left[y] = left[z]
    p[left[y]] = y
    color[y] = color[z]
  end
  if y_original_color == BLACK then
    rb_delete_fixup(T, x)
  end
end

local class = {}

function class.new()
  return {
    { [0] = BLACK };  -- color
    {};  -- parent
    {};  -- left
    {};  -- right
    {};  -- key
    {};  -- value
    NIL; -- root
    0; -- handle
  }
end

function class:search(k)
  local h = tree_search(self, self[ROOT], k)
  return rb_tree_iterator(self, h)
end

function class:minimum()
  local h = tree_minimum(self, self[ROOT])
  return rb_tree_iterator(self, h)
end

function class:maximum()
  local h = tree_maximum(self, self[ROOT])
  return rb_tree_iterator(self, h)
end

function class:successor(h)
  return rb_tree_iterator(self, tree_successor(self, h))
end

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

function class:equal_range(k)
  return rb_tree_range(self:lower_bound(k), self:upper_bound(k))
end

function class:each()
  return rb_tree_range(self:minimum(), self:maximum():successor()):each()
end

function class:empty()
  return self[ROOT] == NIL
end

function class:insert(k, v)
  local key = self[KEY]
  local value = self[VALUE]

  local h = self[HANDLE] + 1
  key[h] = k
  value[h] = v
  self[HANDLE] = h
  rb_insert(self, h)
  return rb_tree_iterator(self, h)
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
  rb_delete(self, h)
  color[h] = nil
  p[h] = nil
  left[h] = nil
  right[h] = nil
  key[h] = nil
  value[h] = nil
  return k, v
end

function class:key(h)
  return self[KEY][h]
end

function class:get(h)
  return self[VALUE][h]
end

function class:set(h, v)
  self[VALUE][h] = v
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function ()
    return setmetatable(class.new(), metatable)
  end;
})
