---
title: O que um erro não pode dizer
version: 1
---

A crença tentadora é que mais detalhe num erro ajuda todo mundo: o cliente vê exatamente o que quebrou e
pode relatar. Mas o cliente de uma API é um estranho, e os detalhes de uma falha dentro do servidor são
coisas sobre as quais ele não pode fazer nada: um banco que recusou uma conexão, um comando SQL, um nome
de classe, a versão de uma biblioteca. Para um cliente de boa-fé, isso é ruído. Para alguém sondando a
API, é um mapa do lado de dentro, dizendo qual banco roda em qual máquina com qual usuário. **A resposta
diz o que o cliente pode fazer, e o log guarda todo o resto.**

## Uma falha que ninguém previu

A livraria não tem banco de dados até a aula 9, então este desvio planta um substituto para um banco que
falhou. No `InMemoryBookRepository.java`, troque o `findById` por este:

```java
    @Override
    public Optional<Book> findById(long id) {
        throw new IllegalStateException("connection to db-01.bookshop.example:5432 refused for user bookshop");
    }
```

Compile, reinicie e peça o livro 1:

@@CAP unexpected@@

Nenhum handler da `ApiErrorHandler` reclama uma `IllegalStateException`, então este é o 500 da primeira
seção desta aula, e o corpo é o do Spring Boot: um timestamp, o status, a frase dele e o caminho. A
mensagem não está ali. O segundo terminal tem tudo:

@@CAP unexpected-log@@

Essa divisão é o padrão do Spring Boot, não sorte. A página de erro dele tem propriedades que decidem o
que vai para o corpo, e a livraria as deixa no padrão. Ligar uma delas mostra o que o padrão deixa de
fora. Iniciada com `--server.error.include-message=always`, a mesma requisição responde:

@@CAP include-message-1@@

E com `--server.error.include-stacktrace=always`, o corpo traz o stack trace inteiro, cortado aqui nas
primeiras linhas pelo `head`:

@@CAP include-message-2@@

@@TRACE-SENTENCE@@ Nenhuma das duas propriedades pertence a uma configuração implantada, e o log já tem
tudo o que elas acrescentam.

## O pega-tudo que vaza

O jeito comum de trazer o 500 também para o formato de problema é um handler para `Exception`, a mãe de
quase tudo. Escrito às pressas, ele fica assim. Acrescente-o à `ApiErrorHandler` acima da sobrescrita,
como um segundo desvio, depois compile e reinicie:

```java
    @ExceptionHandler(Exception.class)
    public ProblemDetail unexpected(Exception e) {
        return problem(HttpStatus.INTERNAL_SERVER_ERROR, "unexpected", "Unexpected error", e.getMessage());
    }
```

@@CAP catch-all@@

@@CATCHALL-PARAGRAPHS@@

Apague o método e devolva o `findById` ao que era antes de seguir.

## Por que a livraria não tem pega-tudo

Um pega-tudo pode ser escrito com segurança: ele registra a exceção com o stack trace e responde com uma
frase fixa que não nomeia nada. Muitas aplicações têm um. A livraria não tem, porque "tudo o que nada
mais específico reclama" cresce junto com a aplicação. O Spring Security, que chega na aula 15, recusa
acesso lançando uma exceção própria e a transforma em 401 ou 403 mais adiante, depois que o controller
terminou; um handler para `Exception` no advice pode pegá-la antes e responder 500. A página de erro do
Spring Boot já faz a metade segura do trabalho, registrando tudo e não dizendo nada. O preço é que o 500
da livraria é a única resposta fora do formato de problema, um preço pago por um erro que não deveria
acontecer.

## O que um detail pode dizer

Todo `detail` da livraria é uma frase que alguém escreveu para o cliente, montada com o que o cliente
mandou. "No book has id 99" devolve o id que foi pedido e nada mais. As mensagens das restrições foram
escritas para quem preenche o formulário. E os handlers do próprio Spring seguem a mesma regra: um corpo
que não é JSON recebe "Failed to read request" @@JACKSON-CLAUSE@@

**Então `e.getMessage()` só vai para uma resposta quando foi você quem escreveu a exceção.** A mensagem
de uma biblioteca é escrita para o desenvolvedor que vai ler o log, e traz o que desenvolvedores
precisam: SQL, caminhos, nomes de máquinas, valores de outras linhas. A aula 13 de `apis` põe isso ao
lado das outras formas de uma API contar demais a um estranho.
