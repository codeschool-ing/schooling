---
title: Medindo o divisor do Haystack
version: 1
---

A medição da aula 10, as mesmas 26 perguntas com resposta, os mesmos três trechos recuperados, a
mesma contagem de tokens, agora para o divisor do Haystack em três configurações: o padrão dele, as
60 palavras da aula 4, e um parágrafo por pedaço.

```
ana@lab:~/rag$ python hs_measure.py
pipeline                        found  tokens
Haystack, defaults              25/26     717
Haystack, 60 words              22/26     244
Haystack, passages              21/26     124
lesson 5's index                26/26     168
```

**O padrão do Haystack é o melhor padrão que este curso mediu.** Com 200 palavras sem sobreposição ele
achou 25 de 26 com 717 tokens por pergunta. O padrão do LangChain achou 23 com 1.943 e o do LlamaIndex
22 com 2.044. Duzentas palavras ficam perto dos 256 pedaços de palavra que o all-MiniLM-L6-v2 lê,
então a busca vê a maior parte de cada pedaço, enquanto os padrões maiores escondiam a maior parte
dos seus. Ainda assim são mais de quatro vezes os 168 tokens da aula 5, por uma resposta a menos.

**Sessenta palavras acharam menos que o padrão.** 22 de 26, enquanto os 400 caracteres do LangChain
acharam 24 e o índice da aula 5, 26. Uma contagem de palavras corta onde cair a sexagésima palavra, no
meio da frase e por cima dos títulos, e sem sobreposição um fato dividido por um corte não fica em
nenhuma das metades; a própria linha "fixed, 60 words" da aula 4 achou 19 pelo mesmo motivo. O que a
aula 5 somou às 60 palavras foi a estrutura do documento e o caminho de títulos no texto do
embedding, e foi isso que a levou a 26.

**Os parágrafos sozinhos foram os mais baratos e os que menos acharam**, 21 com 124 tokens: muitos
parágrafos aqui têm uma ou duas frases, pequenos demais para guardar uma resposta e o contexto dela
juntos.

Então a ordem dos padrões não é a ordem das ferramentas. Uma biblioteca cujo padrão por acaso serve a
um acervo continua tendo um padrão; as configurações que venceram aqui foram escolhidas por este
teste, e o mesmo teste é como qualquer uma das três seria ajustada. A tabela pertence aos treze
documentos da Marginalia e às suas 26 perguntas, e outro acervo pode inverter qualquer linha dela.
