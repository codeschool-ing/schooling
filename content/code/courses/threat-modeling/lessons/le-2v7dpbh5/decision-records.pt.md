---
title: Registros de decisão
version: 1
---

O formato para registrar decisões que equipes de software já usam é o **registro de decisão de
arquitetura (ADR)**: um arquivo curto por decisão, com o contexto, a decisão e as consequências,
guardado no repositório e nunca editado depois. Uma decisão nova que muda uma antiga é um registro
novo que diz qual ele substitui. O curso `architecture-modeling` (aula 5) ensina ADRs para decisões
de projeto; decisões de segurança cabem no mesmo formato com três acréscimos.

| um ADR tem | um registro de decisão de segurança acrescenta |
|---|---|
| um título e um id | a ameaça ou o risco que ele decide, pelo id |
| o contexto | a estimativa, e a decisão: mitigar, eliminar, transferir ou aceitar |
| a decisão | o dono, com nome |
| as consequências | uma data de revisão, e os gatilhos que a antecipam |

A Vereda mantém dois tipos, com dois prefixos para distinguir numa lista: **RA** para um aceite de
risco, **DR** para qualquer outra decisão. O prefixo é para quem lê a pasta; nada no programa que os
lê depende dele.

### Front matter para a máquina, prosa para as pessoas

Cada registro começa com algumas linhas de **front matter**, os campos de que um programa precisa,
entre duas linhas de `---`. O resto é prosa para quem ler em seguida:

```
---
id: RA-001
threat: T14
decision: accept
owner: daniel
decided: 2026-10-01
review by: 2027-04-01
---
```

O front matter torna o registro consultável: um programa consegue listar cada aceite, cada decisão do
daniel, cada revisão deste mês, sem ninguém manter uma lista separada em dia. A prosa é o que torna
a decisão compreensível daqui a um ano, para alguém que não estava na sala.

### Nunca editado, só substituído

Um registro de decisão descreve o que foi decidido numa data, com o que se sabia então. **Editá-lo
depois reescreve a história**: o registro deixa de dizer o que o daniel assinou. Então uma decisão
mudada é um registro novo, com uma linha dizendo *substitui RA-001*, e o antigo fica. O único campo
que pode mudar no lugar é uma situação, se a equipe mantiver uma, porque ela descreve o presente e não
a decisão.

O git torna isso barato de conferir: `git log` num arquivo de decisão mostra se ele foi editado depois
do primeiro commit, e por quem.
