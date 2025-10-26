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

const UV_STEPS = 8.0;

fn rgb(r: i32, g: i32, b: i32) -> vec3<f32> {
    return vec3<f32>(f32(r) / 255.0, f32(g) / 255.0, f32(b) / 255.0);
}

fn quantize(v: f32, n: f32) -> f32 {
    return (floor(v * n) + 0.5) / n;
}

fn quantize_min(v: f32, n: f32) -> f32 {
    return (floor(v * n)) / n;
}
fn quantize_max(v: f32, n: f32) -> f32 {
    return (ceil(v * n)) / n;
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

// this should interpolate between the closest 4 pixels
fn bilinear_height(uv: vec2<f32>) -> f32 {
    let qx = quantize(uv.x, UV_STEPS);
    let qy = quantize(uv.y, UV_STEPS);

    var fraction_x = fract((uv.x * UV_STEPS)) * 0.5;
    var fraction_y = fract((uv.y * UV_STEPS)) * 0.5;
    var surrounding_x: f32;
    if (uv.x * UV_STEPS) % 1.0 < 0.5 {
        surrounding_x = qx - 1.0/UV_STEPS;
        fraction_x += 0.5;
    } else {
        surrounding_x = qx + 1.0/UV_STEPS;
    }

    var surrounding_y: f32;
    if (uv.y * UV_STEPS) % 1.0 < 0.5 {
        surrounding_y = quantize(uv.y - 1.0 / UV_STEPS, UV_STEPS);
    } else {
        surrounding_y = quantize(uv.y + 1.0 / UV_STEPS, UV_STEPS);
        fraction_y += 0.5;
    }

    // return surrounding_x + surrounding_y;

    let my_h = h(v2(qx, qy));

    let surrounding_hx = h(v2(surrounding_x, qy));
    let surrounding_hy = h(v2(qx, surrounding_y));
    let surrounding_h = h(v2(surrounding_x, surrounding_y));


    let interpolated_x = mix(surrounding_h, surrounding_hx, fraction_x);
    let interpolated_y = mix(my_h, surrounding_hy, fraction_y);

    let interpolated_final = mix(interpolated_x, interpolated_y, fraction_x);


    return interpolated_x;
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
    // How to decide on a color?
    // I have the bilinear height and the block height
    // The block height decides the main type of terrain, maybe later combined with a separate texture for biome data.
    // For merging the blocks, I can take a look at the block height of the closest neighboring block.
    // Additionally I need the distance to the closest block for the specific pixel.
    // So I need a function similar to the bilinear_height, returning height and distance.
    // I can use the bilinear height to guide the transition
    let block_height = h(mesh.uv);
    let border_dist = distance_to_closest_neighbor(mesh.uv);

    let water = water_color(border_dist, block_height);

    let ground = ground_color(border_dist, block_height);

    // let c = merge_colors(water, ground, );
    let c: vec3<f32> = vec3<f32>(0.2, .05, 0.1) * abs(bilinear_height(mesh.uv));
    // let c: vec3<f32> = vec3<f32>(0.2, .05, 0.1) * block_height;

    return vec4<f32>(c, 1.0);
}
