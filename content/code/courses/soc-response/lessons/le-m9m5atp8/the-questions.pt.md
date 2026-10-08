---
title: As perguntas que a triagem faz
version: 1
---

A **triagem** é o primeiro olhar sobre um alerta: decidir, em minutos, se é ruído para fechar ou algo para
escalar. Não é a investigação. Um analista de triagem que passa uma hora num alerta parou de fazer triagem,
e a fila atrás dele está crescendo.

A semana, vista como um funil:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"A semana como um funil, de cima para baixo: 382 eventos na tabela; 150 logins falhos; 5 alertas da primeira regra da aula 4; 2 deles verdadeiros; 1 incidente, que é tudo o que aquele endereço fez naquela noite.\"><rect x=\"40.0\" y=\"12\" width=\"640\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"54.0\" y=\"29\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">382</text><text x=\"100.0\" y=\"29\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">eventos na tabela</text><rect x=\"100.0\" y=\"53\" width=\"520\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"114.0\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">150</text><text x=\"160.0\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">logins falhos</text><rect x=\"160.0\" y=\"94\" width=\"400\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"174.0\" y=\"111\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">5</text><text x=\"220.0\" y=\"111\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">alertas, regra v1</text><rect x=\"220.0\" y=\"135\" width=\"280\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"234.0\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2</text><text x=\"280.0\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">alertas verdadeiros</text><rect x=\"280.0\" y=\"176\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"294.0\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><text x=\"340.0\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">incidente</text></svg>", "caption": "Cada degrau para baixo é uma decisão que alguém tomou. A triagem é o terceiro e o quarto."}
```

Cada nível é uma decisão. A regra decidiu quais das 150 falhas mereciam uma pessoa; a triagem decide quais
alertas são verdadeiros, e quais verdadeiros pertencem ao mesmo incidente. Acertar o formato do funil importa
mais do que a velocidade: **fechar um alerta verdadeiro é o erro mais caro de um SOC**, porque nada adiante
vai olhar para ele de novo.

Cinco perguntas, em ordem, para todo alerta:

1. **O que disparou, e sobre o quê?** A regra, os campos, os eventos que ela casou. Leia; não confie no
   título.
2. **É real?** Os eventos dizem o que a regra afirma? Um erro de parsing ou um teste consegue produzir um
   alerta perfeito sobre nada.
3. **É esperado?** O histórico ou o negócio explicam: um usuário conhecido de um lugar conhecido, uma
   tarefa agendada, um teste aprovado?
4. **Quão grave seria?** Se for o que parece, quais ativos, dados e pessoas estão envolvidos?
5. **E agora?** Fechar com um motivo, escalar com o que você encontrou, ou pedir uma informação específica.

As perguntas 2 e 3 são onde a maioria dos alertas termina. A pergunta 4 é o que torna um alerta verdadeiro
urgente ou não.
