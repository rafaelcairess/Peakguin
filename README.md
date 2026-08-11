<h1 align="center">🐧 Peakguin</h1>

<p align="center">
  <strong>Um platformer 2D em pixel art desenvolvido na Godot.</strong>
</p>

<p align="center">
  Explore diferentes biomas, domine novas formas de movimentação e ajude um pequeno pinguim a atravessar um mundo cheio de plataformas, inimigos e perigos.
</p>

<p align="center">
  <code>Godot 4.7.1</code> · <code>GDScript</code> · <code>Pixel Art</code> · <code>2D Platformer</code> · <code>Em desenvolvimento</code>
</p>

<p align="center">
  <img src="docs/screenshots/penguin_sit.gif" alt="Pinguim sentado" width="108">
</p>

<p align="center">
  <sub>Até os heróis precisam descansar antes da próxima aventura.</sub>
</p>

---

## 🎮 Sobre Peakguin

**Peakguin** é meu primeiro jogo indie de plataforma 2D, criado com **Godot Engine** e **GDScript**.

O jogador controla um pequeno pinguim durante uma jornada por diferentes ambientes, cada um apresentando novos obstáculos, inimigos e mecânicas.

O projeto começou como parte do meu aprendizado em desenvolvimento de jogos e evoluiu para um projeto autoral no qual desenvolvo a **programação, os sistemas de gameplay, a construção das fases, as interações e o level design**.

A proposta é explorar diferentes formas de movimentação ao longo das fases, fazendo com que o jogador não apenas pule entre plataformas, mas também nade, deslize, interaja com paredes, utilize plataformas móveis e enfrente diferentes tipos de perigos.

<p align="center">
  <img src="docs/screenshots/world_tour.gif" alt="O pinguim atravessa inverno, floresta, pradaria e trópicos" width="640">
</p>

<p align="center">
  <sub>Uma jornada por Pradaria · Inverno · Floresta · Trópicos</sub>
</p>

---

## 🌎 Biomas

Peakguin possui atualmente quatro ambientes principais em desenvolvimento.

### 🌱 Pradaria

Uma região mais tranquila que apresenta ao jogador os fundamentos de movimentação e plataforma.

É onde as principais mecânicas começam a ser introduzidas antes que os desafios se tornem mais complexos.

### ❄️ Inverno

Montanhas, neve e plataformas em um cenário congelado que combina naturalmente com o protagonista.

A fase amplia os desafios de movimentação e verticalidade.

### 🌲 Floresta

Uma área mais perigosa, com inimigos, ataques à distância, blocos interativos, lava e sequências maiores de plataforma.

### 🌴 Trópicos

Uma região que mistura plataforma tradicional com exploração aquática.

O jogador pode entrar na água e utilizar um sistema próprio de natação enquanto encontra novos personagens, inimigos e obstáculos.

---

# 🎥 Gameplay

## ⚔️ Combate e plataformas

<p align="center">
  <img src="docs/screenshots/forest_gameplay.gif" alt="O pinguim atravessa a floresta, enfrenta esqueletos e supera plataformas sobre a lava" width="640">
</p>

<p align="center">
  <sub>Esqueletos, projéteis, lava e plataformas durante a travessia pela floresta.</sub>
</p>

## 🐧 Movimentação

<p align="center">
  <img src="docs/screenshots/tutorial_gameplay.gif" alt="O pinguim aprende movimentação, natação, escalada, plataformas e agachamento" width="640">
</p>

<p align="center">
  <sub>Diferentes mecânicas de movimentação são introduzidas progressivamente durante as fases.</sub>
</p>

## 🌊 Exploração subaquática

<p align="center">
  <img src="docs/screenshots/ocean_gameplay.gif" alt="O pinguim explora a superfície, nada entre caranguejos e encontra a sereia" width="640">
</p>

<p align="center">
  <sub>A exploração continua debaixo d'água, com movimentação própria, inimigos e NPCs.</sub>
</p>

---

# ✨ Mecânicas

Peakguin possui diferentes sistemas de gameplay implementados em GDScript.

### 🏃 Movimentação do jogador

* Movimento horizontal com aceleração e desaceleração.
* Pulo.
* Quantidade de saltos configurável de acordo com a fase.
* Agachamento.
* Deslize.
* Interação e salto em paredes.
* Sistema próprio de movimentação dentro da água.
* Diferentes estados de queda e movimentação aérea.

### 🎭 Estados e animações

O personagem utiliza uma **máquina de estados** para organizar suas diferentes ações e comportamentos.

Entre os estados existentes estão:

* Idle.
* Walk.
* Jump.
* Fall.
* Duck.
* Slide.
* Swimming.
* Dead.
* Victory.

O personagem também possui animações contextuais de espera, podendo sentar automaticamente após permanecer parado por determinado tempo.

### 💀 Inimigos

O projeto possui diferentes comportamentos de inimigos.

**Esqueletos**

* Patrulha automática.
* Detecção do jogador.
* Ataques à distância.
* Uso de projéteis.

**Caranguejos**

* Patrulha lateral.
* Detecção de paredes.
* Detecção de bordas da plataforma.
* Mudança automática de direção.

### 🧱 Objetos interativos

* Plataformas móveis.
* Blocos quebráveis.
* Blocos que caem.
* Objetos que reaparecem após determinado período.
* Áreas letais.
* Checkpoints.
* Transições entre fases.

### 🌋 Perigos ambientais

O jogador pode encontrar diferentes obstáculos durante as fases, incluindo:

* Lava.
* Projéteis.
* Inimigos.
* Quedas.
* Áreas letais.
* Plataformas temporárias.

---

# 🚩 Sistema de checkpoints

As fases possuem um sistema de checkpoints que registra o último ponto alcançado pelo jogador.

Quando um checkpoint é ativado, ele muda visualmente para indicar seu novo estado.

Caso o jogador morra, a fase é reiniciada e o personagem retorna ao último checkpoint ativado naquela fase.

Se nenhum checkpoint tiver sido alcançado, o jogador retorna ao ponto inicial.

Ao avançar para outra fase, o checkpoint da fase anterior é descartado.

---

# 🎮 Controles

| Ação                  | Teclas               |
| --------------------- | -------------------- |
| Mover para a esquerda | `A` ou `←`           |
| Mover para a direita  | `D` ou `→`           |
| Pular                 | `W`, `↑` ou `Espaço` |
| Nadar                 | `W`, `↑` ou `Espaço` |
| Agachar / deslizar    | `S` ou `↓`           |
| Sentar / levantar     | `3`                  |

Algumas ações também podem acontecer automaticamente dependendo do estado atual do personagem.

---

# 🛠️ Tecnologias

O projeto é desenvolvido utilizando:

* **Godot Engine 4.7.1**
* **GDScript**
* **Git**
* **GitHub**

Entre os recursos da Godot utilizados no projeto estão:

* `CharacterBody2D`
* `Area2D`
* `CollisionShape2D`
* `AnimatedSprite2D`
* `TileMap`
* `Parallax2D`
* Sistema de cenas
* Sistema de sinais
* Grupos de nós
* Física 2D
* Máquina de estados
* Cenas reutilizáveis

---

# 🧠 Desenvolvimento

Um dos principais objetivos do projeto é utilizar Peakguin como experiência prática para estudar arquitetura e desenvolvimento de jogos.

Durante o desenvolvimento foram trabalhados conceitos como:

* Separação de responsabilidades entre scripts.
* Reutilização de cenas.
* Comunicação entre nós.
* Uso de sinais.
* Gerenciamento de estados.
* Física e movimentação 2D.
* Detecção de colisões.
* Inteligência e comportamento básico de inimigos.
* Construção e transição de fases.
* Level design.
* Sistemas de respawn.
* Organização de assets.
* Animação de personagens.
* Paralaxe e composição de cenários.

O projeto continua sendo expandido conforme novos sistemas e conceitos são estudados e implementados.

---

# 📁 Estrutura do projeto

```text
JogoPlataforma/
│
├── entities/       # Jogador, inimigos e objetos reutilizáveis
├── scene/          # Fases e cenas jogáveis
├── scripts/        # Sistemas e lógica de gameplay
├── sprites/        # Sprites, personagens e animações
├── tiles/          # Tilesets, terrenos e elementos dos cenários
├── docs/           # GIFs e imagens utilizadas na documentação
│
└── project.godot   # Configuração principal do projeto
```

A estrutura continua sendo reorganizada conforme o projeto cresce.

---

# ▶️ Executando o projeto

## Requisitos

* **Godot Engine 4.7.1**

Não existem dependências externas adicionais para executar o projeto dentro da Godot.

## Clonando o repositório

```bash
git clone https://github.com/rafaelcairess/JogoPlataforma.git
```

Depois de clonar:

1. Abra a **Godot Engine**.
2. Selecione **Importar** no Gerenciador de Projetos.
3. Navegue até a pasta clonada.
4. Selecione o arquivo `project.godot`.
5. Abra o projeto.
6. Pressione `F5` para executar o jogo.

Também é possível baixar o projeto como ZIP diretamente pelo GitHub e importar o arquivo `project.godot`.

---

# 🚧 Estado do desenvolvimento

> **Peakguin está em desenvolvimento ativo.**

O projeto ainda não representa uma versão final do jogo. Mecânicas, fases, animações e estruturas internas podem mudar durante o desenvolvimento.

### Já implementado

* [x] Movimentação básica.
* [x] Pulo.
* [x] Múltiplos saltos.
* [x] Agachamento.
* [x] Deslize.
* [x] Interação com paredes.
* [x] Máquina de estados do jogador.
* [x] Sistema de natação.
* [x] Plataformas móveis.
* [x] Blocos interativos.
* [x] Inimigos com patrulha.
* [x] Inimigos com ataque à distância.
* [x] Áreas letais.
* [x] Sistema de morte e respawn.
* [x] Checkpoints.
* [x] Transição entre fases.
* [x] Cenários com paralaxe.
* [x] Diferentes biomas.

### Próximos objetivos

* [ ] Refinar as fases existentes.
* [ ] Expandir o comportamento dos inimigos.
* [ ] Adicionar novos tipos de inimigos.
* [ ] Criar mais objetos interativos.
* [ ] Melhorar feedback visual das ações.
* [ ] Adicionar efeitos sonoros.
* [ ] Adicionar música.
* [ ] Refinar animações.
* [ ] Melhorar as transições entre áreas.
* [ ] Criar menus e interface do jogo.
* [ ] Balancear progressão e dificuldade.
* [ ] Finalizar as fases principais.

---

# 🎨 Assets

Os assets de pixel art utilizados em Peakguin foram criados por **GrafxKid** e disponibilizados sob a licença **CC0 1.0 Universal**.

Mais informações podem ser encontradas no arquivo:

[`sprites/Seasonal Tilesets/LICENSE.txt`](sprites/Seasonal%20Tilesets/LICENSE.txt)

A programação, implementação dos sistemas, montagem das fases e desenvolvimento do gameplay de Peakguin são realizados por mim.

---

# 📜 Licença

Os assets externos utilizados possuem suas respectivas licenças descritas na seção de créditos.

A licença do código-fonte de Peakguin ainda não foi definida.

---

<p align="center">
  🐧 <strong>Peakguin</strong>
</p>

<p align="center">
  Meu primeiro passo no desenvolvimento de jogos.
</p>
