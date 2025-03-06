extends Node

## Инвентарь персонажа
var inventory_player : Array = [
	"apple","orange","apple","alarm_potion","amulet_evil","amulet_evil"
]

## Статистика персонажа
var stats_player : Dictionary = {
	"hp" : 10,
	"max_hp" : 10,
	"key" : 0,
	"stop" : false,
	"location" : "",
	"next_location" : ""
}

## Сохраняем в памяти расположение предметов и домов
var memory_items_and_doors : Dictionary = {
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

## Все предметы
var elements_item : Dictionary = {}

## Пул игрока
var pool_player : Node

## Массив для пула объектов
var pool_items : Array = []

func _ready() -> void:
#region Настройки и получение данных
	if not elements_item:
		var open_file : FileAccess = FileAccess.open("res://engine/items.txt",FileAccess.READ)
		elements_item = JSON.parse_string(open_file.get_as_text())
#endregion
