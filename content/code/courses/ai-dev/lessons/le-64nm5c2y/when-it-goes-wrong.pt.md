---
title: Quando o laço não termina
version: 1
---

As falhas de um agente são em geral laços: o modelo pede a mesma coisa de novo, ou continua
explorando sem convergir. O modelo não percebe, porque cada passo é uma decisão nova a partir de uma
conversa que parece progresso. **O host tem de perceber**, com guardas que não dependem do juízo do
modelo.

## A mesma chamada duas vezes

```
ana@dev:~/shop$ python agent.py "Is there a lamp under 100.00?"
[1] call:   read_handbook({"name": "products"})
[1] result: # Products The shop sells mugs, glasses, lamps and small furniture. Mugs
[2] call:   read_handbook({"name": "products"})
[2] host:   the same call twice in one task; stopping
```

O modelo pediu a página de produtos, recebeu, e pediu de novo. A página não lista preços, então um
modelo que quer um preço vai continuar pedindo. A guarda de repetição o parou no passo 2. Sem ela,
isso rodaria até o limite de passos, pagando pela mesma página a cada vez.

## Explorando sem convergir

```
ana@dev:~/shop$ python agent.py "Which is the cheapest lamp you sell?"
[1] call:   read_handbook({"name": "products"})
[1] result: # Products The shop sells mugs, glasses, lamps and small furniture. Mugs
[2] call:   read_handbook({"name": "shipping"})
[2] result: # Shipping Orders ship within two working days from the warehouse in Cam
[3] call:   read_handbook({"name": "coupons"})
[3] result: # Coupons Two coupons are active. WELCOME10 takes 10% off and has no end
[4] call:   read_handbook({"name": "warranty"})
[4] result: # Warranty Every item has a 90-day warranty against manufacturing faults
[5] call:   read_handbook({"name": "returns"})
[5] result: # Returns and refunds A customer may return any item within 30 days of d
host: stopped after 5 steps without an answer
```

Cada chamada é diferente, então a guarda de repetição não dispara. O modelo lê uma página depois da
outra, nenhuma tem preços, e **o limite de passos é o que encerra**, depois de cinco, sem resposta.
Esse é o desfecho certo, já que o manual não lista preços, e o host diz isso em vez de fingir.

O que custou está no registro do labllm, os tokens de entrada dessas cinco requisições:

```
ana@dev:~/shop$ tail -n 5 /var/log/labllm/requests.jsonl | python -c 'import json, sys; u = [json.loads(l)["usage"]["input_tokens"] for l in sys.stdin]; print("input tokens per step:", u, "total", sum(u))'
input tokens per step: [259, 392, 541, 666, 807] total 2665
```

Cada passo leva a conversa até ali, então cada um é maior que o anterior, e os cinco somam 2.665
tokens para uma pergunta sem resposta. Com resultados de ferramentas reais, páginas de documentos ou
linhas de dados, a mesma forma custa muito mais.

## As guardas

- **Um limite de passos**, imposto pelo laço, com uma mensagem que diz que a tarefa não terminou.
  Escolha-o a partir da tarefa legítima mais longa, medida.
- **Uma checagem de repetição** na mesma ferramenta com os mesmos argumentos.
- **Um orçamento** em tokens ou dinheiro por tarefa, a guarda da aula 2 seção 09 aplicada ao laço
  inteiro e não a uma requisição.
- **Um limite de tempo**, para ferramentas que podem travar.
- **Um registro de todo passo**, para uma execução parada poder ser lida depois e o caso entrar numa
  avaliação (aula 5 seção 09) de tarefas que o agente deveria conseguir terminar.

A maioria dos agentes descontrolados em produção não é maliciosa nem está quebrada. É um modelo
fazendo a próxima coisa provável, corretamente, para sempre, sem nada no host para dizer pare.
