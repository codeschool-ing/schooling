---
title: Como sair, e as quatro telas que te seguram
version: 1
---

Esta é a seção para ler duas vezes. Tudo nela acontece quando você está com
pressa.

## Os quatro comandos

| | |
|---|---|
| `Esc` | chegar ao modo normal. **Primeiro, sempre** |
| `:q!` | sair, jogando fora as mudanças |
| `:wq` | salvar e sair |
| `u` | desfazer |

**`Esc` e então `:q!`** é a resposta para "estou preso no vim". Funciona do modo
de inserção, do modo visual, de um comando digitado pela metade. Joga fora as
suas mudanças, que é o que você quer quando não teve a intenção de fazer
nenhuma.

Se o `Esc` parece não funcionar, você provavelmente está no meio de um comando de
várias teclas — aperte duas vezes.

## Tela um: ele não te deixa sair

```
┌────────────────────────────────────────────────────────────────────────┐
│listen 8080                                                             │
│workers 4                                                               │
│timeout 30                                                              │
│log_level info                                                          │
│log_file /var/log/app.log                                               │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│E37: No write since last change (add ! to override)                     │
│Press ENTER or type command to continue                                 │
└────────────────────────────────────────────────────────────────────────┘
```

**O `E37` é o vim te protegendo**, não o vim sendo difícil. Você mudou alguma
coisa e pediu para sair sem salvar.

| | |
|---|---|
| `:wq` | você queria manter |
| `:q!` | você não queria |

Repare que o arquivo perdeu um caractere — o alto da tela começa em `listen`,
porque a mensagem de duas linhas empurrou a vista para baixo, e a linha do `#`
está acima dela. A tela rolando não é o arquivo mudando.

## Tela dois: `Press ENTER`

Qualquer mensagem longa demais, ou qualquer comando que produziu saída, termina
com `Press ENTER or type command to continue`. **Aperte Enter.** Não é um prompt
com consequências; o vim está esperando você ter lido a linha.

## Tela três: o arquivo de swap

```
┌────────────────────────────────────────────────────────────────────────────┐
│E325: ATTENTION                                                             │
│Found a swap file by the name ".server.conf.swp"                            │
│          owned by: ana   dated: Tue Sep 15 11:59:56 2026                   │
│         file name: ~ana/work/edit/server.conf                              │
│          modified: YES                                                     │
│         user name: ana   host name: vm                                     │
│        process ID: 18031                                                   │
│While opening file "server.conf"                                            │
│             dated: Tue Sep 15 11:59:54 2026                                │
│                                                                            │
│(1) Another program may be editing the same file.  If this is the case,     │
│    be careful not to end up with two different instances of the same       │
│    file when making changes.  Quit, or continue with caution.              │
│-- More --                                                                  │
└────────────────────────────────────────────────────────────────────────────┘
```

Aquilo é real: um vim foi aberto, uma linha foi acrescentada, e o processo foi
morto. Isto é o que o vim seguinte mostra.

**O vim mantém um arquivo de swap enquanto você edita**, para que se ele morrer o
seu trabalho não se perca. Encontrar um ao iniciar quer dizer uma de duas coisas,
e a tela diz qual:

| | |
|---|---|
| `process ID: 18031` **ainda rodando** | outra pessoa está com este arquivo aberto. Aperte `q` e vá perguntar |
| aquele processo não existe mais | o vim ou a máquina morreu. O seu trabalho não salvo está no arquivo de swap |

Aperte Enter depois do `-- More --` e as escolhas aparecem. As que importam:

| | |
|---|---|
| `r` | **recover** — carrega o que estava no arquivo de swap |
| `e` | edita assim mesmo, ignorando |
| `q` | sai. **A segura, se você não tem certeza** |
| `d` | apaga o arquivo de swap |

**A sequência certa quando o trabalho era seu e o editor morreu:** aperte `r`,
olhe o que voltou, salve em algum lugar, e então `:q` e apague o arquivo de swap
— o vim não vai fazer isso por você, e enquanto ele existir você vê esta tela
toda vez.

```sh
ls -la .server.conf.swp        # they are hidden, and named after the file
rm .server.conf.swp
```

## Tela quatro: o terminal, não o vim

Às vezes o vim está bem e o terminal não. Os dois casos da seção 8:

| | |
|---|---|
| nada aparece quando você digita | você apertou `Ctrl-s`. Aperte `Ctrl-q` |
| o vim saiu mas o terminal está bagunçado | `reset`, ou `stty sane` |

**O `Ctrl-s` é o que se parece exatamente com um editor travado**, e é um recurso
de terminal da era do papel.

## Dois jeitos de perder trabalho que não são culpa do vim

**Editar um arquivo que outra coisa reescreve.** Um gerenciador de configuração,
um deploy, um serviço que reescreve o próprio arquivo. O vim avisa ao salvar —
`WARNING: The file has been changed since reading it!!!` — e é um prompt que você
tem que ler em vez de dispensar.

**Editar a cópia errada.** `sudo vim` num arquivo, e então descobrir que a sua
mudança não está lá, porque você abriu o `/etc/nginx/nginx.conf` e o que está
valendo é o `/etc/nginx/sites-enabled/default`. Não é problema do editor, e é o
jeito mais comum de uma edição "não pegar".

## O cartão

```
Esc            get to normal mode
:q!            leave, discard changes
:wq            save and leave
u              undo
Ctrl-r         redo
/text  n       search, next
dd  yy  p      delete a line, copy a line, paste
i  A  o        insert here, at end of line, on a new line
:set paste     before pasting anything
```

Nove linhas. Se o vim não é o seu editor, é tudo dele de que você precisa — e as
quatro do alto são as que importam numa máquina em que alguém está esperando.
