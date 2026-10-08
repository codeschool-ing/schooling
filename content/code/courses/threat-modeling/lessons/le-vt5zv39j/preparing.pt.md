---
title: Preparar, sem fingir
version: 1
---

Duas semanas antes de uma auditoria, os auditores mandam uma **lista de pedidos**: os documentos e
registros que querem ver, muitas vezes chamada de lista PBC, de *prepared by client*, preparado pelo
cliente. A da operadora chegou em 2 de outubro com oito itens. A ana a pôs no repositório ao lado do
modelo, com uma terceira coluna nomeando o arquivo que responde a cada pedido:

```
(.venv) ana@vm:~/tm/portal-model$ cat pbc.csv
id,request,evidence
P01,The current threat model of the patient portal,model.py
P02,The risk assessment with owners and estimates,risks.csv
P03,The risk treatment plan,controls.csv
P04,Approval of residual risks by their owners,decisions/RA-001-crafted-pdf.md
P05,Last review of each accepted risk,decisions/RA-002-cancellation-record.md
P06,Proof that staff sign-in requires a second factor,evidence/C1-second-factor-test.txt
P07,Controls mapped to ISO 27001,mapping.csv
P08,Security awareness training records,
```

### Conferindo a lista antes do auditor

O `pbc.py` lê esse arquivo e pergunta ao git sobre cada evidência:

```schooling-example
{"language": "python", "file": "pbc.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Check the auditor's request list: does each request name evidence, and is it in the repository?\"\"\"\nimport csv\nimport subprocess\n\n"}, {"code": "def last_change(path):\n    \"\"\"The date and author of the last commit that touched path, or None if git has never seen it.\"\"\"\n    out = subprocess.run([\"git\", \"log\", \"-1\", \"--format=%ad %an\", \"--date=short\", \"--\", path],\n                         capture_output=True, text=True, check=True).stdout.strip()\n    return out or None\n\n", "note": "Pergunta ao git o último commit que mexeu no arquivo. Um arquivo que o git nunca viu dá resposta vazia, que vira None: a evidência não está no repositório, seja o que for que haja no disco de alguém."}, {"code": "for row in csv.DictReader(open(\"pbc.csv\")):\n    if not row[\"evidence\"]:\n        status = \"NOTHING NAMED\"\n    else:\n        seen = last_change(row[\"evidence\"])\n        status = f\"ok, {seen}\" if seen else \"MISSING\"\n    print(f\"{row['id']}  {status:19}  {row['request']}\")", "note": "Três resultados por pedido: nada nomeado, nomeado e ausente, ou presente com a data e o autor da última mudança."}]}
```

```
(.venv) ana@vm:~/tm/portal-model$ python3 pbc.py
P01  ok, 2026-09-10 ana   The current threat model of the patient portal
P02  ok, 2026-09-22 ana   The risk assessment with owners and estimates
P03  ok, 2026-09-29 ana   The risk treatment plan
P04  ok, 2026-10-01 ana   Approval of residual risks by their owners
P05  ok, 2026-10-01 ana   Last review of each accepted risk
P06  MISSING              Proof that staff sign-in requires a second factor
P07  ok, 2026-10-05 ana   Controls mapped to ISO 27001
P08  NOTHING NAMED        Security awareness training records
```

Dois problemas que o programa consegue ver. **O P06 nomeia um arquivo que não existe**: o C1 está
planejado para a fase 1 e ainda não tem resultado de teste. **O P08 não nomeia nada**, porque a
Vereda não tem treinamento, o que a aula 13 achou pelo mapeamento.

### E os problemas que ele não consegue ver

Um programa confere que a evidência existe. Só uma pessoa confere que ela **responde ao pedido**.
Leia o P02 e o P05 contra os arquivos deles:

- **O P02 pede donos.** O `risks.csv` tem estimativas e nenhuma coluna de dono. Os donos estão em
  `decisions/`, para os três riscos que têm uma decisão, e em lugar nenhum para os outros seis.
- **O P05 pede a última revisão de cada risco aceito.** O arquivo nomeado é o RA-002, cuja revisão
  vencia em 2 de outubro e não aconteceu. A evidência existe, e o que ela prova é a lacuna.

Isso é uma **revisão de prontidão**: a auditoria feita antes, pelo lado auditado. Ela vale mais que a
própria auditoria, porque tudo o que acha ainda pode ser corrigido, ou pelo menos explicado com
honestidade antes que outra pessoa ache.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l14-preparation\" aria-label=\"A preparação da Vereda para a auditoria numa linha do tempo. 2 de outubro: chega a lista de pedidos. 6 de outubro: o pbc.py a confere e acha um item faltando e um sem nada nomeado. Outubro: as lacunas são corrigidas ou explicadas, e as respostas ensaiadas num walkthrough simulado. 9 a 11 de novembro: trabalho de campo. 30 de novembro: o relatório.\"><path d=\"M50.0 120.0 L680.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><circle cx=\"60.3\" cy=\"120.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><path d=\"M60.3 114.0 L60.3 48.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"60.3\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">lista de pedidos</text><text x=\"60.3\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2 out</text><circle cx=\"101.6\" cy=\"120.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><path d=\"M101.6 114.0 L101.6 78.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"101.6\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pbc.py: 2 lacunas</text><text x=\"101.6\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6 out</text><circle cx=\"452.8\" cy=\"120.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><path d=\"M452.8 114.0 L452.8 78.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"452.8\" y=\"70.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">trabalho de campo</text><text x=\"452.8\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">9–11 nov</text><circle cx=\"669.7\" cy=\"120.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><path d=\"M669.7 114.0 L669.7 48.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"669.7\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">relatório</text><text x=\"669.7\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30 nov</text><rect x=\"112.0\" y=\"160.0\" width=\"330.5\" height=\"22.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"277.2\" y=\"171.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">corrigir ou explicar cada lacuna; ensaiar o walkthrough</text><text x=\"360.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">nada é criado para parecer mais antigo do que é</text></svg>", "caption": "Cinco semanas entre o pedido e o trabalho de campo. A maior parte do valor de uma auditoria é gasta nelas, pelo lado auditado."}
```

### O que preparar pode e não pode fazer

Para cada lacuna há dois movimentos honestos. **Corrigir**, se dá para corrigir direito em cinco
semanas: rever o RA-002 com o daniel e registrar a revisão; acrescentar uma coluna de dono ao
`risks.csv`. Ou **explicar**: o P06 é respondido com o plano, a fase e a data, e o P08 com "nenhum, e
aqui está a decisão sobre isso" quando houver uma.

Há um movimento desonesto, e ele tenta justamente por ser fácil: **fazer uma evidência parecer mais
antiga do que é**. Escrever uma revisão do RA-002 com data de 2 de outubro, ou fazer o commit de um
resultado de teste com data de setembro, transforma uma revisão atrasada num registro falsificado. A
primeira coisa é um achado menor; a segunda acaba com a confiança do auditor em todos os outros
itens, e num contrato pode ser fraude. Toda correção feita em outubro tem data de outubro, e diz isso.

O último passo é um **ensaio do walkthrough**: a ana explica o modelo a alguém que nunca o viu, na
ordem em que o auditor vai perguntar, do DFD às decisões. A maioria das auditorias dá errado na
explicação, não na evidência, quando ninguém na sala sabe dizer por que um controle existe. Aqui a
resposta a "por quê?" é sempre um id de ameaça, e é isso que o ensaio confere.
