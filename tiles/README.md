# TileSets compartilhados

- `terrain.tres`: terrenos sólidos de todos os biomas.
- `decoration.tres`: árvores, plantas, casas e outros enfeites.
- `underwater.tres`: água e conteúdo submerso.
- `lava.tres`: tiles de lava e perigo.

Os quatro recursos ficam juntos nesta pasta para serem encontrados rapidamente
no FileSystem da Godot. Mantenha terreno e decoração em `TileMapLayer` separados
para alterar a ordem visual sem afetar as colisões.
