---
title: A isca não tem usuários
version: 1
---

**Um honeypot é algo sem nenhum uso legítimo, posto onde um invasor o encontraria.** Uma máquina de
que o trabalho de ninguém precisa, um arquivo que a função de ninguém abre, uma conta com que ninguém
entra. Como nenhum deles tem usuário, **qualquer toque é um achado**, e isso vira de cabeça para baixo
o problema de sempre da detecção.

Todo outro detector deste curso enfrenta a mesma dificuldade: separar o incomum do só pouco frequente,
em milhares de eventos que são quase todos normais. As regras da aula 8 precisavam saber o que o
portal faz; o scanner da aula 9 teve de discutir com números de pedido; a aula 11 gastou uma seção com
ajuste fino. Um honeypot não precisa de nada disso. Ele não tem de reconhecer um ataque, porque não
está olhando o trabalho de ninguém. Só tem de notar que alguém chegou.

A imagem comum de um honeypot é uma armadilha elaborada que atrai atacantes e os estuda por semanas.
Esse tipo existe, e pesquisadores o rodam na internet. **Dentro de um escritório, o tipo útil é pequeno
e sem graça**, e o trabalho dele não é estudar ninguém. É um fio de alarme no lugar por onde um invasor
passa depois da primeira máquina, quando olha em volta para ver o que mais existe. É a etapa em que
nada mais neste curso é muito bom em notá-lo, porque olhar em volta usa ferramentas comuns de jeitos
comuns.

## Três tipos de isca

| isca | o que é | o que um toque quer dizer |
|---|---|---|
| **um honeypot** | uma máquina, ou portas numa, que oferece serviços que ninguém usa | alguém está explorando a rede |
| **um honeytoken** | um arquivo, uma credencial ou um registro que nada legítimo lê | alguém está mexendo em arquivos que não tinha motivo para abrir |
| **uma conta-isca** | um nome de conta que não existe em lugar nenhum, escrito onde seria achado | alguém está tentando nomes que achou |

Esta aula monta um de cada no laboratório: um honeypot no `trap`, um arquivo-isca no `web`, e um nome
de usuário plantado nesse arquivo que nenhum sistema conhece.

**O que um honeypot custa é sobretudo cuidado.** Ele precisa parecer digno de ser tocado, nunca pode
ser a coisa que mete o escritório em problema, e os alertas precisam chegar a alguém. A seção sobre
posicionamento diz para onde vai esse cuidado. Suba o laboratório com as máquinas que esta aula usa:

```sh
sudo bash hostlab.sh up trap desk web
```
