---
title: Agora, e a cada inicialização
version: 1
---

Um serviço tem **dois interruptores**, e confundir os dois é o engano mais comum com serviços.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 180\" role=\"img\" aria-label=\"Dois interruptores separados para um serviço. start e stop agem agora: start o roda, stop o para. enable e disable agem a cada inicialização: enable faz ele iniciar no boot, disable o deixa desligado. São independentes: um serviço pode estar parado agora e ainda habilitado, e então volta no próximo boot. enable --now faz os dois de uma vez.\"><defs><marker id=\"gr-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"44\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">agora</text><text x=\"20\" y=\"104\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a cada inicialização</text><rect x=\"200\" y=\"24\" width=\"230\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"214\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">start</text><text x=\"214\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">roda agora</text><rect x=\"450\" y=\"24\" width=\"230\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"464\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">stop</text><text x=\"464\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">para agora</text><rect x=\"200\" y=\"84\" width=\"230\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"214\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">enable</text><text x=\"214\" y=\"115\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">inicia no boot</text><rect x=\"450\" y=\"84\" width=\"230\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"464\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">disable</text><text x=\"464\" y=\"115\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">deixa desligado no boot</text><text x=\"200\" y=\"160\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">enable --now</text><text x=\"300\" y=\"160\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">faz os dois</text></svg>", "caption": "Parar um serviço não é desligá-lo. O cron foi parado e continuou habilitado, então uma reinicialização o traria de volta; muitas vezes é isso que se quer, e às vezes o contrário."}
```

```
ana@server:~$ sudo systemctl stop cron
ana@server:~$ systemctl is-active cron
inactive
ana@server:~$ systemctl is-enabled cron
enabled
ana@server:~$ sudo systemctl start cron
ana@server:~$ systemctl is-active cron
active
```

Depois do `stop`, o cron ficou **inactive**, e continuou *enabled*. No próximo boot ele iniciaria
de novo. Isso está certo para um teste rápido, e errado para um serviço que deve ficar desligado: aí é
preciso o **`disable`** também, e o `disable --now` faz os dois.

O que inicia no boot é a lista de unidades habilitadas:

```
ana@server:~$ systemctl list-unit-files --type=service --state=enabled --no-pager --no-legend
cron.service                enabled enabled
e2scrub_reap.service        enabled enabled
getty@.service              enabled enabled
networkd-dispatcher.service enabled enabled
systemd-pstore.service      enabled enabled
systemd-resolved.service    enabled enabled
systemd-timesyncd.service   enabled enabled
```

Sete, neste servidor. A mesma lista num notebook que "demora uma eternidade para ligar" é onde procurar
algo de que ninguém precisa, e a aula 16 volta à inicialização quando uma máquina está lenta.

## restart e reload

O **`restart`** para e inicia um serviço, e é o que fazer depois de mudar o arquivo de configuração
dele. O `reload`, onde o serviço aceita, relê a configuração **sem** parar, então as conexões que ele
mantém não caem. Na dúvida, o `restart` é o que sempre funciona.
