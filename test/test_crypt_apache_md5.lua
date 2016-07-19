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

local crypt_apache_md5 = require "dromozoa.socks.crypt_apache_md5"

local function test(key, salt_string, expected)
  local result = crypt_apache_md5(key, salt_string)
  print(result)
  assert(result == expected)
end

test(
    "password",
    "$apr1$Gvvu.7Ji$w0G/FLFmHCrKxNYRhtAvM1",
    "$apr1$Gvvu.7Ji$w0G/FLFmHCrKxNYRhtAvM1")
test(
    "password",
    "$apr1$Gvvu.7Ji",
    "$apr1$Gvvu.7Ji$w0G/FLFmHCrKxNYRhtAvM1")
test(
    "password",
    "$apr1$Gvvu.7Jixxxxxxxxxxxxxxxxxxxxxxx",
    "$apr1$Gvvu.7Ji$w0G/FLFmHCrKxNYRhtAvM1")
test(
    "01234567890123456789012345678901234567890123456789012345678901234567890123456789",
    "$apr1$D9MRDWjh$G8V8I9G.d69pM7yWkGUlk0",
    "$apr1$D9MRDWjh$G8V8I9G.d69pM7yWkGUlk0")