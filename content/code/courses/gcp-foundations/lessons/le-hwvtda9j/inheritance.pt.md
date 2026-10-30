---
title: Como uma política é herdada, mesclada ou substituída
version: 1
---

**Uma política escrita num nó vale para tudo abaixo dele, e um nó mais abaixo pode mudar isso de um de
três jeitos.** O jeito que ele escolhe está escrito na própria política dele, e a resposta num projeto
qualquer se chama **política efetiva**: o resultado de descer da organização até aquele projeto
aplicando a escolha de cada nó, um por vez.

| a política de um nó diz | efeito sobre o que ele herda |
|---|---|
| nada, nenhuma política aqui | vale sem mudança a política efetiva do pai |
| `inherit_from_parent = true` com valores próprios | **mescla**: numa restrição de lista, os valores do pai e os deste nó se combinam |
| uma política própria, sem herdar, que é o padrão | **substitui**: os valores deste nó são a resposta inteira, para ele e tudo abaixo |
| `reset = true` | volta ao **padrão** da restrição, o do próprio Google, como se nenhuma política existisse acima |

## Mesclando listas

Mesclar é onde o raciocínio precisa de cuidado. Pegue o `gcp.resourceLocations` e o ambiente do
planner:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" data-fig=\"l04-merge\" aria-label=\"O valor efetivo de gcp.resourceLocations em três lugares. A organização permite in:southamerica-locations e in:us-locations. A pasta non-production não escreve nada, então os projetos dela herdam os dois. A pasta production escreve uma política própria sem herdar, permitindo só in:southamerica-east1-locations, então os projetos dela só podem usar São Paulo. Uma caixa tracejada mostra o erro: se production herdasse, o valor dela seria somado ao da organização, e a produção poderia usar os Estados Unidos também.\"><rect x=\"220.0\" y=\"16.0\" width=\"280.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"360.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">organização</text><text x=\"360.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">in:southamerica-locations</text><text x=\"360.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">in:us-locations</text><path d=\"M300.0 80.0 L140.0 116.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M420.0 80.0 L560.0 116.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"30.0\" y=\"116.0\" width=\"220.0\" height=\"96.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"140.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">non-production</text><text x=\"140.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nenhuma política própria</text><text x=\"140.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">efetivo:</text><text x=\"140.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">southamerica + us</text><rect x=\"450.0\" y=\"116.0\" width=\"240.0\" height=\"96.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"570.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">production</text><text x=\"570.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">inherit_from_parent = false</text><text x=\"570.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">in:southamerica-east1-locations</text><text x=\"570.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">efetivo: só São Paulo</text><rect x=\"450.0\" y=\"236.0\" width=\"240.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"570.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">se herdasse (true):</text><text x=\"570.0\" y=\"270.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o valor dela soma ao do pai</text><text x=\"570.0\" y=\"288.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">efetivo: southamerica + us</text><text x=\"250.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">numa lista de permissão, herdar amplia</text><text x=\"250.0\" y=\"282.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">numa lista de negação, estreita</text></svg>", "caption": "A produção substitui a lista da organização. Mesclar a teria ampliado."}
```

A organização permite `in:southamerica-locations` e `in:us-locations`: a empresa opera nos dois. A pasta
`production` escreve uma política própria **sem herdar**, permitindo só `southamerica-east1`, porque os
contratos com os clientes dizem que os dados deles ficam no Brasil. Então todo projeto da produção pode
criar recursos em São Paulo e em nenhum outro lugar, enquanto os projetos de `non-production`, que não
escrevem nada, herdam os dois continentes.

Se a produção tivesse escrito o mesmo valor **com** `inherit_from_parent = true`, a resposta teria sido
o oposto da intenção: o valor dela seria somado ao da organização, e a produção poderia criar recursos
nos Estados Unidos. **Numa lista de permissão, herdar amplia.** Numa lista de negação estreita, porque
uma negação mesclada guarda todo valor que algum nível negou. Essa assimetria é tudo o que dá errado com
políticas de lista, e é por isso que uma pasta que quer restringir costuma substituir em vez de mesclar.

## Booleanas, e a resposta mais próxima

Uma restrição booleana não tem o que mesclar. **Vale a política mais próxima**: um projeto que desliga
o `compute.requireOsLogin` sobrepõe uma organização que o ligou. É por isso que o papel de definir
políticas mora na organização e só lá. Se qualquer dono de projeto pudesse escrever a política do
próprio projeto, toda barreira estaria a uma sobreposição de sumir.

## Testar uma política antes de aplicá-la

Uma restrição gerenciada ou personalizada pode levar uma política de **dry run** ao lado da aplicada. Um
dry run não recusa nada; ele escreve no log de auditoria todo pedido que **teria** recusado. Uma semana
desse log é a resposta honesta para "o que quebra se ligarmos isto?", e é a ordem que o Google
recomenda: dry run, ler as violações, corrigir ou isentar o que merecer, e então aplicar.

Nada disso rodou no laboratório: a herança é avaliada pelo serviço de Organization Policy do Google, que
não tem emulador. A próxima seção escreve as duas políticas da figura e faz o Terraform conferi-las.
