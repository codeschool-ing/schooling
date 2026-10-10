---
title: A qualidade do jeito como foi feito
version: 1
---

**Qualidade do produto é uma propriedade da coisa; qualidade do processo é uma propriedade de como a
coisa é feita.** As duas estão ligadas, e a ligação é mais fraca do que a maioria dos documentos de
processo dá a entender. É nesse vão que quem testa ganha a vida.

## A aposta da qualidade de processo

A ideia é antiga e vem das fábricas. Se o jeito de fazer algo é sólido, repetível e verificado a cada
passo, as coisas feitas assim saem boas, e não é preciso inspecionar cada uma no fim. W. Edwards Deming
passou a carreira defendendo exatamente isso: **inspecionar no fim não melhora a qualidade**, só separa o
bom do ruim, e o custo do ruim já foi pago. Ponha a qualidade dentro do processo e sobra menos para
separar.

O software adotou a ideia em duas famílias de modelos que você vai ver citadas em anúncios de vaga e
contratos:

- a **ISO 9001**, a norma geral de sistemas de gestão da qualidade em qualquer setor. Uma empresa
  certificada mostrou a um auditor que define seus processos, segue-os, registra que seguiu e os melhora.
  Ela não diz nada específico sobre software.
- o **CMMI**, *Capability Maturity Model Integration*, que nasceu de um trabalho na Carnegie Mellon para o
  Departamento de Defesa dos EUA no fim dos anos 1980. Ele classifica uma organização em cinco níveis de
  maturidade, do **inicial**, em que o sucesso depende de heróis, passando por gerenciado, definido e
  gerenciado quantitativamente, até o **em otimização**, em que o processo é medido e melhorado sem parar.

Dentro de um time, a mesma aposta toma formas menores: uma definição de pronto que toda mudança precisa
cumprir, uma revisão antes de cada merge, uma suíte de testes automatizados que roda a cada mudança, uma
retrospectiva depois de cada sprint. Cada uma é uma afirmação sobre **como** o trabalho é feito, e cada
uma está lá porque o time acredita que trabalhar assim produz menos defeitos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 200\" role=\"img\" data-fig=\"l02-chain\" aria-label=\"Quatro caixas em fila: processo, como é feito; o código, qualidade interna; o produto rodando, qualidade externa; na mão de alguém, qualidade em uso. Setas em cima vão da esquerda para a direita, com o rótulo influencia; setas embaixo vão da direita para a esquerda, com o rótulo depende de. Sob cada caixa está o exemplo do Cine Aurora: revisão antes do merge, a linha age maior que 60, R$ 36,00 para quem tem sessenta, um aposentado cobrado a mais.\"><defs><marker id=\"qa-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"qa-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"14.0\" y=\"60.0\" width=\"140.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"84.0\" y=\"80.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">processo</text><text x=\"84.0\" y=\"95.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">como é feito</text><text x=\"84.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">revisão antes do merge</text><path d=\"M84.0 116.0 L84.0 154.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 3\"></path><rect x=\"186.0\" y=\"60.0\" width=\"140.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"256.0\" y=\"80.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o código</text><text x=\"256.0\" y=\"95.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">qualidade interna</text><text x=\"256.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">age &gt; 60</text><path d=\"M256.0 116.0 L256.0 154.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 3\"></path><path d=\"M157.0 76.0 L183.0 76.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-phosphor)\"></path><path d=\"M183.0 104.0 L157.0 104.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"358.0\" y=\"60.0\" width=\"140.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"428.0\" y=\"80.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o produto rodando</text><text x=\"428.0\" y=\"95.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">qualidade externa</text><text x=\"428.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">R$ 36,00 para sessenta</text><path d=\"M428.0 116.0 L428.0 154.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 3\"></path><path d=\"M329.0 76.0 L355.0 76.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-phosphor)\"></path><path d=\"M355.0 104.0 L329.0 104.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"530.0\" y=\"60.0\" width=\"140.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"80.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">na mão de alguém</text><text x=\"600.0\" y=\"95.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">qualidade em uso</text><text x=\"600.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">um aposentado cobrado a mais</text><path d=\"M600.0 116.0 L600.0 154.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 3\"></path><path d=\"M501.0 76.0 L527.0 76.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-phosphor)\"></path><path d=\"M527.0 104.0 L501.0 104.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><text x=\"170.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">influencia</text><text x=\"170.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">depende de</text></svg>", "caption": "A cadeia que as normas desenham. Cada elo torna o seguinte mais provável de ser bom e não garante nada: a revisão foi feita, e o aposentado foi cobrado a mais mesmo assim."}
```

## Onde a aposta falha

A ligação do processo ao produto vai num sentido só e é probabilística. Um bom processo torna bons
produtos **mais prováveis**. Não os torna certos, e pode ser seguido à perfeição produzindo a coisa
errada toda vez.

O time do Cine Aurora tinha um processo: toda mudança era revisada por um segundo desenvolvedor antes do
merge. A revisão do `tickets.py` aconteceu. O Tomás, o outro desenvolvedor, leu `age > 60`, comparou com
a frase *maiores de 60* e aprovou, porque batia. **O processo foi seguido e o defeito passou**, porque o
processo comparava o código com o requisito, e nada comparava o requisito com o mundo.

Esse é o formato geral de uma falha de processo: cada passo faz o que diz, e nenhum dos passos olha para
a coisa que deu errado. Um certificado na parede, uma auditoria ISO 9001 ou um nível do CMMI, te diz que
os passos existem e são seguidos. Não te diz que são os passos certos.

## Medindo cada um

As duas metades se medem de jeitos diferentes, e confundi-las produz parte do teatro que a aula 22
descreve.

- **Medidas de produto** olham para a coisa: defeitos achados nela, quantos escaparam para clientes, quão
  rápido ela responde, quantos usuários terminam uma compra.
- **Medidas de processo** olham para o trabalho: quantas mudanças foram revisadas, quanto tempo uma
  mudança espera por quem testa, com que frequência a suíte roda, quanto tempo um defeito leva para ser
  corrigido.

Uma medida de processo só vale a pena se estiver ligada a uma medida de produto que importe a alguém.
"Toda mudança foi revisada" é um bom fato; era verdade para `age > 60`. O que a tornaria útil é saber
quantos dos defeitos que os clientes acharam tinham passado por uma revisão, que é uma pergunta que junta
as duas e que pouquíssimos times fazem.

## O que quem testa faz com as duas

Teste o produto, e **questione o processo com o que o produto te diz**. Todo defeito que chega a um
cliente passou por todos os passos do processo; para cada um, vale perguntar que passo poderia tê-lo
pegado e por que não pegou. A resposta às vezes é um teste melhor, e às vezes é uma lista de revisão que
ganha uma linha: *alguma borda do requisito pode ser lida de dois jeitos?* Essa linha é qualidade de
processo, comprada com um defeito, e a aula 18 transforma a pergunta num método.
