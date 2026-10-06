---
title: Três coisas que podem dar errado com a informação
version: 1
---

Quase todo mundo chega à segurança com uma imagem na cabeça: **segurança é guardar segredo.** Uma
porta trancada, uma senha, um arquivo que ninguém mais abre. Essa imagem é um terço do assunto, e
um curso construído sobre ela deixaria de fora a maior parte do que de fato machuca uma
organização.

Pegue a pequena livraria que este curso acompanha. Ela vende on-line em `shop.example.com`, guarda
os pedidos num banco de dados e paga nove pessoas. Pergunte o que pode dar errado com a
informação dela, e as respostas caem em três grupos:

| o que acontece | exemplo na livraria | o que é danificado |
|---|---|---|
| alguém lê o que não devia | um estranho baixa a lista de clientes | **confidencialidade** |
| algo muda quando não devia | um preço cai de R$ 45,90 para R$ 4,59 | **integridade** |
| não está lá quando se precisa | a página da loja para de carregar num sábado | **disponibilidade** |

Essas três palavras são a **tríade CIA**, das iniciais em inglês de *confidentiality*,
*integrity* e *availability*. A sigla não tem nada a ver com agência de inteligência; são as
iniciais de três propriedades que a informação pode ter ou perder. Em português também se diz
tríade CID.

**Confidencialidade** é a informação chegar só a quem deve tê-la. A lista de clientes, os
salários, o contrato com um fornecedor. Ela se perde num vazamento, num notebook roubado, num
funcionário lendo um holerite que não é o dele.

**Integridade** é a informação continuar correta e completa, mudada só por quem pode mudá-la e só
do jeito que essa pessoa quis. Ela se perde por adulteração, mas também por acidente: um script
que arredonda todos os preços, um disco que corrompe um bloco, uma planilha colada na coluna
errada. Integridade vale também para os próprios sistemas. Um servidor cujos programas foram
trocados às escondidas perdeu integridade mesmo que nenhum arquivo de dados tenha mudado.

**Disponibilidade** é a informação e os sistemas estarem utilizáveis quando se precisa deles. Ela
se perde com um servidor que caiu, uma enxurrada de tráfego, um ransomware que cifra o disco ou um
backup que ninguém consegue restaurar.

```schooling-figure
{"svg": "<svg id=\"sf-cia-triad\" viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"A tríade CIA como um triângulo. No alto, confidencialidade: só as pessoas certas leem; o oposto é divulgação, a lista de clientes vazada. Embaixo à esquerda, integridade: continua correta; o oposto é alteração, um preço mudado. Embaixo à direita, disponibilidade: está lá quando precisa; o oposto é destruição ou negação, a loja fora do ar.\"><polygon points=\"360,78 145,236 575,236\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></polygon><text x=\"360\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">informação</text><rect x=\"250\" y=\"14\" width=\"220\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">confidencialidade</text><text x=\"360\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">só as pessoas certas leem</text><text x=\"360\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">perdida por: divulgação</text><rect x=\"20\" y=\"236\" width=\"250\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"145\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">integridade</text><text x=\"145\" y=\"274.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">continua correta e completa</text><text x=\"145\" y=\"292.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">perdida por: alteração</text><rect x=\"450\" y=\"236\" width=\"250\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"575\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">disponibilidade</text><text x=\"575\" y=\"274.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">está lá quando precisa</text><text x=\"575\" y=\"292.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">perdida por: destruição ou negação</text></svg>", "caption": "Cada vértice é uma propriedade e, abaixo dele, o dano que a tira."}
```

A tríade merece o lugar porque transforma uma preocupação vaga numa pergunta com resposta. "A loja
é segura?" não tem resposta. "Qual das três um notebook roubado danificaria, e qual uma queda de
energia danificaria?" tem: o notebook ameaça a confidencialidade, a queda de energia ameaça a
disponibilidade, e nenhum dos dois toca a integridade. A aula 2 constrói o vocabulário de risco em
cima disso, e a aula 3 o usa para decidir o que fazer primeiro.

**Um hábito útil daqui em diante:** sempre que encontrar um controle, pergunte qual das três ele
protege. Uma senha protege a confidencialidade. Um checksum protege a integridade. Um segundo
servidor protege a disponibilidade. Alguns controles protegem mais de uma, e alguns protegem uma à
custa de outra, que é o assunto da seção 05 desta aula.
