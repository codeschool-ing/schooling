---
title: O monólito modular
version: 1
---

Um monólito dá errado de um jeito reconhecível. Qualquer função pode chamar qualquer outra, qualquer
consulta pode ler qualquer tabela, e depois de alguns anos cada parte do programa depende de todas as
outras. Brian Foote e Joseph Yoder deram nome ao resultado em 1997: **uma grande bola de lama** (*big
ball of mud*), um sistema sem forma que ninguém consegue mudar sem medo. A conclusão de costume é que
a cura é dividir em serviços. **A bola de lama é uma falha de fronteiras, não de implantação**, e um
programa pode ter fronteiras fortes dentro de um processo só.

Isso é um **monólito modular**: uma unidade implantável, dividida em módulos que são donos de um
pedaço do domínio e dos dados dele, e que só se alcançam por uma superfície pública pequena.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Quatro módulos dentro de um processo, cada um desenhado como uma caixa com uma pequena porta pública na borda. Pedidos alcança estoque e pagamentos pelas portas, em setas contínuas. Uma seta tracejada de pedidos vai direto para a tabela do módulo de estoque e está marcada como proibida.\"><defs><marker id=\"l1-modular-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l1-modular-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"250\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"26\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">um processo, um deploy</text><rect x=\"40\" y=\"60\" width=\"190\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"135\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">pedidos</text><text x=\"135\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">place()</text><rect x=\"300\" y=\"60\" width=\"250\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"440\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">estoque</text><rect x=\"310\" y=\"92\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"370\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">take(sku, n)</text><rect x=\"600\" y=\"72\" width=\"90\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"645\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a tabela dele</text><path d=\"M552 95 L598 95\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"300\" y=\"160\" width=\"250\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"440\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">pagamentos</text><rect x=\"310\" y=\"192\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"370\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">charge(…)</text><path d=\"M232 107 L308 107\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1-modular-ah-phosphor)\"></path><path d=\"M232 207 L308 207\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1-modular-ah-phosphor)\"></path><path d=\"M150 58 C 150 26, 645 22, 645 70\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l1-modular-ah-amber)\"></path><text x=\"400\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">proibido: direto na tabela</text></svg>", "caption": "Um monólito modular continua sendo um deploy só. O que ele acrescenta é uma regra: entra-se num módulo pelas funções públicas dele, nunca pelas tabelas."}
```

O `app.py` da Quitanda já tem os quatro módulos, e já quebra a regra uma vez. `catalogue_list` faz
join de `products` com `stock`, então o catálogo lê uma tabela que pertence ao módulo de estoque.
Funciona, e significa que a tabela de estoque não pode mais mudar de formato sem o catálogo mudar
junto. Num monólito modular o catálogo pede as unidades ao módulo de estoque, por uma função que o
estoque publica, e nunca vê a tabela.

## As três regras

| regra | o que ela impede |
| --- | --- |
| cada módulo é dono das suas tabelas, e só o código dele as lê ou escreve | uma mudança de esquema se espalhando por código que ninguém sabia que dependia dela |
| um módulo só é usado pelas funções que declara públicas | quem chama se acoplar às entranhas dele |
| as dependências entre módulos apontam num sentido só, sem ciclos | dois módulos que só podem mudar juntos, o que é um módulo só |

**Uma regra que ninguém verifica é um hábito, e hábitos se desgastam com prazos.** As regras são
garantidas por uma ferramenta que quebra o build: `import-linter` para Python, ArchUnit para Java, o
sistema de módulos que o Java tem desde a versão 9, `packwerk` para Ruby, os diretórios `internal/`
do Go, que o toolchain do Go não deixa código de fora do diretório pai importar. O repositório onde este curso está
guardado faz a mesma coisa: um teste lê o grafo de imports dos pacotes Go e falha quando um módulo
importa outro que não pode.

## Para que se dar ao trabalho, se é um deploy só

Porque as fronteiras são a parte cara de uma divisão, e saem mais baratas de achar dentro de um
processo. Mover uma fronteira num monólito modular é uma refatoração com um compilador e uma suíte de
testes olhando. Movê-la entre dois serviços é uma mudança em duas implantações, uma API e uma
migração de dados, feita com os dois rodando.

Então um monólito modular é duas coisas ao mesmo tempo: um bom formato para ficar, e o melhor ponto
de partida se chegar o dia de dividir. **Um módulo que já é dono dos seus dados e tem uma superfície
pública é um serviço esperando uma rede**, e a aula 15 mostra como tirar um de um sistema em
funcionamento. Uma bola de lama primeiro precisa virar módulos, e isso é a maior parte do trabalho.
