---
title: Organização, pastas, projetos e recursos
version: 1
---

**Tudo no Google Cloud fica em algum lugar de uma única árvore, e o lugar decide quem pode mexer e o
que a coisa pode fazer.** Uma máquina virtual, um tópico do Pub/Sub, um bucket: cada um pertence a
exatamente um **projeto**. Um projeto pertence a uma **pasta** ou direto à **organização**, e as
pastas se aninham umas dentro das outras até dez níveis. A organização é a raiz, e há uma por empresa.

O quadro errado que as pessoas trazem de outros lugares é que o projeto é uma pasta no sentido de
arquivo de escritório, um lugar para agrupar coisas por arrumação. **Um projeto é uma fronteira.** Ele
tem as próprias APIs ligadas ou desligadas, as próprias cotas, o próprio vínculo com uma conta de
faturamento, a própria política do IAM, e um nome no endereço de todo recurso. Dois projetos não
dividem nada a não ser que alguém os ligue de propósito, que é o assunto da lição 18. As pastas acima
deles são onde mora a arrumação, e onde as regras são escritas uma vez para muitos projetos.

| nível | o que é | quantos |
|---|---|---|
| organização | a empresa, presa a um domínio como `example.com` | uma por conta do Cloud Identity ou do Workspace |
| pasta | um grupo de projetos, ou de outras pastas | quantas a empresa precisar, até dez de profundidade |
| projeto | a fronteira em que todo recurso mora | centenas, numa empresa de qualquer tamanho |
| recurso | a coisa em si: um tópico, uma rede, uma máquina | quantos as cotas permitirem |

## O que desce pela árvore

Duas coisas são escritas no alto da árvore e **herdadas por tudo abaixo**:

- **As políticas de permissão do IAM.** Um papel concedido numa pasta vale em todo projeto dentro
  dela, e em todo recurso dentro desses. A lição 7 diz como as concessões de níveis diferentes se
  combinam, e por que a resposta é uma união: uma concessão feita mais acima não pode ser retirada
  mais abaixo.
- **As políticas da organização**, as barreiras da lição 4: em que regiões os recursos podem ser
  criados, se chaves de conta de serviço podem existir.

O faturamento **não** desce pela árvore. Todo projeto tem o próprio vínculo com uma conta de
faturamento, o assunto da lição 11, e dois projetos na mesma pasta podem ser pagos por contas
diferentes.

## O ambiente que este curso monta

A empresa deste curso é uma equipe pequena que opera um aplicativo de planejamento, o **planner**,
para os seus clientes. O ambiente dela tem a forma a que a maioria das empresas desse tamanho chega:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l02-estate\" aria-label=\"O ambiente da empresa deste curso, como uma árvore. No topo, a organização example.com. Abaixo dela, três pastas: production, non-production e shared. Sob production, o projeto planner-prod. Sob non-production, planner-staging e planner-dev, o projeto que o laboratório usa, que está destacado. Sob shared, planner-network e planner-logs. Sob planner-dev, dois recursos: o tópico orders e uma rede. Uma seta pelo lado esquerdo diz que as políticas de permissão do IAM e as políticas da organização são herdadas para baixo; uma nota diz que o faturamento é vinculado por projeto e não é herdado.\"><defs><marker id=\"l02-estate-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"290.0\" y=\"18.0\" width=\"220.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"400.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">organização</text><text x=\"400.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">example.com</text><path d=\"M400.0 58.0 L150.0 92.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"80.0\" y=\"92.0\" width=\"140.0\" height=\"36.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"150.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">production</text><path d=\"M400.0 58.0 L400.0 92.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"330.0\" y=\"92.0\" width=\"140.0\" height=\"36.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"400.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">non-production</text><path d=\"M400.0 58.0 L630.0 92.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"560.0\" y=\"92.0\" width=\"140.0\" height=\"36.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"630.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shared</text><path d=\"M150.0 128.0 L150.0 168.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"100.0\" y=\"168.0\" width=\"100.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"150.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">planner-prod</text><path d=\"M400.0 128.0 L335.0 168.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"276.0\" y=\"168.0\" width=\"118.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"335.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">planner-staging</text><path d=\"M400.0 128.0 L475.0 168.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"425.0\" y=\"168.0\" width=\"100.0\" height=\"36.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\"></rect><text x=\"475.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">planner-dev</text><path d=\"M630.0 128.0 L585.0 168.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"526.0\" y=\"168.0\" width=\"118.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"585.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">planner-network</text><path d=\"M630.0 128.0 L680.0 168.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"639.0\" y=\"168.0\" width=\"82.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"680.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">planner-logs</text><text x=\"475.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--phosphor)\">o laboratório</text><path d=\"M475.0 204.0 L430.0 248.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"378.0\" y=\"248.0\" width=\"104.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"430.0\" y=\"263.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">topics/orders</text><path d=\"M475.0 204.0 L540.0 248.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"488.0\" y=\"248.0\" width=\"104.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"263.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">networks/planner</text><text x=\"485.0\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">recursos</text><path d=\"M30.0 40.0 L30.0 290.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" marker-end=\"url(#l02-estate-af-ah-amber)\"></path><text x=\"42.0\" y=\"220.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">herdado para baixo:</text><text x=\"42.0\" y=\"236.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">políticas de permissão do IAM</text><text x=\"42.0\" y=\"252.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">políticas da organização</text><text x=\"42.0\" y=\"290.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">faturamento: por projeto, sem herança</text></svg>", "caption": "Uma árvore por empresa. As regras entram nas pastas e descem para todo projeto."}
```

A produção fica numa pasta só dela, porque uma pasta é onde vão as regras mais rígidas: menos pessoas
com papéis, políticas mais apertadas. Homologação e desenvolvimento dividem uma pasta com regras mais
frouxas. Os projetos que servem a todos, a rede compartilhada da lição 18 e os logs, ficam numa
terceira. O projeto que você usa desde a lição 1, o `planner-dev`, é a folha destacada.

## Nenhuma organização

Uma conta do Google Cloud aberta com um Gmail pessoal **não tem nó de organização**. Os projetos dela
ficam no topo sem nada acima, e quem criou cada um é o dono. Funciona, e custa três coisas que uma
empresa percebe tarde:

- não há onde escrever uma regra uma vez para todo projeto, então cada projeto é configurado à mão;
- os projetos pertencem a uma pessoa, e quando essa pessoa sai, sai junto o único dono;
- não há pastas, então as regras mais rígidas da produção não têm onde morar.

Uma organização aparece quando a empresa verifica o seu domínio no **Cloud Identity** ou no **Google
Workspace**, o assunto da lição 10. Projetos criados sem uma podem ser movidos para baixo dela depois.
Nada nesta seção foi rodado: nenhum emulador responde à hierarquia de recursos, e as duas próximas
seções mostram o que o laboratório consegue dizer sobre ela.
