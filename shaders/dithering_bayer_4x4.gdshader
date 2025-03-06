shader_type canvas_item;

// Link to tutorial for the grain method used
// https://gameidea.org/2023/12/01/film-grain-shader/

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_nearest;
uniform int BANDS : hint_range(1, 256, 1) = 12;
uniform int PIXEL_SIZE: hint_range(1, 1000, 1) = 300;
uniform sampler2D NOISE_TEXTURE: repeat_enable;
uniform float grain_amount: hint_range(0.0, 1.0, 0.01) = 0.05;
uniform float grain_size: hint_range(0.0, 10.0) = 1.0;
uniform float dither_strength : hint_range(0.0, 1.0, 0.01) = 0.1; // Dithering intensity

// 4x4 Bayer dither matrix (normalized)
const float bayer_4x4[16] = float[16](
    0.0 / 16.0,  8.0 / 16.0,  2.0 / 16.0, 10.0 / 16.0,
    12.0 / 16.0,  4.0 / 16.0, 14.0 / 16.0,  6.0 / 16.0,
    3.0 / 16.0, 11.0 / 16.0,  1.0 / 16.0,  9.0 / 16.0,
    15.0 / 16.0,  7.0 / 16.0, 13.0 / 16.0,  5.0 / 16.0
);

void fragment() {
    // Get pixelated UV coordinates
    vec2 grid_uv = round(UV * float(PIXEL_SIZE)) / float(PIXEL_SIZE);
    vec4 screen_texture = texture(SCREEN_TEXTURE, grid_uv);
    vec4 grain_texture = texture(NOISE_TEXTURE, grid_uv);
    grain_texture *= grain_amount * grain_size;

    // Get pixel position in a 4x4 grid
    ivec2 pixel_pos = ivec2(FRAGCOORD.xy) % 4;
    int bayer_index = pixel_pos.y * 4 + pixel_pos.x;
    float threshold = bayer_4x4[bayer_index];

    // Calculate base color quantization
    float band_factor = float(BANDS);
    vec3 raw_color = screen_texture.rgb;
    
    // Apply dithering *before* quantization to smooth banding transitions
    vec3 dithered_input = raw_color + (dither_strength * threshold / band_factor);
    
    // Now quantize the dithered color
    vec3 quantized_color = floor(dithered_input * band_factor) / band_factor;

    // Ensure valid color range
    quantized_color = clamp(quantized_color, 0.0, 1.0);

    // Apply grain
    quantized_color = clamp(grain_texture.rgb + quantized_color, 0.0, 1.0);

    COLOR = vec4(quantized_color, screen_texture.a);
}
