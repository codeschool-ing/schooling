---
title: Duas perguntas na porta
version: 1
---

Todo pedido a um banco de dados responde a duas perguntas, e a maior parte da confusão sobre
acesso vem de tratá-las como uma só.

**Autenticação pergunta quem você é.** Uma senha, um certificado, o sistema operacional
garantindo qual usuário abriu o socket, um token do provedor de identidade da empresa. Ela é
respondida uma vez, quando a conexão abre, e a resposta é um nome: daí em diante a sessão *é*
aquele papel.

**Autorização pergunta o que esse nome pode fazer.** Se `bruno` pode ler `sales.customers`,
inserir em `support.tickets`, ver a coluna `cpf`, ou ver as linhas de clientes de outro estado
que não o dele. Ela é perguntada de novo a cada comando, contra privilégios guardados no próprio
banco.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l1-two-gates\" aria-label=\"Uma conexão ao PostgreSQL passa por dois portões. O primeiro, o pg_hba.conf com o método de autenticação, decide quem você é e se pode conectar. O segundo, os privilégios dentro do banco, decide o que esse papel pode fazer com cada objeto.\"><defs><marker id=\"dg-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"80.0\" width=\"120.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">um cliente</text><text x=\"80.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">psql -U bruno</text><rect x=\"180.0\" y=\"30.0\" width=\"220.0\" height=\"170.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"290.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" font-weight=\"600\" fill=\"var(--paper)\">1 · autenticação</text><text x=\"290.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">quem é você?</text><rect x=\"200.0\" y=\"96.0\" width=\"180.0\" height=\"36.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"290.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pg_hba.conf</text><rect x=\"200.0\" y=\"146.0\" width=\"180.0\" height=\"36.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"290.0\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">peer · scram · cert</text><rect x=\"440.0\" y=\"30.0\" width=\"260.0\" height=\"170.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" font-weight=\"600\" fill=\"var(--paper)\">2 · autorização</text><text x=\"570.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o que esse papel pode fazer?</text><rect x=\"460.0\" y=\"96.0\" width=\"220.0\" height=\"36.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CONNECT · USAGE · SELECT</text><rect x=\"460.0\" y=\"146.0\" width=\"220.0\" height=\"36.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">perguntada a cada comando</text><path d=\"M140.0 115.0 L178.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><path d=\"M400.0 115.0 L438.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path></svg>", "caption": "A autenticação é respondida uma vez, na porta; a autorização é perguntada de novo a cada comando.", "same": ["peer · scram · cert"]}
```

As duas falham de jeitos diferentes, e a falha diz qual delas você está vendo. A primeira
tentativa da Ana de usar o laboratório, antes de existir papel para ela:

```
ana@lab:~/gov$ psql
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: FATAL:  role "ana" does not exist
```

Esse é o primeiro portão: o servidor não sabe quem é `ana`, então não há o que autorizar. O
outro portão soa assim, numa sessão que conseguiu entrar:

```
ERROR:  permission denied for schema sales
```

A conexão funcionou. O comando, não. A seção 15 desta aula produz essa linha, e a aula 2 é
inteira sobre o segundo portão.

## Por que a diferença importa para dados

**Autenticação sem autorização dá tudo a todo mundo que loga.** É o estado mais comum do primeiro
banco de uma empresa: uma conta compartilhada, usada pelo site, pelos analistas e pelo job
noturno, com todos os privilégios que existem. Ninguém sabe dizer quem leu a tabela de receitas
no mês passado, porque "quem" é um nome para vinte pessoas e três programas.

**Autorização sem autenticação é pior, porque parece pronta.** Um conjunto cuidadoso de
permissões num papel cuja senha está numa planilha, ou uma linha `trust` na configuração que
deixa qualquer um na rede alegar qualquer nome, não protege nada: as permissões são conferidas
contra um nome que alguém escolheu.

Então uma plataforma de dados precisa das duas, e precisa que cada uma diga algo verdadeiro. Um
papel deve ser uma pessoa ou um programa, para que o que ele fez possa ser atribuído. E o método
que prova o nome deve ser forte o bastante para o nome significar alguma coisa.

## Onde cada portão mora no PostgreSQL

| | autenticação | autorização |
|---|---|---|
| configurada em | `pg_hba.conf`, um arquivo no servidor | `GRANT`, `REVOKE` e políticas, dentro do banco |
| decidida | uma vez, quando a conexão abre | a cada comando |
| falha com | `FATAL` e a conexão fecha | `ERROR` e a sessão segue |
| neste curso | aula 1, e certificados na aula 3 | aulas 2 e 5 |

O resto desta aula é o primeiro portão: os papéis que carregam os nomes, o arquivo que decide
como cada nome é provado, e o log que diz quem entrou.
