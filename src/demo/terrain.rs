use bevy::{
    app::Plugin,
    asset::{Asset, Assets},
    ecs::system::{Commands, ResMut},
    math::{Vec4, primitives::Rectangle},
    mesh::{Mesh, Mesh2d},
    pbr::{Material, MaterialPlugin},
    reflect::TypePath,
    render::render_resource::AsBindGroup,
    sprite_render::{Material2d, MeshMaterial2d},
    state::state::OnEnter,
};

use crate::screens::Screen;

pub struct TerrainPlugin;
/// In this plugin we register the components to:
/// * generate the terrain
/// * render the terrain
/// * collide with the terrain
impl Plugin for TerrainPlugin {
    fn build(&self, app: &mut bevy::app::App) {
        app.add_systems(OnEnter(Screen::Gameplay), debug_setup)
            .add_plugins(MaterialPlugin::<TerrainMaterial>::default());
    }
}

fn debug_setup(
    mut commands: Commands,
    mut materials: ResMut<Assets<TerrainMaterial>>,
    mut meshes: ResMut<Assets<Mesh>>,
) {
    let mesh = meshes.add(Rectangle::new(100.0, 100.0));
    let material = materials.add(TerrainMaterial { time: Vec4::ZERO });

    commands.spawn((Mesh2d(mesh), MeshMaterial2d(material)));
}

#[derive(Asset, TypePath, AsBindGroup, Clone)]
struct TerrainMaterial {
    #[uniform(0)]
    time: Vec4,
}

const FRAGMENT_SHADER_ASSET_PATH: &str = "shaders/terrain.wesl";

impl Material for TerrainMaterial {}

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
