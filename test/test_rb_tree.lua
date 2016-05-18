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

local equal = require "dromozoa.commons.equal"
local sequence = require "dromozoa.commons.sequence"
local xml = require "dromozoa.commons.xml"
local rb_tree = require "dromozoa.socks.rb_tree"

local function reverse(data)
  table.sort(data, function (a, b) return a > b end)
end

local function shuffle(data)
  for i = #data, 2, -1 do
    local j = math.random(1, i)
    local k = data[i]
    data[i] = data[j]
    data[j] = k
  end
end

local RED = 0
local BLACK = 1
local NIL = 0

local function write_dot_node(out, T, x)
  if x ~= NIL then
    local color = T[1]
    local left = T[3]
    local right = T[4]

    local c
    if color[x] == RED then
      c = "red"
    else
      c = "black"
    end
    local label = "[" .. T:key(x) .. "]=" .. ("%q"):format(T:get(x))
    out:write(x, " [label =  <<font color=\"white\">", xml.escape(label), "</font>>, fillcolor = ", c, "];\n")
    write_dot_node(out, T, left[x])
    write_dot_node(out, T, right[x])
  end
end

local function write_dot_edge(out, T, x, y, label)
  if y ~= NIL then
    local left = T[3]
    local right = T[4]

    out:write(x, " -> ", y, "[label = <", xml.escape(label), ">];\n")
    write_dot_edge(out, T, y, left[y], "L")
    write_dot_edge(out, T, y, right[y], "R")
  end
end

local function write_dot(out, T)
  out:write([[
digraph g {
node [color = black, style = filled];
]])

  local left = T[3]
  local right = T[4]
  local root = T.root
  write_dot_node(out, T, root)
  write_dot_edge(out, T, root, left[root], "L")
  write_dot_edge(out, T, root, right[root], "R")

  out:write("}\n")
  return out
end

for i = 1, 3 do
  for j = 1, 3 do
    local data = {}
    for i = 1, 25 do
      data[i] = i
    end

    if i % 3 == 1 then
      reverse(data)
    elseif i % 3 == 2 then
      shuffle(data)
    end

    local T = rb_tree()
    for i = 1, #data do
      local k = data[i]
      T:insert(k, "v" .. k)
    end

    local min = T:minimum()
    assert(T:key(min) == 1)
    assert(T:get(min) == "v1")
    assert(T:predecessor(T:successor(min)) == min)

    local max = T:maximum()
    assert(T:key(max) == 25)
    assert(T:get(max) == "v25")
    assert(T:successor(T:predecessor(max)) == max)

    local x = min
    for i = 1, #data do
      assert(T:key(x) == i)
      assert(T:get(x) == "v" .. i)
      if i == #data then
        x = T:successor(x)
        assert(not x)
      else
        x = T:successor(x)
        assert(x)
      end
    end

    local x = max
    for i = #data, 1, -1 do
      assert(T:key(x) == i)
      assert(T:get(x) == "v" .. i)
      if i == 1 then
        x = T:predecessor(x)
        assert(not x)
      else
        x = T:predecessor(x)
        assert(x)
      end
    end

    assert(not T:empty())

    if j % 3 == 1 then
      reverse(data)
    elseif j % 3 == 2 then
      shuffle(data)
    end

    for i = 1, #data do
      local k = data[i]
      local v = "v" .. k

      local h = assert(T:search(k))
      assert(T:key(h) == k)
      assert(T:get(h) == v)

      local a, b = T:delete(h)
      assert(a == k)
      assert(b == v)
    end

    assert(T:empty())
    assert(equal(T, rb_tree()))
  end
end

local T = rb_tree()

assert(not T:minimum())
assert(not T:maximum())
assert(not T:search(1))
assert(not T:search(4))

T:insert(1, "foo")
T:insert(2, "foo")
T:insert(3, "foo")
T:insert(3, "bar")
T:insert(2, "bar")
T:insert(1, "bar")
T:insert(1, "baz")
T:insert(3, "baz")
T:insert(2, "baz")

assert(T:minimum())
assert(T:maximum())
assert(T:search(1))
assert(T:search(2))
assert(T:search(3))
assert(not T:search(0))
assert(not T:search(4))

local x = T:minimum()
local data = sequence()

repeat
  sequence:push({ T:key(x), T:get(x) })
  x = T:successor(x)
until not x

assert(equal(data, {
  { 1, "foo" };
  { 1, "bar" };
  { 1, "baz" };
  { 2, "foo" };
  { 2, "bar" };
  { 2, "baz" };
  { 3, "foo" };
  { 3, "bar" };
  { 3, "baz" };
}))

write_dot(assert(io.open("test.dot", "w")), T):close()

for i = 1, 3 do
  local x = assert(T:lower_bound(i))
  assert(T:get(x) == "foo")
  local x = assert(T:upper_bound(i))
  assert(T:get(x) == "baz")
end

assert(T:lower_bound(0) == T:minimum())
assert(T:upper_bound(4) == T:maximum())

assert(not T:lower_bound(4))
assert(not T:upper_bound(0))

assert(not T:empty())
