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
local stream_buffer = require "dromozoa.socks.stream_buffer"

local sb = stream_buffer()
sb:write("0123456789")
sb:write("0123456789")
assert(sb:read(3) == "012")
assert(sb:read(3) == "345")
assert(sb:read(3) == "678")
assert(sb:read(3) == "901")
assert(sb:read(3) == "234")
assert(sb:read(3) == "567")
assert(not sb:read(3))
sb:close()
assert(sb:read(3) == "89")
assert(sb:read(3) == "")

local sb = stream_buffer()
sb:write("01234")
assert(sb:read(3) == "012")
assert(not sb:read(3))
assert(sb:read_some(3) == "34")
assert(sb:read_some(3) == "")

local sb = stream_buffer()
sb:write("foo")
sb:write("bar")
sb:write("baz")
sb:close()
assert(equal({ sb:read_until("(oo)") }, { "f", "oo" }))
assert(equal({ sb:read_until("rb") }, { "ba" }))
assert(equal({ sb:read_until("(a)") }, { "", "a" }))
assert(equal({ sb:read_until("(a)") }, { "z" }))
assert(equal({ sb:read_until("(a)") }, { "" }))

local sb = stream_buffer()
sb:write("foo\nbar\nbaz")
sb:close()
assert(equal({ sb:read_until("(\n)") }, { "foo", "\n" }))
assert(equal({ sb:read_until("(\n)") }, { "bar", "\n" }))
assert(equal({ sb:read_until("(\n)") }, { "baz" }))
assert(equal({ sb:read_until("(\n)") }, { "" }))

local sb = stream_buffer()
sb:write("foo\n\nbar\n")
sb:close()
assert(equal({ sb:read_until("(\n)") }, { "foo", "\n" }))
assert(equal({ sb:read_until("(\n)") }, { "", "\n" }))
assert(equal({ sb:read_until("(\n)") }, { "bar", "\n" }))
assert(equal({ sb:read_until("(\n)") }, { "" }))

local sb = stream_buffer()
sb:write(("x"):rep(512))
assert(sb:read(254) == ("x"):rep(254))
assert(sb.index == 255)
assert(#sb[1] == 512)
assert(sb:read(254) == ("x"):rep(254))
assert(sb.index == 1)
assert(#sb[1] == 4)
