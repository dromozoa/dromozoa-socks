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

local sequence_writer = require "dromozoa.commons.sequence_writer"
local sha256 = require "dromozoa.commons.sha256"
local uint32 = require "dromozoa.commons.uint32"

local ROUNDS_DEFAULT = 5000
local ROUNDS_MIN = 1000
local ROUNDS_MAX = 999999999

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
    local a = s:byte(i)
    local b = s:byte(j)
    local c = a * 256 + b
    local a = c % 64
    local c = (c - a) / 64
    local b = c % 64
    local c = (c - b) / 64
    out:write(encoder[a], encoder[b], encoder[c])
  end
  return out
end

local function loop(rounds, A_C, P, S)
  for i = 1, rounds do
    local C = sha256()
    if i % 2 == 0 then
      C:update(P)
    else
      C:update(A_C)
    end
    if i % 3 ~= 1 then
      C:update(S)
    end
    if i % 7 ~= 1 then
      C:update(P)
    end
    if i % 2 == 0 then
      C:update(A_C)
    else
      C:update(P)
    end
    A_C = C:finalize("bin")
  end
  return A_C
end

return function (key, salt)
  local rounds, salt_string = salt:match("^%$5%$rounds=(%d+)%$([^%$]+)")
  local rounds_custom = false
  if rounds then
    rounds = tonumber(rounds)
    rounds_custom = true
  else
    rounds = ROUNDS_DEFAULT
    salt_string = salt:match("^%$5%$([^%$]+)")
  end
  if salt_string then
    salt_string = salt_string:sub(1, 16)
  else
    error("unsupported salt")
  end

  if rounds < ROUNDS_MIN then
    rounds = ROUNDS_MIN
  end
  if rounds > ROUNDS_MAX then
    rounds = ROUNDS_MAX
  end

  local B = sha256()
  B:update(key)
  B:update(salt_string)
  B:update(key)
  local B = B:finalize("bin")

  local A = sha256()
  A:update(key)
  A:update(salt_string)
  local n = #key
  while n > 32 do
    n = n - 32
    A:update(B)
  end
  A:update(B:sub(1, n))
  local n = #key
  while n > 0 do
    if uint32.band(n, 1) == 1 then
      A:update(B)
    else
      A:update(key)
    end
    n = uint32.shr(n, 1)
  end
  local A = A:finalize("bin")

  local DP = sha256()
  for _ = 1, #key do
    DP:update(key)
  end
  local DP = DP:finalize("bin")
  local out = sequence_writer()
  local n = #key
  while n > 32 do
    n = n - 32
    out:write(DP)
  end
  out:write(DP:sub(1, n))
  local P = out:concat()

  local DS = sha256()
  local n = 16 + A:byte(1)
  for _ = 1, n do
    DS:update(salt_string)
  end
  local DS = DS:finalize("bin")
  local out = sequence_writer()
  local n = #salt_string
  while n > 32 do
    n = n - 32
    out:write(DS:sub(1, n))
  end
  out:write(DS:sub(1, n))
  local S = out:concat()

  local C = loop(rounds, A, P, S)

  local out = sequence_writer()
  out:write("$5$")
  if rounds_custom then
    out:write("rounds=", rounds, "$")
  end
  out:write(salt_string, "$")
  encode(out, C, 1, 11, 21)
  encode(out, C, 22, 2, 12)
  encode(out, C, 13, 23, 3)
  encode(out, C, 4, 14, 24)
  encode(out, C, 25, 5, 15)
  encode(out, C, 16, 26, 6)
  encode(out, C, 7, 17, 27)
  encode(out, C, 28, 8, 18)
  encode(out, C, 19, 29, 9)
  encode(out, C, 10, 20, 30)
  encode(out, C, 32, 31)
  return out:concat()
end