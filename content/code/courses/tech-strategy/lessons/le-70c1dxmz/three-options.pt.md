---
title: Três jeitos de ter busca
version: 1
---

Quem compra na Coreto encontra um espetáculo digitando numa caixa de busca, e a caixa é ruim. Ela
roda consultas `LIKE` na tabela de eventos do banco Postgres do `coreto-core`, então o nome de uma
banda digitado com uma letra errada não encontra nada, e um festival com uma escalação longa só
aparece pelo próprio nome. Júlia Sato, a head de produto, pediu uma busca que perdoe erros de
digitação e ordene os resultados com bom senso. O time de Catálogo precisa dizer como.

**A primeira pergunta de sempre é se o time consegue construir.** Consegue: o time de Catálogo é
bom, e busca de texto completo é um problema resolvido. Só que isso responde outra pergunta. Saber
se um time consegue construir algo não diz se construir é o jeito mais barato de tê-lo, nem se é o
melhor uso das horas que vai levar. A decisão tem três opções, e cada uma gasta seu dinheiro num
formato diferente.

## As três opções

**Construir** é melhorar a busca dentro do banco que a Coreto já roda. O Postgres tem busca de texto
completo própria — um índice sobre as palavras de cada evento, ordenação por relevância e extensões
para palavras escritas errado —, então o time escreveria a indexação, as consultas e as regras de
ordenação, e seria dono delas dali em diante.

**Comprar** é contratar um serviço de busca hospedado. A Coreto envia cada mudança nos seus eventos
para a API do fornecedor, e a caixa de busca consulta o fornecedor. Ele roda as máquinas, o índice
e as atualizações, e manda uma fatura todo mês.

**Adotar** é rodar um motor de busca de código aberto nos servidores da própria Coreto. Ninguém é
pago pelo software, e ninguém mais o opera: o motor, o cluster e as atualizações são do time.

## Quanto cada uma custa, linha por linha

Peça ao time de Catálogo o preço de cada opção e a resposta volta em três tipos de dinheiro:
trabalho feito uma vez, tempo de pessoas todo ano, e dinheiro pago a terceiros todo ano. Todo valor
abaixo está em reais, aos R$ 150 da hora de engenharia da Coreto e aos R$ 264.000 do ano de um
engenheiro (1.760 horas).

| | construir | comprar | adotar |
|---|---|---|---|
| trabalho feito uma vez, no ano 1 | 960 h (R$ 144.000) | 240 h (R$ 36.000) | 480 h (R$ 72.000) |
| pessoas, todo ano | um quarto de engenheiro (R$ 66.000) | um vigésimo de engenheiro (R$ 13.200) | 30% de um engenheiro (R$ 79.200) e 80 h de atualizações (R$ 12.000) |
| pago a terceiros, todo ano | capacidade de banco, R$ 3.000 por mês (R$ 36.000) | a licença, R$ 9.000 por mês (R$ 108.000 no ano 1), subindo 10% ao ano | servidores, R$ 6.500 por mês (R$ 78.000) |

Cada célula é uma estimativa que alguém consegue defender, e vale saber o que há dentro dela.

**Construir é sobretudo o trabalho do primeiro ano.** As 960 horas são mais de meio ano de um
engenheiro: o índice, as consultas, o tratamento de erros de digitação, a ordenação e os
testes com buscas reais. Depois disso, um quarto de engenheiro — 440 horas por ano — mantém tudo
funcionando: ajustar a ordenação quando alguém reclama, acrescentar a próxima coisa que produto
pedir. O banco precisa de R$ 3.000 por mês a mais de capacidade para carregar o novo índice e a
carga de consultas.

**Comprar é sobretudo a fatura.** O fornecedor cota R$ 9.000 por mês, e o contrato dele sobe o preço
10% ao ano, então a licença é R$ 108.000 no ano 1, R$ 118.800 no ano 2 e R$ 130.680 no ano 3. A
integração leva 240 horas: manter a cópia dos eventos no fornecedor em dia com a da Coreto, ligar a
caixa de busca à API e ter um plano B para quando o fornecedor cair. Um vigésimo de engenheiro, 88
horas por ano, cuida para que a cópia continue em dia e acompanha as mudanças na API do fornecedor.

**Adotar é sobretudo gente.** Os servidores custam R$ 6.500 por mês, para um cluster com réplicas.
Montar e integrar leva 480 horas. Depois, 30% de um engenheiro, 528 horas por ano, opera o motor —
plantão, espaço em disco, backups, reconstruir um índice que deu errado — e outras 80 horas por ano
vão em atualizações, porque um motor parado numa versão antiga deixa de receber correções de
segurança.

## O que cada uma compra

As três opções são três trocas, e dar nome a elas ajuda mais do que qualquer número isolado.

**Construir troca tempo de engenharia por controle.** A Coreto decide exatamente como os resultados
são ordenados e é dona de cada linha, e paga em horas: no começo, e com uma fatia de uma pessoa
enquanto a funcionalidade existir.

**Comprar troca dinheiro por tempo.** A integração é um quarto das horas de construir, então a busca
melhora em semanas e não em meses, e a Coreto deixa de ser dona de um problema que outras empresas
já resolveram. O preço é uma fatura que sobe todo ano, e um fornecedor entre a Coreto e a sua
própria caixa de busca.

**Adotar troca operação por controle do código.** A Coreto pode ler, mudar e guardar o motor, e
ninguém pode subir o preço dele. O custo é que o time vira operador de uma peça de infraestrutura
que não escreveu.

As três também **gastam em momentos diferentes**, e é disso que dependem as próximas duas seções.
Construir é caro no ano 1 e barato depois. Comprar é barato no ano 1 e mais caro a cada ano. Adotar
é caro todo ano. Uma comparação feita só com os números do primeiro ano escolhe a opção mais barata
de começar, o que diz pouco sobre a opção mais barata de ter. Antes da planilha, porém, a próxima
seção faz a pergunta que muitas vezes decide sem ela: se a busca é algo pelo qual as casas de
espetáculo escolhem a Coreto.
