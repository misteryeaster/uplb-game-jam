shader_type canvas_item;
render_mode unshaded;

const vec2 OFFSETS[8] = {
	vec2(-0.71, -0.71), vec2(-1, 0), vec2(-0.71, 0.71), vec2(0, -1), vec2(0, 1), 
	vec2(0.71, -0.71), vec2(1, 0), vec2(0.71, 0.71)
};

uniform float pixel_size : hint_range(1.0, 50.0) = 4.0;
uniform float line_thickness : hint_range(0.0, 10.0) = 1.0;
uniform vec4 line_color : source_color = vec4(1.0);
uniform bool enable_pixelation = true;
uniform bool enable_outline = true;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
	vec2 uv = SCREEN_UV;
	
	// Apply pixelation if enabled
	if (enable_pixelation) {
		// Calculate texture dimensions
		vec2 texture_size = 1.0 / SCREEN_PIXEL_SIZE;
		// Pixelate the UV coordinates
		uv = floor(SCREEN_UV * texture_size / pixel_size) * pixel_size / texture_size;
		// Clamp to ensure we stay within bounds
		uv = clamp(uv, vec2(0.0), vec2(1.0));
	}
	
	// Get the base color from pixelated or regular coordinates
	vec4 c = texture(screen_texture, uv);
	
	// Apply outline effect if enabled
	if (enable_outline) {
		vec2 size = line_thickness * SCREEN_PIXEL_SIZE;
		float outline = 0.0;
		
		// Project in each direction using the same UV coordinates (pixelated or not)
		for (int i = 0; i < OFFSETS.length(); i++) {
			vec2 coordinate_offset = uv + size * OFFSETS[i];
			outline += texture(screen_texture, coordinate_offset).a;
		}
		
		// Force outline to 1 or 0
		outline = sign(outline);
		
		// If the alpha exists at least a little bit, amplify the colors.
		// This ensures alpha and colors remain precise even when reading from screen.
		if (c.a > 0.0001) {
			c.rgb /= c.a;
		}
		
		c = mix(c, line_color, outline - c.a);
	}
	
	COLOR = c;
}