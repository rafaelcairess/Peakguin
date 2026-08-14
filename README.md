<h1 align="center">Peakguin 🐧</h1> <p align="center"> Um jogo de plataforma 2D em pixel art, desenvolvido sozinho na Godot. </p> <p align="center"> <img src="https://img.shields.io/badge/Godot-4.7.1-478CBF?logo=godotengine&logoColor=white" alt="Godot 4.7.1"> <img src="https://img.shields.io/badge/GDScript-Language-355570" alt="GDScript"> <img src="https://img.shields.io/badge/status-em%20desenvolvimento-yellow" alt="Em desenvolvimento"> <img src="https://img.shields.io/badge/license-TBD-lightgrey" alt="Licença a definir"> </p> <p align="center"> <img src="docs/screenshots/penguin_sit.gif" alt="Pinguim sentado" width="108"> </p>
🐧 Sobre

Peakguin é meu primeiro jogo indie de plataforma 2D. O projeto está sendo desenvolvido inteiramente por mim — programação, level design, mecânicas, inimigos, interações e toda a montagem das fases, usando Godot e GDScript.

A ideia é um platformer relativamente curto (~3 horas de duração), passando por diferentes regiões e introduzindo novas mecânicas ao longo do caminho. Não quero que seja só uma sequência de plataformas: também pretendo trazer momentos de exploração e interação com personagens pelo mapa — como a sereia da fase tropical, que futuramente terá diálogos com o pinguim.

O projeto muda bastante conforme eu aprendo mais sobre desenvolvimento de jogos e testo novas ideias.

<p align="center"> <img src="docs/screenshots/world_tour.gif" alt="O pinguim atravessa inverno, floresta, pradaria e trópicos" width="640"> <br> <sub>Pradaria · Inverno · Floresta · Trópicos</sub> </p>
🗺️ Fases
Fase	Descrição
Pradaria	Área introdutória, usada para apresentar a movimentação básica.
Inverno	Plataformas em cenário congelado e montanhoso.
Floresta	Esqueletos, projéteis, lava e blocos interativos.
Trópicos	Plataformas, natação, caranguejos e área submersa com uma sereia.

As fases ainda não estão finalizadas e devem mudar bastante até uma versão completa do jogo.

🎮 Gameplay

Floresta — esqueletos, projéteis, lava e plataformas.

<p align="center"> <img src="docs/screenshots/forest_gameplay.gif" alt="O pinguim atravessa a floresta, enfrenta esqueletos e supera plataformas sobre a lava" width="640"> </p>

Movimentação — algumas das mecânicas disponíveis atualmente.

<p align="center"> <img src="docs/screenshots/tutorial_gameplay.gif" alt="O pinguim aprende movimentação, natação, escalada, plataformas e agachamento" width="640"> </p>

Área submersa — a fase tropical também tem exploração debaixo d'água.

<p align="center"> <img src="docs/screenshots/ocean_gameplay.gif" alt="O pinguim explora a superfície, nada entre caranguejos e encontra a sereia" width="640"> </p>
⚙️ Mecânicas implementadas

Movimentação e combate

Movimento com aceleração e desaceleração
Pulo e múltiplos saltos configuráveis
Agachamento e deslize
Interação e salto em paredes
Natação
Máquina de estados para as ações do personagem

Level design

Plataformas móveis
Blocos quebráveis
Blocos que caem e reaparecem
Lava, projéteis e outras áreas letais
Checkpoints e transição entre fases
Cenários com paralaxe

Inimigos e criaturas

Inimigos com patrulha
Esqueletos capazes de detectar e atacar o jogador
Caranguejos que detectam paredes e bordas

Sistemas e interface

Sistema de morte e respawn
Três corações de vida, com dano, cura e breve invulnerabilidade
HUD reformulada: fonte clássica em sprites, cronômetro persistente, moedas e vidas
Sistema de interação e diálogos (retratos, texto progressivo, caixas dinâmicas)
Moedas coletáveis e corações giratórios que recuperam vida
Poeira animada após corrida contínua
Tela inicial com seletor de fases, configurações e créditos
Cursores pixel art para mouse e botões da interface
NPCs (fase inicial de implementação)

Também há pequenas animações extras — se o pinguim ficar parado por um tempo, ele acaba sentando sozinho.

💬 NPCs e diálogos

A ideia é que, durante as fases, seja possível encontrar personagens e conversar com eles, dando mais vida ao mundo sem tirar o foco da plataforma. O sistema de diálogos, inspirado em clássicos de RPG e em Stardew Valley, já está funcional:

Detecção de áreas de interação ao redor do pinguim
Caixas de diálogo animadas na parte inferior da tela
Efeito "máquina de escrever" avançando o texto gradualmente
Retratos customizados e nome de quem está falando

A primeira personagem a usar esse sistema é a sereia da área submersa da fase tropical. Vale a pena se aproximar e interagir.

🎮 Controles
Ação	Teclas
Mover para a esquerda	A ou ←
Mover para a direita	D ou →
Pular / nadar	W, ↑ ou Espaço
Agachar / deslizar	S ou ↓
Sentar / levantar	3

Os controles ainda podem mudar durante o desenvolvimento.

🚩 Checkpoints

Quando o jogador ativa um checkpoint, a placa muda de aparência. Se o pinguim morrer depois disso, a fase recarrega e ele retorna ao último checkpoint alcançado — ou ao início da fase, se nenhum tiver sido ativado. Ao avançar para outra fase, o checkpoint anterior é descartado.

🚀 Como executar

Requer Godot 4.7.1.

bash
git clone https://github.com/rafaelcairess/JogoPlataforma.git
Abra a Godot
Clique em Importar
Selecione o arquivo project.godot
Abra o projeto
Pressione F5 para executar

Não há dependências externas adicionais no momento.

📁 Estrutura do projeto
text
JogoPlataforma/
├── entities/                   # Cenas que você arrasta para os níveis
│   ├── player/                 # Pinguim jogável
│   ├── enemies/                # Cogumelo, laranja e esqueletos
│   ├── creatures/               # Animais sem dano, como os caranguejos
│   ├── npcs/                   # NPCs, como a sereia
│   ├── pickups/                 # Moedas e corações prontos para arrastar
│   ├── gameplay/                # Checkpoint, câmera, plataformas e saída
│   └── projectiles/             # Projéteis reutilizáveis
├── scene/                      # Grassland, Forest, Tropic e Winter
├── tiles/                       # Terrain, Decoration, Water e Lava juntos
├── audio/
│   ├── music/                   # Músicas das fases
│   └── sfx/                     # Efeitos sonoros do player e do ambiente
├── effects/                     # Splash da água e poeira de corrida
├── scripts/                     # Código separado pelas mesmas categorias
├── sprites/                     # Sprites brutos e pacotes de arte
├── fonts/                       # Fontes usadas pelo jogo
├── themes/                      # Temas globais da interface
├── ui/                          # HUD, menu principal e menu de pausa
├── docs/                        # GIFs e imagens usados no README
└── project.godot
🚧 Roadmap

Peakguin ainda está no começo do desenvolvimento. Já existem várias mecânicas funcionando e algumas áreas jogáveis, mas falta bastante conteúdo até chegar ao jogo que tenho em mente.

 Expandir sistema de diálogos
 Mais NPCs
 Novos inimigos
 Mais fases e áreas
 Sons e músicas
 Interface e menus
 Melhorias nas animações
 Mais objetos interativos
 Refinamento das fases existentes
 Melhor equilíbrio de dificuldade
 Progressão que resulte em ~3 horas de jogo

Por ser um projeto solo (e meu primeiro jogo), não há previsão definida de conclusão. A prioridade é continuar aprendendo e evoluir aos poucos.

🙌 Créditos

Os assets de pixel art utilizados no projeto são de GrafxKid, disponibilizados sob a licença CC0 1.0 Universal (sprites/Seasonal Tilesets/LICENSE.txt).

Programação, montagem das fases, implementação das mecânicas e desenvolvimento geral são feitos por mim.

📄 Licença

A licença do código-fonte ainda não foi definida.
