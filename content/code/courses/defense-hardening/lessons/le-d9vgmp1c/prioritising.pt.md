---
title: Decidindo o que vem primeiro
version: 1
---

**A gravidade diz quão ruim uma falha seria. A prioridade diz quão cedo você tem de agir, e precisa de
mais dois fatos.** O primeiro é se alguém está explorando a falha. O segundo é se ela pode ser
alcançada na sua máquina. Os dois estão no feed ou no que você já sabe.

| sinal | o que é | quem publica |
|---|---|---|
| **KEV** | o catálogo Known Exploited Vulnerabilities: falhas com evidência de exploração em ataques reais | a CISA, a agência de cibersegurança dos EUA |
| **EPSS** | o Exploit Prediction Scoring System: a probabilidade, de 0 a 1, de uma falha ser explorada nos próximos 30 dias | o FIRST, que mantém o CVSS |
| **exposição** | se o programa vulnerável é alcançável, aqui, pela rede | você: a varredura da aula 1, o inventário da aula 18 |

KEV e EPSS não foram baixados para este curso; o feed traz valores inventados no formato deles. A
lista KEV de verdade tem pouco mais de mil entradas, contra as centenas de milhares de CVEs já
publicados, e **essa proporção é o argumento para usá-la**: a maioria das falhas nunca é usada por
ninguém, e uma equipe que trata todo 7,5 como urgente passa as semanas nas falhas erradas.

A política do escritório, escrita como código para poder ser lida, discutida e aplicada do mesmo
jeito toda vez:

```schooling-example
{"language": "python", "file": "prioritise.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"prioritise.py FEED FOUND_ON < vulncheck output: rank what applies, and give each a due date.\"\"\"\nimport datetime, json, sys\nfrom cvss import score\n\n# Jatobá's policy, written down: what makes a finding urgent, and how long each level may take.\nEXPOSED = {\"nginx\", \"openssh-server\", \"vsftpd\"}   # listening on web, from the scan in lesson 1\nDAYS = {\"P1\": 7, \"P2\": 30, \"P3\": 60, \"P4\": 90}", "note": "A política vem no topo porque é a parte sobre a qual as pessoas discutem: que pacotes são alcançáveis pela rede, segundo a varredura da aula 1, e quantos dias cada nível recebe."}, {"code": "\ndef level(adv, base):\n    if adv[\"kev\"]:\n        return \"P1\", \"exploited in the wild\"\n    if adv[\"epss\"] >= 0.10:\n        return \"P2\", \"likely to be exploited soon\"\n    if base >= 7.0 and adv[\"package\"] in EXPOSED:\n        return \"P2\", \"severe, and reachable from the network\"\n    if base >= 7.0:\n        return \"P3\", \"severe, not reachable from the network\"\n    return \"P4\", \"the rest\"", "note": "Os níveis, em ordem. Exploração conhecida vence tudo; uma chance alta de exploração vem em seguida; depois a gravidade, pesada por a falha ser ou não alcançável pela rede."}, {"code": "\nfeed = {a[\"id\"]: a for a in json.load(open(sys.argv[1]))}\nfound = datetime.date.fromisoformat(sys.argv[2])\nrows = []\nfor line in sys.stdin:\n    if line.rstrip().endswith(\"VULNERABLE\"):\n        adv = feed[line.split()[0]]\n        base = score(adv[\"cvss\"])\n        lv, why = level(adv, base)\n        rows.append((lv, -base, adv[\"id\"], adv[\"package\"], base, adv[\"epss\"], why))\nfor lv, _, ident, pkg, base, epss, why in sorted(rows):\n    due = found + datetime.timedelta(days=DAYS[lv])\n    print(f\"{lv}  due {due}  {ident}  {pkg:15} cvss {base:4}  epss {epss:5}  {why}\")", "note": "Só as linhas que o `vulncheck.py` marcou como `VULNERABLE` são lidas. A saída é ordenada por nível e depois pela nota, da maior para a menor, e cada linha traz a data limite, contada do dia em que a falha foi encontrada e não do dia em que o relatório foi impresso."}]}
```

Alimente-a com o que o `vulncheck.py` encontrou, com a data em que o achado foi feito:

```
ana@admin:~$ python3 vulncheck.py feed.json web | python3 prioritise.py feed.json 2026-10-23
P1  due 2026-10-30  JTB-2026-02  nginx           cvss  7.5  epss  0.41  exploited in the wild
P2  due 2026-11-22  JTB-2026-01  openssh-server  cvss  8.1  epss  0.02  severe, and reachable from the network
P2  due 2026-11-22  JTB-2026-05  vsftpd          cvss  7.5  epss  0.05  severe, and reachable from the network
P4  due 2027-01-21  JTB-2026-07  libssl3t64      cvss  5.9  epss  0.01  the rest
P4  due 2027-01-21  JTB-2026-04  curl            cvss  4.3  epss 0.003  the rest
```

Leia contra as notas sozinhas. **O nginx vem primeiro embora o OpenSSH tenha nota maior**, porque a
falha do nginx está na lista de exploradas: alguém a está usando agora. OpenSSH e vsftpd vêm em
seguida, os dois graves e os dois escutando na rede. libssl e curl vêm por último; a falha do curl
precisa que um usuário busque algo de um site malicioso, e ninguém navega a partir do portal.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l16-priority\" aria-label=\"As cinco falhas que se aplicam ao web, posicionadas pela nota base do CVSS na horizontal e pelo EPSS, a probabilidade de exploração, na vertical. O nginx fica em 7,5 e 0,41 e está marcado como explorado, prioridade 1. O OpenSSH em 8,1 e 0,02 e o vsftpd em 7,5 e 0,05 são prioridade 2. O libssl em 5,9 e 0,01 e o curl em 4,3 e 0,003 são prioridade 4. A nota mais alta não é a primeira prioridade.\"><path d=\"M90.0 250.0 L660.0 250.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M90.0 250.0 L90.0 40.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"90.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><text x=\"204.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><text x=\"318.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6</text><text x=\"432.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">7</text><text x=\"546.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8</text><text x=\"660.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">9</text><text x=\"80.0\" y=\"250.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.0</text><text x=\"80.0\" y=\"208.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.1</text><text x=\"80.0\" y=\"166.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.2</text><text x=\"80.0\" y=\"124.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.3</text><text x=\"80.0\" y=\"82.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.4</text><text x=\"80.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.5</text><text x=\"375.0\" y=\"282.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nota base do CVSS</text><text x=\"80.0\" y=\"24.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">EPSS</text><circle cx=\"489.0\" cy=\"77.8\" r=\"6\" fill=\"var(--amber)\"></circle><text x=\"499.0\" y=\"63.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">nginx  P1</text><circle cx=\"557.4\" cy=\"241.6\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"567.4\" y=\"227.6\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">openssh-server  P2</text><circle cx=\"489.0\" cy=\"229.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"499.0\" y=\"203.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">vsftpd  P2</text><circle cx=\"306.6\" cy=\"245.8\" r=\"6\" fill=\"var(--paper-dim)\"></circle><text x=\"316.6\" y=\"231.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">libssl3t64  P4</text><circle cx=\"124.2\" cy=\"248.7\" r=\"6\" fill=\"var(--paper-dim)\"></circle><text x=\"134.2\" y=\"234.7\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">curl  P4</text><text x=\"499.0\" y=\"81.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">explorado de fato</text></svg>", "caption": "Prioridade não é a nota mais alta: é a nota, a probabilidade e a exposição juntas.", "same": ["EPSS"]}
```

A linha do vsftpd merece uma segunda olhada. A correção dela é uma atualização de versão, e a correção
melhor é a da aula 1: o portal não precisa de servidor FTP nenhum. **Remover é remediar**, muitas
vezes do jeito mais rápido, e o passo de verificação prova isso do mesmo jeito que um patch:

```
ana@web:~$ sudo apt-get purge -y -q vsftpd 2>&1 | grep -E "^(Removing|Purging)" | cut -d" " -f1,2
Removing vsftpd
Purging configuration
ana@admin:~$ python3 vulncheck.py feed.json web | grep vsftpd
JTB-2026-05  vsftpd          -                            fixed in 3.0.5-0ubuntu3.2           not installed
```

`not installed` é a resposta mais forte que uma avaliação pode dar.
