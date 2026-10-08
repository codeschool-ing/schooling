---
title: Registrando a dívida onde ela possa ser vista
version: 1
---

Dívida técnica que vive só na cabeça dos desenvolvedores tem três problemas: é invisível para quem decide prioridades, é esquecida quando quem a conhecia vai embora, e não pode ser comparada, porque ninguém anotou quanto ela custa. Registrá-la é o passo que transforma reclamações em gestão.

## Um registro de dívida

A forma mais simples é uma lista, mantida ao lado do product backlog ou dentro dele, com uma entrada por item de dívida:

| campo | exemplo |
|---|---|
| o quê | a suíte de testes de ponta a ponta falha ao acaso mais ou menos uma vez a cada cinco execuções |
| onde | os testes de agendamento e pagamento; o banco de testes compartilhado |
| juros | cada desenvolvedor perde cerca de meia hora por dia com reexecuções: umas 25 horas por Sprint para o time |
| principal | cerca de 60 horas: isolar os dados de teste e trocar três esperas dependentes de tempo |
| como surgiu | prudente, inadvertida: a suíte cresceu mais rápido que o projeto dela |
| dono | uma pessoa nomeada que mantém a estimativa em dia |
| situação | aberta, revista pela última vez na retrospectiva da Sprint 14 |

**O campo de juros é o que importa.** Sem ele, o registro é uma lista de queixas; com ele, cada item vira algo que pode ser pesado contra uma funcionalidade, como a aula 12 fez com o WSJF.

## No backlog, não ao lado dele

Um registro mantido num documento separado é fácil de parar de ler. Muitos times põem os itens de dívida **no product backlog**, marcados para serem encontrados, onde o Product Owner os vê toda vez que ordena o backlog. A descrição do item carrega os juros e o principal, escritos nos termos que a aula 12 pediu: horas perdidas, risco carregado, datas que importam.

## Registros de decisão de arquitetura

Alguma dívida é assumida de propósito, como decisão: "vamos manter os dados de todas as clínicas num banco por enquanto, e separar quando passarmos de cinquenta clínicas". O lugar disso é um **registro de decisão de arquitetura** (ADR), um documento curto com o contexto, a decisão, as alternativas e as consequências, numerado e guardado junto do código. Um ADR escrito na hora registra o **gatilho de pagamento** — cinquenta clínicas —, para a dívida ser paga quando vencer e não quando alguém se lembrar.

## Ferramentas que estimam dívida

Ferramentas de análise estática informam um número de dívida técnica, em geral em dias de correção, calculado a partir de violações de regras no código. O número é útil como tendência dentro de um código, e enganoso como valor absoluto: conta o principal de tudo o que as regras detectam, sem ideia nenhuma dos juros. Um módulo com cem violações em que ninguém mexe fica, aos olhos da ferramenta, acima de uma suíte de testes instável que custa ao time vinte e cinco horas por Sprint e não tem violação nenhuma.
