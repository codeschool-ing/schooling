---
title: O que o log não diz
version: 1
---

É tentador tratar a história como a documentação: toda mudança está no git, com data e mensagem,
então quem quiser saber pode olhar. **A história diz o que mudou e quando. Ela quase nunca diz por
quê**, e o porquê é o que a próxima pessoa precisa.

Aqui está o registro inteiro de `prompts/triage.txt`, uma linha por commit:

```
ana@lab:~/triage$ git log --format='%h %ad %s' --date=short -- prompts/triage.txt
03e1151 2026-08-17 Put the examples back in JSON
31a6a59 2026-08-14 Make the examples easier to read
c8470c9 2026-08-11 Escape the message so it cannot close its own tags
931c548 2026-08-10 Put the message in tags and say it is data
9683448 2026-08-07 Ask for the JSON object and nothing else
f361c0a 2026-08-05 Add three examples of the answer
90a013e 2026-08-04 Ask for JSON, name the fields and list the labels
8ec39c2 2026-08-03 First triage prompt
```

Cada assunto descreve bem o seu diff. Nenhum diz que problema resolveu, o que mais foi tentado, ou o
que foi medido antes e depois. A mensagem do commit que quebrou tudo é o assunto e mais nada:

```
ana@lab:~/triage$ git log -1 --format=%B 31a6a59
Make the examples easier to read
```

## Seis meses depois

Imagine alguém que entra no time em fevereiro e abre `prompts/triage.txt` pela primeira vez. Os
exemplos são linhas compridas de JSON com todas as aspas, e são difíceis de ler. **A melhoria óbvia
é a que o `31a6a59` fez**, e nada perto do prompt diz que ela já foi feita, levou a nota a zero e foi
revertida três dias depois. O log tem os dois commits, mas ninguém lê um log procurando motivo para
não fazer alguma coisa. A pessoa que sabia mudou de time, e a explicação, se houve uma, está numa
conversa de chat que ninguém encontra.

A aula 14 pôs um número ao lado de cada commit. **Um número diz que uma mudança foi ruim; não diz o
que evitar da próxima vez**, nem quais das escolhas estranhas do prompt seguram alguma coisa. Isso
pede palavras, escritas enquanto o motivo ainda é conhecido e guardadas onde um leitor do prompt vai
encontrá-las.

## Três notas, três perguntas

O resto desta aula escreve três tipos de nota, e cada uma responde a uma pergunta diferente sobre o
prompt:

| nota | a pergunta que responde | escrita quando |
|---|---|---|
| registro de decisão | por que ele é assim? | se escolhe entre opções |
| registro de falhas | o que já deu errado, e o que impede que se repita? | uma falha é encontrada |
| ficha do prompt | o que é isto, quão bom é e quanto custa? | ele vai para produção, e a cada mudança |

Nenhuma delas existe no laboratório. São arquivos que você acrescentaria ao repositório ao lado do
prompt, e as versões mostradas nesta aula foram escritas pelo curso para mostrar a forma. Uma
mensagem de commit mais longa também ajudaria, mas fica espalhada pela história e só é lida por quem
já está rodando `git log`. **Notas ao lado do prompt são lidas por quem abre o prompt.**
