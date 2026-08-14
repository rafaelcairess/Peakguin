# Efeitos sonoros

## Organização

- `music`: músicas completas usadas pelas fases.
- `sfx/player`: ações do personagem, como o pulo.
- `sfx/environment/grass`: passos e sons de grama.
- `sfx/environment/water`: efeitos sonoros de água.
- `sfx/environment/lava`: efeitos sonoros de lava.
- `sfx/pickups`: coleta de moedas e corações.

Todos os efeitos usados nesta pasta possuem licença CC0 e podem ser usados em
projetos comerciais ou não comerciais. Os links abaixo são mantidos para
registrar a origem dos arquivos.

## 8-bit Platformer SFX

- Autor: MoxieCat
- Fonte: https://opengameart.org/content/8-bit-platformer-sfx-0
- Licença: CC0 1.0
- Arquivo usado: `sfx/player/jump.wav`

## 8-bit sound FX

- Autor: Dizzy Crow
- Fonte: https://opengameart.org/content/8-bit-sound-fx
- Licença: CC0 1.0
- Arquivos usados:
  - `Rustle1.wav` como `sfx/environment/grass/grass_step_01.wav`
  - `Rustle2.wav` como `sfx/environment/grass/grass_step_02.wav`
  - `Rustle3.wav` como `sfx/environment/grass/grass_step_03.wav`
  - `WaterSplash.wav` como `sfx/environment/water/water_splash.wav`
  - `ThrustLow.wav` como `sfx/environment/lava/lava_rumble.wav`

O som de lava toca em loop por meio da cena reutilizável
`entities/environment/lava_ambience.tscn`. A propriedade `Audible Distance`
define no Inspector até onde ele pode ser ouvido; o círculo laranja exibido no
editor representa essa distância.

## Bloco quebrável

- Arquivo: `sfx/environment/blocks/block_break.wav`.
- Origem: gerado especificamente para este projeto.
- Característica: impacto curto com estalos de detritos em estilo retrô.
- Gerador reproduzível: `tools/audio/generate_block_break.py`.

## Itens coletáveis

- `sfx/pickups/coin_collect.wav`: confirmação curta da coleta de moeda.
- `sfx/pickups/heart_collect.wav`: sequência ascendente usada na cura.
- Origem: gerados especificamente para este projeto.
- Gerador reproduzível: `tools/audio/generate_pickup_sfx.py`.

Os dois itens expõem **Pickup Sound** e **Pickup Volume Db** no Inspector. Isso
permite trocar o arquivo ou regular seu volume sem alterar o código. Ambos são
enviados para o bus `SFX` e, portanto, também respeitam o volume de efeitos do
menu de configurações.

## Passos de grama

- Arquivos usados: `grass_step_01.wav`, `grass_step_02.wav` e
  `grass_step_03.wav`.
- O jogador reproduz o arquivo original e o interrompe no ponto de corte
  escolhido no menu.

### Calibração dentro do jogo

Abra `Esc > Configurações > Testar sons` para regular e ouvir separadamente o
pulo e o passo. Os ajustes usam os buses `PlayerJump` e `PlayerSteps`, são
salvos em `user://settings.cfg` e continuam subordinados ao volume geral de
efeitos (`SFX`). O controle `Corte` escolhe por quantos segundos o som original
do passo toca, de `0,03s` até `2,02s`.

## RPG Sound Effect Pack

- Autor: Delta12 Studio
- Fonte: https://opengameart.org/content/rpg-sound-effect-pack
- Licença: CC0 1.0
- Arquivo disponível: `sfx/environment/grass/grass.ogg`

CC0 1.0: https://creativecommons.org/publicdomain/zero/1.0/
