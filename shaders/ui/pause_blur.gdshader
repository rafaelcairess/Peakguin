shader_type canvas_item;
render_mode unshaded;

// Aumente este valor no Inspector para deixar o fundo mais desfocado.
uniform float blur_strength : hint_range(0.0, 5.0, 0.1) = 2.0;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;


void fragment() {
	vec4 screen_color = textureLod(screen_texture, SCREEN_UV, blur_strength);
	COLOR = vec4(screen_color.rgb, 1.0);
}
