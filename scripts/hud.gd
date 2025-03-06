extends CanvasLayer

## Задние ячейки инвентаря
@onready var back: GridContainer = $inventory/back
## Основные ячейки инвентаря
@onready var grid: GridContainer = $inventory/grid

## Инвентарь
@onready var inventory: Control = $inventory
## Открыть/закрыть инвентарь
var open_close_: bool
## Последний предмет, по которому нажали
var last_item : Node

## Интерфейс, предлагающий войти в дом
@onready var add_open_door: Control = $interface/add_open_door

## Интерфейс здоровья
@onready var hp: TextureProgressBar = $interface/hud/hp
## Текст здоровья
@onready var text_hp: Label = $interface/hud/hp/text
## Количество ключей
@onready var text_key: Label = $interface/hud/key/text
## Лейбл о взаимодействии
@onready var interactive_add: Control = $interface/interactive_add

## Кнопка удаления предмета из инвентаря
@onready var delete: Button = $inventory/delete
## Кнопка использования предмета из инвентаря
@onready var use: Button = $inventory/use

func _input(event: InputEvent) -> void:
#region Управление
	# Если игрок нажал открыть инвентарь
	if Input.is_action_just_pressed("ui_inventory"):
		# Переключаем переменную открыть/закрыть
		open_close_ = !open_close_
		# Вызываем метод инвентаря
		open_close_inventory_(open_close_)
#endregion

func open_close_inventory_(variant:bool):
#region Открыть или закрыть инвентарь
	# Включить/выключить видимость инвентаря
	inventory.visible = variant
	# Разрешить/Запретить двигаться персонажу
	Memory.stats_player.stop = variant
	# Обновить инвентарь
	call_deferred("update_inventory_","update")
	# Подключить кнопки инвентаря
	call_deferred("update_inventory_","buttons")
	# Подключить кнопки входа в дверь
	call_deferred("update_inventory_","buttons_door")
	# Если инвентарь закрыли
	if not variant:
		# Очистить последний выбранный предмет
		last_item = null
#endregion

func update_interface_():
#region Обновление интерфейса
	# Обновляем количество максимального здоровья
	hp.max_value = Memory.stats_player.max_hp
	# Обновляем количество здоровья
	hp.value = Memory.stats_player.hp
	# Обновляем текст количества здоровья
	text_hp.text = str(Memory.stats_player.hp, "/", Memory.stats_player.max_hp)
	# Обновляем текст количества ключей
	text_key.text = str(Memory.stats_player.key)
#endregion

func update_inventory_(variant:String):
#region Обновление инвентаря
	match variant:
		"create":
			# Создаем задние ячейки инвентаря
			while back.get_child_count() < 24:
				var new_cell_back = $prefabs/cell.duplicate()
				new_cell_back.modulate = Color("ffffffbe")
				new_cell_back.get_node("back/icon").queue_free()
				new_cell_back.get_node("memory_name").queue_free()
				back.add_child(new_cell_back)

		"update":
			# Обновляем основные ячейки инвентаря
			if Memory.inventory_player:
				if grid.get_child_count():
					for child in grid.get_children():
						child.queue_free()

				for key in Memory.inventory_player:
					if Memory.elements_item.has(key):
						var new_cell_back = $prefabs/cell.duplicate()
						var get_timed_item = Memory.elements_item[key]
						var new_atlas_texture : AtlasTexture = AtlasTexture.new()
						new_atlas_texture.atlas = load("res://sprites/items/items.png")

						new_atlas_texture.region = Rect2(
							get_timed_item.rect.x,
							get_timed_item.rect.y,
							get_timed_item.rect.w,
							get_timed_item.rect.h
						)

						new_cell_back.get_node("back/icon").texture = new_atlas_texture
						grid.add_child(new_cell_back)
						new_cell_back.get_node("memory_name").text = str(key)
						new_cell_back.mouse_filter = Control.MOUSE_FILTER_PASS
						new_cell_back.mouse_entered.connect(input_items_inv_.bind(null,true,new_cell_back))
						new_cell_back.mouse_exited.connect(input_items_inv_.bind(null,false,new_cell_back))
						new_cell_back.gui_input.connect(input_items_inv_.bind(true,new_cell_back))
						continue

		"buttons":
			# Подключаем кнопки инвентаря
			for butt in inventory.get_children():
				if butt is Button:
					if not butt.pressed.is_connected(button_inventory_.bind(butt.name)):
						butt.pressed.connect(button_inventory_.bind(butt.name))

			if not last_item or last_item.get_node("memory_name").text not in ["token"]:
				use.modulate = Color.WHITE
				use.disabled = false

		"buttons_door":
			# Подключаем кнопки для дверей
			for butt in $interface/add_open_door/panel/buttons.get_children():
				if not butt.pressed.is_connected(button_open_close_door_.bind(butt.name)):
					butt.pressed.connect(button_open_close_door_.bind(butt.name))

#endregion

func input_items_inv_(event:InputEvent,enter_exit_mouse,body:Node):
#region Управление инвентарем
	match enter_exit_mouse:
		true:
			# Подсветка выбранного предмета
			body.get_node("select").visible = true
			if Memory.elements_item.has(body.get_node("memory_name").text):
				$inventory/descripton.text = (Memory.elements_item[body.get_node("memory_name").text].rus_name).capitalize() + "\n"
				$inventory/descripton.text += (Memory.elements_item[body.get_node("memory_name").text].description).to_lower()

		false:
			# Снятие подсветки, если предмет не выбран
			if body != last_item:
				body.get_node("select").visible = false
			$inventory/descripton.text = ""

	if event:
		# Обработка клика по предмету
		if event.is_pressed() and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			last_item = body
			if last_item.get_node("memory_name").text in ["token"]:
				use.modulate = Color("ffffff7f")
				use.disabled = true
			else:
				call_deferred("update_inventory_","buttons")

			for child in grid.get_children():
				if child != last_item:
					child.get_node("select").visible = false
#endregion

func button_inventory_(name_button:String):
#region Кнопки в инвентаре
	# Если есть в памяти последний выбранный предмет
	if last_item:
		# Проверяем имя кнопки
		match name_button:
			"delete":
				# Если в пуле есть предметы
				if Memory.pool_items:
					# Записываем в переменную последний предмет из массива пула
					var last_pool_items : Node = Memory.pool_items.front()
					# Создаем этот предмет в сцене
					get_tree().current_scene.add_child(last_pool_items)
					# Присваиваем предмету из пула тип из последнего выбранного слота в инвентаре
					last_pool_items.variant_item = last_item.get_node("memory_name").text
					# Перезапускаем метод у пула предмета
					last_pool_items._ready()
					# Устанавливаем позицию для предмета как у игрока
					last_pool_items.global_position = get_tree().get_first_node_in_group("player").global_position
					# Удаляем последний предмет из инвентаря
					last_item.queue_free()
					# Удаляем из инвентаря предмет под индексом полученным из инвентаря массива
					Memory.inventory_player.remove_at(last_item.get_index())
					# Удаляем из массива пула предмет из переменной
					Memory.pool_items.erase(last_pool_items)
			"use":
					# Получаем словарь по индексу последнего во всех конфигах предметов
					var last_item_in_inv : Dictionary = Memory.elements_item[last_item.get_node("memory_name").text]
					# Если предмет можно использовать
					if last_item_in_inv.use:
						for use_element in last_item_in_inv.use:
							call_deferred("use_items_",use_element)
							continue
					else:
						print("NO")
#endregion

func button_open_close_door_(name_button: String):
#region Кнопки на открывание дверей
	match name_button:
		"open":
			# Если есть ключи, открываем дверь
			if Memory.stats_player.key:
				Memory.stats_player.key -= 1
				call_deferred("update_interface_")
				Memory.memory_items_and_doors[Memory.stats_player.next_location].door = "open"
				get_tree().current_scene.call_deferred("systems_","texture_door")
				visible_enter_close_door_interface_(false)
		"cancel":
			# Закрываем интерфейс двери
			visible_enter_close_door_interface_(false)
#endregion

func visible_enter_close_door_interface_(variant:bool):
#region Видимость интерфейса двери
	match variant:
		true:
			# Скрываем инвентарь и показываем интерфейс двери
			inventory.visible = not variant
			Memory.stats_player.stop = not variant
			add_open_door.visible = variant
		false:
			# Скрываем интерфейс двери
			add_open_door.visible = variant
			Memory.stats_player.next_location = ""
#endregion

func interactive_label_text(text:String,open_close:bool):
#region Всплывающее окно о взаимодействии
	match open_close:
		true:
			# Показываем текст взаимодействия
			match text:
				"chest":
					interactive_add.get_child(0).text = "Открыть сундук"
			var new_tween : Tween = create_tween()
			new_tween.tween_property(interactive_add,"position",Vector2(576,648),0.1)
		false:
			# Скрываем текст взаимодействия
			var new_tween : Tween = create_tween()
			new_tween.tween_property(interactive_add,"position",Vector2(576,688),0.1)
#endregion

func use_items_(variant:String):
#region Использование предметов
	if "hpmax" in variant:
		# Увеличиваем максимальное здоровье
		Memory.stats_player.max_hp += int(variant)
		Memory.inventory_player.remove_at(last_item.get_index())
		last_item.queue_free()
		return

	if "hp" in variant:
		# Восстанавливаем здоровье
		Memory.stats_player.hp += int(variant)
		Memory.inventory_player.remove_at(last_item.get_index())
		last_item.queue_free()
		if Memory.stats_player.hp <= 0:
			call_deferred("reload_scene_")

	if "teleport" in variant:
		# Телепортируем игрока
		var player_timed : Node = get_tree().get_first_node_in_group("player")
		if player_timed.access_teleport:
			player_timed.global_position += (player_timed.last_pos_animation * 25)
			Memory.inventory_player.remove_at(last_item.get_index())
			last_item.queue_free()
		else:
			call_deferred("create_label_","teleport")

	if "lock" in variant:
		# Закрываем двери
		for door in Memory.memory_items_and_doors:
			if "house" in door:
				Memory.memory_items_and_doors[door].door = "close"
		if "out" in get_tree().current_scene.name:
				get_tree().current_scene.call_deferred("systems_","texture_door")
				call_deferred("create_label_","door_close")
		Memory.inventory_player.remove_at(last_item.get_index())
		last_item.queue_free()

	call_deferred("update_interface_")
#endregion

func create_label_(text_label : String):
#region Создание текстовой информации
	var player_timed : Node = get_tree().get_first_node_in_group("player")
	var new_label_text = preload("res://prefab/info_label.tscn").instantiate()
	get_tree().current_scene.add_child(new_label_text)
	new_label_text.start_(text_label,player_timed.global_position)
#endregion

func create_wave_item_(variant:String):
#region Табличка о полученном предмете
	var new_wave_item = $prefabs/item.duplicate()
	for key in Memory.elements_item:
		if key in variant:
			var get_timed_item = Memory.elements_item[key]
			var new_atlas_texture : AtlasTexture = AtlasTexture.new()
			new_atlas_texture.atlas = load("res://sprites/items/items.png")

			new_atlas_texture.region = Rect2(
				get_timed_item.rect.x,
				get_timed_item.rect.y,
				get_timed_item.rect.w,
				get_timed_item.rect.h)

			new_wave_item.get_node("main/box/icon").texture = new_atlas_texture
			new_wave_item.get_node("main/box/text").text = (get_timed_item.rus_name).capitalize()
			$interface/get_item/items.add_child(new_wave_item)

			var tween_wave : Tween = create_tween()
			tween_wave.tween_property(
				new_wave_item.get_node("main"),"position",Vector2.ZERO,0.2).set_trans(Tween.TRANS_SPRING)
			tween_wave.tween_property(
				new_wave_item.get_node("main"),"modulate",Color("ffffff00"),2).set_delay(0.5)
			await tween_wave.finished
			new_wave_item.queue_free()
#endregion

func reload_scene_():
#region Перезагрузка сцены
	# Сброс инвентаря и статистики
	Memory.inventory_player = [
	"apple","orange","apple","alarm_potion"
]

	Memory.stats_player = {
	"hp" : 10,
	"max_hp" : 10,
	"key" : 0,
	"stop" : false,
	"location" : "",
	"next_location" : ""
}

	Memory.memory_items_and_doors = {
	"outside":{
		"object" : []
	},

	"house_1" : {
		"door" : "close",
		"object" : []
	},


	"house_2" : {
		"door" : "open",
		"object" : []
	},


	"house_3" : {
		"door" : "empty",
		"object" : []
	},
}
	Memory.pool_items = []
	Memory.pool_player = null
	open_close_inventory_(false)

	# Переход на сцену "outside"
	get_tree().change_scene_to_file("res://map/outside.tscn")
#endregion
