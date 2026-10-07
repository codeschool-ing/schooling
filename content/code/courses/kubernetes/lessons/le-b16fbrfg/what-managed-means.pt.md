---
title: O que um provedor assume, e o que deixa com você
version: 1
---

**É fácil ler "gerenciado" como "problema de outra pessoa", e para um cluster Kubernetes isso é meia
verdade.** O provedor assume o plano de controle: o API server, o etcd, o escalonador e o controller
manager, que a lição 4 abre no cluster do laptop. Ele os mantém rodando em máquinas que você nunca
vê, faz backup do etcd e os atualiza quando você pede, ou no calendário dele se você deixar. O que ele
não assume é tudo o que você põe no cluster.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Um cluster gerenciado desenhado como duas áreas. A área do provedor tem o plano de controle: API server, etcd, escalonador e controller manager, com backup e atualização pelo provedor. A sua área tem os nós de trabalho, os pods e os manifestos, o RBAC e as políticas de rede. Um contorno tracejado em volta dos nós diz que eles passam para o lado do provedor com Autopilot, Auto Mode ou Fargate.\"><defs><marker id=\"mg-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"260\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"150\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">do provedor</text><rect x=\"40\" y=\"60\" width=\"220\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">plano de controle</text><text x=\"150.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">API server · etcd</text><rect x=\"40\" y=\"120\" width=\"220\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">scheduler</text><text x=\"150.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">controller-manager</text><rect x=\"300\" y=\"20\" width=\"400\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"500\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">seu</text><rect x=\"320\" y=\"60\" width=\"170\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"405.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">nós de trabalho</text><text x=\"405.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">kubelet · containerd</text><text x=\"405\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">passa para o provedor com</text><text x=\"405\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Autopilot, Auto Mode, Fargate</text><rect x=\"510\" y=\"60\" width=\"170\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">os seus pods e manifestos</text><rect x=\"510\" y=\"110\" width=\"170\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">quem pode fazer o quê (RBAC)</text><rect x=\"510\" y=\"160\" width=\"170\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">qual pod fala com qual</text><path d=\"M320 85 L262 85\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mg-ah-paper-dim)\" marker-start=\"url(#mg-ah-paper-dim)\"></path></svg>", "caption": "Num cluster gerenciado o plano de controle é sempre do provedor. Os nós podem ficar de qualquer lado; as cargas e as regras sobre elas são sempre suas.", "same": ["API server · etcd", "Autopilot, Auto Mode, Fargate", "kubelet · containerd"]}
```

## A linha, desenhada

| | cluster gerenciado, você roda os nós | cluster gerenciado, o provedor roda os nós também |
|---|---|---|
| API server, etcd, escalonador e as atualizações deles | provedor | provedor |
| as máquinas de trabalho, o sistema operacional e as atualizações delas | você | provedor |
| quantos nós, de que tamanho | você, ou um autoscaler que você configura | provedor, a partir do que os seus pods pedem |
| as suas cargas, as imagens e os manifestos delas | você | você |
| quem pode fazer o quê no cluster (lição 23) | você | você |
| qual pod pode falar com qual (lição 24) | você | você |
| a conta de tudo isso | você | você |

A coluna do meio é o arranjo clássico: o plano de controle do provedor e grupos de nós feitos de
máquinas virtuais na sua conta, que você dimensiona, corrige e atualiza. A coluna da direita é mais
nova e tem um nome diferente em cada provedor (**GKE Autopilot**, **EKS Auto Mode**, ou pods no
**Fargate**), e nela você descreve pods e o provedor decide que máquinas os rodam. Você paga pelo
que os pods pedem e não por máquinas inteiras, e abre mão de escolher as máquinas.

## O que não muda, seja qual for a coluna

Duas linhas ficam com você nas duas colunas, e são as duas que causam a maior parte dos incidentes.
**As suas cargas são suas**: uma imagem quebrada, uma sonda faltando, um limite baixo demais falham
num cluster gerenciado exatamente como falham no laptop. **E o acesso também**: o provedor autentica
as pessoas com o próprio sistema de identidade, mas qual delas pode apagar um deployment é escrito
em RBAC, por você.

Um plano de controle gerenciado também tira algumas coisas que você poderia querer. Você não entra
nele, não lê o etcd diretamente como a lição 4 faz, e não instala um componente seu ao lado do API
server. Os pontos de extensão da lição 45 funcionam num cluster gerenciado porque foram feitos para
serem alcançados pela API, e não pela máquina.
