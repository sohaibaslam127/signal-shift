class_name PuzzleResult
extends VBoxContainer
## Victory panel content: star rating, move summary and personal-best note.

var _stars: StarRating
var _summary: Label
var _note: Label


func _init() -> void:
	add_theme_constant_override("separation", 10)
	_stars = StarRating.new()
	_stars.custom_minimum_size = Vector2(320, 96)
	_stars.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(_stars)
	_summary = Label.new()
	_summary.theme_type_variation = &"StatLabel"
	_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_summary)
	_note = Label.new()
	_note.theme_type_variation = &"DimLabel"
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_note)


## `outcome` comes from GameManager.complete_current().
func show_result(puzzle: PuzzleData, moves: int, stars: int, outcome: Dictionary) -> void:
	_summary.text = "%d %s · par %d" % [moves, "move" if moves == 1 else "moves", puzzle.par]
	var notes := PackedStringArray()
	if bool(outcome.get("new_best", false)) and not bool(outcome.get("first_clear", false)):
		notes.append("New best!")
	elif int(outcome.get("best_moves", 0)) > 0 and int(outcome.get("best_moves", 0)) < moves:
		notes.append("Best: %d moves" % int(outcome["best_moves"]))
	if stars < 3:
		notes.append("Match par for 3 stars.")
	var reward := str(outcome.get("reward", ""))
	if not reward.is_empty():
		notes.append(reward)
	_note.text = "\n".join(notes)
	_note.visible = not notes.is_empty()
	if SaveService.progress.reduced_motion:
		_stars.stars = stars
	else:
		_stars.stars = 0
		var tween := create_tween()
		for i in stars:
			tween.tween_interval(0.18)
			tween.tween_callback(func() -> void:
				_stars.stars = i + 1
				AudioService.play(&"tap", 1.0 + i * 0.25))
