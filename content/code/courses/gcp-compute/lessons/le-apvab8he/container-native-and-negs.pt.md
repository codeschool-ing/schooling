---
title: Balanceamento nativo de contêiner e NEGs
version: 1
---

O balanceador da seção 03 precisa mandar cada requisição para um pod. Há dois jeitos de ele saber
onde os pods estão, e **a diferença é um salto que costumava estar em toda requisição.**

## O caminho antigo: pelos nós

Um balanceador que só conhece máquinas virtuais manda o tráfego aos **nós**, numa porta que o
Kubernetes abre em todo nó para o Service. O nó então entrega a requisição às regras do
`kube-proxy`, que a repassam a um pod, muitas vezes um pod de **outro nó**. Então uma requisição
atravessava a rede duas vezes, a verificação de saúde testava nós e não pods, e um pod que estava
desligando continuava recebendo tráfego até as regras se atualizarem.

## O caminho novo: direto ao pod

**Um grupo de endpoints de rede, NEG, é uma lista de endereços e portas de pods que o balanceador
usa diretamente como backend.** O GKE mantém a lista em dia conforme os pods sobem e param, e o
balanceador manda cada requisição a um pod, verificando a saúde de pods, não de nós.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Dois caminhos para uma requisição. Em cima, pelos nós: o balanceador manda a requisição ao nó A numa porta do nó, e o kube-proxy do nó A a repassa pela rede para um pod no nó B. Embaixo, nativo de contêiner: o balanceador manda a requisição direto ao endereço do pod no grupo de endpoints de rede.\"><defs><marker id=\"l16n-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"24\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">pelos nós</text><rect x=\"24\" y=\"44\" width=\"130\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"89\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">balanceador</text><rect x=\"220\" y=\"36\" width=\"200\" height=\"60\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"320\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nó A</text><text x=\"320\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">kube-proxy</text><rect x=\"480\" y=\"36\" width=\"216\" height=\"60\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"588\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nó B</text><rect x=\"538\" y=\"58\" width=\"100\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"588\" y=\"73\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">pod</text><path d=\"M156 66 L216 66\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l16n-ah)\"></path><path d=\"M422 74 L534 74\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l16n-ah)\"></path><text x=\"160\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">porta do nó, depois um segundo salto</text><text x=\"24\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">nativo de contêiner, com NEG</text><rect x=\"24\" y=\"186\" width=\"130\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"89\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">balanceador</text><text x=\"588\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um pod no nó B</text><rect x=\"538\" y=\"200\" width=\"100\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"588\" y=\"215\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">pod</text><path d=\"M156 215 L534 215\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l16n-ah)\"></path><text x=\"300\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">direto ao endereço do pod</text></svg>", "caption": "Com nós como backend, uma requisição cai em qualquer nó e é repassada, muitas vezes para outro. Um NEG lista os próprios pods, então o salto some e as verificações de saúde testam pods."}
```

Isso se chama **balanceamento de carga nativo de contêiner**, e num cluster nativo de VPC, que é o
que o GKE cria por padrão e o Autopilot sempre é, o Ingress e o Gateway o usam sem precisar pedir.
Você pode ver isso pedido, ou pedir num Service seu, com uma anotação:

```yaml
metadata:
  annotations:
    cloud.google.com/neg: '{"ingress": true}'
```

Vem da documentação do Google; não foi executado.

## O que isso muda na prática

- **Um salto a menos** em toda requisição, o que é latência menor e nenhum tráfego entre nós criado
  pelo próprio balanceador.
- **As verificações de saúde chegam aos pods.** Um pod que falha na verificação para de receber
  tráfego, mesmo que o nó em que está esteja saudável; com nós como backend, um nó com um pod ruim
  entre bons parecia bem.
- **A prontidão chega ao balanceador.** O GKE acrescenta um readiness gate aos pods, então um pod
  novo só conta como pronto para o Kubernetes quando o balanceador o tem como endpoint saudável.
  Numa publicação gradual, os pods antigos não são removidos antes que os substitutos possam de fato
  ser alcançados de fora.

Esse último ponto é o que importa no dia de uma publicação. Sem ele, uma atualização gradual pode
estar "completa" no Kubernetes enquanto o balanceador ainda não tem nenhum endpoint novo saudável,
e os clientes veem erros no minuto entre uma coisa e outra.

## O que um NEG pede do pod

Um pod atrás de um NEG recebe tráfego do balanceador do Google e das verificações de saúde dele, a
partir das faixas de endereço do próprio Google. O firewall precisa deixar essas faixas alcançarem
a porta dos pods, o que o GKE configura para o Ingress que gerencia; e o pod deve responder ao
caminho de verificação de saúde rápido e com honestidade, porque agora o balanceador acredita nele
sobre aquele único pod.
