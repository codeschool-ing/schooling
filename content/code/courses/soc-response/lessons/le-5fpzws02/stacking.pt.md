---
title: Empilhar: a ponta interessante é a curta
version: 1
---

O cavalo de batalha da caça é **empilhar**, também chamado de análise da cauda longa: contar quantas vezes
cada valor, ou cada combinação de valores, aparece, e ler a **ponta rara**. O comportamento normal se
repete; o incomum acontece uma ou duas vezes. Para a H1, empilhe os logins bem-sucedidos por conta e
endereço:

```
ana@soc:~/week$ sqlite3 -header -column siem.db "SELECT user, src_ip, count(*) AS logins FROM logs WHERE action = 'success' GROUP BY user, src_ip ORDER BY logins"
user    src_ip         logins
------  -------------  ------
bruno   198.51.100.22  1     
bruno   203.0.113.66   2     
ana     203.0.113.11   5     
bruno   203.0.113.17   5     
carla   203.0.113.23   5     
diego   198.51.100.22  5     
diego   203.0.113.31   5     
helena  203.0.113.41   5     
```

Ordenado do menos ao mais frequente, o topo da lista é onde olhar. Toda pessoa entra cinco vezes de um
endereço, que é um login por dia útil a partir de casa. O diego também chega ao `files` pelo `gw`
(`198.51.100.22`) todo dia; é o trabalho dele. Três linhas quebram o padrão, e as três são do bruno: **duas
vezes de `203.0.113.66`**, um endereço que a conta dele nunca tinha usado, e **uma vez do `gw` para o
`files`**, coisa que ele nunca faz. A H1 previu exatamente isso, e está lá.

A H3 empilha por hora:

```
ana@soc:~/week$ sqlite3 -header -column siem.db "SELECT strftime('%H', timestamp, '-3 hours') AS hour_local, count(*) AS logins FROM logs WHERE action = 'success' GROUP BY hour_local"
hour_local  logins
----------  ------
02          2     
03          1     
08          30    
```

Trinta logins às oito da manhã, a empresa inteira começando a trabalhar, e **três de madrugada**: dois às 02
e um às 03. Empilhar não diz quem foram; diz onde olhar em seguida, e a consulta seguinte (a aula 7 já a
rodou) aponta a conta do bruno nos três.

Empilhar funciona porque **atacantes são raros e organizações são repetitivas**. A fraqueza é o mesmo fato:
uma coisa legítima e rara, um funcionário novo ou uma tarefa trimestral, também fica na cauda curta, e é na
validação que ela é separada.
