# Heredita

Heredita is a multiplayer map painting and roleplaying sandbox built with Godot.

This repository contains the Godot client and WebSocket room server.

## Run from source

1. Install Godot 4.7
2. Clone this repository.
3. Import `project.godot` into Godot and let the initial asset import finish.
4. Done! Yay!

### Backend configuration

Editor runs and debug builds default to local services. Release builds use the hosted endpoints configured in [Static.gd](libraries/static/Static.gd):

| Service | Editor / debug default | Release default |
| --- | --- | --- |
| Web backend | `http://127.0.0.1:9000` | `https://app.heredita.net` |
| Room server | `ws://127.0.0.1:9001` | `wss://gameserver.heredita.net` |

You can override either like so:

```sh
godot --path . -- \
  --heredita-url=http://127.0.0.1:9000 \
  --gameserver-url=ws://127.0.0.1:9001
```

The main menu can start without these services, but to do playtesting you'll need to run a gameserver. Generally for development you shouldn't need to [and can't, at this time] host a custom api url, but you can also just exclude it if it's not needed [some stuff, incl. room discovery, will break; we're looking into a solution for room discovery so you can do multiplayer testing]

### Room server

After importing the project, start the included room server with:

```sh
godot --headless --path . -- \
  --server \
  --server-port=9001 \
  --heredita-url=http://127.0.0.1:9000
```

`--server` switches the application to use `server/Server.tscn`. `--server-port` sets the port to use... obviously. [defaults to 443 for https]

Release server builds require both `--certificate-path=<path>` and `--private-key=<path>` but debug builds don't, so you're recommended to use debug builds unless you have a domain to use.

## Project layout

| Path | Contents |
| --- | --- |
| `scenes/main_menu/` | Landing page and assorted other non-ingame stuff |
| `scenes/mapper/` | The game itself |
| `server/` | Gameserver backend |
| `libraries/` | Various libraries built by us for the game |
| `assets/` | All game assets. Currently a bit disorganized. |
| `settings.tres` | Settings |
