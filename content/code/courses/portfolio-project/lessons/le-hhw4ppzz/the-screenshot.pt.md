---
title: Uma captura que mostra o ponto
version: 1
---

A captura do README é a primeira evidência que quem avalia vê, aula 16. É um PNG no repositório, referenciado
na oitava linha do README:

```
ana@laptop:~/loanbook$ grep -n 'screenshot' README.md
8:![The list: four items out, one of them overdue](docs/screenshot.png)
ana@laptop:~/loanbook$ python3 -c 'import struct; d = open("docs/screenshot.png", "rb").read(24); print(d[1:4].decode(), *struct.unpack(">II", d[16:24]))'
PNG 1000 876
ana@laptop:~/loanbook$ du -h docs/screenshot.png
68K     docs/screenshot.png
```

Mil pixels de largura, 876 de altura, 68 kilobytes. Três decisões entraram nela.

**Mostra o estado que prova o ponto.** Não a página vazia, não o formulário: a semana semeada, com um
empréstimo marcado como atrasado. Quem avalia e vê *overdue* em negrito entende a regra principal do projeto
sem ler uma palavra sobre ela. Para um projeto cujo ponto é uma recusa, uma segunda captura com a mensagem da
recusa seria a próxima a acrescentar.

**Foi tirada por um script, não à mão.** Sete linhas de Playwright abrem a página em 1000 pixels, esperam as
linhas e salvam a página inteira. Um script tira a mesma imagem toda vez, então quando a página muda a
captura é refeita em segundos em vez de ficar desatualizada. Rodou na máquina que gravou o curso, com o
relógio do servidor em 3 de julho, o dia em que o README foi escrito, para as datas da imagem baterem com o
histórico; o `lab.sh` diz isso ao lado dos bytes da imagem.

**O texto alt diz o que ela mostra**: *the list: four items out, one of them overdue*. Essa frase também
testa a imagem: se você não consegue dizer numa linha o que uma captura mostra, ela não está mostrando uma
coisa só.
