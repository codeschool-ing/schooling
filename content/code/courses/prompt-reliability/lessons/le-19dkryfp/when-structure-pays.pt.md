---
title: Quando a estrutura compensa
version: 2
---

`prompt-engineering` apresentou saída estruturada na aula 18 e esquemas na aula 19. Esta aula os
retoma de propósito, com a pergunta que este curso faz a toda técnica: **com que frequência a
estrutura chega de fato, e o que faz o programa que a lê quando ela não chega?**

A ideia que precisa sair primeiro é a de que JSON é o jeito cuidadoso e profissional de pedir uma
resposta, e prosa o jeito desleixado. **Estrutura é para um leitor que é um programa.** A mesma
mensagem, classificada pelo prompt sem nada e pelo que pede JSON:

```
ana@lab:~/triage$ pl run prompts/v1-bare.txt cases/dev.jsonl --out runs/v1.jsonl
40 calls, prompt a4ffc4b1, llama3.2:3b, written to runs/v1.jsonl
ana@lab:~/triage$ pl run prompts/v2-json.txt cases/dev.jsonl --out runs/v2.jsonl
40 calls, prompt 9c365e2d, llama3.2:3b, written to runs/v2.jsonl
ana@lab:~/triage$ pl show runs/v1.jsonl t17
│ Here is the sorted customer message:
│
│ **Message:** My order was dispatched ten days ago and still hasn't arrived. I need it for a birthday on Saturday.
│
│ **Category:** Missing Order
│
│ **Urgency:** High
│
│ **Reason:** The customer is concerned about receiving their order in time for a birthday on Saturday, which suggests that the order is time-sensitive and requires prompt attention from the support team.
stop: stop, tokens in 69, out 82, 9.3 s
ana@lab:~/triage$ pl show runs/v2.jsonl t17
│ {"category": "delivery", "urgency": "high", "summary": "Order has not arrived ten days after dispatch and is needed for a birthday on Saturday"}
stop: stop, tokens in 114, out 35, 4.3 s
```

Uma pessoa da equipe de atendimento lê a primeira resposta em poucos segundos e sabe o que fazer.
*Missing Order* e *High* não são palavras da loja, e uma pessoa não se importa. Um programa que
encaminha a mensagem para a fila do depósito não se importa com mais nada: precisa de um campo que
consiga achar pelo nome e de um valor que consiga comparar com `delivery`. **Se quem lê a resposta é
uma pessoa, o prompt sem nada estava quase pronto.** A aula 1 o reprovou em todas as verificações
porque o leitor neste curso é um programa, e as verificações são as necessidades desse programa por
escrito.

## O que a estrutura custa, e o que ela economiza

Pedir JSON são mais instruções, então o prompt fica mais longo. A resposta é outra história:

```
ana@lab:~/triage$ python3 stats.py runs/v1.jsonl runs/v2.jsonl
runs/v1.jsonl, 40 calls
  tokens in    mean   61.1   total   2446
  tokens out   mean  107.5   total   4298   max 164
  seconds      p50  12.7   p95  17.9   total  495.1
runs/v2.jsonl, 40 calls
  tokens in    mean  106.2   total   4246
  tokens out   mean   30.6   total   1225   max 38
  seconds      p50   3.7   p95   4.6   total  146.8
```

O prompt foi de 61,1 tokens por chamada para 106,2. **A resposta foi de 107,5 tokens para 30,6**, e
a chamada mediana de 12,7 segundos para 3,7. O prompt sem nada deixou a forma da resposta em aberto,
e o `llama3.2:3b` preencheu o espaço com um título, a mensagem copiada de volta, rótulos em negrito
e um parágrafo de raciocínio que ninguém pediu. Cada um desses tokens é escrito um de cada vez, e
num processador os tokens escritos são os lentos.

Então a preocupação habitual com a estrutura, de que chaves e nomes de campo também são tokens, é
real e pequena. O efeito maior é o do outro lado: **um formato é um limite para o que o modelo pode
escrever**, e um modelo sem limite gasta o espaço. Vale saber disso antes de culpar o JSON por um
pipeline lento, e é um resultado sobre este modelo, nesta tarefa; a aula 6 mede direito o tamanho
das respostas.

## O que a estrutura restringe

Um campo guarda o que o formato deixa guardar. O resumo aqui é uma frase porque o formato diz isso,
e um cliente com dois problemas tem um deles resumido. A prosa tem espaço para *"quase tudo billing,
mas também menciona um livro danificado"*; um campo `category` tem espaço para uma palavra de uma
lista de cinco. **Cada campo que você acrescenta é uma decisão tirada do modelo.** É exatamente o
que você quer para um valor sobre o qual um programa decide, e exatamente o que você não quer para
algo que uma pessoa ia ler e julgar.

Então a regra é sobre o leitor. Peça estrutura quando um programa consome a resposta, e peça tanta
quanto esse programa precisa, que neste curso são dois rótulos e uma frase.
