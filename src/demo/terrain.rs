use bevy::{
    app::Plugin,
    asset::{Asset, Assets},
    ecs::system::{Commands, ResMut},
    math::{Vec3, Vec4, primitives::Rectangle},
    mesh::{Mesh, Mesh2d},
    reflect::TypePath,
    render::render_resource::AsBindGroup,
    sprite_render::{Material2d, Material2dPlugin, MeshMaterial2d},
    state::state::OnEnter,
    transform::components::Transform,
};
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
            .add_plugins(Material2dPlugin::<TerrainMaterial>::default());
    }
}

fn debug_setup(
    mut commands: Commands,
    mut materials: ResMut<Assets<TerrainMaterial>>,
    mut meshes: ResMut<Assets<Mesh>>,
) {
    let mesh = meshes.add(Rectangle::new(100.0, 100.0));
    let material = materials.add(TerrainMaterial { time: Vec4::ZERO });

    commands.spawn((
        Mesh2d(mesh),
        MeshMaterial2d(material),
        Transform::from_translation(Vec3::ZERO),
    ));
    warn!("spawn terrain");
}

#[derive(Asset, TypePath, AsBindGroup, Clone)]
struct TerrainMaterial {
    #[uniform(0)]
    time: Vec4,
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
