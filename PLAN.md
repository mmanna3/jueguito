# PLAN.md — RPG 2D estilo Pokémon (Godot) — Etapa 1

## Estado: implementado y probado (2026-09-15)

Se implementó todo lo descripto abajo. Diferencias respecto al plan original:

- **Input:** en vez de configurar acciones en el Input Map de
  `project.godot` (que requiere serializar objetos `InputEventKey` a mano,
  riesgoso de escribir sin el editor abierto), `Player.gd` lee directamente
  `Input.is_key_pressed(KEY_UP/KEY_W/...)` para flechas y WASD. Funciona
  igual para el usuario; si más adelante preferís remapear teclas desde el
  editor (Project Settings → Input Map), es fácil migrar a acciones con
  nombre.
- **Mapa:** en vez de pintarlo a mano en el editor, se genera por código en
  `Town.gd` (`_build_map()`) a partir de coordenadas simples. Esto deja el
  diseño del pueblo fácil de ajustar (son unos loops + un par de llamadas a
  `_set_block`).

**Probado de verdad con Godot 4.7.2 instalado** (no solo a ojo):

- Import headless (`godot --headless --import`) sin errores en assets ni
  escenas.
- Un script de validación (`SceneTree` custom) instanció `Town.tscn` y
  confirmó por código: las 150 celdas del tilemap tienen el tile esperado
  en cada posición clave (borde, camino, pared de casa, agua, pasto), el
  jugador arranca en el camino, los 3 NPCs tienen su sprite asignado
  correctamente, el jugador queda bloqueado al intentar cruzar el borde de
  árboles, y queda bloqueado al intentar pisar a un NPC.
- Se generó una captura de pantalla real (`--rendering-driver opengl3` +
  `Image.save_png`) para confirmar visualmente el resultado.

**Bug encontrado y corregido durante la prueba:** `project.godot` tenía la
resolución base del viewport puesta en 960x540 (el tamaño de ventana
deseado) en vez de una resolución base chica escalada. Con tiles de 16px
eso hacía que el pueblo se viera diminuto en una esquina de la ventana. Se
corrigió separando `window/size/viewport_width|height` (320x180, la
resolución "lógica" con la que trabaja la cámara) de
`window/size/window_width|height_override` (960x540, el tamaño real de la
ventana) — así el `canvas_items` stretch escala todo 3x con filtro Nearest,
manteniendo el pixel art nítido.

Ver `assets/CREDITS.md` para las coordenadas exactas de cada tile/personaje
usado, por si querés reemplazarlos.



## Objetivo de esta etapa

Sentar la base técnica del juego: un pueblo chico renderizado con tiles, un
personaje que se mueve por el mapa con el teclado (movimiento tile a tile,
como los Pokémon de GBA) y un puñado de NPCs estáticos con los que **todavía
no se puede hablar** (solo bloquean el paso, como preparación para el futuro
sistema de diálogo).

**Explícitamente fuera de esta etapa:** sistema de combate, diálogos/UI de
texto, sonido, guardado de partida, cambio de mapas/transiciones, animación
avanzada de personajes. Todo eso queda para etapas siguientes.

## Decisiones ya tomadas

- **Motor:** Godot 4.x (GDScript).
- **Movimiento:** grid-based — cada pulsación mueve al jugador una celda
  completa (interpolado con `Tween` para que no sea instantáneo/brusco).
- **Tamaño del mapa:** chico, ~15x10 tiles.
- **NPCs:** 2-3, estáticos, con colisión (no se pueden atravesar).
- **Assets:** packs reales, gratuitos y de licencia CC0 de Kenney.nl.

## Assets a usar

Ambos son de [Kenney.nl](https://kenney.nl), licencia **CC0** (dominio
público, uso libre sin atribución obligatoria, aunque mencionarlo es un
lindo gesto). Formato 16x16 px, estilo top-down, encajan bien entre sí.

- **Tileset del mapa:** [Kenney — Roguelike/RPG Pack](https://kenney.nl/assets/roguelike-rpg-pack)
  Incluye pasto, caminos, agua, árboles, casas, cercos, etc. Trae un spritesheet
  único (`roguelikeSheet_transparent.png`) más un XML/JSON con la posición de
  cada tile, ideal para armar un `TileSet` de Godot.
- **Personajes (jugador y NPCs):** [Kenney — Roguelike Characters](https://kenney.nl/assets/roguelike-characters)
  Trae decenas de personajitos 16x16 con variantes de color, perfectos para
  diferenciar al jugador de los NPCs.

Cómo los voy a incorporar al ejecutar el plan:
1. Descargar los dos `.zip` desde Kenney.nl.
2. Copiar los spritesheets a `assets/tileset/` y `assets/characters/`.
3. Armar un `TileSet` de Godot 4 (`res://assets/tileset/town_tileset.tres`)
   recortando el spritesheet en tiles de 16x16, marcando colisión en los que
   correspondan (árboles, agua, paredes de casas).
4. Recortar del sheet de personajes 2-3 frames sueltos para el jugador y 2-3
   distintos para los NPCs (import como `AtlasTexture` o spritesheet con
   `AnimatedSprite2D`, aunque en esta etapa no haga falta animación de
   caminata todavía — puede ser un solo frame estático por dirección).

> Si más adelante preferís reemplazar estos assets por otros (por ejemplo un
> pack más "estilo Pokémon" pago o con otra licencia), simplemente se
> reemplazan los archivos en `assets/tileset/` y `assets/characters/` y se
> re-arma el `TileSet`/los `AtlasTexture` — el resto del código (movimiento,
> colisión, cámara) no depende del arte específico.

## Estructura de carpetas propuesta

```
jueguito/
├── project.godot
├── assets/
│   ├── tileset/
│   │   └── roguelikeSheet_transparent.png
│   └── characters/
│       └── roguelikeChar_transparent.png
├── scenes/
│   ├── Town.tscn          # escena principal: TileMap + Player + NPCs + Camera
│   ├── Player.tscn
│   └── NPC.tscn
└── scripts/
    ├── Player.gd
    └── NPC.gd
```

## Configuración del proyecto

- **Pixel art:** en Project Settings →
  - `rendering/textures/canvas_textures/default_texture_filter` = *Nearest*
    (evita el blur típico al escalar sprites chicos).
  - `display/window/stretch/mode` = *canvas_items*, `aspect` = *keep*, con
    una resolución base baja (ej. 320x180) escalada a una ventana más grande
    (ej. 960x540, factor x3) para que se vea nítido y grande.
- **Input Map:** 4 acciones nuevas, cada una con flecha **y** WASD:
  - `move_up` → Flecha arriba / W
  - `move_down` → Flecha abajo / S
  - `move_left` → Flecha izquierda / A
  - `move_right` → Flecha derecha / D

## Mapa (`Town.tscn`)

- Un `TileMapLayer` (nodo nuevo de Godot 4.3+; si usamos una versión anterior
  de Godot 4, un `TileMap` clásico) llamado `Ground` con el tileset de Kenney.
- Capa de colisión: los tiles de "obstáculo" (árboles, agua, paredes) tienen
  un `PhysicsLayer` con polígono de colisión configurado en el `TileSet`, así
  el jugador no puede caminar sobre ellos sin necesitar nodos extra por tile.
- Diseño del pueblito (15x10 tiles): un borde de árboles/cercos rodeando el
  mapa (para que el jugador no se salga), 2-3 caminos de tierra, 2 casas
  simples (representadas con tiles de pared, no interiores), pasto de fondo.
  Lo armo directamente en el editor de Godot pintando con el `TileMapLayer`.

## Jugador (`Player.tscn` + `Player.gd`)

- Nodo raíz `CharacterBody2D` (aunque no usemos físicas de "empuje", nos da
  colisión sólida contra el TileMap y los NPCs de forma simple) con:
  - `Sprite2D` (o `AnimatedSprite2D` si dejamos preparado un frame por
    dirección) con el personaje de Kenney.
  - `CollisionShape2D` (rectángulo ~14x14, un poco menor al tile para que no
    se enganche en las esquinas).
- **Lógica de movimiento (`Player.gd`)**, grid-based:
  1. En `_unhandled_input` (o `_process` chequeando `Input.is_action_just_pressed`)
     detecto una de las 4 direcciones.
  2. Si el jugador ya está en medio de un movimiento (`is_moving = true`), se
     ignora el input (evita moverse "a mitad de tile").
  3. Calculo la celda destino = celda actual + dirección.
  4. Chequeo si esa celda está libre (no hay colisión del TileMap ni un NPC
     ahí) con un `move_and_collide`/raycast corto, o consultando
     `get_used_cells` y las posiciones de los NPCs.
  5. Si está libre, animo la posición con un `Tween` (`~0.15s`, `TRANS_LINEAR`)
     desde la celda actual a la destino y marco `is_moving = true` hasta que
     termine.
  6. Si está bloqueada, no me muevo (opcionalmente, mirar hacia esa
     dirección para dar feedback visual, sin moverse — típico de Pokémon).

## NPCs (`NPC.tscn` + `NPC.gd`)

- Mismo esqueleto que el jugador pero **sin** lógica de input: `StaticBody2D`
  (o `CharacterBody2D` quieto) + `Sprite2D` + `CollisionShape2D`, para que el
  jugador choque contra ellos y no los atraviese.
- Se agrega un `Area2D` extra llamado `InteractionZone` (un tile alrededor del
  NPC) **ya preparada pero sin conectar a nada todavía** — es el gancho para
  el futuro sistema de diálogo (cuando el jugador entre en esa área y
  presione una tecla de interacción, se podrá disparar un diálogo). En esta
  etapa no hace nada, solo queda declarada.
- Se instancian 2-3 `NPC.tscn` en `Town.tscn`, cada uno con una posición fija
  y un sprite distinto (variantes de color del pack de Kenney) para
  diferenciarlos a simple vista.

## Cámara

- `Camera2D` como hijo de `Player.tscn`, con `position_smoothing` activado
  (suave) y **límites** (`limit_left/right/top/bottom`) seteados al tamaño
  del mapa en píxeles, para que no se vea "fuera" del pueblo.

## Orden de implementación (checklist)

1. Crear proyecto Godot 4.x, configurar pixel art + Input Map.
2. Descargar assets de Kenney y ubicarlos en `assets/`.
3. Armar el `TileSet` con colisión en tiles de obstáculo.
4. Pintar el mapa del pueblo en un `TileMapLayer` dentro de `Town.tscn`.
5. Crear `Player.tscn`/`Player.gd` con movimiento grid-based y probar
   colisión contra bordes/obstáculos del mapa.
6. Agregar `Camera2D` al jugador con límites al mapa.
7. Crear `NPC.tscn`/`NPC.gd` (estático + colisión + `InteractionZone` vacía)
   e instanciar 2-3 en el pueblo.
8. Probar: mover al jugador en las 4 direcciones, verificar que no atraviesa
   árboles/casas/NPCs ni se sale del mapa, y que la cámara lo sigue bien.

## Cómo se prueba al terminar

Abrir el proyecto en Godot, correr `Town.tscn` (F6) y verificar:
- El jugador se mueve tile a tile con flechas/WASD, con una pequeña
  animación de deslizamiento (no salto instantáneo).
- No se puede caminar sobre árboles, agua, casas ni NPCs.
- No se puede salir de los límites del mapa.
- La cámara sigue al jugador sin mostrar zonas vacías fuera del pueblo.

## Próximos pasos (fuera de este plan, para después)

- Sistema de diálogo simple al interactuar con un NPC (usando la
  `InteractionZone` que dejamos preparada).
- Animación de caminata (varios frames por dirección) en vez de sprite fijo.
- Transición entre mapas (ej. entrar a una casa).
- Sistema de combate por turnos estilo Pokémon.
