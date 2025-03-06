extends Area2D

## Разрешен ли выход
var access_exit : bool = false

func _ready() -> void:
#region Подготовка
	# Подключаем сигналы для входа и выхода игрока
	self.body_entered.connect(exit_player_.bind(true))
	self.body_exited.connect(exit_player_.bind(false))

	# Ждем 1 секунду перед проверкой доступа к выходу
	await get_tree().create_timer(1).timeout
	# Если текущая сцена - "outside" и локация игрока не совпадает с именем этого объекта
	if "outside" in get_tree().current_scene.name:
		if Memory.stats_player.location != self.name:
			access_exit = true
#endregion

func exit_player_(body: Node2D, enter_exit: bool):
#region Обработка входа и выхода игрока из зоны
	match enter_exit:
		true:
			# Если выход разрешен
			if access_exit:
				# Если текущая сцена - дом
				if "house" in get_tree().current_scene.name:
					# Меняем сцену на "outside"
					call_deferred("change_scenes_", "outside")
				else:
					# Если дверь открыта, меняем сцену
					if Memory.memory_items_and_doors[get_parent().name].door == "open":
						call_deferred("change_scenes_", get_parent().name)
					else:
						# Показываем интерфейс для открытия двери
						Hud.call_deferred("visible_enter_close_door_interface_", true)
						Memory.stats_player.next_location = get_parent().name
		false:
			# Разрешаем выход и скрываем интерфейс
			access_exit = true
			Hud.call_deferred("visible_enter_close_door_interface_", false)
#endregion

func change_scenes_(map_name: StringName):
#region Смена сцены
	# Сохраняем игрока в пул
	Memory.pool_player = get_tree().get_first_node_in_group("player").duplicate()
	print_rich("[color=green]", get_tree().get_node_count_in_group("player"))

	# Очищаем список объектов текущей локации
	Memory.memory_items_and_doors[get_tree().current_scene.name].object.clear()

	# Сохраняем объекты текущей локации в память
	for item in get_tree().current_scene.get_children():
		if item is StaticBody2D:
			if item.get_script():
				var dic_item = {
					"position" : item.global_position,
					"type" : item.variant_item
				}

				Memory.memory_items_and_doors[get_tree().current_scene.name].object.append(dic_item)
				Memory.pool_items.append(item.duplicate())

	# Меняем сцену
	get_tree().change_scene_to_file("res://map/" + map_name + ".tscn")
#endregion
