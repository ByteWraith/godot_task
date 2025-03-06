extends CharacterBody2D

## Дерево анимаций
@onready var animation_tree: AnimationTree = $animation_tree

## Последнее направление движения
var last_pos_animation : Vector2 = Vector2.UP

## Зона для подбора предметов
@onready var area_get_item: Area2D = $area_get_item

## Базовое направление
var input : Vector2

## Максимальная скорость
@export var max_speed: float = 100.0
## Ускорение
@export var acceleration: float = 500.0
## Замедление
@export var deceleration: float = 500.0

## Луч для определения с чем сталкивается игрок впереди (для телепорта)
@onready var check_wall: RayCast2D = $check_wall
## Луч смотрит на предмет, который можно использовать
var look_at_interact : Node
## Возможно ли телепортироваться
var access_teleport : bool = true

## Объект, с которым можно взаимодействовать
var interact_object : Node

func _init() -> void:
#region Отключение обработки процесса
	set_process(false)
#endregion

func _ready() -> void:
#region Начальные настройки
	# Ожидаем ответа от движка
	await get_tree().process_frame
	# Включаем обработку процесса
	set_process(true)
	# Добавляем в группу игрока
	call_deferred("systems_","add_to_group")
	# Подключаем зону для подбора предметов
	call_deferred("systems_","zone_get_item")
	# Обновляем интерфейс
	call_deferred("systems_","hud_update")
#endregion

func systems_(variant:String):
#region Внутренние настройки
	match variant:
		"add_to_group":
			# Добавляем игрока в группу, если она еще не существует
			if not get_tree().has_group("player"):
				self.add_to_group("player")
		"zone_get_item":
			# Подключаем сигналы для зоны подбора предметов
			area_get_item.body_entered.connect(get_item_)
			area_get_item.area_entered.connect(enter_door_or_interact_.bind(true))
			area_get_item.area_exited.connect(enter_door_or_interact_.bind(false))

		"hud_update":
			# Обновляем интерфейс и инвентарь
			Hud.update_inventory_("create")
			Hud.update_interface_()
#endregion

func _input(event: InputEvent) -> void:
#region Обработка нажатий
	if event.is_pressed() and Input.is_action_just_pressed("ui_use"):
		# Если есть объект для взаимодействия
		if interact_object:
			# Запускаем анимацию открытия
			interact_object.get_node("sprite").play("open")
			# Удаляем зону взаимодействия
			interact_object.get_node("area_interact").queue_free()
			# Если есть элементы в инвентаре
			if Memory.elements_item:
				var timed_array_get_items : Array = Memory.elements_item.keys()
				# Случайно выбираем предметы
				for key in randi_range(1,4):
					# Если в инвентаре меньше 24 предметов
					if Memory.inventory_player.size() < 24:
						# Берем случайное название предмета
						var get_items : String = timed_array_get_items.pick_random()
						# Если это ключ
						if get_items in ["key"]:
							# Увеличиваем количество ключей
							Memory.stats_player.key += 1
						else:
							# Добавляем предмет в инвентарь
							Memory.inventory_player.append(get_items)
							# Добавляем всплывающее окно о подобранном предмете
							Hud.call_deferred("create_wave_item_",get_items)
						continue
					else:
						break

				# Обновляем интерфейс
				Hud.call_deferred("update_interface_")
#endregion

func _process(delta: float) -> void:
#region Обработка каждого кадра
	# Обработка движения
	move_(delta)
	# Анимации
	animation_()
	# Поворот луча
	rotation_ray_wall_()
#endregion

func move_(delta:float):
#region Движение игрока
	if not Memory.stats_player.stop:
		# Получаем вектор ввода от игрока
		input = Input.get_vector("ui_left","ui_right","ui_up","ui_down")

		if input:
			# Двигаем игрока в направлении ввода
			velocity = velocity.move_toward(input * max_speed, acceleration * delta)
		else:
			# Замедляем игрока, если ввода нет
			velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)

		# Применяем движение
		move_and_slide()
	else:
		# Останавливаем игрока, если движение заблокировано
		input = Vector2.ZERO
#endregion

func animation_():
#region Анимации
	# Если происходит движение
	if input:
		# Запоминаем последнее направление движения
		last_pos_animation = input.normalized()

	# Устанавливаем направление для анимации ходьбы
	animation_tree.set("parameters/walk/blend_position",velocity.normalized())
	# Устанавливаем направление для анимации ожидания
	animation_tree.set("parameters/idle/blend_position",last_pos_animation)
#endregion

func rotation_ray_wall_():
#region Направление луча и определение столкновений
	# Если луч сталкивается с чем-то
	if check_wall.is_colliding():
		# Запрещаем телепорт, если луч сталкивается с объектом
		access_teleport = false
	else:
		# Разрешаем телепорт, если луч не сталкивается ни с чем
		access_teleport = true

	# Поворачиваем луч в зависимости от направления движения
	if input.x < 0:
		check_wall.target_position = Vector2(-40,0)
	elif input.x > 0:
		check_wall.target_position = Vector2(40,0)
	elif input.y < 0:
		check_wall.target_position = Vector2(0,-40)
	elif input.y > 0:
		check_wall.target_position = Vector2(0,40)
#endregion

func enter_door_or_interact_(area:Area2D,enter_exit:bool):
#region Взаимодействие с объектами
	match area.name:
		"area_interact":
			match enter_exit:
				true:
					# Показываем текст взаимодействия и выделяем объект
					Hud.call_deferred("interactive_label_text","chest",true)
					area.get_parent().get_node("sprite").material.set("shader_parameter/width",1)
					interact_object = area.get_parent()
				false:
					# Скрываем текст взаимодействия и убираем выделение
					Hud.call_deferred("interactive_label_text","",false)
					area.get_parent().get_node("sprite").material.set("shader_parameter/width",0)
					interact_object = null
#endregion

func get_item_(body:Node2D):
#region Подбор предметов
	if "key" in body.variant_item:
		# Подбираем ключ
		Hud.create_label_("key")
		Memory.stats_player.key += 1
		get_tree().current_scene.remove_child(body)
		Memory.pool_items.append(body)
		Hud.call_deferred("update_interface_")
	else:
		# Подбираем предмет, если есть место в инвентаре
		if Memory.inventory_player.size() < 24:
			Hud.call_deferred("create_wave_item_",body.name)
			Hud.create_label_(Memory.elements_item[body.variant_item].rus_name)
			Memory.inventory_player.append(body.variant_item)
			get_tree().current_scene.remove_child(body)
			Memory.pool_items.append(body)
		else:
			# Сообщаем, что инвентарь полон
			Hud.create_label_("full")
#endregion
