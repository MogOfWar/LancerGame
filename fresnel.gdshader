shader_type spatial;

render_mode blend_mix, cull_disabled, depth_draw_opaque;

uniform vec3 albedo : source_color = vec3(1.0, 0.0, 0.0); // Color of the cylinder
uniform float edge_intensity : hint_range(0.1, 5.0) = 5.0; // Controls how thick the opaque edge is
uniform float center_transparency : hint_range(0.0, 1.0) = 0.1; // Transparency of the middle
uniform float fresnel_intensity: hint_range(0.0,1.0) = 0.5;

void fragment() {
    // Calculate the Fresnel effect (0 at the center facing the camera, 1 at the grazing edges)
    float fresnel = 1.0 - dot(normalize(NORMAL), VIEW)*fresnel_intensity;
    fresnel = pow(fresnel, edge_intensity);

    // Set the base color
    ALBEDO = albedo;
    
    // Combine center transparency with edge opacity
    ALPHA = clamp(center_transparency + fresnel, 0.0, 1.0);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
