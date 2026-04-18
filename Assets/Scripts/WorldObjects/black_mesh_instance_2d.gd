extends MeshInstance2D

func _ready():
	var mesh = QuadMesh.new()
	mesh.size = Vector2(10000, 10000)  # big enough to cover everything
	self.mesh = mesh
	
	material = ShaderMaterial.new()
	material.shader = load("res://black_mask.gdshader")
	material.set_shader_parameter("world_radius", 300.0)
	
func update_radius(value: float):
	material.set_shader_parameter("world_radius", value)
