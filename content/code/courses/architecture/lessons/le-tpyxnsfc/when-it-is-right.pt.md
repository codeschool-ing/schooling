---
title: Quando o monólito é a escolha certa
version: 1
---

A ideia errada é que um monólito é o que uma equipe constrói antes de saber das coisas, e que um
sistema sério é feito de serviços. **Para a maioria dos sistemas, na maior parte do tempo, um programa
bem dividido é o projeto mais barato e mais seguro**, e os motivos são concretos.

**Uma equipe.** Um programa em que trabalha uma equipe de até umas dez pessoas não tem com quem se
coordenar além dela mesma. A principal coisa que serviços compram é que equipes separadas possam
implantar separadamente, e uma equipe só não ganha nada por esse preço.

**As fronteiras ainda não são conhecidas.** Um produto novo muda a ideia do que é um pedido, ou de
onde termina o estoque e começa o catálogo, a cada poucas semanas. Dentro de um programa isso é uma
refatoração. Entre serviços é uma mudança em duas APIs e uma migração. O conselho de Martin Fowler em
2015, com o nome *MonolithFirst*, era começar com um monólito e dividir só quando as fronteiras
parassem de se mexer, porque uma divisão na linha errada é pior do que nenhuma.

**Os dados precisam ser consistentes.** A seção anterior mostrou: um banco, uma transação, quatro
mudanças ou nenhuma. Uma loja que nunca pode vender o que não tem ganha isso de graça aqui.

**Latência.** Uma chamada de função leva nanossegundos e uma chamada pela rede leva pelo menos uma
fração de milissegundo, muitas vezes vários. Uma requisição que toca dez partes do sistema paga isso
dez vezes quando as partes são serviços.

**Operação.** Uma coisa para implantar, um log para ler, um processo para analisar, um lugar onde um
erro tem um stack trace que desce até o fim. A aula 2 conta no que essa lista se transforma com cinco
serviços.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Um gráfico com a complexidade do sistema no eixo horizontal e a produtividade da equipe no vertical. A linha do monólito começa alta e cai rápido à medida que a complexidade cresce. A dos microsserviços começa mais baixa, pelo custo de operar muitos serviços, e cai devagar. As linhas se cruzam; à esquerda do cruzamento o monólito é mais produtivo.\"><defs><marker id=\"l1-premium-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"280\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M80 250 L680 250\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1-premium-ah-wire)\"></path><path d=\"M80 250 L80 40\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1-premium-ah-wire)\"></path><text x=\"380\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">complexidade do sistema</text><text x=\"90\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">produtividade</text><path d=\"M90 70 C 250 80, 380 150, 640 236\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M90 150 C 300 152, 450 160, 640 180\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"170\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">monólito</text><text x=\"470\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">microsserviços</text><circle cx=\"430\" cy=\"162\" r=\"5\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></circle><text x=\"430\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o cruzamento</text><text x=\"200\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a maioria dos sistemas vive aqui</text></svg>", "caption": "O formato que Martin Fowler desenhou em 2015 para o custo extra dos microsserviços. Não há números de propósito: onde as linhas se cruzam muda de sistema para sistema, e a maioria nunca chega lá."}
```

Fowler desenhou essa figura em 2015 para dar nome ao **custo extra dos microsserviços** (*microservice
premium*): o custo fixo de rodar um sistema como serviços, pago em implantação, monitoramento e no
tratamento de falhas entre eles, antes de qualquer benefício chegar. Abaixo de certo nível de
complexidade esse custo nunca se paga.

## Sistemas grandes que continuaram um programa só

Isso não é conselho só para sistemas pequenos. A Shopify descreveu no blog de engenharia como mantém a
sua aplicação central de comércio como um grande programa Ruby on Rails, dividido em componentes com
fronteiras garantidas em vez de em serviços. E em 2023 a equipe por trás do monitoramento de streams
do Amazon Prime Video escreveu que levar essa ferramenta de componentes distribuídos separados para um
processo só cortou o custo de infraestrutura dela em mais de 90%, porque os componentes passavam cada
quadro de vídeo uns aos outros através de armazenamento.

**Nenhum dos dois é argumento de que serviços estão errados.** Cada um é evidência de que o formato de
um sistema decorre das forças dele, a equipe, os dados, a carga, e não do tamanho nem do ano.
