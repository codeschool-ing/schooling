---
title: A revisão, e os motivos pelos quais os apps voltam
version: 1
---

**A revisão é uma pessoa, ou um processo, na loja conferindo o seu app contra regras escritas antes
de os usuários o receberem, e a maioria das recusas é sobre um app que não estava pronto, e não sobre
um app que quebrou uma regra de propósito.** A imagem comum é a de um porteiro procurando conteúdo
proibido. Isso acontece, e as regras sobre conteúdo são longas, mas os motivos mais comuns são mais
sem graça: o app travou, um link não levava a lugar nenhum, uma tela ainda dizia "lorem ipsum", ou o
revisor não conseguiu passar do login.

## As diretrizes da Apple, e o que a Apple diz que dá errado

**As regras da Apple são as App Review Guidelines**, uma página pública em
`developer.apple.com/app-store/review/guidelines`, organizada em cinco partes: segurança, desempenho,
negócios, design e jurídico, cada regra com um número como 2.1. A página da Apple sobre o App Review,
lida em 30 de outubro de 2026, diz que ela revisa "pelo menos 50% dos envios em menos de 24 horas e
90% em menos de 48 horas", e lista os problemas mais comuns. A primeira afirmação é a que vale
guardar: "mais de 40% dos problemas não resolvidos estão ligados à diretriz 2.1: App Completeness, que
cobre travamentos, conteúdo provisório, informação incompleta e mais".

| o que a Apple lista | o que significa para o planner |
|---|---|
| **travamentos e bugs** | testar em aparelhos com o sistema mais recente antes de enviar; um travamento ao abrir é uma recusa |
| **links quebrados** | todo link precisa funcionar, e todo app precisa de um link para o suporte e outro para a política de privacidade |
| **conteúdo provisório** | nenhum texto de exemplo, nenhuma tela vazia, nenhuma imagem de "em breve" |
| **informação incompleta** | se recursos exigem login, dar ao revisor "um nome de usuário e uma senha de uma conta de demonstração válida" |
| **problemas de política de privacidade** | a diretriz 5.1: uma política com link nos metadados e dentro do app, dizendo o que é coletado e com quem é compartilhado |

**A conta de demonstração é a que pega os iniciantes.** A diretriz 2.1 pede que você "inclua os dados
de uma conta de demonstração (e ligue o seu serviço de back-end!) se o app tiver login". Um planner que
sincroniza com um servidor e pede uma conta na primeira tela é um app que o revisor não consegue abrir
sem ela. Uma conta de demonstração que funciona, num servidor que está no ar durante a revisão, faz
parte do envio.

**A privacidade é revisada contra o que você declarou.** A aula 13 tratou das declarações que cada
loja manda preencher. A revisão as compara com o que o app faz: um app que pede localização enquanto
as informações de privacidade dele dizem que não coleta nenhuma tem duas afirmações que não podem ser
verdadeiras ao mesmo tempo, e a segunda foi escrita por você.

## A revisão do Google Play

**O Play também revisa apps, contra as Políticas do Programa para Desenvolvedores.** A documentação do
Android sobre publicação diz que um app fica disponível "depois de passar pela revisão do Google
Play". As políticas em si, e o relato do Google sobre os motivos comuns de recusa, estão nas páginas
de ajuda e de políticas do Play Console, que não puderam ser acessadas da máquina em que este curso foi
escrito; esta aula não cita nenhuma delas. O que ela pode dizer a partir da própria documentação do
Android é mais estreito, e é o próximo parágrafo.

**O Play também testa o app em aparelhos antes de uma pessoa vê-lo.** A documentação do Android
descreve o **relatório de pré-lançamento**: quando um build é enviado para a faixa de teste aberto ou
fechado, o Play o executa numa variedade de aparelhos e versões do Android e informa problemas de
"estabilidade", "compatibilidade com o Android", "desempenho", "acessibilidade" e "vulnerabilidades de
segurança". É o revisor mais barato que o app vai ter, e ele confere o assunto da aula 19.

## Quando um app é recusado

**Uma recusa é uma mensagem, não uma sentença.** Ela diz o que o revisor encontrou, e a resposta comum
é um build novo ou metadados corrigidos, enviados de novo. A Apple também deixa você recorrer ao App
Review Board dela, um recurso por envio, quando acha que o revisor entendeu mal o app. Como responder,
quanto tempo leva cada passo e como funciona o recurso são a aula 6 do `mobile-delivery`.

**A recusa mais barata é a que você mesmo pega.** Antes de enviar, a lista de conferência do planner é
curta e sai direto da tabela acima: abrir o app num aparelho real com o sistema mais recente; abrir
todo link; procurar texto provisório; entrar com a conta de demonstração que você está para dar ao
revisor; e ler a declaração de privacidade contra o que o app de fato coleta.
