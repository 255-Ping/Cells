extends MeshInstance2D

func _ready():
	var quad = QuadMesh.new()
	quad.size = Vector2(10000, 10000)  # big enough to cover everything
	self.mesh = quad

	material = ShaderMaterial.new()
	material.shader = load("res://Assets/Shaders/black_mask.gdshader")
	material.set_shader_parameter("world_radius", WorldWrapper.world_radius)
	WorldWrapper.world_radius_changed.connect(update_radius)
	
func update_radius(value: float):
	material.set_shader_parameter("world_radius", value)
