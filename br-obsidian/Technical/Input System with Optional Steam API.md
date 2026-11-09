check for steam api, init if it exists

get list of devices steam api will be sending events for

wire up steam device connect / disconnect
- these need to block godot's connect/disconnect functions

get list of input devices godot knows about. de-duplicate steam api

wire up godot-native device connect / disconnect
 
eat input from devices steam is handling. steam wrapper will send virtual device events instead

load input map from project settings

apply user overrides from keybind settings to the input map

keybinds are device-agnostic. every keybind listens to every device at all times.

this all only aplies to controllers. keyboard input is done seperately