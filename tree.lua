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
local NIL = { color = BLACK }

local function left_rotate(T, x)
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
end

local function right_rotate(T, x)
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
end

local function insert_fixup(T, z)
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
end

local function insert(T, z)
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
end

local uid = 0

local function dump_node(out, T, x)
  if x ~= NIL then
    uid = uid + 1
    x.uid = uid
    local color
    if x.color == RED then
      color = "red"
    else
      color = "black"
    end
    out:write(uid, " [label =  <<font color=\"white\">", xml.escape(x.key), "</font>>, fillcolor = ", color, "];\n")
    dump_node(out, T, x.left)
    dump_node(out, T, x.right)
  end
end

local function dump_edge(out, T, x, y)
  if y ~= NIL then
    out:write(x.uid, " -> ", y.uid, ";\n")
    dump_edge(out, T, y, y.left)
    dump_edge(out, T, y, y.right)
  end
end

local function dump(out, T)
  out:write("digraph g {\n")
  out:write("graph [rankdir = LR];\n")
  out:write("node [color = black, style = filled];\n")
  dump_node(out, T, T.root)
  dump_edge(out, T, T.root, T.root.left)
  dump_edge(out, T, T.root, T.root.right)
  out:write("}\n")
end

local T = { root = NIL }

insert(T, { key = 1 })
insert(T, { key = 2 })
insert(T, { key = 3 })
insert(T, { key = 4 })
insert(T, { key = 5 })
insert(T, { key = 6 })
insert(T, { key = 7 })
insert(T, { key = 8 })

-- for i = 1, 10000 do
--   insert(T, { key = math.random() })
-- end

-- print(json.encode(T))

dump(io.stdout, T)
