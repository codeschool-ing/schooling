---
title: Quatro outras respostas para o mesmo problema
version: 1
---

**O Kubernetes não é o único orquestrador, e para muitas equipes não é o melhor.** Cada ferramenta
desta seção responde aos problemas que a lição 1 mediu (cópias em várias máquinas, um endereço na
frente delas, atualizações sem intervalo) e cada uma traça em outro lugar a linha do que você mesmo
opera. Essa linha é o que vale comparar, mais do que qualquer lista de recursos.

## O modo Swarm: o Docker espalhado por máquinas

O modo Swarm vem embutido no Docker Engine. `docker swarm init` transforma uma máquina em
gerenciadora, `docker swarm join` acrescenta outras, e um `compose.yaml` vira uma aplicação rodando
com `docker stack deploy`. Ele mantém uma contagem de réplicas, espalha as cópias pelas máquinas,
publica uma porta em todas elas pelo que chama de routing mesh e atualiza uma cópia de cada vez, com
`--update-order start-first` invertendo a ordem que custou à lição 1 as suas doze requisições.

A força dele é que quase não há nada novo para aprender depois do curso `docker`: o arquivo é o
mesmo arquivo. A fraqueza é o tamanho do que existe em volta. Não há equivalente aos milhares de
aplicações empacotadas, operadores e integrações escritos para o Kubernetes, e a maioria dos
provedores de hospedagem não oferece Swarm gerenciado nenhum.

*Este curso não mostra o Swarm rodando.* O laptop em que ele foi gravado ligou o modo Swarm, mas o
routing mesh nunca respondeu na porta publicada, então não havia uma transcrição honesta para
mostrar.

## Nomad: um binário, e não só containers

O Nomad, da HashiCorp, é um escalonador distribuído como um binário único, que roda como servidor ou
como cliente. Os jobs dele podem ser containers Docker, mas também um executável comum, um programa
Java ou uma máquina virtual, o que importa para uma empresa que ainda tem muito software que nunca
foi posto numa imagem. Ele deixa a descoberta de serviços e os segredos para os irmãos, Consul e
Vault, então uma montagem completa são três produtos e não um.

**A licença dele mudou em 2023**, de uma licença de código aberto para a Business Source License, que
permite a maior parte do uso interno e restringe oferecê-lo como serviço concorrente. Para uma
equipe escolhendo uma base para os próximos dez anos, quem é dono do código faz parte da decisão.

## ECS: o orquestrador do próprio provedor

O Amazon ECS roda containers na AWS com um plano de controle que a AWS opera e pelo qual não cobra.
Você descreve uma *task* (um ou mais containers) e um *service* (quantas tasks, atrás de qual
balanceador), e elas rodam em máquinas virtuais que você administra ou no Fargate, onde não há
máquina nenhuma para você ver. O Cloud Run do Google e o Azure Container Apps são parentes próximos
nas nuvens deles.

O preço dessa comodidade é que a descrição só significa algo naquele provedor. Uma task definition
do ECS não é um arquivo que outra nuvem leia, e mudar de lugar significa reescrevê-la.

## Uma plataforma: entregar uma imagem e parar por aí

Na outra ponta estão as plataformas (Heroku, Fly.io, o Cloud Run no uso mais simples, e muitas
outras) em que você entrega uma imagem ou até o código-fonte, diz quanta memória precisa e recebe um
endereço. Escala, certificados e máquinas são problema delas. Você abre mão do controle da rede, de
onde as coisas rodam e de tudo aquilo em que a plataforma não pensou, e paga por uso a uma taxa
maior do que as máquinas custariam.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Um gráfico com dois eixos. Na horizontal, quanto você mesmo opera, de muito à esquerda a quase nada à direita. Na vertical, com que facilidade a mesma descrição vai para outro lugar. O Kubernetes por conta própria, o modo Swarm e o Nomad ficam em cima, à esquerda. O Kubernetes gerenciado fica em cima, mais à direita. ECS, Cloud Run e Container Apps ficam mais abaixo e à direita, e uma plataforma fica embaixo, à direita.\"><defs><marker id=\"alt-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><path d=\"M80 260 L690 260\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#alt-ah-wire)\"></path><path d=\"M80 260 L80 20\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#alt-ah-wire)\"></path><text x=\"690\" y=\"282\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">você opera menos</text><text x=\"92\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">os arquivos mudam de lugar com mais facilidade</text><rect x=\"110\" y=\"46\" width=\"190\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"205.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Kubernetes por conta própria</text><rect x=\"110\" y=\"96\" width=\"190\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"205.0\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">modo Swarm, Nomad</text><rect x=\"350\" y=\"66\" width=\"190\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"445.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Kubernetes gerenciado</text><rect x=\"400\" y=\"150\" width=\"230\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"515.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">ECS, Cloud Run, Container Apps</text><rect x=\"500\" y=\"206\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">uma plataforma</text></svg>", "caption": "A maioria das ferramentas troca um eixo pelo outro. O Kubernetes é o que aparece duas vezes perto do topo: rodado por você, ou por um provedor, com os mesmos arquivos.", "same": ["ECS, Cloud Run, Container Apps"]}
```

| | quem roda o plano de controle | o que você descreve | onde roda |
|---|---|---|---|
| Kubernetes, por conta própria | você | objetos em YAML (lição 2) | em qualquer lugar, com os mesmos arquivos |
| Kubernetes gerenciado (lição 6) | o provedor | os mesmos objetos | em qualquer provedor que o ofereça |
| modo Swarm | você | um `compose.yaml` | onde o Docker rodar |
| Nomad | você | um arquivo de job em HCL | em qualquer lugar, mais trabalho fora de container |
| ECS, Cloud Run, Container Apps | o provedor | o formato daquele provedor | só naquele provedor |
| uma plataforma | o provedor | uma imagem, um tamanho, um domínio | só naquela plataforma |

**Leia a tabela pelo padrão, não pelas células.** Descendo por ela, você opera menos e consegue se
mover menos. O Kubernetes é incomum por estar nas duas pontas: você pode rodá-lo por conta própria
em quaisquer máquinas, ou deixar que qualquer um dos grandes provedores rode o plano de controle, e
os arquivos que você escreve são os mesmos nos dois casos.
