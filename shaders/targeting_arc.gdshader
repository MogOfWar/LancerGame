shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix;

uniform vec4 line_color : source_color = vec4(0.0, 1.0, 0.4, 1.0);
uniform float speed : hint_range(0.1, 10.0) = 3.0;
uniform float density : hint_range(1.0, 30.0) = 10.0;
uniform float glow_strength : hint_range(1.0, 10.0) = 3.0;

void fragment() {
    // Scroll UV.x backwards to make arrows move forward towards the target
    float scrolled_x = mod(UV.x * density - TIME * speed, 1.0);
    
    // Create an arrow / chevron shape procedurally
    // UV.y goes from 0.0 (left side) to 1.0 (right side)
    float center_y = abs(UV.y - 0.5) * 2.0; // 0.0 at center, 1.0 at edges
    float arrow_mask = step(center_y, scrolled_x) * step(scrolled_x, center_y + 0.3);
    
    // Fallback: Simple dashed line if you prefer dashes over arrows
    float dash_mask = step(0.5, scrolled_x);

    ALBEDO = line_color.rgb;
    ALPHA = line_color.a * dash_mask;
    
    // EMISSION drives Godot's Glow/WorldEnvironment Bloom
    EMISSION = line_color.rgb * glow_strength * arrow_mask;
}