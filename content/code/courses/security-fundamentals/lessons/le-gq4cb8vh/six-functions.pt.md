---
title: Seis funções
version: 1
---

O **NIST**, o instituto nacional de padrões e tecnologia dos Estados Unidos, publica muita orientação de
segurança, e dois documentos dele são usados muito além dos Estados Unidos. O primeiro é o
**Cybersecurity Framework (CSF)**: uma linguagem comum para o que um programa de segurança deve
alcançar. Ele foi publicado em 2014, revisto em 2018, e a versão atual, o **CSF 2.0**, saiu em fevereiro
de 2024. Usá-lo é voluntário, não custa nada, e ele é pensado para organizações de qualquer tamanho e
setor.

O CSF organiza tudo em **seis funções**:

```schooling-figure
{"svg": "<svg id=\"sf-csf-wheel\" viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"As seis funções do NIST CSF 2.0. Governar fica no centro. Em volta dele, em ordem: identificar, proteger, detectar, responder e recuperar.\"><circle cx=\"360\" cy=\"140\" r=\"50\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></circle><text x=\"360\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">GOVERNAR</text><text x=\"360\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">GV</text><rect x=\"298\" y=\"18\" width=\"124\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"33.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">identificar</text><text x=\"360\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">ID</text><rect x=\"488\" y=\"87\" width=\"124\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"550\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">proteger</text><text x=\"550\" y=\"119.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">PR</text><rect x=\"415\" y=\"199\" width=\"124\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"477\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">detectar</text><text x=\"477\" y=\"231.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">DE</text><rect x=\"181\" y=\"199\" width=\"124\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"243\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">responder</text><text x=\"243\" y=\"231.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">RS</text><rect x=\"108\" y=\"87\" width=\"124\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"170\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">recuperar</text><text x=\"170\" y=\"119.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">RC</text></svg>", "caption": "Governar no meio, dirigindo as cinco que existem desde 2014."}
```

| função | a pergunta que responde | na livraria |
|---|---|---|
| **Governar** (*Govern*) | como as decisões de segurança são tomadas, e quem responde? | o apetite a risco dos sócios, papéis, política (aulas 3, 13) |
| **Identificar** (*Identify*) | o que temos, e quais os riscos a isso? | a lista de ativos e o registro de riscos (aulas 2, 3) |
| **Proteger** (*Protect*) | que salvaguardas impedem que as coisas deem errado? | segmentação, menor privilégio, MFA, backups (aulas 5, 6, 9, 12) |
| **Detectar** (*Detect*) | como percebemos quando algo dá errado? | o log do portal e a regra de detecção (aulas 10, 11) |
| **Responder** (*Respond*) | o que fazemos com um incidente detectado? | revogar a senha vazada, conter, comunicar |
| **Recuperar** (*Recover*) | como voltamos ao normal? | restaurar do backup dentro do RTO (aula 12) |

As cinco primeiras funções existem desde 2014. **Governar** é nova na 2.0, e a figura a põe no meio de
propósito: ela trata de como as outras cinco são dirigidas, por quem e contra qual apetite a risco. Na
versão 1.1 quase tudo isso morava dentro de Identificar, e as organizações continuavam tratando segurança
como assunto técnico da TI. Tirar a governança para uma função própria é o framework dizendo, como faz a
cláusula 5 da ISO 27001, que segurança é responsabilidade da liderança.

### Por que seis funções são úteis

As funções não são passos para fazer em ordem; uma organização faz as seis o tempo todo. O valor delas é
como **checklist de equilíbrio**. A maioria das organizações, deixada sozinha, põe quase todo o esforço em
Proteger, porque é a parte visível e que se compra, e depois descobre durante um incidente que não tinha
como Detectar e nenhum jeito praticado de Recuperar. Dispor as atividades da loja sob as seis funções
mostra as falhas de relance, que é o mesmo uso que a aula 4 fez da tabela de funções de controle.
