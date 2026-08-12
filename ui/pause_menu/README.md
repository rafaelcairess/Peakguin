# Menu de pausa

O menu é carregado globalmente pelo Autoload `PauseMenu` e abre com `Esc`
(`ui_cancel`). Não é necessário adicioná-lo manualmente em cada fase.

## Trocar a arte futuramente

1. Abra `pause_menu.tscn`.
2. Selecione o nó raiz `PauseMenu`.
3. No Inspector, abra **Arte opcional**.
4. Arraste uma textura para `Panel Texture` para trocar a moldura central.
5. Use `Title Icon` e os campos de ícone dos botões conforme necessário.

Os campos podem permanecer vazios durante o desenvolvimento. A estrutura de
containers ajusta os controles automaticamente sem depender do tamanho da
janela. O shader do fundo está em `res://shaders/ui/pause_blur.gdshader`; sua
propriedade `blur_strength` controla a intensidade do desfoque.
