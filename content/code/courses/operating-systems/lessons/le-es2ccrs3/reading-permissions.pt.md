---
title: Lendo a sequência de permissões
version: 1
---

Todo arquivo e pasta no Linux tem **um dono, um grupo e três conjuntos de permissões**. O `ls -l`
mostra tudo:

```
ana@server:/srv/office$ ls -l
total 8
-rw-r--r-- 1 ana ana    9 Sep  1 09:00 payroll.txt
drwxr-xr-x 2 ana ana 4096 Sep  1 09:00 reports
ana@server:/srv/office$ id
uid=1000(ana) gid=1000(ana) groups=1000(ana),27(sudo)
ana@server:/srv/office$ id bruno
uid=1001(bruno) gid=1001(bruno) groups=1001(bruno)
ana@server:/srv/office$ ls -ld /home/ana /home/bruno
drwxr-x--- 6 ana   ana   4096 Sep 25 10:49 /home/ana
drwxr-x--- 2 bruno bruno 4096 Sep 25 10:53 /home/bruno
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"A sequência de permissões do ls -l, -rw-r-----, desmontada. O primeiro caractere é o tipo: um traço para arquivo, d para pasta. Depois, três grupos de três letras. rw- é o que o dono, ana, pode fazer: ler e gravar. r-- é o que o grupo, também chamado ana, pode fazer: ler. --- é o que todos os demais podem fazer: nada. Depois da sequência, o ls -l mostra o dono, ana, o grupo, ana, e o nome, payroll.txt.\"><defs><marker id=\"mo-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"34\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"37.0\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">-</text><text x=\"37.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">tipo</text><text x=\"37.0\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">d = pasta</text><rect x=\"60\" y=\"20\" width=\"64\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"92.0\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">rw-</text><text x=\"92.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">dono</text><text x=\"92.0\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ana</text><rect x=\"130\" y=\"20\" width=\"64\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"162.0\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">r--</text><text x=\"162.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">grupo</text><text x=\"162.0\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ana</text><rect x=\"200\" y=\"20\" width=\"64\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"232.0\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">---</text><text x=\"232.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">outros</text><text x=\"232.0\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">todos os demais</text><rect x=\"310\" y=\"20\" width=\"96\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"358\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">ana</text><text x=\"358\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">dono</text><rect x=\"420\" y=\"20\" width=\"96\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"468\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">ana</text><text x=\"468\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">grupo</text><rect x=\"530\" y=\"20\" width=\"130\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"595\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">payroll.txt</text><text x=\"595\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">nome</text><text x=\"20\" y=\"140\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">r = ler · w = gravar · x = executar um arquivo ou entrar numa pasta</text></svg>", "caption": "Três perguntas, três respostas cada: esta pessoa pode ler, mudar, executar ou entrar? As letras respondem sim, o traço responde não.", "same": ["ana"]}
```

- **O dono** é o usuário que criou o arquivo, aqui a `ana`. As três primeiras letras são dela.
- **O grupo** é um grupo de usuários, aqui também chamado `ana`: o Ubuntu dá a todo usuário um grupo
  particular com o mesmo nome. As três letras do meio valem para os membros dele.
- **Outros** são todos os demais na máquina, e as três últimas letras são deles. O `bruno`, criado para
  esta aula, não pertence a nenhum grupo da ana, como o `id bruno` mostra, então para ele as três
  últimas letras são a resposta inteira.

**O `payroll.txt` começa como `-rw-r--r--`**: a ana pode ler e gravar, e todos os demais podem ler.
Esse último `r` é o motivo de o estagiário conseguir abri-lo.

Vale reparar no último comando. **As pastas pessoais no Ubuntu são `drwxr-x---`**: os outros não têm
permissão nenhuma, então ninguém mais consegue nem olhar dentro de `/home/ana`. Esse é o padrão desde o
Ubuntu 21.04; instalações mais antigas e muitas outras distribuições deixam as pastas pessoais legíveis
por todos.
