---
title: Pôr a decisão por escrito
version: 1
---

**Uma decisão que ninguém escreveu acaba sendo tomada de novo, por alguém que não sabe por que ela foi
tomada da primeira vez.** Um ano depois de a Roda Livre escolher onde moram as suas tabelas, um
engenheiro novo vai olhar a escolha e ver só os custos, porque os motivos ficaram numa reunião. Ou ele
desfaz a escolha e redescobre os motivos do jeito difícil, ou a deixa como está e ninguém sabe dizer
se ela ainda faz sentido.

O remédio é curto. Michael Nygard o propôs num texto de 2011, *Documenting Architecture Decisions*: um
**registro de decisão de arquitetura**, ou ADR (*architecture decision record*), uma página de texto
para cada decisão importante, guardada no mesmo repositório do código que ela afeta. Aqui está o que
Davi e Ana escreveram depois da matriz:

```localised
# 3. As tabelas analíticas moram num servidor PostgreSQL que nós rodamos

Situação: aceita, 8 de outubro de 2025
Decidido por: Davi, Ana. Consultados: Marta, Caio.

## Contexto
Marta precisa da contagem por estação antes das saídas da van às 09:30 e
às 16:00, com dados de no máximo duas horas. Um ano de leituras das docas
ocupa menos de 4 GB.
O time tem duas pessoas. Davi roda PostgreSQL há seis anos; ninguém aqui
rodou um warehouse gerenciado.
Notas com pesos para um time de dois: PostgreSQL que rodamos 36, warehouse
gerenciado 35, Parquet no armazenamento 33. Com pesos para um ano de
crescimento, o warehouse gerenciado vence, 39 a 31.

## Decisão
Manter as tabelas analíticas num servidor PostgreSQL que nós rodamos,
separado do banco do aplicativo. Manter os arquivos brutos em Parquet,
para que as tabelas possam ser reconstruídas em outro lugar.

## Consequências
Boa: usa o que o time conhece, e não há cobrança por consulta.
Ruim: cerca de dez horas por mês de manutenção, e Davi fica de plantão.
Ruim: espaço para crescer teve a nota mais baixa; uma segunda cidade
o poria à prova.

Revisitar quando uma segunda cidade assinar, quando uma consulta de que
Marta precisa levar mais de um minuto, ou quando a manutenção passar de
vinte horas num mês.
```

## As partes, e por que cada uma está ali

- **Um número e um título que enuncia a decisão.** "As tabelas analíticas moram num servidor
  PostgreSQL que nós rodamos" é fácil de achar e diz o resultado; "Discussão sobre banco de dados" não
  é nem uma coisa nem outra.
- **Uma situação.** Proposta, aceita ou substituída. Um ADR não é editado depois de aceito. Quando a
  decisão muda, um registro novo diz isso e o antigo é marcado *substituído pelo 9*, para a história
  do raciocínio sobreviver.
- **O contexto**: os fatos que eram verdade quando a decisão foi tomada. Esta é a parte que envelhece,
  e é por isso que vale guardar o registro. Quem ler em 2027 pode ver que o time tinha duas pessoas e
  o dado ocupava 4 GB, e julgar se isso ainda vale.
- **A decisão**, em uma ou duas frases, na voz ativa.
- **As consequências, inclusive as ruins.** Um registro que só lista vantagens é um discurso de vendas,
  e o próximo engenheiro vai desconfiar dele inteiro. Escrever que Davi fica de plantão é o que torna
  o custo visível para quem um dia vai pagá-lo.

A última linha não está no original de Nygard, e é o hábito mais útil a acrescentar: **as condições
que reabririam a decisão**. Ela transforma "revisitar algum dia" em algo que uma pessoa consegue
conferir. Duas das três condições são medidas, o que faz dela o mesmo tipo de promessa que um SLO:
quando a consulta passar de um minuto, a pergunta volta sozinha.

O registro levou vinte minutos para ser escrito. `architecture` e `tech-strategy` vão mais fundo em
manter decisões vivas num time maior; para duas pessoas, um arquivo numerado por decisão no
repositório do pipeline basta.
