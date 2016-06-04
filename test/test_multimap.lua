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
local multimap = require "dromozoa.socks.multimap"

local function count(range)
  local count = 0
  for _ in range:each() do
    count = count + 1
  end
  return count
end

local m = multimap()

assert(m:empty())
assert(not m:single())

m:insert(1, "foo")

assert(not m:empty())
assert(m:single())

m:insert(2, "foo")
m:insert(3, "foo")
m:insert(1, "bar")
m:insert(2, "bar")

assert(m:equal_range(0):empty())
assert(not m:equal_range(1):empty())
assert(not m:equal_range(2):empty())
assert(not m:equal_range(3):empty())
assert(m:equal_range(4):empty())

assert(not m:equal_range(0):single())
assert(not m:equal_range(1):single())
assert(not m:equal_range(2):single())
assert(m:equal_range(3):single())
assert(not m:equal_range(4):single())

m:insert(3, "bar")
m:insert(1, "baz")
m:insert(2, "baz")
m:insert(3, "baz")

assert(count(m) == 9)

assert(count(m:equal_range(0)) == 0)
assert(count(m:equal_range(1)) == 3)
assert(count(m:equal_range(2)) == 3)
assert(count(m:equal_range(3)) == 3)
assert(count(m:equal_range(4)) == 0)

assert(count(m:upper_bound(0)) == 0)
assert(count(m:upper_bound(1)) == 3)
assert(count(m:upper_bound(2)) == 6)
assert(count(m:upper_bound(3)) == 9)
assert(count(m:upper_bound(4)) == 9)

assert(count(m:lower_bound(0)) == 9)
assert(count(m:lower_bound(1)) == 9)
assert(count(m:lower_bound(2)) == 6)
assert(count(m:lower_bound(3)) == 3)
assert(count(m:lower_bound(4)) == 0)

assert(count(m:upper_bound(1.5)) == 3)
assert(count(m:lower_bound(2.5)) == 3)

assert(m:upper_bound(0.5):delete() == 0)
assert(m:upper_bound(1.5):delete() == 3)

assert(m:lower_bound(3.5):delete() == 0)
assert(m:lower_bound(2.5):delete() == 3)
assert(count(m) == 3)

m:insert(42, "qux")

assert(equal({ m:head() }, { 2, "foo" }))
assert(equal({ m:tail() }, { 42, "qux" }))
assert(equal({ m:equal_range(42):head() }, { 42, "qux" }))
assert(equal({ m:equal_range(42):tail() }, { 42, "qux" }))

local m = multimap()
m:insert(1, "a")
m:insert(2, "b")
m:insert(3, "c")
m:insert(4, "d")
local count = 0
for k, v in m:each() do
  count = count + 1
  if v == "b" then
    -- m:insert(3, "x")
    m:insert(4, "x")
  end
end
assert(count == 4)