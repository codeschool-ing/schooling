---
title: Backups, logs e a cauda longa
version: 1
---

O expurgo apagou 9.826 receitas de `health.prescriptions`. Elas ainda estão em pelo menos três outros
lugares, e um cronograma de retenção que os ignora é um cronograma para uma cópia só.

## Backups

O backup da semana passada guarda toda linha que o expurgo removeu. É para isso que um backup serve, e
ele também é uma cópia de dado expirado. A prática defensável, a mesma da eliminação na aula 7:

- **backups têm retenção própria**, escrita no cronograma: 35 dias de backups diários, por exemplo, e
  nada mais antigo. Passada essa janela, o dado expurgado sumiu de todo lugar;
- **uma restauração reaplica o expurgo.** Restaurar o backup da semana passada traz de volta as linhas
  expiradas da semana passada, então o procedimento de restauração roda o expurgo antes de alguém usar
  o banco restaurado;
- a **recuperação a um ponto no tempo** guarda o log de escrita antecipada (WAL) pela sua janela; a
  retenção dela é a janela, e ela conta como backup.

## Logs

O log do servidor, o da aplicação e o do balanceador de carga guardam fragmentos de dado pessoal: um
e-mail numa mensagem de erro, um CPF numa consulta que falhou, um endereço IP. A aula 4 mostrou um log
bem feito: o audit device do OpenBao escreve um hash com chave (`hmac-sha256:...`) de cada valor
sensível no lugar do valor, então o log prova qual token foi usado sem guardar o token. A maioria dos
logs não é construída assim, e por isso eles têm a retenção mais curta de todas: dias ou semanas, e
não anos.

## Cópias que ninguém listou

O mapa de linhagem da aula 9 terminava nas arestas que nenhuma ferramenta vê: a extração de uma
analista, um CSV mandado por e-mail, um banco de teste. A retenção só os alcança se o mapa os alcançar.
Um expurgo que apaga 950 pedidos do banco e deixa a extração de vendas de 2020 num drive compartilhado
deixou o banco conforme e a empresa nem um pouco mais.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l10-copies\" aria-label=\"Onde uma linha expirada mora. O expurgo a apaga do banco. Os backups a guardam até a retenção deles acabar, e uma restauração precisa rodar o expurgo de novo. Os logs guardam fragmentos dela por dias ou semanas. Extrações e cópias de teste a guardam até alguém achá-las, o que só um mapa de linhagem torna possível.\"><defs><marker id=\"dg-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"80.0\" width=\"130.0\" height=\"60.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">linha expirada</text><text x=\"85.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pedido de 2020</text><rect x=\"230.0\" y=\"20.0\" width=\"200.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"330.0\" y=\"39.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">banco</text><text x=\"450.0\" y=\"39.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o expurgo a apaga</text><path d=\"M150.0 110.0 L228.0 39.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><rect x=\"230.0\" y=\"68.0\" width=\"200.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"330.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">backups</text><text x=\"450.0\" y=\"87.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">até a janela deles acabar</text><path d=\"M150.0 110.0 L228.0 87.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><rect x=\"230.0\" y=\"116.0\" width=\"200.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"330.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">logs</text><text x=\"450.0\" y=\"135.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">fragmentos, dias ou semanas</text><path d=\"M150.0 110.0 L228.0 135.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><rect x=\"230.0\" y=\"164.0\" width=\"200.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"330.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">extrações, cópias de teste</text><text x=\"450.0\" y=\"183.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">até alguém achá-las</text><path d=\"M150.0 110.0 L228.0 183.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path></svg>", "caption": "Um cronograma de retenção cobre toda cópia, ou cobre uma só.", "same": ["backups", "logs"]}
```
