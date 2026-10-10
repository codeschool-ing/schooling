---
title: Limites além da contagem de requisições
version: 1
---

**Contar requisições limita com que frequência um cliente pede, e não diz nada sobre quanto uma
requisição pede.** Um cliente dentro das dez por segundo dele ainda pode mandar uma requisição que sobe
um gigabyte, pede todas as linhas de uma tabela ou aninha uma consulta em vinte níveis. O API4:2023 da
OWASP lista essas coisas ao lado da taxa de requisições por isso: cada uma é um jeito de gastar os
recursos do servidor que um limite de taxa nunca vê.

A regra por trás de cada linha desta tabela é a mesma. **Toda quantidade que o cliente controla ganha
um teto, e o teto é conferido antes de o trabalho ser feito**, não depois de o servidor ter lido o
gigabyte ou rodado a consulta.

| o que o cliente controla | o limite | respondido com | onde neste curso |
|---|---|---|---|
| o tamanho do corpo | um `Content-Length` máximo, conferido antes de ler o corpo | `413 Content Too Large` | aqui, e no proxy em `servers-cache` |
| quantos itens uma página devolve | um tamanho de página padrão, e um máximo que o cliente não consegue aumentar | a página pedida, cortada, ou `400` | aula 2 |
| quanto uma consulta pede | uma profundidade máxima ou um custo calculado por consulta | `400`, antes de rodá-la | aula 3 |
| quantas operações uma requisição carrega | um tamanho máximo de lote | `400` ou `413` | aula 3 |
| quanto tempo uma requisição roda | um tempo limite para o trabalho e para a consulta ao banco | `503` ou `504` | `servers-cache` |
| tentativas de login | poucas por minuto por conta e por endereço, depois um atraso | `429` | aula 10 |
| dinheiro gasto mais adiante | um limite de gasto no provedor, e uma cota por cliente aqui | `429`, ou o recurso desligado | as cotas desta aula |

## Duas delas, de perto

### O corpo

O `rest.py` lê `Content-Length` bytes porque o cliente disse que eram tantos. Um servidor que confia no
número lê o que mandarem, para a memória. A defesa é um teto comparado com o cabeçalho antes de um único
byte do corpo ser lido, e um `413` quando passa dele.

### Tentativas de login

Um formulário de login é o único lugar em que um cliente rápido é quase sempre um atacante, porque
pessoas digitam senhas devagar. O limite ali é pequeno, cinco ou dez por minuto, contado **por conta em
que se tenta entrar** além de por endereço, para que palpites espalhados por muitos endereços ainda
encontrem um contador só. A aula 10 trata de tornar cada palpite caro com um hash lento; o limite trata
de fazer com que sejam poucos. Os dois são necessários, porque cada um sozinho deixa uma brecha: um hash
lento sem limite ainda pode ser adivinhado devagar a partir de mil máquinas, e um limite sobre um hash
rápido é desfeito no primeiro vazamento do banco.
