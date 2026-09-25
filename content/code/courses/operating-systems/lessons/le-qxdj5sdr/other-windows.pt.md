---
title: Os Windows que não estão na prateleira
version: 1
---

Mais quatro tipos de Windows aparecem no trabalho de suporte, e cada um atende uma necessidade
diferente.

## LTSC: o que não muda

O **Windows 11 Enterprise LTSC** (*Long-Term Servicing Channel*, canal de manutenção de longo prazo)
recebe **só atualizações de segurança, por anos**, e nunca uma atualização de recursos. Nenhum app novo
aparece, nenhuma configuração muda de lugar. Ele é feito para máquinas que precisam se comportar no
último dia como no primeiro: um aparelho de hospital, um terminal de fábrica, um caixa de loja. A
variante IoT do LTSC 2024 tem suporte por dez anos.

Ele **não** é um Windows melhor para PCs de escritório. Os programas esperam um Windows recente, e
alguns, como a Microsoft Store e os apps dela, ficam de fora.

## Windows Server

Mesmo kernel, outro trabalho. O **Windows Server 2025**, nas edições *Standard* e *Datacenter*, roda o
Active Directory, compartilhamentos de arquivos e máquinas virtuais. A licença é **por núcleo de
processador**, e as duas edições diferem principalmente em quantas máquinas virtuais uma licença
cobre. Ele não tem Microsoft Store e, instalado como *Server Core*, não tem área de trabalho nenhuma: o
servidor sem interface gráfica da aula 3, na versão Windows.

## Windows on Arm

Alguns notebooks, incluindo todo **Copilot+ PC** com Snapdragon, têm um processador Arm em vez de um
Intel ou AMD. O Windows roda nativo, e programas feitos para x64 rodam por um emulador chamado
**Prism**. A maioria funciona; drivers antigos e alguns softwares antitrapaça e de VPN, não. É o ponto
da aula 1 sobre drivers serem escritos para um hardware, chegando a um lugar novo.

## Edições N

Na Europa, o **Windows 11 Pro N** e o **Home N** são vendidos sem alguns apps de mídia, por questões de
concorrência. No resto são idênticos, e as peças que faltam são um download gratuito chamado *Media
Feature Pack*. Uma chamada de vídeo que falha num PC do escritório e funciona no seguinte pode ser
exatamente isso.
