# TocaBoquita 🧸

Sandbox infantil para navegador, inspirado en Toca Boca / Sago Mini: **sin reglas, sin puntaje, sin perder**. Explorar, tocar y descubrir.

- **Motor:** Godot 4.4.x (GDScript, 2D).
- **Arquitectura:** data-driven con `Resource` (`.tres`). El contenido vive en datos editables desde el Inspector; el motor es genérico.
- **Objetivo:** web-first (export HTML5/WASM), escalable escena por escena.

> Estado actual: **Fases 1–6 completas**. Hub + 5 escenarios (Cocina, Dormitorio, Baño, Parque, Fiesta) conectados, navegación con fundido, persistencia, personaje con wardrobe, inventario portable entre escenas, partículas y audio. Todo con placeholders generados por código (formas pastel, sin PNGs externos).

## Cómo jugar (resumen)
1. Pantalla **"toca para empezar"** (desbloquea el audio del navegador).
2. **Hub**: toca una puerta para entrar a un escenario. Botón **🏠** para volver.
3. En cada escena: **toca** objetos para que cambien de estado (color/sonido/partículas), **arrastra** comida/juguetes a las zonas (ej. comida → olla, pato → tina).
4. **👕 Wardrobe**: cambia piel/pelo/ropa del personaje (se guarda).
5. **Mochila** (recuadro arriba a la izquierda): arrastra un objeto *portable* ahí para llevarlo; tócalo en la mochila para sacarlo en otra escena.
6. Todo se **autoguarda**; al recargar vuelves donde estabas.

---

## Cómo abrir el proyecto

1. Instala **Godot 4.4** (rama estable). Edición estándar (GDScript), no se necesita .NET.
2. Godot → *Import* → selecciona `project.godot` de esta carpeta.
3. La primera vez Godot genera `.godot/` (cache de imports). Es normal que tarde unos segundos.
4. Pulsa **F5** (Play). Verás el gate **"toca para empezar"**; al tocar entra la escena de prueba.

### Qué probar en la Fase 1
- **Toca la forma de la izquierda (lámpara):** cicla entre *apagada* (gris) y *encendida* (amarillo), con sonido y un pequeño "squash".
- **Arrastra el personaje de la derecha** con el dedo/mouse.
- **Botón mute** (arriba a la derecha).

---

## Cómo exportar a Web

1. *Project → Export…* → ya existe el preset **"Web"** (`export_presets.cfg`).
2. La primera vez, Godot pedirá instalar las **Export Templates** de la misma versión: *Editor → Manage Export Templates → Download and Install*.
3. *Export Project* → carpeta de salida (se sugiere `build/web/`), nombre `index.html`.
4. Genera: `index.html`, `index.js`, `index.wasm`, `index.pck`, `index.audio.worklet.js`, etc.

### Probar el build local (¡no abrir con `file://`!)
Debe servirse por HTTP. Desde la carpeta del build:

```bash
# Opción con Python
python3 -m http.server 8000
# Abre http://localhost:8000
```

> El proyecto está configurado en **single-thread** (`variant/thread_support=false`) para máxima compatibilidad de hosting. Si tu host soporta las cabeceras COOP/COEP, puedes activar multi-thread (ver abajo).

### Hosting
- **itch.io:** sube el zip del build y activa *"SharedArrayBuffer support"* en la página del juego.
- **Static host con cabeceras (Netlify, Vercel, etc.):** si activas multi-thread, sirve con:
  - `Cross-Origin-Opener-Policy: same-origin`
  - `Cross-Origin-Embedder-Policy: require_corp`
- **Audio en web:** los navegadores no reproducen audio hasta un gesto del usuario. Por eso existe el overlay **"toca para empezar"** (gate de audio) que desbloquea el `AudioServer`.

---

## Arquitectura (resumen)

Todo es **data-driven**: la lógica es genérica, el contenido son `Resource`.

| Capa | Archivos |
|------|----------|
| **Datos** (`Resource`) | `resources/StateDef.gd`, `ObjectData.gd`, `DropZoneDef.gd`, `CharacterLayer.gd`, `CharacterData.gd`, `SceneData.gd`, `PlacedObject.gd`, `SceneExit.gd` |
| **Core** (motor genérico) | `core/SceneEngine.gd`, `InteractiveObject.gd`, `StateMachine.gd`, `Draggable.gd`, `DropZone.gd`, `ParticleFactory.gd` |
| **Autoloads** (singletons) | `autoloads/GameState.gd`, `AudioManager.gd`, `SaveManager.gd`, `SceneRouter.gd` + `ParticleFactory` |
| **UI** | `ui/HUD.gd` (mute, hub, inventario), `ui/Wardrobe.gd` |
| **Entidades / escenas** | `entities/Character.gd`, `scenes/Boot.*` |
| **Contenido** | `data/objects/*.tres`, `data/scenes/*.tres`, `data/characters/*.tres` |
| **Placeholders** | `resources/Placeholder.gd` (formas + beep por código) |
| **Herramientas / tests** | `tools/build_data.gd` (genera el contenido), `tests/SmokeRunner.*` |

### Flujo de runtime
`Boot` (gate audio) → `SceneRouter.start()` → carga guardado → monta un `SceneEngine` con el `SceneData` de la escena → el engine instancia fondo, objetos, drop zones, salidas y el personaje. El HUD persiste entre escenas.

## Regenerar el contenido base
Los `.tres` de `data/` se generan con un script de autoría (y luego se editan en el Inspector):
```bash
godot --headless -s res://tools/build_data.gd
```

## Correr los tests
Smoke test + integración (navega las 6 escenas, valida persistencia y HUD):
```bash
godot --headless res://tests/SmokeRunner.tscn   # imprime [OK]/[FAIL], sale !=0 si falla
```

Principio: **ningún `if object.id == "..."` en el motor.** Para agregar contenido se editan/crean `.tres`.

---

## Cómo agregar contenido (la parte importante)

> En Fase 1 la escena de prueba se arma por código + un `.tres` de ejemplo (`data/objects/lampara.tres`). En la Fase 2 llega `SceneEngine`, que construye escenas enteras desde `SceneData .tres`. La forma de los datos ya está congelada.

### Agregar un OBJETO nuevo
1. En el editor: *FileSystem → New Resource → `ObjectData`*. Guárdalo en `res://data/objects/<id>.tres`.
2. Rellena `id`, `draggable`, `portable`.
3. En `states` agrega `StateDef`: por cada estado, su `texture` (o solo `modulate` para placeholder), `sound`, `animation`, y `next_state` (vacío = cicla).
4. Listo: al tocarlo ciclará por sus estados. Sin tocar GDScript.

### Agregar un PERSONAJE nuevo
1. *New Resource → `CharacterData`* en `res://data/characters/<id>.tres`.
2. Agrega `CharacterLayer` por capa (`slot`: piel/pelo/ropa/accesorio/expresion), con `texture` (o `modulate`) y `z_index`.
3. Las capas se apilan por `z_index`. El Wardrobe (Fase 4) las intercambiará por slot.

### Agregar una ESCENA nueva (Fase 2)
1. *New Resource → `SceneData`* en `res://data/scenes/<id>.tres`.
2. Pon `background` (o `background_color`), `ambient_music`.
3. En `placed_objects` agrega `PlacedObject` (un `ObjectData` + `position`).
4. En `exits` agrega `SceneExit` (zona + `target_scene_id`) para conectar con otras escenas.

---

## Reemplazar placeholders por arte final
Cada `StateDef` / `CharacterLayer` tiene un campo `texture: Texture2D`. Hoy está vacío y se usa una forma pastel por código tintada con `modulate`. Para usar arte final: asigna la `Texture2D` en el `.tres`. **No se toca lógica.**

---

## Roadmap
- [x] **Fase 1** — Esqueleto: proyecto, gate de audio, objeto que cicla estados, personaje arrastrable, export web.
- [x] **Fase 2** — Core data-driven: `SceneEngine`, `DropZone`; Cocina 100% desde Resources.
- [x] **Fase 3** — Multi-escena + Hub: `SceneRouter`, `GameState`, `SaveManager`.
- [x] **Fase 4** — Personaje + Wardrobe.
- [x] **Fase 5** — Inventario portable + audio + partículas (pooling).
- [x] **Fase 6** — Dormitorio, Baño, Parque, Fiesta. `ASSETS.md`.

### Ideas para seguir (solo crear Resources)
Playa, supermercado, doctor, granja… Crea un `SceneData` nuevo, sus `ObjectData`, y enlaza una puerta en `hub.tres`. Cero código.
