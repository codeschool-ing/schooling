---
title: Criando pastas e arquivos
version: 2
---

Tudo nesta aula acontece numa pasta, `~/work`, com dois arquivos já dentro: um log de backup e uma lista
de clientes. Crie-os no seu servidor primeiro. A segunda linha é um programinha: um laço que escreve 240
linhas, dez para cada dia a partir de 1º de setembro, como um backup que roda a cada poucos minutos as
deixaria. A terceira escreve a lista de clientes de uma vez:

```sh
rm -rf ~/work && mkdir ~/work && cd ~/work
for i in $(seq 1 240); do printf '2026-09-%02d 09:%02d backup ok\n' $(( (i-1)/10 + 1 )) $(( (i-1) % 60 )); done > backup.log
printf 'id,name,city\n1,Acme Ltd,Sao Paulo\n2,Bravo & Filhos,Campinas\n3,Casa Verde,Santos\n' > clients.csv
```

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

- O `mkdir` faz uma pasta. O `mkdir reports/2026/q3` **falhou**, porque `reports` e `2026` ainda não
  existiam. O **`-p`** faz as pastas de cima que faltam, e não diz nada se já existirem, e é por isso que
  scripts sempre o usam.
- O `touch` cria um arquivo vazio ou, se o arquivo existe, só atualiza a data dele. Não muda conteúdo
  em nenhum dos casos.
- O `echo "…" > todo.txt` cria um arquivo com uma linha. O `>` manda a saída do `echo` para o arquivo
  em vez da tela, o assunto da seção 03.
- O `ls -F` marca pastas com `/`, e o `find` lista tudo abaixo de uma pasta, por mais fundo que
  seja.

A maioria dos comandos que dão certo **não imprime nada**. O silêncio é a resposta; erros são a única
coisa que vale imprimir, e o `mkdir` mostrou um.
