shader_type spatial;

uniform sampler2D texturemap: hint_albedo;
uniform vec2 texture_scale = vec2(8.0, 4.0);

uniform sampler2D uv_offset_texture: hint_black;
uniform vec2 uv_offset_scale = vec2(0.1, 0.1);
uniform float uv_offset_time_scale = 0.02;
uniform float uv_offset_amplitude = 0.025;

uniform sampler2D normalmap: hint_normal;

uniform vec2 amplitude = vec2(1.2, 0.2);
uniform vec2 frequency = vec2(3, 1.2);

uniform vec2 time_factor = vec2(1.0, 1.5);

uniform float refraction = 0.05;

uniform float beer_factor = 1.0;

uniform vec3 watercolor = vec3(0.2, 0.25, 0.3);
uniform float wavegain = 1.0;

uniform vec2 tangent_offset = vec2(0.0, 0.8);
uniform vec2 binormal_offset = vec2(0.8, 0.0);


float height(vec2 pos, float time) {
	return amplitude.x * sin(pos.x * frequency.x + TIME + time_factor.x) + amplitude.y * sin(pos.y * frequency.y + TIME * time_factor.y);
}

void vertex() {
	VERTEX.y += height(VERTEX.xz, TIME);
	
	TANGENT = normalize(vec3(0.0, height(VERTEX.xz + tangent_offset, TIME) - height(VERTEX.xz - tangent_offset, TIME), 1));
	BINORMAL = normalize(vec3(1, height(VERTEX.xz + binormal_offset, TIME) - height(VERTEX.xz - binormal_offset, TIME), 0.0));
	
	NORMAL = cross(TANGENT, BINORMAL);
}

void fragment() { 
	vec2 base_uv_offset = UV * uv_offset_scale;
	base_uv_offset += TIME * uv_offset_time_scale;
	
	vec2 texture_based_offset = texture(uv_offset_texture, base_uv_offset).rg;
	texture_based_offset = texture_based_offset * 2.0 - 1.0;
	
	vec2 texture_uv = UV * texture_scale;
	texture_uv += uv_offset_amplitude * texture_based_offset;
	
	float waves_height = texture_based_offset.y + uv_offset_amplitude;
	
	ALBEDO = texture(texturemap, texture_uv).rgb * 0.5;
	
	if (ALBEDO.r > 0.9 && ALBEDO.g > 0.9 && ALBEDO.b > 0.9) {
		ALPHA = 0.9;
	} else {
		float depth = texture(DEPTH_TEXTURE, SCREEN_UV).r;
		
		// grab to values
		//depth = depth * 50.0 - 49.0;
		
		// unproject depth
		depth = depth * 2.0 - 1.0;
		float z = -PROJECTION_MATRIX[3][2] / (depth + PROJECTION_MATRIX[2][2]);
		// float x = (SCREEN_UV.x * 2.0 - 1.0) * z / PROJECTION_MATRIX[0][0];
		// float y = (SCREEN_UV.y * 2.0 - 1.0) * z / PROJECTION_MATRIX[1][1];
		float delta = -(z - VERTEX.z); // z is negative.
		// delta *= 0.1;
		
		// beers law
		float att = exp(-delta * beer_factor);
		
		ALPHA = clamp(1.0 - att, 0.0, 1.0);
	}
	

	NORMALMAP = texture(normalmap, base_uv_offset / 5.0).rgb;
	NORMALMAP_DEPTH = 0.2;
	METALLIC = 0.5;
	ROUGHNESS = 0.2;
	
	vec3 ref_normal = normalize(mix(NORMAL, 
		TANGENT * NORMALMAP.x  + BINORMAL * NORMALMAP.y + NORMAL + NORMALMAP.z,
		NORMALMAP_DEPTH));
	vec2 ref_ofs = SCREEN_UV - ref_normal.xy * refraction;
	EMISSION += textureLod(SCREEN_TEXTURE, ref_ofs, ROUGHNESS * 0.0).rgb * (1.0 - ALPHA);
	ALBEDO *= ALPHA;
	
	 // calculate water-mirror
    vec2 xdiff = vec2(0.1, 0.0)*wavegain*4.;
    vec2 ydiff = vec2(0.0, 0.1)*wavegain*4.;

}