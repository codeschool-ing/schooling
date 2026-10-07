---
title: Dois de tudo, e nada compartilhado
version: 1
---

Olhe de novo os pods da seção anterior. No `kind-shop`, `10.244.1.3` no `shop-worker`; no `kind-eu`,
`10.244.1.3` no `eu-worker`. **O mesmo endereço, para dois pods diferentes**, porque os dois clusters
foram criados com a mesma configuração e distribuem a mesma faixa de pods:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Um laptop guarda um arquivo kubeconfig com dois contextos, kind-shop e kind-eu. Cada contexto aponta para o API server do próprio cluster. Os dois clusters têm cada um o próprio control plane, o próprio etcd e os próprios nós, e os dois dão aos pods endereços da mesma faixa, 10.244.0.0/16. Nenhuma linha liga os dois clusters entre si; a única coisa que eles compartilham é o arquivo no laptop.\"><defs><marker id=\"mc-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"mc-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"mc-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"250\" y=\"16\" width=\"220\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"43.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">~/.kube/config</text><text x=\"360.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">kind-shop · kind-eu</text><text x=\"360\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o current-context decide para onde vai um kubectl sem flag</text><rect x=\"40\" y=\"150\" width=\"240\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"160.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">kind-shop</text><text x=\"160.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">control plane, etcd e nós próprios</text><text x=\"160\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">pods: 10.244.0.0/16</text><rect x=\"440\" y=\"150\" width=\"240\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"560.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">kind-eu</text><text x=\"560.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">control plane, etcd e nós próprios</text><text x=\"560\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">pods: 10.244.0.0/16</text><path d=\"M300 88 L160 148\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mc-ah-phosphor)\"></path><path d=\"M420 88 L560 148\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mc-ah-amber)\"></path><path d=\"M290 190 L430 190\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"360\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">nada os liga</text></svg>", "caption": "Dois clusters só se encontram no seu kubeconfig. Cada um tem o próprio API server e os próprios nomes, e aqui até os mesmos endereços de pod."}
```

Dentro de um cluster, qualquer pod alcança qualquer outro pelo endereço, como a lição 18 mostrou. Entre
dois, essa promessa não existe, e com faixas sobrepostas ela não pode ser acrescentada depois sem
renumerar um deles. **Se clusters puderem um dia precisar conversar de pod para pod, dê a cada um a sua
faixa quando ele for criado.** Essa é uma decisão do dia em que o cluster nasce.

Todo o resto é dobrado do mesmo jeito. Cada cluster tem o próprio etcd, então um Deployment chamado
`shop` em cada um são dois objetos sem relação que por acaso têm o mesmo nome. Cada um tem o próprio RBAC,
então ser administrador num não diz nada sobre o outro. Cada um tem o próprio DNS, então
`shop.default.svc` responde só dentro do próprio cluster. E cada um tem a própria versão, atualizada no
próprio dia. **Esse é o motivo de ter dois:** uma mudança ruim, uma atualização quebrada ou um namespace
apagado fica dentro de um deles.

Esse isolamento é o motivo de haver vários clusters mesmo numa empresa pequena. As divisões comuns são
por ambiente (o staging não pode prejudicar a produção), por região (uma falha numa não derruba a outra)
e por confiança (um time que roda código de clientes ganha um cluster que ninguém mais divide). Os
namespaces da lição 20 dividem um cluster entre times; eles compartilham um control plane, um etcd e uma
atualização, e é nessa linha que um segundo cluster começa a valer a pena.
