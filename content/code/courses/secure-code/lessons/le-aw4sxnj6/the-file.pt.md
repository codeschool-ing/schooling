---
title: O padrão como arquivo
version: 1
---

O ASVS é publicado como PDF e documento Word para leitura, e como **arquivo CSV** para trabalhar:
uma linha por requisito, com capítulo, seção, identificador, texto e nível. Um arquivo dá para
buscar, contar e transformar numa lista de verificação, e é assim que uma equipe o usa no dia a dia.

A pasta desta aula é `~/sc/asvs`. Baixe o CSV da versão 5.0.0 do repositório do projeto e veja as
primeiras linhas:

```
(.venv) ana@vm:~/sc$ mkdir asvs
(.venv) ana@vm:~/sc$ cd asvs
(.venv) ana@vm:~/sc/asvs$ curl -sSLO https://raw.githubusercontent.com/OWASP/ASVS/v5.0.0/5.0/docs_en/OWASP_Application_Security_Verification_Standard_5.0.0_en.csv
(.venv) ana@vm:~/sc/asvs$ head -n 2 OWASP_Application_Security_Verification_Standard_5.0.0_en.csv | cut -c 1-100
chapter_id,chapter_name,section_id,section_name,req_id,req_description,L
V1,Encoding and Sanitization,V1.1,Encoding and Sanitization Architecture,V1.1.1,"Verify that input i
```

### Um programa pequeno para ler

O módulo `csv` do Python o lê diretamente. Este programa imprime as contagens por nível e por
capítulo quando roda sem argumento, e todo requisito cujo identificador começa com um prefixo quando
recebe um. Salve como `asvs.py`:

```python
# asvs.py
import csv
import sys
from collections import Counter

FILE = "OWASP_Application_Security_Verification_Standard_5.0.0_en.csv"
ROWS = list(csv.DictReader(open(FILE, encoding="utf-8")))

if len(sys.argv) == 1:
    new = Counter(row["L"] for row in ROWS)
    print(f"{len(ROWS)} requirements")
    total = 0
    for level in "123":
        total += new[level]
        print(f"  level {level}: {new[level]:3} new, {total:3} to meet in all")
    for chapter, count in Counter(f"{r['chapter_id']} {r['chapter_name']}" for r in ROWS).items():
        print(f"  {count:3}  {chapter}")
else:
    prefix = sys.argv[1].upper()
    for row in ROWS:
        if row["req_id"].startswith(prefix):
            print(f"{row['req_id']} (L{row['L']}) {row['req_description']}")
```

```
(.venv) ana@vm:~/sc/asvs$ python3 asvs.py
345 requirements
  level 1:  70 new,  70 to meet in all
  level 2: 183 new, 253 to meet in all
  level 3:  92 new, 345 to meet in all
   30  V1 Encoding and Sanitization
   13  V2 Validation and Business Logic
   31  V3 Web Frontend Security
   16  V4 API and Web Service
   13  V5 File Handling
   47  V6 Authentication
   19  V7 Session Management
   13  V8 Authorization
    7  V9 Self-contained Tokens
   36  V10 OAuth and OIDC
   24  V11 Cryptography
   12  V12 Secure Communication
   21  V13 Configuration
   13  V14 Data Protection
   21  V15 Secure Coding and Architecture
   17  V16 Security Logging and Error Handling
   12  V17 WebRTC
```

**345 requisitos em 17 capítulos.** O nível 1 pede 70 deles; o nível 2, o alvo do portal, 253. Os
capítulos seguem a forma de uma aplicação: o que entra e sai (V1, V2), o navegador (V3), arquivos
(V5), quem você é (V6), sessões (V7), o que você pode fazer (V8), e assim por diante até os logs
(V16).

### Lendo uma seção

Identificadores têm três partes: capítulo, seção, requisito. `V2.2.1` é o capítulo V2, *Validation
and Business Logic*, seção 2, *Input Validation*, requisito 1. Peça a seção inteira pelo prefixo, com
o ponto no fim para `V2.2` não pegar também `V2.20`:

```
(.venv) ana@vm:~/sc/asvs$ python3 asvs.py v2.2.
V2.2.1 (L1) Verify that input is validated to enforce business or functional expectations for that input. This should either use positive validation against an allow list of values, patterns, and ranges, or be based on comparing the input to an expected structure and logical limits according to predefined rules. For L1, this can focus on input which is used to make specific business or security decisions. For L2 and up, this should apply to all input.
V2.2.2 (L1) Verify that the application is designed to enforce input validation at a trusted service layer. While client-side validation improves usability and should be encouraged, it must not be relied upon as a security control.
V2.2.3 (L2) Verify that the application ensures that combinations of related data items are reasonable according to the pre-defined rules.
```

Releia o V2.2.1 e o V2.2.2 pensando nas aulas 2 e 3. **Validação positiva contra uma lista de
permissão**, numa camada de serviço confiável, com a validação no cliente incentivada pela
usabilidade e nunca usada como controle: o curso chegou às mesmas frases que o padrão escreve, e é
para isso que serve ter um padrão. A próxima seção associa cada aula ao seu capítulo.
