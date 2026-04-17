extends Node3D

@export var rigidBody: RigidBody3D
@export var hitbox: Area3D
@export var attackArea: Area3D
@export var visionArea: Area3D
@export var visionRaycast: RayCast3D
@export var ui = Node2D
@export var healthBar = ProgressBar
@export var clockBar: TextureProgressBar
@export var animator: AnimationPlayer
@export var teamSprite: Sprite2D
var world: Node3D

@export var unitId: int
@export var unitType: String
#for now 0 is self, 1 is opponent
@export var unitOwner: int
var timeToPlace: float
var placed: bool
var targetPos: Vector2
@export var hideClock: bool

var height: float = 1
var width: float = 0.5

var maxHealth: int = 20
var health: int
var defense: int = 0
var attackDamage: int = 5
var attackCooldown: float = 1
var timeLastAttacked: float
var attackRange: float = 1
var attackAoE: float = 0
var attackPierceDefense: bool = false
var attackTargetMeathod: int = 0
var moveSpeed: int = 10
var building: bool
#soup to op, goop to op, soup to self, goop to self,
var resourceOnDeath: Array[int] = [
	0, 0, 0, 0,
]
var buildingDamageBoost: float

func _ready() -> void:
	world = get_parent()
	
	var loadStats = world.unitStats[unitType]
	height = loadStats[2]
	width = loadStats[3]
	maxHealth = loadStats[4]
	defense = loadStats[5]
	attackDamage = loadStats[6]
	attackCooldown = loadStats[7]
	attackRange = loadStats[8]
	attackAoE = loadStats[9]
	attackPierceDefense = loadStats[10]
	attackTargetMeathod = loadStats[11]
	moveSpeed = loadStats[12]
	building = loadStats[13]
	resourceOnDeath = [loadStats[14][0],loadStats[14][1],loadStats[14][2],loadStats[14][3],]
	buildingDamageBoost = loadStats[15]
	
	health = maxHealth
	healthBar.max_value = maxHealth
	
	if building:
		rigidBody.freeze = true
	
	rigidBody.position.y = height / 2
	rigidBody.get_child(0).mesh.height = height
	rigidBody.get_child(0).mesh.radius = width / 2
	rigidBody.get_child(0).mesh.material.albedo_color = world.unitMeshes[unitType]
	rigidBody.get_child(1).shape.height = height
	rigidBody.get_child(1).shape.radius = width / 2
	hitbox.get_child(0).shape.height = height
	hitbox.get_child(0).shape.radius = width / 2
	attackArea.get_child(0).shape.radius = attackRange
	visionArea.get_child(0).shape.radius = attackRange + 3
	
	clockBar.get_parent().visible = not hideClock
	if unitOwner == 0:
		clockBar.tint_progress = Color("0090ffaf")
		teamSprite.modulate = Color("0090ffff")
		healthBar.modulate = Color("0090ffff")
	elif unitOwner == 1:
		clockBar.tint_progress = Color("ff0000af")
		teamSprite.modulate = Color("ff0000ff")
		healthBar.modulate = Color("ff0000ff")
	
	if not hideClock:
		animator.play("clockStart")

func _process(delta: float) -> void:
	runUi()
	
	if timeToPlace > world.gametime:
		return
	
	if not placed:
		place()
		placed = true
	
	var target: Node3D = getTarget(attackArea)
	#if attackArea.get_overlapping_areas().size() > 1:
		#for area in attackArea.get_overlapping_areas():
			#var checkTarget: Node3D = area.get_parent().get_parent()
			#if not checkTarget.unitOwner == unitOwner && checkTarget.placed:
				#target = checkTarget
	if not target == null:
		rigidBody.linear_velocity = Vector3.ZERO
		if timeLastAttacked + attackCooldown < world.gametime:
			if attackAoE == 0:
				attack(target)
			else:
				for area in attackArea.get_overlapping_areas():
					var checkTarget: Node3D = area.get_parent().get_parent()
					if not checkTarget.unitOwner == unitOwner && checkTarget.placed:
						if checkTarget.rigidBody.global_position.distance_to(target.rigidBody.global_position) <= attackAoE:
							attack(checkTarget)
	elif not building:
		move()

func runUi():
	ui.position = world.camera.unproject_position(rigidBody.global_position + height * Vector3(0, 1, 0))
	if health == maxHealth && not building:
		healthBar.visible = false
		teamSprite.visible = placed
	else:
		healthBar.visible = true
		teamSprite.visible = false
		healthBar.value = health

func place():
	if not hideClock:
		if unitOwner == 0:
			animator.play("clockEndBlue")
		else:
			animator.play("clockEndRed")
	rigidBody.collision_layer = 2
	rigidBody.collision_mask = 3

func move():
	#pathfind
	var target = getTarget(visionArea)
	if target == null:
		if rigidBody.global_position.x < 0:
			targetPos.x = -5
		else:
			targetPos.x = 5
		if unitOwner == 0:
			if rigidBody.global_position.z <= -5:
				targetPos = Vector2(0, -9)
			else:
				if rigidBody.global_position.z <= 1:
					targetPos.y = -5
				else:
					targetPos.y = 1
		else:
			if rigidBody.global_position.z >= 5:
				targetPos = Vector2(0, 9)
			else:
				if rigidBody.global_position.z >= -1:
					targetPos.y = 5
				else:
					targetPos.y = -1
	else:
		targetPos = Vector2(target.rigidBody.global_position.x, target.rigidBody.global_position.z)
	moveAroundTo(targetPos)
	#rigidBody.linear_velocity = Vector3(targetPos.x - rigidBody.global_position.x,  0, targetPos.y - rigidBody.global_position.z).normalized() * moveSpeed / 10

func moveAroundTo(targetPos: Vector2):
	#var targetPos3 = Vector3(targetPos.x, 0, targetPos.y)
	#visionRaycast.look_at(targetPos3)
	#visionRaycast.target_position.z = rigidBody.position.distance_to(targetPos3) * -1
	#visionRaycast.force_raycast_update()
	var imidiateTargetPos: Vector2
	if false:#visionRaycast.is_colliding() && visionRaycast.get_collision_point().distance_to(rigidBody.position) < width + 0.1:
		imidiateTargetPos = targetPos + Vector2(randf_range(1, -1), randf_range(1, -1))
	else:
		imidiateTargetPos = targetPos
	rigidBody.linear_velocity = Vector3(imidiateTargetPos.x - rigidBody.global_position.x,  0, imidiateTargetPos.y - rigidBody.global_position.z).normalized() * moveSpeed / 10

func getTarget(area):
	if area.has_overlapping_areas():#area.get_overlapping_areas().size() > 1:
		var target: Node3D = null
		var distanceToTarget: float = 0
		for hitbox in area.get_overlapping_areas():
			var checkTarget: Node3D = hitbox.get_parent().get_parent()
			if (not checkTarget.unitOwner == unitOwner) && checkTarget.placed:
				visionRaycast.look_at(checkTarget.rigidBody.global_position)
				if visionRaycast.is_colliding() && (not visionRaycast.get_collider().get_parent() == world.level):
					var currentDistance = rigidBody.global_position.distance_to(checkTarget.rigidBody.global_position)
					if currentDistance < distanceToTarget or distanceToTarget == 0:
						target = checkTarget
						distanceToTarget = currentDistance
		return target

func attack(target: Node3D):
	timeLastAttacked = world.gametime
	var damage = attackDamage + (buildingDamageBoost * int(target.building)) - (target.defense * int(not attackPierceDefense))
	if damage > 0:
		target.health -= damage
	if target.health <= 0:
		target.die()

func die():
	if get_multiplayer_authority() == 1:
		world.unitDeath.rpc(unitId)
	else:
		world.queue_free()
