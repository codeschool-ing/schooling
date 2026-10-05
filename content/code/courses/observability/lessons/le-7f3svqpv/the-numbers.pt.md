---
title: MTTD, MTTA, MTTR, e o que as médias escondem
version: 1
---

As equipes medem a resposta com uma família de intervalos, cada um o tempo entre dois momentos de um
incidente. A linha do tempo da aula 17 tem todos os momentos, então o incidente dela pode ser medido
com exatidão:

| intervalo | de | até | aula 17 |
|---|---|---|---|
| tempo para detectar | a falha começa | um alerta dispara | 3 min 9 s |
| tempo para reconhecer | o alerta dispara | uma pessoa diz *estou com isto* | 2 s, a declaração fazendo as vezes de reconhecimento |
| tempo para mitigar | a falha começa | os usuários deixam de ser prejudicados | 4 min 12 s, a reversão |
| tempo para resolver | a falha começa | o incidente é encerrado | 9 min 6 s |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"O incidente da aula 17 num eixo de tempo, em segundos desde a versão. Versão em 0, page em 189, incidente declarado em 191, reversão em 252, page resolvido em 309, incidente encerrado em 546. Abaixo do eixo, quatro colchetes: tempo para detectar de 0 a 189, tempo para reconhecer de 189 a 191, tempo para mitigar de 0 a 252, tempo para resolver de 0 a 546.\"><defs><marker id=\"iv-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M170 90 L690 90\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#iv-ah)\"></path><path d=\"M170.0 82 L170.0 98\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"170.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">versão</text><text x=\"170.0\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0 s</text><path d=\"M350.0 82 L350.0 98\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"350.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">page</text><text x=\"350.0\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">189 s</text><path d=\"M351.9047619047619 82 L351.9047619047619 98\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"351.9047619047619\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">declarado</text><text x=\"351.9047619047619\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">191 s</text><path d=\"M410.0 82 L410.0 98\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"410.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">reversão</text><text x=\"410.0\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">252 s</text><path d=\"M464.2857142857143 82 L464.2857142857143 98\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"464.2857142857143\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">page resolvido</text><text x=\"464.2857142857143\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">309 s</text><path d=\"M690.0 82 L690.0 98\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"690.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">encerrado</text><text x=\"690.0\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">546 s</text><rect x=\"170.0\" y=\"145\" width=\"180.0\" height=\"14\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"158\" y=\"152\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tempo para detectar</text><rect x=\"350.0\" y=\"179\" width=\"4\" height=\"14\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"158\" y=\"186\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tempo para reconhecer</text><rect x=\"170.0\" y=\"213\" width=\"240.0\" height=\"14\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"158\" y=\"220\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tempo para mitigar</text><rect x=\"170.0\" y=\"247\" width=\"520.0\" height=\"14\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"158\" y=\"254\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tempo para resolver</text></svg>", "caption": "Os quatro intervalos de um incidente. A detecção foi quase todo o tempo para mitigar, e a janela que se encheu antes do page foi o que o definiu.", "same": ["page"]}
```

O *M* de **MTTD** ou **MTTR** é *mean*, média: a média de um intervalo ao longo de muitos incidentes.
O MTTR é o mais citado, e também é usado para quatro coisas diferentes (restaurar, reparar, responder,
resolver). Então **um relatório deve dizer de que intervalo fala** antes de alguém comparar dois
números.

Cada intervalo aponta para uma correção diferente:

- **Detecção** são os alertas. A da aula 17 foi quase toda a janela de cinco minutos da regra de taxa de
  queima se enchendo, que é o preço de não acionar alguém por picos.
- **Reconhecimento** é a escala e a política de escalonamento.
- **Mitigação** é o runbook e as ferramentas: aqui, uma anotação de deploy que respondeu *o que
  mudou?* e uma reversão que levou um comando.

**A média engana, pelo mesmo motivo que a aula 7 deu para a latência.** Durações de incidentes são
assimétricas: a maioria é curta, e algumas duram uma noite inteira. Uma equipe com nove incidentes de
vinte minutos e um de nove horas tem uma média de cerca de uma hora e quinze, que não descreve nenhum
deles. A mediana e o incidente mais longo do trimestre dizem mais, e a própria lista de incidentes diz
mais ainda.

E um MTTR caindo nem sempre é boa notícia. Ele cai quando uma equipe fica mais rápida, e também cai
quando ela passa a declarar incidentes pequenos que antes ignorava, o que é uma mudança boa que parece
a mesma melhora. **Os números começam uma conversa na revisão; não a terminam.**
