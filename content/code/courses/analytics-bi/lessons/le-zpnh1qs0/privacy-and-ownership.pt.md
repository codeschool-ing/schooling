---
title: Dados pessoais, e quem é dono dos campos
version: 1
---

Reverse ETL copia dados do warehouse para ferramentas que outras pessoas operam. Duas perguntas precisam
de resposta antes da primeira sincronização, e nenhuma é técnica.

## Os dados pessoais saem de casa

O modelo da Lantern não manda nomes nem endereços de e-mail: um id de cliente, um segmento, uma região e
alguns números. Uma sincronização real com um CRM quase sempre manda mais, e cada campo é dado pessoal
sendo copiado para a empresa que opera o CRM. Pela LGPD essa cópia precisa das mesmas coisas que a
origem precisou:

- **uma finalidade**: o campo existe no CRM porque alguém age sobre ele. Essa é também a segunda seção
  desta aula, vista do outro lado;
- **minimização**: mande os campos de que a finalidade precisa, e nada só por estar disponível;
- **um contrato com o fornecedor** que trata os dados em nome da empresa, dizendo o que ele pode e não
  pode fazer com eles;
- **uma eliminação que alcance a cópia**, que é o que o laço de exclusão desta aula faz.

Uma sincronização é o jeito mais fácil que existe de pôr muito dado pessoal em muitos lugares, sem
alarde. Esse é o motivo de tratar o modelo dela como uma decisão que alguém assina.

## Quem é dono de um campo

A sincronização escreve `health` em todo contato, toda hora. Um vendedor que o muda à mão, porque sabe
algo que os dados não sabem, vê a mudança desfeita na execução seguinte e para de confiar no CRM.
**Todo campo sincronizado precisa de um dono só**: ou a sincronização — e então o campo é só de leitura
para as pessoas, e o CRM diz isso — ou as pessoas — e então a sincronização não o escreve. Um campo que
os dois escrevem é um campo em que ninguém pode confiar.

A mesma regra vale para a própria sincronização. Ela precisa de um dono, como um painel na aula 6: a
pessoa que lê a última linha dela, responde quando um vendedor relata um valor errado e decide quando o
modelo muda. A aula 8 mostra como as ferramentas comerciais organizam exatamente essas decisões.
