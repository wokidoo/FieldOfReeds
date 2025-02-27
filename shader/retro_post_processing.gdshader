shader_type canvas_item;
// Link to tutorial for the grain method used
// https://gameidea.org/2023/12/01/film-grain-shader/


uniform sampler2D SCREEN_TEXTURE: hint_screen_texture,filter_nearest;
uniform int BANDS : hint_range(1, 256, 1) = 12;
uniform int PIXEL_SIZE:hint_range(1, 1000, 1) = 300;
uniform sampler2D NOISE_TEXTURE: repeat_enable;
uniform float grain_amount: hint_range(0.0, 1.0, 0.01) = 0.05;
uniform float grain_size: hint_range(0.0, 10.0) = 1.0;

void fragment() {
	// Get pixelated UV coordinates
	vec2 grid_uv = round(UV * float(PIXEL_SIZE)) / float(PIXEL_SIZE);
	vec4 screen_texture = texture(SCREEN_TEXTURE,grid_uv);
	vec4 grain_texture = texture(NOISE_TEXTURE,grid_uv);
	grain_texture *= grain_amount *grain_size;
	// Apply color banding
	screen_texture.rgb = floor(screen_texture.rgb * float(BANDS)) / float(BANDS);
	// Apply grain
	screen_texture.rgb = clamp(grain_texture.rgb + screen_texture.rgb,0.0,1.0);
	COLOR = screen_texture;
}
