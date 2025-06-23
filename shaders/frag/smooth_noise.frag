#version 330 core
out vec4 frag_color;

in VS_OUT {
	vec3 frag_position;
	vec3 tex_coords;
}
fs_in;

uniform float zoom;
uniform sampler3D noise;

/*

	fract_x := linalg.fract(x)
	fract_y := linalg.fract(y)
	fract_z := linalg.fract(z)

	x2 := x - 1
	if x2 < 0 do x2 = linalg.round(NOISE_WIDTH / zoom) - 1
	xi := int(x)
	x2i := int(x2)

	y2 := y - 1
	if y2 < 0 do y2 = linalg.round(NOISE_HEIGHT / zoom) - 1
	yi := int(y)
	y2i := int(y2)

	z2 := z - 1
	if z2 < 0 do z2 = linalg.round(NOISE_DEPTH / zoom) - 1
	zi := int(z)
	z2i := int(z2)

	value: f64 = 0
	value += fract_x * fract_y * fract_z * noise[get_noise_index(xi, yi, zi)]
	value += (1 - fract_x) * fract_y * fract_z * noise[get_noise_index(x2i, yi, zi)]
	value += fract_x * (1 - fract_y) * fract_z * noise[get_noise_index(xi, y2i, zi)]
	value += (1 - fract_x) * (1 - fract_y) * fract_z * noise[get_noise_index(x2i, y2i, zi)]
	value += fract_x * fract_y * (1 - fract_z) * noise[get_noise_index(xi, yi, z2i)]
	value += (1 - fract_x) * fract_y * (1 - fract_z) * noise[get_noise_index(x2i, yi, z2i)]
	value += fract_x * (1 - fract_y) * (1 - fract_z) * noise[get_noise_index(xi, y2i, z2i)]
	value += (1 - fract_x) * (1 - fract_y) * (1 - fract_z) * noise[get_noise_index(x2i, y2i, z2i)]

*/

void main() {
	vec3 texture_size = textureSize(noise, 0) / zoom;
	vec3 texel_size = 1.0 / texture_size;

	vec3 tex_coords = fs_in.tex_coords * texture_size; // 0.0 ~ 255.0
	vec3 rounded_coords = floor(tex_coords);		   // 0 ~ 255
	vec3 fractions = tex_coords - rounded_coords;	   // 0.0 ~ 1.0
	vec3 inverse = vec3(1.0) - fractions;			   // 0.0 ~ 1.0

	vec3 fract_coords = rounded_coords * texel_size; // 0.0 ~ 1.0
	vec3 offset = fract_coords - texel_size;		 // 0.0 ~ 1.0

	vec3 value = vec3(0.0);

	value += fractions.x * fractions.y * fractions.z * texture(noise, fract_coords).rgb;
	value += inverse.x * fractions.y * fractions.z * texture(noise, vec3(offset.x, fract_coords.yz)).rgb;
	value += fractions.x * inverse.y * fractions.z * texture(noise, vec3(fract_coords.x, offset.y, fract_coords.z)).rgb;
	value += inverse.x * inverse.y * fractions.z * texture(noise, vec3(offset.xy, fract_coords.z)).rgb;

	value += fractions.x * fractions.y * inverse.z * texture(noise, vec3(fract_coords.xy, offset.z)).rgb;
	value += inverse.x * fractions.y * inverse.z * texture(noise, vec3(offset.x, fract_coords.y, offset.z)).rgb;
	value += fractions.x * inverse.y * inverse.z * texture(noise, vec3(fract_coords.x, offset.yz)).rgb;
	value += inverse.x * inverse.y * inverse.z * texture(noise, offset).rgb;

	// for (int x = -1; x <= 1; x += 2) {
	// 	for (int y = -1; y <= 1; y += 2) {
	// 		for (int z = -1; z <= 1; z += 2) {
	// 			vec3 offset = vec3(x, y, z) * texel_size;
	// 			value += texture(noise, tex_coords + offset).rgb;
	// 		}
	// 	}
	// }
	//
	// value /= 8.0;

	frag_color = vec4(value, 1.0);
}
