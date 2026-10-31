---
title: O seu computador, e os três jeitos de prepará-lo
version: 1
---

**Este curso não dá máquina nenhuma a você.** Todo comando dele roda num computador que você controla,
e esta seção é como deixá-lo pronto antes que a última seção da aula 1 peça para você digitar alguma
coisa. As aulas seguintes contam com o que você monta aqui e avisam quando acrescentam algo.

O que você precisa é pouco no começo e cresce em dois passos:

| a partir de | o quê | mais ou menos quanto de disco |
|---|---|---|
| aula 1 | Node.js 22.22.0, npm, git, um terminal e um editor | o `node_modules` de um projeto tem uns 400 MB |
| aula 3 | um navegador e, se quiser, o Expo Go num celular | nada a mais no computador |
| aulas 3, 17, 18 e 20 | um Java Development Kit 17 e o Android SDK, para os builds Android | 2,5 GB do SDK, e mais de 500 MB de cache do Gradle depois de um build |

**O Node.js é instalado exatamente como a aula 1 de `javascript` o instala**: o tarball 22.22.0 do
nodejs.org, descompactado em `~/.local/node`, com `node`, `npm` e `npx` ligados em `~/.local/bin`. Se
você fez aquele curso, ele já está aí; a próxima seção confere. Se não fez, a seção "Your computer,
set up for this course" daquela aula tem os cinco comandos, e num Mac o mesmo tarball existe para
`darwin-arm64` e `darwin-x64`.

## Os três caminhos

**1. Instalado no seu próprio computador. É este que você deve escolher.** Linux, um Mac, ou Windows com
o WSL 2 rodando Ubuntu. Tudo roda em velocidade total, o navegador que mostra o app da aula 3 é o que
você já usa, e um celular na mesma rede Wi-Fi alcança o servidor de desenvolvimento diretamente. Custa
o disco da tabela e nada mais. No Windows, mantenha o projeto dentro do sistema de arquivos do próprio
WSL (`~/planner`, não `/mnt/c/...`): o npm e o bundler leem milhares de arquivos pequenos, e fazer isso
atravessando a fronteira com o Windows é muitas vezes mais lento.

**2. Uma máquina virtual Ubuntu 24.04.** VirtualBox no Windows ou no Linux, UTM num Mac. Dê a ela 4 GB
de memória, dois processadores e 40 GB de disco, que é o que o curso precisa mais espaço para o
sistema. O seu computador paga pela máquina enquanto ela roda, mais ou menos essa memória tirada de
todo o resto. Duas coisas ficam mais difíceis: um celular só alcança um servidor de desenvolvimento
dentro de uma máquina virtual se a rede dela estiver em modo *bridge* e não *NAT*, e o emulador
Android precisa de virtualização por hardware, que a maioria das máquinas virtuais não repassa aos
convidados.

**3. Online, num ambiente de desenvolvimento na nuvem.** Qualquer máquina Linux que você alcance por um
navegador ou por SSH serve: GitHub Codespaces, Gitpod, um servidor que você aluga. O seu computador
não paga nada, e você precisa de conexão em cada minuto de estudo. O build web é alcançado pelo
redirecionamento de portas do serviço, e um celular não alcança o servidor de desenvolvimento sem um
túnel. **As franquias gratuitas deles mudam sem aviso**, e nada neste curso depende da de uma empresa
específica: se a que você usa deixar de ser gratuita, os comandos são os mesmos em qualquer outro
lugar.

## O celular, se você tiver um

**Um celular é opcional e vale a pena.** O Expo Go, um app gratuito nas duas lojas, roda o seu projeto
num aparelho de verdade sem construir nada: a aula 3 mostra como. Ele mostra as views nativas de
verdade que esta aula descreveu, onde o navegador mostra HTML no lugar delas. Nenhum passo deste curso
*exige* um, porque toda aula também roda num navegador ou em testes no computador.

## O que precisa de mais que um computador

Duas coisas precisam, e a seção sobre a fronteira, na aula 1, diz quais aulas elas tocam. **Um
emulador Android** precisa de virtualização por hardware no computador que o roda: KVM no Linux, a
Windows Hypervisor Platform no Windows, o Hypervisor framework num Mac. **O simulador de iOS e o Xcode
precisam de um Mac**, pela licença da Apple, e nenhuma máquina virtual ou ambiente na nuvem desta lista
oferece um.
