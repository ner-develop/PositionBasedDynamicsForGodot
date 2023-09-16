extends Node

class_name PBD

class Vertex:
	var is_fixed: bool = false
	var x: Vector3 = Vector3.ZERO
	var p: Vector3 = Vector3.ZERO
	var v: Vector3 = Vector3.ZERO
	var w: float = 0.0
	var initial_position: Vector3 = Vector3.ZERO
	var particle_ref: Particle = null
	
	func _init(particle:Particle):
		particle_ref = particle


@export var priority: int = 0
@export var stiffness: float = 1.0
@export var iterations: int = 10
@export var gravity: Vector3 = Vector3(0, -9.8, 0)
var vertices: Array[Vertex] = []




func initialize(particles:Array[Particle]):
	print("[" + name + "] initialize")
	for i in range(0, particles.size()):
		var vertex = Vertex.new(particles[i])
		vertices.append(vertex)
		
		# (1) ~ (3)
		vertex.is_fixed = i == 0
		vertex.initial_position = vertex.particle_ref.global_position
		
		vertex.x = vertex.initial_position
		vertex.v = Vector3.ZERO
		vertex.w = 1.0 / vertex.particle_ref.mass

func step(Δt:float):
	# 固定点の位置をデータに反映
	for vertex in vertices:
		if (!vertex.is_fixed):
			continue
		vertex.x = vertex.particle_ref.global_position
	
	simulate(Δt)
	
	# シミュレーション結果のデータを反映
	for vertex in vertices:
		vertex.particle_ref.global_position = vertex.x
	

func simulate(Δt:float):
	# (5)
	for vertex in vertices:
		if (vertex.is_fixed):
			continue
		vertex.v = vertex.v + Δt * gravity
	
	# (6) スキップ
	# damp velocities
	
	# (7)
	for vertex in vertices:
		vertex.p = vertex.x + Δt * vertex.v
	
	# (8) スキップ
	# generate collision constraints
	
	# (9) ~ (10)
	var k = 1.0 - pow(1 - clamp(stiffness, 0.0, 1.0), 1.0 / iterations)
	for iterationCount in range(0, iterations):
		project_constraints(k)
	
	# (12) ~ (15)
	for vertex in vertices:
		if (vertex.is_fixed):
			continue
		vertex.v = (vertex.p - vertex.x) / Δt
		vertex.x = vertex.p
	
	# (16) スキップ
	# velocity update
	
	
func project_constraints(k:float):
	for i in range(0, vertices.size() - 1):
		var v1 = vertices[i]
		var v2 = vertices[i + 1]
		
		var p1_p2 = v1.p - v2.p
		var p1_p2_length = p1_p2.length()
		var w1 = v1.w
		var w2 = v2.w
		
		var grad_c = p1_p2 / p1_p2_length
		var c = constraint(v1, v2)
		var s = c / ((w1 + w2) * grad_c.dot(grad_c))
		
		var Δp1 = -s * w1 * grad_c
		var Δp2 = +s * w1 * grad_c
		
		v1.p += Δp1 * k
		v2.p += Δp2 * k
	
func constraint(v1:Vertex, v2:Vertex):
	var d = (v1.initial_position - v2.initial_position).length()
	return (v1.p - v2.p).length() - d
