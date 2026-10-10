---
title: Seu laboratório, e três jeitos de ter um
version: 1
---

Este curso se aprende destruindo bancos de dados, e **a plataforma não te dá um para destruir**.
Tudo o que você digita nele roda numa máquina sua, montada nesta lição e ampliada nas seguintes.
Isso não é uma lacuna do curso. Montar o ambiente é a primeira coisa que este trabalho pede, e um
servidor que você mesmo configurou é o único tipo que você tem permissão para matar.

O que você precisa é de **um computador com Ubuntu 24.04 e vários servidores PostgreSQL nele**. O
empacotamento do Ubuntu deixa uma máquina rodar muitos servidores independentes, cada um com sua
porta, seu diretório de dados e seu log, e foi assim que cada transcrição do curso foi gravada: um
primário na porta 5432, um segundo servidor na 5433 quando a lição 2 precisa de um lugar para
restaurar, e mais três que o Patroni roda a partir da lição 16. As lições seguintes instalam as
ferramentas de que precisam, o pgBackRest na lição 5 e Patroni, etcd, HAProxy e PgBouncer quando
chegar a vez deles, cada um com o comando que faz isso.

## O que uma máquina só não consegue mostrar

Vários servidores num mesmo computador dividem um disco, um relógio e uma placa de rede, então
algumas falhas não conseguem acontecer com um deles sem acontecer com todos. Um disco morrendo
debaixo de um servidor, ou um cabo cortado entre dois prédios, são coisas que este laboratório
**simula** parando um processo ou bloqueando uma porta, e as lições que fazem isso avisam. Todo o
resto (uma queda, um arquivo corrompido, uma tabela apagada, uma réplica que fica para trás, dois
servidores que acreditam estar no comando) é real aqui.

## Numa máquina virtual: o caminho recomendado

Uma **máquina virtual** é um computador inteiro simulado dentro do seu, com sistema operacional
próprio, que você pode quebrar e jogar fora sem mexer em mais nada. Neste curso isso importa mais do
que nunca: você vai apagar diretórios de dados, matar servidores no meio de uma escrita e encher um
disco de write-ahead log, e nada disso deveria acontecer no computador em que você trabalha.

O programa que roda a máquina é um **hipervisor**:

| seu computador | hipervisor | custo |
|---|---|---|
| Windows, Linux, ou um Mac com processador Intel | VirtualBox, em virtualbox.org | grátis |
| um Mac com Apple silicon (M1 em diante) | UTM, em mac.getutm.app | grátis |

1. Instale o hipervisor e baixe a imagem do instalador do **Ubuntu Server 24.04 LTS** em
   ubuntu.com. No Apple silicon pegue a versão ARM; em todo o resto, a marcada `amd64`.
2. Crie uma máquina com ela, com **2 processadores, 4 GB de memória e um disco de 25 GB**.
3. Ligue a máquina e aceite os padrões do instalador. Ele pede seu nome, um nome para o servidor e
   um nome de usuário; escolha nomes de que você vá se lembrar.
4. Quando ela reiniciar, faça login. Você está num prompt como `ana@vm:~$`, e a próxima seção começa
   ali.

**O que isso custa ao seu computador:** 4 GB de memória enquanto a máquina roda, e até 25 GB de
disco, a maior parte sem uso até a lição 2 montar um banco grande para cronometrar uma restauração.
Se o seu computador tem 8 GB no total, feche o que puder enquanto a máquina roda; com menos que
isso, siga um dos outros dois caminhos.

> **Seu prompt não vai dizer `ana@vm`.** Neste curso `ana` é a usuária e `vm` é a máquina; no seu,
> são os nomes que você escolheu no passo 3. Todos os comandos são os mesmos.

Um hipervisor também consegue tirar um **snapshot** da máquina inteira: salvar o estado exato dela e
voltar a ele em um segundo. Tire um ao final desta lição. É o seguro mais barato que este curso
oferece, e é um backup do tipo que a lição 3 explica, então até lá você vai saber o que ele protege
e o que não protege.

## Instalado direto no seu computador

Se o seu computador **já roda Ubuntu 24.04 ou Debian 12**, os comandos deste curso funcionam nele
como estão impressos e você não precisa de máquina virtual. No **Windows**, o WSL 2 roda o Ubuntu
24.04 dentro do Windows (`wsl --install -d Ubuntu-24.04` num PowerShell de administrador) e te dá os
mesmos pacotes; o curso não foi gravado ali, então espere pequenas diferenças no jeito como os
serviços sobem.

Em qualquer dos dois casos, tudo o que você destruir está no computador que você usa para todo o
resto. Esse é o custo real deste caminho, e o motivo de ele não ser o recomendado.

No **macOS** não há caminho instalado: o Postgres.app e o Homebrew instalam o PostgreSQL, mas nenhum
dos dois tem as ferramentas do Ubuntu para rodar vários servidores, e a maioria dos comandos deste
curso não existiria. Use o UTM.

## Online, no computador de outra pessoa

Qualquer provedor de nuvem te aluga uma pequena **máquina virtual com Ubuntu 24.04**, e você se
conecta a ela com `ssh` e digita exatamente o que este curso mostra. Não custa nada ao seu
computador e custa dinheiro por hora. Escolha 2 processadores e 4 GB, **apague a máquina quando
terminar uma sessão**, e recrie a partir de um snapshot na próxima vez. Nunca abra as portas do
PostgreSQL dela para a internet; você chega nelas de dentro da máquina, como o curso faz.

Alguns provedores oferecem alguns meses de uma máquina pequena de graça. Use se houver, e não faça
planos em cima disso: ofertas grátis mudam de termos, e nada neste curso depende das de nenhuma
empresa.

Um **serviço gerenciado de PostgreSQL** não é um quarto caminho. Ele te dá um banco e guarda para si
o servidor, os arquivos dele e a replicação, que é exatamente o assunto deste curso. A lição 21 é
sobre o que um serviço assim promete, e é a única lição que você poderia fazer ali.

## Qual escolher

A máquina virtual. Custa uma tarde, uma vez, é o único caminho em que quebrar coisas não custa nada,
e quando a sua tela e uma transcrição discordam isso quer dizer que a diferença está no que você
digitou, e não no sistema em que você está.
