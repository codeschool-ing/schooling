---
title: Onde a camada mora em outras ferramentas
version: 1
---

A camada da Lantern são views SQL com comentários, e isso é uma camada semântica de verdade: toda
ferramenta que lê PostgreSQL a lê do mesmo jeito. Organizações maiores costumam usar um produto
feito para isso. Eles diferem em onde as definições moram e quanto impõem; a ideia é a que esta aula
construiu. As descrições abaixo vêm da documentação de cada produto, e nenhum deles rodou para o
curso.

| ferramenta | onde as definições moram | o que acrescenta às views |
|---|---|---|
| LookML, no Looker | arquivos de texto com views, medidas e os joins entre elas, guardados no git | os joins são declarados uma vez, então um usuário não consegue juntar duas tabelas de um jeito que o modelo não permite |
| dbt Semantic Layer, com MetricFlow | arquivos YAML ao lado de um projeto dbt, nomeando entidades, medidas e métricas | uma métrica é definida uma vez e compilada para SQL para a ferramenta que pedir, na granularidade que pedir |
| Cube | um servidor com arquivos de modelo próprios, entre o banco e as ferramentas | uma API na frente do banco, com cache e regras de acesso |
| um modelo semântico do Power BI | o modelo dentro de um arquivo do Power BI: relacionamentos, medidas em DAX | um modelo compartilhado por muitos relatórios, publicado no serviço do Power BI |

Três perguntas situam qualquer um deles, e são as mesmas três a fazer à camada desta aula:

- **Quem escreve uma definição, e onde ela é revisada?** Arquivos no git podem ser revisados como
  código; uma definição digitada na tela de uma ferramenta em geral não pode.
- **Um usuário consegue contorná-la?** Views podem ser contornadas por quem tem acesso às tabelas, e
  é por isso que o papel desta aula só lê a camada. Alguns produtos recusam joins inseguros de vez.
- **Quais ferramentas a leem?** Views são lidas por qualquer coisa que fale SQL. A camada própria de
  um produto é lida pelas ferramentas que a suportam, e uma definição que mora num único painel
  deixa de ser compartilhada no momento em que chega uma segunda ferramenta.

A aula 4 monta a mesma estrela como um modelo semântico do Power BI, e a aula 5 reencontra o LookML
no contexto do Looker.
