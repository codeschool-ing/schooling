---
title: Um scanner de conteúdo
version: 1
---

**Um scanner de conteúdo lê arquivos e informa quais trazem dados pessoais.** Rodado sobre um
servidor de arquivos, ele responde à pergunta com que a DLP começa, que é onde os dados estão em
repouso; rodado no momento em que um arquivo está para sair, ele é a conferência que decide se pode.
É o mesmo programa nos dois lugares, e este é curto o bastante para ler. Salve-o no `desk` como
`scan.py`:

```schooling-example
{"language": "python", "file": "scan.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"scan.py: find CPFs and card numbers in files, check them, and say how many without printing them.\"\"\"\nimport os, re, sys\n\nCPF = re.compile(r\"(?<![\\d.])\\d{3}\\.?\\d{3}\\.?\\d{3}-?\\d{2}(?![\\d-])\")\nCARD = re.compile(r\"(?<!\\d)(?:\\d[ -]?){12,18}\\d(?!\\d)\")", "note": "Dois padrões acham os candidatos: um CPF escrito com ou sem os pontos e o traço, e uma sequência de treze a dezenove dígitos, com espaços e traços permitidos, que cobre todo tamanho de cartão em uso. As verificações em volta impedem que um padrão comece ou termine no meio de um número maior."}, {"code": "def cpf_ok(text):\n    d = [int(c) for c in text if c.isdigit()]\n    if len(set(d)) == 1:\n        return False\n    for n in (9, 10):\n        r = sum(x * w for x, w in zip(d, range(n + 1, 1, -1))) * 10 % 11\n        if (0 if r == 10 else r) != d[n]:\n            return False\n    return True\n\ndef luhn_ok(text):\n    d = [int(c) for c in text if c.isdigit()]\n    total = 0\n    for i, x in enumerate(reversed(d)):\n        x = x * 2 if i % 2 else x\n        total += x - 9 if x > 9 else x\n    return total % 10 == 0", "note": "Cada candidato é conferido do jeito que o emissor calcula. Um CPF feito de um dígito repetido, `111.111.111-11`, passa na conta e é recusado pela Receita Federal, então é recusado aqui também."}, {"code": "def mask(text):\n    digits = [c for c in text if c.isdigit()]\n    return \"\".join(digits[:3]) + \"*\" * (len(digits) - 5) + \"\".join(digits[-2:])", "note": "**Uma ferramenta de DLP que imprime o que achou acabou de copiar os dados pessoais para o próprio log.** Então ela imprime uma contagem e um exemplo mascarado até os três primeiros e os dois últimos dígitos, o que basta para uma pessoa achar a linha e é pouco demais para usar."}, {"code": "def scan(path, check):\n    found = {\"cpf\": [], \"card\": [], \"rejected\": 0}\n    text = open(path, errors=\"replace\").read()\n    for kind, pattern, ok in ((\"cpf\", CPF, cpf_ok), (\"card\", CARD, luhn_ok)):\n        for m in pattern.finditer(text):\n            if not check or ok(m.group()):\n                found[kind].append(m.group())\n            else:\n                found[\"rejected\"] += 1\n    return found\n\ncheck = \"--no-check\" not in sys.argv\nfor top in [a for a in sys.argv[1:] if not a.startswith(\"--\")]:\n    paths = [top] if os.path.isfile(top) else sorted(\n        os.path.join(root, name) for root, _, files in os.walk(top) for name in files)\n    for path in paths:\n        f = scan(path, check)\n        if f[\"cpf\"] or f[\"card\"]:\n            first = mask((f[\"cpf\"] or f[\"card\"])[0])\n            print(f'{path}: {len(f[\"cpf\"])} CPF, {len(f[\"card\"])} card, '\n                  f'{f[\"rejected\"]} rejected, e.g. {first}')", "note": "O resto recebe arquivos, ou diretórios para percorrer, e imprime uma linha por arquivo que contenha algo. `--no-check` guarda toda ocorrência sem a conta, que é como a seção sobre falsos positivos mede quanto a conferência vale."}]}
```

Dê a ele algo para ler: uma pasta com a lista de clientes, um arquivo de números de pedido e um
memorando sem número nenhum.

```
ana@desk:~$ mkdir docs; mv clientes.csv docs/
ana@desk:~$ printf "Pedido 12345678901 entregue\nPedido 98765432100 pendente\nCaixa 111.111.111-11\n" > docs/pedidos.txt
ana@desk:~$ printf "Reunião de quinta às 10h, sala 2.\n" > docs/memo.txt
```

Depois varra a pasta:

```
ana@desk:~$ python3 scan.py docs
docs/clientes.csv: 20 CPF, 20 card, 0 rejected, e.g. 881******41
docs/pedidos.txt: 1 CPF, 0 card, 2 rejected, e.g. 987******00
```

A lista de clientes informa todos os vinte CPFs e os vinte cartões. O memorando não aparece, porque
um arquivo sem nada dentro não ganha linha. **O arquivo de pedidos é o interessante.** Três coisas ali
parecem um CPF; duas foram rejeitadas, e uma passou: `98765432100`, um número de pedido, por acaso
tem dígitos verificadores válidos. Para o scanner é um CPF, e nenhuma conta consegue dizer o
contrário, porque é um CPF perfeitamente válido. O `111.111.111-11` da linha do caixa foi recusado
porque um CPF de onze dígitos iguais passa na conta e não é emitido.

Os exemplos vêm mascarados até os três primeiros e os dois últimos dígitos. **Isso não é enfeite.** A
saída de uma ferramenta de DLP vai para um log, um alerta, um chamado e um e-mail para quem revisa;
uma ferramenta que imprimisse o que achou copiaria os dados pessoais para todos eles. Todo produto
comercial mascara pelo mesmo motivo, e os relatórios que ele guarda sobre o que achou são eles mesmos
tratados como dados pessoais, que é o assunto da última seção.

## O que o scanner não vê

Padrões acham **identificadores**, números com um formato conhecido. A maior parte do que um
escritório preferiria guardar também não tem formato: um contrato, uma revisão de salário, a situação
fiscal de um cliente escrita em frases. Nenhum padrão acha essas coisas. Ferramentas comerciais
acrescentam três recursos para elas, e nenhum roda aqui:

- **rótulos**, postos por uma pessoa ou por uma regra quando um documento é criado, que a ferramenta
  depois respeita ("confidencial: clientes"), como os rótulos de confidencialidade do Microsoft
  Purview;
- **correspondência exata de dados**: a ferramenta recebe uma cópia protegida da lista real de
  clientes e reconhece qualquer documento que traga linhas dela, o que acha clientes reais e não só
  números válidos;
- **impressões digitais** de documentos específicos, para que uma cópia do modelo de contrato do ano
  seja reconhecida mesmo editada.

Um rótulo depende de pessoas o aplicarem. Os outros dois dependem de o escritório entregar à
ferramenta uma cópia exatamente dos dados que quer proteger, então o próprio armazenamento da
ferramenta vira mais um lugar a proteger.
