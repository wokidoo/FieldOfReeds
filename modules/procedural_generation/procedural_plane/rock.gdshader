shader_type spatial;
render_mode blend_mix, 
			depth_draw_opaque, 
			cull_disabled, 
			diffuse_toon, 
			specular_toon,
			shadows_disabled;
uniform vec3 primary_colour: source_color = vec3(0.13, 0.174, 0.025);
uniform vec3 secondary_colour: source_color;
uniform float weight:hint_range(0.0, 1.0);
varying vec3 local_normal;
 
void vertex(){
	local_normal = NORMAL;
}

void fragment() {
	float edge = dot(vec3(0.0,1.0,0.0),local_normal);
	vec3 colour = mix(primary_colour,secondary_colour,step(edge,weight));
	//colour = vec3(0.0,DEPTH,0.0);
	ALBEDO.rgb = colour;
}

