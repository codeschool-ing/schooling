---
title: KVM, e por que os rótulos se misturam
version: 1
---

O laboratório deste curso usa **QEMU** e **KVM**, e eles não cabem direito em nenhuma das caixas, o
que vale saber porque você vai encontrar a discussão.

O **QEMU** sozinho é um hypervisor tipo 2 no sentido mais puro: um programa comum que imita um
computador inteiro, processador incluído, em software. Ele consegue imitar até um processador que não
tem, um ARM num laptop Intel, por exemplo. É correto e lento.

O **KVM** faz parte do kernel Linux. Carregado, ele transforma o próprio Linux num hypervisor: o
kernel escalona convidados do jeito que escalona processos, e usa os recursos de virtualização do
processador para rodar as instruções deles diretamente. O QEMU então só fornece os dispositivos, o
disco e a placa de rede, e entrega o processador ao KVM. Linux com KVM é tipo 1, porque o hypervisor
está no kernel sobre o hardware, ou tipo 2, porque é um sistema comum que você também usa para outras
coisas? Gente que entende do assunto discorda, e o Proxmox, aula 6, é construído sobre ele.

**Guarde a pergunta, não o rótulo: o que fica mais perto do hardware, e o processador ajuda?** A
segunda metade dessa pergunta acaba importando muito mais para a velocidade, e é nela que o
laboratório deste curso tem algo a mostrar.
