---
title: Para que serve uma política, e para que não serve
version: 1
---

**Cross-site scripting**, XSS, é o que acontece quando um texto que outra pessoa escolheu acaba numa página como código. Pode ser o nome de um paciente, uma mensagem, um termo de busca, escrito no HTML sem o escape que a aula 4 ensinou e lido pelo navegador como script. A aula 7 trata das três formas que ele
toma. Esta aula trata do que limita o estrago no dia em que o escape falha, porque num código com
centenas de templates, um dia ele falha.

É assim que se deve pensar a **Content Security Policy**: uma **segunda linha**. A primeira linha é
escrever todo valor na página com segurança, para o contexto dele, toda vez. Uma política não
substitui isso e não consegue. O que ela faz é tornar muito menos provável que um escape esquecido vire
um script rodando com a sessão do paciente.

### Um cabeçalho

Uma política é um cabeçalho de resposta que o servidor manda com cada página,
`Content-Security-Policy`, feito de **diretivas** separadas por ponto e vírgula. Cada diretiva nomeia
um tipo de recurso e as origens de onde o navegador pode carregá-lo:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l08-policy\" aria-label=\"Uma Content Security Policy em ação. O cabeçalho script-src 'self' chega ao navegador com a página. Três scripts tentam rodar. Um script carregado de um arquivo do próprio portal, /static/portal.js, roda. Um script escrito dentro da página, seja quem for que o pôs ali, é recusado. Um script de outro host é recusado. Cada recusa é relatada ao /csp-report do portal.\"><defs><marker id=\"l08-policy-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l08-policy-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"16\" width=\"680\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Content-Security-Policy: script-src 'self'</text><text x=\"360\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">o navegador confere cada script com a política</text><rect x=\"20\" y=\"84\" width=\"300\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"170.0\" y=\"98.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">/static/portal.js</text><text x=\"170.0\" y=\"111.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">um arquivo do próprio portal</text><path d=\"M320 105 L460 105\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-policy-ah-phosphor)\"></path><rect x=\"460\" y=\"84\" width=\"240\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"580.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">roda</text><rect x=\"20\" y=\"138\" width=\"300\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"170.0\" y=\"152.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;script&gt; dentro da página</text><text x=\"170.0\" y=\"165.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">seja quem for que o pôs ali</text><path d=\"M320 159 L460 159\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-policy-ah-amber)\"></path><rect x=\"460\" y=\"138\" width=\"240\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"580.0\" y=\"159.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">recusado, relatado</text><rect x=\"20\" y=\"192\" width=\"300\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"170.0\" y=\"206.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">um script de outro host</text><text x=\"170.0\" y=\"219.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">um host fora da política</text><path d=\"M320 213 L460 213\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-policy-ah-amber)\"></path><rect x=\"460\" y=\"192\" width=\"240\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"580.0\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">recusado, relatado</text></svg>", "caption": "A política não distingue script inline bom de ruim, então recusa todos. É esse o preço, e a proteção.", "same": ["/static/portal.js"]}
```

As diretivas que esta aula usa, e o que cada uma diz ao navegador:

| diretiva | o que ela permite |
|---|---|
| `default-src 'self'` | tudo o que não é nomeado abaixo: só da origem do próprio portal |
| `script-src 'self'` | scripts só de arquivos na origem do portal; **nenhum script inline**, nenhum `eval` |
| `object-src 'none'` | nenhum conteúdo de plug-in |
| `base-uri 'none'` | nenhuma tag `<base>`, que mudaria para onde toda URL relativa aponta |
| `frame-ancestors 'none'` | nenhum outro site pode mostrar o portal dentro de um frame |
| `form-action 'self'` | formulários só podem enviar para o portal |
| `report-uri /csp-report` | mandar um relatório de toda violação para este endereço |

A linha que faz o trabalho é `script-src 'self'`. Uma falha de XSS põe script **dentro da página**, e
uma página cuja política só permite scripts carregados dos arquivos do próprio portal não o roda. É
também por isso que ela custa algo: **os scripts inline do próprio portal também param de rodar**, e
os tratadores de evento inline, como `onclick="…"`, também. Cada um precisa ir para um arquivo antes de
a política poder ser aplicada.

### O que ela não faz

- **Não corrige a falha.** O texto que deveria ter sido escapado continua na página, e ainda pode
  estragar o layout ou enganar quem lê. Corrija o escape; a política compra tempo.
- **É tão rígida quanto a diretiva mais fraca.** `'unsafe-inline'` em `script-src` desliga a proteção
  principal, e permitir uma rede de distribuição de conteúdo inteira permite todo script que alguém já
  publicou nela.
- **É aplicada pelo navegador.** Um cliente que não é navegador a ignora. Tudo bem: a política protege
  os navegadores dos pacientes, que é onde o XSS roda.
