---
title: Quão cedo, para quem, e o caminho de volta
version: 1
---

"Atualize tudo na hora" e "nunca mexa numa máquina que funciona" estão os dois errados. A resposta
depende do que a atualização muda:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 180\" role=\"img\" aria-label=\"Com que rapidez cada tipo de atualização deve chegar às máquinas de um escritório. Correções de segurança em dias, para toda máquina, automaticamente. Atualizações comuns em uma ou duas semanas, para um grupo piloto antes e depois o resto. Atualizações de recursos em meses, depois de o grupo piloto usar por semanas.\"><defs><marker id=\"rg-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"30\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tipo</text><text x=\"240\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">quão cedo</text><text x=\"410\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">para quem</text><rect x=\"20\" y=\"30\" width=\"680\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">correções de segurança</text><text x=\"240\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">em dias</text><text x=\"410\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">toda máquina, automaticamente</text><rect x=\"20\" y=\"76\" width=\"680\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">atualizações comuns</text><text x=\"240\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">em uma ou duas semanas</text><text x=\"410\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um grupo piloto antes, depois o resto</text><rect x=\"20\" y=\"122\" width=\"680\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">atualizações de recursos</text><text x=\"240\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">em meses</text><text x=\"410\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">depois de o grupo piloto usar por semanas</text></svg>", "caption": "Quanto mais uma atualização muda, mais ela espera e menor é o grupo que a encontra primeiro. As correções de segurança são a exceção que não espera."}
```

O **grupo piloto** são algumas máquinas cujos usuários sabem que vêm primeiro, muitas vezes a da própria
Ana. Se uma atualização de recursos quebra o scanner, quebra uma mesa, e o resto do escritório espera
enquanto se pede um driver ao fabricante.

## Segurando um pacote

Às vezes um programa não pode mudar, por um tempo: o software da contabilidade é certificado numa
versão exata de uma biblioteca até o fornecedor se atualizar. O Linux consegue **segurar** um pacote
enquanto todo o resto se atualiza:

```
ana@server:~$ sudo apt-mark hold cron
cron set on hold.
ana@server:~$ apt-mark showhold
cron
ana@server:~$ sudo apt-mark unhold cron
Canceled hold on cron.
```

Uma retenção é uma **dívida sem data**. Anote por que e até quando, ou o pacote fica para trás por anos e
vira o próximo CVE que ninguém corrigiu.

## Reiniciando

A maioria das atualizações do Linux vale quando o programa reinicia; um **kernel** novo precisa que a
máquina inteira reinicie, o ponto da aula 3. O Ubuntu deixa um arquivo de aviso quando isso é
necessário:

```
ana@server:~$ ls /var/run/reboot-required
ls: cannot access '/var/run/reboot-required': No such file or directory
```

Nenhum arquivo assim, então nenhuma reinicialização está pendente. No Windows, o equivalente é o
*Reinicialização necessária* no Windows Update, e é por isso que o horário ativo existe.

## O caminho de volta

- **Windows**: *Configurações > Windows Update > Histórico de atualizações > Desinstalar atualizações*,
  ou o `wusa` da seção 02; uma atualização de recursos pode ser revertida em até dez dias, em *Sistema >
  Recuperação > Voltar*.
- **Linux**: o `apt install pacote=versão` põe de volta uma versão mais velha enquanto o arquivo ainda a
  tiver, e um snapshot ou backup do disco do servidor é o caminho de volta maior.
- **Qualquer um**: o backup feito antes, do qual a aula 17 depende.
