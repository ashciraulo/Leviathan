class_name Safe
extends Object
## Reading numbers and switches from files a player could have edited or a
## crash could have cut short (saves, settings): anything that isn't the
## right kind of value gives the fallback instead of stopping the game.


## A number (or a string of one) as a float, else the fallback. Never NaN
## or infinite.
static func number(value: Variant, fallback: float) -> float:
	var out := fallback
	if value is int or value is float:
		out = float(value)
	elif value is String and value.is_valid_float():
		out = value.to_float()
	return out if is_finite(out) else fallback


## A whole number (or a string of one), else the fallback. Huge values are
## held to what an int can carry.
static func whole(value: Variant, fallback: int) -> int:
	if value is int:
		return value
	if value is float and is_finite(value):
		return int(clampf(value, -1e15, 1e15))
	if value is String and value.is_valid_int():
		return value.to_int()
	return fallback


## A true/false switch (or 0/1), else the fallback.
static func truth(value: Variant, fallback: bool) -> bool:
	if value is bool:
		return value
	if value is int or value is float:
		return value != 0
	return fallback
