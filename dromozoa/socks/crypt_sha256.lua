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

local function crypt_sha256(key, salt)
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

  local context_a = sha256()
  context_a:update(key)
  context_a:update(salt_string)

  local context_b = sha256()
  context_b:update(key)
  context_b:update(salt_string)
  context_b:update(key)
  local digest_b = context_b:finalize("bin")

  local n = #key
  while n > 32 do
    n = n - 32
    context_a:update(digest_b)
  end
  context_a:update(digest_b:sub(1, n))

  local n = #key
  while n > 0 do
    if uint32.band(n, 1) == 1 then
      context_a:update(digest_b)
    else
      context_a:update(key)
    end
    n = uint32.shr(n, 1)
  end

  local digest_a = context_a:finalize("bin")

  local context_dp = sha256()
  for _ = 1, #key do
    context_dp:update(key)
  end
  local digest_dp = context_dp:finalize("bin")

  local out = sequence_writer()
  local n = #key
  while n > 32 do
    n = n - 32
    out:write(digest_dp)
  end
  out:write(digest_dp:sub(1, n))
  local p = out:concat()

  local context_ds = sha256()
  local n = 16 + digest_a:byte(1)
  for _ = 1, n do
    context_ds:update(salt_string)
  end
  local digest_ds = context_ds:finalize("bin")

  local out = sequence_writer()
  local n = #salt_string
  while n > 32 do
    n = n - 32
    out:write(digest_ds:sub(1, n))
  end
  out:write(digest_ds:sub(1, n))
  local s = out:concat()

  local digest = digest_a
  for i = 0, rounds - 1 do
    local context_c = sha256()
    if i % 2 == 1 then
      context_c:update(p)
    else
      context_c:update(digest)
    end
    if i % 3 ~= 0 then
      context_c:update(s)
    end
    if i % 7 ~= 0 then
      context_c:update(p)
    end
    if i % 2 == 1 then
      context_c:update(digest)
    else
      context_c:update(p)
    end
    digest = context_c:finalize("bin")
  end

  local out = sequence_writer()
  out:write("$5$")
  if rounds_custom then
    out:write("rounds=", rounds, "$")
  end
  out:write(salt_string, "$")
  encode(out, digest, 1, 11, 21)
  encode(out, digest, 22, 2, 12)
  encode(out, digest, 13, 23, 3)
  encode(out, digest, 4, 14, 24)
  encode(out, digest, 25, 5, 15)
  encode(out, digest, 16, 26, 6)
  encode(out, digest, 7, 17, 27)
  encode(out, digest, 28, 8, 18)
  encode(out, digest, 19, 29, 9)
  encode(out, digest, 10, 20, 30)
  encode(out, digest, 32, 31)
  return out:concat()
end

return crypt_sha256
