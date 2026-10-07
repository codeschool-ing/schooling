---
title: O seu laboratório, e três maneiras de ter um
version: 1
---

**Toda aula deste curso executa alguma coisa**: uma suíte de testes, uma CI que responde a um push,
um deploy, um canário que para uma versão ruim. Você executa também, numa máquina sua, e nada aqui
precisa de mais de uma. Esta seção diz do que essa máquina precisa e três maneiras de tê-la. A
próxima monta o projeto em que todas as aulas trabalham, e a seguinte diz o que fazer quando a
montagem dá errado.

O laboratório é um computador Linux com quatro coisas:

- **git, curl e jq**, dos pacotes do próprio Ubuntu: o git para o histórico do projeto e a CI da
  aula 5, o curl para falar com o programa por HTTP, o jq para ler JSON na aula 6;
- **uv**, uma ferramenta que cria ambientes virtuais de Python e instala versões de Python. A CI da
  aula 5 roda a suíte em Python 3.11, 3.12 e 3.13, e o uv busca qualquer uma delas que não
  encontrar;
- **Python 3.13** num ambiente virtual dentro do projeto, com três bibliotecas fixadas nas versões
  com que as transcrições foram gravadas: pytest, coverage e Hypothesis;
- **o próprio projeto**, `shipquote`, que a próxima seção monta.

Mais nada. O `shipquote` usa só a biblioteca padrão do Python. A transportadora a que ele pede
preços é um pequeno servidor que você escreve na aula 2, e a CI da aula 5 é um script que você
escreve num repositório git. Os "ambientes" das aulas 7 a 11 são diretórios e processos nesta
mesma máquina. A aula 6 acrescenta duas ferramentas opcionais e diz como instalá-las ali.

## Três maneiras de ter um

| caminho | o que você ganha | quanto custa | as transcrições |
|---|---|---|---|
| **uma máquina virtual** (recomendado) | um Ubuntu Server 24.04, separado do seu sistema | alguns gigabytes de disco, e 2 GB de memória enquanto roda | batem como impressas |
| **instalado** | as mesmas ferramentas no computador que você já usa | uns 75 MB na sua pasta pessoal, mais cada Python que o uv baixar | batem no Ubuntu 24.04; perto disso nos outros |
| **online** | uma máquina Linux no navegador | nada no seu computador; horas de uma cota mensal | perto, não exatas |

**A máquina virtual é o caminho recomendado.** Da aula 7 em diante, o curso sobe e derruba
servidores em uma dúzia de portas entre 8080 e 9092, e grava versões em `~/envs`; num computador
em que você também trabalha, isso colide com o que mais estiver rodando ali. Os scripts se apoiam
em ferramentas do Linux como `setsid` e `sha256sum`, que um Mac não tem com esses nomes. E um
snapshot da máquina tirado quando a montagem funciona dá um recomeço limpo sempre que um
experimento der errado. Use o hipervisor que combina com o seu computador: VirtualBox no Windows
ou no Linux, UTM num Mac com Apple silicon, Hyper-V no Windows se ele estiver ligado, com uma
imagem do Ubuntu Server 24.04 baixada de ubuntu.com. A aula 4 do `virtualization` monta uma no
VirtualBox passo a passo. No Windows, o WSL rodando Ubuntu 24.04 também é uma máquina virtual, e
funciona do mesmo jeito.

**Instalado** serve num computador que já roda Ubuntu 24.04, com os mesmos comandos. Em outro
Linux os nomes dos pacotes podem mudar. Num Mac, o git e o curl vêm com as ferramentas de
desenvolvedor de linha de comando da Apple, e o uv e o jq se instalam com o Homebrew. As seis
primeiras aulas não pedem nada específico do Linux; as aulas 7 a 11 precisam das ferramentas do
Linux citadas acima, e esse é o motivo para usar a máquina virtual ali. Nada disso foi executado para
este curso, então um caminho ou uma versão numa transcrição pode diferir do seu.

**Online**, o GitHub Codespaces dá uma máquina Linux com um terminal no navegador. Não custa nada ao
seu computador; o GitHub dá às contas pessoais uma cota mensal de horas e cobra o que passar dela,
em termos que ele define e pode mudar. Não foi executado para este curso. Qual Linux um codespace
roda decide se os comandos abaixo funcionam como impressos, e `cat /etc/os-release` diz isso antes
de você começar.

## Montando

Tudo abaixo é digitado num terminal na máquina que você escolheu. Primeiro os pacotes do próprio
sistema:

```sh
sudo apt-get update
sudo apt-get install -y git curl jq pipx
```

O `pipx` instala um programa Python num diretório só dele e põe o comando em `~/.local/bin`. É
assim que o uv entra, sem tocar no Python em que o próprio Ubuntu roda:

```sh
pipx install uv
pipx ensurepath
```

O `pipx ensurepath` acrescenta `~/.local/bin` ao seu `PATH` no `~/.bashrc`, que um terminal lê
quando abre. **Então feche o terminal e abra outro** antes de seguir; o antigo não sabe onde está o
`uv`. No novo, as três ferramentas respondem:

```
ana@laptop:~$ uv --version
uv 0.12.23 (x86_64-unknown-linux-gnu)
ana@laptop:~$ git --version
git version 2.43.0
ana@laptop:~$ jq --version
jq-1.7
```

O seu uv pode ser mais novo que este; qualquer um da 0.11 em diante se comporta igual para este
curso.

Por último, o git precisa saber quem está fazendo os commits, uma vez por máquina. Use o seu nome e
o seu endereço; as transcrições aqui usam os de Ana, a desenvolvedora de cujo terminal elas vêm:

```sh
git config --global user.name "Ana Lima"
git config --global user.email ana@example.org
git config --global init.defaultBranch main
```

A terceira linha dá o nome `main` ao primeiro branch de todo repositório novo, que é como o curso
inteiro o chama.

## O que as transcrições imprimem

Toda transcrição do curso foi gravada no Ubuntu 24.04 e mostra o prompt `ana@laptop:~/shipquote$`.
O seu mostra o seu usuário e a sua máquina e, enquanto um ambiente virtual está ativo, `(.venv)` na
frente, que as transcrições omitem. Os hashes dos commits e os de um artefato construído são
diferentes em cada máquina, porque dependem de quem fez o commit e de quando; todo o resto, nomes
de testes, contagens, preços e mensagens de erro, deve bater com o que você vê.
