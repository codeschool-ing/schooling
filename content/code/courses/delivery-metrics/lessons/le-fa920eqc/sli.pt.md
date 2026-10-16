---
title: O que conta como uma cobrança boa
version: 1
---

Toda discussão sobre confiabilidade começa com uma palavra que ninguém definiu. O time de suporte diz que os pagamentos com cartão ficaram "fora do ar" na terça; os devs dizem que o serviço ficou no ar o dia inteiro e que o provedor de cartão estava lento. Os dois descrevem a mesma hora, e não conseguem resolver nada até concordarem sobre o que estão contando.

Um **indicador de nível de serviço**, ou SLI, é esse acordo escrito como uma razão:

```localised
SLI = eventos bons ÷ eventos válidos
```

É uma fração, entre 0% e 100%, das coisas que o serviço fez e que deram certo, contadas num período. Os livros de SRE do Google, que deram nome à ideia, recomendam essa forma acima de qualquer outra, porque uma razão de eventos significa a mesma coisa num domingo tranquilo e na última tarde do mês.

## A definição do time de Billing

Para cobranças no cartão, o time de Billing escreveu assim:

- **um evento válido** é uma tentativa de cobrança que chega ao serviço vinda do terminal de uma loja;
- **um evento bom** é uma que é respondida em até 10 segundos e cobra o cartão exatamente uma vez, ou o recusa por um motivo que o banco deu.

Há três escolhas escondidas nessas duas linhas, e cada uma é o tipo de coisa sobre a qual um time discute só uma vez, se ela estiver escrita.

- **Uma recusa pode ser boa.** Um cartão sem saldo deve ser recusado, e recusá-lo em dois segundos é o serviço funcionando. Contar recusas como ruins faria o SLI cair toda vez que os clientes ficassem sem dinheiro, o que não tem nada a ver com o time.
- **Lento é ruim.** O dono de uma loja com fila no caixa não consegue distinguir um pagamento que falhou de um que leva quarenta segundos; os dois o fazem tentar de novo. Então o limite pertence ao que o usuário aguenta, e os dez segundos vieram das anotações do time de suporte, não dos servidores do time.
- **Cobrar duas vezes é ruim.** É a pior resposta que existe, pior que uma falha, e um SLI que contasse só "o provedor disse sim?" teria registrado a tarde de 30 de setembro como um sucesso.

## Medido onde o usuário está

Um SLI é medido o mais perto do usuário que o time conseguir. A CPU de um servidor, o número de instâncias rodando ou um health check que responde "ok" são causas, e cada uma delas pode parecer bem enquanto o terminal de cada loja espera. O time de Billing conta no ponto em que a requisição do terminal chega e a resposta sai, que é o lugar mais próximo que o time controla.

## Poucos, não quarenta

Um serviço precisa de **um a três SLIs por coisa que um usuário está tentando fazer**, e os tipos usuais são poucos:

| tipo | a pergunta | para o time de Billing |
|---|---|---|
| disponibilidade | respondeu? | a cobrança recebeu uma resposta |
| latência | a resposta foi rápida o bastante? | em até 10 segundos |
| correção | a resposta estava certa? | cobrado uma vez, o valor certo |
| atualidade | os dados eram recentes o bastante? | o extrato mensal pronto até as 06:00 do dia 1º |

O time juntou os três primeiros num único SLI para cobranças, porque o dono da loja os vive como uma coisa só, e manteve a atualidade como um segundo SLI para o extrato. Dois números são um painel que alguém lê; quarenta são um painel que todo mundo aprende a ignorar, e a aula 18 trata de aonde isso leva.
