---
title: O que é uma versão
version: 1
---

A resposta natural é que uma versão de um prompt é o texto dele, e cada commit do arquivo é uma nova
versão. **Isso é quase tudo, e a parte que falta é a parte que quebra.**

## O id é o arquivo

Todo `pl run` imprime um id do prompt, e o id não é um contador. São os oito primeiros caracteres de
um hash SHA-256 dos bytes do arquivo, então os mesmos bytes dão sempre o mesmo id, venham de onde
vierem:

```
ana@lab:~/triage$ pl run prompts/triage.txt cases/dev.jsonl --out runs/now.jsonl
40 calls, prompt c1916fcd, written to runs/now.jsonl
ana@lab:~/triage$ git show c8470c9:prompts/triage.txt > runs/triage-c8470c9.txt
ana@lab:~/triage$ pl run runs/triage-c8470c9.txt cases/dev.jsonl --out runs/c8470c9.jsonl
40 calls, prompt c1916fcd, written to runs/c8470c9.jsonl
ana@lab:~/triage$ git diff c8470c9 03e1151 -- prompts/triage.txt | wc -l
0
```

`git show c8470c9:prompts/triage.txt` imprime o arquivo como ele era naquele commit, e a execução
dessa cópia antiga tem o id do arquivo de hoje, `c1916fcd`. O diff entre os dois commits não tem
linha nenhuma: o commit mais novo devolveu o arquivo exatamente ao que era em 11 de agosto, então os
dois são uma versão só com dois hashes de commit. **Um id calculado do conteúdo não se deixa enganar
por um nome novo, uma cópia ou uma reversão**, e é isso que você quer da coisa sob a qual um resultado
é arquivado.

## O mesmo id, outro prompt

Agora rode o mesmo arquivo com um parâmetro mudado na linha de comando:

```
ana@lab:~/triage$ pl run prompts/triage.txt cases/dev.jsonl --set temperature=0.8 --out runs/hot.jsonl
40 calls, prompt c1916fcd, written to runs/hot.jsonl
ana@lab:~/triage$ pl check runs/hot.jsonl
check      pass  fail
json         40     0
fields       40     0
labels       40     0
category     31     9
urgency      28    12
all          28    12
```

O id continua `c1916fcd`, e a nota foi de 36 em 40 para 28. O arquivo não mudou, então o hash dele
também não; o que mudou foi uma configuração que o hash nunca viu. Duas execuções arquivadas sob um
id agora discordam em oito mensagens, e **quem ler os resultados depois não tem como distinguir uma
da outra**. A aula 8 é onde a temperatura em si é medida; aqui ela é só a configuração mais fácil de
mudar sem querer.

É por isso que a bancada lê parâmetros do topo do arquivo do prompt. Um arquivo pode começar com
linhas `nome: valor` e uma linha `---`, e tudo acima do `---` é configuração:

```
ana@lab:~/triage$ head -n 2 prompts/v17-static-first.txt
cache: on
---
```

`cache` é o que a aula 17 usa; `model`, `temperature`, `top_k`, `top_p` e `max_tokens` são os
outros. Um parâmetro escrito ali faz parte dos bytes, então mudá-lo muda o id. **Um parâmetro passado
na linha de comando pertence à execução, e nada o registra.**

## Quatro coisas fazem uma versão

- **O texto**, que o git já acompanha.
- **Os parâmetros**, no arquivo, onde o hash os enxerga.
- **O modelo.** Outro modelo com o mesmo texto é outro prompt em tudo o que importa, porque o texto é
  só metade do que produz a resposta. Vários provedores publicam nomes de modelo com uma data, ao
  lado de apelidos mais curtos que passam a apontar para um modelo mais novo quando ele sai; a
  documentação de modelos da Anthropic e a da OpenAI descrevem a diferença. Ponha o nome com data no
  cabeçalho e a troca vira um commit que alguém vê. O substituto tem um modelo só, então o
  laboratório não consegue mostrar este mudando.
- **O conjunto de teste**, porque uma nota pertence a um par. Trinta e seis de quarenta só significa
  algo ao lado das quarenta, e `cases/dev.jsonl` também está no git, então a versão dele é um commit
  como a do prompt.

Um resultado anotado sem as quatro coisas é um resultado sobre algo que você não consegue mais
reconstruir.
