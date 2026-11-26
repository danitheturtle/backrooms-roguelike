// Shader yoinked from a now deleted radial menu godot plugin and modded by me -Dani
//
// Copyright (c) 2021 Will Whitty
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

shader_type canvas_item;

const vec2 MIDPOINT = vec2(0.5, 0.5);
const float outer_radius = 0.5;

uniform float inner_radius = 0.25;
uniform float cursor_deg = 0.4;
uniform float cursor_size = 0.4;
uniform vec4 color_bg = vec4(0.3, 0.3, 0.3, 1.0);
uniform vec4 color_fg = vec4(0.6, 0.6, 0.6, 1.0);
uniform float bevel_radius = 0.05;
uniform bool bevel_enabled = false;
uniform vec4 bevel_color = vec4(0.8, 0.8, 0.8, 1.0);

// returns 1 if in circle, 0 if not
float circle(vec2 uv, float radius) {
    float dist = length(uv - MIDPOINT);
    if (dist <= radius) {
        return 1.0;
    }
    return 0.0;
}

float is_in_ring(vec2 uv) {
    return circle(uv, outer_radius) - circle(uv, inner_radius);
}

float is_in_bevel(vec2 uv) {
    float inside = circle(uv, inner_radius);
    float outside = circle(uv, outer_radius);
    return abs(
        (outside - circle(uv, outer_radius - bevel_radius)) +
        (circle(uv, inner_radius + bevel_radius))
    );
}

float find_deg(vec2 uv) {
    vec2 offset = uv - MIDPOINT;
    return atan(offset.y, offset.x);
}

vec4 find_color(vec2 uv) {
    // Bevel color logic
    if (bevel_enabled && is_in_bevel(uv) > 0.0) {
        return bevel_color;
    }
    float current_degree = abs(find_deg(uv) - cursor_deg);
    if (current_degree < cursor_size || current_degree > TAU - cursor_size) {
        return color_fg;
    }
    return color_bg;
}

void fragment() {
    COLOR = find_color(UV) * is_in_ring(UV);
}
