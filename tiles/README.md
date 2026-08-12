# Tiles

- `terrain/terrain.tres`: terrenos sólidos de todos os biomas.
- `decoration/decoration.tres`: árvores, plantas, casas e outros enfeites.
- `environment/underwater.tres`: água e conteúdo submerso.
- `hazards/lava.tres`: tiles de lava e perigo.

Mantenha terreno e decoração em `TileMapLayer` separados. Assim é possível
alterar a ordem visual da decoração sem afetar as colisões do terreno.
