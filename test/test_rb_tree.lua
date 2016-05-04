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

local dumper = require "dromozoa.commons.dumper"
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
      local v = "v" .. k
      T:insert(k, v)
    end
    print(dumper.encode(T))

    local a = assert(T:minimum())
    local b = assert(T:maximum())
    assert(T:key(a) == 1)
    assert(T:get(a) == "v1")
    assert(T:key(b) == 25)
    assert(T:get(b) == "v25")

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
    assert(T:empty())
    print(dumper.encode(T))
  end
end

local T = rb_tree()
T:insert(1, "foo")
T:insert(2, "foo")
T:insert(3, "foo")
T:insert(1, "bar")
T:insert(2, "bar")
T:insert(3, "bar")
T:insert(1, "baz")
T:insert(2, "baz")
T:insert(3, "baz")

local x = T:minimum()
local max = T:maximum()
while true do
  print(T:key(x), T:get(x))
  if x == max then
    x = T:next(x)
    assert(x == 0)
    break
  else
    x = T:next(x)
  end
end

--[[
local x = T:search(2)
assert(x:key() == 2)
assert(x:get() == "foo")

local x = T:search(1.5)
assert(x.handle == 0)

local x = T:lower_bound(2)
assert(x:key() == 2)
assert(x:get() == "foo")

local x = T:lower_bound(1.5)
assert(x:key() == 2)
assert(x:get() == "foo")

local x = T:upper_bound(2)
assert(x:key() == 3)
assert(x:get() == "foo")

local x = T:upper_bound(2.5)
assert(x:key() == 3)
assert(x:get() == "foo")

print("--")
for k, v in T:each() do
  print(k, v)
end

print("--")
for k, v in T:equal_range(2):each() do
  print(k, v)
end
]]
