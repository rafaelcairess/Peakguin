# HUD do jogo

A cena `game_hud.tscn` é instanciada dentro de `entities/player/player.tscn` e,
por isso, aparece automaticamente em todas as fases que utilizam o Player.

O HUD apresenta:

- três corações de vida;
- cronômetro no formato `MM:SS`, limitado a `99:59`;
- contador de moedas com três dígitos.

Para mudar posição ou espaçamento, edite `TopRight` e seus Containers na cena
do HUD. A leitura do sprite de números e a atualização dos valores ficam em
`scripts/ui/game_hud.gd`.

As cenas de moeda e coração ficam em `entities/pickups`. Ao selecionar a raiz
de uma delas, as propriedades **Pickup Sound** e **Pickup Volume Db** ficam
disponíveis no Inspector.
