---
title: Quando gRPC, e quando não
version: 1
---

**O gRPC serve entre programas que são seus nas duas pontas, e serve mal onde quem chama é de outra
pessoa.** Dentro de uma empresa, uma equipe publica um `.proto`, todas as outras geram a partir dele,
e o compilador prende todas a ele. Na borda, quem chama pode ser um navegador, um parceiro que só tem
o `curl` ou um script escrito numa tarde, e é mais fácil atender cada um deles com o JSON da aula 1.

A ideia errada é a de que o gRPC é um REST mais rápido e o substitui. Trinta e três bytes contra
oitenta e cinco é real, e para a maioria das APIs não é o que decide: uma requisição que passa o
tempo esperando um banco de dados não vai perceber se a resposta tinha 33 bytes ou 85. O que decide
é quem está na outra ponta.

## Onde ele vale a pena

**Entre os seus próprios serviços.** Os dois lados são gerados de um arquivo só, uma mudança que
quebra o contrato quebra o build em vez da produção, e um prazo passa de um serviço para o seguinte
sem ninguém escrever código para isso.

**Onde os dados precisam fluir, e não ser buscados.** Um nível que muda, uma entrega enviada aos
pedaços, uma conversa nos dois sentidos: os quatro tipos de chamada dão a cada um o seu formato, numa
conexão só, onde o REST faria polling ou precisaria de outra tecnologia ao lado.

**Onde muitas linguagens se encontram.** As quatro linguagens da trilha têm gRPC, e um `.proto` é o
mesmo contrato em cada uma delas.

## Onde não

**Uma API pública.** Quem a usa quer ler uma resposta com os olhos, testá-la com o `curl` e chamá-la
de um navegador. As três coisas vêm de graça com a aula 1 e são um projeto com gRPC.

**Qualquer coisa que um navegador chame direto**, pelo motivo da seção anterior: precisa de gRPC-Web
e de um proxy, ou de um gateway JSON, que é uma API REST com passos a mais.

**Respostas que um cache poderia servir.** Toda chamada gRPC é um `POST`, e caches HTTP não guardam
as respostas de `POST`. Um catálogo que milhares de pessoas leem e poucas mudam é aquilo para que o
`GET` da aula 1 e o cache dele foram feitos.

| situação | escolha | porque |
|---|---|---|
| o depósito respondendo aos caixas | gRPC | as duas pontas são suas, e o estoque muda enquanto um caixa observa |
| o catálogo da livraria para parceiros | REST | desconhecidos, `curl`, navegadores e caches |
| a exportação noturna de vendas para o contador | REST | um download de JSON que qualquer um abre, e nada para transmitir |
| dez serviços internos em quatro linguagens | gRPC | um contrato, gerado em todo lugar, prazos repassados |

**A resposta comum na prática é os dois**: REST ou GraphQL na borda, onde quem chama é de outras
pessoas, e gRPC atrás, onde quem chama é seu. O shelf já tem esse formato, com o `rest.py` na porta
8000 para os clientes da loja e o depósito na 50051 para os caixas.
