---
title: Rótulos de confidencialidade e linhagem
version: 1
---

**Esta seção é ensinada a partir da documentação da Microsoft e não foi executada.**

## Um rótulo diz como tratar o dado, não o que ele é

**Uma classificação descreve conteúdo; um rótulo de confidencialidade declara uma política.** "Esta
coluna guarda números de CPF" é uma classificação. "Confidencial: dados pessoais" é um rótulo, e
significa algo para pessoas e para outras ferramentas: quem pode ver, se pode sair da empresa, como é
exibido. Os rótulos são definidos uma vez para a organização inteira, no lado Microsoft 365 do
Purview da primeira seção, onde já marcam documentos e e-mails.

**O Data Map pode aplicar esses mesmos rótulos aos ativos que varreu, a partir das classificações
deles**: uma regra diz que uma coluna classificada como CPF ganha "Confidencial: dados pessoais", e
toda tabela com uma coluna assim carrega o rótulo no catálogo. A documentação faz disso uma opção que a
organização precisa ligar, e ela depende das licenças de Microsoft 365 da organização, que é o ponto
em que as duas famílias da primeira seção se encontram e onde uma equipe de dados costuma descobrir
que precisa da concordância de alguém do lado do Microsoft 365. O rótulo no catálogo é informação
para quem o consulta; se uma consulta àquela coluna é então recusada ou mascarada é decidido pelo
próprio armazenamento, pelas permissões e pelos recursos de mascaramento dele, não pelo rótulo.

## Linhagem: quem copiou o quê para onde

**Linhagem é o registro de onde vieram os dados de um ativo**: esta tabela Delta foi gravada por
aquele notebook a partir daqueles arquivos Avro, que o Capture gravou a partir daquele event hub. Ela
responde à segunda metade da pergunta com que esta lição abriu, "quem o copiou para lá", e responde à
pergunta que um engenheiro faz antes de mudar qualquer coisa, "o que quebra mais adiante se eu
remover esta coluna".

**O Purview não descobre a linhagem lendo os dados. As ferramentas que movem os dados a informam.**
Os pipelines do Data Factory e do Synapse, depois que a factory ou o workspace é conectado à conta do
Purview, informam o que cada atividade de cópia e cada data flow leu e gravou, como a Microsoft
documenta; o Power BI faz o mesmo para os seus conjuntos de dados e relatórios. Uma varredura
contribui com o que consegue ver das próprias definições de uma fonte, como uma view de banco
construída sobre tabelas. Cada informação acrescenta arestas ao mapa, e o retrato é um grafo das
fontes aos relatórios.

**Um programa seu não informa nada.** O `classify.py` do curso, um script Python numa máquina
virtual, um notebook que grava um arquivo: as saídas deles aparecem no mapa como ativos sem pai, e o
grafo de linhagem tem um buraco exatamente onde fica um passo escrito à mão. O pipeline da Quitanda
tem vários passos assim neste curso, os programas das lições 20, 23 e 24 entre eles, e cada um é um
lugar onde "de onde veio isto" precisa ser respondido de memória. A regra prática é que **a linhagem é
tão completa quanto a parcela da movimentação de dados que passa por ferramentas que a informam**, e
uma equipe que se importa com linhagem move os dados por essas ferramentas, ou acrescenta ela mesma
as arestas que faltam pela interface de programação do Purview.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Um grafo de linhagem. O event hub clicks leva aos arquivos Avro do Capture, uma aresta informada pelo Capture; os arquivos Avro levam a uma tabela Delta de cliques, uma aresta informada por uma atividade de cópia do Data Factory; a tabela Delta leva a um relatório do Power BI, uma aresta informada pelo Power BI. Embaixo, customers.csv, gravado por um script, fica sozinho sem aresta de entrada, porque nada informou de onde ele veio.\" data-fig=\"l25-lineage\"><rect x=\"20\" y=\"50\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">event hub clicks</text><rect x=\"200\" y=\"50\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">arquivos Avro do Capture</text><rect x=\"380\" y=\"50\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">tabela Delta de cliques</text><rect x=\"560\" y=\"50\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">relatório do Power BI</text><line x1=\"162\" y1=\"70\" x2=\"192.0\" y2=\"70.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><polygon points=\"198,70 192.0,73.0 192.0,67.0\" fill=\"var(--amber)\" stroke=\"none\"></polygon><text x=\"180.0\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">Capture</text><line x1=\"342\" y1=\"70\" x2=\"372.0\" y2=\"70.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><polygon points=\"378,70 372.0,73.0 372.0,67.0\" fill=\"var(--amber)\" stroke=\"none\"></polygon><text x=\"360.0\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">cópia do Data Factory</text><line x1=\"522\" y1=\"70\" x2=\"552.0\" y2=\"70.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><polygon points=\"558,70 552.0,73.0 552.0,67.0\" fill=\"var(--amber)\" stroke=\"none\"></polygon><text x=\"540.0\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">Power BI</text><rect x=\"380\" y=\"140\" width=\"140\" height=\"44\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"450\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">customers.csv</text><text x=\"450\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">gravado por um script</text><text x=\"368\" y=\"162\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sem pai: nada o informou</text></svg>", "caption": "A linhagem são as arestas que as ferramentas informam; um passo escrito à mão deixa um ativo sem pai.", "same": ["event hub clicks", "Capture", "Power BI"]}
```
