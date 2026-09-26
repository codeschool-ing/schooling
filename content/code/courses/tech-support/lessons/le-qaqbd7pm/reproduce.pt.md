---
title: Reproduzir: ver com os próprios olhos
version: 1
---

A primeira coisa é ver o que a Carla vê, no computador dela, com um comando que pergunta o que o navegador
dela pergunta:

```
ana@pc1:~$ date "+%H:%M"; curl -sS -m 10 http://intranet/
00:18
curl: (7) Failed to connect to intranet port 80 after 3108 ms: Couldn't connect to server
ana@pc1:~$ curl -sS -m 10 http://intranet/
curl: (7) Failed to connect to intranet port 80 after 3137 ms: Couldn't connect to server
```

Agora existe **uma mensagem, e uma hora**. O `curl` tentou conectar em `intranet` na porta 80 e desistiu
depois de 3108 milissegundos, e uma segunda tentativa levou 3137: o mesmo defeito, do mesmo jeito,
duas vezes. É isso que *reproduzido* quer dizer. É também mais do que o chamado dizia: "não abre" podia
ser uma página em branco, um erro do servidor ou uma tela de login, e cada um desses é um defeito
diferente.

Dois hábitos fazem este passo valer o tempo:

- **Copie a mensagem, nunca a resuma.** `Couldn't connect to server` depois de três segundos diz que nada
  respondeu. "Deu um erro" não diz nada.
- **Anote a hora.** Logs são procurados por hora, e "hoje de manhã" bate com horas deles.

Se você não consegue reproduzir um defeito, isso também é um achado, e não o fim: pergunte quando
acontece, de onde e com quem, aula 2, e registre a tentativa no chamado, aula 5.
