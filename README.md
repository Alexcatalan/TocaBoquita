# TocaBoquita 🧸

Sandbox infantil para navegador, inspirado en Toca Boca / Sago Mini: **sin reglas, sin puntaje, sin perder**. Explorar, tocar y descubrir.

- **Motor:** Godot 4.4.x (GDScript, 2D).
- **Arquitectura:** data-driven con `Resource` (`.tres`). El contenido vive en datos editables desde el Inspector; el motor es genérico.
- **Objetivo:** web-first (export HTML5/WASM), escalable escena por escena.

> Estado actual: **Fase 1 — Esqueleto**. Proyecto configurado, gate de audio web, escena de prueba con un objeto que cicla estados al tocarlo y un personaje arrastrable. Todo con placeholders generados por código (formas pastel, sin PNGs externos).

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
| **Datos** (`Resource`) | `resources/StateDef.gd`, `ObjectData.gd`, `CharacterLayer.gd`, `CharacterData.gd`, `SceneData.gd`, `PlacedObject.gd`, `SceneExit.gd` |
| **Core** (motor genérico) | `core/InteractiveObject.gd`, `StateMachine.gd`, `Draggable.gd` |
| **Autoloads** (singletons) | `autoloads/AudioManager.gd` |
| **Entidades / escenas** | `entities/Character.gd`, `scenes/Boot.*`, `scenes/TestScene.*` |
| **Contenido** | `data/objects/*.tres` (ej. `lampara.tres`) |
| **Placeholders** | `resources/Placeholder.gd` (formas + beep por código) |

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
- [ ] **Fase 2** — Core data-driven: `SceneEngine`, `DropZone`; Cocina 100% desde Resources.
- [ ] **Fase 3** — Multi-escena + Hub: `SceneRouter`, `GameState`, `SaveManager`.
- [ ] **Fase 4** — Personaje + Wardrobe.
- [ ] **Fase 5** — Inventario portable + audio + partículas (pooling).
- [ ] **Fase 6** — Dormitorio, Baño, Parque, Fiesta. `ASSETS.md`.
