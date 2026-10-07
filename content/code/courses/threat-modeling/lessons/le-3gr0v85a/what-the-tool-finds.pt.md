---
title: O que a ferramenta acha
version: 1
---

O pytm lê o modelo da aula 2 e aplica a ele a sua própria biblioteca de ameaças: perto de cem
regras, cada uma uma condição sobre os fatos que o modelo declara, a maioria tirada do CAPEC, o
catálogo de padrões de ataque da MITRE. É justo perguntar por que a equipe passou uma tarde em
catorze ameaças quando um programa produz uma lista em um segundo. Esta seção roda o programa e
responde.

### Rode

O `findings.py` lê o JSON que `model.py --json` escreve. Com um argumento, conta os achados por
elemento; com o nome de um elemento, lista os achados dele, opcionalmente só os primeiros:

```schooling-example
{"language": "python", "file": "findings.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Summarise what pytm found: where the findings landed, or the list for one element.\"\"\"\nimport collections\nimport json\nimport sys\n\nfindings = json.load(open(sys.argv[1]))[\"findings\"]\n", "note": "O JSON que o pytm escreve tem uma lista `findings`: uma entrada por regra que disparou, com o elemento em que disparou."}, {"code": "if len(sys.argv) == 2:\n    print(f\"{len(findings)} findings on {len({f['target'] for f in findings})} elements\")\n    for target, n in collections.Counter(f[\"target\"] for f in findings).most_common():\n        print(f\"  {n:3}  {target}\")", "note": "Só com o arquivo, conta os achados por elemento, do maior para o menor."}, {"code": "else:\n    mine = [f for f in findings if f[\"target\"] == sys.argv[2]]\n    show = int(sys.argv[3]) if len(sys.argv) > 3 else len(mine)\n    for f in mine[:show]:\n        print(f\"  {f['threat_id']:6} {f['severity']:9} {f['description']}\")\n    if show < len(mine):\n        print(f\"  ... and {len(mine) - show} more\")", "note": "Com o nome de um elemento, lista os achados dele: o id da regra, a severidade que o pytm atribui e a descrição. Um terceiro argumento mostra só os primeiros."}]}
```

```
(.venv) ana@vm:~/tm/portal-model$ python3 model.py --json model.json
(.venv) ana@vm:~/tm/portal-model$ python3 findings.py model.json
196 findings on 17 elements
   47  Portal
   47  Staff console
   34  Reminder worker
    5  Sign in and book
    5  Pages and booking status
    5  Upload exam PDF
    5  Store exam PDF
    5  Read and write bookings
    5  Charge for a session
    5  Payment webhook
    5  Manage the agenda
    5  Read and write records
    5  Open exam PDF
    5  Read tomorrow's bookings
    5  Send reminder
    4  Records database
    4  Exam files
```

**196 achados.** Os três processos levam 128, cada fluxo leva exatamente cinco, e as quatro
entidades externas não levam nenhum.

```
(.venv) ana@vm:~/tm/portal-model$ python3 findings.py model.json 'Staff console' 12
  INP03  High      Server Side Include (SSI) Injection
  CR01   High      Session Sidejacking
  INP05  Very High Command Line Execution through SQL Injection
  AA01   Medium    Authentication Abuse/ByPass
  DS01   Medium    Excavation
  DE02   Medium    Double Encoding
  AC01   Medium    Privilege Abuse
  DO01   Medium    Flooding
  HA01   Very High Path Traversal
  DO02   Medium    Excessive Allocation
  INP08  High      Format String Injection
  INP09  High      LDAP Injection
  ... and 35 more
```

O portal e o console da equipe recebem os mesmos 47, porque o modelo os descreve do mesmo jeito:
dois servidores na nuvem, guardando sessões, respondendo HTTPS. A ferramenta não tem como saber
que um atende pacientes e o outro lê o prontuário de todos os pacientes, porque nada no modelo diz
isso. Mais abaixo na lista do console:

```
(.venv) ana@vm:~/tm/portal-model$ python3 findings.py model.json 'Staff console' | grep -i php
  INP16  High      PHP Remote File Inclusion
```

Não existe PHP em lugar nenhum da Vereda. A regra dispara porque nada no modelo diz o contrário.

```
(.venv) ana@vm:~/tm/portal-model$ python3 findings.py model.json 'Payment webhook'
  DE01   Medium    Interception
  AC05   Medium    Content Spoofing
  DE03   Medium    Sniffing Attacks
  CR06   High      Communication Channel Manipulation
  CR08   Medium    Client-Server Protocol Manipulation
```

Dos cinco no webhook, **Content Spoofing** é o que chega mais perto da T01. Ele dispara por causa
dos fatos que o modelo declara sobre o fluxo: nada diz que ele é cifrado, e nada diz que o portal
autentica a origem. É uma regra casando com atributos ausentes, e não alguém percebendo que um
desconhecido consegue marcar um agendamento como pago, e ela dispararia do mesmo jeito num fluxo
onde a consequência fosse trivial.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l03-tool-and-hand\" aria-label=\"Onde os achados caem, por tipo de elemento. Os 196 achados do pytm: 128 nos três processos, 60 nos doze fluxos, 8 nos dois repositórios e nenhum nas entidades externas. As 14 ameaças escritas à mão: 2 em processos, 10 em fluxos, 1 num repositório e 1 numa entidade externa.\"><text x=\"190.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">pytm: 196 achados</text><text x=\"140.0\" y=\"62.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">processos</text><rect x=\"150.0\" y=\"48.0\" width=\"200.0\" height=\"28.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"150.0\" y=\"48.0\" width=\"130.6\" height=\"28.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"286.6\" y=\"62.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">128  (65%)</text><text x=\"140.0\" y=\"110.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">fluxos de dados</text><rect x=\"150.0\" y=\"96.0\" width=\"200.0\" height=\"28.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"150.0\" y=\"96.0\" width=\"61.2\" height=\"28.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"217.2\" y=\"110.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">60  (31%)</text><text x=\"140.0\" y=\"158.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">repositórios</text><rect x=\"150.0\" y=\"144.0\" width=\"200.0\" height=\"28.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"150.0\" y=\"144.0\" width=\"8.2\" height=\"28.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"164.2\" y=\"158.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">8  (4%)</text><text x=\"140.0\" y=\"206.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">entidades externas</text><rect x=\"150.0\" y=\"192.0\" width=\"200.0\" height=\"28.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"156.0\" y=\"206.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">0  (0%)</text><text x=\"550.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">à mão: 14 ameaças</text><text x=\"500.0\" y=\"62.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">processos</text><rect x=\"510.0\" y=\"48.0\" width=\"200.0\" height=\"28.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"510.0\" y=\"48.0\" width=\"28.6\" height=\"28.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"544.6\" y=\"62.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">2  (14%)</text><text x=\"500.0\" y=\"110.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">fluxos de dados</text><rect x=\"510.0\" y=\"96.0\" width=\"200.0\" height=\"28.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"510.0\" y=\"96.0\" width=\"142.9\" height=\"28.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"658.9\" y=\"110.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">10  (71%)</text><text x=\"500.0\" y=\"158.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">repositórios</text><rect x=\"510.0\" y=\"144.0\" width=\"200.0\" height=\"28.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"510.0\" y=\"144.0\" width=\"14.3\" height=\"28.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"530.3\" y=\"158.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">1  (7%)</text><text x=\"500.0\" y=\"206.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">entidades externas</text><rect x=\"510.0\" y=\"192.0\" width=\"200.0\" height=\"28.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"510.0\" y=\"192.0\" width=\"14.3\" height=\"28.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"530.3\" y=\"206.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">1  (7%)</text></svg>", "caption": "As duas listas são sobre o mesmo desenho. A ferramenta conta o que cada elemento poderia sofrer; as pessoas contaram onde a confiança muda."}
```

### O que a ferramenta não enxerga

Três das catorze ameaças escritas à mão dependem de fatos que o modelo não contém, e nenhuma regra
consegue achá-las:

- **T12, o console na internet.** O modelo põe o console na nuvem da Vereda, como projetado. A
  ferramenta acredita no desenho.
- **T13, o worker como dono do banco.** O pytm não tem atributo para qual conta de banco um
  processo usa.
- **T08, o SMS que revela o tratamento.** É sobre o que o texto de uma mensagem diz a quem segura o
  celular, o que está fora do alcance de qualquer regra sobre elementos.

### Para que ela serve

Uma lista assim é um **lembrete de mecanismos**, lido por alguém que conhece o sistema. Path
traversal no console vale uma pergunta: o console alguma vez monta um caminho de arquivo a partir
do que um usuário digitou? Se a resposta é não, o achado se fecha numa frase. Se ninguém sabe, ele
cumpriu o seu papel. Usada assim, uma hora com os 196 acrescenta duas ou três perguntas à lista da
tarde.

Usada do outro jeito, como o próprio modelo de ameaças, ela enterra a T01 na posição 2 de 5 num
fluxo entre 196, com severidade média, ao lado de PHP num sistema sem PHP. **Um modelo de ameaças
são as catorze frases, cada uma esperando uma decisão. A lista da ferramenta é insumo para ele.**
