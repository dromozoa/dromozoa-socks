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
local reader_buffer = require "dromozoa.socks.reader_buffer"

local rb = reader_buffer()
rb:write("0123456789")
rb:write("0123456789")
assert(rb:read(3) == "012")
assert(rb:read(3) == "345")
assert(rb:read(3) == "678")
assert(rb:read(3) == "901")
assert(rb:read(3) == "234")
assert(rb:read(3) == "567")
assert(not rb:read(3))
rb:close()
assert(rb:read(3) == "89")
assert(rb:read(3) == "")

local rb = reader_buffer()
rb:write("01234")
assert(rb:read(3) == "012")
assert(not rb:read(3))
assert(rb:read_some(3) == "34")
assert(rb:read_some(3) == "")

local rb = reader_buffer()
rb:write("foo")
rb:write("bar")
rb:write("baz")
rb:close()
assert(equal({ rb:read_until("(oo)") }, { "f", "oo" }))
assert(equal({ rb:read_until("rb") }, { "ba" }))
assert(equal({ rb:read_until("(a)") }, { "", "a" }))
assert(equal({ rb:read_until("(a)") }, { "z" }))
assert(equal({ rb:read_until("(a)") }, { "" }))

local rb = reader_buffer()
rb:write("foo\nbar\nbaz")
rb:close()
assert(equal({ rb:read_until("(\n)") }, { "foo", "\n" }))
assert(equal({ rb:read_until("(\n)") }, { "bar", "\n" }))
assert(equal({ rb:read_until("(\n)") }, { "baz" }))
assert(equal({ rb:read_until("(\n)") }, { "" }))

local rb = reader_buffer()
rb:write("foo\n\nbar\n")
rb:close()
assert(equal({ rb:read_until("(\n)") }, { "foo", "\n" }))
assert(equal({ rb:read_until("(\n)") }, { "", "\n" }))
assert(equal({ rb:read_until("(\n)") }, { "bar", "\n" }))
assert(equal({ rb:read_until("(\n)") }, { "" }))

local rb = reader_buffer()
rb:write(("x"):rep(512))
assert(rb:read(256) == ("x"):rep(256))
assert(rb.index == 257)
assert(#rb[1] == 512)
assert(rb:read(128) == ("x"):rep(128))
assert(rb.index == 1)
assert(#rb[1] == 128)
