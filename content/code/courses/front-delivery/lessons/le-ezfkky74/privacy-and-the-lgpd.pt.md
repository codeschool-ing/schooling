---
title: Privacidade, e a LGPD
version: 1
---

**Um relatório de erro é um dado sobre a pessoa cujo navegador o mandou, e no Brasil a LGPD, a Lei Geral
de Proteção de Dados (lei 13.709, de 2018), diz o que se deve a ela.** Dado pessoal, na lei, é qualquer
informação sobre uma pessoa identificada ou identificável. Um relatório com um e-mail dentro é dado
pessoal sem discussão. Um relatório sem nenhum ainda pode ser, quando posto ao lado do endereço de onde
veio: o coletor recebe o endereço IP de toda requisição, guardando-o ou não.

Esta seção é o lado de quem protege, para quem desenvolve e decide o que uma página manda. Não é
aconselhamento jurídico, e um produto que coleta relatórios de usuários de verdade deve ter o aviso de
privacidade revisado por quem dá esse aconselhamento.

## Os princípios, aplicados a um relatório

O artigo 6º da LGPD lista os princípios que todo tratamento de dados pessoais segue. Quatro deles decidem
quase tudo o que um relatório de erro deve ser:

- **Finalidade**: os relatórios existem para achar e consertar falhas, e não são usados para mais nada,
  nem para analytics, nem para seguir uma pessoa pelo produto.
- **Necessidade**: só o que essa finalidade exige. É a regra da seção anterior: `pathname` e não `href`,
  nenhum valor de campo, nenhum id de usuário. Um relatório que precisasse saber quem é a pessoa, para
  falar com ela, é um pedido de suporte, e pergunta antes.
- **Transparência**: o aviso de privacidade diz que relatórios de erro são coletados, o que há neles, quem
  os recebe e por quanto tempo são guardados.
- **Segurança**: os relatórios ficam onde só a equipe pode lê-los, o coletor recusa o que não espera, e os
  source maps continuam privados.

## Uma base legal, e um prazo

Todo tratamento precisa de uma das bases legais do artigo 7º. Para relatórios guardados para manter um
serviço funcionando, o **legítimo interesse** é a que costuma ser considerada, e ela exige pesar o
interesse da equipe contra as expectativas e os direitos da pessoa, e registrar essa ponderação por
escrito. O consentimento é o outro caminho, e uma página que o pede precisa funcionar igualmente bem quando
a resposta é não.

Os relatórios também devem ser apagados quando deixam de ser úteis. Uma regra como *noventa dias, depois o
arquivo é apagado* é fácil de declarar no aviso e fácil de seguir; o coletor desta aula guarda tudo para
sempre, o que serve num notebook só e é errado em qualquer outro lugar.

## Para onde os relatórios vão

Um serviço hospedado é uma empresa que recebe os relatórios em nome da equipe: nos termos da lei, um
*operador*, agindo para o *controlador*, que é a equipe. Os servidores dele costumam ficar fora do Brasil,
e **mandar dados pessoais para fora é uma transferência internacional**, que o artigo 33 só permite nos
casos que lista, como para um país que a ANPD, a autoridade nacional, reconheceu, ou sob cláusulas
contratuais aprovadas por ela. Os serviços oferecem configurações para isso: a região onde os dados ficam
guardados, a remoção de tipos conhecidos de dado pessoal antes de guardar, e chaves que impedem o SDK de
mandar endereços IP e cookies. A próxima seção mostra a última delas na configuração do Sentry.

**A proteção mais simples é a da seção anterior: um relatório que não leva nada sobre a pessoa quase não é
assunto dela.**
