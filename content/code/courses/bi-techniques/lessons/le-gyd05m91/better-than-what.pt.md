---
title: Melhor que o quê?
version: 1
---

**Uma previsão só é boa comparada com alguma coisa**, e a comparação mais esquecida é com as
previsões que não precisam de método. Antes de alguém ajustar Holt-Winters, ARIMA ou Prophet, três
referências deveriam estar na mesa:

| referência | a previsão | onde ela ganha de você |
|---|---|---|
| **ingênua** | o último valor, repetido | séries que vagueiam, em que o valor mais recente é o melhor palpite |
| **ingênua sazonal** | a mesma semana do ano passado | séries dominadas por uma sazonalidade estável |
| **média** | a média do histórico | séries que são quase só ruído em volta de um nível fixo |

Elas não custam nada, ninguém precisa mantê-las, e em muitas séries reais uma delas é difícil de
vencer. Um método que não vence a previsão ingênua sazonal está acrescentando complexidade e nenhuma
precisão, e não deveria ser usado, por mais sofisticado que pareça. A aula 5 mede todas as previsões
desta aula contra a ingênua e a ingênua sazonal nas mesmas semanas de 2025.

## Escolher entre as três famílias

| | suavização exponencial | ARIMA | Prophet |
|---|---|---|---|
| pensa em termos de | nível, tendência, sazonalidade | dependência do passado recente | tendência com dobras, sazonalidades, feriados |
| precisa de você | os tipos de tendência e sazonalidade | `p`, `d`, `q` e os gêmeos sazonais | lista de feriados, pontos de mudança se conhecidos |
| no seu melhor | séries de negócio sazonais estáveis | séries com impulso de curto prazo | dado diário, várias sazonalidades, muitos feriados |
| custo de um erro | geralmente leve | uma ordem mal escolhida pode prever bobagem | uma lista de feriados errada ajusta a história errada |

**Nenhuma delas é a melhor em geral**, e competições de previsão com milhares de séries reais
encontraram de novo e de novo que métodos simples e médias de vários métodos são difíceis de vencer.
A regra prática é curta: comece pelas referências, ajuste um ou dois métodos que combinem com a
série, e fique com o que se sair melhor em dados que ele não viu. As aulas 4 e 5 mostram como.
