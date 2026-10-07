---
title: Um mapeamento no repositório
version: 1
---

O mapeamento mora onde o modelo mora, como mais um arquivo juntado por id. A ana o acrescentou ao
repositório em 5 de outubro:

```
(.venv) ana@vm:~/tm/portal-model$ cat mapping.csv
control,plan,iso27001,csf
C1,phase 1,8.5,PR.AA-03
C2,phase 2,8.22,PR.IR-01
C3,phase 2,8.26,PR.DS-02
C4,phase 1,8.3,PR.AA-05
C5,phase 1,8.2,PR.AA-05
C6,not bought,8.7,PR.PS-05
C7,phase 2,5.17 8.5,PR.AA-03
C8,phase 1,5.34,PR.DS-02
C9,phase 2,8.26,PR.IR-04
C10,phase 2,8.6,PR.IR-04
C11,law,5.15 5.34,PR.AA-05
```

Quatro colunas. O controle, pelo id de `controls.csv`. **Onde ele está no plano** da aula 11: fase 1,
fase 2, feito porque a lei exige, ou não comprado. Depois uma referência em cada framework, ou duas
separadas por espaço quando um controle responde a duas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l13-files\" aria-label=\"Os quatro arquivos que o laboratório junta, e a coluna que cada junção usa. threats.csv guarda de T01 a T17. requirements.csv nomeia as suas ameaças numa coluna chamada threats. controls.csv nomeia a ameaça que reduz numa coluna chamada risk. mapping.csv nomeia um controle numa coluna chamada control e acrescenta uma referência da ISO 27001 e uma do NIST CSF. Toda junção é por id.\"><defs><marker id=\"l13-files-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30.0\" y=\"120.0\" width=\"150.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"105.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">threats.csv</text><text x=\"105.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">T01 … T17</text><rect x=\"30.0\" y=\"15.0\" width=\"150.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"105.0\" y=\"31.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">requirements.csv</text><text x=\"105.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R01 … R19</text><rect x=\"290.0\" y=\"120.0\" width=\"150.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"365.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">controls.csv</text><text x=\"365.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">C1 … C11</text><rect x=\"540.0\" y=\"120.0\" width=\"150.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"615.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">mapping.csv</text><text x=\"615.0\" y=\"159.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ISO 27001 e</text><text x=\"615.0\" y=\"172.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">NIST CSF</text><path d=\"M105.0 85.0 L105.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-files-tm-ah-paper-dim)\"></path><text x=\"115.0\" y=\"102.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">coluna threats</text><path d=\"M290.0 155.0 L180.0 155.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-files-tm-ah-paper-dim)\"></path><text x=\"235.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">risk</text><path d=\"M540.0 155.0 L440.0 155.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-files-tm-ah-paper-dim)\"></path><text x=\"490.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">control</text><text x=\"360.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">cada seta aponta para o arquivo cujo id ela nomeia</text></svg>", "caption": "Nenhum arquivo repete as palavras de outro. Uma ameaça renomeada em threats.csv não muda nada nos outros três, porque eles guardam o id dela.", "same": ["C1 … C11", "NIST CSF", "R01 … R19", "T01 … T17"]}
```

O arquivo não diz nada que um leitor também ache em outro lugar. Não repete o nome do controle, o
custo nem a ameaça, porque isso está em `controls.csv` e uma cópia divergiria na primeira vez que um
deles mudasse. Ele guarda o único fato novo, as referências, e o id que o junta a todo o resto.

### Lendo de volta

O `crosswalk.py` junta os dois arquivos e imprime o mapeamento em três formas:

```schooling-example
{"language": "python", "file": "crosswalk.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Read the controls through a framework: ISO/IEC 27001:2022 Annex A, or the NIST CSF 2.0.\n\n    python3 crosswalk.py            every control, its threat and both references\n    python3 crosswalk.py iso27001   grouped by the four themes of Annex A\n    python3 crosswalk.py csf        grouped by the six functions of the CSF\n\"\"\"\nimport collections\nimport csv\nimport re\nimport sys\n", "note": "O que ele lê e as três formas que imprime. A docstring nomeia as edições, porque uma referência não quer dizer nada sem uma."}, {"code": "GROUPS = {\n    \"iso27001\": {\"5\": \"organisational\", \"6\": \"people\", \"7\": \"physical\", \"8\": \"technological\"},\n    \"csf\": {\"GV\": \"Govern\", \"ID\": \"Identify\", \"PR\": \"Protect\",\n            \"DE\": \"Detect\", \"RS\": \"Respond\", \"RC\": \"Recover\"},\n}\n\ncontrols = {row[\"control\"]: row for row in csv.DictReader(open(\"controls.csv\"))}\nmapping = list(csv.DictReader(open(\"mapping.csv\")))\n", "note": "Como as referências de cada framework se agrupam: o Anexo A pelo número antes do ponto, o CSF pelas duas letras da função. Os dois arquivos são lidos inteiros e juntados pelo id do controle."}, {"code": "if len(sys.argv) == 1:\n    for m in mapping:\n        c = controls[m[\"control\"]]\n        print(f\"{m['control']:4} {c['risk']:4} {m['iso27001']:9} {m['csf']:9} {m['plan']:10}  {c['name']}\")\n    sys.exit()\n", "note": "Sem argumento, uma linha por controle: o id, a ameaça, as duas referências e onde ele está no plano. O nome vem de controls.csv, nunca do mapeamento."}, {"code": "framework = sys.argv[1]\nrefs = collections.defaultdict(list)\nfor m in mapping:\n    for ref in m[framework].split():\n        refs[ref].append(m)\n", "note": "Inverte o mapeamento: para cada referência, os controles que a respondem. Um controle com duas referências cai sob as duas."}, {"code": "def order(ref):\n    return [int(p) if p.isdigit() else p for p in re.split(r\"[.-]\", ref)]\n", "note": "Ordena 8.22 depois de 8.5, o que uma ordenação de texto simples erra."}, {"code": "for prefix, name in GROUPS[framework].items():\n    mine = sorted((r for r in refs if r.split(\".\")[0] == prefix), key=order)\n    print(f\"{name:14} {len(mine)}\")\n    for ref in mine:\n        names = [m[\"control\"] + (\" (not bought)\" if m[\"plan\"] == \"not bought\" else \"\") for m in refs[ref]]\n        print(f\"  {ref:9} {'  '.join(names)}\")", "note": "Todo grupo é impresso, os vazios também, porque uma função vazia é o achado. Um controle que não foi comprado diz isso onde quer que apareça."}]}
```

Sem argumento, todo controle, a ameaça para a qual foi escolhido, as duas referências e onde está no
plano:

```
(.venv) ana@vm:~/tm/portal-model$ python3 crosswalk.py
C1   T03  8.5       PR.AA-03  phase 1     second factor for staff
C2   T03  8.22      PR.IR-01  phase 2     console on the clinic network only
C3   T01  8.26      PR.DS-02  phase 2     webhook signature and amount check
C4   T07  8.3       PR.AA-05  phase 1     ownership check on exam downloads
C5   T13  8.2       PR.AA-05  phase 1     least-privilege account for the worker
C6   T14  8.7       PR.PS-05  not bought  isolated viewer for exam PDFs
C7   T02  5.17 8.5  PR.AA-03  phase 2     sign-in rate limit and breached passwords
C8   T08  5.34      PR.DS-02  phase 1     reminder text without the clinic
C9   T10  8.26      PR.IR-04  phase 2     upload size and type limit
C10  T11  8.6       PR.IR-04  phase 2     daily cap on reminder messages
C11  T03  5.15 5.34 PR.AA-05  law         receptionist role without clinical notes
```

Lida na horizontal, cada linha é a cadeia inteira que este curso construiu: uma ameaça, um controle,
o que cada framework o chama e se ele já existe. **Essa última coluna é a que um questionário mais
costuma perder.** "Vocês protegem os arquivos de exame contra sobrescrita?" tem uma resposta honesta
que não é sim nem não: o C4 está planejado para a fase 1, e até lá a T07 está aberta.

### Um mapeamento, mantido com honestidade

Três regras mantêm o arquivo digno de ser lido:

- **Um controle sem referência mantém a sua linha.** A célula vazia diz que ninguém achou onde ele se
  encaixa, o que é diferente de o controle não existir.
- **Uma referência sem controle não é escrita aqui.** Este arquivo mapeia controles para fora. A
  pergunta "quais controles do Anexo A nós não temos?" pertence à declaração de aplicabilidade, na
  próxima seção, onde cada um dos 93 é respondido.
- **A edição fica escrita.** `iso27001` aqui quer dizer a edição de 2022 e `csf` quer dizer a 2.0, e a
  docstring do `crosswalk.py` diz isso. Quando qualquer um for revisado, a coluna ganha a edição no
  nome, para um mapeamento velho não poder ser lido como um novo.
