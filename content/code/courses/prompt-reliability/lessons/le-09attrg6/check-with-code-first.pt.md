---
title: Primeiro, verifique com código
version: 1
---

As duas primeiras marcações certas da autoavaliação na execução com temperatura 0 foram respostas
que não eram analisáveis. Um programa acha essas sem perguntar a ninguém:

```
ana@lab:~/triage$ pl check runs/v6.jsonl --failures | grep json
json         68     2
t26    json      not JSON
t39    json      not JSON
```

As mesmas duas, `t26` e `t39`, achadas porque o `json.loads` falhou. **Uma verificação escrita em
código é exata e não custa nada**: nunca duvida de uma resposta válida, nunca deixa passar uma
quebrada e não acrescenta chamada nenhuma. A revisão do modelo sobre as mesmas duas respostas
custou duas chamadas e não acertou mais.

## O que o código enxerga

Quase tudo o que dá errado nas respostas deste curso é visível para um programa:

- **Análise**: a resposta é JSON, e nada além disso.
- **Campos**: os campos pedidos, e nenhum outro. Foi isso que pegou o número de pedido copiado na
  aula 1.
- **Rótulos**: cada valor está na sua lista.
- **Um canário**: o `pl check --canary` reprova uma resposta que repete uma palavra que o prompt
  nunca deve revelar, o teste que a aula 10 usou para instruções vazadas.
- **Tamanho e palavras**: a aula 6 contou tamanhos e a aula 12 verificou o tom com regras.

Cada um desses é uma linha de código com resposta certa, e nenhum deveria ser uma pergunta para um
modelo.

## O que só um modelo enxerga

O que o código não enxerga é se `billing` é a leitura certa de uma mensagem sobre um cartão-presente.
É a única pergunta para a qual a autoavaliação serve, e com os números deste laboratório ela a
responde com precisão 0,73 e revocação 0,57. Antes de pôr uma verificação assim num pipeline, decida
o que uma marcação faz. Trocar a resposta pela sugestão do revisor teria substituído seis rótulos
errados por outros seis rótulos errados. **Encaminhar uma resposta marcada para uma pessoa**
transforma uma marcação duvidosa em onze mensagens que alguém lê, oito delas valendo a leitura.

A ordem vem dos custos:

1. O código verifica toda resposta, de forma exata e de graça, e devolve as que falham ou as manda
   para uma pessoa.
2. A verificação do modelo lê o que passou e marca o que lhe parece duvidoso.
3. Uma pessoa lê o que foi marcado.

**Meça a verificação do modelo como qualquer outra verificação**: contra rótulos que uma pessoa deu,
em precisão e revocação, na configuração que você roda. E lembre da aula 19 ao escolher o
verificador. Um revisor que tem os mesmos pontos cegos do modelo que respondeu deixa passar os
mesmos erros, e outro modelo, ou o mesmo com evidência que a primeira chamada não tinha, é o jeito
de fazer os erros dele serem outros.
