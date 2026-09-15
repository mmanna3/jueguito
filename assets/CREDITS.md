# Créditos de assets

Ambos packs son de [Kenney.nl](https://kenney.nl), licencia **CC0** (dominio
público). No es obligatorio pero está bueno mencionarlo.

- **Tileset del mapa:** Kenney — Roguelike/RPG Pack
  https://kenney.nl/assets/roguelike-rpg-pack
  → `assets/tileset/roguelikeSheet_transparent.png`
- **Personajes:** Kenney — Roguelike Characters
  https://kenney.nl/assets/roguelike-characters
  → `assets/characters/roguelikeChar_transparent.png`

## Coordenadas usadas (columna, fila) — celdas de 16x16 con 1px de separación

### Tileset (`town_tileset.tres`)

| Tile   | Coord (col,fila) | Uso                    |
|--------|-------------------|-------------------------|
| Pasto  | (5, 0)            | Piso caminable          |
| Camino | (6, 0)            | Piso caminable          |
| Árbol  | (13, 10)          | Borde del mapa, bloquea |
| Pared  | (16, 13)          | Casas, bloquea          |
| Agua   | (0, 0)            | Laguna decorativa, bloquea |

### Personajes

| Personaje | Coord (col,fila) |
|-----------|-------------------|
| Jugador   | (0, 5)            |
| NPC 1     | (0, 6)            |
| NPC 2     | (1, 6)            |
| NPC 3     | (1, 8)            |

Para reemplazar cualquiera de estos assets: pisar el `.png` correspondiente
en `assets/tileset/` o `assets/characters/` (si mantenés el mismo tamaño de
celda 16x16) o, si usás un pack distinto, actualizar las coordenadas en
`assets/tileset/town_tileset.tres` (tiles del mapa) y en las escenas
`Player.tscn` / los overrides de `atlas_coords` en `Town.tscn` (personajes).
