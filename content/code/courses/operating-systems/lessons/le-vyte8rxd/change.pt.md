---
title: Mudando: acrescentar, sobrescrever, copiar, mover
version: 1
---

## `>` e `>>`

```
ana@server:~/work$ cat todo.txt
call the printer company
ana@server:~/work$ echo "order toner" >> todo.txt
ana@server:~/work$ cat todo.txt
call the printer company
order toner
ana@server:~/work$ echo "renew the domain" > todo.txt
ana@server:~/work$ cat todo.txt
renew the domain
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 96\" role=\"img\" aria-label=\"O que os dois redirecionamentos fazem com um arquivo que já tem uma linha, call the printer company. Com dois sinais de maior, a linha nova, order toner, é acrescentada no fim, e o arquivo fica com duas linhas. Com um sinal de maior, o arquivo inteiro é trocado pela linha nova, renew the domain, e o conteúdo antigo some sem pergunta.\"><defs><marker id=\"rd-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"16\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">todo.txt antes</text><rect x=\"20\" y=\"28\" width=\"200\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"43\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">call the printer company</text><text x=\"260\" y=\"16\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">&gt;&gt;</text><text x=\"284\" y=\"16\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">acrescenta</text><rect x=\"260\" y=\"28\" width=\"200\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"270\" y=\"43\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">call the printer company</text><text x=\"270\" y=\"63\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">order toner</text><text x=\"500\" y=\"16\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">&gt;</text><text x=\"516\" y=\"16\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">substitui</text><rect x=\"500\" y=\"28\" width=\"200\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"510\" y=\"43\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">renew the domain</text></svg>", "caption": "Um caractere de diferença, e um deles destrói o conteúdo do arquivo sem perguntar. Na dúvida, use >>."}
```

**O `>>` acrescentou uma linha; o `>` trocou o arquivo inteiro.** Os dois são silenciosos, e o segundo
destruiu `call the printer company` e `order toner` sem perguntar. É o jeito mais comum de perder o
conteúdo de um arquivo na linha de comando, em geral apertando `>` uma vez onde se queria `>>`.

Para mudar uma linha no meio de um arquivo, use um editor. O **`nano`** é o simples na maioria dos
sistemas Linux, com os comandos listados no pé da tela; o curso de terminal Linux trata do Vim.

## Copiar, mover, renomear

```
ana@server:~/work$ cp clients.csv clients-backup.csv
ana@server:~/work$ mv todo.txt notes-todo.txt
ana@server:~/work$ mv clients-backup.csv invoices/
ana@server:~/work$ cp -r reports reports-copy
ana@server:~/work$ ls -F . invoices
.:
backup.log  clients.csv  invoices/  notes-todo.txt  notes.txt  reports/  reports-copy/

invoices:
clients-backup.csv
```

- O **`cp`** copia, e o **`cp -r`** copia uma pasta com tudo o que há dentro.
- O **`mv`** move, e **mover dentro da mesma pasta é renomear**: não existe um comando separado para
  renomear. O `mv todo.txt notes-todo.txt` renomeou; o `mv clients-backup.csv invoices/` moveu.
- A `/` no fim de `invoices/` é um hábito que vale ter. Se `invoices` não existisse, o `mv` recusaria em
  vez de renomear o arquivo para `invoices` em silêncio.

**O `cp` e o `mv` sobrescrevem um arquivo existente com o mesmo nome sem perguntar.** O `-i` os faz
perguntar, e o `-n` os faz recusar.
