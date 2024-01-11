extends Control


@onready var dialogue_player: DialoguePlayer = %DialoguePlayer
@onready var dialogue_label: Label = %DialogueLabel
@onready var advance_indicator: Control = %AdvanceIndicator


func _process(_delta: float) -> void:
	advance_indicator.visible = !dialogue_player.is_playing()


func _on_dialogue_player_text_changed(text: String) -> void:
	dialogue_label.text = text


func _on_dialogue_player_visible_character_count_changed(count: int) -> void:
	dialogue_label.visible_characters = count
