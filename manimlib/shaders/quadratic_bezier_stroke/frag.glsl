#version 330

in vec2 uv_coords;

in float uv_stroke_width;
in float uv_anti_alias_width;
in vec4 color;

in float is_linear;

out vec4 frag_color;

const float QUICK_DIST_WIDTH = 0.2;

float dist_to_curve(){
    // Returns distance from uv_coords to the curve v = u^2
    float x0 = uv_coords.x;
    float y0 = uv_coords.y;

    // In the linear case, the curve will have
    // been set to equal the x axis
    if(bool(is_linear)) return abs(y0);

    if(uv_stroke_width < QUICK_DIST_WIDTH){
        // This is a quick approximation for computing
        // the distance to the curve.
        // Evaluate F(x, y) = y - x^2
        // divide by its gradient's magnitude
        return abs((y0 - x0 * x0) / sqrt(1 + 4 * x0 * x0));
    }
    // Otherwise, solve for the minimal distance.
    // The distance squared between (x0, y0) and a point (x, x^2) looks like
    //
    // (x0 - x)^2 + (y0 - x^2)^2 = x^4 + (1 - 2y0)x^2 - 2x0 * x + (x0^2 + y0^2)
    //
    // Setting the derivative equal to zero (and rescaling) looks like
    // 
    // x^3 + (0.5 - y0) * x - 0.5 * x0 = 0
    //
    // Use two rounds of Newton's method
    float x = x0;
    float p = (0.5 - y0);
    float q = -0.5 * x0;
    for(int i = 0; i < 2; i++){
        float fx = x * x * x + p * x + q;
        float dfx = 3 * x * x + p;
        x = x - fx / dfx;
    }
    return distance(uv_coords, vec2(x, x * x));
}


void main() {
    if (uv_stroke_width == 0) discard;

    // sdf for the region around the curve we wish to color.
    float signed_dist = dist_to_curve() - 0.5 * uv_stroke_width;

    frag_color = color;
    frag_color.a *= smoothstep(0.5, -0.5, signed_dist / uv_anti_alias_width);
}