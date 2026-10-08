---
title: "Escolhendo o próximo token: temperatura, top-p e sementes"
version: 2
---

A seção 06 usou a decodificação gulosa, ficando sempre com o token do topo. Por padrão um modelo
não faz isso: ele **sorteia um, com peso pelas probabilidades**. Um token com 5% é escolhido mais
ou menos uma vez em vinte. Três ajustes mudam esse sorteio. Se você pode mexer neles depende do
provedor, como mostra o fim desta seção.

## Temperatura

**A temperatura remodela a distribuição antes do sorteio.** Abaixo de 1 ela a aguça, e os tokens
prováveis ficam mais prováveis ainda. Acima de 1 ela a achata, dando mais chance aos tokens raros.
Em 0 o sorteio some e o token do topo sempre ganha, o que é a decodificação gulosa de novo. O
mesmo prompt e a mesma semente aleatória em três temperaturas:

```
ana@dev:~/shop$ python scratch/generate.py "The default value is" --tokens 16 --temperature 0 --seed 8
The default value is 0.0. The value of the parameter is used to scale the output
ana@dev:~/shop$ python scratch/generate.py "The default value is" --tokens 16 --temperature 0.7 --seed 8
The default value is 0. The default value is 0.
The default value is 0
ana@dev:~/shop$ python scratch/generate.py "The default value is" --tokens 16 --temperature 1.5 --seed 8
The default value is 8 red selectors would affect physically exactly abc downwards]
 (*) Output Fully duality
```

Em 0 o texto é a continuação mais previsível, e plausível. Em 0,7 este sorteio **caiu num laço**:
depois que `The default value is 0.` foi escrito duas vezes, escrever uma terceira era a coisa
mais provável a fazer, e nada no laço da seção 06 percebe repetição. Em 1,5, tokens que o modelo
achava muito improváveis são escolhidos com tanta frequência que o texto deixa de formar frases:
palavras em inglês numa ordem que nenhuma frase tem, um colchete solto e uma ou outra palavra com
maiúscula.

O padrão do próprio Ollama é 0,8. Toda resposta deste curso que não define uma temperatura, pelo
`ollama run` ou por um SDK, é sorteada nesse valor, e é por isso que **as suas respostas vão sair
com outras palavras que as da aula**, e às vezes chegar a outra conclusão. Onde isso importa, a
aula diz o que procurar em vez de quais foram as palavras.

## A semente

O sorteio precisa de uma fonte de aleatoriedade. Fixe-a, e a mesma distribuição dá os mesmos
sorteios. Mude-a, e o mesmo prompt na mesma temperatura dá outro texto:

```
ana@dev:~/shop$ python scratch/generate.py "The default value is" --tokens 16 --temperature 0.7 --seed 1
The default value is inherited from the superclass, so you don't need to specify it in the subclass
ana@dev:~/shop$ python scratch/generate.py "The default value is" --tokens 16 --temperature 0.7 --seed 2
The default value is 24 hours. It is possible to set the duration of the poll to a
ana@dev:~/shop$ python scratch/generate.py "The default value is" --tokens 16 --temperature 0.7 --seed 3
The default value is 16, which is a good starting point for most users. You can adjust
```

Três sementes, três afirmações confiantes sobre três coisas diferentes. **Não espere as mesmas
três na sua máquina**, e não espere que nem uma semente fixa dure muito: na máquina da gravação,
as três sementes deram continuações diferentes antes de o Ollama ser reinstalado. Uma diferença
no último dígito de uma probabilidade basta para mudar um sorteio, e daí em diante cada token
decorre de um texto diferente.

**É por isso que a mesma pergunta a um modelo hospedado dá uma resposta diferente a cada vez.**
Algumas APIs de provedores nem deixam fixar a semente, e as que aceitam uma descrevem o resultado
como melhor esforço. Mesmo em temperatura 0, os provedores não prometem saída idêntica para
pedidos idênticos: não há garantia de que o hardware deles faça as contas bit a bit iguais de um
pedido para o outro. As probabilidades da seção 06 mexendo alguns pontos entre execuções são um
sinal da mesma coisa. **Não construa nada que dependa de um modelo se repetir exatamente.** Se um
teste precisa de uma resposta fixa, o teste não deveria estar chamando um modelo; a aula 4 volta a
isso.

## Top-p

**O top-p corta a cauda antes do sorteio.** Ele fica com os tokens mais prováveis até que as
probabilidades somem *p*, e sorteia só entre esses. Com *p* em 0,5, o sorteio é entre o punhado
de tokens que formam a metade mais provável da distribuição, por mais que a temperatura a tenha
achatado. Aqui está a execução em 1,5 de novo, com esse corte:

```
ana@dev:~/shop$ python scratch/generate.py "The default value is" --tokens 16 --temperature 1.5 --top-p 0.5 --seed 8
The default value is 0. If the specified range is a fraction of the total size of the
```

Uma frase de novo, e quase com sentido: o corte tirou as palavras improváveis e deixou o sorteio
livre para vagar só entre as prováveis. **Mude um dos dois ajustes, não os dois**: eles agem
sobre a mesma coisa, e mexer nos dois torna impossível saber qual mudou a saída. Alguns
provedores oferecem também o **top-k**, que fica com um número fixo de tokens em vez de uma fatia
da probabilidade; o `generate.py` o põe em 0, o que no Ollama quer dizer sem limite, para que só
os dois ajustes acima estejam em ação.

## Quais APIs deixam você mexer neles

São ajustes do sorteio, e o sorteio acontece do lado do provedor, então é o provedor que decide
quais você pode mudar. Perguntar a cada um dos três SDKs que você instalou o que a chamada de
geração aceita dá três respostas diferentes. O `~/shop/scratch/knobs.py` lê os parâmetros de cada
chamada, sem enviar nada:

```python
import inspect

import anthropic
import openai
from google.genai import types

calls = {
    "anthropic messages.create": inspect.signature(anthropic.Anthropic().messages.create).parameters,
    "openai chat.completions.create": inspect.signature(openai.OpenAI().chat.completions.create).parameters,
    "google GenerateContentConfig": types.GenerateContentConfig.model_fields,
}
for name, params in calls.items():
    have = [k for k in ("temperature", "top_p", "top_k", "seed") if k in params]
    print(f"{name:32} {' '.join(have) or '(none of them)'}")
```

```
ana@dev:~/shop$ python scratch/knobs.py
anthropic messages.create        (none of them)
openai chat.completions.create   temperature top_p seed
google GenerateContentConfig     temperature top_p top_k seed
```

**A API atual da Anthropic não aceita nenhum dos quatro.** O SDK `anthropic` não tem esse
argumento, e a referência da API, lida em 2 de outubro de 2026, não menciona nenhum: como os
modelos Claude sorteiam os tokens é decisão da Anthropic. O Chat Completions da OpenAI aceita
temperatura, top-p e semente, e o do Google acrescenta o top-k. A aula 10 põe as três APIs lado
a lado. A maior parte deste curso chama o Ollama pelo SDK `anthropic`, então a maior parte dos
programas também não pode definir uma temperatura, e as respostas são sorteadas no padrão do
Ollama.

## O que usar em trabalho de programação, onde der

- **Código, extração, classificação: temperatura baixa**, de 0 a 0,3. Existe uma resposta certa e
  a variedade só acrescenta jeitos de errar.
- **Nomes, alternativas, ideias de teste: perto do padrão do provedor**, muitas vezes 1. Aqui a
  variedade é o objetivo, e você pode pedir várias e ficar com a melhor.
- **Deixe o resto no padrão** até ter um motivo medido para mexer. Um ajuste copiado de um post de
  blog é um ajuste que ninguém da sua equipe consegue explicar depois.

Onde a API não oferece temperatura, os mesmos objetivos se alcançam no próprio pedido: peça uma
resposta num formato fixo quando quiser consistência, e várias alternativas quando quiser
variedade. A aula 5 é sobre escrever esses pedidos.
