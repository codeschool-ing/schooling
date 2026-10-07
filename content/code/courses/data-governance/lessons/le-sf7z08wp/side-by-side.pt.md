---
title: A LGPD e o GDPR, lado a lado
version: 1
---

Para um time que já trabalha sob a LGPD, o GDPR é quase todo as mesmas obrigações com números
diferentes. Os números são onde os erros acontecem.

| | LGPD | GDPR |
|---|---|---|
| bases legais | dez (art. 7º) | seis (art. 6(1)): consentimento, contrato, obrigação legal, interesses vitais, interesse público, interesses legítimos |
| proteção do crédito como base | sim (art. 7º, X) | não — em geral cai no interesse legítimo |
| dado sensível | art. 11, uma lista de exceções | art. 9, "categorias especiais", uma lista de dez exceções |
| crianças | consentimento de um dos pais, no melhor interesse da criança (art. 14) | em serviços online, consentimento dos pais abaixo de **16**, que um Estado-membro pode baixar até 13 (art. 8) — Portugal escolheu **13** |
| encarregado (DPO) | o controlador indica um, com dispensa para agentes de pequeno porte | exigido de órgãos públicos e onde a atividade principal é monitoramento em larga escala ou categorias especiais em larga escala (art. 37) |
| responder a um pedido | acesso em 15 dias (art. 19) | **um mês**, prorrogável por dois em pedidos complexos (art. 12(3)) |
| comunicação de violação à autoridade | 3 dias úteis (Resolução 15/2024) | **72 horas**, quando viável (art. 33) |
| avaliação de impacto | quando a ANPD pede (art. 38) | **obrigatória** para tratamento com probabilidade de alto risco (art. 35) |
| multa máxima | 2% do faturamento no Brasil, até R$ 50 milhões por infração | **4% do faturamento anual mundial ou 20 milhões de euros**, o que for maior (art. 83(5)) |

## Direitos com nomes diferentes

O GDPR lista os direitos em artigos separados: acesso (15), retificação (16), apagamento (17),
limitação (18), portabilidade (20), oposição (21), e não ficar sujeito a decisão unicamente
automatizada (22). Dois merecem uma segunda olhada:

- **Limitação** (art. 18) é a versão do GDPR para o *bloqueio* da LGPD: o dado é guardado mas não
  usado, enquanto se resolve uma disputa sobre sua exatidão ou licitude. Num banco, é uma marca que
  toda consulta de toda finalidade precisa respeitar — e, portanto, uma coluna que o `consent_now` da
  aula 7 teria de aprender a ler.
- **Oposição** (art. 21) é absoluta para marketing direto: quando a pessoa se opõe, o marketing para,
  sem teste de balanceamento. A LGPD chega ao mesmo lugar pela revogação do consentimento, ou pelo
  artigo 18, §2º quando a base é outra.

## O hábito que se transfere

As tabelas da aula 7 passam para cá com um acréscimo. O `gov.subject_requests` tinha um vencimento
de 15 dias para tudo; um pedido de uma cliente de Lisboa vence em um mês. **O vencimento depende da
lei, e a lei depende da linha** — então a coluna gerada vira uma regra sobre duas colunas, e um
pedido de Portugal respondido no dia 20 está no prazo enquanto um de São Paulo está atrasado. Um time
que guarda um número só na cabeça guarda o errado para metade dos clientes.
