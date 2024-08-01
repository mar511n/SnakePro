shader_type canvas_item;
uniform vec4 color = vec4(1.0);
uniform float frequency = 10.0;
uniform float phase_speed = 17.0;

void fragment() {
  vec2 pos = UV - vec2(0.5);
  float angle = atan(pos.y, pos.x);
  if (angle < 0.0) {
    angle += 2.0 * PI;
  }
  float ring = step(0,sin(frequency * angle + TIME * phase_speed));
  COLOR = vec4(COLOR.rgb, ring * COLOR.a);
}