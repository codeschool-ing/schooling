---
title: O seu laboratório, e onde ele roda
version: 1
---

Tudo neste curso é feito no **seu próprio computador**. Ninguém entrega uma máquina para você praticar:
o laboratório do curso é algo que você monta, e montá-lo é a primeira coisa que o curso ensina. As
próximas três seções o preparam, o resto desta aula faz o primeiro convidado à mão, e a seção 11 é
para quando algo der errado, porque quase sempre algo dá.

O laboratório é um computador Linux com o **Ubuntu 24.04 LTS**, com o **QEMU** e o **libvirt**
instalados, e os convidados dele também são Ubuntu. Há três jeitos de ter esse computador.

**Instalado: o Ubuntu no próprio computador. É o que escolher se você puder.** O curso de sistemas
operacionais instalou o Ubuntu, sozinho ou ao lado do Windows, e essa instalação é tudo de que isto
precisa. Os convidados então rodam no processador de verdade quase na velocidade total, pelo KVM, que a
aula 2 explica. O que custa: uns 10 GB de disco para o laboratório além do sistema, e memória para cada
convidado ligado ao mesmo tempo, 1 GiB cada na maioria das aulas e três de uma vez na aula 14. Um
computador com 8 GB de memória fica folgado; com 4 GB, funciona com um convidado por vez.

**Numa máquina virtual: o Ubuntu Server 24.04 como convidado do sistema que você já tem.** No Windows,
o hypervisor é o Hyper-V, que vem no Windows Pro, ou o VirtualBox. Num Mac com processador Intel é o
VirtualBox ou o VMware Fusion, e num Mac com processador Apple, o UTM. Os convidados do seu laboratório passam a ser
convidados dentro de um convidado, e só são rápidos se o hypervisor de fora repassar os recursos de
virtualização do processador, o que se chama **virtualização aninhada**. No VirtualBox é *Enable Nested
VT-x/AMD-V*, nas configurações de processador da máquina, e no Hyper-V é `Set-VMProcessor -VMName NOME
-ExposeVirtualizationExtensions $true` no PowerShell, com a máquina desligada. Sem isso tudo funciona,
mais devagar, e este curso foi gravado exatamente assim. O que custa: a máquina de fora precisa de 4 GB
de memória e 40 GB de disco só dela, tirados do seu computador enquanto roda. Num Mac com processador
Apple os convidados são ARM: os comandos são os mesmos, com `arm64` onde este curso diz `amd64`, e alguns
números das capturas vão ser diferentes.

**Online: um servidor Linux alugado por hora.** Qualquer provedor que venda um servidor virtual com o
Ubuntu 24.04 serve, e você o acessa por ssh. A maioria não oferece virtualização aninhada, então o
laboratório roda devagar, como no segundo caminho. O que custa: dinheiro a cada hora em que o servidor
existe, então destrua-o ao terminar e faça de novo da próxima vez. Planos gratuitos vêm e vão e
costumam dar memória de menos para um laboratório, então não planeje um curso em cima de um.

Se você só quer ver as janelas, o **VirtualBox sozinho** roda no Windows, no macOS e no Linux, e a aula 4
o usa. Ele não basta para o resto do curso, que digita os comandos num host Linux.

Onde este curso diz `ana@host`, a pessoa é a ana e o computador dela se chama host. O seu vai ter os seus
próprios nomes no prompt, e os endereços e tamanhos da sua saída vão ser um pouco diferentes dos daqui;
os comandos, não.
