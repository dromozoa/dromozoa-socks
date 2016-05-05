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

local multimap = require "dromozoa.socks.multimap"

local m = multimap()
m:insert(1, "foo")
m:insert(2, "foo")
m:insert(3, "foo")
m:insert(1, "bar")
m:insert(2, "bar")
m:insert(3, "bar")
m:insert(1, "baz")
m:insert(2, "baz")
m:insert(3, "baz")

for k, v in m:upper_bound(2):each() do
  print(k, v)
end

for k, v, h in m:each() do
  print(k, v, h.a, h.b)
end
assert(m:size() == 9)

for k, v, h in m:each() do
  h:delete()
end
assert(m:size() == 0)
