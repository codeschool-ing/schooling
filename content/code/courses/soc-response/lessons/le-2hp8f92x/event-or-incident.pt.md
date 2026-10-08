---
title: Evento, alerta, incidente
version: 1
---

A aula 1 usou três palavras com folga; esta fase precisa delas com exatidão, porque as obrigações do plano se
prendem à terceira.

| palavra | definição | na semana |
|---|---|---|
| **evento** | qualquer coisa observável que aconteceu | 382 linhas no `siem.db` |
| **alerta** | um evento, ou padrão de eventos, que uma regra selecionou para uma pessoa | os cinco alertas da aula 4 |
| **incidente** | uma violação, ou ameaça iminente de violação, da política de segurança, de uso aceitável ou das práticas de segurança padrão | o que a aula 7 escalou |

A definição de incidente é a que o NIST usou por anos, e tem duas partes que merecem atenção. **Uma violação
não precisa ter dado certo**: uma ameaça iminente, como uma senha funcionando nas mãos de alguém de fora,
basta. E **ela é medida contra a política**, não contra o dano: um único login de alguém usando a senha de um
colega é um incidente, mesmo que a pessoa não tenha feito nada depois.

A maioria dos eventos nunca vira alerta e a maioria dos alertas nunca vira incidente. O erro de que a
identificação protege vai nos dois sentidos: **um incidente tratado como alerta** é fechado pela triagem e
nunca investigado, e **um alerta tratado como incidente** arrasta uma equipe para uma resposta completa por
causa de um erro de digitação. Os cinco alertas da aula 7 foram para os dois lados em poucos minutos: três
fechados, um virou incidente, um se juntou a ele.
