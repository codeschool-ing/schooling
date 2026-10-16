---
title: Quatro perguntas, respondidas em quatro velocidades
version: 1
---

"O modelo está funcionando?" parece uma pergunta só. **São quatro, e o que as separa é quanto tempo
você espera pela resposta.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l09-four-signals\" aria-label=\"Um eixo de tempo do momento de um pedido até noventa dias depois. Se está respondendo e quão rápido se sabe em segundos; o que está dizendo se sabe na manhã seguinte; se acertou se sabe noventa dias depois, quando os desfechos chegam.\"><path d=\"M250.0 220.0 L700.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M300.0 216.0 L300.0 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"300.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">segundos</text><path d=\"M470.0 216.0 L470.0 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"470.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma noite</text><path d=\"M650.0 216.0 L650.0 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"650.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">90 dias</text><text x=\"20.0\" y=\"23.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">está respondendo?</text><text x=\"20.0\" y=\"39.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">status de cada pedido</text><path d=\"M255.0 30.0 L294.0 30.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><circle cx=\"300.0\" cy=\"30.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"20.0\" y=\"69.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">quão rápido?</text><text x=\"20.0\" y=\"85.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">milissegundos por pedido</text><path d=\"M255.0 76.0 L294.0 76.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><circle cx=\"300.0\" cy=\"76.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"20.0\" y=\"115.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">o que está dizendo?</text><text x=\"20.0\" y=\"131.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">esta noite contra as semanas anteriores</text><path d=\"M255.0 122.0 L464.0 122.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><circle cx=\"470.0\" cy=\"122.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"20.0\" y=\"161.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">acertou?</text><text x=\"20.0\" y=\"177.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">notas contra desfechos</text><path d=\"M255.0 168.0 L644.0 168.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><circle cx=\"650.0\" cy=\"168.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"314.0\" y=\"53.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">o serviço</text><text x=\"484.0\" y=\"145.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">o modelo</text></svg>", "caption": "As duas perguntas que um modelo divide com qualquer serviço têm resposta na hora; as duas dele esperam, e a que mais importa é a que mais espera."}
```

| pergunta | o que responde | quando |
| --- | --- | --- |
| está respondendo? | o status de cada pedido, uma execução que terminou | segundos |
| quão rápido? | o tempo que cada pedido levou | segundos |
| o que está dizendo? | as notas e as entradas desta noite contra as noites anteriores | uma noite |
| acertou? | as notas de uma noite passada contra o que os membros fizeram depois | 90 dias, para este modelo |

**As duas primeiras são as perguntas de qualquer serviço web**, e nada nelas é específico de
aprendizado de máquina: um serviço fora do ar ou lento falha, seja qual for o modelo dentro dele.

**As duas últimas são do próprio modelo.** Um serviço pode responder cada pedido em cinco
milissegundos com status 200 e errar sobre todos os membros, e nenhuma checagem de velocidade ou de
status vai notar. A terceira pergunta pode ser feita na manhã seguinte, porque compara o modelo com
ele mesmo. A quarta é a de verdade, e para o modelo de afastamento ela espera o rótulo: saber se um
membro voltou leva 90 dias, o atraso que a lição 3 desenhou como a maturidade do rótulo.

**Então as checagens que podem rodar cedo ficam no lugar da que não pode.** Se as notas desta noite
não se parecem em nada com as da semana passada, algo mudou, e você descobre três meses antes do que
o boletim teria contado. Esta lição constrói uma checagem para cada linha, e depois pergunta quanto
custa manter cada tipo de implantação rodando.
