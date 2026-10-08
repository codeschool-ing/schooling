---
title: A sua máquina, e três jeitos de ter uma
version: 1
---

Toda aula daqui em diante roda comandos num computador de verdade: programas pequenos que conferem as
respostas de um modelo e, em algumas aulas, um modelo de verdade escrevendo essas respostas. Esta seção
monta esse computador. A próxima monta o diretório em que toda aula trabalha.

A máquina precisa de três coisas:

- **um terminal Linux com Python 3**, para os programas que as aulas imprimem inteiros. Eles só usam a
  biblioteca do próprio Python, então não há pacote para instalar por causa deles;
- **o Ollama**, um programa gratuito que roda um modelo de linguagem no seu próprio computador, sem
  conta e sem cartão;
- **um modelo para ele, o `llama3.2:3b`**: o Llama 3.2 da Meta, com três bilhões de parâmetros, pequeno
  o bastante para um notebook comum. Todo curso de IA daqui usa o mesmo, então, se você o instalou para
  o `prompt-engineering`, já o tem.

## Três jeitos de ter uma

| caminho | o que você tem | quanto custa | as transcrições |
|---|---|---|---|
| **instalado** (recomendado) | Ubuntu 24.04 no seu computador, ou no WSL no Windows | uns 2 GB de disco para o modelo e 3 GB de memória enquanto ele responde | batem com o que está impresso |
| **uma máquina virtual** | Ubuntu Server 24.04, à parte do seu sistema | o mesmo, mais o sistema e a memória do convidado | batem com o que está impresso, mais devagar |
| **online** | uma máquina Linux alugada por hora | nada no seu computador; uma conta por hora | parecidas, não idênticas |

**Instalado é o caminho recomendado**, e o motivo é o modelo. Ele é de longe a coisa mais pesada do
curso, e roda mais rápido no computador sem intermediários. Uma máquina virtual reserva para si uma
fatia fixa da memória e, na maioria dos hipervisores, não alcança a placa de vídeo. O resto da
preparação é um diretório na sua pasta pessoal, que sai de novo com um `rm`.

- **No Linux**, rode os comandos abaixo. Eles foram rodados no Ubuntu 24.04; outra distribuição tem os
  mesmos programas com os nomes de pacote dela.
- **No Windows**, instale o WSL com o Ubuntu 24.04 (`wsl --install -d Ubuntu-24.04` num PowerShell
  aberto como administrador, e depois reinicie) e digite tudo o que vem abaixo na janela do Ubuntu.
- **No macOS**, o Ollama tem um aplicativo próprio em ollama.com, e o macOS já traz um Python 3 depois
  que as ferramentas de linha de comando estão instaladas (`xcode-select --install`). Isso não foi
  rodado para este curso, então uma versão numa transcrição vai ser diferente da sua, e os programas
  funcionam do mesmo jeito.

**Uma máquina virtual** é o caminho para um computador que você prefere não mexer. Use o Ubuntu Server
24.04 LTS como convidado: VirtualBox no Windows e no Linux, UTM no macOS. Dê a ela pelo menos 6 GB de
memória e 25 GB de disco, porque o modelo precisa de uns 3 GB dessa memória só para ele. Conte com
respostas mais lentas do que fora dela.

**Online**, qualquer provedor de nuvem aluga uma máquina Linux por hora, e o GitHub Codespaces dá uma
no navegador. Escolha uma com pelo menos 8 GB de memória. Uma cota gratuita pode cobrir parte do curso,
em termos que a empresa define e pode mudar, então planeje como se fosse pagar. Isso não foi rodado
para este curso.

## Instalando

Tudo o que vem abaixo é digitado num terminal na máquina que você escolheu. Primeiro os pacotes do
próprio Ubuntu:

```sh
sudo apt-get update
sudo apt-get install -y python3 curl zstd
```

Depois o Ollama, com o instalador que os autores dele publicam. Ele põe o programa em `/usr/local` e,
numa máquina que roda `systemd`, como o Ubuntu, o transforma num serviço que sobe junto com a máquina:

```sh
curl -fsSL https://ollama.com/install.sh | sh
```

Depois o modelo. Isto baixa 2,0 GB, uma vez:

```sh
ollama pull llama3.2:3b
```

Confira o que você tem:

```
ana@lab:~$ python3 --version; ollama --version
Python 3.12.3
ollama version is 0.40.0
ana@lab:~$ ollama list
NAME           ID              SIZE      MODIFIED       
llama3.2:3b    a80c4f17acd5    2.0 GB    56 minutes ago    
ana@lab:~$ ollama run llama3.2:3b "Say hello in five words."
Hello there, I'm here now.

ana@lab:~$ ollama ps
NAME           ID              SIZE      PROCESSOR          CONTEXT    RUNNER      UNTIL              
llama3.2:3b    a80c4f17acd5    2.9 GB    30%/70% CPU/GPU    4096       llamacpp    4 minutes from now    
```

O `ollama list` é o que está no disco, e o `ollama ps` é o que está na memória: o modelo é carregado na
primeira vez que alguém lhe faz uma pergunta, ocupa **2,9 GB** enquanto está carregado e é descarregado
cinco minutos depois da última pergunta. Esse é o número para comparar com o seu computador.

A coluna `PROCESSOR` diz onde o trabalho rodou. O computador em que estas aulas foram gravadas não tem
placa de vídeo, e o Ollama contou a unidade de matrizes do próprio processador como acelerador, por
isso não aparece `100% CPU`. No seu aparece `100% CPU`, ou a fatia que a sua placa de vídeo pegou.

### Com menos memória

Num computador com 8 GB de memória ou menos, use o modelo menor da mesma família:

```sh
ollama pull llama3.2:1b
```

Ele baixa 1,3 GB e ocupou 2,0 GB de memória na mesma máquina. As respostas dele são visivelmente piores,
e vão diferir mais das transcrições daqui. A próxima seção diz como apontar os programas do curso para
ele.

### Com uma chave de API

O outro caminho é um modelo pago, de um provedor que você escolher. O único programa deste curso que
conversa com um modelo fala chat completions, o protocolo que a maioria dos provedores serve, e três
variáveis o apontam para outro lugar; a próxima seção diz quais são. Toda requisição custa dinheiro.
**Nada no curso precisa disso.** O modelo local basta para terminar todas as aulas.
