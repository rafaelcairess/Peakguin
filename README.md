<h1 align="center">Jogo de Plataforma 2D</h1>

<p align="center">
  Um platformer 2D em pixel art desenvolvido com Godot 4 e GDScript.
</p>

<p align="center">
  <code>Godot 4.7.1</code> · <code>GDScript</code> · <code>Em desenvolvimento</code>
</p>

<p align="center">
  <img src="docs/screenshots/gameplay.gif" alt="Gameplay na floresta mostrando o personagem e um bloco quebrável" width="720">
</p>

## Sobre o jogo

O jogador controla um pinguim por cenários com identidades e desafios diferentes. O projeto combina movimentação responsiva, exploração, inimigos, perigos ambientais e objetos interativos.

Atualmente existem três biomas conectados em um ciclo jogável:

1. **Floresta** — esqueletos, projéteis, lava e blocos quebráveis.
2. **Pradaria** — uma introdução mais tranquila à movimentação.
3. **Trópicos** — água, plataformas móveis e trechos de precisão.

## Mecânicas

- Movimento com aceleração e desaceleração.
- Pulo e múltiplos saltos configuráveis por fase.
- Agachamento e deslize.
- Interação e salto em paredes.
- Natação com física própria.
- Plataformas móveis com duração configurável.
- Blocos que quebram, caem e reaparecem após alguns segundos.
- Esqueletos com patrulha, detecção e ataque à distância.
- Sereia amigável patrulhando a área submersa da fase tropical.
- Lava, projéteis e outras áreas letais.
- Transição automática entre fases.
- Cenários com múltiplas camadas de paralaxe.
- Máquina de estados para controlar as ações do jogador.

## Cenários

<p align="center">
  <img src="docs/screenshots/grassland.png" alt="Fase de pradaria" width="31%">
  <img src="docs/screenshots/forest.png" alt="Fase de floresta" width="31%">
  <img src="docs/screenshots/tropic.png" alt="Fase tropical" width="31%">
</p>

## Controles

| Ação | Teclas |
| --- | --- |
| Mover para a esquerda | `A` ou `←` |
| Mover para a direita | `D` ou `→` |
| Pular / nadar | `W`, `↑` ou `Espaço` |
| Agachar / deslizar | `S` ou `↓` |
| Sentar / levantar | `3` ou automaticamente após 25 s parado |
| Animação de vitória (teste) | `4` |

## Como executar

### Pela Godot

1. Instale a **Godot 4.7.1**, versão utilizada no desenvolvimento.
2. Clone o repositório:

   ```bash
   git clone https://github.com/rafaelcairess/JogoPlataforma.git
   ```

3. No Gerenciador de Projetos da Godot, selecione **Importar**.
4. Escolha o arquivo `project.godot`.
5. Pressione `F5` para iniciar o jogo ou `F6` para executar a cena aberta.

Também é possível baixar o projeto como ZIP pelo GitHub e importar o `project.godot`. Não há dependências externas nem etapa adicional de compilação.

## Estrutura do projeto

```text
JogoPlataforma/
|-- entities/       # Jogador, inimigos e objetos reutilizáveis
|-- scene/          # Fases jogáveis
|-- scripts/        # Lógica de gameplay em GDScript
|-- sprites/        # Personagens, cenários e animações
|-- tiles/          # Terrenos, decorações, água e lava
|-- docs/           # Imagens e animações da documentação
`-- project.godot   # Configuração principal da Godot
```

## Estado do desenvolvimento

O projeto está em desenvolvimento. Entre os próximos passos estão o refinamento das fases, melhorias no ciclo de morte e reinício, novos objetos interativos e mais feedback visual e sonoro para as ações do jogador.

## Créditos e licença

Os assets de pixel art são de **GrafxKid** e foram disponibilizados sob a licença **CC0 1.0 Universal**. Consulte o arquivo [LICENSE dos assets](sprites/Seasonal%20Tilesets/LICENSE.txt) para mais informações.

A licença do código-fonte do projeto ainda não foi definida.
