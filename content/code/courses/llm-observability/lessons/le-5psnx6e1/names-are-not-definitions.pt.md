---
title: Um nome não é uma definição
version: 2
---

Todo framework tem uma métrica chamada faithfulness e uma chamada relevance, e os nomes sugerem que
medem a mesma coisa. Não medem. As definições abaixo foram lidas no código das versões que a aula 12
instala, RAGAS 0.3.1 e DeepEval 4.2.8:

| Nome | Neste curso | No RAGAS | No DeepEval |
| --- | --- | --- | --- |
| relevance | o veredicto do juiz, recusa decidida pelo gabarito | um modelo escreve perguntas que a resposta responderia; a média do cosseno delas com a pergunta real, vezes zero se a resposta for evasiva | a parcela das afirmações da resposta que um modelo julga relevantes, as duvidosas contadas como relevantes |
| faithfulness | a nota do juiz para o apoio das afirmações da resposta nas fontes | a parcela das afirmações da resposta que um modelo julga dedutíveis do contexto | a parcela das afirmações da resposta que um modelo não acha contraditas pelo contexto, as duvidosas contadas como aprovadas |
| context precision | parcela de trechos que são gold, pesada pela posição | parcela de trechos que um modelo, ou uma comparação de texto, julga úteis contra uma referência, pesada pela posição | parcela de trechos que um modelo julga relevantes para a resposta esperada, pesada pela posição |

Três diferenças são grandes o bastante para mudar o veredicto sobre a mesma resposta:

- **O RAGAS dá 0 de relevância a uma resposta evasiva.** O prompt que pede a pergunta gerada também
  pergunta se a resposta é evasiva (*noncommittal*), e dá "I don't know" como exemplo. A recusa
  combinada é evasiva por essa definição, então o RAGAS reprova toda recusa, como o juiz deste curso fez
  na aula 10 e a rubrica não faz.
- **A faithfulness do DeepEval pergunta se uma afirmação é contradita; a do RAGAS, se pode ser
  deduzida.** Uma resposta que acrescenta um fato que o contexto não menciona, sem contradizê-lo, passa
  na primeira e falha na segunda.
- **Duvidoso é uma decisão.** O DeepEval conta um veredicto duvidoso (*borderline*) como aprovado nessas
  duas métricas por padrão, e oferece um ajuste para contá-lo como reprovado na faithfulness. As mesmas
  respostas podem ter notas diferentes conforme um padrão que a maioria das pessoas nunca lê.

Nenhuma delas está errada. Cada uma é uma definição que alguém escolheu, e um número só é comparável
com outro calculado pela mesma definição, nas mesmas respostas, com o mesmo modelo de juiz. **Duas
equipes que relatam "faithfulness 0,9" podem estar relatando coisas diferentes**, e o relato honesto
nomeia o framework, a versão, a classe da métrica e o modelo que a rodou.

As definições do próprio curso estão no `metrics.py`, uma docstring cada. A aula 12 roda os dois frameworks
nas mesmas quarenta e oito respostas, com o `llama3.2:3b` como juiz.
