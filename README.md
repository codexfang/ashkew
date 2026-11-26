# Ashkew

Co-op anomaly-horror puzzle game for Roblox. Every player sees a *different* version
of the same room, and the team has to talk it out and vote on which anomaly is real
before the room folds in on them.

## Running it

1. Install [Rokit](https://github.com/rojo-rbx/rokit), then run `rokit install` in this folder (installs Rojo).
2. Install the Rojo plugin in Roblox Studio.
3. `rojo serve`, open a Baseplate in Studio, and click **Connect** in the Rojo plugin.
4. Test multiplayer with **Test → Clients and Servers → 2 Players → Start**.

## Layout

| Folder        | Ends up in                                 |
|---------------|--------------------------------------------|
| `src/server`  | `ServerScriptService.Server`               |
| `src/client`  | `StarterPlayer.StarterPlayerScripts.Client`|
| `src/shared`  | `ReplicatedStorage.Shared`                 |
