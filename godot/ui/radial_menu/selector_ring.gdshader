shader_type canvas_item;

const vec2 MIDPOINT = vec2(0.5, 0.5);
const float outer_radius = 0.5;

uniform float inner_radius = 0.25;
uniform bool snap = true;
uniform bool cursor_enabled = false;
uniform float cursor_pos = 0.0;
uniform float cursor_size = 1.570796;
uniform vec4 color_bg = vec4(0.3, 0.3, 0.3, 1.0);
uniform vec4 color_fg = vec4(0.6, 0.6, 0.6, 1.0);

// returns 1 if in circle, 0 if not
float circle(vec2 _uv, float _radius) {
    float dist = length(_uv - MIDPOINT);
    if (dist <= _radius) {
        return 1.0;
    }
    return 0.0;
}

// returns 1 if in ring, 0 if not
float is_in_ring(vec2 _uv, float _outer_radius, float _inner_radius) {
    return circle(_uv, _outer_radius) - circle(_uv, _inner_radius);
}

void fragment() {
    float half_cursor_size = cursor_size * 0.5;
    vec2 offset = UV - MIDPOINT;
    float pixel_rotation = atan(offset.y,offset.x);
    float next_cursor_pos = snap
        ? round(cursor_pos / cursor_size) * cursor_size
        : cursor_pos;
    float pixel_to_cursor_rotation = abs(pixel_rotation - next_cursor_pos);
    bool pixel_in_cursor = (
        pixel_to_cursor_rotation < half_cursor_size || 
        pixel_to_cursor_rotation > TAU - half_cursor_size
    );
    float pixel_not_in_cursor = float(!cursor_enabled || !pixel_in_cursor);
    vec4 final_bg_color = color_bg * pixel_not_in_cursor + color_fg * (1.0 - pixel_not_in_cursor);
    COLOR = final_bg_color * is_in_ring(UV, outer_radius, inner_radius);
}
