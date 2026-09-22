---
name: threejs-r3f
description: "Three.js and React Three Fiber — 3D scenes, shaders, postprocessing."
disable-model-invocation: true
---

# Three.js & R3F

`three` r185 · `@react-three/fiber` 9.x · `@react-three/drei` 10.x · `@react-three/postprocessing` 3.x.

**R3F 9 = React 19 only** (`>=19 <19.3`). React 18 → R3F 8 + drei 9. Default renderer: WebGL. WebGPU opt-in:

```tsx
import * as THREE from 'three/webgpu'
<Canvas gl={async (p) => { const r = new THREE.WebGPURenderer(p as any); await r.init(); return r }} />
```

## When to Use

| Need | Tool |
|---|---|
| Full 3D scene (React) | R3F + drei |
| Vanilla 3D | Three.js direct |
| Simple 3D UI transforms | CSS `transform3d` |
| 2D particles / generative | Canvas 2D |
| Shader-only (no scene graph) | Raw WebGL / ShaderMaterial |

## Scene Setup

```tsx
import { Canvas } from '@react-three/fiber'
import { Environment, OrbitControls } from '@react-three/drei'
import { Suspense } from 'react'

<Canvas camera={{ position: [0, 2, 5], fov: 45 }} dpr={[1, 2]} gl={{ antialias: true, alpha: false, powerPreference: 'high-performance' }}>
  <Suspense fallback={null}>
    <Environment preset="studio" />
    <OrbitControls makeDefault enableDamping dampingFactor={0.05} />
    <Scene />
  </Suspense>
</Canvas>
```

- Always `<Suspense>` for loaders
- `dpr={[1, 2]}` clamps Retina
- `frameloop="demand"` + `invalidate()` for static scenes
- Isolate Canvas from parent state — re-renders remount scene

## Hooks

| Hook | Use | Gotcha |
|---|---|---|
| `useFrame((state, delta) => {})` | Per-frame logic | Never setState |
| `useThree()` | gl, scene, camera, size, viewport | Destructure sparingly |
| `useLoader(Loader, url)` | Load resources | Needs Suspense |
| `useGraph(scene)` | Extract nodes/materials from GLTF | After useGLTF |

```tsx
useFrame((state, delta) => {
  meshRef.current.rotation.y += delta * 0.5
  material.uniforms.uTime.value = state.clock.elapsedTime
})
```

## Drei Essentials

| Component | Use |
|---|---|
| `Environment` | HDRI — `studio`, `sunset`, `city`, `forest`, `dawn` |
| `Float` | Idle float animation |
| `useGLTF` / `.preload()` | Load .glb/.gltf |
| `useTexture` / `.preload()` | Textures with Suspense |
| `MeshTransmissionMaterial` | Glass/crystal refraction |
| `PresentationControls` | Drag-to-rotate product view |
| `Center`, `Detailed` | Auto-center, LOD by distance |
| `Instances` | Declarative instancing |
| `ContactShadows` | Soft ground shadow without shadow maps |
| `AdaptiveDpr`, `AdaptiveEvents` | Drop quality while camera moves |
| `Bvh` | Fast raycasting on heavy scenes |

## Lighting Rigs

```tsx
// Studio HDRI (easiest)
<Environment preset="studio" background={false} /><ambientLight intensity={0.2} />

// Studio directional
<ambientLight intensity={0.4} />
<directionalLight position={[5,8,3]} intensity={1.2} castShadow shadow-mapSize={2048} />
<directionalLight position={[-3,4,-5]} intensity={0.3} />

// Outdoor
<Environment preset="sunset" background />
<directionalLight position={[10,15,5]} intensity={2} castShadow color="#ffeedd" />
<hemisphereLight args={['#87CEEB', '#362907', 0.3]} />

// Dramatic
<color attach="background" args={['#000000']} />
<fog attach="fog" args={['#000000', 5, 20]} />
<spotLight position={[3,8,2]} angle={0.3} penumbra={0.8} intensity={3} castShadow color="#ff6644" />
```

## Loading Models

```tsx
function Model(props) {
  const { nodes, materials } = useGLTF('/model.glb')
  return (
    <group {...props} dispose={null}>
      <mesh geometry={nodes.Body.geometry} material={materials.skin} castShadow />
    </group>
  )
}
useGLTF.preload('/model.glb')
// Draco: useGLTF('/model-draco.glb', true)
```

```tsx
const [colorMap, normalMap, roughnessMap] = useTexture(['/color.jpg', '/normal.jpg', '/roughness.jpg'])
<meshStandardMaterial map={colorMap} normalMap={normalMap} roughnessMap={roughnessMap} />
useTexture.preload(['/color.jpg', '/normal.jpg', '/roughness.jpg'])
```

Tip: [gltf.pmnd.rs](https://gltf.pmnd.rs/) for typed R3F components.

## Responsive Canvas

```tsx
// Parent needs explicit dimensions
<div style={{ width: '100%', height: '100vh' }}><Canvas><Scene /></Canvas></div>

function ResponsiveObject() {
  const { viewport } = useThree() // world units at z=0
  return <mesh scale={viewport.width > 6 ? 1 : 0.6}><boxGeometry /><meshStandardMaterial /></mesh>
}

<PerformanceMonitor onIncline={() => setDpr(2)} onDecline={() => setDpr(1)}><Scene /></PerformanceMonitor>
```

## Camera

```tsx
// Perspective: fov 35-45 cinematic, 60-75 immersive, 20-30 telephoto
<Canvas camera={{ position: [0, 2, 5], fov: 45, near: 0.1, far: 100 }} />
// Orthographic (isometric): <Canvas orthographic camera={{ position: [0,5,10], zoom: 50 }} />

function CameraRig({ target }: { target: [number, number, number] }) {
  const _target = useMemo(() => new THREE.Vector3(), [])
  const _pos = useMemo(() => new THREE.Vector3(), [])
  useFrame((state, delta) => {
    _target.set(...target)
    state.camera.position.lerp(_pos.set(target[0], target[1]+2, target[2]+5), delta * 2)
    state.camera.lookAt(_target)
  })
  return null
}
```

## Shadows

```tsx
<Canvas shadows>
  <directionalLight castShadow shadow-mapSize={2048} />
  <mesh castShadow /><mesh receiveShadow rotation-x={-Math.PI/2} position-y={-1}>
    <planeGeometry args={[20,20]} /><shadowMaterial opacity={0.3} />
  </mesh>
  <ContactShadows position={[0,-1,0]} opacity={0.4} scale={10} blur={2} far={4} />
</Canvas>
```

## Controls

```tsx
<OrbitControls makeDefault enableDamping minPolarAngle={0} maxPolarAngle={Math.PI/2} />
<PresentationControls global snap speed={1.5} polar={[-Math.PI/4, Math.PI/4]}><Model /></PresentationControls>
<MapControls makeDefault enableRotate={false} />
```

## Postprocessing

```tsx
import { EffectComposer, Bloom, ChromaticAberration } from '@react-three/postprocessing'

<EffectComposer>
  <Bloom luminanceThreshold={1} luminanceSmoothing={0.4} intensity={0.6} />
  <ChromaticAberration offset={[0.002, 0.002]} />
</EffectComposer>
```

Bloom: emissive/color > 1.0 to glow. Order matters. Single merged pass.

## Shaders

```tsx
const uniforms = useMemo(() => ({ uTime: { value: 0 }, uColor: { value: new THREE.Color('#ff6600') } }), [])
useFrame((state) => { materialRef.current.uniforms.uTime.value = state.clock.elapsedTime })

// drei shaderMaterial helper
const WaveMaterial = shaderMaterial({ uTime: 0, uAmplitude: 0.3 }, vertexShader, fragmentShader)
extend({ WaveMaterial }) // augment ThreeElements for R3F v9
// <waveMaterial uTime={0} />
```

**Patterns:**

| Pattern | Use |
|---|---|
| Simplex + FBM | Terrain, clouds, organic textures |
| Fresnel | Glass, shields — `pow(1.0 - dot(normal, viewDir), power)` |
| UV scroll | Flowing water — `uv.y += uTime * 0.1; uv = fract(uv)` |
| UV distort | Heat haze — sine offset on uv.x/y |
| Noise displacement | Vertex shader — `position + normal * snoise(...) * amplitude` |
| Gradient map | Toon/heat — remap NdotL through color ramp |

```tsx
// Animated blob — noise displacement + fresnel
function Blob() {
  const ref = useRef<THREE.ShaderMaterial>(null!)
  const uniforms = useMemo(() => ({
    uTime: { value: 0 }, uAmplitude: { value: 0.3 },
    uColorA: { value: new THREE.Color('#1a0533') }, uColorB: { value: new THREE.Color('#ff6600') },
    uFresnelPower: { value: 3.0 },
  }), [])
  useFrame((s) => { ref.current.uniforms.uTime.value = s.clock.elapsedTime })
  return (
    <mesh>
      <icosahedronGeometry args={[1.5, 64]} />
      <shaderMaterial ref={ref} vertexShader={vert} fragmentShader={frag} uniforms={uniforms} />
    </mesh>
  )
}
```

**Uniforms:** always `useMemo`. Update in `useFrame` via ref, not props. Use `/* glsl */` tag.

## Performance

| Pattern | When |
|---|---|
| `<Instances>` / `InstancedMesh` | 100+ identical meshes |
| `<Detailed distances={[0,50,100]}>` | LOD |
| `useGLTF` + Draco | 70-90% smaller models |
| `useTexture` + KTX2 | 1/4 VRAM textures |
| `frameloop="demand"` | Static scenes |
| `dispose={null}` on `<primitive>` | Reuse shared geometry |

**Targets:** < 100 draw calls, < 1M triangles, 60fps mid-range GPU. Monitor with `stats-gl` or `r3f-perf`.

## DO NOT

| BAD | GOOD | Why |
|---|---|---|
| `setState` in `useFrame` | Mutate ref directly | 60 re-renders/s |
| `new Vector3()` per frame | `useMemo(() => new Vector3())` + reuse | GC stutter |
| Manual texture without dispose | JSX primitives auto-dispose; cleanup in `useEffect` | VRAM leak |
| State in Canvas parent | Isolate `<SceneCanvas />` | Remount + flash |
| Loaders without Suspense | Wrap in `<Suspense>` | Throws promise |
| Bloom threshold 0 on everything | `luminanceThreshold={1}` + emissive > 1 | Whole scene glows |
| Shader uniforms recreated each render | `useMemo` uniforms | New objects every frame |
| Low-poly geometry + vertex displacement | Subdivide (`128` segments) | No visible displacement |
