extends Node3D

var gametime: float
var botSpawnTimer: float

@export var level: Node3D
@export var cursor: Node3D
@export var camera: Camera3D
@export var cameraJoint: Node3D
@export var raycast: RayCast3D
@export var unplaceable: Node3D

@export var towers: Array[Node3D]
@export var gems: Node3D
var blueGems: int
var redGems: int
@export var gemsBlueLabel: Label
@export var gemsRedLabel: Label
@export var gemScene: PackedScene

@export var myTeam: int

@export var Ui: Node2D
@export var soupBar: ProgressBar
@export var soupBarInt: ProgressBar
@export var soupBarFull: ProgressBar
@export var goopBar: ProgressBar
@export var goopBarInt: ProgressBar
@export var goopBarFull: ProgressBar
@export var cardSprites: Array[Sprite2D]
@export var UiCursor: Area2D

@export var unitScene: PackedScene

var unitsEver: int = 6

var unitEachName: Array[String] = [
	"PrincessTower", "KingTower", "Guy", "AnkleBiter", "BigGuy", "Clanker", "Archer", "GlassCannon", "ShieldGuy", "Destroyer", 
]
var deck: Array[String]
#soupCost, goopCost, height, width, maxHealth, defense, attackDamage, attackCooldown, attackRange, attackAoE, 
#attackPierceDefense, attackTargetMeathod, moveSpeed, building, resourceOnDeath, buildingDamageBoost
var unitStats: Dictionary = {
	"PrincessTower":	[0, 0, 2, 1.5, 100, 0, 2, 0.5, 5, 0, true, 0, 0, true, [0,0,0,0], 0],
	"KingTower":		[0, 0, 3, 2, 200, 0, 4, 2, 5, 1, true, 0, 0, true, [0,0,0,0], 0],
	"Guy":				[2, 0, 1, 0.5, 10, 0, 4, 1, 1, 0, false, 0, 10, false, [0,1,0,0], 0],
	"AnkleBiter": 		[3, 2, 0.5, 0.5, 8, 0, 2, 0.5, 1, 0, false, 0, 20, false, [0,0.5,0,0], 0],
	"BigGuy": 			[0, 5, 2, 1, 30, 0, 15, 2, 1.5, 0, false, 0, 5, false, [0,2,0,0], 0],
	"Clanker":			[5, 0, 1, 1, 15, 2, 5, 2, 1, 0.5, false, 0, 8, false, [0,3,0,0], 0],
	"Archer": 			[3, 3, 1, 0.5, 6, 0, 3, 1, 4, 0, false, 0, 10, false, [0,1,0,0], 0],
	"GlassCannon": 		[4, 2, 2, 0.5, 4, 0, 10, 1, 2, 0, false, 0, 10, false, [0,2,0,0], 0],
	"ShieldGuy": 		[1, 3, 2, 1, 50, 0, 1, 1, 1, 0, false, 0, 10, false, [0,2,0,0], 0],
	"Destroyer": 		[3, 5, 0.5, 0.5, 20, 0, 2, 1, 1, 0, false, 0, 20, false, [0,4,0,0], 18],
}
var unitMeshes: Dictionary = {
	"PrincessTower": Color(0.31, 0.31, 0.31, 1.0),
	"KingTower": Color(0.199, 0.199, 0.199, 1.0),
	"Guy": Color(1.0, 0.833, 0.0, 1.0),
	"AnkleBiter": Color(0.533, 1.0, 0.0, 1.0),
	"BigGuy": Color(1.0, 0.4, 0.0, 1.0),
	"Clanker": Color(0.338, 0.178, 0.274, 1.0),
	"Archer": Color(0.0, 0.55, 0.348, 1.0),
	"GlassCannon": Color(0.68, 0.68, 0.68, 1.0),
	"ShieldGuy": Color(0.095, 0.43, 0.599, 1.0),
	"Destroyer": Color(1.0, 0.0, 0.517, 1.0),
}
var cardStats: Array = [
	
]
#0 is next card, 1-4 are in hand
var cardTypes: Array[String] = [
	"", "", "", "", ""
]
#0 is none, 1-4 is which one
var cardHeld: int

var soup: float = 4
var goop: float = 4

func _ready() -> void:
	for i in unitEachName.size() -2:
		deck.append(unitEachName[i+2])
	deck.shuffle()
	for i in 5:
		drawCard(i)
	if myTeam == 0:
		unplaceable.get_child(0).visible = false
		unplaceable.get_child(1).visible = false
		unplaceable.get_child(2).visible = false
		gemsBlueLabel.position.y = -26.0
		gemsRedLabel.position.y = -126.0
	else:
		unplaceable.get_child(3).visible = false
		unplaceable.get_child(4).visible = false
		unplaceable.get_child(5).visible = false
		gemsBlueLabel.position.y = -126.0
		gemsRedLabel.position.y = -26.0

func _process(delta: float) -> void:
	gametime += delta
	
	var mousePos = get_viewport().get_mouse_position()
	var worldPos = camera.project_position(mousePos, 25)
	
	#cameraJoint.rotation.y += delta * 0.5
	if myTeam == 1:
		cameraJoint.rotation.y = PI
	
	soup += delta * 0.5
	if soup > 10:
		soup = 10
		soupBarFull.visible = true
	elif soup < 10:
		soupBarFull.visible = false
	soupBar.value = soup
	soupBarInt.value = soupBarInt.value * 0.9 + int(soup) * 0.1
	goop += delta * 0.2
	if goop > 10:
		goop = 10
		goopBarFull.visible = true
	elif goop < 10:
		goopBarFull.visible = false
	goopBar.value = goop
	goopBarInt.value = goopBarInt.value * 0.9 + int(goop) * 0.1
	
	Ui.global_position = get_viewport().size * 0.5
	var scaleMod: float = float(get_viewport().size.y) / 648
	Ui.scale = Vector2(scaleMod, scaleMod)
	UiCursor.global_position = mousePos
	if Input.is_action_pressed("click"):
		if UiCursor.has_overlapping_areas():
			for card in 4:
				if UiCursor.overlaps_area(cardSprites[card+1].get_child(0)):
					cardHeld = card +1
					cursor.mesh.material.albedo_color = unitMeshes[cardTypes[cardHeld]]
					if myTeam == 0:
						unplaceable.get_child(4).visible = not towers[4] == null
						unplaceable.get_child(5).visible = not towers[5] == null
					else:
						unplaceable.get_child(1).visible = not towers[1] == null
						unplaceable.get_child(2).visible = not towers[2] == null
					unplaceable.visible = true
	
	raycast.look_at(worldPos)
	raycast.force_raycast_update()
	if raycast.is_colliding():
		var hitPoint = raycast.get_collision_point()
		var placePos = getPlacePos(hitPoint)
		raycast.look_at(placePos)
		raycast.force_raycast_update()
		if raycast.get_collider().collision_layer == 1 && mousePos.y < get_viewport().size.y*4/5:#raycast.get_collider().collision_layer == 1 && mousePos.y < 648*4/5:
			cursor.visible = true
			cursor.position = placePos
			if Input.is_action_just_released("click"):
				if not cardHeld == 0 && soup >= unitStats[cardTypes[cardHeld]][0] && goop >= unitStats[cardTypes[cardHeld]][1]:
					soup -= unitStats[cardTypes[cardHeld]][0]
					goop -= unitStats[cardTypes[cardHeld]][1]
					deck.append(cardTypes[cardHeld])
					spawnUnit.rpc(placePos, cardTypes[cardHeld], myTeam, 1)
					drawCard(cardHeld)
				cardHeld = 0
				cursor.mesh.material.albedo_color = Color(0.0, 0.0, 0.0, 1.0)
				unplaceable.visible = false
		else:
			cursor.visible = false
	if botSpawnTimer <= gametime:
		var pos: Vector3
		pos.x = randf_range(-10, 10)
		if myTeam == 0:
			pos.z = randf_range(-2, -12)
		else:
			pos.z = randf_range(2, 12)
		#spawnUnit(pos, unitEachName[andi_range(2, unitEachName.size()-1)], fmod(myTeam+1, 2), 1)
		botSpawnTimer += randf_range(5, 10)
	
	for gem in gems.get_children():
		gem.rotation.y += delta
		var gemTargetPosition = Vector3(12, 10, 0)
		gem.global_position = gem.global_position * 0.9 + gemTargetPosition * 0.1
		if gem.global_position.distance_to(gemTargetPosition) < 0.1:
			gemsBlueLabel.text = str(blueGems)
			gemsRedLabel.text = str(redGems)
			gem.queue_free()

@rpc("any_peer", "call_local", "reliable")
func spawnUnit(pos: Vector3, type: String, owner: int, amount: int):
	if type == "Guy":
		amount = 3
	if type == "AnkleBiter":
		amount = 5
	if type == "Archer":
		amount = 2
	for i in amount:
		var newUnit = unitScene.instantiate()
		newUnit.unitId = unitsEver
		unitsEver += 1
		var spawnPosition: Vector3
		if i == 0:
			spawnPosition = pos
			newUnit.hideClock = false
		else:
			spawnPosition = pos + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
			newUnit.hideClock = true
		newUnit.position = spawnPosition
		newUnit.timeToPlace = gametime + 1.5
		newUnit.unitType = type
		newUnit.unitOwner = owner
		add_child(newUnit)

func drawCard(cardNumber):
	if not cardNumber == 0:
		cardTypes[cardNumber] = cardTypes[0]
		cardSprites[cardNumber].self_modulate = unitMeshes[cardTypes[cardNumber]]
		setCardCosts(cardSprites[cardNumber].get_child(1).get_child(0), unitStats[cardTypes[0]][0])
		setCardCosts(cardSprites[cardNumber].get_child(2).get_child(0), unitStats[cardTypes[0]][1])
	#cardTypes[0] = ""
	#var newCard: String = ""
	#while cardTypes.has(newCard):
		#newCard = unitEachName[randi_range(2, unitEachName.size()-1)]
	#cardTypes[0] = newCard
	cardTypes[0] = deck[0]
	deck.remove_at(0)
	cardSprites[0].self_modulate = unitMeshes[cardTypes[0]]

func getPlacePos(pos: Vector3):
	pos.y = 0
	if pos.x > 9.5:
		pos.x = 9.5
	if pos.x < -9.5:
		pos.x = -9.5
	if myTeam == 0:
		if pos.z > 11.5:
			return Vector3(pos.x, 0, 11.5)
		if (pos.x < 0 && towers[4]) or (pos.x >= 0 && towers[5]):
			if pos.z < 0.5:
				return Vector3(pos.x, 0, 0.5)
		else:
			if pos.z < -3.5:
				return Vector3(pos.x, 0, -3.5)
	else:
		if pos.z < -11.5:
			return Vector3(pos.x, 0, -11.5)
		if (pos.x < 0 && towers[1]) or (pos.x >= 0 && towers[2]):
			if pos.z > -1.5:
				return Vector3(pos.x, 0, -1.5)
		else:
			if pos.z > 4.5:
				return Vector3(pos.x, 0, 4.5)
	return pos

func setCardCosts(label: Label, value: int):
	if value == 0:
		label.get_parent().visible = false
	else:
		label.get_parent().visible = true
		label.text = str(value)

func findUnitById(unitId: int):
	for i in get_children().size() - 5:
		var checkUnit = get_child(i+5)
		if "unitId" in checkUnit && checkUnit.unitId == unitId:
			return checkUnit
	return null

@rpc("any_peer", "call_local", "reliable")
func unitDeath(unitId: int):
	var unit: Node3D = findUnitById(unitId)
	if unit == null:
		return
	var type = unit.unitType
	var owner = unit.unitOwner
	var pos = unit.rigidBody.global_position
	
	if owner == myTeam:
		soup += unit.resourceOnDeath[2]
		goop += unit.resourceOnDeath[3]
	else:
		soup += unit.resourceOnDeath[0]
		goop += unit.resourceOnDeath[1]
	
	var particles = preload("res://Scenes/death_particles.tscn").instantiate()
	particles.position = pos
	add_child(particles)
	
	if type == "PrincessTower" or type == "KingTower":
		if owner == 0:
			redGems += 1
		else:
			blueGems += 1
		createGem(pos, owner)
		if type == "KingTower":
			if owner == 0:
				if towers[1]:
					towers[1].die()
				if towers[2]:
					towers[2].die()
			else:
				if towers[4]:
					towers[4].die()
				if towers[5]:
					towers[5].die()
	unit.queue_free()

func createGem(pos: Vector3, color: int):
		var newGem = gemScene.instantiate()
		newGem.position = pos
		if color == 0:
			newGem.mesh.material.albedo_color = Color(1.0, 0.0, 0.0, 1.0)
		else:
			newGem.mesh.material.albedo_color = Color(0.0, 0.567, 1.0, 1.0)
		gems.add_child(newGem)
