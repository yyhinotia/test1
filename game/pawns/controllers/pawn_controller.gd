class_name PawnController
extends Node

var pawn: Pawn

func bind(new_pawn: Pawn) -> void:
	pawn = new_pawn

func _physics_process(delta: float) -> void:
	if pawn == null or not pawn.is_alive():
		return
	update_controller(delta)

func update_controller(_delta: float) -> void:
	pass