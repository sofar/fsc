
## fsc

This mod is designed to help write more secure formspec handling
code. It achieves this by throwing out the concept of "formspec
names" entirely and giving each formspec shown to the player a unique,
random ID. The player can only then submit form data using this unique
ID, and, the handling code can invalidate the ID during processing
automatically.

This reduces the risk that an attacker can forge formspec data and
send uninvited packets to the server. The server will discard any
form data that appears to come from a client that is attempting to
use old or incorrect fsc-created forms and will note this event in
the minetest log.

Because of the simplicity of the approach, mods will no longer need
to focus on basic formspec handling code and can instead spent their
time verifying the proper permissions and input data correctness.

This mod also provides a much more simple way to maintain a formspec
"context" and pass it along to subsequent formspecs. This makes
writing formspec code simpler as the context does not need to be
maintained outside the formspec handling or creation code, and no
memory leakage needs to be worried about.

A player can also only ever obtain one context, and attempting to
use an invalid or outdated context will result in all current valid
formspec contexts being revoked. Combined together, all these features
make formspecs a lot safer to work with.

## Usage

The basic workflow of `fsc` contains of a single function call. Outside
of this function call, there are no other API functions or data.

```
function fsc.show(name, formspec, context, callback)
	-- `name`: a playername,
	-- `formspec`: a valid formspec string,
	-- `context`: any data, may be `nil`
	-- `callback`: function(player, fields, context).
```

The return value of `fsc.show()` is always `nil` - it returns nothing.

The callback function will only be called if basic sanity checks on the data
pass requirements. You can implement it simply as follows:

```
local function callback(player, fields, context)
	-- `player`: player object,
	-- `fields`: table containing formspec data returned by the player client,
	-- `context`: any data, will never be `nil`. If no context was passed
	--            to `fsc.show()`, it will contain `{}`
	return true
end
```

The return value of the callback may be `nil` or `true`. If you return
`nil`, the context is not invalidated, and the player may submit the
formspec using the same ID again. This is useful if the player merely
selects a list item or otherwise performs an action in the form that
does not cause the form to be closed on the client, and you wish to
keep the form open.

If you return `true`, or if you return `nil` and `fields.quit` is set,
then the fsc code will invalidate the ID and close the formspec. You
should return `true` unless you want to keep the form open to the
player.

Making a simple callback handler that shows a new form is therefore
relatively straightforward. The below example passes the current
context data through to the new form. The old form will close, and
the new form will appear to the player with the new content.

```
local function callback(player, fields, context)
	local name = player:get_player_name()
	if fields.rename then
		fsc.show(name,
			"field[new_name;What is the new name?;" .. minetest.formspec_escape(context.old_name) .. "]",
			context,
			callback)
		return
	else
		-- do something else
		return true
	end
end
```

In some cases, you may wish to show a form without having the
need for a callback, in case the content is just informational and
non-interactive. In that case, you can omit a callback handler by
just inserting an empty callback handler, as follows:

  `fsc.show(name, formspec, {}, function() end)`

## Node Formspecs

Node formspecs are not handled. Due to the nature of node/inventory
formspecs, it is inherently impossible to perform the same checks on
node/inventory formspecs as `fsc` can do for (normal) formspecs.

## License

FormSpec Context ('fsc') mod for minetest, licensed under the `ISC` license:

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

