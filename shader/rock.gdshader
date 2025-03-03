shader_type spatial;
render_mode blend_mix, 
			depth_draw_opaque, 
			cull_disabled, 
			diffuse_toon, 
			specular_toon,
			world_vertex_coords,
			shadows_disabled;
uniform vec3 primary_colour: source_color = vec3(0.13, 0.174, 0.025);
uniform vec3 secondary_colour: source_color;
uniform float weight:hint_range(0.0, 1.0);
uniform float water_level_margin = 0.0;
global uniform float water_level;

varying vec3 local_normal;
 
void vertex(){
	local_normal = NORMAL;
}

void fragment() {
	float world_y = (INV_VIEW_MATRIX * vec4(VERTEX,1.0)).y;
	float edge = smoothstep(water_level+water_level_margin,water_level,world_y);
	vec3 colour = mix(primary_colour,secondary_colour,edge);
	//colour = vec3(0.0,DEPTH,0.0);
	ALBEDO.rgb = colour;
}

