---
title: Cinco situações em que você não escolhe
version: 1
---

Você tem um editor de que gosta. Esta aula não é sobre ele, porque estas cinco
situações não perguntam.

**Uma: a máquina está em outro lugar.** Você está nela por `ssh` (aula 5 seção
06). Não há nada gráfico, e copiar o arquivo, editar e copiar de volta são três
passos onde um basta — e dois desses passos são onde as permissões se perdem.

**Duas: você é root por noventa segundos.** Uma linha num arquivo de
configuração, e sai. O argumento da aula 4 seção 11 sobre o `sudo` vale: quanto
mais curta aquela janela, melhor.

**Três: algo abriu um editor e está te esperando.**

```sh
git commit          # opens an editor for the message
crontab -e          # opens an editor for your schedule — lesson 13
visudo              # opens an editor, and checks the syntax on the way out
sudoedit /etc/x     # opens an editor, as you, on a root-owned file
systemctl edit x    # opens an editor for a unit override
```

**Nenhum desses é uma pergunta.** Um programa abriu *alguma coisa* e não continua
até você resolver, e se você não sabe o que ele abriu, você está na situação da
piada.

**Quatro: a máquina está quebrada.** Uma imagem de resgate, um contêiner com doze
pacotes, um sistema que não passa do `emergency.target`. O que há é o `vi`,
porque alguma coisa tem que haver, e a coisa que sempre há é a que alguém decidiu
em 1976.

**Cinco: é mais rápido.** Não para escrever um programa — para o trabalho que
você vai fazer de verdade, que é *mudar uma linha num arquivo e conferir que não
mudou mais nada*. Abrir uma IDE para isso é como pegar o carro para ir até o
portão.

## O que há nesta máquina

```
ana@vm:~$ ls -l /usr/bin/vi /etc/alternatives/vi
lrwxrwxrwx 1 root root 18 Mar 10  2026 /etc/alternatives/vi -> /usr/bin/vim.basic
lrwxrwxrwx 1 root root 20 Mar 10  2026 /usr/bin/vi -> /etc/alternatives/vi
```

O `vi` não é um programa aqui. É um link simbólico para o sistema de alternativas
da aula 2 seção 11, apontando para o `vim.basic` — então digitar `vi` te dá o
vim, com algumas configurações de compatibilidade ligadas. Num sistema mínimo ele
pode apontar para o `vim.tiny`, ou para o `busybox vi`, e esses são genuinamente
mais limitados.

| | |
|---|---|
| `vi` | está em **tudo**. Normalmente o vim, às vezes um vi menor |
| `vim` | está em quase tudo |
| `nano` | está em quase toda instalação padrão de distribuição |
| `emacs` | está quando alguém o instalou |

**O `vi` é o com que dá para contar.** É essa a razão inteira de esta aula gastar
mais seções com o vim do que com qualquer outra coisa, e não é um endosso.

## O que esta aula faz

| | |
|---|---|
| **nano**, numa seção | dez minutos, e o bastante para o trabalho |
| **vim**, em sete | porque é o que está lá, e porque é uma ideia só |
| **emacs**, numa | honestamente, e brevemente |
| **qual deles**, e como torná-lo padrão | a parte que sobrevive aos três |

E as telas são reais. Cada editor foi iniciado num terminal de verdade, as teclas
foram digitadas, a tela que ele desenhou foi capturada, e as linhas de texto
foram **conferidas contra o arquivo em disco** — então uma tela que saísse errada
teria sido pega em vez de impressa. Onde o arquivo não está na tela, como no
prompt `Save modified buffer?` do nano, a tela é o que o nano desenhou e nada
mais.
