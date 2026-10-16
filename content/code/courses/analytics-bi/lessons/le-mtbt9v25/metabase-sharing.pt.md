---
title: Coleções, permissões e links
version: 1
---

Uma pergunta que só o autor encontra é um rascunho. O Metabase organiza o trabalho salvo em
**coleções**, que são pastas: uma coleção pessoal por pessoa, e coleções compartilhadas para times.
Quem procura as perguntas de receita da Lantern deveria achá-las numa coleção compartilhada com nome,
e não em onze pessoais.

Quem pode ver o quê é decidido nas configurações de admin, em **Permissions**, por **grupos** de
pessoas, e tem duas camadas fáceis de confundir:

- **permissões de dados** decidem que bancos, schemas e tabelas um grupo pode consultar, e se pode
  escrever SQL ou só usar o editor;
- **permissões de coleção** decidem que perguntas e painéis salvos um grupo pode abrir ou editar.

As duas se combinam. Um grupo com acesso a uma coleção mas não aos dados por trás de uma pergunta abre
a pergunta e tem o resultado recusado. O arranjo da Lantern da aula 3 ajuda aqui: o Metabase chega ao
banco por um papel que só lê a camada, então mesmo a permissão de dados mais generosa dentro do
Metabase para em `semantic`.

## Links públicos

O Metabase consegue compartilhar uma pergunta ou um painel por um **link público**: um endereço que
qualquer um abre sem entrar. Na versão que este curso roda, o compartilhamento público **vem ligado
numa instalação nova**, como as configurações dele mostravam quando o curso foi gravado; um
administrador pode desligá-lo nas configurações de admin, e num Metabase com dados de clientes essa é a
primeira coisa a fazer. Trate um link público como publicação: quem tiver o link vê os dados, o link
viaja em e-mails e conversas, e revogá-lo depois não desfaz o que foi visto. Para qualquer coisa com
dados de clientes, a resposta é não.

Painéis — várias perguntas numa página, com filtros que as movem juntas — são o outro tipo de trabalho
salvo do Metabase, e a aula 6 trata de montar um bem.
