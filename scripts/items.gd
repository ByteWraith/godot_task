extends StaticBody2D

## Спрайт предмета
@onready var sprite: Sprite2D = $sprite
## Вариант предмета
var variant_item : String = "random"

func _ready() -> void:
	# Отложенный вызов функции генерации предмета
	call_deferred("generate_item_")

func generate_item_():
	# Создаем массив всех имен предметов
	var all_name_item : Array
	for key in Memory.elements_item:
		all_name_item.append(key)

	# Если вариант предмета "random", выбираем случайный предмет
	if variant_item in ["random"]:
		variant_item = all_name_item.pick_random()

	# Получаем регион текстуры для выбранного предмета
	var region_element = Memory.elements_item[variant_item].rect

	# Устанавливаем регион текстуры для спрайта
	sprite.texture.region = Rect2(
		region_element.x,
		region_element.y,
		region_element.w,
		region_element.h)

	# Устанавливаем имя объекта в соответствии с выбранным предметом
	self.name = variant_item

	# Добавляем объект в группу "outside_item"
	self.add_to_group("outside_item")
