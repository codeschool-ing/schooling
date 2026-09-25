---
title: O cron, o jeito mais antigo
version: 1
---

Os timers são o jeito moderno nas distribuições com systemd. O **cron** é mais velho que o próprio Linux,
roda em todo Unix, macOS incluído, e é o que a maioria dos scripts e tutoriais existentes usa.

```
ana@server:~$ crontab -l
no crontab for ana
ana@server:~$ echo '30 18 * * 1-5 df -h / >> /home/ana/disk.log' | crontab -
ana@server:~$ crontab -l
30 18 * * 1-5 df -h / >> /home/ana/disk.log
ana@server:~$ ls /etc/cron.daily
apt-compat
dpkg
```

Cada usuário tem uma **crontab**, uma tabela de comandos agendados. O `crontab -l` a lista, e o
`crontab -e` a abre num editor; aqui uma linha foi mandada por pipe com `crontab -` para o registro
ficar curto.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"Os cinco campos de tempo de uma linha do crontab, 30 18 asterisco asterisco 1-5, seguidos do comando. 30 é o minuto, de 0 a 59. 18 é a hora, de 0 a 23. O asterisco do terceiro campo é qualquer dia do mês. O do quarto é qualquer mês. 1-5 é o dia da semana, segunda a sexta. Lido junto: às 18:30, de segunda a sexta, grava o uso do disco em disk.log.\"><defs><marker id=\"cr-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"96\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"68\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">30</text><text x=\"68\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">minuto</text><text x=\"68\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">0 a 59</text><rect x=\"130\" y=\"20\" width=\"96\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"178\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">18</text><text x=\"178\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">hora</text><text x=\"178\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">0 a 23</text><rect x=\"240\" y=\"20\" width=\"96\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"288\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">*</text><text x=\"288\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">dia do mês</text><text x=\"288\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">qualquer</text><rect x=\"350\" y=\"20\" width=\"96\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"398\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">*</text><text x=\"398\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">mês</text><text x=\"398\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">qualquer</text><rect x=\"460\" y=\"20\" width=\"96\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"508\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">1-5</text><text x=\"508\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">dia da semana</text><text x=\"508\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">segunda a sexta</text><rect x=\"570\" y=\"20\" width=\"130\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"635\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">df -h / &gt;&gt; …</text><text x=\"635\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o comando</text><text x=\"20\" y=\"140\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">às 18:30, de segunda a sexta, grava o uso do disco em disk.log</text></svg>", "caption": "Cinco campos, sempre nesta ordem, e o asterisco quer dizer todos. O dia da semana conta a partir do domingo como 0, e é por isso que os dias úteis são 1-5."}
```

O sistema tem os próprios agendamentos também: arquivos em **`/etc/cron.d`**, e scripts deixados em
**`/etc/cron.daily`**, `weekly` e `monthly`, que rodam uma vez por dia, semana ou mês sem ninguém escrever
um horário. Neste servidor o `apt` e o `dpkg`, as ferramentas da aula 11, mantêm um script cada ali.

| | cron | timer do systemd |
|---|---|---|
| onde | `crontab -e`, `/etc/cron.d` | um `.timer` e um `.service` |
| o log | onde o comando o mandar | o journal, com o nome do serviço |
| uma execução perdida com a máquina desligada | pulada | roda no próximo boot, com `Persistent=true` |
| testar agora | rodar o comando à mão | `systemctl start` no serviço |
| no macOS | sim | não |

**Escolha timers num servidor com systemd** pelo journal e pelo comportamento com execuções perdidas;
**saiba ler crontabs** porque todo servidor herdado tem alguma.
