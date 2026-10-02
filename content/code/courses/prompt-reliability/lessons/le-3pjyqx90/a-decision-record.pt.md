---
title: Um registro de decisão
version: 1
---

Um registro de decisão é um arquivo curto escrito no momento em que uma escolha é feita, dizendo o
que foi escolhido e por quê. A forma vem da arquitetura de software. No texto *Documenting
Architecture Decisions* (2011), Michael Nygard propôs um arquivo pequeno e numerado por decisão, com o
contexto, a decisão, o status e as consequências, guardado no repositório junto com o código. **Ele
funciona para prompts pelo mesmo motivo que funciona para código**: as escolhas que parecem mais
estranhas costumam ser as que alguém aprendeu do jeito difícil.

## A evidência primeiro

O registro abaixo responde à pergunta de fevereiro, por que os exemplos estão em JSON. A evidência é
uma comparação que qualquer pessoa pode rodar de novo, a versão com exemplos em linhas simples contra
a versão com exemplos em JSON:

```
ana@lab:~/triage$ git show 31a6a59:prompts/triage.txt > runs/plain.txt
ana@lab:~/triage$ pl run runs/plain.txt cases/dev.jsonl --out runs/plain.jsonl
40 calls, prompt 055cb22b, written to runs/plain.jsonl
ana@lab:~/triage$ pl run prompts/triage.txt cases/dev.jsonl --out runs/dev.jsonl
40 calls, prompt c1916fcd, written to runs/dev.jsonl
ana@lab:~/triage$ pl compare runs/plain.jsonl runs/dev.jsonl
runs/plain.jsonl         passes 0/40
runs/dev.jsonl           passes 36/40
fixed 36, broken 0, still passing 0, still failing 4
sign test on the 36 that changed: p = 0.000
```

Trinta e seis corrigidas e nenhuma quebrada. O valor p aparece como `0.000` porque é pequeno demais
para três casas decimais: trinta e seis mudanças todas no mesmo sentido não deixam espaço para sorte.

## O registro

```localised
0001  Os exemplos são escritos em JSON, exatamente como a resposta

Data     2026-08-17
Status   aceita

Contexto
  prompts/triage.txt mostra três exemplos da resposta. Em 14 de agosto
  (31a6a59) eles foram reescritos como linhas simples, para ler melhor.
  A instrução de responder só com o objeto JSON ficou.

Opções consideradas
  1. Sem exemplos, o formato descrito em palavras (90a013e): 24/40 em dev.
  2. Exemplos em linhas simples (31a6a59): 0/40 em dev.
  3. Exemplos em JSON, campo por campo a resposta (03e1151): 36/40 em dev.

Decisão
  Opção 3. O modelo copia a forma da resposta do primeiro exemplo,
  então cada exemplo é escrito exatamente como o programa que lê a
  resposta espera. Legibilidade não é motivo para mudá-los.

Evidência
  pl compare runs/plain.jsonl runs/dev.jsonl
  fixed 36, broken 0, still passing 0, still failing 4
  sign test on the 36 that changed: p = 0.000

Revisar quando
  o formato da resposta mudar, o modelo mudar, ou os exemplos forem
  trocados. Qualquer uma dessas passa pela barreira da aula 14.
```

Cada parte está ali para um leitor que não estava na sala.

- *Contexto* diz o que era verdade quando a escolha foi feita, para que o leitor saiba se ainda é.
- *Opções consideradas* lista as que perderam, com os números. A opção rejeitada é a que a próxima
  pessoa vai propor, e é aqui que ela descobre que já foi tentada.
- *Decisão* é um parágrafo, e dá o mecanismo além do veredito: a resposta copia o primeiro
  exemplo.
- *Evidência* é um comando e o que ele imprimiu. Colar a saída mantém a afirmação verificável
  depois que os arquivos de execução sumirem; o comando deixa qualquer um produzi-la de novo.
- *Revisar quando* nomeia as condições que tornariam a decisão errada. **Um registro sem isso
  parece permanente**, e nada num prompt é.

## Como manter os registros honestos

Numere os registros e nunca edite um depois de aceito. Quando uma decisão for revertida, escreva um
registro novo que diga isso e marque o antigo como substituído, que é a regra que o texto de Nygard
dá. O raciocínio antigo continua legível, e o novo precisa explicar o que mudou. Ligue cada registro
ao commit que o executa, para que o log aponte para o motivo mesmo sem conseguir guardá-lo.

**Escreva um quando houve uma escolha de verdade**, não a cada commit. O `c8470c9`, o escape da
mensagem, pedia uma frase na mensagem do commit; a forma dos exemplos, que uma pessoa razoável
mudaria, pedia um registro.
