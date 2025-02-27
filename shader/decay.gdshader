shader_type spatial;

uniform float AMOUNT: hint_range(0.0, 1.0);
uniform sampler2D MASK;
uniform sampler2D DECAY;

void fragment() {
    // Sample the decay texture and mask
    vec4 decay = texture(DECAY, UV);
    float mask = texture(MASK, UV).r;

    // Calculate progress
    float progress = step(mask, AMOUNT);
    // Set ALBEDO for the decay effect
    ALBEDO = decay.rgb;

    // Use ALPHA to blend the overlay with the base material
    ALPHA = progress;
}
