---
title: Seu laboratório, e três jeitos de ter um
version: 1
---

**Toda aula deste curso roda alguma coisa numa máquina sua**: uma bilheteria sob carga, um banco
com uma réplica, cinco bancos diferentes um depois do outro, um sistema de rastreamento, uma
ferramenta de teste de carga. Nada é hospedado para você. Esta seção diz o que essa máquina precisa
ter e dá três jeitos de ter uma; a próxima monta o projeto que todas as aulas medem, e a seguinte
diz o que fazer quando a montagem dá errado.

O laboratório é **um computador Linux com Docker**. Todo banco e todo servidor do curso roda num
contêiner, então a lista do que instalar é curta:

- **Docker Engine e o plugin Compose**, que rodam todos os bancos, a bilheteria e as ferramentas
  das aulas 7, 8 e 12;
- **Python 3**, para o gerador de carga que você escreve na seção 04 e para os programinhas das
  aulas 3, 10 e 11. O Ubuntu já tem;
- **curl**, para conversar com a bilheteria à mão. O Ubuntu também já tem.

O que ela precisa do computador por baixo é a parte a planejar:

| | mínimo | recomendado | por quê |
|---|---|---|---|
| processadores | 2 | **4** | as seções 07 e 08 dão à bilheteria 1, 2 e 4 processadores, e o gerador de carga precisa de algum para si |
| memória | 6 GB | **8 GB** | a aula 5 roda Cassandra e Neo4j, que querem de 1 a 2 GB cada, um de cada vez |
| disco | 25 GB | **40 GB** | as imagens do curso somam uns 6 GB, e os bancos gravam dados próprios |

Com dois processadores toda aula continua funcionando, e as seções 07 e 08 mostram menos, porque há
menos para dar. As aulas dizem onde isso muda um número.

## Três jeitos de ter um

| caminho | o que você ganha | quanto custa | as transcrições |
|---|---|---|---|
| **uma máquina virtual** (recomendado) | Ubuntu Server 24.04, separado do seu sistema | a memória e os processadores que você der a ela, enquanto roda; 40 GB de disco | iguais ao impresso |
| **instalado** | Docker no computador que você já usa | o espaço do próprio Docker, e portas e processadores divididos com tudo o mais que você roda | parecidas; diferentes no macOS e no Windows onde indicado |
| **online** | uma máquina Linux no navegador | nada no seu computador; horas de uma cota mensal | parecidas, não idênticas |

**A máquina virtual é o caminho recomendado**, por três motivos que pesam neste curso em
particular. Medir é o assunto inteiro, e uma máquina virtual tem um número fixo de processadores
que nada mais no seu computador está usando; um notebook com um navegador e uma videochamada
abertos mede também o navegador e a chamada. A aula 5 sobe bancos que querem um ou dois gigabytes
cada, e é mais fácil esquecer deles numa máquina que você pode desligar. E um snapshot tirado
quando a montagem funciona dá um recomeço limpo sempre que um experimento deixa bagunça.

Use o hipervisor que combina com o seu computador: VirtualBox no Windows ou no Linux, UTM num Mac
com Apple silicon, Hyper-V no Windows se estiver ligado, com uma imagem do Ubuntu Server 24.04 de
ubuntu.com. A aula 4 de `virtualization` monta uma no VirtualBox passo a passo. Dê a ela os
processadores e a memória da tabela acima, e chame a máquina de `lab`; o prompt das transcrições é
`ana@lab`, e o seu terá o seu nome de usuário.

**Instalado** quer dizer Docker no computador que você usa todo dia. No Linux é o Docker Engine,
igual ao da máquina virtual. No Windows e no macOS é o Docker Desktop, que roda por trás uma
pequena máquina virtual Linux própria; ele é gratuito para uso pessoal e para empresas pequenas
nos termos do Docker, que o Docker define e pode mudar. Tudo no curso funciona ali, com duas
diferenças que vale saber: os processadores que o Docker pode usar são definidos nas configurações
do Docker Desktop, não pelo computador, e `localhost` dentro de um contêiner é o próprio contêiner
em qualquer sistema, coisa de que o curso nunca depende. Nada deste caminho foi rodado para este
curso.

**Online**, o GitHub Codespaces dá uma máquina Linux com Docker já instalado e um terminal no
navegador. Não custa nada ao seu computador; o GitHub dá às contas pessoais uma cota mensal de
horas e cobra além dela, em termos que ele define e pode mudar. O tamanho da máquina é escolhido
quando ela é criada, e a aula 5 quer a memória da tabela acima. Ele não foi rodado para este curso.

## Montando

Na máquina virtual, ou no Ubuntu, tudo abaixo é digitado num terminal.

**Se você fez `docker`**, a aula 6 de lá instalou o Docker Engine pelo repositório do próprio
Docker, e é exatamente isso que este curso precisa; pule para a conferência no fim desta seção. Foi
também assim que a máquina onde as transcrições foram gravadas foi montada.

Senão, o caminho mais curto são os pacotes do próprio Ubuntu:

```sh
sudo apt-get update
sudo apt-get install -y docker.io docker-compose-v2 python3 curl
```

O Docker do Ubuntu é um pouco mais antigo que o do próprio Docker e faz as mesmas coisas para este
curso. Ele não foi rodado para este curso; se algum comando aqui se comportar diferente, a aula 6
de `docker` tem o outro caminho, passo a passo.

Depois deixe seu usuário falar com o Docker sem `sudo`, entrando no grupo dono do socket do Docker:

```sh
sudo usermod -aG docker $USER
```

Um grupo é lido quando você entra na sessão, então **saia e entre de novo**, ou feche o terminal e
reabra a conexão com a máquina virtual. Estar no grupo `docker` equivale a ser root naquela
máquina, o que é mais um motivo para fazer isso numa máquina virtual e não no seu próprio
computador.

## A conferência

Três comandos, e três respostas:

```
ana@lab:~/tickets$ docker --version
Docker version 29.8.2, build 7fc2dff
ana@lab:~/tickets$ docker compose version
Docker Compose version v5.6.0
ana@lab:~/tickets$ python3 --version
Python 3.13.16
```

A sua versão do Docker pode ser mais antiga ou mais nova; qualquer uma a partir da 25 se comporta
igual aqui. O Python que imprimiu `3.13.16` acima é o da máquina de gravação; o Ubuntu 24.04
imprime `3.12.3`, e os programas do curso rodam em qualquer Python a partir do 3.10.
