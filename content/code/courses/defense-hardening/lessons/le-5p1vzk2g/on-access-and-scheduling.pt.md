---
title: Quando a varredura roda, e o que acontece com o que ela acha
version: 1
---

**Um scanner protege nos momentos em que roda, e a escolha do momento é uma decisão de projeto.** São
três, e um antivírus de desktop faz todos:

| | quando | quanto custa | o que deixa passar |
|---|---|---|---|
| **no acesso** | toda vez que um arquivo é aberto, gravado ou executado | um atraso em cada operação de arquivo | nada do que é tocado, se for rápido o bastante para acompanhar |
| **sob demanda, agendada** | uma varredura completa de noite ou semanal | atividade de disco enquanto dura | tudo entre uma varredura e outra |
| **na entrada** | e-mail, downloads e mídia removível, quando chegam | atraso na entrada | arquivos que chegam por outro caminho |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l07-moments\" aria-label=\"A vida de um arquivo numa estação, da esquerda para a direita, e os três momentos em que um scanner pode olhá-lo. Na entrada, quando chega por e-mail, download ou pendrive. No acesso, toda vez que é aberto, gravado ou executado. No horário, na varredura noturna, alguém tenha tocado nele ou não. Entre varreduras agendadas, um arquivo que ninguém abre só é visto no acesso se for aberto.\"><defs><marker id=\"l07-moments-dh-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><path d=\"M40.0 120.0 L690.0 120.0\" stroke=\"var(--wire)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l07-moments-dh-ah-wire)\"></path><circle cx=\"90.0\" cy=\"120.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"90.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">chega</text><rect x=\"15.0\" y=\"145.0\" width=\"150.0\" height=\"34.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">na entrada</text><path d=\"M90.0 126.0 L90.0 145.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\" fill=\"none\"></path><circle cx=\"300.0\" cy=\"120.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"300.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">aberto, gravado, executado</text><rect x=\"225.0\" y=\"145.0\" width=\"150.0\" height=\"34.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"300.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">no acesso</text><path d=\"M300.0 126.0 L300.0 145.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\" fill=\"none\"></path><circle cx=\"560.0\" cy=\"120.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"560.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">toda noite</text><rect x=\"485.0\" y=\"145.0\" width=\"150.0\" height=\"34.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"560.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">varredura agendada</text><path d=\"M560.0 126.0 L560.0 145.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\" fill=\"none\"></path><text x=\"360.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o laboratório só rodou varreduras sob demanda</text></svg>", "caption": "Cada momento cobre uma lacuna diferente; um produto de desktop usa os três."}
```

## No acesso, e por que o laboratório não consegue mostrar

O scanner de acesso do ClamAV, o `clamonacc`, pede ao kernel que segure cada arquivo aberto até o
scanner olhá-lo. Ele usa o **fanotify**, uma interface do kernel que pertence ao computador inteiro,
então precisa rodar no próprio host, como root, e um contêiner não consegue usá-la. **A varredura no
acesso não foi executada para este curso.** Num computador Linux seu ela é configurada em
`/etc/clamav/clamd.conf`, com `OnAccessIncludePath` citando os diretórios a vigiar e
`OnAccessPrevention yes` fazendo o kernel recusar o acesso a um arquivo que casa, em vez de só
informar.

O Windows faz o mesmo no Microsoft Defender Antivirus, onde se chama **proteção em tempo real** e vem
ligada por padrão; também é assim que a maioria dos produtos comerciais funciona em todas as
plataformas.

## Varreduras agendadas e quarentena

Uma varredura agendada é o `clamscan` ou o `clamdscan` rodado por um timer, exatamente como a aula 3
rodou um playbook. O que importa é o que ela faz com um achado. Mover o arquivo para um diretório de
**quarentena** que só o root lê o tira do alcance sem destruir a evidência:

```
ana@desk:~$ sudo install -d -m 700 /var/quarantine && sudo clamscan --no-summary -r -d lab.ndb --move=/var/quarantine samples/; ls samples; sudo ls /var/quarantine
samples/copy.txt: Jatoba.Lab.Marker.UNOFFICIAL FOUND
samples/copy.txt (real path: '/home/ana/samples/copy.txt'): moved to '/var/quarantine/copy.txt'
samples/changed.txt: Jatoba.Lab.Marker.UNOFFICIAL FOUND
samples/changed.txt (real path: '/home/ana/samples/changed.txt'): moved to '/var/quarantine/changed.txt'
samples/invoice.txt: Jatoba.Lab.Marker.UNOFFICIAL FOUND
samples/invoice.txt (real path: '/home/ana/samples/invoice.txt'): moved to '/var/quarantine/invoice.txt'
changed.txt
copy.txt
invoice.txt
```

O `--move` moveu cada achado e disse para onde. O diretório original ficou vazio, os arquivos estão em
`/var/quarantine` com modo `700`, e uma pessoa pode olhá-los, devolver um que foi falso positivo ou
entregar um a um analista. **Apagar na detecção é a única escolha que não tem volta**, e com
heurísticas no meio, algumas detecções estão erradas.

## O atualizador faz parte do controle

Um scanner só é tão atual quanto a última atualização, e o atualizador é um serviço como outro
qualquer:

```
ana@desk:~$ systemctl is-enabled clamav-freshclam; systemctl is-active clamav-freshclam; grep -E "^(DatabaseMirror|Checks)" /etc/clamav/freshclam.conf
disabled
inactive
Checks 24
DatabaseMirror db.local.clamav.net
DatabaseMirror database.clamav.net
```

No `desk` o serviço está desabilitado e inativo, porque o laboratório não tem rede; ele confere 24
vezes por dia quando roda, contra dois espelhos. Numa máquina de verdade, **um atualizador que parou de
funcionar é um scanner que envelhece em silêncio**, continuando a dizer que está tudo limpo, e uma
verificação de monitoramento sobre a idade do banco de assinaturas pertence ao lado da verificação do
próprio scanner.
