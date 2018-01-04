
--[[

  FormSpec Context ('fsc') mod for minetest

  Copyright (C) 2018 Auke Kok <sofar@foo-projects.org>

  Permission to use, copy, modify, and/or distribute this software for
  any purpose with or without fee is hereby granted, provided that the
  above copyright notice and this permission notice appear in all copies.

  THE SOFTWARE IS PROVIDED "AS IS" AND ISC DISCLAIMS ALL WARRANTIES
  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL ISC BE LIABLE FOR ANY
  SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
  AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING
  OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

]]--

fsc = {}

local _data = {}

local SRNG = SecureRandom()
assert(SRNG)

local function make_new_random_id()
	local s = SRNG:next_bytes(16)
	return s:gsub(".", function(c) return string.format("%02x", string.byte(c)) end)
end

function fsc.show(name, formspec, context, callback)
	assert(name)
	assert(formspec)
	assert(callback)

	if not context then
		context = {}
	end

	-- invalidate any old data from previous formspecs by overwriting it
	local id = "fsc:" .. make_new_random_id()
	_data[name] = {
		id = id,
		name = name,
		context = context,
		callback = callback,
	}

	minetest.show_formspec(name, id, formspec)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if not formname:match("fsc:") then
		-- invalidate fsc data for this player
		local name = player:get_player_name()
		_data[name] = nil

		return false
	end

	local name = player:get_player_name()
	local data = _data[name]
	if not data then
		minetest.log("warning", "fsc: no data for formspec sent by " .. name)
		minetest.close_formspec(name, formname)
		return
	end
	if data.id ~= formname then
		minetest.log("warning", "fsc: invalid id for formspec sent by " .. name)
		minetest.close_formspec(name, formname)
		_data[name] = nil
		return
	end
	if data.name ~= name then
		minetest.log("error", "fsc: internal error (name mismatch)")
		minetest.close_formspec(name, formname)
		_data[name] = nil
		return
	end
	if data then
		if data.callback(player, fields, data.context) then
			minetest.close_formspec(name, formname)
			_data[name] = nil
		elseif fields.quit then
			_data[name] = nil
		end
	end
end)

minetest.register_on_leaveplayer(function(player)
	_data[player:get_player_name()] = nil
end)

