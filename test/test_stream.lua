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
local dumper = require "dromozoa.commons.dumper"
local stream = require "dromozoa.socks.stream"

local s = stream()
s:write("0123456789")
s:write("0123456789")
assert(s:read(3) == "012")
assert(s:read(3) == "345")
assert(s:read(3) == "678")
assert(s:read(3) == "901")
assert(s:read(3) == "234")
assert(s:read(3) == "567")
assert(not s:read(3))
s:close()
assert(s:read(3) == "89")
assert(s:read(3) == "")

local s = stream()
s:write("01234")
assert(s:read(3) == "012")
assert(not s:read(3))
assert(s:read_some(3) == "34")
assert(s:read_some(3) == "")

--[[

local s = stream()
assert(not s:next_char(1, 1, 0))
assert(not s:find_char(1, 1, "f"))

s:write("foo")
s:write("bar")
s:write("baz")

assert(equal({ s:next_char(1, 1, 0) }, { 1, 1 }))
assert(equal({ s:next_char(1, 1, 1) }, { 1, 2 }))
assert(equal({ s:next_char(1, 1, 2) }, { 1, 3 }))
assert(equal({ s:next_char(1, 1, 3) }, { 2, 1 }))
assert(equal({ s:next_char(2, 2, 4) }, { 3, 3 }))
assert(not s:next_char(2, 2, 5))

assert(equal({ s:find_char(1, 1, "f") }, { 1, 1 }))
assert(equal({ s:find_char(1, 1, "o") }, { 1, 2 }))
assert(equal({ s:find_char(1, 1, "b") }, { 2, 1 }))
assert(equal({ s:find_char(2, 2, "b") }, { 3, 1 }))
assert(not s:find_char(1, 2, "f"))

-- local s = stream()
-- s:write("abcdefgh")
-- s:write("ijklmnop")
-- s:write("qrstuvwx")
-- s:write("yz")
-- assert(s:find("a") == 1)
-- assert(s:find("h") == 8)
-- assert(s:find("q") == 17)
-- assert(s:find("x") == 24)
-- assert(s:find("z") == 26)
]]
