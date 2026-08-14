shader_type spatial;

// Ensure vertex colors (your biomes) are passed to the fragment shader
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform float line_thickness : hint_range(0.0, 10.0) = 1.5;
uniform vec4 line_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
    // UV.x represents distance from center (0.0 at center, 1.0 at corners).
    // We calculate the distance from the absolute edge (1.0).
    float dist_from_edge = 1.0 - UV.x;
    
    // fwidth() calculates how fast UV.x is changing in screen space.
    // This brilliant function ensures your grid lines remain the exact same 
    // pixel thickness on your monitor regardless of how far the camera zooms out!
    float pixel_size = fwidth(UV.x);
    
    // Create a smooth mask that is 1.0 at the edge, and 0.0 inside the hex
    float line_mask = 1.0 - smoothstep(0.0, pixel_size * line_thickness, dist_from_edge);
    
    // Mix the vertex color (COLOR.rgb) with the line color based on the mask
    ALBEDO = mix(COLOR.rgb, line_color.rgb, line_mask);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
