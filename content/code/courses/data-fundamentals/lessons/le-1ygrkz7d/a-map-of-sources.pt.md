---
title: Um mapa das fontes, e de quem é cada uma
version: 1
---

**Uma fonte é um sistema que outra pessoa construiu para outro trabalho, e o engenheiro de dados a lê
como visita.** A imagem comum é a de uma prateleira: os dados estão em algum lugar, prontos, esperando
alguém vir buscar. Nada na Roda Livre é assim. O banco do aplicativo foi feito para cobrar clientes, os
sensores das docas para mostrar um mapa, o provedor de pagamentos para movimentar dinheiro. Cada um
está ocupado com o seu trabalho quando Davi vem lê-lo, e cada um muda quando os donos decidem, não
quando ele decide.

Por isso a primeira coisa a saber sobre uma fonte não é o formato. É de quem ela é, como lê-la sem
atrapalhar, e o que ela faz no dia em que muda.

## Seis tipos, e o que cada um faz de errado primeiro

Esta aula percorre seis tipos de fonte, na ordem em que ana os encontra no primeiro mês dela. A tabela é a
aula inteira num lugar só; cada linha é uma seção própria.

| tipo | na Roda Livre | de quem é | como se lê | o que dá errado primeiro |
|---|---|---|---|---|
| **banco de dados** | viagens, clientes, bicicletas | o time do aplicativo | uma consulta, uma cópia, ou o log de mudanças | ler deixa o app lento; remoções somem da cópia |
| **API** | cobranças e estornos | o provedor de pagamentos, outra empresa | requisições HTTP, página por página | limites de taxa, tokens vencidos, um campo que muda de sentido |
| **arquivo** | a exportação diária da oficina contratada | um parceiro | esperar por ele num diretório ou num bucket | é lido antes de terminar de chegar |
| **log** | o log de acesso do servidor da API | o time de plataforma | analisar linhas de texto | o formato muda; está cheio de dados pessoais |
| **eventos de aplicação** | toques e telas no app | o time de produto | um fluxo ou um bucket de JSON | o mesmo evento chega duas vezes; o relógio do celular está errado |
| **IoT** | um sensor em cada doca | a operação e o fornecedor | leituras enviadas a cada minuto | lacunas, relógios que derivam, leituras fora de ordem |

Duas colunas pesam mais que as outras. **De quem é** decide a quem você pergunta antes de começar e quem
avisa você antes de algo mudar; em metade da tabela a resposta é outra empresa. **O que dá errado
primeiro** é a falha pela qual cada tipo é famoso, e nenhuma delas faz um programa parar. Uma cópia que
perde uma remoção, um arquivo lido pela metade, uma leitura contada duas vezes: cada uma produz uma
tabela com cara de completa.

## Perguntar e ser avisado

Os seis também diferem em quem se mexe primeiro. Um banco, uma API e um arquivo esperam ser
consultados: o programa de Davi decide quando ler, e a fonte nem sabe nem se importa. Eventos e
leituras de sensor são enviados: o app e as docas decidem quando falar, e alguma coisa do lado da Roda
Livre precisa estar escutando quando falam. A aula 3 chamou isso de pull e push. A diferença decide a
cara de uma falha. Quando um pull falha, o leitor sabe, porque a requisição dele falhou. Quando um push
falha, os dados simplesmente nunca chegam, e o único jeito de perceber é saber o que deveria ter vindo.

Essa última ideia atravessa todas as seções seguintes: **uma fonte é conferida contra o que ela deveria
ter produzido, não contra o que chegou.**
