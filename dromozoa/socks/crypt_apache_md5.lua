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

local md5 = require "dromozoa.commons.md5"
local sequence_writer = require "dromozoa.commons.sequence_writer"
local uint32 = require "dromozoa.commons.uint32"

local encoder = {
  [0] = ".";
  [1] = "/";
}

local n = ("0"):byte() - 2
for i = 2, 11 do
  local byte = i + n
  local char = string.char(byte)
  encoder[i] = char
end

local n = ("A"):byte() - 12
for i = 12, 37 do
  local byte = i + n
  local char = string.char(byte)
  encoder[i] = char
end

local n = ("a"):byte() - 38
for i = 38, 63 do
  local byte = i + n
  local char = string.char(byte)
  encoder[i] = char
end

local function encode(out, s, i, j, k)
  if k then
    local a = s:byte(i)
    local b = s:byte(j)
    local c = s:byte(k)
    local d = a * 65536 + b * 256 + c
    local a = d % 64
    local d = (d - a) / 64
    local b = d % 64
    local d = (d - b) / 64
    local c = d % 64
    local d = (d - c) / 64
    out:write(encoder[a], encoder[b], encoder[c], encoder[d])
  else
    local b = s:byte(i)
    local a = b % 64
    local b = (b - a) / 64
    out:write(encoder[a], encoder[b])
  end
  return out
end

return function (key, salt)
  local salt_string = salt:match("^%$apr1%$([^%$]+)")
  if salt_string then
    salt_string = salt_string:sub(1, 8)
  else
    error("unsupported salt")
  end

  local A = md5()
  A:update(key)
  A:update("$apr1$")
  A:update(salt_string)

  local B = md5()
  B:update(key)
  B:update(salt_string)
  B:update(key)
  local B = B:finalize("bin")

  local n = #key
  while n > 16 do
    n = n - 16
    A:update(B)
  end
  A:update(B:sub(1, n))

  local n = #key
  while n > 0 do
    if uint32.band(n, 1) == 1 then
      A:update("\0")
    else
      A:update(key:sub(1, 1))
    end
    n = uint32.shr(n, 1)
  end
  local A = A:finalize("bin")

  for i = 0, 999 do
    local C = md5()
    if i % 2 == 1 then
      C:update(key)
    else
      C:update(A)
    end
    if i % 3 ~= 0 then
      C:update(salt_string)
    end
    if i % 7 ~= 0 then
      C:update(key)
    end
    if i % 2 == 1 then
      C:update(A)
    else
      C:update(key)
    end
    A = C:finalize("bin")
  end

  local out = sequence_writer()
  out:write("$apr1$", salt_string, "$")
  encode(out, A, 1, 7, 13)
  encode(out, A, 2, 8, 14)
  encode(out, A, 3, 9, 15)
  encode(out, A, 4, 10, 16)
  encode(out, A, 5, 11, 6)
  encode(out, A, 12)
  return out:concat()
end
