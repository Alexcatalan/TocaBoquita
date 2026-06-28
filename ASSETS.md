# ASSETS — arte necesario (placeholders → arte final)

Hoy **todo es arte procedural generado por código** (`resources/Art.gd`): cada objeto se dibuja como una figura reconocible (refri, torta, pato, árbol…) con antialias y volumen suave, a partir de `shape` + `modulate` del estado. El personaje también es procedural por capas. El juego es 100% jugable así, sin un solo PNG.

**Para pasar a arte final no se toca lógica:** cada `StateDef` y cada `CharacterLayer` tiene un campo `texture: Texture2D`. Si `texture` está vacío, se dibuja `shape` con Art; si asignas una `Texture2D` en el `.tres` (Inspector), esa textura tiene prioridad y Art deja de usarse para ese estado.

## Convenciones
- **Estilo:** cartoon moderno y amable; formas suaves, colores planos pastel, volumen simple.
- **Formato:** PNG con transparencia. Filtro de textura nearest/lineal ya configurado.
- **Tamaño base de objetos:** ~160–220 px de lado (la hitbox se ajusta sola al tamaño del sprite, con mínimo generoso para dedos).
- **Pivote:** centrado (los `Sprite2D` se centran por defecto).
- **Paleta pastel de referencia (la usa `tools/build_data.gd`):**
  - crema `#FAF0DC`, lavanda `#DBD1F2`, menta `#E0F5E6`
  - azul `#80B3FF`, celeste `#B3D9FF`, naranja `#FF9E52`
  - verde `#9EDB9E`, amarillo `#FFEB80`, rojo `#F27272`, rosa `#FFB3CC`, café `#CC9966`

## Inventario de arte por escena
Cada objeto necesita **una textura por estado**. Estados actuales (placeholder = color):

### Personaje (`data/characters/nina.tres`)
| Capa (slot) | Notas |
|---|---|
| ropa | cuerpo/vestido, z=0 |
| piel | cabeza/cara, z=1 |
| pelo | z=2 |
| (futuro) accesorio, expresion | el Wardrobe ya soporta slots extra |

### Cocina
| Objeto | Estados |
|---|---|
| refri | cerrado, abierto |
| estufa | apagada, encendida |
| olla | vacia, llena |
| grifo | cerrado, abierto |
| ventana | dia, noche |
| manzana / pan / zanahoria | (1 estado, arrastrables) |

### Dormitorio
| Objeto | Estados |
|---|---|
| cama | hecha, dormido |
| lampara | apagada, encendida |
| closet | cerrado, abierto |
| reloj | tic, tac |
| oso / bloque / pelota_dorm | (arrastrables) |
| ventana | dia, noche |

### Baño
| Objeto | Estados |
|---|---|
| tina | vacia, agua, burbujas |
| espejo | normal, empanado |
| grifo_bano | cerrado, abierto |
| toalla | colgada, caida |
| pasta / cepillo / pato | (arrastrables) |

### Parque
| Objeto | Estados |
|---|---|
| columpio | quieto, meciendose |
| tobogan | vacio, usandose |
| charco | quieto, salpicando |
| arbol | verano, otono |
| flor | cerrada, abierta |
| mascota / pelota | (arrastrables) |

### Fiesta
| Objeto | Estados |
|---|---|
| torta | apagada, velas |
| globo1 / globo2 | inflado, estallado |
| regalo1 / regalo2 | cerrado, abierto |
| canon | listo, disparado |
| gorro | (arrastrable) |

## Fondos
Cada `SceneData` tiene `background: Texture2D` (hoy se usa `background_color`). Un fondo de **1280×720** (o mayor, se recorta con KEEP_ASPECT_COVERED) por escena: hub, cocina, dormitorio, bano, parque, fiesta.

## Audio (opcional)
- `ambient_music` por escena (`SceneData`): loop suave por ambiente.
- `sound` por `StateDef` / `DropZoneDef`: SFX corto. Hoy se usan beeps sintéticos.

## Partículas
Ya implementadas por código (`ParticleFactory`): `corazones`, `burbujas`, `estrellas`, `confeti`. Se referencian por id en `StateDef.particle` / `DropZoneDef.particle`. Para arte final, se puede dar una textura al emisor en `ParticleFactory.gd`.
