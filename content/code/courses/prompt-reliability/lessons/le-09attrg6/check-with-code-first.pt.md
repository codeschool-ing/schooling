---
title: Primeiro, verifique com código
version: 2
---

Duas respostas da execução com temperatura 0 não são JSON. Um programa as acha sem perguntar a
ninguém:

```
ana@lab:~/triage$ pl check runs/v6.jsonl --failures | grep json
json         68     2
t38    json      not a JSON object
h28    json      not a JSON object
```

O `json.loads` falha no `t38` e no `h28`, toda vez, pelo motivo que de fato está lá:

```
ana@lab:~/triage$ pl show runs/v6.jsonl t38
│ {"category": "returns", "urgency": "high", "summary": "Ebook won"}}
stop: stop, tokens in 145, out 22, 2.5 s
```

O resumo para no apóstrofo de *won't* e uma segunda chave fecha o objeto, a falha que a aula 15
registrou como F-0001. O revisor leu esta resposta e disse OK. Ele marcou o `h28`, que tem o mesmo
defeito, com *the category is missing a value*, que não é o defeito. **Uma verificação escrita em
código é exata e não custa nada**: nunca duvida de uma resposta válida, nunca deixa passar uma
quebrada, e não acrescenta chamada nenhuma. A revisão do modelo das mesmas setenta respostas custou
setenta chamadas e chamou 45 delas de quebradas.

## O que o código vê

A maior parte do que dá errado com as respostas deste curso é visível para um programa:

- Análise: a resposta é JSON, e nada mais.
- Campos: os campos pedidos, e nenhum outro. Foi o que pegou o número de pedido copiado na aula 1.
- Rótulos: cada valor vem da sua lista. Foi o que pegou *events* na aula 18.
- Um canário: uma resposta que repete uma palavra que o prompt nunca deve revelar, o teste que a
  aula 10 usou para instruções vazadas.
- Tamanho e palavras: a aula 6 contou tamanhos e a aula 12 verificou o tom com regras.

Cada uma dessas é uma linha de código com uma resposta certa, e nenhuma deveria ser uma pergunta
para um modelo.

## O que só um modelo vê

O que o código não vê é se `returns` é a leitura certa de uma mensagem sobre um pacote que nunca
chegou. É a única pergunta para a qual uma autoverificação existe, e nos números deste laboratório
este revisor a responde pouco melhor que o acaso. Antes de uma verificação assim entrar num
pipeline, decida o que uma marcação faz. Sobrescrever a resposta agiria sobre 27 alarmes falsos em
setenta. **Mandar uma resposta marcada para uma pessoa** transforma uma marcação numa mensagem que
alguém lê, e aqui isso são 45 mensagens para achar 18.

A ordem sai dos custos:

1. O código verifica toda resposta, exatamente e de graça, e manda as que reprovam de volta ou para
   uma pessoa.
2. A verificação de um modelo lê o que passou e marca o que lhe parece duvidoso, depois de ter sido
   medida e se mostrado melhor que uma moeda.
3. Uma pessoa lê o que foi marcado.

**Meça a verificação do modelo como qualquer outra**: contra rótulos que uma pessoa deu, em
precisão e revocação, na configuração que você roda, e contra uma moeda. E lembre-se da aula 19 ao
escolher o verificador. Um revisor que compartilha os pontos cegos do modelo que respondeu
compartilha os erros que ele deixa passar, e um modelo diferente, ou o mesmo com evidência que a
primeira chamada não tinha, é o jeito de fazer os erros dele serem outros.
