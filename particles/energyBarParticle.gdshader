shader_type canvas_item;
render_mode blend_mix;

uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_width_pixels : hint_range(0.0, 10.0) = 2.0;
uniform float alpha_threshold : hint_range(0.0, 1.0) = 0.05;

void fragment() {
	// Get the color and alpha of the current pixel
	vec4 pixel_color = texture(TEXTURE, UV);
	
	// Check if the current pixel is mostly transparent
	if (pixel_color.a < alpha_threshold) {
		// Get texture size and calculate pixel size in UV coordinates
		vec2 texture_size = vec2(textureSize(TEXTURE, 0));
		vec2 pixel_uv_size = vec2(1.0) / texture_size;
		
		bool found_opaque_neighbor = false;
		
		// Sample in a circle/diamond pattern for better outline quality
		float width = outline_width_pixels;
		
		// Check neighbors within the outline width
		for (float y = -width; y <= width && !found_opaque_neighbor; y += 1.0) {
			for (float x = -width; x <= width && !found_opaque_neighbor; x += 1.0) {
				// Skip center pixel
				if (x == 0.0 && y == 0.0) continue;
				
				// Optional: Use distance check for circular outline instead of square
				// if (length(vec2(x, y)) > width) continue;
				
				// Calculate neighbor UV
				vec2 neighbor_uv = UV + vec2(x, y) * pixel_uv_size;
				
				// Only sample if within texture bounds
				if (neighbor_uv.x >= 0.0 && neighbor_uv.x <= 1.0 && 
				    neighbor_uv.y >= 0.0 && neighbor_uv.y <= 1.0) {
					
					float neighbor_alpha = texture(TEXTURE, neighbor_uv).a;
					
					if (neighbor_alpha >= alpha_threshold) {
						found_opaque_neighbor = true;
					}
				}
			}
		}
		
		if (found_opaque_neighbor) {
			COLOR = outline_color;
		} else {
			COLOR = vec4(0.0, 0.0, 0.0, 0.0);
		}
	} else {
		// Pixel is opaque, use original color
		COLOR = pixel_color;
	}
}