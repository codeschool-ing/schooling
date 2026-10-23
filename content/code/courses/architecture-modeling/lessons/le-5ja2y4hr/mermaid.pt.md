---
title: "Mermaid: a vida da passagem, como texto"
version: 1
---

**Mermaid é uma sintaxe de texto para diagramas, renderizada por uma biblioteca JavaScript.** O
GitHub, o GitLab e muitos sites de documentação desenham um bloco Mermaid dentro do Markdown sem
ferramenta nenhuma, e essa é a grande vantagem dele: o diagrama mora no README e aparece onde as
pessoas já leem. Para um arquivo próprio, ou para uma verificação num pipeline, o renderizador de
linha de comando `mmdc` faz o mesmo trabalho.

## Instalando o renderizador

Instale-o na pasta `diagrams`, numa versão fixa, para que todos numa equipe renderizem com a mesma:

```
ana@vm:~/diagrams$ npm install --no-audit --no-fund @mermaid-js/mermaid-cli@11.17.0

added 190 packages in 11s
```

A instalação também baixa o navegador headless que o `mmdc` usa para desenhar, que é para onde vai
a maior parte dos 700 MB e a maior parte do tempo.

## A máquina de estados da aula 4, escrita

Salve isto como `ticket.mmd`. É a vida da passagem da aula 4, mais a transição que a tabela de
estados acrescentou:

```
stateDiagram-v2
    direction LR
    [*] --> Held
    Held --> Held : payment declined
    Held --> Paid : payment approved
    Held --> Expired : 10 min pass / release seat
    Paid --> Boarded : scanned at the door
    Paid --> Refunded : cancelled [3 h or more] / refund
    Paid --> NoShow : departed [not scanned]
    Expired --> Expired : payment approved / refund
```

Cada linha depois do cabeçalho é uma transição: origem, `-->`, destino e, depois dos dois-pontos, o
rótulo, que aqui mantém a forma `evento [guarda] / ação` da aula 4 como texto simples. `[*]` é o
pseudoestado inicial. O Mermaid desenha os estados e os posiciona sozinho.

Renderize:

```
ana@vm:~/diagrams$ npx mmdc -i ticket.mmd -o ticket.svg
Generating single mermaid chart
ana@vm:~/diagrams$ ls -l ticket.svg
-rw-rw-r-- 1 ana ana 19293 Oct 23 02:06 ticket.svg
```

Abra `ticket.svg` num navegador. Compare com a figura da aula 4: os mesmos estados e transições,
dispostos pela ferramenta em vez de à mão.

## Quando o texto está errado

Troque a seta da linha *Paid → Boarded* de `-->` para `->`, salve como `broken.mmd` e renderize de
novo:

```
ana@vm:~/diagrams$ npx mmdc -i broken.mmd -o broken.svg 2>&1 | head -5
Generating single mermaid chart

Error: Parse error on line 7:
...lease seat    Paid -> Boarded : scanned
----------------------^
ana@vm:~/diagrams$ npx mmdc -i broken.mmd -o broken.svg > /dev/null 2>&1; echo $?
1
```

O renderizador recusa, aponta a linha, marca o lugar e sai com um código de saída diferente de zero.
**Essa recusa é todo o argumento a favor de diagramas como texto numa equipe**: uma imagem numa
ferramenta de desenho não consegue estar errada de um jeito que uma máquina perceba, e esta
consegue. A seção desta aula sobre o pipeline transforma o código de saída num build que falha.

## Num README

Dentro do Markdown no GitHub ou no GitLab, o mesmo texto vai num bloco cercado cuja info string é
`mermaid`, e o site desenha. Não precisa de renderizador, e o diagrama muda no mesmo pull request
que o código. O custo é que você não consegue verificá-lo no seu pipeline a não ser que também rode
o `mmdc` nele, que é o que a seção sobre o pipeline faz.
