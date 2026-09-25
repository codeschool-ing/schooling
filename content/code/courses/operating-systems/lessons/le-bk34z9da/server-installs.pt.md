---
title: Um servidor não tem área de trabalho
version: 1
---

O servidor do escritório não precisa de tela: ninguém se senta na frente dele. Para esse trabalho existe
o **Ubuntu Server**, e ele é diferente em três pontos que vale conhecer antes de escolhê-lo.

**O instalador é em texto.** As mesmas perguntas do Desktop (idioma, teclado, rede, disco, conta),
respondidas com as setas e o Enter. Parece antiquado e é mais rápido.

**Ele oferece instalar o servidor SSH.** O SSH é como você chega a uma máquina Linux a partir de outro
computador e digita comandos nela como se estivesse sentado ali; o curso de redes o usa o tempo todo.
Marque a opção durante a instalação, e o servidor pode voltar para o armário sem teclado nem monitor.

**Não há interface gráfica depois.** Você entra num prompt como os dos registros deste curso, e tudo é
feito com comandos. Isso é uma vantagem: nada para atualizar que ninguém usa, menos memória gasta, menos
portas de entrada para um atacante.

## Desktop ou servidor?

| | Desktop | Server |
|---|---|---|
| usado por | uma pessoa, na frente dele | outros computadores, pela rede |
| interface | gráfica | texto, acessado por SSH |
| trabalho típico no escritório | o PC da recepção | arquivos compartilhados, backups, a fila de impressão |

Os dois são o mesmo Ubuntu por baixo: o mesmo `apt`, o mesmo `sudo`, a mesma árvore de pastas. Um
servidor pode ganhar uma área de trabalho depois com um pacote, e um desktop pode rodar programas de
servidor. A escolha é sobre para que a máquina serve, não sobre o que ela consegue fazer.

## Na nuvem

A maioria dos servidores Linux de hoje nem está num armário: são máquinas virtuais alugadas de um
provedor de nuvem. Essas não se instalam de uma ISO. Elas começam de uma **imagem** pronta, e os passos
da primeira hora da seção 05, atualizações e um usuário com `sudo`, são a parte que continua igual. O
curso de virtualização continua daqui.
