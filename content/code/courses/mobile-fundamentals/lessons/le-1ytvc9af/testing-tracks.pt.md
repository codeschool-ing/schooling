---
title: Faixas de teste, antes de o público ver qualquer coisa
version: 1
---

**Uma faixa de teste é o jeito de uma loja entregar um build a algumas pessoas e não a todo mundo,
pela própria loja.** A imagem comum de um beta é um arquivo passado por e-mail. No Android isso ainda
funciona para o celular de um amigo, como disse a aula 1; num iPhone não funciona, porque um iPhone só
instala o que a Apple assinou. Por isso as duas lojas oferecem faixas, e o que uma faixa tem de útil é
que o testador instala e atualiza o app do jeito que um usuário real vai fazer, pela loja, com a mesma
assinatura e o mesmo caminho de atualização.

## Google Play: interno, fechado, aberto

A documentação do Android sobre testar um app bundle descreve três etapas pelas quais uma versão pode
passar "antes de ir para produção":

| faixa | quem recebe | para que serve |
|---|---|---|
| **teste interno** | uma lista pequena de pessoas que você nomeia | "testes internos e verificações de qualidade", rápido |
| **teste fechado** | "um conjunto maior de testadores", por convite | versões de pré-lançamento, depois que a equipe ficou satisfeita; o Play cria uma chamada Alpha para começar |
| **teste aberto** | qualquer um que entrar | "uma variedade maior de usuários", antes da produção |

**A ordem é o ponto.** Cada faixa só amplia o público depois que a mais estreita não encontrou nada
grave, e o relatório de pré-lançamento da seção anterior roda nas faixas fechada e aberta, então um
travamento num modelo de celular que ninguém da equipe tem aparece antes da primeira instalação do
público. A mesma página também descreve o **compartilhamento rápido**: uma URL para um build de teste,
em que "os códigos de versão não precisam ser únicos". Essa exceção é útil aqui, porque em todo outro
lugar o código de versão é o número que a loja não deixa reusar, como mostra a próxima seção.

## Apple: TestFlight

**O TestFlight é a faixa de teste da Apple, com dois tipos de testador.** A página do TestFlight da
Apple, lida em 30 de outubro de 2026, dá os números:

| | quantos | quem | revisão |
|---|---|---|---|
| **testadores internos** | "até 100 membros da sua equipe de desenvolvimento" | pessoas com um papel na conta da equipe no App Store Connect | a página não cita etapa de revisão |
| **testadores externos** | "até 10.000" | qualquer um com um endereço de e-mail ou um link público | o primeiro build precisa estar "aprovado pelo App Review" |

**O teste externo é revisado, e isso surpreende as pessoas.** A diretriz 2.2 da Apple acrescenta que
"atualizações significativas do build beta devem ser enviadas à revisão do TestFlight antes de serem
distribuídas aos testadores", e que um build do TestFlight deve ser feito para lançamento público e
seguir as mesmas diretrizes. Então as recusas da seção anterior podem alcançar um beta também, o que
é mais um motivo para passar pela lista de conferência antes do primeiro build externo, e não antes do
lançamento.

## O caminho do planner

Para um planner construído depois da bifurcação, uma ordem sensata em cada loja são os mesmos três
passos:

1. **A equipe primeiro.** Teste interno no Play e testadores internos no TestFlight: as pessoas que o
   escreveram, nos próprios celulares, minutos depois do envio.
2. **Um grupo que não é a equipe.** Uma faixa fechada ou um grupo do TestFlight com algumas dezenas de
   alunos que toparam experimentar, por tempo suficiente para usá-lo numa semana real de estudo, que é
   o único jeito de o total da semana ser testado com dados que ninguém inventou.
3. **Quem quiser.** Uma faixa aberta, ou um link público do TestFlight, para a última rodada antes da
   produção.

**O retorno de um testador só é tão útil quanto o número de build que vem com ele.** "O total está
errado", vindo de um testador, não significa nada até você saber que build ele rodou, e a loja diz,
porque todo build leva o próprio número. Esse número, e a regra de que ele precisa sempre crescer, são
a próxima seção.

**A aula 7 do `mobile-delivery` é a prática** desta seção: montar cada faixa, convidar testadores e
levar um build de uma etapa à seguinte.
