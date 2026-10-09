---
title: A linha do tempo
version: 1
---

A **linha do tempo** é a espinha de uma investigação: todo evento relevante, de toda fonte, numa lista só,
num fuso só. É onde as lacunas aparecem (nada entre 02:41 e 03:05: o que aconteceu?) e onde as afirmações são
conferidas (a transferência começou antes ou depois do login no `files`?). Salve isto em `~/week` como
`timeline.sql`:

```sql
-- timeline.sql: Thursday night in one list, every source, UTC and local side by side
.headers on
.mode column
SELECT timestamp AS utc, time(timestamp, '-3 hours') AS local, host, product, action,
       coalesce(user, '') AS user, coalesce(src_ip, '') AS src, coalesce(dst_ip, '') AS dst,
       coalesce(bytes, '') AS bytes
FROM logs
WHERE timestamp BETWEEN '2026-09-17 05:00' AND '2026-09-17 06:30'
  AND (src_ip IN ('203.0.113.66', '198.51.100.22', '192.168.20.10') OR user = 'bruno')
  AND NOT (product = 'sshd' AND action = 'failure')
  AND NOT (product = 'firewall' AND src_ip = '203.0.113.66' AND dst_port = 22)
UNION ALL
SELECT min(timestamp), time(min(timestamp), '-3 hours'), 'gw', 'sshd', count(*) || ' failures',
       count(DISTINCT user) || ' accounts', '203.0.113.66', '', ''
FROM logs WHERE src_ip = '203.0.113.66' AND action = 'failure'
ORDER BY utc;
```

A primeira parte seleciona os eventos da noite para o endereço, a conta e os hosts envolvidos, deixando de
fora as 57 falhas e todas as 59 linhas de firewall daquele endereço; a segunda parte as traz de volta como **uma linha** que diz
quantas foram. Uma linha do tempo que listasse cada falha esconderia os seis eventos que importam debaixo de
sessenta que não importam.

```
ana@soc:~/week$ sqlite3 siem.db < timeline.sql
utc                  local     host   product   action       user         src            dst            bytes    
-------------------  --------  -----  --------  -----------  -----------  -------------  -------------  ---------
2026-09-17 05:10:06  02:10:06  gw     sshd      57 failures  19 accounts  203.0.113.66                           
2026-09-17 05:33:07  02:33:07  gw     sshd      success      bruno        203.0.113.66                           
2026-09-17 05:35:40  02:35:40  files  sshd      success      bruno        198.51.100.22                          
2026-09-17 05:35:40  02:35:40  fw     firewall  connection                198.51.100.22  192.168.20.10           
2026-09-17 05:41:12  02:41:12  fw     firewall  connection                192.168.20.10  203.0.113.200           
2026-09-17 05:41:12  02:41:12  fw     flow      flow                      192.168.20.10  203.0.113.200  612408119
2026-09-17 06:05:22  03:05:22  gw     sshd      success      bruno        203.0.113.66                           
```

Leia de cima para baixo e ela conta a história sem nada acrescentado: tentativas a partir das 02:10, um login
com senha às 02:33:07, um salto para o `files` dois minutos e meio depois, o firewall vendo isso no mesmo
segundo, uma transferência para fora às 02:41:12 contada duas vezes (o primeiro pacote no firewall e o total
no fluxo), e a volta com chave às 03:05:22.

Três regras mantêm uma linha do tempo honesta. **Um fuso**, dito no cabeçalho; aqui o UTC é a referência e o
horário local aparece ao lado. **Cada linha diz de onde veio**, para que uma entrada duvidosa possa ser
rastreada até a linha crua. E **inferências são marcadas como inferências**: "uma chave foi acrescentada entre
02:35 e 03:05" entra na linha do tempo, rotulada como inferida do login das 03:05, até a aula 17 achar a
evidência no disco.
