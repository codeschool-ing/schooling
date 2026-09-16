---
title: Arquivos, buffers e janelas — e como sair
version: 1
---

## Salvar e sair

| | |
|---|---|
| `:w` | salva |
| `:w nome` | salva em outro arquivo, e continua editando este |
| `:q` | sai |
| `:wq` ou `:x` | salva e sai |
| `:q!` | sai, **jogando fora** as mudanças não salvas |
| `:wa` `:qa` `:wqa` | todos os arquivos abertos |
| `ZZ` | `:wq`, a partir do modo normal |
| `ZQ` | `:q!`, a partir do modo normal |

O `:x` difere do `:wq` num ponto: ele não salva se nada mudou, então não mexe na
data de modificação. Num arquivo que outra coisa está vigiando, isso importa.

## O `:w` diz o que salvou

```
┌────────────────────────────────────────────────────────────────────────┐
│# the server configuration                                              │
│listen 8080                                                             │
│workers 4                                                               │
│timeout sixty                                                           │
│log_level info                                                          │
│log_file /var/log/app.log                                               │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│"server.conf" 6L, 104B written                        4,13          All │
└────────────────────────────────────────────────────────────────────────┘
```

Ele abriu como `6L, 101B`. Ele salvou `6L, 104B`. **Seis linhas nas duas vezes —
nada foi apagado** — e três bytes a mais, porque `30` virou `sixty`.

Ler aquela linha leva um segundo e pega a edição que você não quis fazer.

## Arquivos novos

```
┌────────────────────────────────────────────────────────────────────────────┐
│                                                                            │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│"brandnew.txt" [New]                                      0,0-1         All │
└────────────────────────────────────────────────────────────────────────────┘
```

**`[New]`** — o arquivo ainda não existe, e não vai existir até você dar `:w`.
Abrir um arquivo com o nome errado e encontrá-lo vazio normalmente é isso, e o
marcador é a pista.

## Quando você não pode salvar

```
┌────────────────────────────────────────────────────────────────────────────┐
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│E45: 'readonly' option is set (add ! to override)                           │
│Press ENTER or type command to continue                                     │
└────────────────────────────────────────────────────────────────────────────┘
```

Aquilo é `vim /etc/hostname` como usuário comum, uma edição, e `:w`. O vim abriu
o arquivo como somente leitura — ele avisou `W10: Warning: Changing a readonly
file` no instante em que a edição foi feita — e se recusa a salvar.

**O `:w!` passa da opção `readonly` e então falha na permissão**, porque o
arquivo é do root e você não é (aula 4 seção 02). As respostas de verdade são:

```sh
sudoedit /etc/hostname        # edits a copy as you, installs it as root
sudo vim /etc/hostname        # runs the whole editor as root
:w !sudo tee %                # the famous trick, from inside vim
```

**O `sudoedit` é o certo** e está na seção 13. O `sudo vim` roda um editor
inteiro, com arquivo de configuração e plugins, como root, que é uma superfície
maior do que o trabalho pede.

## Vários arquivos de uma vez

```
┌────────────────────────────────────────────────────────────────────────────┐
│timeout 30                                                                  │
│log_level info                                                              │
│log_file /var/log/app.log                                                   │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│:ls                                                                         │
│  1 %a   "server.conf"                  line 1                              │
│  2      "notes.txt"                    line 0                              │
│Press ENTER or type command to continue                                     │
└────────────────────────────────────────────────────────────────────────────┘
```

O `vim server.conf notes.txt` abre dois **buffers**. O `:ls` os lista, e os
marcadores importam: o `%` é o desta janela, o `a` é ativo.

| | |
|---|---|
| `:e arquivo` | abre outro arquivo |
| `:bn` `:bp` | buffer seguinte, anterior |
| `:b2` ou `:b notes` | vai a um buffer pelo número ou por parte do nome |
| `:bd` | fecha um buffer |
| `:ls` | lista todos |

**Um buffer é um arquivo em memória; uma janela é uma vista de um deles.** Fechar
uma janela não fecha o buffer, que é por que o `:q` às vezes te deixa dentro do
vim.

## Divisões

```
┌────────────────────────────────────────────────────────────────────────────┐
│the first line                                                              │
│the second line                                                             │
│the third line                                                              │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│notes.txt                                                 1,1            All│
│# the server configuration                                                  │
│listen 8080                                                                 │
│workers 4                                                                   │
│timeout 30                                                                  │
│log_level info                                                              │
│server.conf                                               1,1            Top│
│"notes.txt" 3L, 46B                                                         │
└────────────────────────────────────────────────────────────────────────────┘
```

`:sp notes.txt` — **duas janelas, cada uma com a sua própria linha de status**
dando o nome do arquivo, a posição do cursor e quanto do arquivo está visível:
`All` para o arquivo de três linhas, `Top` para o de seis linhas numa janela de
cinco.

| | |
|---|---|
| `:sp arquivo` | divide na horizontal |
| `:vs arquivo` | divide na vertical |
| `Ctrl-w` e então `w` | circula entre as janelas |
| `Ctrl-w` e então `h` `j` `k` `l` | vai para a janela naquele sentido |
| `Ctrl-w` e então `q` | fecha esta janela |
| `:only` | fecha todas as janelas menos esta |

**O `Ctrl-w` é o prefixo de janela**, e todo comando de janela começa com ele.

## Ler e executar

```sh
:r file           # read a file in below the cursor
:r !date          # read the output of a command in
:!ls -l           # run a command, show the output, come back
:%!sort           # pipe the whole buffer through sort and replace it
:%!python3 -m json.tool    # reformat the buffer as JSON
```

**O `:%!comando` é o recurso mais bem guardado do vim.** O buffer vai para a
entrada padrão do comando e a saída o substitui — então todo filtro da aula 8
está disponível para você no arquivo que você está editando, sem salvar antes:

```
┌────────────────────────────────────────────────────────────────────────┐
│apple                                                                   │
│banana                                                                  │
│cherry                                                                  │
│pear                                                                    │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│4 lines filtered                                      1,1           All │
└────────────────────────────────────────────────────────────────────────┘
```

Quatro linhas fora de ordem, `:%!sort`, e **`4 lines filtered`**.

## Uma coisa que vai te morder

```
┌────────────────────────────────────────────────────────────────────────┐
│pear                                                                    │
│list.txtY-list.txtm-list.txtd                                           │
│apple                                                                   │
│cherry                                                                  │
│banana                                                                  │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│                                                      2,1           All │
└────────────────────────────────────────────────────────────────────────┘
```

Aquilo foi `:r !date +%Y-%m-%d`, num arquivo chamado `list.txt`.

**Na linha de comando do vim, o `%` quer dizer o nome do arquivo atual.** Então
`+%Y-%m-%d` virou `+list.txtY-list.txtm-list.txtd`, o `date` recebeu um
disparate, e o vim leu o disparate para dentro. Escape com `\%`, ou ponha entre
aspas — e este é o mesmo `%` que faz o `:w !sudo tee %` funcionar.
