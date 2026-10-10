---
title: A política, escrita antes de ser necessária
version: 1
---

Um orçamento sobre o qual ninguém age é um gráfico. O que o transforma numa decisão é uma **política de orçamento**: um documento curto, escrito enquanto o orçamento está saudável, que diz o que o time faz quando ele não está. Ela precisa ser escrita com antecedência pelo mesmo motivo que um simulado de incêndio é feito num dia tranquilo: na noite em que o orçamento acaba, todo mundo na sala tem um motivo para querer uma exceção.

## A política do time de Billing

Bia a escreveu com o head de produto em julho, e os dois a assinaram, com o diretor de engenharia acima deles:

| orçamento restante, 30 dias móveis | o que acontece |
|---|---|
| mais de 50% | releases como de costume |
| de 0% a 50% | toda release das cobranças no cartão vai primeiro para 5% das lojas e espera uma hora |
| gasto | **nenhuma release de funcionalidade nas cobranças no cartão** até o orçamento voltar a ser positivo; correções, mudanças de segurança e os itens de ação do incidente que o gastou vêm primeiro |
| gasto duas vezes num trimestre | confiabilidade é o primeiro item do plano do trimestre seguinte, com pessoas nomeadas para ela |

Três coisas nessa tabela importam mais que os limites.

- **Ela diz quem decide.** A política diz o que acontece automaticamente. Uma exceção, uma funcionalidade que não pode esperar, exige que o head de produto a peça por escrito, e o pedido fica registrado ao lado da release. Isso torna as exceções possíveis e visíveis, que é o objetivo: uma política sem exceções quebra na primeira emergência real, e uma com exceções silenciosas não é uma política.
- **Ela para o trabalho em funcionalidades, não o trabalho.** Um congelamento de funcionalidades não manda ninguém para casa. Ele move o tempo do time para as coisas que gastaram o orçamento, e é daí que o orçamento volta.
- **Ela trata do serviço, não das pessoas.** Ninguém é culpado por um orçamento gasto, e a política não pergunta quem o gastou. A hora lenta do provedor em 16 de setembro conta exatamente tanto quanto a release do próprio time; o orçamento mede o que as lojas viveram, e o postmortem da aula 15 pergunta por quê.

## O que isso significa em outubro

A janela móvel mantém setembro à vista por mais 30 dias. **O incidente de 30 de setembro gastou sozinho mais que o orçamento de um mês inteiro**, então, com as cobranças de outubro no volume de setembro, o orçamento fica abaixo de zero até esse dia sair da janela, no fim de outubro. Pela política do time, é um mês sem releases de funcionalidade nas cobranças no cartão.

Isso é a política funcionando, não falhando. O trabalho de outubro já está escolhido por ela: a chave de idempotência em toda nova tentativa de cobrança, o alerta de cobranças duplicadas, a release para 5% das lojas e os itens de ação atrasados da aula 15. A aula 15 encontrou três itens atrasados que teriam deixado a tarde de setembro menor; a política é o que finalmente os coloca à frente das funcionalidades para as quais eles viviam perdendo.

## Quando a política é ignorada

A primeira vez que o orçamento acaba é o teste de se o time tem uma. Se uma funcionalidade urgente sai mesmo assim, sem a exceção por escrito, a política acabou, e com ela o único argumento que permitia ao time dizer não sem briga. Times que querem que uma política de orçamento sobreviva a mantêm curta, mantêm poucos limites e **mantêm barato o caminho da exceção**, para que ninguém tenha motivo para contorná-lo.
