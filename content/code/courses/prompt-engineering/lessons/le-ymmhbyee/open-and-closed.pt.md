---
title: Pesos abertos e modelos fechados
version: 2
---

"Aberto" é usado sem muito cuidado quando se fala de modelos, e esse uso esconde a pergunta que
importa: **dá para obter os pesos, e o que você pode fazer com eles?** Um modelo fechado é um que
você só usa pelo serviço do provedor. Um modelo de pesos abertos é um cujos pesos você pode baixar,
o que, depois da lição 8, você sabe que quer dizer o modelo inteiro: o arquivo de números e mais
nada.

## Dois jeitos de usar um modelo

| | por uma API | pesos que você mesmo roda |
|---|---|---|
| onde roda | nas máquinas do provedor | na sua máquina, ou num servidor que você aluga |
| o que você paga | por token, a cada pedido | o hardware e a energia, seja qual for o volume |
| memória | problema do provedor | parâmetros × bytes por peso, lição 8 |
| os seus prompts | vão para o provedor | nunca saem da sua máquina |
| quando o modelo muda | quando o provedor o muda ou o aposenta | quando você decide |
| o que você pode mudar | o prompt | o prompt e os pesos, por ajuste fino (lição 9) |

Nenhuma das colunas é melhor em geral. Uma API dá os maiores modelos sem hardware nenhum, e um
modelo que você roda dá controle e mantém os dados em casa. Muitos modelos de pesos abertos também
são oferecidos por API por empresas de nuvem, o que é um terceiro arranjo: o hardware de outra
pessoa, um modelo aberto e as condições dela.

## Pesos abertos não são código aberto

Código aberto, em software, quer dizer que o código-fonte é publicado e você pode estudá-lo, mudá-lo
e compartilhá-lo. **Num modelo, os pesos são só um dos ingredientes.** Os dados de treinamento, o
código que treinou o modelo e a filtragem que o moldou em geral não são publicados, e sem eles
ninguém consegue reconstruir o modelo nem conferir com o que ele foi treinado. "Pesos abertos" é o
termo exato para a maior parte dos modelos chamados de abertos, e é o que este curso usa.

## O que a licença permite

Um modelo que se baixa sempre vem com uma licença, e as licenças diferem em pontos que importam para
uma empresa. Algumas são licenças de código aberto padrão, que permitem quase tudo com atribuição.
Outras são próprias de uma empresa, e podem restringir o uso acima de certo tamanho de empresa,
proibir alguns usos, exigir que o nome do modelo apareça no seu produto ou limitar o uso das saídas
dele para treinar outros modelos. **Leia a licença do modelo exato que você baixa**, não um resumo
da família: dois lançamentos do mesmo provedor podem ter condições diferentes.

Você baixou um na lição 1, e o Ollama guarda a licença ao lado dos pesos:

```
ana@lab:~/pe$ ollama show --license llama3.2:3b | head -2; ollama show --license llama3.2:3b | wc -l
LLAMA 3.2 COMMUNITY LICENSE AGREEMENT
Llama 3.2 Version Release Date: September 25, 2024
163
```

Uma licença da própria empresa, com 163 linhas, e é ela que decide o que você pode construir em cima
do `llama3.2:3b`. Lê-la é o passo de que esta seção trata, e ele está a um comando de distância.

## Para onde vão os seus dados

Com uma API, cada prompt e cada resposta passam pelo provedor. O que acontece com eles depois está
escrito nos termos e na política de dados do provedor, e é a primeira coisa que alguém de segurança
ou do jurídico vai perguntar. Perguntas a responder a partir dos documentos do próprio provedor:

- os dados são guardados, e por quanto tempo?
- são usados para treinar modelos futuros, e dá para desligar isso?
- em que países são processados, e isso atende às regras a que você está sujeito?
- o app para o consumidor e a API para empresas têm termos diferentes? Muitas vezes têm.

**Nunca responda a essas perguntas de memória ou com base num post de blog.** Os termos mudam, e
diferem entre planos do mesmo provedor. Um modelo que você mesmo roda responde às quatro por
construção, e esse é um dos principais motivos de organizações escolherem pesos abertos apesar do
hardware. Todo prompt que você mandou com o `ask` até aqui foi para `localhost` e para mais lugar nenhum, a não ser que você tenha apontado o `ASK_URL` para um provedor.
