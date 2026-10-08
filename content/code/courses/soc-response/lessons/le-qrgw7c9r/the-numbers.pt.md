---
title: Os números
version: 1
---

"O que aconteceu, e quando" se responde com evidência, não com memória, e o primeiro passo é transformar a
linha do tempo em **intervalos**. A aula 5 nomeou os três que um SOC acompanha, MTTD, MTTA e MTTR; um incidente
dá um valor de cada, e alguns outros que só um incidente tem. Escreva isto como `milestones.sql` em `~/week`:

```schooling-example
{"language": "sql", "file": "milestones.sql", "parts": [{"code": "-- milestones.sql: Thursday's incident in intervals, from the logs and the incident record\n.headers on\n.mode column\nCREATE TEMP TABLE milestone (name TEXT, at TEXT);  -- every time in UTC", "note": "Uma tabela temporária, que some quando o sqlite3 termina: os marcos são calculados a cada vez, nunca guardados junto aos logs."}, {"code": "INSERT INTO milestone\n  SELECT 'first guess', min(timestamp) FROM logs WHERE src_ip = '203.0.113.66' AND action = 'failure'\n  UNION ALL\n  SELECT 'first login', min(timestamp) FROM logs WHERE src_ip = '203.0.113.66' AND action = 'success';", "note": "Dois marcos vêm dos próprios logs, então não há como lembrar errado."}, {"code": "INSERT INTO milestone VALUES                   -- from the incident record, INC-2026-014\n  ('alert fired',  '2026-09-17 05:35:00'),\n  ('alert taken',  '2026-09-17 11:12:00'),\n  ('declared',     '2026-09-17 12:12:00'),\n  ('contained',    '2026-09-17 12:45:00'),\n  ('recovered',    '2026-10-02 13:00:00');", "note": "O resto vem do registro do incidente, copiado à mão, em UTC como todo o resto do siem.db."}, {"code": "SELECT \"from\", \"to\", \"from (UTC)\",\n       printf('%d d %02d h %02d min', s / 86400, s % 86400 / 3600, s % 3600 / 60) AS took\nFROM (SELECT a.name AS \"from\", b.name AS \"to\", a.at AS \"from (UTC)\",\n             strftime('%s', b.at) - strftime('%s', a.at) AS s   -- seconds between the two\n      FROM milestone a, milestone b\n      WHERE (a.name, b.name) IN (VALUES\n        ('first guess', 'first login'), ('first login', 'alert fired'), ('alert fired', 'alert taken'),\n        ('alert taken', 'declared'), ('declared', 'contained'), ('first login', 'contained'),\n        ('contained', 'recovered')))\nORDER BY \"from (UTC)\", s;", "note": "Cada par de marcos vira um intervalo, em segundos, impresso como dias, horas e minutos."}]}
```

O horário do alerta é o que a aula 5 supôs no exemplo dela; os outros são o registro de decisões da aula 13 e a
data em que a recuperação fechou. Rode contra o SIEM da aula 4:

```
ana@soc:~/week$ sqlite3 siem.db < milestones.sql
from         to           from (UTC)           took            
-----------  -----------  -------------------  ----------------
first guess  first login  2026-09-17 05:10:06  0 d 00 h 23 min 
first login  alert fired  2026-09-17 05:33:07  0 d 00 h 01 min 
first login  contained    2026-09-17 05:33:07  0 d 07 h 11 min 
alert fired  alert taken  2026-09-17 05:35:00  0 d 05 h 37 min 
alert taken  declared     2026-09-17 11:12:00  0 d 01 h 00 min 
declared     contained    2026-09-17 12:12:00  0 d 00 h 33 min 
contained    recovered    2026-09-17 12:45:00  15 d 00 h 15 min
```

Leia a coluna da direita de cima para baixo, e a noite conta a própria história:

- **23 minutos** de palpites até uma senha funcionar. O firewall viu cada tentativa; nada as impediu.
- **1 minuto** do login até o alerta. A regra estava boa: a detecção funcionou.
- **5 horas e 37 minutos** do alerta até uma pessoa assumi-lo. É o passo mais longo da noite, e ninguém errou
  nele: ninguém deveria estar acordado.
- **1 hora** de assumir o alerta até declarar, gasta confirmando com o gestor do bruno, pelas regras da aula 7.
- **33 minutos** de declarar até conter. O playbook e os runbooks fizeram o trabalho deles.
- **7 horas e 11 minutos** do primeiro login até a contenção: a janela do invasor. Os dados saíram nos
  primeiros oito minutos dela, que é a parte desconfortável.
- **15 dias** de recuperação, quase tudo as duas semanas de vigilância reforçada que a aula 14 pediu.

Os números não dizem que alguém foi lento. Dizem **para onde o tempo foi**, e ele foi para uma lacuna entre um
alerta e uma pessoa. Isso é um achado sobre o sistema, que é exatamente o que uma revisão procura.

Guarde o `milestones.sql`. O próximo incidente recebe a mesma consulta com outros horários, e depois de alguns
o *médio* de MTTD e MTTA começa a significar alguma coisa.
