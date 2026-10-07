---
title: Onde você vai digitar — três jeitos de ter o Git
version: 1
---

Da próxima seção em diante, este curso se aprende digitando. Cada aula mostra um comando e o que
voltou, e você roda o mesmo comando e compara. **A plataforma não roda o Git por você.** Você
precisa de um terminal com o Git, numa máquina que você controla, e há três jeitos de ter um. Um é
o recomendado. Os outros dois são opções de verdade, cada uma com um custo que o primeiro não tem.

## Numa máquina virtual — o caminho recomendado

Uma **máquina virtual** é um computador inteiro simulado dentro do seu, com sistema operacional
próprio, que você pode quebrar e jogar fora sem mexer em mais nada. Rode o **Ubuntu Server 24.04
LTS** numa delas e você tem exatamente o sistema em que este curso foi gravado. Ele já vem com o
Git instalado, na versão 2.43.0, a mesma que toda transcrição mostra.

O programa que roda a máquina é um **hipervisor**, e qual usar depende do seu computador:

| seu computador | hipervisor | custo |
|---|---|---|
| Windows, Linux, ou um Mac com processador Intel | VirtualBox, em virtualbox.org | gratuito |
| um Mac com Apple silicon (M1 em diante) | UTM, em mac.getutm.app | gratuito |

Os passos, uma vez só:

1. Instale o hipervisor e baixe a imagem de instalação do Ubuntu Server 24.04 LTS em ubuntu.com.
   No Apple silicon, pegue a versão ARM; em todo o resto, a marcada `amd64`.
2. Crie uma máquina nova a partir dessa imagem com **2 processadores, 2 GB de memória e um disco
   de 20 GB**.
3. Ligue-a e aceite os padrões do instalador. Ele pede seu nome, um nome para o servidor e um nome
   de usuário. Escolha nomes de que vá lembrar, porque o usuário você vai digitar todo dia.
4. Quando ela reiniciar, entre com esse usuário e a senha, e pergunte ao Git o que ele é:

```
ana@vm:~$ git --version
git version 2.43.0
ana@vm:~$ sudo apt install git
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
git is already the newest version (1:2.43.0-1ubuntu7.3).
0 upgraded, 0 newly installed, 0 to remove and 29 not upgraded.
```

O segundo comando é o que você usaria para instalá-lo, e aqui ele só confirma que não há nada a
fazer. O `sudo` pede sua senha na primeira vez: ele roda o comando como administrador da máquina,
que é o que instalar qualquer coisa exige.

**O que custa ao seu computador:** os 2 GB de memória enquanto a máquina roda, e os poucos
gigabytes de disco que o Ubuntu vai ocupando. Tudo o que este curso cria são alguns megabytes a
mais. A primeira instalação leva quase uma hora, e a maior parte é esperar o instalador.

> **Seu prompt não vai dizer `ana@vm`.** Neste curso `ana` é o usuário e `vm` é a máquina. No seu
> são os nomes que você escolheu no passo 3. Todo comando é o mesmo.

## Instalado direto no seu computador

Se o seu computador **já roda Ubuntu ou Debian**, pule a máquina virtual: `sudo apt install git`
instala o Git, e tudo neste curso funciona como está impresso. É o caminho mais barato que existe.

No **macOS**, digitar `git` num terminal oferece instalar as ferramentas de desenvolvedor da Apple,
que o incluem. No **Windows**, o instalador de git-scm.com traz o Git e um terminal chamado Git
Bash, e todo comando deste curso funciona nesse terminal. Qualquer um dos dois custa algumas
centenas de megabytes de disco e nada enquanto você não o usa.

O que eles não dão é o mesmo sistema. O Git da Apple é outra versão, diferente da das transcrições.
O Git para Windows pergunta, durante a instalação, que editor usar e como chamar o primeiro branch;
a próxima seção define os dois com comandos, então qualquer resposta serve. O Windows também
termina as linhas dos arquivos de texto de um jeito diferente do Linux e do macOS, e o Git converte
entre os dois quando você faz commit, então você vai ver avisos sobre `LF` e `CRLF` que nenhuma
transcrição daqui tem. Nada disso muda o que um comando faz. Muda o que a tela diz em volta dele.

## Online, no servidor de outra pessoa

Alguns serviços dão a você um terminal numa aba do navegador, numa máquina deles, com o Git
instalado: o GitHub Codespaces e o Google Cloud Shell são dois, e os dois têm uma cota gratuita
quando isto foi escrito. **Não custa nada ao seu computador**, e precisa de uma conta e de conexão.

Use se os outros dois estiverem fora de alcance hoje, e planeje mudar. Uma cota gratuita é uma
oferta de uma empresa, e ofertas mudam seus limites e seus termos; este curso não depende de
nenhuma delas. A máquina também é deles: o que você deixa nela dura o quanto eles decidirem, então
um histórico que importa para você não deve morar só ali.

## Qual escolher

A máquina virtual, a menos que o seu computador já rode Ubuntu. Ela custa uma hora, uma vez, e
compra a única propriedade que os outros não têm: **quando a sua tela e a transcrição discordam, a
diferença está no que você digitou**, e não em qual sistema você está.

A próxima seção começa nesse prompt, e a seguinte é para quando esta não saiu como está escrito.
