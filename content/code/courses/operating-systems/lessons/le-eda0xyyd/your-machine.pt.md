---
title: Uma máquina sua para este curso
version: 1
---

Toda transcrição deste curso foi digitada numa máquina só: um servidor Ubuntu pequeno chamado `server`,
com o PowerShell 7 instalado ao lado do bash. **Você monta a mesma máquina, no seu próprio computador,
antes que a próxima seção peça para digitar qualquer coisa.** Ninguém hospeda uma para você, e isso faz
parte da matéria: pôr um sistema numa máquina é o assunto das aulas 2 a 4, e o primeiro que você instala
é este.

Há três jeitos de ter essa máquina. **Fique com a máquina virtual**, a menos que tenha um motivo para não
ficar.

| | o que é | o que custa ao seu computador |
|---|---|---|
| **uma máquina virtual** (recomendado) | o Ubuntu Server 24.04 LTS rodando numa janela do computador que você já usa | 2 processadores e 2 GB de memória enquanto roda, um disco virtual de 25 GB que só ocupa o que preenche, e uns 4 GB para o instalador que você baixa |
| instalado | o Ubuntu num computador só dele, ou ao lado do Windows no seu | um computador sobrando, ou parte do seu disco e uma mudança de partições (aula 3) que perde dados quando feita errado |
| online | um servidor Linux pequeno alugado de um provedor de nuvem | dinheiro por hora ou por mês, um cartão cadastrado e uma máquina na internet desde o primeiro minuto |

**Por que a máquina virtual.** As aulas 9 a 17 mudam usuários, permissões, serviços e os arquivos que
configuram o sistema, e uma aula que quebra alguma coisa não deveria custar mais do que montar de novo.
Uma máquina virtual é um arquivo no seu disco: dá para guardar o estado dela antes de uma aula, voltar a
ele depois e apagá-la quando o curso acabar, sem nunca mexer no computador em que você estuda. Um
computador com 8 GB de memória roda a máquina com folga ao lado de um navegador. Com 4 GB ela roda, se
você fechar todo o resto antes.

O programa que a roda é um *hipervisor*, e qual usar depende do que o seu computador roda:

| o seu computador | o hipervisor | o instalador a baixar |
|---|---|---|
| Windows | VirtualBox, gratuito; ou o Hyper-V, que já vem na edição Pro | Ubuntu Server, `amd64` |
| um Mac com processador Intel | VirtualBox | Ubuntu Server, `amd64` |
| um Mac com Apple silicon (M1 em diante) | UTM, gratuito | Ubuntu Server, `arm64` |
| Linux | virt-manager, ou VirtualBox | Ubuntu Server, `amd64` |

O curso de virtualização explica o que um hipervisor faz. Aqui ele é só a janela em que o servidor roda.

**Instalado** é a escolha certa se você tem um computador sobrando que pode apagar. Ao lado do Windows
é possível, e a aula 3 mostra como, mas as aulas finais do curso quebram coisas de propósito, e você
estaria quebrando o computador de que precisa para ler a aula seguinte. **Online** aparece aqui para você
saber que existe. Vários provedores oferecem um servidor pequeno de graça por um tempo, e as condições
mudam; nada neste curso depende de nenhum deles. Um servidor com endereço público é sondado por
estranhos em minutos, então, se escolher esse caminho, guarde a chave SSH que o provedor entrega e nunca
defina uma senha simples.

## Windows e macOS

O servidor é onde você digita as partes de Linux e de PowerShell, que são a maior parte do que se digita
neste curso. As partes que só o Windows ou o macOS mostram não foram rodadas para este curso, cada aula
avisa isso onde elas aparecem, e você as pratica no que tiver dos dois.

- **Se o seu computador roda Windows**, ele é o seu laboratório de Windows. Dá também para instalar o
  Windows 11 numa máquina virtual com o instalador da aula 2: ele pede 4 GB de memória, 64 GB de disco e
  um TPM virtual, que o VirtualBox 7 e o Hyper-V oferecem. Sem chave de produto ele funciona, com um aviso
  na tela e as opções de personalização travadas.
- **Se você tem um Mac**, ele é o seu laboratório de macOS. O macOS só pode rodar em hardware da própria
  Apple, em máquina virtual ou não, então, sem um Mac, a aula 4 é para ler, não para digitar.

A próxima seção monta o servidor.
