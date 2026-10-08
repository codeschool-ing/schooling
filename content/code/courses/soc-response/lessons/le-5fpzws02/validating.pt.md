---
title: Validar, e o resultado negativo
version: 1
---

Uma pilha aponta; não prova. A **validação** pergunta se a coisa rara é o que a hipótese diz que é, usando
dados que a busca não usou. Para as três linhas da H1, a aula 7 já fez o trabalho: o endereço tentou 19 contas
antes, o dono da conta entrou normalmente de casa naquela mesma manhã, e uma transferência grande veio em
seguida. Fatos independentes, todos apontando para o mesmo lado: o achado está confirmado e vai para a
resposta a incidentes.

A H2 volta diferente:

```
ana@soc:~/week$ sqlite3 -header -column siem.db "SELECT src_ip, count(*) AS n FROM logs WHERE host = 'files' GROUP BY src_ip"
src_ip         n
-------------  -
198.51.100.22  6
```

Cada um dos seis logins no `files` veio do endereço do `gw`. **A H2 é falsa nesta semana**: ninguém chegou ao
`files` a não ser pelo `gw`. Isso é um **resultado negativo**, e ele vale exatamente tanto quanto a precisão
com que é escrito:

```localised
Caçada H2, 21 set 2026, ana
Hipótese: alguém chegou ao files sem passar pelo gw.
Dados: siem.db, logins do sshd no files, de 14 a 20 set 2026 (6 eventos).
Método: contar os logins no files por endereço de origem.
Resultado: negativo. Todos os 6 de 198.51.100.22 (gw).
Limites: cobre só SSH; os outros serviços do files não registram no SIEM.
```

A última linha é a importante. Um resultado negativo não diz nada sobre dados que não foram pesquisados, e
**uma caçada que não diz os próprios limites vai ser lida como se cobrisse mais do que cobriu**. Aqui, é
também uma lacuna a corrigir: se o `files` tivesse uma segunda porta de entrada, o SIEM não a veria.
