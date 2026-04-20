shader_type canvas_item;

uniform float world_radius = 1000.0;

void fragment() {
    vec2 world_pos = (UV - vec2(0.5)) * 10000.0;
    float dist = length(world_pos);

    float edge = smoothstep(world_radius - 20.0, world_radius + 20.0, dist);
    COLOR = vec4(0.0, 0.0, 0.0, edge);
}