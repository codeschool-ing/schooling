---
title: Uma hipótese que pode estar errada
version: 1
---

Uma hipótese útil tem três propriedades: é **específica** o bastante para apontar dados, **testável** com os
dados que você tem, e **refutável**, o que quer dizer que existe um resultado que a provaria errada. "Talvez
tenhamos sido invadidos" falha nas três. Três que passam, para a empresa do laboratório, cada uma de uma fonte
de inspiração diferente:

| | hipótese | inspirada em | dados |
|---|---|---|---|
| **H1** | se uma conta foi usada por outra pessoa que não a dona nesta semana, ela entrou de um endereço que aquela conta nunca tinha usado | ATT&CK T1078, Valid Accounts | logins bem-sucedidos, por conta e endereço |
| **H2** | se alguém chegou ao `files` sem passar pelo `gw`, há um login no `files` a partir de um endereço que não é o do `gw` | o desenho da rede: o `files` só deveria ser alcançável a partir do `gw` | logins no `files`, por origem |
| **H3** | se a conta de uma pessoa foi usada fora do expediente, há logins em horas em que ninguém trabalha | os hábitos da empresa: todo mundo começa por volta das oito | logins bem-sucedidos, por hora |

Repare na forma: **"se isto aconteceu, então isto estaria nos dados."** A segunda metade é o que torna uma
hipótese testável, porque diz exatamente o que procurar e onde. Ela também diz o que a ausência significa:
se os dados da H2 não mostram nenhuma origem além do `gw`, a H2 é falsa nesta semana, e você pode dizer isso.

Hipóteses vêm da inteligência (a aula 8 disse que campanhas de adivinhação atingem o setor), do ATT&CK
(escolha uma técnica e pergunte o que ela deixaria nos seus logs), do próprio desenho do ambiente (o que nunca
deveria acontecer aqui?) e do último incidente (como a mesma coisa pareceria da próxima vez?).
