extends Node

signal changed

const ITEMS := {
    "senzu": {"name":"Semilla Senzu", "type":"consumable", "description":"Restaura todo el HP y KI.", "value":35},
    "water": {"name":"Agua de entrenamiento", "type":"consumable", "description":"Restaura 35 KI.", "value":12},
    "ki_capsule": {"name":"Cápsula KI", "type":"consumable", "description":"Restaura 60 KI.", "value":28},
    "iron": {"name":"Mineral de hierro", "type":"material", "description":"Material para mejorar equipo.", "value":8},
    "raw_meat": {"name":"Carne de bestia", "type":"material", "description":"Carne resistente; sirve para fabricar raciones.", "value":9},
    "saibaman_seed": {"name":"Semilla de Saibaman", "type":"material", "description":"Semilla extraña de energía biológica.", "value":18},
    "bandit_cloth": {"name":"Tela de bandido", "type":"material", "description":"Trozo de ropa útil para fabricar vendas.", "value":14},
    "dino_hide": {"name":"Cuero de dino", "type":"material", "description":"Cuero grueso y resistente.", "value":24},
    "pirate_coin": {"name":"Moneda pirata", "type":"material", "description":"Moneda encontrada en las costas.", "value":30},
    "ice_shard": {"name":"Fragmento de hielo KI", "type":"material", "description":"Cristal helado cargado de energía.", "value":36},
    "galactic_badge": {"name":"Insignia galáctica", "type":"material", "description":"Emblema de una patrulla espacial.", "value":52},
    "namek_crystal": {"name":"Cristal de Namek", "type":"material", "description":"Cristal verde utilizado en tecnología y rituales.", "value":64},
    "zenicoin": {"name":"Ficha antigua", "type":"material", "description":"Una ficha usada por comerciantes.", "value":20},
    "novice_gi": {"name":"Gi del principiante", "type":"armor", "description":"DEF +4.", "value":40, "defense":4},
    "heavy_gi": {"name":"Gi reforzado", "type":"armor", "description":"DEF +8, FUE +1.", "value":120, "defense":8, "strength":1},
    "training_band": {"name":"Banda de entrenamiento", "type":"accessory", "description":"FUE +2.", "value":30, "strength":2},
    "ice_guard": {"name":"Coraza Glacial", "type":"armor", "description":"DEF +12, KI +2.", "value":260, "defense":12, "ki_power":2},
    "namek_charm": {"name":"Amuleto de Namek", "type":"accessory", "description":"KI +5, DEF +2.", "value":340, "ki_power":5, "defense":2},
    "dragon_orb": {"name":"Orbe del Dragón", "type":"special", "description":"Una reliquia vinculada a la historia.", "value":500},
    "rr_insignia": {"name":"Insignia del Ejército Red", "type":"material", "description":"Emblema recuperado de patrullas militares.", "value":48},
    "karin_talisman": {"name":"Talismán de Karin", "type":"material", "description":"Talismán de entrenamiento de la torre sagrada.", "value":140}
}

func add_item(id: String, amount: int = 1) -> void:
    GameState.inventory[id] = int(GameState.inventory.get(id, 0)) + amount
    changed.emit()

func remove_item(id: String, amount: int = 1) -> bool:
    var have := int(GameState.inventory.get(id, 0))
    if have < amount:
        return false
    GameState.inventory[id] = have - amount
    changed.emit()
    return true

func use_item(id: String) -> String:
    if int(GameState.inventory.get(id, 0)) <= 0:
        return "No tienes ese objeto."
    if id == "senzu":
        remove_item(id)
        GameState.hp = GameState.max_hp()
        GameState.ki = GameState.max_ki()
        GameState.changed.emit()
        return "Semilla Senzu usada. HP y KI restaurados."
    if id == "water":
        remove_item(id)
        GameState.ki = mini(GameState.max_ki(), GameState.ki + 35)
        GameState.changed.emit()
        return "Bebiste agua. +35 KI."
    if id == "ki_capsule":
        remove_item(id)
        GameState.ki = mini(GameState.max_ki(), GameState.ki + 60)
        GameState.changed.emit()
        return "Cápsula KI usada. +60 KI."
    return "Ese objeto no se puede usar aquí."

func equip(id: String) -> bool:
    if not ITEMS.has(id):
        return false
    var item: Dictionary = ITEMS[id]
    var type := str(item.get("type", ""))
    if type != "armor" and type != "accessory":
        return false
    if int(GameState.inventory.get(id, 0)) <= 0:
        return false
    GameState.equipment[type] = id
    GameState.changed.emit()
    return true

func get_item_name(id: String) -> String:
    return str(ITEMS.get(id, {"name": id}).get("name", id))

func get_item_data(id: String) -> Dictionary:
    return ITEMS.get(id, {})

func craft_ki_capsule() -> bool:
    if int(GameState.inventory.get("iron",0)) < 2 or int(GameState.inventory.get("water",0)) < 1:
        return false
    remove_item("iron",2)
    remove_item("water",1)
    add_item("ki_capsule",1)
    return true

func craft_ration() -> bool:
    if int(GameState.inventory.get("raw_meat",0)) < 2 or int(GameState.inventory.get("water",0)) < 1:
        return false
    remove_item("raw_meat",2)
    remove_item("water",1)
    add_item("senzu",1)
    return true

func buy(id: String, amount: int = 1) -> bool:
    if not ITEMS.has(id):
        return false
    var price := int(ITEMS[id].get("value", 0)) * amount
    if GameState.zeni < price:
        return false
    GameState.zeni -= price
    add_item(id, amount)
    GameState.changed.emit()
    return true

func sell(id: String, amount: int = 1) -> bool:
    if not remove_item(id, amount):
        return false
    GameState.zeni += int(ITEMS.get(id, {}).get("value", 0) * amount * 0.5)
    GameState.changed.emit()
    return true

func equipment_bonus(stat: String) -> int:
    var total := 0
    for id in GameState.equipment.values():
        var item: Dictionary = ITEMS.get(str(id), {})
        total += int(item.get(stat, 0))
    return total
