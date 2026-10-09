---
title: Fatos, com as fontes
version: 1
---

Um fato num relatório é uma frase e uma fonte. Para os números, a fonte fica melhor como um arquivo: uma consulta
por número, numeradas, para o relatório poder dizer "57 tentativas (fato 1)" e um auditor poder rodar o fato 1 de
novo. Escreva isto como `facts.sql` em `~/week`:

```sql
-- facts.sql: every number the report states, each from one query, numbered so the report can cite it
.headers on
.mode column
SELECT 1 AS n, 'password guesses from 203.0.113.66' AS fact, count(*) AS value
  FROM logs WHERE src_ip = '203.0.113.66' AND action = 'failure'
UNION ALL
SELECT 2, 'accounts those guesses named', count(DISTINCT user)
  FROM logs WHERE src_ip = '203.0.113.66' AND action = 'failure'
UNION ALL
SELECT 3, 'successful logins from 203.0.113.66', count(*)
  FROM logs WHERE src_ip = '203.0.113.66' AND action = 'success'
UNION ALL
SELECT 4, 'hosts reached by bruno that night', count(DISTINCT host)
  FROM logs WHERE user = 'bruno' AND action = 'success'
   AND timestamp BETWEEN '2026-09-17 05:00' AND '2026-09-17 06:30'
UNION ALL
SELECT 5, 'bytes from files to 203.0.113.200', sum(bytes)
  FROM logs WHERE product = 'flow' AND src_ip = '192.168.20.10' AND dst_ip = '203.0.113.200'
UNION ALL
SELECT 6, 'the same, in MB (10^6 bytes)', round(sum(bytes) / 1e6)
  FROM logs WHERE product = 'flow' AND src_ip = '192.168.20.10' AND dst_ip = '203.0.113.200';
```

Cada `SELECT` é um fato, e o `UNION ALL` os empilha numa tabela. Rode contra o SIEM da aula 4, e calcule o hash do
banco e das consultas, para o apêndice poder nomear exatamente de quais dados e de quais perguntas os números
vieram:

```
ana@soc:~/week$ sqlite3 siem.db < facts.sql
n  fact                                 value    
-  -----------------------------------  ---------
1  password guesses from 203.0.113.66   57       
2  accounts those guesses named         19       
3  successful logins from 203.0.113.66  2        
4  hosts reached by bruno that night    2        
5  bytes from files to 203.0.113.200    612408119
6  the same, in MB (10^6 bytes)         612.0    
ana@soc:~/week$ sha256sum siem.db facts.sql
8804ccde7f44b2db5934be6be962e31dd42f006b566bf5d45e0a1bc629a9ea8d  siem.db
c65f6fdec8c26b0f6e82160d85770d9f277df831ba2fd4b8baf38561e03a49a8  facts.sql
```

Seis fatos, e o corpo do relatório agora pode afirmá-los com simplicidade: **57 tentativas de senha** de um
endereço, citando **19 contas**; **2 logins bem-sucedidos** a partir dele, os dois do bruno; **2 hosts da empresa**
alcançados; e **612.408.119 bytes**, 612 MB, enviados do servidor de arquivos para `203.0.113.200`. O fato 6 diz o
que "MB" significa, porque um relatório que mistura megabytes decimais e mebibytes binários erra por cinco por
cento na direção que ninguém percebe.

Fatos que não são números recebem o mesmo tratamento, com a fonte citada: "o bruno entrou normalmente do endereço
de costume às 08:35 (SIEM, log do sshd do `gw`)"; "a exportação apagada de contatos de clientes foi recuperada da
imagem do disco do servidor de arquivos (imagem 001, inode 24, SHA-256 no apêndice C)".

**Um fato é o que a evidência mostra, e nada mais.** "A senha do bruno foi adivinhada" é uma inferência, e muito
forte: 57 falhas em 19 contas, depois sucesso em uma. O relatório pode dizê-la, com a palavra "inferido" e o
motivo, e mantê-la separada dos fatos medidos acima dela.
