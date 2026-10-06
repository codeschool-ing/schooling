---
title: Dado de teste não é dado de produção
version: 1
---

O jeito mais rápido de conseguir dados de teste realistas é copiar a produção. É também o jeito como
uma empresa acaba com nomes, endereços e históricos de compra de clientes no notebook de cada
desenvolvedor, em cada log de CI e em cada banco de homologação com controle de acesso mais fraco que
o real. Pela LGPD, uma cópia de dados pessoais é um tratamento como outro qualquer: precisa de
finalidade e de base legal, e "era conveniente para os testes" não é nenhuma das duas.

**Dado de teste se fabrica, não se pega.** Tudo o que os testes do `shipquote` usam foi escrito para
eles. Os endereços de e-mail, por exemplo:

```
ana@laptop:~/shipquote$ grep -rhoE '[a-z]+@[a-z.]+' tests/ | sort | uniq -c
      3 bia@example.org
```

Um endereço, três usos, em `example.org`. Esse domínio, com `example.com` e `example.net`, é
reservado pelo RFC 2606 para documentação e testes, então um teste que mande e-mail sem querer manda
para lugar nenhum e não alcança pessoa real alguma. O mesmo cuidado vale para os outros
identificadores que um sistema brasileiro trata:

| identificador | o que os testes deveriam usar |
|---|---|
| e-mail | um endereço em `example.org`, `example.com` ou `example.net` |
| CEP | CEPs reais de lugares públicos, como `01310-100` na Avenida Paulista |
| CPF | números gerados para passar nos dígitos verificadores, nunca o de uma pessoa real |
| número de cartão | os números de teste que um provedor de pagamento publica para a sandbox |
| endereço IP | as faixas de documentação, `192.0.2.0/24` e as duas irmãs |

## Quando o dado de produção é mesmo necessário

Às vezes é: um defeito que só os dados de um cliente reproduzem, ou um desempenho que depende de
distribuições reais. As respostas defensáveis, em ordem de preferência:

1. **Reproduzir a forma, não o dado.** Descubra o que o registro com falha tem de especial, um nome
   com apóstrofo, um endereço com 300 caracteres, e escreva um caso de fábrica para isso.
2. **Anonimizar antes de copiar.** Troque nomes, documentos e contatos por valores gerados, de forma
   consistente, para os relacionamentos sobreviverem e as pessoas não. Faça isso dentro da fronteira
   da produção, antes de o dado sair.
3. **Levar o teste até o dado**, sob os controles de acesso da produção, em vez de levar o dado até
   o teste.

## Dados no pipeline

Da aula 5 em diante, os testes rodam em máquinas que você não observa, e a saída deles fica em logs
que muita gente lê. Um teste que imprime o registro de um cliente quando falha o publica. A aula 9
trata de manter segredos fora do pipeline; dados pessoais merecem o mesmo tratamento, e o jeito mais
barato de mantê-los fora dos logs é nunca tê-los nos testes.
