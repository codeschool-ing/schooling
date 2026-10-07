---
title: Quando implantar cada mudança, e quando não
version: 1
---

Implantação contínua não é a meta de toda equipe, e os motivos para não adotá-la são específicos. A
pergunta útil não é *somos maduros o bastante?*, e sim **o que daria errado se todo commit verde
chegasse aos usuários em uma hora?**

## Onde a implantação contínua cabe

Ela cabe quando quatro coisas são verdade:

1. **Publicar é barato e reversível.** Voltar é um comando (aula 11), e os usuários mal veem um
   release ruim antes de ele sumir.
2. **Os testes carregam a confiança.** Tudo o que uma pessoa na barreira conferiria é conferido pelo
   pipeline.
3. **As mudanças são pequenas.** Um deploy contém um ou dois merges, então quando algo quebra a causa
   é óbvia.
4. **A produção é observada.** Erros e latência são medidos, e alguém, ou algo, reage (aulas 10 e 11).

Para um serviço web como o `shipquote`, as quatro dão para arranjar, e equipes que as arranjam
implantam muitas vezes por dia.

## Onde não cabe

- **Apps móveis.** Um release passa pela revisão de uma loja, e os usuários atualizam quando querem. O
  que se implanta continuamente é o build para testadores; o que chega à loja é uma decisão. Na trilha
  `mobile`, o `mobile-delivery` trata da liberação em etapas nas lojas.
- **Software instalado pelos clientes**, de aplicativos de desktop a firmware: ninguém consegue
  reverter um aparelho no bolso de alguém.
- **Mudanças reguladas**, em que uma pessoa nomeada precisa aprovar um release por lei ou por
  contrato.
- **Lançamentos coordenados**, em que uma mudança precisa entrar no ar num momento marcado. Isso
  costuma se resolver melhor implantando antes atrás de uma **feature flag**, aula 10, e ligando-a no
  momento, o que separa implantar de liberar.

## A pergunta que decide

Seja qual for a escolha da equipe, uma propriedade importa mais que o rótulo: **daria para publicar a
`main` agora, com segurança, em minutos?** Se sim, a equipe tem entrega contínua, e se é uma pessoa ou
uma regra que aperta o botão é uma escolha que ela pode rever. Se não, porque publicar leva um fim de
semana, um congelamento ou um checklist que só uma pessoa entende, então nenhum dos rótulos se aplica,
e o trabalho é tornar a publicação entediante.
