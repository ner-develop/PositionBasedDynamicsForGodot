extends Node

class_name XPBD

class ParticleData:
	var is_fixed: bool
	var x: Vector3
	var xi: Vector3
	var v: Vector3
	var m: float
	var w: float
	var initial_position: Vector3
	var particle_ref: Particle
	
	func _init(particle: Particle):
		particle_ref = particle

class Constraint:
	var λ: float
	var α: float
	var p1: ParticleData
	var p2: ParticleData
	var d: float
	
	func _init(particle_data1: ParticleData, particle_data2: ParticleData):
		p1 = particle_data1
		p2 = particle_data2
		d = (p2.initial_position - p1.initial_position).length()
	
	func compute_Δλ(Δt: float):
		var vector = p2.xi - p1.xi
		var distance = vector.length()
		var c = distance - d
		var α_tilda = α / (Δt * Δt)
		var grad_c = vector / distance
		var inv_m = p1.w + p2.w
		return (c - α_tilda * λ) / (grad_c.dot(inv_m * grad_c) + α_tilda)
	
	func compute_Δx(Δλ: float):
		var grad_c = (p2.xi - p1.xi).normalized()
		return grad_c * Δλ



@export var priority: int = 0
@export var flexibility: float = 0.0001
@export var iterations: int = 10
@export var gravity: Vector3 = Vector3(0.0, -9.8, 0.0)
var particle_data_list: Array[ParticleData] = []
var constraint_list: Array[Constraint] = []






func initialize(particle_list: Array[Particle]):
	print("[" + name + "] initialize")
	for i in range(particle_list.size()):
		var particle_data = ParticleData.new(particle_list[i])
		particle_data_list.append(particle_data)
		
		particle_data.is_fixed = i == 0
		particle_data.initial_position = particle_data.particle_ref.global_position
		
		particle_data.x = particle_data.initial_position
		particle_data.m = particle_data.particle_ref.mass
		particle_data.w = 1.0 / particle_data.m
		particle_data.v = Vector3.ZERO
	
	for i in range(particle_data_list.size() - 1):
		constraint_list.append(Constraint.new(particle_data_list[i], particle_data_list[i + 1]))


func step(Δt: float):
	# 固定点の位置をデータに反映
	for p in particle_data_list:
		if !p.is_fixed:
			continue
		p.x = p.particle_ref.global_position
	
	simulate(Δt)
	
	# データを位置に反映
	for p in particle_data_list:
		p.particle_ref.global_position = p.x


func simulate(Δt: float):
	for p in particle_data_list:
		# predict position
		var x_tilda = p.x + Δt * p.v
		
		# initialize solve
		p.xi = x_tilda
	
	for c in constraint_list:
		# initialize multipliers
		c.λ = 0
		c.α = flexibility
	
	var i = 0
	while i < iterations:
		for c in constraint_list:
			# compute
			var Δλ = c.compute_Δλ(Δt)
			var Δx = c.compute_Δx(Δλ)
			
			# update
			c.λ = c.λ + Δλ
			c.p1.xi = c.p1.xi + c.p1.w * Δx
			c.p2.xi = c.p2.xi - c.p2.w * Δx
		
		i = i + 1
	
	for p in particle_data_list:
		if p.is_fixed:
			continue
		# update velocity
		p.v = (p.xi - p.x) / Δt + gravity * Δt
		# update position
		p.x = p.xi



