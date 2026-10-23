---
title: O que fica fora do log
version: 1
---

Um log é lido por mais gente que qualquer outra saída de um serviço: operadores, desenvolvedores, suporte, o
fornecedor da plataforma de logs, quem restaurar um backup no ano que vem. **Ele é guardado por mais tempo que
os dados que descreve**, e é copiado para lugares aonde o banco nunca vai. Então a regra do que ele pode
conter é mais rígida que a regra do banco, não mais frouxa.

## Nunca

- **Segredos.** Senhas, tokens, chaves de API, cookies de sessão, o cabeçalho `Authorization`. A linha de
  acesso do boxoffice registra o caminho e nunca um cabeçalho desde a aula 2, e é por isso que os tokens da
  equipe da aula 2 não aparecem em nenhum log deste curso.
- **Dados de pagamento.** Números de cartão e seus códigos de segurança, que as regras das bandeiras proíbem
  guardar em qualquer lugar fora de um sistema certificado.
- **Corpos inteiros de requisição ou resposta.** Um corpo contém o que o cliente mandou, inclusive tudo dos
  dois itens acima, e registrá-lo "para depurar" registra tudo isso.

## Só quando necessário, e reduzido

**Dados pessoais**, um e-mail, um nome, um endereço, são regulados: a LGPD no Brasil e o GDPR na Europa dão às
pessoas direitos sobre eles, inclusive o de apagá-los, e um log cheio de e-mails é uma cópia de dados pessoais
que ninguém vai encontrar quando o pedido de exclusão chegar. Registre um identificador no lugar, o id do
ingresso ou de uma conta, que leva ao dado onde ele é gerido. Quando um endereço ajuda mesmo, **reduza-o no
tipo**, como o `email` da seção 03 fez com `LogValue`: toda chamada que registra esse tipo recebe a forma
reduzida, e ninguém precisa lembrar.

## O que uma boa linha contém

O id da requisição, o método e o caminho, o status, o tamanho, a duração: a escolha da aula 2, agora como
campos. Os ids das coisas envolvidas, o evento e o ingresso. **O erro, por inteiro, do lado do servidor**, que
a aula 3 deixou fora da resposta ao cliente e pôs no log. E o nível, definido com honestidade: um 404 de um
cliente é `INFO`, não `ERROR`; um log em que tudo é erro é um log em que nada é.

## Conferindo

Uma regra mantida de memória falha. Três hábitos a sustentam: **tipos que se mascaram sozinhos**, como acima;
uma pergunta de revisão, "o que este campo pode conter?", para toda chamada de log nova que recebe um valor
de uma requisição; e uma busca de vez em quando nos logs reais por um `@`, um `Bearer` ou dezesseis dígitos
seguidos. Os testes da aula 15 podem afirmar que a saída de log de um handler não contém o token que ele
recebeu.
