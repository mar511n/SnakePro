shader_type canvas_item;
render_mode world_vertex_coords;
render_mode blend_mix;

uniform sampler2D windnoise;
uniform vec2 lefttop = vec2(48,48);
uniform vec2 size = vec2(2448,2448);
// Wind settings.
uniform float speed = 1.2;
uniform float minStrength : hint_range(0.0, 1.0) = 0.15;
uniform float maxStrength : hint_range(0.0, 1.0) = 0.3;
uniform float strengthScale = 200.0;
uniform float interval = 3.5;
uniform float detail = 2.0;
uniform float heightOffset : hint_range(0.0, 1.0);
uniform float minHeight : hint_range(-1.0, 1.0, 0.1);

varying vec2 vert;
varying float noise;


float getWind(vec2 uv, float time){
    float diff = pow(maxStrength - minStrength, 2.0);
    float strength = clamp(minStrength + diff + sin(time / interval) * diff, minStrength, maxStrength) * strengthScale;
    float wind = (sin(time) + cos(time * detail)) * strength * max(minHeight, (1.0-uv.y) - heightOffset);
    return wind;
}

void vertex() {
	vert = (VERTEX-lefttop)/size;
	noise = texture(windnoise, vert).r;
    float time = TIME * speed + noise*5.0 + vert.x*10.0;
    VERTEX.x += getWind(UV, time);
}
/*
void fragment() {
	COLOR = vec4(vert.x,vert.y,0.0,noise);
	if (vert.x > 1.0 || vert.y > 1.0 || vert.x < 0.0 || vert.y < 0.0) {
		COLOR = vec4(0.0,0.0,0.0,1.0);
	}
}
*/