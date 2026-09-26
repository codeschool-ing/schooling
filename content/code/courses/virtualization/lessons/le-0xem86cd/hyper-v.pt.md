---
title: Hyper-V
version: 1
---

O **Hyper-V** é o hypervisor da Microsoft, e já está na maioria dos computadores de empresa: vem com o
Windows 10 e 11 **Pro, Enterprise e Education**, não com o Home, e com o Windows Server. Ele é ligado
como um recurso do Windows, e depois de reiniciar o computador liga primeiro o hypervisor da Microsoft,
com o Windows rodando por cima, o tipo 1 da aula 2 num laptop.

Ele é gerenciado pelo **Gerenciador do Hyper-V**, uma janela que lista as máquinas e o estado delas, e
pelo PowerShell. Quatro das escolhas dele diferem dos outros hypervisors deste curso, e as quatro
aparecem em chamados:

- **Geração 1 ou 2**, escolhida quando a máquina é feita e nunca mudada. A geração 1 imita um PC antigo
  com BIOS; a geração 2 tem UEFI e Secure Boot e é a escolha certa para qualquer sistema moderno. Um
  **convidado Linux na geração 2 não dá boot até o Secure Boot ser trocado para o modelo chamado
  *Microsoft UEFI Certificate Authority***, que é o esquecido com mais frequência.
- **VHDX** é o formato de disco dele, e **ponto de verificação** (checkpoint) é a palavra dele para
  snapshot. Um checkpoint de *produção*, o padrão, pede ao convidado que arrume os arquivos e não salva
  memória; um *padrão* salva o estado em execução, como os snapshots da aula 9.
- **Serviços de Integração** são o agente de convidado dele. Convidados Windows os têm embutidos, e o
  Linux os tem no kernel.
- **Sessão avançada** conecta a um convidado Windows do jeito que a Área de Trabalho Remota faz, com área
  de transferência, som e uma tela que muda de tamanho.
