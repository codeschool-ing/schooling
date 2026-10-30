---
title: O postmortem sem culpa
version: 1
---

**Um postmortem sem culpa (blameless) pergunta como o sistema permitiu um erro, não quem o cometeu.** "A Ana fez
deploy de uma configuração ruim" é verdade e inútil: a próxima pessoa vai fazer deploy de uma também. "Uma mudança
de configuração chegou à produção sem um plano que alguém tenha lido, e nada a testou" é um achado com correção. A
culpa faz as pessoas esconderem o que fizeram, e um postmortem escrito a partir de fatos escondidos não acha nada;
esse é o argumento prático, antes de qualquer argumento sobre gentileza.

## O documento

A loja escreve um para todo SEV1 e SEV2, em até uma semana, com estes títulos:

| título | o que vai nele |
|---|---|
| resumo | três frases: o que aconteceu, por quanto tempo, quem foi afetado, com números |
| impacto | o orçamento do SLO gasto (lição 13), pedidos afetados, dinheiro se houver |
| linha do tempo | da evidência, como a seção anterior montou, em UTC |
| o que deu certo | sempre tem itens, e vale guardá-los |
| o que deu errado | os achados, cada um um fato sobre o sistema |
| onde tivemos sorte | as coisas que teriam piorado tudo e não aconteceram |
| ações | cada uma com responsável e data, e cada uma ligada a um achado |

Para o incidente de pagamento, a linha de impacto diz: "Entre 14:12 e 14:18 UTC, 85 de 240 checkouts (35%)
precisaram de nova tentativa de pagamento; todos foram concluídos." As duas contagens vêm direto da transcrição da
seção anterior. Como todo pedido foi concluído, nenhuma requisição falhou, e o SLO de disponibilidade da lição 13
não gastou nada do orçamento: foi um incidente de latência, e o indicador de latência da lição 13 é onde ele
apareceria.

## Achados que levam a algum lugar

Um achado é útil quando uma ação pode decorrer dele. Três deste incidente:

- **A duração do alerta era maior que o incidente.** Ação: comparar dez minutos com o histórico dos últimos três
  meses de tentativas, e decidir se cinco minutos chamariam por ruído.
- **Ninguém soube até um cliente escrever.** Ação: rotear a política de queima lenta da lição 13 para o canal de
  chamados, para que uma rajada como esta seja pelo menos vista no mesmo dia.
- **A lógica de nova tentativa escondeu as falhas dos clientes.** Isso deu certo, e fica.

**Uma ação sem responsável e sem data é um desejo.** A loja revisa as ações do mês anterior no início de todo
postmortem; uma ação ainda aberta depois de duas revisões ou está feita, ou é abandonada de propósito e anotada
como abandonada, para que a lista de ações continue sendo uma lista de coisas que alguém está mesmo fazendo.

## "Causa raiz"

Postmortems costumam ter um título para a causa raiz, e o da loja não tem. Incidentes num sistema deste tamanho
raramente têm uma causa só: o serviço de pagamento estava lento, **e** a nova tentativa estava em cinco segundos,
**e** o alerta esperava dez minutos, **e** era sexta-feira. Nomear uma delas como a raiz faz as outras parecerem
cenário. Listar fatores contribuintes mantém todos eles na frente das pessoas que podem corrigi-los.
