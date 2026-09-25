---
title: Achando arquivos, e achando palavras dentro deles
version: 1
---

De novo duas perguntas: **quais arquivos se chamam assim**, e **quais arquivos contêm isto**.

```
ana@server:~$ find work -name '*.txt'
work/invoices/104.txt
work/reports/q3.txt
ana@server:~$ grep -rn "Acme" work
work/invoices/104.txt:1:Invoice 104 for Acme Ltd
work/clients.csv:2:1,Acme Ltd,Sao Paulo
PS /home/ana> Get-ChildItem work -Recurse -Filter *.txt -Name
invoices/104.txt
reports/q3.txt
PS /home/ana> Select-String -Path work/*/*.txt, work/*.csv -Pattern Acme

work/invoices/104.txt:1:Invoice 104 for Acme Ltd
work/clients.csv:2:1,Acme Ltd,Sao Paulo
```

- O **`find`** busca pelo **nome** (e tamanho, data, dono), descendo a partir de uma pasta. O padrão vai
  entre aspas, para o `find` receber o `*` em vez de o shell expandi-lo antes, o ponto da aula 12.
- O **`grep -rn`** busca **dentro** dos arquivos: o `-r` percorre as pastas, o `-n` imprime o número da
  linha. Ele achou `Acme` na fatura e na lista de clientes.
- O **`Get-ChildItem -Recurse -Filter`** é o `find` do PowerShell, e o **`Select-String`** é o `grep`
  dele, imprimindo o arquivo, o número da linha e a linha no mesmo formato.

No Prompt de Comando:

```sh
dir /s /b *.txt
findstr /s /i /n "Acme" *.txt
```

O `dir /s /b` lista todo arquivo que casa abaixo da pasta atual, um caminho completo por linha, e o
**`findstr`** é o `grep` do Prompt de Comando: `/s` para subpastas, `/i` para ignorar maiúsculas, `/n`
para números de linha. No Windows a caixa de busca do Explorador de Arquivos faz o mesmo para pessoas;
os comandos são para quando o resultado precisa ir para algum lugar, um arquivo ou o próximo comando.
