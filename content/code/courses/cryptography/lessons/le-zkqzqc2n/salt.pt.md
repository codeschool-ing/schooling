---
title: Um sal por conta
version: 1
---

**Um sal é um valor aleatório, diferente para cada conta, misturado à senha antes do hash e guardado
ao lado do resultado.** Ele não é secreto. Seu único trabalho é fazer a mesma senha dar um valor
guardado diferente em cada conta, e em cada sistema.

## O mesmo banco, com sal

As oito contas de novo, agora guardadas como SHA-256 de um sal de 16 bytes seguido da senha. Cada
linha traz o esquema, o sal em Base64 e o resumo, separados por `$`:

```
ana@lab:~/lab$ vcrypt store salted-sha256 data/users.csv > store-salted.txt; head -3 store-salted.txt
ana.lima:sha256$0/nfYBQd1s+OH9g42kQLEg$cefd1b667bdaf806ce088a7a42ea0a13400e51d4bb2572239bc9ddadd5a3877c
bruno.reis:sha256$qEu3wpXcXcqDBA7Q2eSpmQ$da4cfbd05bd39f57f8564ab7168d6ab31a75a92c38068f7a2b5234cd398668d2
carla.souza:sha256$kQnk8qVcKObWWJG4rA4n3w$b6bb275d982eaac82714b707ee5a4656105871b6b3e1033ba3c5f5509218a389
```

Ana e Carla escolheram a mesma senha, e os valores guardados delas não têm nada em comum. A
auditoria que achou dois grupos na seção anterior não acha nenhum:

```
ana@lab:~/lab$ vcrypt audit store-salted.txt
8 accounts, 8 different stored values
  no two accounts share a stored value
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"Dois painéis. Sem sal: uma lista pré-calculada de resumos de senhas comuns bate com Ana, Carla e Fábio de uma vez, porque os valores guardados deles são idênticos. Com sal: o valor de cada conta mistura o próprio sal, então a mesma senha dá três valores sem relação, e nenhuma lista calculada antes bate com nenhum deles; cada conta precisa ser atacada sozinha.\"><defs><marker id=\"salt-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">sem sal</text><text x=\"380\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">com um sal por conta</text><rect x=\"20\" y=\"36\" width=\"150\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"95\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">lista pré-calculada</text><text x=\"95\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">de senhas comuns</text><rect x=\"200\" y=\"120\" width=\"150\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"210\" y=\"135\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ana.lima: 9df1…</text><polyline points=\"170,80 198,135\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#salt-ah-amber)\"></polyline><rect x=\"200\" y=\"160\" width=\"150\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"210\" y=\"175\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">carla.souza: 9df1…</text><polyline points=\"170,80 198,175\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#salt-ah-amber)\"></polyline><rect x=\"200\" y=\"200\" width=\"150\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"210\" y=\"215\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">fabio.nunes: 9df1…</text><polyline points=\"170,80 198,215\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#salt-ah-amber)\"></polyline><rect x=\"400\" y=\"120\" width=\"170\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"410\" y=\"135\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ana.lima: cefd…</text><text x=\"590\" y=\"135\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">sal próprio</text><rect x=\"400\" y=\"160\" width=\"170\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"410\" y=\"175\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">carla.souza: b6bb…</text><text x=\"590\" y=\"175\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">sal próprio</text><rect x=\"400\" y=\"200\" width=\"170\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"410\" y=\"215\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">fabio.nunes: 0244…</text><text x=\"590\" y=\"215\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">sal próprio</text><rect x=\"380\" y=\"36\" width=\"150\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><text x=\"455\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lista pré-calculada</text><text x=\"455\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">não bate com nada</text><text x=\"20\" y=\"248\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">mesma senha, mesmo valor: uma consulta acha três contas</text></svg>", "caption": "Um sal transforma uma consulta contra o banco inteiro em trabalho separado para cada conta."}
```

## O que o sal derrota, e o que não derrota

O sal elimina os dois primeiros problemas da seção anterior:

- **senhas iguais deixam de ficar visíveis**, porque o sal de cada conta é diferente;
- **listas pré-calculadas deixam de funcionar**, porque uma lista teria de ser calculada para cada
  sal possível, e com 16 bytes aleatórios há 2¹²⁸ deles. Um atacante agora precisa começar do zero
  em cada conta, com o sal daquela conta.

Ele não faz nada contra o terceiro. SHA-256 com sal é exatamente tão rápido quanto SHA-256 simples,
então, escolhida uma conta, o atacante ainda consegue testar bilhões de candidatas por segundo
contra ela. O sal transforma um ataque ao banco inteiro em oito ataques separados; não deixa nenhum
deles mais lento.

## Como um sal é escolhido

- **Aleatório**, do gerador criptográfico do sistema, no momento em que a senha é guardada. O
  laboratório deriva seus sais de rótulos para que as transcrições se repitam; é a mesma
  conveniência dos IVs fixos da aula 1, e a mesma coisa que um sistema real nunca pode fazer.
- **Novo a cada troca de senha**, não um por usuário para sempre. Um sal reaproveitado entre as
  senhas de um usuário mostraria quando alguém voltou a uma senha antiga.
- **Longo o bastante para ser único**: 16 bytes é o tamanho usual, e o padrão de toda biblioteca
  chega lá.
- **Guardado ao lado do hash**, no mesmo campo, como acima. Ele é necessário para verificar, e
  escondê-lo não acrescenta nada.

Na prática você nunca manipula um sal. O bcrypt e o Argon2id, assunto da próxima seção, geram um e
o escrevem na string guardada por você. Um projeto que pede para você gerenciar sais à mão é sinal
de um esquema mais antigo.
