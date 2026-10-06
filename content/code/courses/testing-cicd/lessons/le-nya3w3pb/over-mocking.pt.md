---
title: Quando os dublês testam a coisa errada
version: 1
---

Dublês deixam os testes rápidos e focados. Usados em toda parte, produzem testes que não conferem
nada com que um usuário se importaria. Três falhas se repetem, e cada uma tem um sintoma que dá para
notar na revisão.

## O teste espelha a implementação

Imagine um teste de `place` escrito com mocks para tudo, afirmando cada chamada em ordem: `add`
chamado com o e-mail e os centavos, depois `send` chamado com o assunto e o corpo. Agora alguém muda
`place` para guardar e enviar dentro de um auxiliar de transação, `with orders.saving(...)`, com o
mesmo resultado para o cliente. O teste falha, porque as chamadas mudaram, embora nada que o cliente
vê tenha mudado.

**Sintoma: o teste quebra numa refatoração que manteve o comportamento.** Um teste deveria falhar
quando o comportamento está errado e passar quando está certo, e um teste que repete o código linha
por linha falha nos dois tipos de mudança. O `test_orders.py` do `shipquote` afirma uma chamada, o
e-mail, porque o e-mail *é* comportamento. Não afirma como o pedido foi guardado; o estado do fake
responde isso.

## O dublê se afasta do real

A seção 06 mostrou um mock simples passando depois de `send` virar `deliver`, e a seção 10 mostrou
um stub passando depois de `cents` virar `price_cents`. **Sintoma: o dublê foi escrito à mão, de
memória, e nada o amarra ao colaborador real.** Os remédios são os dois mostrados: construir os
mocks a partir da classe real com `create_autospec`, e conferir os stubs contra o serviço real com
testes de contrato.

## Tudo é dublê, então nada é testado

Um teste que substitui o banco, a transportadora, o mailer *e* a função de preço, e depois afirma
que o handler os chamou, testa a ordem de quatro chamadas de função. Se todo colaborador de um
trecho de código é um dublê, o teste é sobre a fiação dos mocks, não sobre o programa. **Sintoma:
você não consegue dizer que defeito este teste pegaria.** A regra da aula 1 ajuda aqui também:
teste cada regra na camada mais baixa que a observa, e use objetos reais onde forem baratos. `brl` e
`freight` nunca viram mock no `shipquote`: são rápidas e determinísticas, então os testes as chamam
de verdade.

## Um checklist curto

Antes de acrescentar um dublê, pergunte:

1. **O real é lento, caro, não determinístico ou indisponível?** Se não for, use o real.
2. **Esta chamada é o comportamento, ou um passo até ele?** Verifique chamadas só no primeiro caso.
3. **O que mantém este dublê honesto?** Uma especificação vinda da classe real, um teste de
   contrato, ou uma execução compartilhada contra fake e real. Se a resposta for "nada", o dublê é
   um palpite.

A aula 4 acrescenta uma quarta pergunta, com números por trás: a cobertura informa as linhas que um
teste executou, e uma linha executada sob um dublê que não faz nada é uma linha que o relatório
conta e ninguém conferiu.
