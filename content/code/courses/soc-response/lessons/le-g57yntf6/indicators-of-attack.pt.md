---
title: Indicadores de ataque: comportamento
version: 1
---

Um **indicador de ataque (IoA)** descreve comportamento em vez de um valor: o que está sendo feito, qualquer
que seja o endereço, o arquivo ou a conta. A regra v2 da aula 4 era um. Mais três, cada um uma consulta sobre
a semana, e cada um dispararia na quinta mesmo que todos os endereços fossem outros.

**Quem está sendo adivinhado.** A distinção da aula 2, conta inexistente contra senha errada, separa uma
pessoa que errou a digitação de alguém percorrendo uma lista:

```
ana@soc:~/week$ sqlite3 -header -column siem.db "SELECT src_ip, detail, count(*) AS n FROM logs WHERE src_ip IN ('203.0.113.66', '203.0.113.23') AND action = 'failure' GROUP BY 1, 2"
src_ip        detail          n 
------------  --------------  --
203.0.113.23  wrong_password  2 
203.0.113.66  unknown_user    39
203.0.113.66  wrong_password  18
```

As duas falhas da carla são senhas erradas na própria conta. As do visitante são **39 nomes que não existem
aqui** e 18 senhas erradas em nomes que existem. Ninguém digita o próprio nome de usuário errado como
`printer`.

**Um login por um método que a conta nunca usou:**

```
ana@soc:~/week$ sqlite3 -header -column siem.db "SELECT user, method, count(*) AS logins, min(datetime(timestamp, '-3 hours')) AS first_local FROM logs WHERE action = 'success' GROUP BY user, method"
user    method     logins  first_local        
------  ---------  ------  -------------------
ana     publickey  5       2026-09-14 08:15:05
bruno   password   7       2026-09-14 08:33:31
bruno   publickey  1       2026-09-17 03:05:22
carla   password   5       2026-09-14 08:18:38
diego   publickey  10      2026-09-14 08:26:10
helena  password   5       2026-09-14 08:02:51
```

Toda conta mantém um método a semana toda. A conta do bruno ganha um segundo, `publickey`, **uma vez**, às
03:05 de quinta. Um login com chave não é suspeito por si só (a ana e o diego não usam outra coisa); um
primeiro login com chave numa conta que só usou senha quer dizer que uma chave foi acrescentada, e alguém
deveria saber quem a acrescentou.

**Uma primeira transferência para um destino novo:**

```
ana@soc:~/week$ sqlite3 -header -column siem.db "SELECT dst_ip, count(*) AS transfers, min(datetime(timestamp, '-3 hours')) AS first_local, sum(bytes) / 1000000 AS mb FROM logs WHERE product = 'flow' GROUP BY dst_ip"
dst_ip         transfers  first_local          mb  
-------------  ---------  -------------------  ----
203.0.113.150  7          2026-09-14 01:00:00  2494
203.0.113.200  1          2026-09-17 02:41:12  612 
```

O backup vai para um endereço, toda noite, desde segunda. `203.0.113.200` aparece uma vez, às 02:41 de
quinta, com **612 MB**: um destino visto pela primeira vez recebendo um volume grande de um servidor que
guarda arquivos de clientes. O volume não é incomum aqui, já que todo backup é maior; **a novidade é**.

Cada um desses é uma pergunta sobre *comportamento contra uma referência*, e é por isso que vale construir a
referência (aula 6). Eles também geram mais falsos positivos do que um IoC atômico: um provedor de backup
novo também é um destino visto pela primeira vez. Esse é o preço de uma detecção que dura, pago em tempo de
triagem.
