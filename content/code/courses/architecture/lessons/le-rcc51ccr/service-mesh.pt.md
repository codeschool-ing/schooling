---
title: A service mesh
version: 1
---

A loja da aula 2 tem um timeout na sua única chamada ao serviço de estoque e repassa um id de
requisição. Com vinte serviços, cada um precisa do mesmo punhado de tarefas de rede: timeouts e
retries, criptografia entre serviços, saber quem está chamando, métricas de cada chamada, e um jeito de
mandar uma pequena fração do tráfego para uma versão nova. Escritas dentro de cada serviço, em cada
linguagem, elas se desencontram. **Uma service mesh tira essas tarefas dos serviços e as põe num proxy
que fica ao lado de cada um.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Dois serviços, cada um num pod com um proxy sidecar ao lado. Os serviços só falam com o próprio proxy por localhost; os dois proxies falam entre si pela rede com TLS mútuo, retries e timeouts. Acima deles, um plano de controle manda configuração e certificados para cada proxy.\"><defs><marker id=\"l3-mesh-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l3-mesh-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"270\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"220\" y=\"24\" width=\"280\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">plano de controle</text><text x=\"360\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">config, certificados, política</text><rect x=\"40\" y=\"110\" width=\"260\" height=\"140\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"54\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pod</text><rect x=\"56\" y=\"150\" width=\"100\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"106\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">shop</text><rect x=\"184\" y=\"150\" width=\"100\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"234\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">proxy</text><text x=\"234\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sidecar</text><path d=\"M158 185 L182 185\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3-mesh-ah-wire)\" marker-start=\"url(#l3-mesh-ah-wire)\"></path><path d=\"M234 148 L234 72\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l3-mesh-ah-phosphor)\"></path><rect x=\"420\" y=\"110\" width=\"260\" height=\"140\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"434\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pod</text><rect x=\"564\" y=\"150\" width=\"100\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"614\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">stock</text><rect x=\"436\" y=\"150\" width=\"100\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"486\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">proxy</text><text x=\"486\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sidecar</text><path d=\"M538 185 L562 185\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3-mesh-ah-wire)\" marker-start=\"url(#l3-mesh-ah-wire)\"></path><path d=\"M486 148 L486 72\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l3-mesh-ah-phosphor)\"></path><path d=\"M286 200 L434 200\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3-mesh-ah-phosphor)\" marker-start=\"url(#l3-mesh-ah-phosphor)\"></path><text x=\"360\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">mTLS, retries, timeouts entre os proxies</text></svg>", "caption": "O plano de dados é um proxy ao lado de cada serviço, carregando todo o tráfego dele. O plano de controle nunca toca uma requisição; ele diz aos proxies o que fazer.", "same": ["pod", "proxy", "sidecar"]}
```

## Dois planos

**O plano de dados** são os proxies. Cada serviço ganha um, implantado junto com ele como *sidecar*, e
cada byte que o serviço manda ou recebe passa por ele. O serviço fala HTTP simples com o próprio proxy
em `localhost`; os proxies falam entre si pela rede, e é neles que acontecem os timeouts, os retries e
a criptografia. O Envoy é o proxy que a maioria das malhas usa; o Linkerd tem o seu, escrito em Rust.

**O plano de controle** nunca toca uma requisição. Ele guarda a configuração, emite os certificados e
empurra os dois para cada proxy: "chamadas ao estoque estouram em dois segundos", "mande 5% do tráfego
para a versão 2 do estoque". Istio e Linkerd são as duas malhas mais conhecidas, e as duas rodam em
Kubernetes.

## O que ela dá

| recurso | o que substitui no código do próprio serviço |
| --- | --- |
| TLS mútuo entre serviços | certificados e TLS configurados em cada serviço, em cada linguagem |
| timeouts, retries, circuit breaking | o código que as aulas 11 e 12 escrevem à mão |
| divisão de tráfego | uma versão nova recebendo uma pequena fração das requisições antes de todas |
| métricas e traces uniformes | instrumentação acrescentada a cada serviço separadamente |
| política | "só a loja pode chamar o estoque", garantido fora do serviço de estoque |

**TLS mútuo** é o recurso que mais justifica uma malha. Cada proxy tem um certificado com o nome do seu
serviço, e os dois lados de cada conexão verificam o do outro, então uma chamada vai criptografada e o
serviço de estoque sabe que quem chama é mesmo a loja, sem nenhum dos dois programas ter uma linha de
código de TLS.

## O que ela custa

Um proxy por serviço é um processo por serviço: mais memória, mais CPU, e **dois saltos a mais em cada
chamada**, saindo pelo proxy de quem chama e entrando pelo de quem é chamado. O plano de controle é mais
um sistema distribuído para instalar, atualizar e entender, e quando uma chamada falha, a falha pode
estar na configuração de um proxy que ninguém da equipe escreveu. Uma malha se paga na escala em que
vinte equipes escreveriam a mesma lógica de retry vinte vezes; para os dois serviços da Quitanda ela
seria mais maquinário do que sistema.

A aula 15 constrói o padrão sidecar à mão no seu laboratório, um proxy ao lado de um serviço numa rede
compartilhada, que é o plano de dados da malha sem o plano de controle.
