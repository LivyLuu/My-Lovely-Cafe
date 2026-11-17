shader_type spatial;
render_mode cull_back, specular_disabled;

// Base look
uniform vec4 base_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D albedo_texture : source_color;

// The shadow band is TINTED rather than just darkened — this is the
// single biggest thing that sells "anime" over generic toon shading.
// Cool blue-purple for daytime scenes, warm orange-red for sunset —
// just swap this per material instance, same shader everywhere.
uniform vec4 shade_color : source_color = vec4(0.55, 0.5, 0.68, 1.0);
uniform float shade_threshold : hint_range(-1.0, 1.0) = 0.0;
uniform float shade_softness : hint_range(0.01, 0.5) = 0.08;

// Rim light — the glowing edge look. Tint this warm/orange for sunset
// backlighting, cooler for daytime.
uniform vec4 rim_color : source_color = vec4(1.0, 0.85, 0.65, 1.0);
uniform float rim_power : hint_range(1.0, 8.0) = 3.0;
uniform float rim_strength : hint_range(0.0, 2.0) = 0.5;

// Small sharp specular dot, classic anime hair/eye/glossy-surface
// highlight. Leave at 0.0 for matte props (wood, fabric); turn up for
// ceramics, glass, ceramics, ceramic mugs, metal.
uniform float highlight_strength : hint_range(0.0, 2.0) = 0.0;
uniform float highlight_size : hint_range(1.0, 128.0) = 48.0;

// Real-time shadows from the world's main light (the sun / moon): the shadow shapes other objects
// and the model's own limbs and ears throw onto the surface.
//   OFF (default): the material is still lit by the real light (its direction, colour and
//                  strength drive the toon shade), but the light's shadow map is ignored, so
//                  no extra shadow shapes land on top of the toon shade.
//   ON:            the light's shadow map darkens the material like any other lit surface.
// This only covers directional lights. A point or spot light that has shadows turned on still
// casts its shadows here: for those, Godot gives light() a single combined number (range
// falloff times shadow) that can't be pulled apart.
uniform bool receive_world_shadows = false;

void fragment() {
	ALBEDO = base_color.rgb * texture(albedo_texture, UV).rgb;
	ROUGHNESS = 1.0;

	// Rim light computed once here, reused for every light in light().
	vec3 view_dir = normalize(VIEW);
	float fresnel = pow(1.0 - clamp(dot(NORMAL, view_dir), 0.0, 1.0), rim_power);
	EMISSION = rim_color.rgb * fresnel * rim_strength;
}

void light() {
	// ATTENUATION is the light's range falloff multiplied by its shadow map. A directional light
	// has no range falloff, so for the sun it is ONLY the shadow map: using 1.0 instead ignores
	// the shadows while the light's direction and colour still shape the toon shade below.
	float atten = ATTENUATION;
	if (!receive_world_shadows && LIGHT_IS_DIRECTIONAL) {
		atten = 1.0;
	}

	// Two-band toon diffuse: smoothstep instead of a hard if/else, so
	// the band edge is soft (no jagged aliasing) at negligible extra cost.
	float ndotl = dot(NORMAL, LIGHT);
	float band = smoothstep(shade_threshold - shade_softness, shade_threshold + shade_softness, ndotl);

	vec3 lit = ALBEDO;
	vec3 shadowed = ALBEDO * shade_color.rgb;
	DIFFUSE_LIGHT += mix(shadowed, lit, band) * atten * LIGHT_COLOR;

	if (highlight_strength > 0.0) {
		float spec = pow(clamp(dot(NORMAL, normalize(LIGHT + VIEW)), 0.0, 1.0), highlight_size);
		float spec_band = smoothstep(0.5, 0.52, spec);
		SPECULAR_LIGHT += spec_band * highlight_strength * LIGHT_COLOR * atten;
	}
}
