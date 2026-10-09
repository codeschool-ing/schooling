---
title: O que é uma versão
version: 2
---

A resposta natural é que uma versão de um prompt é o texto dele, e um commit do arquivo é uma versão
nova. **Isso é quase tudo, e a parte que falta é a parte que quebra.**

## O id é o arquivo

Todo `pl run` imprime um id de prompt, e o id não é um contador. São os oito primeiros caracteres de
um hash SHA-256 dos bytes do arquivo, então os mesmos bytes sempre dão o mesmo id, venham de onde
vierem:

```
ana@lab:~/triage$ pl run prompts/triage.txt cases/dev.jsonl --out runs/now.jsonl
40 calls, prompt c1916fcd, llama3.2:3b, written to runs/now.jsonl
ana@lab:~/triage$ git show c8f1927:prompts/triage.txt > runs/triage-c8f1927.txt
ana@lab:~/triage$ pl run runs/triage-c8f1927.txt cases/dev.jsonl --out runs/c8f1927.jsonl
40 calls, prompt c1916fcd, llama3.2:3b, written to runs/c8f1927.jsonl
ana@lab:~/triage$ git diff c8f1927 85dfa4e -- prompts/triage.txt | wc -l
0
```

O `git show c8f1927:prompts/triage.txt` imprime o arquivo como ele era naquele commit, e a execução
dessa cópia antiga tem o id do arquivo de hoje, `c1916fcd`. O diff entre os dois commits não tem
linha nenhuma: o commit mais novo devolveu o arquivo exatamente ao que ele era em 11 de agosto, então
os dois são uma versão sob dois hashes de commit. **Um id calculado a partir do conteúdo não se deixa
enganar por uma renomeação, uma cópia ou uma reversão**, que é o que você quer da coisa sob a qual um
resultado é arquivado.

## O mesmo id, outro prompt

Agora rode o mesmo arquivo com um parâmetro mudado na linha de comando:

```
ana@lab:~/triage$ pl run prompts/triage.txt cases/dev.jsonl --set temperature=0.8 --out runs/hot.jsonl
40 calls, prompt c1916fcd, llama3.2:3b, written to runs/hot.jsonl
ana@lab:~/triage$ pl check runs/hot.jsonl
check      pass  fail
json         39     1
fields       39     1
labels       39     1
category     36     4
urgency      24    16
all          24    16
```

O id continua `c1916fcd`, e 24 de 40 passam, que é também o que a execução padrão aprova; a última
seção desta aula compara as duas. O arquivo não mudou, então o hash dele também não: o que mudou foi
uma configuração que o hash nunca viu. O mesmo total não diz nada sobre se as mesmas mensagens
passaram, e não passaram. **Duas execuções arquivadas sob um id, feitas com configurações
diferentes, e quem ler os resultados depois não tem como distingui-las.** A aula 8 é onde a
temperatura em si é medida; aqui ela é só a configuração mais fácil de mudar por acidente.

É por isso que o harness lê parâmetros do topo do arquivo do prompt, como fazem o `v6-header.txt` da
aula 4 e o `reply-varied.txt` da aula 8: um arquivo pode começar com linhas `nome: valor` e uma linha
`---`, e tudo acima do `---` é uma configuração. **Um parâmetro escrito ali faz parte dos bytes,
então mudá-lo muda o id. Um parâmetro passado na linha de comando pertence à execução, e nada o
registra.**

## Quatro coisas fazem uma versão

- **O texto**, que o git já acompanha.
- **Os parâmetros**, no arquivo, onde o hash consegue vê-los.
- **O modelo.** Outro modelo com o mesmo texto é outro prompt em tudo o que importa, porque o texto é
  só metade do que produz a resposta. O `pl` manda `llama3.2:3b`, um nome e uma tag; o `ollama list`
  do Ollama mostra o id por trás da tag, `a80c4f17acd5`, e uma tag pode ser baixada de novo e apontar
  para outros pesos. Provedores hospedados publicam nomes de modelo com uma data, ao lado de apelidos
  mais curtos que passam para um modelo mais novo quando um é lançado; a documentação de modelos da
  Anthropic e a da OpenAI descrevem a diferença. Ponha o nome exato no cabeçalho e uma troca vira um
  commit que alguém consegue ver.
- **O conjunto de teste**, porque uma nota pertence a um par. Uma contagem de quarenta só significa
  algo ao lado das quarenta, e o `cases/dev.jsonl` também pertence ao git, então a versão dele é um
  commit como a do prompt.

E a aula 8 acrescenta uma quinta que nenhum arquivo consegue guardar: **a máquina**. O mesmo prompt,
modelo, configuração e conjunto de teste imprimiram 22 numa máquina e 21 em outra. Um resultado
anotado sem tudo isso é um resultado sobre algo que você não consegue mais reconstruir exatamente; o
máximo que dá para fazer é anotar onde ele rodou.
