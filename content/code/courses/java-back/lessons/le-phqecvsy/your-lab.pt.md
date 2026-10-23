---
title: Uma máquina para este curso, e três jeitos de ter uma
version: 1
---

Este curso se aprende construindo. Cada aula mostra um comando e o que voltou, e o motivo de
mostrar o que voltou é você rodar o mesmo comando e comparar. Então, antes do Maven, uma máquina.
**A plataforma não roda nada por você**: o JDK, o Maven e, mais adiante, o PostgreSQL e o Docker
são instalados por você, num computador que você controla, e toda transcrição deste curso foi
gravada num computador assim.

Esse computador é um **Ubuntu 24.04** com **OpenJDK 25** e **Maven 3.8.7**, os dois do repositório
do próprio Ubuntu. Há três jeitos de ter um. Um é o recomendado, e os outros dois são opções reais
com custos que o primeiro não tem.

## Numa máquina virtual — o caminho recomendado

Uma **máquina virtual** é um computador inteiro simulado dentro do seu, com sistema operacional
próprio, que você pode quebrar e jogar fora sem mexer em mais nada. Rode o **Ubuntu Server 24.04
LTS** numa delas e instale as ferramentas pelos pacotes do Ubuntu, e você tem o sistema em que
este curso foi gravado: o que você vê deve bater com as transcrições em tudo, menos nos tempos, em
alguns números de build e no nome do prompt.

O programa que roda a máquina é um **hipervisor**, e qual usar depende do seu computador:

| seu computador | hipervisor | custo |
|---|---|---|
| Windows, Linux, ou um Mac com processador Intel | VirtualBox, em virtualbox.org | grátis |
| um Mac com Apple silicon (M1 em diante) | UTM, em mac.getutm.app | grátis |

Os passos, uma vez só:

1. Instale o hipervisor e baixe a imagem de instalação do Ubuntu Server 24.04 LTS em ubuntu.com.
   No Apple silicon pegue a versão ARM; em qualquer outro lugar, a marcada como `amd64`.
2. Crie uma máquina nova a partir dessa imagem com **2 processadores, 4 GB de memória e um disco
   de 30 GB**. Mais de qualquer um deixa builds e testes mais rápidos, e nada no curso precisa de
   mais.
3. Inicie a máquina e aceite os padrões do instalador. Ele pede seu nome, um nome para o servidor
   e um nome de usuário. Escolha nomes que você vai lembrar, porque vai digitar o usuário todo dia.
4. Quando ela reiniciar, entre com esse usuário e senha. Você está num prompt como `ana@vm:~$`, e a
   próxima seção começa dali.

**O que isso custa ao seu computador**, e por que os números são maiores do que um primeiro curso
de Java precisa. O JDK e o Maven ocupam uns 400 MB instalados. As bibliotecas que o Maven baixa
para os projetos deste curso ocupam mais algumas centenas de megabytes na sua pasta pessoal. A
aula 9 acrescenta o PostgreSQL, e a aula 19 acrescenta o Docker, que roda um PostgreSQL de verdade
num container para os testes e guarda as imagens dele no disco. Uma aplicação Spring Boot, um banco
de dados e uma execução de testes lado a lado são o motivo dos 4 GB de memória.

> **O seu prompt não vai dizer `ana@vm`.** Neste curso `ana` é a usuária e `vm` é a máquina; no
> seu são os nomes que você escolheu no passo 3. Todo comando é igual.

## Instalado direto no seu computador

Se o seu computador **já roda Ubuntu 24.04**, pule a máquina virtual: os comandos da próxima seção
funcionam nele exatamente como estão escritos, e este é o caminho mais barato que existe. Outra
versão do Ubuntu, ou o Debian, pode não ter os mesmos nomes de pacote, e `apt search openjdk` diz
quais ela tem.

No **macOS** e no **Windows**, há builds do OpenJDK 25 e do Maven — o Eclipse Temurin, em
adoptium.net, é um JDK comum, o Maven vem de maven.apache.org, e o Homebrew instala os dois no Mac.
O que você recebe é um Maven mais novo que o 3.8.7, e isso muda parte do que esta aula imprime: a
seção sobre plugins mostra um build que falha por causa de qual Maven está rodando, e num Maven
mais novo esse build pode passar. Os comandos da aula 9 em diante, que instalam o PostgreSQL e o
Docker do jeito do Ubuntu, também não vão valer como estão escritos.

## Online, num ambiente de desenvolvimento na nuvem

Um **ambiente de desenvolvimento na nuvem** é uma máquina Linux no data center de outra empresa,
que você acessa pelo navegador, com editor e terminal. O GitHub Codespaces é um deles no momento em
que este texto é escrito, com uma cota mensal gratuita. **Não custa nada ao seu computador**, e
exige uma conta e uma conexão.

Use-o para começar se os outros dois estiverem fora de alcance hoje, e planeje mudar. O sistema
operacional da máquina e o Java que vem instalado são escolha do provedor, então os comandos de
instalação podem precisar de ajuste; cotas gratuitas são uma oferta de uma empresa, e ofertas mudam;
e a aula 19 roda containers, o que um ambiente online permite ou não a critério do dono. Nenhuma
aula deste curso depende de provedor nenhum.

## Qual escolher

A máquina virtual, a não ser que o seu computador já rode Ubuntu 24.04. Ela custa uma tarde, uma
vez, e compra a propriedade que os outros não têm: **quando a sua tela e a transcrição discordam, a
diferença está no que você digitou**, e não em qual sistema você está.
