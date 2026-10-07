---
title: Os direitos do titular
version: 1
---

A pessoa a quem um dado se refere é o **titular**. O **artigo 18** lhe dá nove direitos perante o
controlador, e cada um acaba virando, para um time de dados, uma consulta, um script ou um
procedimento:

| | a pessoa pode pedir | o que isso quer dizer no banco |
|---|---|---|
| I | **confirmação** de que seus dados são tratados | alguma linha aponta para ela? |
| II | **acesso** aos dados | toda linha sobre ela, legível |
| III | **correção** de dados incompletos, inexatos ou desatualizados | um `UPDATE`, e o registro de que foi pedido |
| IV | **anonimização, bloqueio ou eliminação** de dados desnecessários, excessivos ou tratados em desconformidade | achar o que nunca foi necessário — a minimização da aula 6 |
| V | **portabilidade** a outro fornecedor, mediante requisição expressa | a mesma exportação do II, num formato que outro sistema consiga ler |
| VI | **eliminação** dos dados tratados com consentimento, exceto onde o artigo 16 permite guardar | seção 10 |
| VII | **informação sobre com quem os dados foram compartilhados** | o registro das operações sabe, ou ninguém sabe |
| VIII | **informação sobre a possibilidade de não consentir**, e o que decorre da negativa | o texto do formulário |
| IX | **revogação do consentimento** | os eventos da seção 6 |

Quatro parágrafos do mesmo artigo moldam como se responde. O pedido é feito por **requerimento
expresso**, da pessoa ou de representante legal (§3º). Não custa **nada** à pessoa (§5º). Se o
controlador não puder agir de imediato, tem de dizer por quê, ou dizer que não é o controlador e
indicar quem é (§4º). E quando um dado é corrigido, eliminado, anonimizado ou bloqueado, o controlador
tem de **avisar os outros agentes com quem compartilhou o dado**, para que façam o mesmo (§6º) — o
que só é possível se alguém anotou quem são eles.

## Dois direitos além do artigo 18

O **artigo 9º** dá à pessoa o direito ao *acesso facilitado* às informações sobre o tratamento: a
finalidade, a forma e a duração, quem é o controlador e como falar com ele, com quem o dado é
compartilhado e para quê, e os direitos dela. Isso é o aviso de privacidade, e o registro das
operações da aula 6 é de onde ele deve ser escrito, e não o contrário.

O **artigo 20** deixa a pessoa pedir a **revisão de uma decisão tomada unicamente com base em
tratamento automatizado** que afete seus interesses, perfilamento incluído — um score de crédito, um
alerta de fraude que cancela um pedido. O controlador tem de explicar, quando pedido, os critérios e
procedimentos por trás da decisão, protegidos os segredos comerciais. O texto publicado primeiro dizia
que a revisão seria feita por pessoa natural; a reforma de 2019 (Lei 13.853) deixou essas palavras de
fora, então a lei não exige um humano na revisão. Um modelo de fraude que cancela pedidos sem ninguém
olhar ainda precisa ser explicável ao cliente que ele cancelou.

## O que os direitos exigem dos dados

Relendo a tabela como engenheiro, três coisas se destacam:

- **É preciso conseguir achar tudo sobre uma pessoa.** Os direitos I, II, V e VI começam aí. Um id
  de cliente que algumas tabelas carregam e outras alcançam por um join, e um campo de texto livre
  onde alguém digitou um CPF, são onde a busca dá errado.
- **É preciso guardar registro dos próprios pedidos** — o que foi pedido, quando, o que foi
  respondido —, porque valem o prazo da seção 9 e o ônus da prova da seção 6.
- **É preciso saber para quem você deu o dado**, porque o §6º obriga o controlador a repassar o
  pedido.

A aula 6 construiu a primeira dessas coisas, a classificação em `gov.column_class`. A próxima seção a
usa.
