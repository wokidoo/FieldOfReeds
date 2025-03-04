shader_type spatial;

render_mode blend_mix,
			diffuse_toon,
			specular_toon,
			shadows_disabled;
			
uniform vec3 primary_color:source_color;
uniform vec3 secondary_color:source_color;
uniform float proximity_scale:hint_range(0.0, 1.0) = 1.0;
uniform vec3 proximity_color:source_color;
uniform sampler2D NOISE_TEXTURE_1:repeat_enable;
uniform sampler2D NOISE_TEXTURE_2:repeat_enable;
uniform sampler2D PROXIMITY_NOISE:repeat_enable;

uniform sampler2D depth_texture: hint_depth_texture, repeat_disable, filter_nearest;

const float time_scale = 0.0009;

void fragment() {
	float depth = texture(depth_texture,SCREEN_UV).r;
	vec4 depth_world_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	depth_world_pos.xyz /= depth_world_pos.w;
	float proximity = clamp(smoothstep(depth_world_pos.z + 1.0, depth_world_pos.z, VERTEX.z), 0.0, proximity_scale);

	float noise_1 = texture(NOISE_TEXTURE_1,UV+TIME*time_scale).g;
	float noise_2 = texture(NOISE_TEXTURE_2,UV-TIME*time_scale).g;
	float proximity_noise = texture(PROXIMITY_NOISE,UV+TIME*time_scale).g;
	
	vec3 color = mix(primary_color,secondary_color*proximity,noise_1*noise_2);
	color += proximity_color * proximity;
	
	ALBEDO = color;
	EMISSION = color;
	ALPHA = (1.0-proximity);
}

