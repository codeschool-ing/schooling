---
title: Um base backup e um arquivo: qualquer momento depois dele
version: 1
---

Junte as peças das duas últimas lições. Um base backup é o banco num momento, junto com um bilhete,
o `backup_label`, dizendo em que ponto do log a recuperação tem que começar. O arquivo é todo
segmento do log desde então. Reaplicar o arquivo sobre o base backup pode parar **em qualquer
lugar**: no fim do base backup, no último registro arquivado, ou em qualquer ponto no meio.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Uma linha do tempo. Um base backup tirado no domingo às 02:00, seguido de uma longa fileira de segmentos arquivados até agora. Um colchete sob o trecho todo diz que qualquer momento ali pode ser restaurado. Mais adiante, um segmento aparece faltando, e uma nota diz que a recuperação termina ali, por mais que venha depois.\"><defs><marker id=\"l4t-am\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"75\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">base backup</text><text x=\"75\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">domingo 02:00</text><rect x=\"140\" y=\"50\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"174\" y=\"50\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"208\" y=\"50\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"242\" y=\"50\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"276\" y=\"50\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"310\" y=\"50\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"344\" y=\"50\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"378\" y=\"50\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"412\" y=\"50\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"446\" y=\"50\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"480\" y=\"50\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"514\" y=\"50\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"548\" y=\"50\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"582\" y=\"50\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"616\" y=\"50\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"650\" y=\"50\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"372\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">segmentos arquivados</text><text x=\"702\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">agora</text><path d=\"M20 110 L20 118 L544 118 L544 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"282\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">qualquer momento daqui pode ser restaurado</text><path d=\"M563 84 L563 160\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l4t-am)\"></path><text x=\"563\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">um segmento faltando</text><text x=\"563\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">termina a recuperação aqui</text></svg>", "caption": "Um base backup e o arquivo depois dele. A recuperação pode parar em qualquer momento a partir do fim do backup, desde que a corrente de segmentos não tenha falhas; a primeira lacuna é até onde ela consegue ir.", "same": ["base backup"]}
```

É por isso que o arquivamento é chamado de backup que nunca acaba. O base backup é tirado toda
noite, ou toda semana; o arquivo cresce continuamente no meio; e os momentos restauráveis não são
alguns pontos por dia, mas cada transação confirmada desde o base backup mais antigo guardado até o
último segmento arquivado.

Duas consequências decidem como as peças têm que ser guardadas, e as lições 5, 6 e 7 se apoiam
nas duas:

- **Um base backup sem o seu log é inútil, e o log sem um base backup é inútil.**
  A recuperação parte de um base backup e precisa de todo segmento a partir do ponto de início
  desse backup, sem falhas, até o momento que você quer. Um segmento faltando termina a recuperação
  ali, por mais arquivo que venha depois dele. Por isso o arquivo é guardado a partir do início do
  base backup **mais antigo** do qual você pretende restaurar, e um base backup antigo só é apagado
  junto com os segmentos de que só ele precisava.
- **A restauração demora o quanto demora a reaplicação.** Recuperar até um momento uma semana depois
  do base backup significa reaplicar uma semana de log, o que num banco ocupado são horas. O
  intervalo entre base backups é, portanto, uma decisão sobre tempo de restauração tanto quanto
  sobre armazenamento, e a lição 8 põe um número nele.

O que ainda não está aqui é como parar no momento que você quer, e como dizer ao servidor que
momento é esse. Isso é a lição 6. A lição 5 primeiro entrega os base backups e o arquivo a uma
ferramenta, que os mantém juntos, os verifica e os apaga na ordem certa.
