---
title: O OWASP API Security Top 10
version: 1
---

**A OWASP, Open Worldwide Application Security Project, publica uma lista dos dez riscos que mais vê
em APIs reais, e a edição de 2023 é a atual.** Não é uma lista de ataques para decorar. Cada item é um
erro no jeito como uma API foi projetada ou implantada, e cada um tem uma defesa que este curso já
construiu ou nomeou.

| risco | o que dá errado | a defesa | aula |
|---|---|---|---|
| API1 Broken Object Level Authorization | um cliente pede `/v1/orders/1042` e recebe, embora o pedido 1042 seja de outra pessoa | conferir, em toda requisição, que quem chama pode ter **este objeto**, e não só este tipo de objeto | 11 |
| API2 Broken Authentication | senhas enviadas ou guardadas mal, tokens que nunca expiram, login sem limite de tentativas | mecanismos padrão, implementados por uma biblioteca, nunca inventados | 7, 8, 9, 10 |
| API3 Broken Object Property Level Authorization | a resposta traz campos que quem chama não devia ver, ou uma escrita aceita campos que ele não devia definir, como `role` | a representação montada campo a campo, campos desconhecidos recusados, campos graváveis conferidos por papel | 1, 2, 11 |
| API4 Unrestricted Resource Consumption | um cliente manda requisições suficientes, ou pede linhas suficientes, para deixar a API lenta para todos ou aumentar a conta dela | limites por cliente, de taxa e de tamanho | 12 |
| API5 Broken Function Level Authorization | uma conta comum chama um endpoint de administrador e funciona | toda função confere o papel ou o escopo de quem chama, as administrativas acima de todas | 11 |
| API6 Unrestricted Access to Sensitive Business Flows | um fluxo legítimo, comprar, reservar, cadastrar, executado mil vezes por um programa | limites que seguem o negócio, por conta e por fluxo | 12 |
| API7 Server Side Request Forgery | a API busca um endereço que o cliente forneceu, e o cliente fornece um interno | uma lista de destinos permitidos, e endereços conferidos antes de conectar | esta |
| API8 Security Misconfiguration | um CORS permissivo, cabeçalhos faltando, HTTP simples, erros falantes, uma versão no `Server` | uma configuração decidida uma vez e aplicada a toda resposta | esta |
| API9 Improper Inventory Management | uma versão antiga ou um endpoint de teste esquecido ainda respondendo, sem correções | um contrato escrito de todo endpoint e toda versão, e versões antigas aposentadas | 1, 6 |
| API10 Unsafe Consumption of APIs | a API confia no que a API de um parceiro manda mais do que no que os usuários mandam | as respostas do parceiro validadas como qualquer entrada | esta |

Os nomes ficam em inglês, como a OWASP os publica, porque são nomes.

## O que a lista diz sobre onde está o perigo

**Três dos dez são autorização em três profundidades diferentes**: o objeto (API1), as propriedades do
objeto (API3) e a função (API5). O primeiro deles encabeça a lista inteira, e os três têm a mesma
causa: a autenticação respondeu "quem é?", e depois ninguém perguntou "e essa pessoa pode fazer
*isto*?". A própria autenticação, API2, é um quarto. É por isso que as aulas 7 a 11 são metade deste
curso.

**Dois são sobre volume** e não sobre uma requisição isolada: API4 é demais de qualquer coisa, API6 é
demais de algo que é permitido. Um limite de taxa defende os dois, e a API6 ainda pede uma decisão que
só o negócio pode tomar, como quantos ingressos uma conta pode comprar.

**A API8 é o assunto desta aula.** Tudo o que as seções anteriores fizeram no `secure.py` é
configuração: quais origens podem ler, quais cabeçalhos saem, se a conexão é cifrada, o que um erro
diz sobre o servidor. Nada disso é algoritmo, e cada peça é uma linha fácil de esquecer.

**A API9 é a que se esconde.** Um inventário é uma lista de todo endpoint e toda versão que responde,
e o documento OpenAPI da aula 6 é essa lista quando é mantido verdadeiro. A rota `/v2` de um livro
na aula 1 é o caso em miniatura: depois que `/v2` existe, `/v1` continua acessível até alguém decidir
aposentá-la, e um endpoint de que ninguém se lembra é um endpoint que ninguém corrige.

A API7 e a API10, as outras duas marcadas "esta", são o assunto da próxima seção: nas duas, é a API
quem faz uma requisição.
