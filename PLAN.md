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

## Etapa 2: diálogos (2026-09-15)

Se agregó un sistema de diálogo simple:

- **Tecla:** `ui_accept` (Enter / Espacio — la acción default de Godot, no
  hubo que tocar el Input Map).
- **Cómo funciona:** `Player.gd` guarda hacia dónde está mirando
  (`facing`). Al apretar la tecla de interacción, calcula la celda de
  enfrente y busca si hay un NPC ahí (grupo `"npc"`). Si lo hay, le pide al
  autoload `Dialogue` (`scripts/DialogueBox.gd` + `scenes/DialogueBox.tscn`)
  que muestre sus líneas una por una; cada `NPC` tiene `npc_name` y
  `dialogue_lines` exportados, seteados por instancia en `Town.tscn`.
  Mientras el diálogo está activo, el jugador no se puede mover.
- **Probado:** con Godot corriendo (self-test temporal en `_ready()` de
  `Town.gd`, después revertido) se confirmó por código que el diálogo abre
  con el NPC correcto al interactuar de frente, avanza línea por línea, se
  cierra solo al terminar, y no se dispara si no hay nadie enfrente. También
  se sacó una captura real mostrando el cartel en pantalla.
- **Bug encontrado y corregido:** el autoload en `project.godot` necesita
  el prefijo `*` (`Dialogue="*res://scenes/DialogueBox.tscn"`) — sin él,
  Godot no lo registra como singleton global y falla la compilación de
  cualquier script que lo referencie.
- **Bug reportado y corregido (2026-09-15):** el diálogo nunca terminaba —
  al llegar a la última línea y apretar Enter, se reabría en la línea 1 en
  vez de cerrarse. Causa: tanto `Player.gd` como `DialogueBox.gd` sondeaban
  `Input.is_action_just_pressed("ui_accept")` cada uno por su lado en
  `_physics_process`. En el frame exacto en que `Dialogue._advance()`
  cerraba el diálogo (`is_active = false`), el chequeo de `Player`
  (`if Dialogue.is_active: return`) ya veía `false` y trataba ese mismo
  Enter como un interact nuevo, reabriendo la conversación. Se resolvió
  pasando el manejo de `ui_accept` de sondeo (`_physics_process`) a evento
  (`_unhandled_input` + `get_viewport().set_input_as_handled()`), que
  garantiza que un mismo Enter lo procese un solo handler. El movimiento
  (flechas/WASD, que sí necesita sondeo para repetirse mientras se mantiene
  apretada la tecla) no se tocó.



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

## Etapa 3: escena del bosque, Ryan, Abuela Catta y arte propio (2026-09-16)

Se agregó una escena inicial nueva con arte propio (no placeholders de
Kenney), reemplazando a `Town.tscn` como `run/main_scene` (que sigue en el
proyecto, funcional, para más adelante).

### Arte

Ver `COMO_DARLE_MI_ESTILO_A_LOS_SRPITES.md` para la guía general. Lo que se
hizo acá en concreto:

- **Mapa (`assets/tileset_forest/`)**: en vez de dibujar tiles nuevos de
  cero, se **recolorearon** (hue-shift + brillo/saturación, con
  ImageMagick) el pasto, camino y agua del tileset de Kenney hacia gamas de
  violeta — mantiene el sombreado original, solo cambia el color. El único
  tile dibujado a mano fue el árbol con tronco: se recortó la copa
  recoloreada (violeta) y se le agregó un tronco marrón de un par de
  píxeles, ya que el tile original de Kenney no tenía tronco visible. Los
  6 tiles quedaron en `forest_sheet.png` (pasto, camino, arbusto de borde,
  árbol con tronco, agua, arbusto decorativo) + `forest_tileset.tres`.
- **Ryan (protagonista) y Abuela Catta**: dibujados a mano, pixel por
  pixel, con un script propio (`pixelart.py`, ver scratchpad de la sesión)
  que arma un PNG a partir de una grilla de caracteres + paleta de colores
  — no hay herramienta de generación de imágenes disponible. Sprites de
  16x16 en `assets/characters_custom/` (`ryan.png`, `abuela.png`). Al ser
  dibujo propio simple, la calidad es más "indie chico" que el detalle del
  pack de Kenney — si en algún momento no convence, se puede reemplazar por
  un pack temático (ej. buscar en itch.io algo tipo "Mystic Woods").
- **Retratos de diálogo**: no son un dibujo aparte — son la cabeza de cada
  sprite (recorte de las primeras 10 filas) reusada tal cual, así quedan
  100% consistentes con el personaje que se ve caminando. Archivos
  `ryan_portrait.png` / `abuela_portrait.png`.
- Ahora `Player.tscn` (compartido por `Town.tscn` y `Forest.tscn`) usa el
  sprite de Ryan en vez del genérico de Kenney — el protagonista es el
  mismo en todo el juego.

### Sistema de diálogo generalizado

`DialogueBox` pasó de "un NPC dice N líneas" a **conversaciones de varios
hablantes**: `Dialogue.start_conversation(entries)` recibe un array de
`{"speaker": ..., "portrait": ..., "text": ...}` y muestra cada entrada al
apretar `ui_accept`. Se agregó un `TextureRect` a la izquierda del cartel
con el retrato del hablante actual (se oculta solo si esa entrada no tiene
retrato, para no romper los NPCs viejos del pueblo que no tienen uno).

Para que una escena pueda armar una conversación a medida (con líneas del
propio jugador incluidas, como la del bosque) sin tocar el NPC genérico,
`NPC.gd` ahora tiene:
- `custom_texture` / `portrait` (exportados): para usar un sprite propio
  en vez de una pieza del spritesheet de Kenney.
- Señal `interact_requested`: si algo está conectado a esta señal (por
  ejemplo `Forest.gd`), el NPC le cede el control de la interacción en vez
  de mostrar su diálogo genérico de una sola voz.

`Player.gd` ahora simplemente llama a `npc.interact()` — quedó desacoplado
de cómo cada NPC decide manejar la conversación.

### Escena `Forest.tscn` / `Forest.gd`

Bosque cerrado de 15x10 tiles, con una laguna de Agua Púrpura visible al
lado de donde está parada la Abuela Catta (para que la charla tenga un
correlato visual), árboles y arbustos decorativos, y un sendero. Ryan
arranca cerca; al acercarse a la Abuela Catta y apretar Enter, se dispara
la conversación completa (10 líneas, alternando Ryan/Abuela Catta, cada
una con su retrato), definida directamente en `Forest.gd`.

### Probado con Godot real

- Import headless sin errores.
- Self-test simulando 11 Enters reales: la conversación completa avanza
  línea por línea alternando hablante y retrato correctamente, y se cierra
  sola al final (sin reabrirse).
- Se verificó que los NPCs viejos del pueblo (Don Braulio, etc.) siguen
  funcionando con el sistema de diálogo generalizado (sin retrato, como
  corresponde).
- Captura de pantalla real confirmando el bosque violeta y el cartel de
  diálogo con retrato en pantalla.

## Etapa 3b: mapa 8x más grande, prolijidad visual y ajustes de UI (2026-09-16)

Feedback del usuario tras ver la Etapa 3, y lo que se cambió:

- **Bug de fondo gris en árboles/plantas — causa real y fix**: los tiles de
  árbol/arbusto/roca son siluetas con transparencia (no ocupan el tile
  16x16 completo), y `Forest.tscn` los pintaba en la misma (única)
  `TileMapLayer` que el pasto, tapándolo. La transparencia dejaba ver el
  color de fondo de la ventana en vez del pasto. Se resolvió con **dos
  capas**: `Ground` (pasto/camino/agua, siempre sólido) y `Decoration`
  (árboles/arbustos/rocas encima, con transparencia — el pasto de `Ground`
  se ve por los bordes). Mismo `TileSet` compartido por ambas capas.
- **Mapa 8 veces más grande**: de 15x10 (150 tiles) a 40x30 (1200 tiles).
  Cámara y límites actualizados acordes (antes 240x160, ahora 640x480);
  como `Player.tscn` se comparte con `Town.tscn`, el límite de cámara se
  sobrescribe puntualmente en la instancia de `Forest.tscn`.
- **Bordes mixtos** (en vez de un hedge uniforme en las 4 puntas): agua a
  la izquierda, roca a la derecha, bosque (2 tiles de espesor) arriba y
  abajo.
- **Grupos de árboles infranqueables**: 6 "arboledas" de 6-7 tiles cada
  una, en formas irregulares (no rectángulos), mezclando arbusto/árbol
  redondo/pino para que no se vean repetitivas. Se verificó por código que
  bloquean el paso.
- **Tiles nuevos** (todos en `assets/tileset_forest/forest_sheet.png`):
  pasto con sombra (variante más oscura, para parches de "hierba
  sombreada"), pasto con flores (dibujadas a mano, no recoloreadas —
  recolorear el tile original de Kenney le daba un color feo y dejaba un
  artefacto blanco), pino con tronco (mismo truco que el árbol redondo:
  copa recortada + tronco a mano), roca gris (dibujada a mano con
  ImageMagick, ya que los tiles de roca de Kenney son piezas de un
  auto-tile conectado y no se pueden usar sueltas).
- **Laguna con forma irregular**: se dejó de usar un bloque cuadrado de
  agua. Ahora es el gráfico de laguna redonda de 3x3 tiles de Kenney
  (`assets/tileset_forest/pond.png`), recoloreado con reemplazo de color
  puntual (no hue-shift global, que daba un borde verde feo) — cuerpo de
  agua púrpura + orilla gris-lavanda. Se usa como sprite aparte (no como
  tile repetible) porque es una pieza única.
- **Diálogo — tipografía**: el nombre del que habla ahora es más grande
  (15px) y en color dorado (`#FFD75E`) para que resalte por sobre el texto
  (no hay una fuente bold cargada en el proyecto, así que la jerarquía se
  logra con tamaño + color en vez de negrita real). El texto del cuerpo se
  achicó de 12px a 9px.

Todo probado con Godot real: self-test que aleja la cámara para capturar
el mapa completo, verifica colisión contra una de las arboledas nuevas, y
dispara el diálogo para confirmar la tipografía — más una captura visual
de cada cosa.

**Pendiente / no incluido en este pase**: `Town.tscn` (el pueblo) todavía
usa una sola `TileMapLayer`, así que probablemente tenga el mismo problema
de fondo gris en sus árboles si se lo mira de cerca — no se tocó porque el
pedido de esta vuelta fue específicamente sobre la escena del bosque. Si
se quiere, se aplica el mismo fix de dos capas ahí.

## Etapa 3c: rediseño del cuadro de diálogo (2026-09-16)

El usuario reportó que la tipografía y el estilo del cuadro de diálogo se
veían mal ("de mala calidad"), a pesar de haber achicado el tamaño de
fuente en la Etapa 3b. Causa real, no era solo "tamaño":

- El proyecto usa la fuente default de Godot (una fuente de UI genérica,
  no pensada para pixel art) **combinada con el filtro "Nearest" global**
  que el proyecto necesita para que los sprites se vean nítidos. Ese
  filtro aplicado a una fuente suave/antialiaseada la deja con bordes
  toscos y da esa sensación de "mala calidad" / letras gigantes, más allá
  del tamaño en puntos configurado.
- El cuadro en sí era un `Panel` default de Godot: un rectángulo gris
  liso, sin borde ni identidad visual propia.

Qué se cambió:

- **Tipografías nuevas** (descargadas de Google Fonts, licencia OFL,
  quedaron en `assets/fonts/` con su licencia): **VT323** para el cuerpo
  del texto (legible, minúsculas normales, look de terminal retro) y
  **Silkscreen Bold** para el nombre de quien habla (mayúsculas, peso bold
  real —no un truco de tamaño—, en dorado `#FFD75E`). Ambas soportan
  acentos y signos en español (¿¡áéíóúñ), verificado antes de usarlas.
- **Filtro de texturas en Linear solo para el diálogo**: se seteó
  `texture_filter = Linear` en el `Control` raíz del `DialogueBox` (se
  hereda a todos sus hijos), así el texto se renderiza suave aunque el
  resto del juego (sprites, tiles) siga en Nearest para mantener el pixel
  art nítido.
- **El `Panel` pasó a tener un `StyleBoxFlat` propio**: fondo violeta muy
  oscuro semi-transparente, borde de 2px en lavanda claro, esquinas
  redondeadas (6px) y una sombra suave — deja de ser un rectángulo gris
  genérico. El marco del retrato tiene su propio `StyleBoxFlat` a juego.
- **Ajuste de layout**: el panel creció un poco de alto para que las
  líneas más largas del guión entren sin desbordarse (se detectó por
  captura de pantalla que una línea larga se salía del cuadro), se
  activó `clip_contents` como resguardo, y se dividieron 3 líneas
  demasiado largas del guión de la abuela en "beats" más cortos (más
  auténtico al género además de más seguro).
- Cuando un NPC no tiene retrato (los del pueblo, por ahora), el texto
  ahora ocupa todo el ancho disponible en vez de dejar un hueco vacío a
  la izquierda.

Probado con Godot real: se imprimieron las 16 líneas del guión del bosque
con su longitud en caracteres para confirmar que ninguna es más larga que
la más larga ya verificada por captura (110 caracteres, entra en 3
renglones), y se sacaron capturas del diálogo en el bosque (con retrato) y
en el pueblo (sin retrato) para confirmar el resultado visual.

**Ajuste posterior**: el nombre quedó demasiado grande y en negrita para
el gusto del usuario. Se cambió `Silkscreen-Bold.ttf` por
`Silkscreen-Regular.ttf` (misma familia, sin negrita) y el tamaño bajó de
16 a 11, retocando además los márgenes verticales para que no quede un
hueco entre el nombre y el texto.

**Cancelar diálogo con ESC**: `DialogueBox._unhandled_input` ahora también
escucha `ui_cancel` (Escape, acción default de Godot) y cierra la
conversación de inmediato sin pasar por las líneas que falten. Probado por
código: se abre el diálogo, se avanza un par de líneas, se simula ESC, se
confirma que `Dialogue.is_active` pasa a `false` y que el jugador puede
volver a moverse.

**Orilla en el agua del borde izquierdo**: el agua del límite izquierdo
del mapa era un tile plano (un rectángulo violeta liso), que no se leía
como agua. Se reutilizaron 3 piezas del gráfico de la laguna ("manantial")
del centro del mapa —esquina superior, borde recto, esquina inferior, cada
una con orilla gris-lavanda— para armar una costa vertical a lo largo de
todo el borde izquierdo. Quedaron como tiles nuevos (índices 10-12 de
`forest_sheet.png`: `WATER_EDGE_TOP/MID/BOTTOM`), con la misma colisión
que el resto de los obstáculos.

**Fix inmediato**: esas piezas de orilla son siluetas con esquinas
transparentes (igual que los árboles), y se habían pintado en `Ground`
—que no tiene nada debajo— así que esas esquinas dejaban ver el fondo gris
de la ventana en vez del pasto. Se pasaron a `Decoration` (con `Ground`
en pasto por debajo, como ya se hace con árboles/rocas/arbustos), así el
pasto se ve por las esquinas y la orilla se funde con el bosque en vez de
tener un borde gris/negro.

## Etapa 4: el manantial responde y aparece el Extraño (2026-09-16)

Primer gancho de historia real, con una cutscene disparada por el jugador.

### Diseño

1. **El manantial ("Agua Púrpura") ahora es interactivo.** Parándose al
   lado y apretando `ui_accept`, muestra un texto sin nombre de hablante
   (estilo narración): *"El Agua Púrpura brota de la tierra calmada, como
   si escondiera el secreto de un pasado olvidado."*
2. **Gateo narrativo**: la primera vez que se interactúa con el agua
   *después* de haber hablado con la Abuela Catta, se dispara la escena
   del Extraño. Si se interactúa con el agua antes de hablar con la
   abuela, o después de que la escena ya ocurrió una vez, solo se repite
   el texto — no pasa nada más (a propósito, tal como se pidió).
3. **Aviso al jugador** (antes de la escena, en vez de música — se puede
   sumar sonido más adelante sin tocar esta lógica): un signo de
   exclamación naranja aparece arriba de Ryan con un pequeño rebote, *y*
   la cámara tiembla brevemente. Se combinaron las dos ideas que
   propusiste porque son baratas de implementar y se refuerzan entre sí.
4. **El Extraño**: personaje nuevo, dibujado a mano igual que Ryan y la
   Abuela (encapuchado, ojos y un emblema en el pecho violeta brillante —
   pensado para leerse como amenazante/misterioso). Aparece invisible,
   ubicado fuera de los márgenes del mapa, y "camina" (interpola su
   posición con un `Tween`, igual que se desliza el jugador tile a tile,
   pero en una sola animación larga) hasta pararse cerca de Ryan y la
   Abuela.
5. **Mientras el Extraño camina, el jugador no se puede mover.** Se agregó
   `Player.movement_locked` (además de `Dialogue.is_active`) para congelar
   input durante cutscenes que no son, en sí mismas, un diálogo.
6. Termina la escena con el diálogo de los 3 (tal como lo escribiste,
   palabra por palabra) y ahí queda — nada más pasa por ahora, como
   pediste, a la espera del sistema de combate.

### Cambios técnicos

- **Grupo de interacción generalizado**: `NPC.gd` y el nuevo
  `WaterSpring.gd` (script chico para el manantial) se anotan en el grupo
  `"interactable"` (antes era `"npc"`, mal nombre para algo que no es una
  persona). `Player.gd` ahora busca en ese grupo genérico y llama
  `.interact()` en lo que encuentre — el manantial le cede el control a
  `Forest.gd` exactamente igual que hace la Abuela con la conversación a
  medida (señal `interact_requested`).
- **`NPC.gd` ganó `walk_to(target_pos, duration)`**: desliza al personaje
  con un `Tween`, `await`-eable, para que una escena pueda hacer "entrar
  caminando" a un personaje sin jugador de por medio.
- **`DialogueBox` ganó una señal `dialogue_closed`**, así `Forest.gd` puede
  encadenar pasos de una cutscene con `await Dialogue.dialogue_closed` en
  vez de sondear `is_active`. También aprendió a mostrar una línea sin
  nombre de hablante (oculta el `NameLabel` y corre el texto hacia arriba)
  para el texto de narración del manantial.
- Toda la orquestación de la escena (bloquear/desbloquear al jugador, el
  aviso, la caminata, el diálogo) vive en `Forest.gd`, no en los
  personajes — mantiene a `NPC.gd`/`WaterSpring.gd` genéricos y
  reutilizables.

### Probado con Godot real

Self-test completo simulando: interactuar con el agua antes de hablar con
la abuela (solo texto, sin cutscene) → hablar con la abuela (16 líneas) →
interactuar con el agua de nuevo (dispara todo: bloqueo de movimiento,
aviso, el Extraño camina hasta la posición exacta esperada, se abre el
diálogo de los 3 con el hablante/retrato correcto en cada línea, se
desbloquea el movimiento al cerrar) → interactuar con el agua una tercera
vez (no se repite nada). Más tres capturas reales: el signo de
exclamación, el Extraño a mitad de camino, y el diálogo de los 3 ya
reunidos junto al manantial.

### Bug reportado por el usuario: interactuar con el manantial no hacía nada

Jugando de verdad (no con los self-tests, que llamaban `.interact()`
directo salteándose el chequeo de distancia real), el usuario reportó que
pararse al lado del manantial y apretar Enter no pasaba nada.

**Causa**: `Player._interact()` calculaba si el interactuable estaba "cerca"
comparando la celda de enfrente contra un único punto (`thing.global_position`)
con una tolerancia de 4px — funciona para un NPC de 16x16, porque el
jugador siempre puede pararse justo a un tile de su centro. Pero el
manantial mide 48x48 (3x3 tiles): su centro nunca cae a un tile exacto de
ninguna celda donde el jugador pueda pararse (esas celdas están *adentro*
del propio manantial, bloqueadas por su colisión). No existía ninguna
posición real desde la que el chequeo diera "true".

**Fix**: `Player._interact()` ahora chequea si la celda de enfrente cae
dentro de un **área** (`Rect2`) centrada en el interactuable, no contra un
punto. Cada interactuable expone `@export var interact_size` (`NPC.gd`
usa 16x16 por default, `WaterSpring.gd` usa 48x48, el tamaño real del
manantial). Probado con Godot real simulando al jugador parado y encarando
el manantial desde las 4 direcciones (no llamando `.interact()` a mano) —
las 4 funcionan — y también que la abuela y los NPCs del pueblo (16x16)
lo siguen funcionando igual que antes.

## Etapa 5: sistema de batalla por turnos (2026-09-16)

Primer combate del juego: Ryan vs. Extraño, al terminar el diálogo de los
3 junto al manantial.

### Números acordados con el usuario

| | Nivel | PS (HP) |
|---|---|---|
| Ryan | 1 | 12 |
| Extraño | 50 | 1000 |

- **Golpear** (Ryan): 5 de daño.
- **Sombra Extraña** (Extraño): 110 de daño (definido por el usuario tras
  preguntarle — mata a Ryan de un solo golpe con margen).

No hace falta "trampear" el resultado: con esos números, Ryan pega una vez
(Extraño 1000→995), el Extraño responde con Sombra Extraña y lo deja en 0
— la derrota sale sola de la matemática del combate.

### Diseño

- **Escena de batalla aparte** (`Battle.tscn`/`Battle.gd`), como en un RPG
  clásico de verdad: se corta la vista del bosque (`get_tree().change_scene_to_file`)
  y aparece la pantalla de combate (fondo propio, HP bars, sprites
  agrandados de Ryan y el Extraño reusando el arte ya dibujado).
- **Turnos fijos**: primero Ryan (el jugador elige, aunque hoy solo hay una
  opción real), después el Extraño (automático, siempre usa Sombra
  Extraña).
- **Menú de 4 slots de ataque**, navegable con flechas/WASD + Enter, tal
  como pidió el usuario para dejar la puerta abierta a que Ryan aprenda más
  ataques después. Slot 0 = "Golpear" (dorado, seleccionable); slots 1-3 =
  "—" (gris, bloqueados — apretar Enter ahí no hace nada).
- El "relato" del combate ("Ryan usa Golpear.", "¡Extraño perdió 5 PS!",
  etc.) reutiliza el mismo `Dialogue` autoload que ya existe para las
  conversaciones — mismo cartel, misma tecla para avanzar, cero UI nueva
  que aprender.
- Los datos del combate (nombres, niveles, HP, ataques) están hardcodeados
  en `Battle.gd` porque hoy es el único combate posible en el juego. El día
  que haya más de un enemigo, eso pasa a viajar desde afuera (por ejemplo
  vía `GameState`).

### Qué pasa al perder (definido con el usuario)

Vuelve al bosque y sigue la conversación que escribió:

> **ABUELA:** Dejame a mí.
> *(tiembla la pantalla)*
> **EXTRAÑO:** Nunca me imaginé que esta vieja sería tan poderosa.
> **ABUELA:** Ryan, rápido, vamos.

Y ahí queda (nada más, como en la etapa anterior).

**Cómo viaja el estado entre escenas**: se agregó un autoload chico,
`GameState.gd` (`var returning_from_battle_defeat`), porque Godot
reinstancia `Forest.tscn` de cero en cada cambio de escena y pierde
cualquier variable local. `Battle.gd` prende la bandera justo antes de
volver al bosque; `Forest.gd` la lee una vez en `_ready()`, la apaga, y si
estaba prendida dispara la escena de la abuela (reposiciona a Ryan y al
Extraño cerca del manantial, hace temblar la cámara entre las dos
conversaciones) en vez de arrancar el bosque normal.

### Probado con Godot real

Se corrió la cadena completa (`Battle.tscn` como escena principal
temporalmente, simulando la selección de "Golpear" y avanzando los
carteles con `Dialogue._advance()`, sin tocar el teclado): el menú
bloqueado no hace nada, Golpear resta exactamente 5 PS (995/1000), Sombra
Extraña dejó a Ryan en 0/12, la escena cambió sola a `Forest.tscn`, y ahí
`GameState.returning_from_battle_defeat` llegó en `true` y disparó la
escena de la abuela hasta el final (con el movimiento del jugador
desbloqueado al cerrar). Más dos capturas reales de la pantalla de batalla
(el menú recién abierto, y el resultado final con la barra de Ryan vacía y
la del Extraño casi intacta).

### Ajustes posteriores del usuario

- **El cursor del menú se podía mover a slots vacíos** (apretar "abajo"
  deseleccionaba "Golpear" y había que volver con "arriba", o dar la
  vuelta completa). `Battle.gd::_move_cursor()` ahora salta los slots con
  `null` en vez de pasar por ellos — si solo hay un ataque real, el cursor
  simplemente no se mueve. Probado por código: apretar "abajo" una, tres, y
  "arriba" una vez, siempre se queda en el slot 0.
- **El Extraño reacciona de verdad cuando la abuela interviene.** Además
  del temblor de cámara ya existente, ahora:
  - Se dibujó una variante del sprite del Extraño
    (`stranger_shocked.png` + su retrato) con los ojos y el emblema del
    pecho en naranja-rojo intenso en vez del violeta calmo — a 16x16 un
    cambio de color se lee mucho mejor que intentar dibujar un gesto
    facial distinto, y con eso alcanza para transmitir sorpresa/dolor/
    bronca. `NPC.gd` ganó `set_sprite_texture()` para poder cambiarlo en
    caliente.
  - El propio NPC del Extraño (el que está parado en el mapa) tiembla un
    ratito en el lugar, después del temblor general de la pantalla.
    `NPC.gd` ganó `shake(duration, strength)`, igual que el temblor de
    cámara pero aplicado a la posición del personaje.
  - Su retrato en el cartel de diálogo de esa línea también usa la cara
    con los ojos naranjas, no la calma de siempre.
  Probado con Godot real: capturas confirmando que el sprite en el mapa
  efectivamente cambia de expresión en el momento justo.

## Etapa 6: 4 Extraños, ataque de la abuela narrado, y bosque libre (2026-09-16)

### 1. Ahora vienen 4 Extraños, no uno solo

`Forest.tscn` tiene `Stranger`, `Stranger2`, `Stranger3`, `Stranger4` (misma
escena/arte para los 4 — son genéricos). `Forest.gd` los maneja como
`strangers: Array` y los mueve/anima en paralelo (caminata de entrada,
temblor, cambio de cara) con loops, no código repetido x4. Se ubican en 3
de los 4 lados del manantial (no rodeándolo del todo), para dejar hueco
para acercarse a cada uno y para que Ryan pueda pasar entre ellos y el
agua. Solo el primero (`Stranger`) habla en la confrontación inicial — los
otros 3 están ahí en silencio, como pediste.

### 2. Texto de narrador al atacar

Justo después de que la abuela dice "Dejame a mí." y antes del temblor de
pantalla, aparece un texto sin nombre de hablante (mismo estilo narración
que ya usábamos para el manantial): *"Abuela Catta utiliza el Cristal
Púrpura para atacar a los Extraños."*

### 3. Bosque libre después del ataque

Se sacó el diálogo final fijo que cerraba la escena ("Nunca me
imaginé.../Ryan, rápido, vamos") — en su lugar, apenas termina el ataque:

- Los 4 Extraños reaccionan **todos igual, en paralelo**: cambian a la cara
  con los ojos naranjas y tiemblan un ratito cada uno (`NPC.gd::shake()`,
  ya existía, ahora se llama x4 sin esperar uno a que termine el otro).
- Cada uno queda con su propia frase para cuando le hablás (usando el
  mecanismo genérico de `NPC.gd`, no hizo falta código nuevo): *"Nunca
  había visto un poder semejante"*, *"Ya vienen refuerzos"*, *"Ouch, eso
  dolió"* — como pediste solo 3 frases distintas para 4 personajes, el 4to
  repite la primera.
- El jugador recupera el control, y **la abuela lo sigue**: `Player.gd`
  ahora emite una señal `move_finished(from_pos, to_pos)` cada vez que
  termina un paso; `Forest.gd` la escucha y manda a la abuela
  (`NPC.gd::walk_to()`) a deslizarse hasta la celda que Ryan acaba de
  dejar libre — quedar siempre pegada un paso atrás, para cualquier lado
  que doble. Se le agregó a `walk_to()` un chequeo para cortar el tween
  anterior si todavía estaba en curso (si no, dos deslizamientos seguidos
  muy rápido competían por la misma posición y quedaba raro).

Probado con Godot real (dos self-tests separados): la llegada inicial de
los 4 al manantial cae exacto en sus posiciones; después del ataque, los 4
tienen la cara/retrato/frase correctos, la abuela sigue a Ryan a la celda
exacta que dejó libre, y hablar con cada uno de los 4 da la frase que le
corresponde. Más una captura real de los 4 alrededor del manantial.

### El "bug" de las casillas bloqueadas: no era un bug

Preguntaste por qué, después de que la abuela ataca, Ryan no puede pasar
por algunas casillas alrededor del manantial. La causa: el Extraño (antes
solo había uno) queda parado ahí, visible, con colisión — como cualquier
NPC, bloquea su propia casilla. Antes de que llegara no había nadie ahí,
por eso se sentía distinto. No es un bug, es el personaje ocupando su
lugar — pero con 4 en vez de 1 había que ser más cuidadoso con dónde los
poné para no encerrar el manantial; por eso quedaron repartidos en 3 lados
en vez de amontonados, dejando siempre un camino libre para acercarse a
cada uno.

### Ajuste: diálogo corto tras el ataque + la abuela repite el apuro

Dos cambios en `_play_post_battle_scene`:

- Justo después de que todos los Extraños tiemblan (pero antes de
  desbloquear el movimiento), ahora hay un diálogo cortito automático:
  **Extraño**: "¡Agghh! Nunca vi un poder semejante." / **Abuela Catta**:
  "Rápido, Ryan, hacia el sur." — recién después de eso arranca el bosque
  libre.
- `_on_abuela_interact()` ahora chequea `_abuela_following`: si ya pasó el
  ataque (la abuela está siguiendo a Ryan), hablarle repite "Rápido,
  Ryan, hacia el sur." en vez del saludo original de la Ceremonia — no
  tendría sentido repetir esa presentación en ese punto de la historia.

Probado con Godot real: la escena post-batalla llega a buen término
(`movement_locked=false`, `abuela_following=true`) recién después de que
ese diálogo corto se cierra, y hablarle a la abuela en modo seguimiento
devuelve exactamente "Rápido, Ryan, hacia el sur." — más una captura real
del cartel con la cara del Extraño ya asustada.

## Etapa 7: manantial con candado, y transición a un mapa nuevo (2026-09-16)

### 1. El manantial no reacciona hasta hablar con la abuela

`_on_pond_interact()` ahora corta al principio si `not _talked_to_abuela`
— antes de eso, interactuar con el manantial no hace absolutamente nada
(ni siquiera el texto de narración).

### 2. Transición al Bosque Púrpura chico (la parte que más te interesaba)

Cómo queda armado, paso a paso:

1. **Se abre un hueco real en el mapa.** Justo después del diálogo corto
   del Extraño/abuela tras el ataque, `Forest.gd` borra (`erase_cell`) los
   tiles de bosque en 3 columnas al centro del borde sur (filas 28-29,
   columnas 19-21) — no es cosmético, son celdas de `Decoration` que
   realmente dejan de bloquear.
2. **Un `Area2D` invisible ("SouthExit")** ocupa exactamente ese hueco. En
   cuanto el `CharacterBody2D` del jugador la pisa, dispara
   `_on_south_exit_entered` — con una bandera (`_leaving_south`) para que
   no se dispare dos veces.
3. **Fundido a negro real**, no un corte seco: se agregó un autoload nuevo,
   `Transition` (`scenes/Transition.tscn` + `scripts/Transition.gd`), un
   `CanvasLayer` con un `ColorRect` a pantalla completa que persiste entre
   escenas (como `Dialogue`) y expone `fade_out()`/`fade_in()` como
   corutinas `await`-eables. `Forest.gd` bloquea al jugador, espera el
   fundido a negro, y recién ahí cambia de escena.
4. **El estado que necesita sobrevivir el cambio de escena** (Godot
   reinstancia todo de cero) viaja por `GameState.entering_forest_south`,
   el mismo patrón que ya se usaba para volver de la batalla.
5. **Escena nueva `ForestSouth.tscn`/`ForestSouth.gd`**: mapa de 20x15 (un
   cuarto del área del bosque grande de 40x30), mismo tileset violeta,
   completamente cerrado por bosque (sin más salidas por ahora). Ryan
   aparece entrando por el norte con la abuela justo detrás; en su
   `_ready()`, si `GameState.entering_forest_south` está prendido, bloquea
   el movimiento, hace `Transition.fade_in()` (de negro a transparente), y
   recién ahí lo libera. El seguimiento de la abuela se reconecta ahí
   mismo (mismo mecanismo que en el bosque grande: `Player.move_finished`
   → la abuela se desliza a la celda que Ryan dejó libre).
6. **La nave**: objeto nuevo dibujado a mano (plato circular gris viejo,
   cúpula de vidrio violeta, manchas de óxido, lucecitas ámbar — pensado
   para leerse como tecnología vieja/ajena, no orgánico como el resto del
   escenario), en el centro del mapa. Usa un script genérico nuevo,
   `InteractableProp.gd` (StaticBody2D + señal `interact_requested` +
   `interact_size` exportado), el mismo patrón que ya usaba el manantial
   — se armó genérico a propósito para no repetir código con el próximo
   objeto grande que haga falta.
7. **El diálogo de la nave** es el que escribiste, palabra por palabra,
   solo partido en más "renglones" en 2 lugares donde el texto original
   era largo (ya aprendimos que eso puede desbordar el cartel) — el
   contenido no cambió, solo la cantidad de Enters para leerlo. Termina
   ahí, como pediste, sin disparar nada más.

Probado con Godot real, la cadena completa: manantial mudo antes de hablar
con la abuela → post-batalla abre el hueco de verdad (se verificó que esa
celda queda sin tile) → parar al jugador arriba del `Area2D` dispara el
fundido y el cambio de escena → `ForestSouth` carga con Ryan y la abuela
en la posición esperada → hablarle a la nave reproduce las 10 líneas en
el orden y con el hablante/retrato correctos. Más dos capturas reales: el
clarito con la nave a lo lejos, y el cartel de diálogo ya abierto.

## Etapa 8: sin bloqueos falsos, y la emboscada final (2026-09-16)

### 1. Los Extraños vencidos ya no bloquean el paso

El reporte tenía sentido: alrededor del manantial había celdas bloqueadas
que no deberían estarlo. Causa: los 4 Extraños derrotados seguían siendo
obstáculos físicos, como si todavía fueran una amenaza activa — no tiene
sentido narrativo que un enemigo vencido y tembloroso siga bloqueando el
camino. `NPC.gd` ganó `set_solid(bool)` (activa/desactiva su
`CollisionShape2D`); en el mismo loop donde ya se les cambiaba la cara y
temblaban, ahora también se vuelven "atravesables" —siguen ahí, se les
puede seguir hablando (eso no depende de la colisión física), pero no
estorban para caminar. El manantial sigue bloqueando como corresponde,
es agua de verdad. Probado con Godot real: `test_move` hacia la celda de
cada uno de los 4 da `false` (no bloquea) y hacia el manantial sigue
dando `true`.

### 2. La emboscada final y la fuga en la nave

Al terminar la conversación de la nave (los 10 renglones sobre la
Rebelión, Cocco, Paltiv y Neurolick), se dispara automáticamente
`_play_ambush_scene()` en `ForestSouth.gd`:

1. Aparecen 10 Extraños más (`Ambush1`...`Ambush10`, mismo arte genérico,
   repartidos por el claro sin pisar la nave ni el sendero) — de golpe,
   sin caminata de entrada esta vez, porque la escena es de emergencia
   ("Ahora vas a ver, vieja" no da tiempo a una llegada lenta).
2. Diálogo: **Extraño**: "Ahora vas a ver, vieja." / **Abuela Catta**:
   "Ryan, no hay más tiempo."
3. Línea de narrador (mismo estilo sin nombre que ya usábamos): "Abuela
   Catta empuja a Ryan dentro de la nave."
4. Tiembla la cámara, Ryan desaparece (`player.visible = false` +
   `movement_locked = true` — para siempre, no hay nada más que hacer
   después de esto) y la abuela se queda parada sola, encarando a los 10.
5. La nave se desliza hacia arriba y se va del mapa (`Tween` sobre su
   posición, 1.1s, aceleración de despegue) y desaparece.

Nada más pasa después — como en los episodios anteriores, queda ahí a la
espera de lo que sigue. Probado con Godot real: los 10 quedan visibles,
`player.visible=false`, `movement_locked=true`, la nave termina
exactamente en la posición esperada tras el despegue y queda invisible.
Más una captura real del momento con los 10 Extraños rodeando el claro.

## Etapa 9: pausa antes de la emboscada, y pantalla de capítulo (2026-09-16)

### 1. Pausa (temblor) antes de que hable el Extraño

En `_play_ambush_scene()`, apenas aparecen los 10 Extraños, ahora hay un
temblor corto (0.3s) antes de abrir el diálogo — el mismo recurso que ya
usábamos como "aviso" en otras escenas, reutilizado acá como pausa
dramática previa a que hable.

### 2. Pantalla de capítulo bloqueante al final

Después de que la nave se va del mapa, `_show_chapter_screen()` funde a
negro (reusando el autoload `Transition`) y deja un cartel fijo:
**"Capítulo 1: La búsqueda"**, en dorado, centrado, con la tipografía
`Silkscreen-Bold`. No hay manera de sacarlo — no es una animación que
termina sola, es el estado final: `player.movement_locked` ya quedó en
`true` desde el paso anterior (para siempre, no se vuelve a desbloquear),
así que no queda ninguna acción disponible. Primer intento con
`font_size = 22` se salía de la pantalla (el texto es largo para los 320px
de ancho base); se ajustó a `14`, confirmado por captura que entra
completo y centrado.

Probado con Godot real, con captura de pantalla real del cartel final.
