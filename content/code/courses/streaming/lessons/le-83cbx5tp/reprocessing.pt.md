---
title: Reprocessando ao lado da versão que roda
version: 1
---

O replay move um grupo existente para trás. **O reprocessamento roda uma versão nova do programa
desde o começo, num grupo novo, enquanto a antiga continua servindo.** A diferença importa quando a
saída é algo que as pessoas estão lendo: voltar o único consumidor para segunda faz a página de
estoque mostrar os números de segunda enquanto durar o atraso. Rodar a versão nova ao lado faz a
página continuar como estava, errada do jeito antigo, até a nova alcançar o fim e ser conferida.

O padrão tem um nome emprestado dos deploys, **blue-green**, e quatro passos:

1. **Inicie a versão nova com um `group.id` novo.** Um grupo novo não tem offsets confirmados, então
   com `auto.offset.reset=earliest` ele lê o tópico desde a mensagem mais antiga. Nada no grupo
   antigo muda.
2. **Dê a ela uma saída própria.** Um tópico novo, `stock.v2`, ou uma tabela nova. Duas versões
   escrevendo no mesmo lugar produzem uma mistura das duas.
3. **Deixe-a alcançar o fim, e compare.** O lag dela chega a zero; a saída concorda com a antiga onde
   a antiga estava certa e difere onde estava o bug.
4. **Mude os leitores, depois aposente a versão antiga** e apague o grupo dela.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Um tópico, sales, lido por dois grupos de consumidores. A versão antiga, grupo stock-count, escreve na saída que as pessoas leem. A versão nova, grupo stock-v2, começa da mensagem mais antiga e escreve numa saída própria. Quando a nova alcança o fim e a saída dela é conferida, os leitores mudam para ela e o grupo antigo é apagado.\" data-fig=\"l16-bluegreen\"><defs><marker id=\"l16-bluegreen-ah-83\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l16-bluegreen-ah-8343\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"85\" width=\"130\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"85\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">sales</text><rect x=\"250\" y=\"30\" width=\"190\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"345\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">versão antiga</text><text x=\"345\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">grupo stock-count</text><rect x=\"250\" y=\"140\" width=\"190\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"345\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">versão nova</text><text x=\"345\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">grupo stock-v2</text><path d=\"M 150 105 L 245 62\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-bluegreen-ah-8343)\"></path><text x=\"195\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no fim</text><path d=\"M 150 125 L 245 168\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-bluegreen-ah-83)\"></path><text x=\"190\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">da mensagem mais antiga</text><rect x=\"500\" y=\"40\" width=\"90\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"545\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">stock</text><rect x=\"500\" y=\"150\" width=\"90\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"545\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">stock.v2</text><path d=\"M 440 60 L 495 60\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-bluegreen-ah-8343)\"></path><path d=\"M 440 170 L 495 170\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-bluegreen-ah-83)\"></path><path d=\"M 545 85 L 545 145\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"560\" y=\"115\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">comparar</text><text x=\"655\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">leitores hoje</text><path d=\"M 625 60 L 595 60\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-bluegreen-ah-8343)\"></path><text x=\"655\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">depois da troca</text><path d=\"M 625 170 L 595 170\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-bluegreen-ah-83)\"></path></svg>", "caption": "Reprocessamento blue-green: a versão nova alcança o fim ao lado da antiga, e os leitores só mudam quando ela alcança.", "same": ["sales"]}
```

## O grupo novo

A seção de mensagens venenosas deixou o `stock-count` com uma mensagem ruim resolvida. Uma segunda
versão do contador, em `stock-v2`, começa do início de `sales`:

```
ubuntu@stream:~/work$ python sturdy_consumer.py --group stock-v2 --dead-letter sales.dlq
```

O cluster agora conhece todos os grupos que esta lição criou, e o novo está no fim do tópico:

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --list
```

Depois que os leitores passaram para a saída nova, o grupo antigo é só um conjunto de offsets
confirmados que ninguém usa. Apagá-lo os remove, então as ferramentas de grupo param de listá-lo e
ninguém retoma dele por engano depois. Um grupo só pode ser apagado quando nenhum membro está
rodando:

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --delete --group stock-count
```

## O que reprocessar custa

**Tudo o que a versão nova escreve fora do Kafka acontece de novo.** O tópico de cartas mortas é o
exemplo diante de você: a versão 2 encontrou a mesma venda ruim e a mandou para `sales.dlq` uma
segunda vez, então o tópico agora tem duas cópias de um mesmo problema. Um e-mail, um pagamento, uma
mensagem a um fornecedor seriam enviados duas vezes do mesmo jeito. Uma versão nova com efeitos
colaterais precisa deles desligados, apontados para uma cópia, ou idempotentes, que é a lição 8 de
novo.

Ele custa também uma leitura completa do tópico, na velocidade que a versão nova conseguir. Ler uma
semana de vendas leva o volume da semana dividido pela taxa do consumidor, e um consumidor que trata
dez vendas por segundo demora bastante numa semana movimentada. Várias instâncias no grupo novo
dividem as partições, até uma por partição, que é a regra da lição 4 e o motivo de o número de
partições ser escolhido pensando em reprocessamento.
