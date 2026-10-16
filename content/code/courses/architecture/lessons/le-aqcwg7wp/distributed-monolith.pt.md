---
title: O monólito distribuído
version: 1
---

Há um jeito de pagar a conta inteira da seção anterior e não receber nada do que ela compra. **Um
monólito distribuído** é um sistema dividido em serviços que ainda não conseguem mudar, ser implantados
ou falhar de forma independente. Ele tem a latência e as falhas parciais dos serviços e o acoplamento
de um monólito, e é o resultado mais comum de dividir sem nomear uma força.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Quatro serviços em fila, catálogo, pedidos, estoque e pagamentos, ligados por chamadas síncronas em cadeia, todos lendo um banco compartilhado embaixo, e os quatro envolvidos por uma única caixa tracejada com o rótulo implantados juntos no mesmo dia.\"><defs><marker id=\"l2-dmono-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l2-dmono-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"30\" width=\"660\" height=\"110\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"6 4\"></rect><text x=\"46\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">implantados juntos, no mesmo dia</text><rect x=\"50\" y=\"64\" width=\"130\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">catalogue</text><path d=\"M182 92 L208 92\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2-dmono-ah-amber)\"></path><path d=\"M115 122 L115 162\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2-dmono-ah-wire)\"></path><rect x=\"210\" y=\"64\" width=\"130\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"275\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">orders</text><path d=\"M342 92 L368 92\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2-dmono-ah-amber)\"></path><path d=\"M275 122 L275 162\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2-dmono-ah-wire)\"></path><rect x=\"370\" y=\"64\" width=\"130\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"435\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">stock</text><path d=\"M502 92 L528 92\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2-dmono-ah-amber)\"></path><path d=\"M435 122 L435 162\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2-dmono-ah-wire)\"></path><rect x=\"530\" y=\"64\" width=\"130\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">payments</text><path d=\"M595 122 L595 162\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2-dmono-ah-wire)\"></path><rect x=\"50\" y=\"164\" width=\"610\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"355\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um banco compartilhado</text></svg>", "caption": "Um monólito distribuído: os custos de rede dos serviços e o acoplamento de um monólito, ao mesmo tempo. As três marcas dele estão desenhadas aqui, a cadeia, as tabelas compartilhadas e o deploy conjunto."}
```

Ele tem três marcas, e qualquer uma basta para desconfiar:

**São implantados juntos.** Uma mudança em pedidos precisa de uma mudança em estoque, lançada na mesma
hora, numa ordem específica. As equipes mantêm uma planilha de que versões funcionam juntas. A
independência para a qual os serviços existem sumiu.

**Dividem um banco.** O atalho da seção sobre ser dono do dado. Os serviços parecem separados no repositório e estão
colados no esquema.

**Chamam uns aos outros em longas cadeias síncronas.** Uma requisição ao catálogo chama pedidos, que
chama estoque, que chama pagamentos, cada um esperando o próximo. A latência da requisição é a soma da
cadeia, e a disponibilidade é o produto: se cada um de quatro serviços responde 99,9% do tempo, a
cadeia responde no máximo 99,9% elevado à quarta potência, uns 99,6%, o que é quase quatro vezes
o tempo fora do ar de qualquer um deles. A aula 5 faz essa conta e mostra a alternativa à cadeia.

## Como os sistemas chegam aqui

Em geral dividindo por camadas técnicas ou por substantivo, antes de as fronteiras serem conhecidas, e
depois descobrindo que toda funcionalidade atravessa todo serviço. Às vezes dividindo uma bola de lama
direto, sem fazer módulos antes, de modo que os serviços herdam cada dependência emaranhada que o
código tinha. E às vezes compartilhando uma biblioteca de classes de domínio entre todos os serviços,
de modo que uma mudança em `Product` é uma mudança em todos ao mesmo tempo.

## Saindo

A saída é a que a aula 1 descreveu: achar as fronteiras de verdade, e traçá-las. Na prática isso
muitas vezes quer dizer **juntar serviços de novo** onde eles sempre mudam juntos, o que parece andar
para trás e é a correção mais barata disponível. A equipe de engenharia da Segment descreveu ter feito
exatamente isso em 2018, juntando mais de cem serviços de destino de volta em um depois que o custo
operacional de mantê-los separados passou do que a divisão dava.

**Um serviço que não pode ser implantado sozinho não é um serviço.** Esse teste, aplicado com
honestidade a cada linha do diagrama, encontra a maioria dos monólitos distribuídos antes de serem
construídos.
