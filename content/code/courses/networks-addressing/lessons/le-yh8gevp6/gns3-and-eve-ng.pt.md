---
title: GNS3 e EVE-NG: rodando o software de verdade
version: 1
---

O GNS3 e o EVE-NG fazem o contrário do Packet Tracer. Em vez de imitar um roteador, **eles rodam o
sistema operacional real do roteador** dentro de uma máquina virtual ou de um emulador, e ligam as
máquinas com cabos virtuais. Quando um roteador num deles responde a `show ip route`, é o código do
próprio fabricante respondendo. **Nenhum dos dois foi executado para esta aula**: as imagens de
dispositivo que eles precisam são software licenciado, e nada nesta página é saída deles.

O GNS3 é gratuito e de código aberto, e vem em duas partes: um cliente gráfico onde você desenha a
topologia e um servidor que roda os dispositivos. O servidor pode rodar no mesmo computador, mas em
geral roda numa máquina virtual própria (a GNS3 VM) ou em outro computador, porque os dispositivos são
pesados. Ele roda vários tipos de dispositivo lado a lado:

- imagens antigas de roteadores Cisco, por um emulador chamado Dynamips;
- qualquer coisa que dê boot no QEMU, o software de máquinas virtuais: uma imagem moderna de roteador
  ou firewall, um servidor Linux, um cliente Windows;
- contêineres Docker, para hosts leves.

Um nó **cloud** liga a rede emulada a uma interface real do seu computador, para que o laboratório
alcance a rede real ou a internet quando você quiser.

O EVE-NG (Emulated Virtual Environment – Next Generation) faz o mesmo trabalho como um servidor que
você usa pelo navegador. Ele é instalado como máquina virtual ou num servidor dedicado, e a topologia,
os dispositivos e os consoles deles abrem todos no navegador, o que combina com um laboratório que
várias pessoas compartilham. Ele vem numa edição Community gratuita e numa edição Professional paga.

O que os dois dão é fidelidade: um firewall de um fabricante e um roteador de outro, cada um rodando o
software real e configurado pela linha de comando real. O que isso custa:

- **imagens**: nenhuma das duas ferramentas vem com software de fabricante. As imagens de roteador e
  firewall vêm dos fabricantes, sob as licenças deles, muitas vezes ligadas a um contrato de suporte ou
  a uma conta de treinamento; uma imagem copiada de outro lugar é software que você não tem licença
  para rodar;
- **memória e processador**: cada dispositivo é uma máquina virtual com memória reservada só para
  ele, e uma imagem atual de fabricante pode querer gigabytes, então um laboratório de dez desses
  roteadores pede um servidor, não um notebook;
- **preparação**: a imagem precisa ser importada e casada com as configurações que a fazem dar boot, o
  que demora mais que desenhar a rede.

Use os dois quando a marca e a versão importam: ensaiar uma mudança no software exato do firewall que
a empresa usa, estudar para a certificação de um fabricante no sistema operacional dele, ou reproduzir
um problema que um dispositivo real mostra e um modelo não mostraria.
