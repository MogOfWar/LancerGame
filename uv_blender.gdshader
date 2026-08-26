shader_type spatial;
render_mode blend_mix, cull_disabled;

instance uniform vec3 albedo : source_color = vec3(1.0, 1.0, 1.0);
uniform float center_transparency : hint_range(0.0, 1.0) = 0.1;
uniform float radius;
uniform float edge_intensity : hint_range(1.0, 2.0) = 1.5;

// Passes the local vertex position from the vertex shader to the fragment shader
varying vec3 local_pos;

void vertex() {
    // VERTEX in the vertex function is in local object space (model space)
    local_pos = VERTEX;
}

void fragment() {
    // Calculate the horizontal distance from the center axis (ignoring height/Y)
    float dist_from_center = length(local_pos.xz);
    
    // Normalize it based on your actual radius (0.0 at center, 1.0 at outer edge)
    float edge_factor = pow(clamp(dist_from_center / radius, 0.0, 1.0), edge_intensity);

    ALBEDO = albedo*vec3(edge_factor, edge_factor, edge_factor);
    
    // Fades smoothly from the center transparency to fully opaque at the edges
    ALPHA = mix(center_transparency, 1.0, edge_factor);
}
