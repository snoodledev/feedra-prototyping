extends Node

## ENUMS
enum PadColors {
	Blue,
	Green,
	LightBlue,
	Magenta,
	Orange,
	Purple,
	Red,
	Teal,
	White,
	Yellow
}

## ICONS
const ICON_PLAY_24 = preload("res://assets/graphics/icons/system/24px/play.svg")
const ICON_PAUSE_24 = preload("res://assets/graphics/icons/system/24px/pause.svg")

## GLOBAL VARIABLES
var is_edit_mode: bool = false

## SIGNALS
signal edit_mode_changed()
