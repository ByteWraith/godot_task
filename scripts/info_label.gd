extends Control

## Ссылка на текстовый элемент Label
@onready var text: Label = $text

func start_(variant:String, pos:Vector2):
#region Функция для начала создания текстового сообщения
	# Отложенный вызов функции создания текста
	call_deferred("create_", variant, pos)
#endregion

func create_(variant:String, pos:Vector2):
#region Функция создания текстового сообщения
	# Выбор текста в зависимости от переданного варианта
	match variant:
		"key":
			text.set_text("+1 ключ")
		"full", "full_inv":
			# Случайный выбор текста для полного инвентаря
			text.text = ["инвентарь полон", "полный инвентарь", "я не могу взять больше"].pick_random()
		"teleport":
			# Случайный выбор текста для невозможности телепортации
			text.text = ["я не буду телепортироваться в стену", "эй! это слишком опасно!", "ага, это не станция 9 3/4"].pick_random()
		"fullhp", "full_hp":
			# Случайный выбор текста для полного здоровья
			text.text = ["я здоров", "пока приберегу"].pick_random()
		"door_close":
			# Текст для закрытых дверей
			text.text = "Двери закрыты!"
		_:
			# Текст по умолчанию для других случаев
			text.text = "взял " + variant

	# Устанавливаем позицию текста
	self.global_position = pos

	# Создаем твин для анимации текста
	var new_tween: Tween = create_tween()
	# Анимация движения текста вверх
	new_tween.tween_property(self, "global_position", Vector2(self.global_position.x, (self.global_position.y + -25.0)), 0.3).set_trans(Tween.TRANS_SPRING)
	# Анимация исчезновения текста
	new_tween.tween_property(self, "modulate", Color("ffffff00"), 1.0)
	# Ожидаем завершения анимации
	await new_tween.finished
	# Отложенный вызов функции удаления текста
	call_deferred("delete_")
#endregion

func delete_():
#region Функция удаления текстового сообщения
	# Удаляем текстовое сообщение из сцены
	queue_free()
#endregion
