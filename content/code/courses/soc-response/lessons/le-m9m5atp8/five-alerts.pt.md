---
title: Cinco alertas, um de cada vez
version: 1
---

A primeira regra da aula 4 gerou cinco alertas. Pegue-os na ordem em que chegaram, como uma fila os
entregaria. O primeiro veio de `203.0.113.41` na segunda:

```
ana@soc:~/week$ bash context.sh 203.0.113.41
day         product   action      accounts  n
----------  --------  ----------  --------  -
2026-09-14  firewall  connection            2
2026-09-14  sshd      failure     helena    1
2026-09-14  sshd      success     helena    1
2026-09-15  firewall  connection            1
2026-09-15  sshd      success     helena    1
2026-09-16  firewall  connection            1
2026-09-16  sshd      success     helena    1
2026-09-17  firewall  connection            1
2026-09-17  sshd      success     helena    1
2026-09-18  firewall  connection            1
2026-09-18  sshd      success     helena    1
```

**O que disparou:** uma falha e depois um sucesso. **É real:** sim, as duas linhas existem. **É esperado:**
este endereço entra como helena toda manhã de dia útil, uma vez, com um erro de digitação na segunda. Feche
como **falso positivo**, motivo "usuária conhecida, endereço conhecido, um erro de digitação", e siga. Os dois
alertas de `203.0.113.23`, na terça e na quarta, se leem do mesmo jeito para a carla, como a aula 4 mostrou;
os dois fecham com o mesmo motivo. Três alertas, três minutos.

O quarto, de `203.0.113.66` na quinta às 02:33:

```
ana@soc:~/week$ bash context.sh 203.0.113.66
day         product   action      accounts                                                                                                           n 
----------  --------  ----------  -----------------------------------------------------------------------------------------------------------------  --
2026-09-17  firewall  connection                                                                                                                     59
2026-09-17  sshd      failure     ana,bruno,carla,diego,helena,root,admin,test,oracle,ubuntu,user,backup,git,finance,hr,scanner,printer,support,dev  57
2026-09-17  sshd      success     bruno                                                                                                              2 
```

Nada antes de quinta. 57 falhas em 19 contas, a maioria nomes que não existem aqui, depois dois sucessos
como bruno. **É esperado?** O histórico do próprio bruno responde:

```
ana@soc:~/week$ sqlite3 -header -column siem.db "SELECT datetime(timestamp, '-3 hours') AS local, host, method, src_ip FROM logs WHERE user = 'bruno' AND action = 'success'"
local                host   method     src_ip       
-------------------  -----  ---------  -------------
2026-09-14 08:33:31  gw     password   203.0.113.17 
2026-09-15 08:00:36  gw     password   203.0.113.17 
2026-09-16 08:28:51  gw     password   203.0.113.17 
2026-09-17 02:33:07  gw     password   203.0.113.66 
2026-09-17 02:35:40  files  password   198.51.100.22
2026-09-17 03:05:22  gw     publickey  203.0.113.66 
2026-09-17 08:35:03  gw     password   203.0.113.17 
2026-09-18 08:29:00  gw     password   203.0.113.17 
```

Em todos os outros dias, o bruno entra uma vez, por volta das oito e meia, com senha, de `203.0.113.17`. Na
quinta há três logins que ele não reconheceria: de um endereço novo às 02:33, **seguindo do `gw` para o
servidor de arquivos dois minutos depois**, e de volta às 03:05 com chave, um método que ele nunca usa. E às
08:35 ele entrou como sempre de casa, então a pessoa e a conta estavam em dois lugares naquela manhã.

Isso basta para escalar. Mais um olhar, para o que passou pelo firewall naquela hora, entra na nota de
escalação:

```
ana@soc:~/week$ sqlite3 -header -column siem.db "SELECT datetime(timestamp, '-3 hours') AS local, product, src_ip, dst_ip, dst_port, bytes FROM logs WHERE timestamp BETWEEN '2026-09-17 05:30' AND '2026-09-17 06:30' AND product IN ('firewall', 'flow') ORDER BY timestamp"
local                product   src_ip         dst_ip         dst_port  bytes    
-------------------  --------  -------------  -------------  --------  ---------
2026-09-17 02:33:07  firewall  203.0.113.66   198.51.100.22  22                 
2026-09-17 02:35:40  firewall  198.51.100.22  192.168.20.10  22                 
2026-09-17 02:41:12  firewall  192.168.20.10  203.0.113.200  443                
2026-09-17 02:41:12  flow      192.168.20.10  203.0.113.200  443       612408119
2026-09-17 03:05:22  firewall  203.0.113.66   198.51.100.22  22                 
```

Às 02:41, o `files` abriu uma conexão para `203.0.113.200` e enviou **612.408.119 bytes**, cerca de 612 MB,
para um endereço que o backup nunca usa. O quinto alerta, às 03:05, é o mesmo visitante; ele entra na mesma
escalação em vez de abrir outra. **Cinco alertas viraram três fechamentos e uma escalação**, e a escalação é
sobre algo para o qual nenhuma regra foi escrita: a transferência.
