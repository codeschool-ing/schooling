---
title: Onde dá errado
version: 1
---

O OWASP Top 10, a lista de riscos de aplicações web mais usada, pôs o **controle de acesso quebrado**
em primeiro lugar na edição de 2021. Quase todo caso é um de poucos erros, e cada um é uma versão de
confundir as duas perguntas desta aula.

### Autenticado, logo permitido

O portal confere o dono do holerite contra o usuário logado. Imagine uma versão que não conferisse:
qualquer usuário logado poderia trocar `/payslips/ana` por `/payslips/bruno` no endereço e ler. Essa
falha tem nome, **referência direta insegura a objeto** (*insecure direct object reference*, IDOR): o
endereço se refere direto a um objeto, e o programa nunca pergunta se este usuário pode ter aquele
objeto. É comum porque é invisível no uso normal. Todo usuário que clica nos links que recebeu vê só os
próprios dados, e só quem edita o endereço acha o buraco.

### A verificação que mora na página

Uma página que esconde o menu "admin" dos usuários comuns não os impediu de usar as funções de admin;
impediu que vissem o botão. Se o servidor por trás do botão não conferir o papel de novo, qualquer um
que mande o mesmo pedido direto, como o `curl` fez no laboratório, passa. **Toda verificação que
importa roda no servidor.**

### Uma verificação faltando num caminho

Uma aplicação com quarenta páginas confere permissões em trinta e nove. A quadragésima, uma exportação
acrescentada às pressas, devolve a lista inteira de clientes a qualquer um logado. O controle de acesso
falha na página mais fraca, e é por isso que o `secure-code` ensina a pôr a verificação num lugar só
por onde todo pedido passa, do jeito que o ponto de aplicação da aula 7 fica na frente de todo recurso.

### Respostas que vazam

Um formulário de login que diz "usuário não existe" para um erro e "senha errada" para o outro contou a
um atacante quais nomes de usuário existem. O portal do laboratório responde 401 para os dois, e as
páginas de holerite recusam antes de conferir a existência, as duas coisas pelo mesmo motivo: **uma
recusa não deve responder a uma pergunta que a pessoa não podia fazer.**

### 401 e 403 não são enfeite

Acertar os códigos ajuda quem opera um sistema tanto quanto quem o usa. Uma alta de 401 no log são
pessoas falhando em provar quem são: senhas esquecidas, ou alguém tentando adivinhar. Uma alta de 403
são pessoas que provaram quem são e estão pedindo o que não podem ter: um papel errado, ou uma conta
sendo usada por alguém explorando. Dois problemas diferentes, e o código diz qual olhar. A aula 11
trata de transformar sinais como esses em alertas.
