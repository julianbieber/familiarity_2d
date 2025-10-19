use bevy::image::ImageSampler;
use bevy::math::prelude::*;
use bevy::{
    app::{Plugin, Update},
    asset::{Asset, Assets, Handle, RenderAssetUsages},
    ecs::{
        schedule::IntoScheduleConfigs,
        system::{Commands, Query, Res, ResMut},
    },
    image::Image,
    math::{Vec3, Vec4, primitives::Rectangle},
    mesh::{Mesh, Mesh2d},
    reflect::TypePath,
    render::render_resource::{AsBindGroup, Extent3d},
    sprite_render::{Material2d, Material2dPlugin, MeshMaterial2d},
    state::{condition::in_state, state::OnEnter},
    time::Time,
    transform::components::Transform,
};
use noiz::prelude::*;
use tracing::warn;

use crate::screens::Screen;

pub struct TerrainPlugin;
/// In this plugin we register the components to:
/// * generate the terrain
/// * render the terrain
/// * collide with the terrain
impl Plugin for TerrainPlugin {
    fn build(&self, app: &mut bevy::app::App) {
        app.add_systems(OnEnter(Screen::Gameplay), debug_setup)
            .add_systems(Update, update_time.run_if(in_state(Screen::Gameplay)))
            .add_plugins(Material2dPlugin::<TerrainMaterial>::default());
    }
}

fn debug_setup(
    mut commands: Commands,
    mut materials: ResMut<Assets<TerrainMaterial>>,
    mut meshes: ResMut<Assets<Mesh>>,
    mut images: ResMut<Assets<Image>>,
) {
    let mesh = meshes.add(Rectangle::new(4096.0, 4096.0));
    let terrain = generate_chunk();

    let height_tex = images.add(terrain.as_tex());
    let material = materials.add(TerrainMaterial {
        time: Vec4::ZERO,
        height_texture: height_tex,
    });

    commands.spawn((
        Mesh2d(mesh),
        MeshMaterial2d(material),
        Transform::from_translation(Vec3::ZERO),
    ));
    warn!("spawn terrain");
}

fn generate_chunk() -> TerrainChunk {
    let mut t = TerrainChunk::zero();
    let mut noise = Noise::<PerCell<OrthoGrid, Random<SNorm, f32>>>::default();
    noise.set_seed(123);
    noise.set_frequency(3.0);

    for y in 0..TerrainChunk::SQUARE {
        for x in 0..TerrainChunk::SQUARE {
            let world_pos = Vec2::new(x as f32, y as f32) * 0.12;
            let height = noise.sample(world_pos);
            t.set(x, y, height);
        }
    }

    t
}

pub struct TerrainChunk {
    heights: Vec<f32>,
}

impl TerrainChunk {
    const SQUARE: usize = 64 * 2;

    pub fn zero() -> TerrainChunk {
        let heights = vec![0.0; TerrainChunk::SQUARE * TerrainChunk::SQUARE];
        TerrainChunk { heights }
    }

    /// assumes x and y 0..SQUARE
    pub fn set(&mut self, x: usize, y: usize, h: f32) {
        assert!(x < TerrainChunk::SQUARE);
        assert!(y < TerrainChunk::SQUARE);

        let i = y * TerrainChunk::SQUARE + x;
        self.heights[i] = h;
    }

    #[allow(dead_code)]
    pub fn get(&self, x: usize, y: usize) -> f32 {
        assert!(x < TerrainChunk::SQUARE);
        assert!(y < TerrainChunk::SQUARE);

        let i = y * TerrainChunk::SQUARE + x;
        self.heights[i]
    }

    fn as_tex(&self) -> Image {
        let height_bytes = self.heights.iter().flat_map(|f| f.to_le_bytes()).collect();
        let mut i = Image::new(
            Extent3d {
                width: TerrainChunk::SQUARE as u32,
                height: TerrainChunk::SQUARE as u32,
                depth_or_array_layers: 1,
            },
            bevy::render::render_resource::TextureDimension::D2,
            height_bytes,
            bevy::render::render_resource::TextureFormat::R32Float,
            RenderAssetUsages::all(),
        );
        i.sampler = ImageSampler::nearest();

        i
    }
}

fn update_time(
    time: Res<Time>,
    mut terrain_materials: ResMut<Assets<TerrainMaterial>>,
    terrain_chunks: Query<&MeshMaterial2d<TerrainMaterial>>,
) {
    for c in terrain_chunks.iter() {
        if let Some(m) = terrain_materials.get_mut(c.0.id()) {
            m.time = Vec4::new(time.elapsed_secs(), 0.0, 0.0, 0.0);
        }
    }
}

/// Contains the render information for a single chunk
#[derive(Asset, TypePath, AsBindGroup, Clone)]
struct TerrainMaterial {
    #[uniform(0)]
    time: Vec4,
    #[texture(1)]
    #[sampler(2)]
    height_texture: Handle<Image>,
}

const FRAGMENT_SHADER_ASSET_PATH: &str = "shaders/terrain.wesl";

impl Material2d for TerrainMaterial {
    fn vertex_shader() -> bevy::shader::ShaderRef {
        bevy::shader::ShaderRef::Default
    }

    fn fragment_shader() -> bevy::shader::ShaderRef {
        FRAGMENT_SHADER_ASSET_PATH.into()
    }

    fn depth_bias(&self) -> f32 {
        0.0
    }

    fn alpha_mode(&self) -> bevy::sprite_render::AlphaMode2d {
        bevy::sprite_render::AlphaMode2d::Opaque
    }
}
