---
title: O que o log não diz
version: 2
---

É tentador tratar a história como a documentação: toda mudança está no git, com uma data e uma
mensagem, então quem quiser saber pode olhar. **A história diz o que mudou e quando. Quase nunca diz
por quê**, e o porquê é o que a próxima pessoa precisa.

Aqui está o registro inteiro do `prompts/triage.txt`, uma linha por commit, como o `history.sh` da
aula 14 o fez:

```
ana@lab:~/triage$ git log --format='%h %ad %s' --date=short -- prompts/triage.txt
85dfa4e 2026-08-17 Put the examples back in JSON
86913c0 2026-08-14 Make the examples easier to read
c8f1927 2026-08-11 Escape the message so it cannot close its own tags
a0f1d2a 2026-08-10 Put the message in tags and say it is data
5b2d8d0 2026-08-07 Ask for the JSON object and nothing else
ab97290 2026-08-05 Add three examples of the answer
61d470e 2026-08-04 Ask for JSON, name the fields and list the labels
341f8f8 2026-08-03 First triage prompt
```

Todo assunto é uma descrição justa do seu diff. Nenhum diz que problema resolveu, o que mais foi
tentado, ou o que foi medido antes e depois. Os dois commits com que a aula 14 terminou não trazem
nada além do assunto:

```
ana@lab:~/triage$ git log -1 --format=%B 86913c0
Make the examples easier to read

ana@lab:~/triage$ git log -1 --format=%B 85dfa4e
Put the examples back in JSON
```

## Seis meses depois

Imagine alguém que chega em fevereiro e abre o `prompts/triage.txt` pela primeira vez. Os exemplos
são linhas longas de JSON com todas as aspas escritas, e são difíceis de ler. **A melhoria óbvia é a
que o `86913c0` fez**, e nada perto do prompt diz que ela já foi feita, aprovou três mensagens a mais
no dev, e foi desfeita três dias depois por alguém que anotou o que fez e não por quê. O log tem os
dois commits, mas ninguém lê um log atrás de um motivo para não fazer algo, e aqui não há motivo
nenhum para achar. Quem sabia mudou de equipe, e a explicação, se houve uma, está numa conversa de
chat que ninguém encontra.

A aula 14 pôs um número ao lado de cada commit. **Um número diz o que uma mudança fez num conjunto
de teste; não diz o que foi pesado contra ela**, nem quais das escolhas estranhas do prompt sustentam
alguma coisa. Isso precisa de palavras, escritas enquanto o motivo ainda é conhecido, e guardadas
onde quem lê o prompt vai encontrá-las.

## Três notas, três perguntas

O resto desta aula escreve três tipos de nota, cada um respondendo a uma pergunta diferente sobre o
prompt:

| nota | a pergunta que responde | escrita quando |
|---|---|---|
| registro de decisão | por que ele é assim? | uma escolha é feita entre opções |
| registro de falhas | o que já deu errado, e o que impede que aconteça de novo? | uma falha é achada |
| ficha do prompt | o que é isto, quão bom é, e quanto custa? | ele é publicado, e a cada mudança |

Nenhuma delas é um programa. São arquivos que você acrescentaria ao repositório ao lado do prompt, e
as desta aula foram escritas pelo curso a partir das execuções que ela mostra. Uma mensagem de commit
mais longa também ajudaria, mas fica espalhada pela história e só é lida por quem já está rodando
`git log`. **Notas ao lado do prompt são lidas por quem abre o prompt.**
