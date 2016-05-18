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

local s = stream()
s:write("foo")
s:write("bar")
s:write("baz")
s:close()
assert(equal({ s:read_until("(oo)") }, { "f", "oo" }))
assert(equal({ s:read_until("rb") }, { "ba" }))
assert(equal({ s:read_until("(a)") }, { "", "a" }))
assert(equal({ s:read_until("(a)") }, { "z" }))
assert(equal({ s:read_until("(a)") }, { "" }))

local s = stream()
s:write("foo\nbar\nbaz")
s:close()
assert(equal({ s:read_until("(\n)") }, { "foo", "\n" }))
assert(equal({ s:read_until("(\n)") }, { "bar", "\n" }))
assert(equal({ s:read_until("(\n)") }, { "baz" }))
assert(equal({ s:read_until("(\n)") }, { "" }))

local s = stream()
s:write("foo\n\nbar\n")
s:close()
assert(equal({ s:read_until("(\n)") }, { "foo", "\n" }))
assert(equal({ s:read_until("(\n)") }, { "", "\n" }))
assert(equal({ s:read_until("(\n)") }, { "bar", "\n" }))
assert(equal({ s:read_until("(\n)") }, { "" }))
