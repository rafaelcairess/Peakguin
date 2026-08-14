# Tela inicial

`main_menu.tscn` é uma base visual simples para a tela inicial do Peakguin.

## Como trocar as fases

Selecione o nó raiz `MainMenu`. Na seção **Fases** do Inspector você pode
arrastar qualquer cena `.tscn` para:

- `Default Level`: fase aberta pelo botão **Jogar**;
- `Grassland Level`;
- `Winter Level`;
- `Forest Level`;
- `Tropic Level`.

Os quatro últimos campos alimentam o seletor **Levels**.

## Como personalizar

Na seção **Visual** do mesmo nó existem campos para cor e imagem de fundo,
logo, animações do pinguim e texturas dos botões. Todos são opcionais. Sem
nenhuma textura configurada, o menu permanece simples e o pinguim reutiliza
automaticamente as animações do Player.

O nó `PenguinPreview` já possui o recurso `penguin_menu_frames.tres`, por isso
o pinguim aparece também no editor. Para trocar seus sprites:

1. selecione `PenguinPreview`;
2. clique na propriedade **Sprite Frames**;
3. edite a animação `walk` na área **SpriteFrames**;
4. substitua os quadros ou arraste outro recurso `SpriteFrames`.

Para mover ou redimensionar sem tocar nos quadros, selecione `PenguinAnchor`.

Os textos e posições também podem ser alterados diretamente nos nós da cena.
Os ícones e uma música de menu possuem campos próprios no Inspector. Para a
música, você pode selecionar o nó raiz `MainMenu` e usar **Menu Music**, ou
selecionar o nó `MenuMusic` e arrastar o áudio para **Stream**. A reprodução
passa pelo bus `Music` e pelo fade do `MusicManager`.
