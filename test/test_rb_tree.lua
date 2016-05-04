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
        assert(x == rb_tree.NIL)
      else
        x = T:successor(x)
        assert(x ~= rb_tree.NIL)
      end
    end

    local x = max
    for i = #data, 1, -1 do
      assert(T:key(x) == i)
      assert(T:get(x) == "v" .. i)
      if i == 1 then
        x = T:predecessor(x)
        assert(x == rb_tree.NIL)
      else
        x = T:predecessor(x)
        assert(x ~= rb_tree.NIL)
      end
    end

    if j % 3 == 1 then
      reverse(data)
    elseif j % 3 == 2 then
      shuffle(data)
    end

    for i = 1, #data do
      local k = data[i]
      local v = "v" .. k

      local h = T:search(k)
      assert(T:key(h) == k)
      assert(T:get(h) == v)

      local a, b = T:delete(h)
      assert(a == k)
      assert(b == v)
    end
  end
end

local T = rb_tree()
T:insert(1, "foo")
T:insert(2, "foo")
T:insert(3, "foo")
T:insert(3, "bar")
T:insert(2, "bar")
T:insert(1, "bar")
T:insert(1, "baz")
T:insert(3, "baz")
T:insert(2, "baz")

local x = T:minimum()
local data = sequence()

repeat
  sequence:push({ T:key(x), T:get(x) })
  x = T:successor(x)
until x == rb_tree.NIL

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
