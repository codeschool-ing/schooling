---
title: MoSCoW
version: 1
---

O **MoSCoW** separa requisitos em quatro grupos. Dai Clegg o criou na Oracle em 1994, e ele passou a fazer parte do Dynamic Systems Development Method, o DSDM, um dos métodos representados na reunião de 2001 que escreveu o manifesto ágil. As letras minúsculas só estão lá para dar para pronunciar.

- **Must have** (tem de ter): sem isso, a versão não tem sentido ou é ilegal. Se um must-have não ficar pronto, a versão não sai.
- **Should have** (deveria ter): importante e esperado, mas há uma solução de contorno, mesmo que dolorosa.
- **Could have** (poderia ter): desejável; é o primeiro a sair se faltar tempo.
- **Won't have this time** (não terá desta vez): combinado como fora desta versão. Escrever isso é o ponto: impede que o item seja pressuposto.

## A regra que faz funcionar

As categorias não servem para nada se tudo for Must, que é o que acontece quando quem quer o próprio item construído é chamado a rotulá-lo. A orientação do DSDM acrescenta um orçamento: **os must-haves deveriam ser no máximo uns 60% do esforço**, e os could-haves por volta de 20%. Os could-haves são a contingência: quando a estimativa estoura, eles caem, e os must-haves ainda chegam na data.

Para a versão de agendamento online do time Agenda, uma passada de MoSCoW poderia ficar assim:

| grupo | itens |
|---|---|
| Must | pacientes agendam e cancelam; recepcionistas veem os agendamentos; pagamento do sinal |
| Should | lembretes por SMS na véspera |
| Could | relatórios para donos de clínica; consultas recorrentes |
| Won't, desta vez | um aplicativo móvel nativo; integração com o sistema contábil das clínicas |

## O que ele faz e o que não faz

O MoSCoW é bom numa coisa: **combinar escopo para uma data fixa**, e por isso cabe nos projetos de tempo fixo e escopo variável do DSDM e nos contratos da aula 1 que fixam orçamento e data. É rápido, todo mundo entende, e a lista de "won't" evita discussões depois.

Ele é ruim para ordenar itens **dentro** de um grupo. Dez must-haves ainda precisam de uma ordem, e o MoSCoW não oferece nenhuma. Também não diz nada sobre tempo: um should-have cujo valor some em maio e um que será igualmente bem-vindo em dezembro ficam na mesma caixa. A próxima técnica trata exatamente disso.
