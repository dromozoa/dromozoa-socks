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

local json = require "dromozoa.commons.json"
local xml = require "dromozoa.commons.xml"

local RED = 0
local BLACK = 1
local NIL = 0

local ROOT = 1
local COLOR = 2
local PARENT = 3
local LEFT = 4
local RIGHT = 5
local KEY = 6
local VALUE = 7

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

local function dump_node(out, T, x)
  if x ~= NIL then
    local color = T[COLOR]
    local left = T[LEFT]
    local right = T[RIGHT]
    local key = T[KEY]

    local c
    if color[x] == RED then
      c = "red"
    else
      c = "black"
    end
    out:write(x, " [label =  <<font color=\"white\">", xml.escape(key[x]), "</font>>, fillcolor = ", c, "];\n")
    dump_node(out, T, left[x])
    dump_node(out, T, right[x])
  end
end

local function dump_edge(out, T, x, y)
  if y ~= NIL then
    local left = T[LEFT]
    local right = T[RIGHT]

    out:write(x, " -> ", y, ";\n")
    dump_edge(out, T, y, left[y])
    dump_edge(out, T, y, right[y])
  end
end

local function dump(out, T)
  local left = T[LEFT]
  local right = T[RIGHT]

  out:write("digraph g {\n")
  out:write("graph [rankdir = LR];\n")
  out:write("node [color = black, style = filled];\n")
  dump_node(out, T, T[ROOT])
  dump_edge(out, T, T[ROOT], left[T[ROOT]])
  dump_edge(out, T, T[ROOT], right[T[ROOT]])
  out:write("}\n")

  return out
end

local function shuffle(keys)
  for i = #keys, 2, -1 do
    local j = math.random(1, i)
    local k = keys[i]
    keys[i] = keys[j]
    keys[j] = k
  end
end

local function reverse(keys)
  table.sort(keys, function (a, b) return a > b end)
end


local function test_insert(T, keys)
  local key = T[KEY]
  for i = 1, #keys do
    key[i] = keys[i]
    insert(T, i)
  end
end

local function test_search(T, keys)
  local key = T[KEY]
  for i = 1, #keys do
    local k = keys[i]
    local j = assert(search(T, T[ROOT], k))
    assert(key[j] == k)
  end
end

local function test_delete(T, keys)
  for i = 1, #keys do
    local k = keys[i]
    local j = assert(search(T, T[ROOT], k))
    if k == 9 and j == 9 then
      dump(io.open("test.dot", "w"), T):close()
    end
    delete(T, j)
  end
end

-- reverse(keys)
-- shuffle(keys)

for i = 1, 3 do
  for j = 1, 3 do
    local keys = {}

    for i = 1, 25 do
      keys[i] = i
    end

    if i % 3 == 1 then
      reverse(keys)
    elseif i % 3 == 2 then
      shuffle(keys)
    end

    local T = {
      NIL; -- [1] root
      { [0] = BLACK };  -- [2] color
      {};  -- [3] parent
      {};  -- [4] left
      {};  -- [5] right
      {};  -- [6] key
      {};  -- [7] value
    }

    test_insert(T, keys)

    if j % 3 == 1 then
      reverse(keys)
    elseif j % 3 == 2 then
      shuffle(keys)
    end

    test_search(T, keys)
    test_delete(T, keys)
    assert(T[ROOT] == NIL)
    print(json.encode(T))
  end
end
