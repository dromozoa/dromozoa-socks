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

    assert(T:minimum():key() == 1)
    assert(T:minimum():get() == "v1")
    assert(T:maximum():key() == 25)
    assert(T:maximum():get() == "v25")

    if j % 3 == 1 then
      reverse(data)
    elseif j % 3 == 2 then
      shuffle(data)
    end

    for i = 1, #data do
      local k = data[i]
      local v = "v" .. k
      local node = T:search(k)
      assert(node:key() == k)
      assert(node:get() == v)
      local a, b = node:delete()
      assert(a == k)
      assert(b == v)
    end
    assert(T:empty())
    print(dumper.encode(T))
  end
end
