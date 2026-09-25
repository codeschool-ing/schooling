---
title: Criando pastas e arquivos
version: 1
---

Tudo nesta aula acontece numa pasta, `~/work`, com dois arquivos já dentro: um log de backup e uma lista
de clientes.

```
ana@server:~/work$ mkdir invoices
ana@server:~/work$ mkdir reports/2026/q3
mkdir: cannot create directory ‘reports/2026/q3’: No such file or directory
ana@server:~/work$ mkdir -p reports/2026/q3
ana@server:~/work$ touch notes.txt
ana@server:~/work$ echo "call the printer company" > todo.txt
ana@server:~/work$ ls -F
backup.log  clients.csv  invoices/  notes.txt  reports/  todo.txt
ana@server:~/work$ find reports
reports
reports/2026
reports/2026/q3
```

- O **`mkdir`** faz uma pasta. O `mkdir reports/2026/q3` **falhou**, porque `reports` e `2026` ainda não
  existiam. O **`-p`** faz as pastas de cima que faltam, e não diz nada se já existirem, e é por isso que
  scripts sempre o usam.
- O **`touch`** cria um arquivo vazio ou, se o arquivo existe, só atualiza a data dele. Não muda conteúdo
  em nenhum dos casos.
- O **`echo "…" > todo.txt`** cria um arquivo com uma linha. O `>` manda a saída do `echo` para o arquivo
  em vez da tela, o assunto da seção 03.
- O **`ls -F`** marca pastas com `/`, e o **`find`** lista tudo abaixo de uma pasta, por mais fundo que
  seja.

A maioria dos comandos que dão certo **não imprime nada**. O silêncio é a resposta; erros são a única
coisa que vale imprimir, e o `mkdir` mostrou um.
