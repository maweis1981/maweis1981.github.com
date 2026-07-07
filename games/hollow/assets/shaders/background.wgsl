// Animated background for hollowlullaby — a flowing aurora/nebula made from
// domain-warped fractal noise (the classic Inigo Quilez technique). Drawn on a
// full-screen quad behind the game (custom Bevy `Material2d`). Loaded as an
// asset, so it hot-reloads on desktop and is bundled on iOS (WGSL -> Metal).

#import bevy_sprite::mesh2d_vertex_output::VertexOutput

// Material uniform (bind group index filled in by Bevy's preprocessor).
// data = (time_seconds, aspect_ratio, unused, unused)
@group(#{MATERIAL_BIND_GROUP}) @binding(0) var<uniform> data: vec4<f32>;

// Cheap hash (Dave Hoskins, no `sin` — avoids banding and is fast enough to run
// fullscreen at high refresh on device).
fn hash2(p: vec2<f32>) -> f32 {
    var p3 = fract(vec3<f32>(p.x, p.y, p.x) * 0.1031);
    p3 = p3 + dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// Value noise with a smootherstep interpolant.
fn noise(p: vec2<f32>) -> f32 {
    let i = floor(p);
    let f = fract(p);
    let u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    let a = hash2(i + vec2<f32>(0.0, 0.0));
    let b = hash2(i + vec2<f32>(1.0, 0.0));
    let c = hash2(i + vec2<f32>(0.0, 1.0));
    let d = hash2(i + vec2<f32>(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Fractal Brownian motion: 4 octaves, rotated each step to break up axis alignment.
fn fbm(p0: vec2<f32>) -> f32 {
    var p = p0;
    var value = 0.0;
    var amp = 0.5;
    let m = mat2x2<f32>(1.6, 1.2, -1.2, 1.6);
    for (var i: i32 = 0; i < 4; i = i + 1) {
        value = value + amp * noise(p);
        p = m * p;
        amp = amp * 0.5;
    }
    return value;
}

@fragment
fn fragment(mesh: VertexOutput) -> @location(0) vec4<f32> {
    let t = data.x;
    let aspect = max(data.y, 0.0001);
    let energy = clamp(data.z, 0.0, 1.0);   // gameplay impulse from ScreenShake
    let theme = clamp(data.w, 0.0, 1.0);    // 0 = cool aurora, 1 = warm garden

    // Aspect-corrected, centered coordinates so the noise isn't stretched.
    var p = vec2<f32>((mesh.uv.x - 0.5) * aspect, mesh.uv.y - 0.5) * 3.0;

    // The flow speeds up when the game is energized (a hit / score just landed).
    let flow = t * (1.0 + energy * 3.0);

    // One level of domain warping — samples the field through an offset built
    // from the field itself, which gives the soft flowing "aurora" motion.
    let q = vec2<f32>(
        fbm(p + vec2<f32>(0.0, flow * 0.06)),
        fbm(p + vec2<f32>(5.2, 1.3) - flow * 0.05),
    );
    let f = fbm(p + 4.0 * q + vec2<f32>(1.7, 9.2));

    // Two palettes, chosen by theme: the default cool aurora
    // (navy -> indigo -> teal -> cyan) and a warm "enchanted garden"
    // (deep moss -> leaf green -> meadow -> soft floral highlight).
    let c_base = mix(vec3<f32>(0.02, 0.03, 0.07), vec3<f32>(0.03, 0.07, 0.05), theme);
    let c_indigo = mix(vec3<f32>(0.07, 0.06, 0.22), vec3<f32>(0.09, 0.19, 0.10), theme);
    let c_teal = mix(vec3<f32>(0.04, 0.24, 0.36), vec3<f32>(0.18, 0.44, 0.22), theme);
    let c_cyan = mix(vec3<f32>(0.35, 0.62, 0.72), vec3<f32>(0.74, 0.86, 0.46), theme);

    var col = mix(c_base, c_indigo, clamp(f * f * 2.2, 0.0, 1.0));
    col = mix(col, c_teal, clamp(length(q) * 0.9, 0.0, 1.0));
    col = mix(col, c_cyan, clamp(q.x * q.x * 1.6, 0.0, 1.0));

    // Slow overall "breathing" so it never looks static.
    col = col * (0.9 + 0.1 * sin(t * 0.4));

    // Gameplay reactivity: brighten the whole field and bloom a warm cyan-white
    // into the brightest aurora bands on impact, so the background pulses with play.
    col = col * (1.0 + energy * 0.7);
    let flash = vec3<f32>(0.30, 0.55, 0.75);
    col = col + flash * energy * smoothstep(0.35, 0.95, f);

    // Cozy drifting motes (pollen / fireflies) that slowly rise and twinkle —
    // warmer and denser in the garden theme, a faint sparkle in the cool one.
    let mv = vec2<f32>((mesh.uv.x - 0.5) * aspect, mesh.uv.y - 0.5);
    var motes = 0.0;
    for (var i: i32 = 0; i < 3; i = i + 1) {
        let fi = f32(i);
        let scale = 7.0 + fi * 4.0;
        let q = mv * scale + vec2<f32>(0.0, t * (0.04 + fi * 0.015));
        let id = floor(q);
        let fq = fract(q);
        let ctr = vec2<f32>(0.5, 0.5) + 0.34 * vec2<f32>(hash2(id) - 0.5, hash2(id + 3.7) - 0.5);
        let dd = length(fq - ctr);
        let tw = 0.5 + 0.5 * sin(t * 1.5 + hash2(id) * 6.28);
        motes = motes + smoothstep(0.10, 0.0, dd) * tw;
    }
    col = col + vec3<f32>(0.95, 0.88, 0.55) * motes * (0.10 + 0.30 * theme);

    // Soft vignette to focus the play area.
    let d = distance(mesh.uv, vec2<f32>(0.5, 0.5));
    col = col * (1.0 - smoothstep(0.5, 1.05, d) * 0.55);

    return vec4<f32>(col, 1.0);
}
