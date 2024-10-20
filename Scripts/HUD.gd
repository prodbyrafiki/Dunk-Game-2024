extends CanvasLayer

@onready var current_weapon_label = $VBoxContainer/HBoxContainer/CurrentWeapon
@onready var current_ammo_label = $VBoxContainer/HBoxContainer2/CurrentAmmo
@onready var current_weapon_stack = $VBoxContainer/HBoxContainer3/WeaponStack



func _on_weapons_manager_update_ammo(Ammo):
	current_ammo_label.set_text(str(Ammo[0])+" / "+str(Ammo[1]))


func _on_weapons_manager_update_weapon_stack(Weapon_Stack):
	current_weapon_stack.set_text("")
	for i in Weapon_Stack:
		current_weapon_stack.text += "\n" + i
	


func _on_weapons_manager_weapon_changed(Weapon_Name):
	current_weapon_label.set_text(Weapon_Name)
