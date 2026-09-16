# Cómo darle mi propio estilo a los sprites y mapas

Recomendación para reemplazar los assets de Kenney (placeholders) por arte
propio, en orden de importancia.

## 1. Trabajá al tamaño nativo del tile (16x16 px)

No dibujes grande y después reduzcas. El pixel art no perdona el escalado
automático: una imagen bajada de resolución con un algoritmo genérico da
bordes borrosos o ruido de color. Si dibujás directamente en 16x16 (o como
mucho 32x32 y después achicás a mano, tile por tile, corrigiendo pixel por
pixel), controlás cada pixel y mantenés la nitidez que ya tienen los assets
de Kenney que usamos ahora.

Esto no es negociable si querés que se vea prolijo al lado del resto — es
la parte que menos se parece a dibujar "normal" y la que más hay que
practicar si nunca hiciste pixel art.

## 2. Usá una herramienta pensada para esto

Nada de Photoshop/Procreate. Opciones:

- [Aseprite](https://www.aseprite.org/) — pago (~20 USD), el estándar de
  la industria.
- [LibreSprite](https://libresprite.github.io/) — gratis, fork de una
  versión vieja de Aseprite.
- [Piskel](https://www.piskel.com/) — gratis, funciona en el navegador.

Todas dan zoom por pixel, onion skinning para animar, y manejo de paleta
indexada — pensadas para esta escala.

## 3. Definí una paleta de colores chica y fija antes de dibujar nada

No vayas eligiendo colores al vuelo. Es lo que más "unifica" un estilo
visual entre personajes y mapas distintos. Mirá
[Lospec.com](https://lospec.com/palette-list) para elegir o armar una
paleta de 16-32 colores, y usá esa misma paleta para todo (tiles nuevos y
personajes nuevos), aunque dibujes cada cosa en momentos distintos.

## 4. Mantené la convención que ya tenemos

Celdas de 16x16, personajes de un solo frame por ahora (mirando "hacia
abajo", como los NPCs actuales) para no tener que rehacer animación.

Cuando tengas un `.png` (tileset propio o spritesheet de personajes),
pasámelo y lo reemplazo en `assets/` actualizando las coordenadas — no
hace falta que armes vos el `TileSet` de Godot.

## Trade-off a tener en cuenta

Cuanto más te alejes de 16x16 con separación de 1px (el grid que ya está
armado), más código hay que tocar (tamaños de colisión, cámara, posiciones).
Si querés tiles más grandes (32x32) para tener más detalle, es viable pero
conviene decidirlo ahora y migrar todo junto, no mezclar tamaños.
