shader_type canvas_item;

uniform sampler2D base_offset;
uniform float line_tickness = 0.1;
uniform float offset_mul = 2.0;
uniform float amp1 = 0.125;
uniform float freq1 = 4;
uniform float speed1 = 5.0;
uniform float amp2 = 0.125;
uniform float freq2 = 9;
uniform float speed2 = 1.46;
uniform vec4 col : source_color = vec4(1.0);

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	float angle = atan(UV.y-0.5, UV.x-0.5);
	if (angle < 0.0) {
	angle += 2.0 * PI;
	}
	float h = amp1*sin(angle*freq1 + TIME*speed1) + amp2*sin(angle*freq2 + TIME*speed2);
	h += amp1+amp2;
	h += texture(base_offset, vec2(1.0-angle/(2.0*PI),0)).r*offset_mul;
	h /= 2.0*(amp1+amp2) + offset_mul;
	h = clamp(h, 0.0, 1.0);
	float r = length(vec2(UV.x-0.5,UV.y-0.5))*2.0;
	if (r < h && h-r < line_tickness) {
		COLOR = vec4(col.r,col.g,col.b,COLOR.a);
	}else{
		COLOR = vec4(0.0,0.0,0.0,0.0);
	}
	//COLOR = vec4(vec3(1)*h,1);
	//COLOR *= texture(base_offset, vec2(UV.x,UV.y));
}

