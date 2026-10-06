---
title: Variáveis categóricas
version: 1
---

Uma **variável categórica** coloca cada observação num de vários grupos. A coluna *pagamento* da Horta
é uma: cada pedido caiu em exatamente um entre `pix`, `cartão` e `dinheiro`. *bairro* é outra, com
quatro grupos nestas doze linhas.

Os grupos se chamam **categorias**, ou níveis. O teste para reconhecer uma variável categórica é
simples: o valor responde *qual?* e não *quanto?*

## O que dá para fazer com categorias

Dá para **contar**. Seis pedidos foram pagos por pix, quatro com cartão e dois em dinheiro. Divida
pelos doze pedidos e as contagens viram **proporções**: metade por pix, um terço com cartão e um sexto
em dinheiro.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 520 250\" role=\"img\" data-fig=\"l01-payment-bars\" aria-label=\"Um gráfico de barras de como os doze pedidos foram pagos: pix 6, cartão 4, dinheiro 2. As barras ficam separadas porque as categorias não têm ordem e não há nada entre elas.\"><path d=\"M90.0 40.0 L90.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M86.0 200.0 L90.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"82.0\" y=\"200.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M90.0 177.1 L480.0 177.1\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M86.0 177.1 L90.0 177.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"82.0\" y=\"177.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><path d=\"M90.0 154.3 L480.0 154.3\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M86.0 154.3 L90.0 154.3\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"82.0\" y=\"154.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><path d=\"M90.0 131.4 L480.0 131.4\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M86.0 131.4 L90.0 131.4\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"82.0\" y=\"131.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3</text><path d=\"M90.0 108.6 L480.0 108.6\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M86.0 108.6 L90.0 108.6\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"82.0\" y=\"108.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><path d=\"M90.0 85.7 L480.0 85.7\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M86.0 85.7 L90.0 85.7\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"82.0\" y=\"85.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><path d=\"M90.0 62.9 L480.0 62.9\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M86.0 62.9 L90.0 62.9\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"82.0\" y=\"62.9\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6</text><path d=\"M90.0 40.0 L480.0 40.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M86.0 40.0 L90.0 40.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"82.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">7</text><text x=\"90.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pedidos</text><path d=\"M116.0 200.0 L116.0 62.9 L194.0 62.9 L194.0 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"155.0\" y=\"52.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">6</text><text x=\"155.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pix</text><path d=\"M246.0 200.0 L246.0 108.6 L324.0 108.6 L324.0 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"285.0\" y=\"98.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">4</text><text x=\"285.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cartão</text><path d=\"M376.0 200.0 L376.0 154.3 L454.0 154.3 L454.0 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"415.0\" y=\"144.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">2</text><text x=\"415.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">dinheiro</text><path d=\"M90.0 200.0 L480.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"285.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">como o pedido foi pago</text></svg>", "caption": "Cada barra é uma contagem. Os espaços dizem que não há nada entre duas categorias, e a ordem das barras é uma escolha — aqui, da maior para a menor.", "same": ["pix"]}
```

Dá para dizer qual categoria é a mais comum. Isso se chama **moda**, e a aula 3 dá a ela um lugar
próprio ao lado da média e da mediana. Para *pagamento*, a moda é `pix`.

E a lista quase acaba aí. Não existe forma de pagamento média nem bairro total, porque somar `pix`
com `cartão` não tem significado. Todo resumo de uma variável categórica parte de uma contagem.

## As categorias não podem se sobrepor, e precisam cobrir tudo

Duas propriedades tornam uma variável categórica utilizável, e as duas falham em silêncio quando
ninguém confere.

**Cada observação pertence a uma categoria só.** Se o formulário deixasse o cliente marcar "pix" e
"cartão" no mesmo pedido, as contagens somariam mais que o número de pedidos, e uma proporção de 60%
ao lado de outra de 50% deixaria de significar qualquer coisa.

**Toda observação pertence a alguma categoria.** Uma coluna real quase sempre precisa de um `outro` ou
de um `não registrado`. Sem isso, os pedidos que não cabem em lugar nenhum são empurrados para a
categoria mais próxima, ou descartados, e nos dois casos a contagem fica errada sem nada parecer
errado.

## Uma categoria escrita de dois jeitos são duas categorias

O computador compara valores letra por letra. Se uma pessoa digita `Pix`, outra `pix` e uma terceira
`PIX`, o computador conta três categorias, cada uma menor que a verdade. Barão Geraldo digitado uma
vez com acento e outra sem vira dois bairros.

Esse é o defeito mais comum em dados categóricos reais, e o curso `data-cleaning` trata dele com
calma. Aqui basta conhecer o sintoma: **uma tabela de frequências com mais categorias do que o mundo
tem** é uma tabela que precisa de limpeza antes que alguém a leia.
