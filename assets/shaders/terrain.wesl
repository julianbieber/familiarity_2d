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

@fragment
fn fragment(
    mesh: VertexOutput,
) -> @location(0) vec4<f32> {
    let height = textureSample(height_texture, height_texture_sampler, mesh.uv).x;
    return vec4<f32>(height, 0.0, 0.0, 1.0);
}
