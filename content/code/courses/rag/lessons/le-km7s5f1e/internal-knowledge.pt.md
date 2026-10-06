---
title: Bases de conhecimento internas
version: 1
---

O quarto uso é o que as empresas pedem primeiro e implantam por último: um assistente sobre tudo o que
a empresa escreveu para si mesma. O manual de atendimento, o runbook do armazém, os procedimentos do
financeiro, as atas de todas as reuniões. O valor é óbvio, porque o conhecimento existe e ninguém
consegue achá-lo. A dificuldade é que **documentos internos foram escritos para leitores
específicos**, e um assistente que lê todos eles em nome de qualquer pessoa removeu em silêncio uma
fronteira com que os documentos contavam.

## Para quem é cada documento

Cada documento deste corpus diz para quem foi escrito, no cabeçalho:

```
ana@lab:~/rag$ grep -h "^audience:" data/docs/*.md | sort | uniq -c
      1 audience: developers
      1 audience: finance
      8 audience: public
      1 audience: sellers
      2 audience: staff
```

Oito são públicos: qualquer um pode ler o regulamento de devoluções. Dois são para funcionários, um
para vendedores do marketplace, um para desenvolvedores com chave de afiliado, e um só para a equipe
financeira. O documento do financeiro diz isso no primeiro parágrafo: *do not share the thresholds in
this document with support agents, sellers or customers: an agent who knows them can be talked into
working around them.*

Agora pergunte à busca da mesa de um atendente:

```
ana@lab:~/rag$ python sections.py "When does an order get held for manual fraud review?"
[1] 0.720  finance-refund-controls > Automatic holds
[2] 0.573  support-handbook > Suspected fraud
[3] 0.514  finance-refund-controls > Finance reviews
An order with a score of 0.82 or more is held before dispatch and goes to manual review. [1] The payment provider gives every order a fraud score from 0 to 1. [1]
```

**O limiar exato que a equipe financeira pediu para esconder dos atendentes, entregue a um atendente,
com citação.** Nada deu errado no pipeline. A pergunta era uma boa pergunta, a busca achou a melhor
seção, o gerador a citou fielmente. O vazamento é uma propriedade do projeto: um índice só sobre
documentos com leitores diferentes, e uma busca que não sabe quem está perguntando.

A seção certa para esse atendente era a segunda, *Suspected fraud* do manual, que diz para abrir uma
revisão do financeiro e continuar respondendo ao cliente normalmente. Ela veio em segundo porque fala
do que *fazer*, e a pergunta era sobre a regra.

## Por que isso não se resolve no prompt

A solução tentadora é uma instrução: *não revele informação confidencial.* Ela falha por um motivo que
vale dizer com todas as letras. **Quando o texto está no prompt, ele já foi revelado ao modelo**, e a
única coisa entre ele e o leitor é o julgamento do modelo sobre uma instrução. Um modelo pode ser
convencido a contornar uma instrução; uma pergunta pode ser formulada de modo que o limiar seja citado
como parte de "explicar o processo"; e o modelo não consegue dizer qual leitor tem direito a quê,
porque nada na requisição diz quem é o leitor.

O único lugar confiável para a fronteira é **antes da recuperação**: a busca devolve só pedaços que
quem pergunta pode ler, decidido por quem a pessoa é, não pelo que perguntou. Isso precisa do público
guardado ao lado de cada pedaço, o que a aula 5 faz, e de um filtro construído a partir do papel do
usuário logado, que é a aula 14. Até lá, o arranjo honesto são dois índices, um público e um por
público, e as execuções desta aula mostram por que um índice só para tudo não é um atalho.

## O que o conhecimento interno pede de um pipeline

- **Permissões em cada pedaço**, copiadas do documento na indexação e aplicadas na busca.
- **Um dono para cada documento.** A linha `owner:` do cabeçalho diz quem mantém cada um verdadeiro;
  uma base de conhecimento interna apodrece mais rápido porque não é trabalho de ninguém mantê-la
  atual.
- **Exclusão que funciona.** Quando um documento é retirado, os pedaços dele têm de sair do índice no
  mesmo dia, não na próxima reconstrução completa.
- **Um registro do que foi perguntado e do que foi recuperado**, para que um vazamento como o de cima
  seja achado num log e não num print. A aula 9 registra cada consulta.
