---
title: Quatro coisas, nesta ordem
version: 1
---

Tudo neste curso até aqui é maquinário. Um **incidente** é o que acontece com as pessoas em volta
dele: algo quebrou, os clientes percebem ou logo vão perceber, e alguém precisa agir com informação
incompleta e o relógio correndo. Ele corre melhor quando o seu formato foi decidido antes, e o formato
tem quatro partes, nesta ordem:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Quatro fases ao longo de um eixo de tempo. Detectar começa na falha e termina quando a primeira pessoa fica sabendo. Decidir vem em seguida e se sobrepõe a comunicar, que vai da primeira mensagem até o fim do incidente, com atualizações num intervalo regular. Registrar vem depois do fim e produz ações.\"><defs><marker id=\"l22p-pa\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M20 180 L700 180\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l22p-pa)\"></path><path d=\"M40 172 L40 188\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"40\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">falha</text><path d=\"M180 172 L180 188\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"180\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">alguém sabe</text><path d=\"M520 172 L520 188\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"520\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fim</text><rect x=\"40\" y=\"30\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"110\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\" font-weight=\"600\">detectar</text><rect x=\"180\" y=\"70\" width=\"340\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\" font-weight=\"600\">decidir</text><rect x=\"190\" y=\"110\" width=\"330\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"260\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">comunicar</text><path d=\"M330 112 L330 138\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M400 112 L400 138\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M470 112 L470 138\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"435\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">atualização</text><rect x=\"540\" y=\"30\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"620\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">registrar</text><text x=\"620\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ações, com responsáveis</text></svg>", "caption": "As quatro partes de um incidente. Detectar termina quando alguém sabe; decidir e comunicar andam lado a lado até o fim; o registro vem depois e termina em mudanças."}
```

1. **Detectar.** Ficar sabendo que algo está errado, de preferência por um alerta (lições 5 e 13), no
   pior caso por um cliente. O tempo entre a falha e a primeira pessoa saber é o primeiro número de
   todo relatório pós-incidente.
2. **Decidir.** Escolher o que fazer: fazer failover, esperar, restaurar, reverter uma release. As três
   perguntas da lição 15 são o centro disso, e um gerenciador de cluster as responde nos casos que
   cobre. As decisões que sobram para uma pessoa são as que ninguém automatizou, e são as difíceis.
3. **Comunicar.** Dizer às pessoas afetadas o que se sabe, o que está sendo feito e quando elas vão
   ter notícias de novo, desde o começo e num intervalo regular, inclusive quando nada mudou.
4. **Registrar**, depois que acabou: o que aconteceu, quando, por quê, e o que muda para que não
   aconteça do mesmo jeito de novo.

Dois papéis evitam que as três primeiras atrapalhem umas às outras, mesmo quando as mesmas duas
pessoas fazem todo o resto. O **líder do incidente** decide e mantém uma nota corrente do que foi feito
e quando; o **comunicador** fala com todo mundo fora da sala. A pessoa digitando comandos no banco não
é nenhum dos dois, se houver gente suficiente: consertar, decidir e explicar ao mesmo tempo é como um
passo acaba pulado.

O resto desta lição executa um incidente no cluster das lições 16 a 19, com o `orders.sh` fazendo o
papel dos clientes, e passa pelas quatro partes com o que ele deixou para trás.
