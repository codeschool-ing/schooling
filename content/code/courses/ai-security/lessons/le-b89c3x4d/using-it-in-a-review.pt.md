---
title: Usar a lista numa revisão
version: 1
---

A lista é mais útil num momento: quando um recurso está para ir ao ar e alguém precisa dizer o que pode
dar errado com ele. O método é o mesmo do inventário da aula 1, com os nomes da OWASP como linhas.

## Duas linhas sem nada

```
ana@lab:~/guard$ guard owasp --uncovered
LLM04 Data and Model Poisoning           NOT COVERED IN THIS LAB
LLM08 Vector and Embedding Weaknesses    NOT COVERED IN THIS LAB
10 categories, 2 with no control in this lab
```

*Data and model poisoning* (LLM04) e *vector and embedding weaknesses* (LLM08) tratam dos dados de que
um modelo aprende ou que ele busca: um conjunto de treino ou uma base vetorial que alguém adulterou, ou
que vaza o que guarda. O assistente da Tarefa, como está neste laboratório, não busca nada além de três
páginas da central de ajuda escritas pela Tarefa, então a exposição hoje é pequena. **Uma exposição pequena ainda é uma linha.**

## Uma revisão, linha a linha

Para um recurso em revisão, cada uma das dez recebe uma de três respostas, as mesmas três da aula 1:

- **um controle**, nomeado, com a aula ou o código que o fornece;
- **não se aplica**, com o motivo: um assistente sem ferramentas não tem agência excessiva a revisar, e o
  motivo fica escrito para ser revisto no dia em que ele ganhar uma;
- **um risco aceito**, com quem o aceitou e até quando.

Uma revisão que termina com dez respostas, três delas *risco aceito*, é melhor do que uma que termina
com dez vistos. Ela diz onde está o trabalho.

## A lista vai mudar

A edição de 2025 reorganizou a de 2023: algumas entradas foram fundidas, *system prompt leakage* e
*vector and embedding weaknesses* entraram, e *misinformation* substituiu a mais estreita
*overreliance*. A próxima edição vai mudar de novo, porque as aplicações mudam. Mantenha o mapa no
repositório, como o inventário, e atualize-o quando a OWASP atualizar; os controles não dependem dos
números, e um revisor que sabe o que cada controle faz encaixa uma categoria nova numa tarde.
