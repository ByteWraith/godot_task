extends Node2D

## Маркер спавна игрока
var marker_spawn_player: Marker2D

func _ready() -> void:
	# Ищем маркер спавна игрока
	call_deferred("systems_", "get_spawn_marker")
	# Добавляем игрока на сцену
	call_deferred("systems_", "create_player")
	# Обновляем имя локации, где находится игрок
	call_deferred("systems_", "update_name_location")
	# Подгружаем объекты на сцену
	call_deferred("systems_", "reload_item")

func systems_(variant: String):
#region Системные настройки
	# Обработка различных системных задач
	match variant:
		"get_spawn_marker":
			# Ищем маркер спавна игрока на сцене
			marker_spawn_player = find_child("spawn_player")

		"create_player":
			# Если в памяти есть игрок
			if Memory.pool_player:
				# Если найден маркер спавна
				if marker_spawn_player:
					# Добавляем игрока из пула на сцену
					var new_player_in_pool = Memory.pool_player
					self.add_child(new_player_in_pool)
					# Устанавливаем позицию игрока на позицию маркера спавна
					new_player_in_pool.global_position = marker_spawn_player.global_position
					# Очищаем пул игрока
					Memory.pool_player = null

		"update_name_location":
			# Обновляем имя текущей локации в памяти
			Memory.stats_player.location = get_tree().current_scene.name

		"reload_item":
			# Перезагрузка предметов на сцене
			if Memory.memory_items_and_doors[self.name].object:
				# Удаляем старые предметы
				for prev_item in self.get_children():
					if prev_item is StaticBody2D:
						if prev_item.get_script():
							prev_item.queue_free()

				# Создаем новые предметы из пула
				for new_item in Memory.memory_items_and_doors[self.name].object:
					var pool_object = Memory.pool_items.front()
					self.add_child(pool_object)
					# Устанавливаем позицию и тип предмета
					pool_object.global_position = new_item.position
					pool_object.variant_item = new_item.type
					pool_object._ready()
					Memory.pool_items.pop_front()
#endregion
