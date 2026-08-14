shader_type spatial;

uniform sampler2D heightmap : hint_default_black;
uniform float height_scale = 10.0;
uniform float texture_scale = 1.0;

uniform vec3 grass_color : source_color = vec3(0.2, 0.6, 0.1);
uniform vec3 rock_color : source_color = vec3(0.4, 0.4, 0.4);

void vertex() {
    // 1. Calculate UV coordinates (or use VERTEX.xz for world-space tiling)
    vec2 sample_uv = UV * texture_scale;

    // 2. Sample height from the noise texture
    float height = texture(heightmap, sample_uv).r;

    // 3. Displace the vertical position
    VERTEX.y += height * height_scale;

    // 4. Recalculate Normals (Finite Difference method) for proper lighting
    float delta = 0.01;
    float h_right = texture(heightmap, sample_uv + vec2(delta, 0.0)).r * height_scale;
    float h_up    = texture(heightmap, sample_uv + vec2(0.0, delta)).r * height_scale;

    vec3 tangent = normalize(vec3(delta, h_right - (height * height_scale), 0.0));
    vec3 bitangent = normalize(vec3(0.0, h_up - (height * height_scale), delta));
    NORMAL = normalize(cross(bitangent, tangent));
}

void fragment() {
    // 1. Check vertical orientation (NORMAL.y = 1.0 is flat ground, 0.0 is a vertical cliff)
    float slope = NORMAL.y;

    // 2. Blend between grass and rock based on steepness
    if (slope > 0.7) {
        ALBEDO = grass_color;
    } else {
        ALBEDO = rock_color;
    }

    // 3. Set surface roughness
    ROUGHNESS = 0.8;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
