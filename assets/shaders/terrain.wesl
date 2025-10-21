struct VertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(2) uv: vec2<f32>,
}

struct CustomMaterial {
    // Needed for 16-bit alignment on WebGL2
    time: vec4<f32>,
}

@group(2) @binding(0) var<uniform> material: CustomMaterial;
@group(2) @binding(1) var height_texture: texture_2d<f32>;
@group(2) @binding(2) var height_texture_sampler: sampler;

const UV_STEPS = 128.0;

fn rgb(r: i32, g: i32, b: i32) -> vec3<f32> {
    return vec3<f32>(f32(r) / 255.0, f32(g) / 255.0, f32(b) / 255.0);
}

fn quantize(v: f32, n: f32) -> f32 {
    return (floor(v * n) + 0.5) / n;
}

fn v2(x: f32, y: f32) -> vec2<f32> {
    return vec2<f32>(x, y);
}

fn h(p: vec2<f32>) -> f32 {
    return textureSample(height_texture, height_texture_sampler, p).x;
}

// top, left, right, bottom
fn surrounding_heights(uv: vec2<f32>) -> vec4<f32> {
    let x = quantize(uv.x, UV_STEPS);
    let y = quantize(uv.y, UV_STEPS);
    let offset = 1.0 / UV_STEPS;

    let top = y + offset;
    let bottom = y - offset;
    let left = x - offset;
    let right = x + offset;

    return vec4<f32>(
        h(v2(x, top)),
        h(v2(left, y)),
        h(v2(right, y)),
        h(v2(x, bottom))
    );
}

fn distance_to_closest_neighbor(uv: vec2<f32>) -> f32 {
    let x = quantize(uv.x, UV_STEPS) - uv.x;
    let y = quantize(uv.y, UV_STEPS) - uv.y;

    return length(v2(x, y));
}

fn water_color(border_dist: f32, height: f32) -> vec3<f32> {

    var c = rgb(99, 115, 229);
    let depth_modifier = 1.0 + height;

    return c ;
            // return vec4<f32>(1.0) * d;
        // }

        // c *= depth_modifier;

        // return vec4<f32>(c, 1.0);
}

fn ground_color(border_dist: f32, height: f32) -> vec3<f32> {
    return rgb(121, 115, 45);

}


fn merge_colors(water_color: vec3<f32>, ground_color: vec3<f32>, shore_dist: f32) -> vec3<f32> {
    let m = clamp(shore_dist, 0.0, 0.2);

    return mix(water_color, ground_color, m);
}

fn shore_dist(uv: vec2<f32>, h: f32) -> f32 {

    let s = surrounding_heights(uv);


    return 1.0;
}



@fragment
fn fragment(
    mesh: VertexOutput,
) -> @location(0) vec4<f32> {
    let height = h(mesh.uv);
    let border_dist = distance_to_closest_neighbor(mesh.uv);

    let water = water_color(border_dist, height);

    let ground = ground_color(border_dist, height);

    let c = merge_colors(water, ground, shore_dist(mesh.uv));

    return vec4<f32>(c, 1.0);
}
