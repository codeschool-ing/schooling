---
title: Escolher um modelo
version: 1
---

O jeito comum de escolher um modelo de embedding é abrir um leaderboard e ficar com o modelo do
topo. Um leaderboard tira a média de notas sobre muitos conjuntos de dados públicos, e a aula 9
mostrou por que isso é um ponto de partida e não uma resposta: os seus textos não são os conjuntos
de dados dele. As medições desta aula dizem a mesma coisa por outro lado. O WordLlama, um modelo
muito menor, venceu o MiniLM na busca da central de ajuda e perdeu para ele nos tickets, com os
mesmos 40 artigos, os mesmos clientes e a mesma máquina.

**Escolha em duas passadas.** A primeira elimina modelos com perguntas que têm resposta sim ou não,
e não precisa de medição. A segunda mede os poucos que sobram, com os seus dados, e só então olha
o preço.

## As perguntas que eliminam um modelo

| pergunta | o que conferir | onde o curso encontrou isso |
|---|---|---|
| Em que línguas estão os textos? | as línguas em que ele foi treinado, no model card | aula 1: um modelo inglês tratou um título em português como sem relação com a própria tradução |
| Que tipo de texto é? | se ele foi treinado nesse domínio; existe modelo de domínio para código, direito e finanças | a tabela desta aula |
| Qual o tamanho de cada texto? | a entrada máxima; o que passar disso é cortado ou recusado | aula 9: o MiniLM ignora o que passa do limite; a tabela lista 8.191 tokens para a OpenAI e 32.000 para a Voyage |
| O texto pode sair das suas máquinas? | uma API hospedada recebe todo texto que você transforma em vetor | a aula 9 roda um modelo aberto localmente |
| Você pode usá-lo comercialmente? | a licença dos pesos, que nem sempre é a licença do código | abaixo |
| Quão rápido ele precisa ser? | textos por segundo no seu hardware, ou o limite de requisições do fornecedor | esta aula: WordLlama 128 vezes mais rápido que o MiniLM aqui |
| Quanto você consegue guardar? | dimensões × 4 bytes por vetor, antes de qualquer índice | a aula 1 mediu um vetor; a aula 18 mede o resto |

**Uma licença é uma pergunta de sim ou não, e pesos abertos não a respondem sozinhos.** O pacote
do WordLlama declara a licença MIT, e o all-MiniLM-L6-v2 é publicado sob Apache 2.0: as duas
permitem que uma loja os use comercialmente. A Jina publica os pesos do jina-embeddings-v3 sob CC
BY-NC 4.0, uma licença não comercial, então uma loja pode lê-los e testá-los, mas precisa de um
acordo com a Jina para rodá-los em produção, ou paga pela API. Leia a licença no model card antes
do primeiro benchmark, porque um modelo que você não pode usar não vale a medição.

**Privacidade também é uma pergunta de sim ou não.** A aula 1 mostrou que o vetor da mensagem de
uma cliente é dado pessoal. Mandar a mensagem para uma API hospedada para obter esse vetor é mandar
a mensagem, e se isso é permitido é uma decisão de quem responde pelos dados, tomada antes da
primeira requisição.

## Meça o que sobrou, depois ponha preço

Para os modelos que continuam de pé, meça do jeito que esta aula mediu: as suas perguntas, as
respostas que você decidiu que estão certas, e a fração que cai em primeiro e entre as primeiras.
Vinte e quatro perguntas bastam para pegar um modelo claramente errado para o trabalho, e são
poucas para separar dois que estão perto; uma diferença de uma ou duas perguntas é ruído. Olhe as
falhas uma a uma, como `misses.py` fez, porque um padrão nelas (palavras em comum, uma língua,
textos longos) diz mais que a contagem.

O preço vem por último porque é o mais fácil de ler e o mais fácil de supervalorizar. Um modelo
mais barato que manda clientes para o artigo errado não sai mais barato quando alguém precisa
responder as perguntas que ele perdeu. E o preço inclui o que a aula 18 acrescenta: armazenamento
para cada vetor, e a conta inteira de novo no dia da troca.

## O caso da Marginalia

A central de ajuda da Marginalia é quase toda em inglês, com alguns artigos em português:

```
ana@lab:~/emb$ jq -r .lang data/help.jsonl | sort | uniq -c
     37 en
      3 pt
```

Uma central de ajuda com artigos em português vai receber perguntas em português. Isso elimina
todo modelo só de inglês antes de qualquer medição, inclusive os dois do laboratório: o
laboratório os usa porque eles rodam nesta máquina, e não porque servem para a loja. Sobram os
modelos multilíngues, hospedados ou abertos. Se os textos podem ir para uma API hospedada é uma
decisão da loja sobre as mensagens dos clientes, e se a resposta for não, a lista encolhe para
modelos abertos multilíngues com uma licença que permita uso comercial. Esses poucos são medidos
nas 24 perguntas, com perguntas em português acrescentadas, e o melhor deles recebe preço por
último.
