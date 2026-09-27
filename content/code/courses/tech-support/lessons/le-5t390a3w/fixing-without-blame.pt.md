---
title: Consertando, e dizendo o que aconteceu
version: 1
---

O conserto é um comando, como o Bruno, e a checagem é a própria impressão dele:

```
ana@pc1:~$ sudo -u bruno lpoptions -d office >/dev/null && sudo -u bruno lpstat -d
system default destination: office
ana@pc1:~$ sudo -u bruno bash -c "cd ~ && lp report.txt"
request id is office-5 (1 file(s))
```

O padrão dele é `office` de novo, e o `report.txt` foi para `office`. O que sobra é contar para ele, e as
palavras decidem se ele abre o próximo chamado ou se vira sozinho:

- **Descreva a configuração, não o erro.** *"Seu computador estava configurado para mandar os documentos
  para a impressora de PDF, então eles viravam arquivos em vez de sair impressos. Já deixei como antes."*
  Tudo nela é verdade, e ninguém nela fez nada errado.
- **Mostre onde aconteceu**, para que da próxima vez que a janela aparecer ele saiba o que ela pergunta.
  É um minuto, e é o que evita o mesmo chamado no mês que vem.
- **Agradeça o detalhe sobre a janela.** Foi a coisa mais útil que alguém disse no chamado, e as pessoas
  repetem o que é agradecido.

A aula 4 é sobre explicar sem jargão e sem diminuir ninguém, e ela começa daqui.
