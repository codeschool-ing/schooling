---
title: Vendo o que as regras decidem
version: 1
---

**Um conjunto de regras que ninguém lê vira um conjunto de regras que ninguém entende.** Todo
firewall cresce: uma exceção para um fornecedor, uma porta para um projeto que acabou, uma regra
copiada de outro servidor. Um ano depois ninguém sabe que regras ainda fazem alguma coisa, e ninguém
se arrisca a apagar uma. Dois hábitos mantêm um firewall de host legível, e os dois são de evidência,
não de memória.

## Contadores

Toda regra desta aula que importa leva `counter`, e de propósito. Um contador responde à primeira
pergunta de uma revisão, **esta regra alguma vez bate?**, sem registrar uma única linha de log. Um
`drop` com o contador subindo é uma regra fazendo o seu trabalho e uma pergunta sobre quem insiste
em tentar. Uma regra com o contador em zero depois de meses ou guarda contra algo que nunca
acontece, ou não casa mais aquilo para que foi escrita, e as duas coisas valem saber.

## Rastreando um pacote

Quando algo é recusado e ninguém sabe que regra fez isso, o nftables consegue seguir um pacote pelo
conjunto de regras. Uma regra põe uma marca, `meta nftrace set 1`, nos pacotes que casa, e o `nft
monitor trace`, rodado como root num segundo shell, imprime as regras por que cada pacote marcado
passa e o veredito em que termina. Insira a regra que marca no topo da chain de saída do `web`,
inicie o monitor num segundo shell no `web` e depois tente a conexão que a política recusa:

```
ana@web:~$ sudo nft insert rule inet web_egress output meta nftrace set 1
ana@web:~$ nc -z -w1 desk 22; echo "exit $?"
exit 1
ana@web:~$ sudo cat /tmp/trace.txt | head -8 | cut -c1-150
trace id b13335e5 inet web_egress output packet: oif "eth0" ip saddr 192.168.60.10 ip daddr 192.168.60.20 ip dscp cs0 ip ecn not-ect ip ttl 64 ip id 3
trace id b13335e5 inet web_egress output rule meta nftrace set 1 (verdict continue)
trace id b13335e5 inet web_egress output rule counter packets 2 bytes 120 comment "web starts nothing else" (verdict continue)
trace id b13335e5 inet web_egress output policy drop 
```

O rastro se lê de cima para baixo: o pacote ao entrar na chain, com os endereços que o identificam,
as duas regras que bateram com ele e o deixaram seguir, e o `policy drop` no fim. Regras com que ele
não bateu não são impressas. O segundo id de rastro é a mesma conexão tentada de novo, o que o TCP
faz quando nenhuma resposta vem. **Essa é a resposta a "que regra bloqueou isto" sem adivinhar**, e é assim que se depura uma lista de
permissões quando um programa legítimo revela precisar de um destino que ninguém anotou.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l10-trace\" aria-label=\"Um pacote do web para a porta 22 do desk descendo a chain web_egress output, como o nft monitor trace a imprime. Primeiro a regra que marca, meta nftrace set 1, veredito continue. Depois as regras de loopback, conexões estabelecidas e DNS, com que ele não bate. Depois o contador, veredito continue. Embaixo, a política da chain, drop.\"><defs><marker id=\"l10-trace-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"140.0\" y=\"30.0\" width=\"380.0\" height=\"28.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"152.0\" y=\"44.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">meta nftrace set 1</text><text x=\"540.0\" y=\"44.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">marca: continue</text><rect x=\"140.0\" y=\"67.0\" width=\"380.0\" height=\"28.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"152.0\" y=\"81.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">oif &quot;lo&quot; accept</text><text x=\"540.0\" y=\"81.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">não bate</text><rect x=\"140.0\" y=\"104.0\" width=\"380.0\" height=\"28.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"152.0\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ct state established,related accept</text><text x=\"540.0\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">não bate</text><rect x=\"140.0\" y=\"141.0\" width=\"380.0\" height=\"28.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"152.0\" y=\"155.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ip daddr 192.168.60.53 udp dport 53 accept</text><text x=\"540.0\" y=\"155.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">não bate</text><rect x=\"140.0\" y=\"178.0\" width=\"380.0\" height=\"28.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"152.0\" y=\"192.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">counter</text><text x=\"540.0\" y=\"192.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">conta: continue</text><rect x=\"140.0\" y=\"215.0\" width=\"380.0\" height=\"28.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"152.0\" y=\"229.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">policy drop</text><text x=\"540.0\" y=\"229.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">o veredito</text><path d=\"M110.0 44.0 L110.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10-trace-dh-ah-paper-dim)\"></path><text x=\"100.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">web para desk:22</text></svg>", "caption": "O trace diz a regra que decidiu, então ninguém precisa adivinhar."}
```

O rastreamento é para uma pergunta, não para todo dia: ele imprime para cada pacote marcado, e num
servidor movimentado isso é uma enxurrada. Apague a regra que marca quando a pergunta tiver resposta.

## Logs

Uma instrução `log` numa regra grava uma linha para cada pacote que casa, no log do kernel. **Neste
laboratório esse log pertence ao seu computador, não aos contêineres**, pelo mesmo motivo da trilha
de auditoria da aula 8: um contêiner não recebe um pedaço do buffer do kernel, então uma regra `log`
no `web` grava linhas que o `web` não consegue ler. Num servidor de verdade, ou na sua própria
máquina virtual fora dos contêineres, `journalctl -k` as mostra. Um drop registrado em log deve ter
limite de taxa, com `limit rate 10/minute` antes do `log`, ou um cliente barulhento enche o disco.

## A revisão

Uma vez por trimestre, alguém lê o conjunto de regras de cada servidor contra o trabalho dele, com
os contadores ao lado. Toda regra precisa de um dono e de um motivo, que um `comment` na regra pode
levar, como duas desta aula levam. Uma regra que ninguém sabe explicar é tirada primeiro em modo de
monitoramento, trocando o veredito dela por um contador por algumas semanas, e apagada quando nada
quebrar.
