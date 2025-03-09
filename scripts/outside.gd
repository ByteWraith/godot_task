extends Node2D

func _ready() -> void:
	# Отложенный вызов системных функций
	call_deferred("systems_", "load_player")
	# Обновить текстуру дверей
	call_deferred("systems_", "texture_door")
	# Перезагрузить объекты на карте
	call_deferred("systems_", "reload_item")

func systems_(variant: String):
#region Системные настройки
	# Обработка различных системных задач
	match variant:
		"load_player":
			# Загрузка игрока на сцену
			if Memory.pool_player:
				# Если игрок уже существует в пуле
				if Memory.stats_player.location:
					print("YES")
					var new_pool_player = Memory.pool_player
					get_node("scenes").add_child(new_pool_player)
					# Устанавливаем позицию игрока на выходе из предыдущей локации
					new_pool_player.global_position = get_node("scenes/" + Memory.stats_player.location + "/" + "exit").global_position
					Memory.pool_player = null
			else:
				# Если игрок не существует, создаем нового
				Memory.stats_player.location = self.name
				var new_player_instantiate = preload("res://prefab/player.tscn").instantiate()
				get_node("scenes").add_child(new_player_instantiate)
				# Устанавливаем начальную позицию игрока
				new_player_instantiate.global_position = Vector2(282, 172)

		"texture_door":
			# Обновление текстур дверей
			for house in get_node("scenes").get_children():
				if "house" in house.name and house is StaticBody2D:
					match Memory.memory_items_and_doors[house.name].door:
						"open":
							# Устанавливаем текстуру для открытой двери
							house.get_node("door").texture.region = Rect2(16, 113, 16, 15)
						"close":
							# Устанавливаем текстуру для закрытой двери
							house.get_node("door").texture.region = Rect2(16, 80, 16, 17)

		"reload_item":
			# Перезагрузка предметов на сцене
			if Memory.memory_items_and_doors.outside.object:
				# Удаляем старые предметы
				for prev_item in self.get_children():
					if prev_item is StaticBody2D:
						if prev_item.get_script():
							prev_item.queue_free()

				# Создаем новые предметы из пула
				for new_item in Memory.memory_items_and_doors.outside.object:
					var pool_object = Memory.pool_items.front()
					self.add_child(pool_object)
					# Устанавливаем позицию и тип предмета
					pool_object.global_position = new_item.position
					pool_object.variant_item = new_item.type
					pool_object._ready()
					Memory.pool_items.pop_front()
#endregion

func change_scenes_(map_name: StringName):
#region Смена сцены
	# Сохраняем игрока в пул
	Memory.pool_player = get_tree().get_first_node_in_group("player").duplicate()

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
