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
-- local NIL = {}
-- local NIL = nil
local NIL = 0

-- [1] root
-- [2] color
-- [3] parent
-- [4] left
-- [5] right
-- [6] key
-- [7] value

local function left_rotate(T, x)
  local p = T[3]
  local left = T[4]
  local right = T[5]

  local y = right[x]
  right[x] = left[y]
  if left[y] ~= NIL then
    p[left[y]] = x
  end
  p[y] = p[x]
  if p[x] == NIL then
    T[1] = y
  elseif x == left[p[x]] then
    left[p[x]] = y
  else
    right[p[x]] = y
  end
  left[y] = x
  p[x] = y

--[[
  local y = x.right
  x.right = y.left
  if y.left ~= NIL then
    y.left.p = x
  end
  y.p = x.p
  if x.p == NIL then
    T.root = y
  elseif x == x.p.left then
    x.p.left = y
  else
    x.p.right = y
  end
  y.left = x
  x.p = y
]]
end

local function right_rotate(T, x)
  local p = T[3]
  local left = T[4]
  local right = T[5]

  local y = left[x]
  left[x] = right[y]
  if right[y] ~= NIL then
    p[right[y]] = x
  end
  p[y] = p[x]
  if p[x] == NIL then
    T[1] = y
  elseif x == right[p[x]] then
    right[p[x]] = y
  else
    left[p[x]] = y
  end
  right[y] = x
  p[x] = y

--[[
  local y = x.left
  x.left = y.right
  if y.right ~= NIL then
    y.right.p = x
  end
  y.p = x.p
  if x.p == NIL then
    T.root = y
  elseif x == x.p.right then
    x.p.right = y
  else
    x.p.left = y
  end
  y.right = x
  x.p = y
]]
end

local function insert_fixup(T, z)
  local color = T[2]
  local p = T[3]
  local left = T[4]
  local right = T[5]

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
  color[T[1]] = BLACK

--[[
  while z.p.color == RED do
    if z.p == z.p.p.left then
      local y = z.p.p.right
      if y.color == RED then
        z.p.color = BLACK
        y.color = BLACK
        z.p.p.color = RED
        z = z.p.p
      else
        if z == z.p.right then
          z = z.p
          left_rotate(T, z)
        end
        z.p.color = BLACK
        z.p.p.color = RED
        right_rotate(T, z.p.p)
      end
    else
      local y = z.p.p.left
      if y.color == RED then
        z.p.color = BLACK
        y.color = BLACK
        z.p.p.color = RED
        z = z.p.p
      else
        if z == z.p.left then
          z = z.p
          right_rotate(T, z)
        end
        z.p.color = BLACK
        z.p.p.color = RED
        left_rotate(T, z.p.p)
      end
    end
  end
  T.root.color = BLACK
]]
end

local function insert(T, z)
  local color = T[2]
  local p = T[3]
  local left = T[4]
  local right = T[5]
  local key = T[6]

  local y = NIL
  local x = T[1]
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
    T[1] = z
  elseif key[z] < key[y] then
    left[y] = z
  else
    right[y] = z
  end
  left[z] = NIL
  right[z] = NIL
  color[z] = RED
  insert_fixup(T, z)

--[[
  local y = NIL
  local x = T.root
  while x ~= NIL do
    y = x
    if z.key < x.key then
      x = x.left
    else
      x = x.right
    end
  end
  z.p = y
  if y == NIL then
    T.root = z
  elseif z.key < y.key then
    y.left = z
  else
    y.right = z
  end
  z.left = NIL
  z.right = NIL
  z.color = RED
  insert_fixup(T, z)
]]
end

local function search(T, x, k)
  local left = T[4]
  local right = T[5]
  local key = T[6]

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
  local left = T[4]
  while left[x] ~= NIL do
    x = left[x]
  end
  return x

--[[
  while x.left ~= NIL do
    x = x.left
  end
  return x
]]
end

local function transplant(T, u, v)
  local p = T[3]
  local left = T[4]
  local right = T[5]

  if p[u] == NIL then
    T[1] = v
  elseif u == left[p[u]] then
    left[p[u]] = v
  else
    right[p[u]] = v
  end
  p[v] = p[u]

--[[
  if u.p == NIL then
    T.root = v
  elseif u == u.p.left then
    u.p.left = v
  else
    u.p.right = v
  end
  v.p = u.p
]]
end

local function delete_fixup(T, x)
  local color = T[2]
  local p = T[3]
  local left = T[4]
  local right = T[5]

  while x ~= T[1] and color[x] == BLACK do
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
        x = T[1]
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
        x = T[1]
      end
    end
  end
  color[x] = BLACK

--[[
  while x ~= T.root and x.color == BLACK do
    if x == x.p.left then
      local w = x.p.right
      if w.color == RED then
        w.color = BLACK
        x.p.color = RED
        left_rotate(T, x.p)
        w = x.p.right
      end
      if w.left.color == BLACK and w.right.color == BLACK then
        w.color = RED
        x = x.p
      else
        if w.right.color == BLACK then
          w.left.color = BLACK
          w.color = RED
          right_rotate(T, w)
          w = x.p.right
        end
        w.color = x.p.color
        x.p.color = BLACK
        w.right.color = BLACK
        left_rotate(T, x.p)
        x = T.root
      end
    else
      local w = x.p.left
      if w.color == RED then
        w.color = BLACK
        x.p.color = RED
        right_rotate(T, x.p)
        w = x.p.left
      end
      if w.right.color == BLACK and w.left.color == BLACK then
        w.color = RED
        x = x.p
      else
        if w.left.color == BLACK then
          w.right.color = BLACK
          w.color = RED
          left_rotate(T, w)
          w = x.p.left
        end
        w.color = x.p.color
        x.p.color = BLACK
        w.left.color = BLACK
        right_rotate(T, x.p)
        x = T.root
      end
    end
  end
  x.color = BLACK
]]
end

local function delete(T, z)
  local color = T[2]
  local p = T[3]
  local left = T[4]
  local right = T[5]
  local key = T[6]

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
    if p[x] == z then
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

--[[
  local y = z
  local y_original_color = y.color
  if z.left == NIL then
    x = z.right
    transplant(T, z, z.right)
  elseif z.right == NIL then
    x = z.left
    transplant(T, z, z.left)
  else
    y = minimum(T, z.right)
    y_original_color = y.color
    x = y.right
    if x.p == z then
      x.p = y
    else
      transplant(T, y, y.right)
      y.right = z.right
      y.right.p = y
    end
    transplant(T, z, y)
    y.left = z.left
    y.left.p = y
    y.color = z.color
  end
  if y_original_color == BLACK then
    delete_fixup(T, x)
  end
]]
end

local function dump_node(out, T, x)
  if x ~= NIL then
    local color = T[2]
    local left = T[4]
    local right = T[5]
    local key = T[6]

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
    local left = T[4]
    local right = T[5]

    out:write(x, " -> ", y, ";\n")
    dump_edge(out, T, y, left[y])
    dump_edge(out, T, y, right[y])
  end
end

local function dump(out, T)
  local left = T[4]
  local right = T[5]

  out:write("digraph g {\n")
  out:write("graph [rankdir = LR];\n")
  out:write("node [color = black, style = filled];\n")
  dump_node(out, T, T[1])
  dump_edge(out, T, T[1], left[T[1]])
  dump_edge(out, T, T[1], right[T[1]])
  out:write("}\n")
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
  local key = T[6]
  for i = 1, #keys do
    key[i] = keys[i]
    insert(T, i)
  end
end

local function test_search(T, keys)
  local key = T[6]
  for i = 1, #keys do
    local k = keys[i]
    local j = assert(search(T, T[1], k))
    assert(key[j] == k)
  end
end

local function test_delete(T, keys)
  for i = 1, #keys do
    local k = keys[i]
    local j = assert(search(T, T[1], k))
    delete(T, j)
  end
end

local keys = {}

for i = 1, 25 do
  keys[i] = i
end

-- reverse(keys)
-- shuffle(keys)

local T = {
  NIL; -- [1] root
  {};  -- [2] color
  {};  -- [3] parent
  {};  -- [4] left
  {};  -- [5] right
  {};  -- [6] key
  {};  -- [7] value
}

-- local T = {
--   root = NIL;
--   p = {};
--   left = {};
--   right = {};
--   color = {};
--   key = {};
-- }
test_insert(T, keys)
-- dump(io.stdout, T)
-- print(json.encode(T))

-- reverse(keys)
-- shuffle(keys)

test_search(T, keys)
test_delete(T, keys)
assert(T[1] == NIL)
-- dump(io.stdout, T)

