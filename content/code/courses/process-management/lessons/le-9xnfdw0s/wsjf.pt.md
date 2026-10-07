---
title: Weighted shortest job first
version: 1
---

O custo do atraso diz quanto custa esperar. Ainda não diz o que fazer primeiro, porque os itens também diferem em quanto tempo levam. A resposta de Reinertsen é o **weighted shortest job first**, ou WSJF (o trabalho mais curto ponderado primeiro): divida o custo do atraso de cada item pela duração dele, e faça primeiro a razão mais alta.

```localised
WSJF = custo do atraso / tamanho do trabalho
```

A lógica é a de uma fila. Um trabalho curto com alto custo do atraso deveria passar na frente de um longo, porque enquanto o curto é feito o longo perde pouco, e o contrário faria o curto perder muito. A razão captura as duas coisas de uma vez.

## A versão do SAFe

Medir o custo do atraso em dinheiro é difícil, então o SAFe, que tornou o WSJF conhecido, o estima em **pontos relativos** como a soma de três componentes, cada um na escala de Fibonacci modificada da aula 10:

- **valor para o usuário e o negócio** — quanto usuários ou o negócio o querem;
- **criticidade de tempo** — quão rápido o valor decai, o perfil de urgência da seção anterior;
- **redução de risco e habilitação de oportunidades** — quanto ele reduz risco ou abre opções futuras.

O tamanho do trabalho é estimado na mesma escala relativa. O terceiro componente é o que mais importa a um arquiteto, e a seção depois da próxima volta a ele.

## Os quatro candidatos do time Agenda

| funcionalidade | valor | tempo | risco | custo do atraso | tamanho | WSJF |
|---|---|---|---|---|---|---|
| agendamento online | 13 | 8 | 3 | 24 | 13 | 1,85 |
| lembretes por SMS | 8 | 5 | 1 | 14 | 3 | 4,67 |
| atualização do banco | 1 | 8 | 13 | 22 | 5 | 4,40 |
| relatórios para donos de clínica | 8 | 2 | 2 | 12 | 8 | 1,50 |

A ordem é **lembretes por SMS, atualização do banco, agendamento online, depois relatórios**. O agendamento online tem o maior custo do atraso de todos e ainda assim vem em terceiro, porque também é o maior trabalho: dois itens menores entregam o valor deles enquanto ele ainda estaria em andamento. A atualização do banco, com quase nenhum valor direto para os usuários, vem em segundo, pela criticidade de tempo — a versão atual sai de suporte em breve — e pelo risco que remove.

## Na planilha

Com os componentes nas colunas B a E das linhas 2 a 5, nas fórmulas de uma planilha em português, o LibreOffice devolveu:

```localised
F2   =B2+C2+D2                                     24
G2   =ARRED(F2/E2;2)                               1,85
G3   =ARRED(F3/E3;2)                               4,67
=ÍNDICE(A2:A5;CORRESP(MÁXIMO(G2:G5);G2:G5;0))      SMS reminders
```

Em inglês, `ARRED` é `ROUND`, `ÍNDICE` é `INDEX` e `CORRESP` é `MATCH`.

## Os limites dele

O WSJF é a razão de duas estimativas, então herda a incerteza das duas, e mudanças pequenas nas entradas podem trocar vizinhos de lugar. Ele serve melhor para separar o claramente primeiro do claramente último, com o meio resolvido em conversa. E como todo componente é relativo, os números não significam nada fora da sessão que os produziu, como os story points da aula 10.
