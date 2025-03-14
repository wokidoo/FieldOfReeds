shader_type spatial;
render_mode blend_mix,
			depth_draw_opaque,
			cull_disabled,
			diffuse_toon,
			specular_toon,
			shadows_disabled,
			world_vertex_coords,
			ensure_correct_normals;

group_uniforms COLORS;
uniform vec4 BaseColor : source_color = vec4(0.507, 0.319, 0.093,1.0);
uniform vec4 SecondaryColor : source_color = vec4(0.13, 0.174, 0.025, 1.0);
uniform float color_coefficient: hint_range(-1.0, 1.0) = 0.0;

group_uniforms WIND;
global uniform float wind_speed;
global uniform vec3 wind_direction;
uniform sampler2D wind_noise:repeat_enable,filter_nearest_mipmap;

group_uniforms SWAY;
uniform float sway_intensity = 0.1;
uniform float sway_speed: hint_range(0.0, 50.0) = 1.0;
uniform vec3 sway_direction = vec3(1.0,0.0,1.0);
uniform sampler2D sway_noise : repeat_enable,filter_nearest;

group_uniforms MISC;
uniform float water_level_margin = 2.35;
uniform float roughness: hint_range(0.0, 1.0) = 0.0;
global uniform float water_level;

varying vec3 WORLD_POSITION;
varying bool REMOVE_BLADE;

const vec3 NORMAL_DIRECTION = vec3(0.0,1.0,0.0);

vec3 sway(float mask,float intensity, float speed, vec3 direction, vec4 noise_texture){
	//Initial direction of sway
	vec3 sway = sway_direction;
	//defines how far the sway will deform the vertex
	sway *= sway_intensity;
	//height mask for the each grass blade
	sway *= mask;
	//adds back and forth to sway and sets the speed of sway
	sway *= sin(TIME*noise_texture.g*speed);
	//uses sway_tex to randomly select sway direction
	sway *= mix(-1.0,1.0,noise_texture.g);
	//removes upwards sway
	sway.y =0.0;
	return sway;
}

void vertex(){
	//current blade height (0.0 - 1.0)
	float height = (1.0-UV.y);

	//Used to choose which blades of grass will sway based off a noise map
	vec4 sway_tex = texture(sway_noise,NODE_POSITION_WORLD.xz);
	//sway effect
	vec3 sway = sway(height,sway_intensity,sway_speed,sway_direction,sway_tex);

	vec4 wind_tex = texture(wind_noise,NODE_POSITION_WORLD.xz);
	vec3 wind = wind_direction;
	wind *= height;
	wind *= mix(0.5,1.0,(sin(TIME * wind_speed * wind_tex.g)+1.0)/2.0);
	//wind *= mix(-1.0,1.0,wind_tex.g);
	wind.y = 0.0;

	VERTEX += sway;
	VERTEX += wind;

	WORLD_POSITION = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 colour = mix(BaseColor.rgb,SecondaryColor.rgb,color_coefficient+UV.y);

	ALBEDO = colour;
	ROUGHNESS = roughness;
	NORMAL = NORMAL_DIRECTION;
	NORMAL_MAP = NORMAL_DIRECTION;
}
