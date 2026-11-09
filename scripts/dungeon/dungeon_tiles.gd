class_name DungeonTiles
extends Object
## Builds the dungeon pieces a Room's layout asks for (gaps, hook posts,
## crates, plates, bars, the big-key door, the boss, and the Kiln's lava,
## boulders, pegs, drop hammers and Clinkers), then wires up the
## room-wide parts once every tile is placed: the gap field, the puzzle that
## opens the bars, and a listing deck.

const LETTERS := "_OK=|!GV^Yizk"


static func handles(letter: String) -> bool:
	return LETTERS.contains(letter)


static func make(letter: String, room: Room, pos: Vector2) -> Node2D:
	var tile := Vector2i(int(pos.x) / Room.TILE, int(pos.y) / Room.TILE)
	match letter:
		"_":
			return null  # Drawn and handled by the room's PitField.
		"^":
			return null  # Lava: also the PitField's.
		"Y":
			return Boulder.new()
		"i":
			return Peg.new()
		"z":
			var hammer := DropHammer.new()
			hammer.tile = tile
			return hammer
		"k":
			return Clinker.new()
		"O":
			return HookPost.new()
		"K":
			return Crate.new()
		"=":
			var plate := PressurePlate.new()
			plate.tile = tile
			return plate
		"|":
			return Bars.new()
		"!":
			var fixed := Bars.new()
			fixed.fixed = true
			return fixed
		"G":
			var door := BigDoor.new()
			door.room_coord = room.coord
			door.dungeon = room.dungeon
			door.right_half = room.tile_at(tile.x - 1, tile.y) == "G"
			return door
		"V":
			match room.dungeon:
				"kiln":
					return Slagwyrm.spawn_in(room, pos)
			return BarnacleMatriarch.spawn_in(room, pos)
	return null


static func finish(room: Room) -> void:
	var has_gap := false
	var has_puzzle := false
	for y in Room.ROWS:
		for x in Room.COLS:
			var letter := room.tile_at(x, y)
			has_gap = has_gap or letter in ["_", "^"]
			has_puzzle = has_puzzle or letter in ["=", "|"]
	if has_gap or room.lava_rise > 0.0:
		var field := PitField.new()
		field.name = "PitField"
		room.add_child(field)
	if has_puzzle or room.chest_hidden:
		var puzzle := RoomPuzzle.new()
		puzzle.name = "Puzzle"
		room.add_child(puzzle)
	if room.tilt != Vector2.ZERO:
		var deck := DeckTilt.new()
		deck.name = "DeckTilt"
		deck.push = room.tilt
		room.add_child(deck)
