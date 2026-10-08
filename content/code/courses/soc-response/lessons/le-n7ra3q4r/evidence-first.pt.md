---
title: Evidência primeiro
version: 1
---

Toda ação de contenção muda o sistema em que toca. Isolar um host encerra as conexões dele; desligar um
servidor esvazia a memória; trocar uma senha reescreve o arquivo que guardava a antiga. **O que uma ação
destrói precisa ser anotado antes da ação**, ou some para sempre. A RFC 3227, a orientação para coleta de
evidência citada desde 2002, dá a ordem: **a ordem de volatilidade**, o que dura menos primeiro.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"A ordem de volatilidade da RFC 3227, da mais volátil para a menos: registradores e cache da CPU; tabelas de rota e ARP, a lista de processos, as conexões abertas e a memória; sistemas de arquivos temporários; disco; logs remotos e dados de monitoramento; backups e arquivos. Colete nessa ordem, porque cada camada dura mais do que a de cima.\"><rect x=\"20\" y=\"10\" width=\"520\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">registradores, cache</text><text x=\"560\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nanossegundos</text><rect x=\"20\" y=\"56\" width=\"520\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">tabelas de rota e ARP, processos, conexões abertas, memória</text><text x=\"560\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">segundos a minutos</text><rect x=\"20\" y=\"102\" width=\"520\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">sistemas de arquivos temporários</text><text x=\"560\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">até reiniciar</text><rect x=\"20\" y=\"148\" width=\"520\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">disco</text><text x=\"560\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">até ser sobrescrito</text><rect x=\"20\" y=\"194\" width=\"520\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">logs remotos, dados de monitoramento</text><text x=\"560\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a política de retenção</text><rect x=\"20\" y=\"240\" width=\"520\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"260\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">backups, arquivos</text><text x=\"560\" y=\"260\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">meses a anos</text></svg>", "caption": "Colete de cima para baixo: o que dura menos vai primeiro."}
```

Numa resposta, as linhas de cima são as que importam, porque nada mais as guarda. Uma lista de processos ou
uma tabela de conexões abertas só existe enquanto a máquina roda; o disco ainda vai estar lá amanhã. Então o
hábito, antes de tocar qualquer host do escopo, é anotar três coisas juntas: **quando** o estado foi lido,
**qual** era, e um **hash** do arquivo que o guarda, para ninguém poder dizer depois que ele foi editado. No
laboratório, uma pasta e quatro comandos:

```
root@soc:~# mkdir ir
root@soc:~# date -Is > ir/when.txt; for h in gw files; do ip netns exec $h ss -tan > ir/$h-ss.txt; done
root@soc:~# cat ir/when.txt ir/files-ss.txt
2026-10-07T20:39:24-03:00
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess
LISTEN 0      128    192.168.20.10:22        0.0.0.0:*          
root@soc:~# sha256sum ir/*
4b985e28ce680289950ee3d9ac852f704843e819af47f5d78351e0b82f0817f4  ir/files-ss.txt
a15d29fb4781dbadf0a64a578fde398d2faafe6a509e7ad075dbd3ac6d0f4faa  ir/gw-ss.txt
fc75ec741d666a9b5c86bb1b9f8d0f248b8410058812bc92dc9501e49f9091f2  ir/when.txt
```

`ss -tan` lista todos os sockets TCP do namespace de rede do host. No `files` só há o `sshd` esperando
conexões, porque nada está conectado ao laboratório agora: o que importa aqui é o hábito, não o conteúdo. Num
servidor de verdade, depois de uma invasão de verdade, o mesmo arquivo listaria o que ainda estivesse
conectado, e seria o único registro disso que vai existir depois que a contenção começar.

O `sha256sum` dá a cada arquivo a sua impressão digital. Copie essas três linhas para o registro do incidente,
`INC-2026-014`, com o nome de quem rodou os comandos. A aula 16 faz a mesma coisa com discos inteiros, e a
aula 17 com a memória, que precisa de ferramentas próprias. Aqui, a regra é só a ordem: **coletar, depois
agir**.

Ela tem um limite. Se dados estão saindo agora, esperar uma hora para gerar a imagem de um servidor é mais uma
hora de dados saindo. Coletar o estado volátil leva um minuto; esse minuto quase sempre compensa, e a hora às
vezes não. Esse julgamento é da líder do incidente, e a última seção desta aula é sobre como ele é feito.
