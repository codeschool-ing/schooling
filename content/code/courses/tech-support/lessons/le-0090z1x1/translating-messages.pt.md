---
title: Quatro mensagens, traduzidas
version: 1
---

Quatro mensagens que um usuário poderia ler ao telefone, produzidas de verdade no `pc1`:

```
ana@pc1:~$ curl -sS -m 10 http://intranet/
curl: (6) Could not resolve host: intranet
ana@pc1:~$ sudo -u elisa cat /etc/shadow
cat: /etc/shadow: Permission denied
ana@pc1:~$ curl -sS -m 10 http://localhost:8080/
curl: (7) Failed to connect to localhost port 8080 after 31 ms: Couldn't connect to server
ana@pc1:~$ lpstat -p office
printer office disabled since Sat Sep 26 00:47:23 2026 -
        paper jam, tray 2
```

E o que cada uma significa para quem a viu:

| a máquina disse | o que significa para a pessoa | o que você poderia dizer |
|---|---|---|
| `Could not resolve host: intranet` | o computador não achou o endereço da intranet | *"Seu computador não achou onde fica a intranet. Estou vendo por quê."* |
| `Permission denied` | esta conta não pode abrir aquele arquivo | *"Sua conta não tem permissão para abrir esse arquivo. Se você precisa dele para o trabalho, vejo quem pode liberar."* |
| `Couldn't connect to server` | nada respondeu naquele endereço | *"O programa que você está tentando acessar não está respondendo. Não é o seu computador."* |
| `disabled ... paper jam, tray 2` | a impressora parou sozinha | *"A impressora parou por causa de papel preso na bandeja 2. Depois de tirar, ela continua."* |

Dois hábitos aparecem na coluna da direita. **Cada frase diz quem não tem culpa quando isso é verdade**
("não é o seu computador"), porque as pessoas supõem que quebraram alguma coisa. E **nenhuma promete o que
ainda não se sabe**: "estou vendo por quê" é honesto onde "daqui a pouco volta" é um palpite.
