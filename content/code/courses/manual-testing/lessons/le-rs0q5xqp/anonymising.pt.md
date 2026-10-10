---
title: Anonimizando uma cópia da produção
version: 1
---

Mais cedo ou mais tarde alguém propõe testar com uma cópia do banco de dados real, e o argumento a
favor é bom: os dados de produção têm todo nome estranho, todo pedido abandonado e todo cliente que
fez algo que ninguém previu. O argumento contra é que **uma cópia da produção é uma cópia dos dados
pessoais de todos os clientes, num ambiente com mais gente, controles mais fracos e nenhum motivo
para guardá-los**. A resposta a que a maioria dos times chega é uma cópia alterada para não dizer
mais quem é quem, e as maneiras de alterá-la não são equivalentes.

## O que a lei diz

No Brasil a lei é a LGPD, a Lei Geral de Proteção de Dados. Ela trata como dado pessoal qualquer
informação que identifica uma pessoa, ou poderia identificá-la, e copiá-la para um ambiente de teste
é tratá-la: isso pede uma finalidade, exige proteção, e o acesso fica limitado a quem precisa.
**Dados anonimizados ficam fora da lei**, mas só se o processo não puder ser revertido com esforços
razoáveis; a lei diz isso no artigo 12. **Dados pseudonimizados, que podem ser ligados de novo à
pessoa por quem tem uma informação adicional, continuam sendo dados pessoais.** O GDPR europeu traça
a mesma linha. A consequência prática para quem testa: uma cópia mascarada ou pseudonimizada é mais
segura que uma crua, e ainda precisa ser tratada como dado pessoal.

## Três maneiras de alterar uma cópia

**Mascarar** troca parte de um valor por caracteres fixos. `Débora Barbosa` vira `D***** B******`. A
forma sobrevive, o tamanho e a primeira letra, que é o que um teste de layout ou de limite de campo
precisa. A unicidade não: Débora Barbosa e Daniel Bezerra viram os dois `D***** B******`, e qualquer
tabela que se refira à conta pelo nome deixa de distinguir os dois. E a parte que sobrevive ainda diz
algo: uma inicial e um tamanho, ao lado de uma cidade e de uma data de nascimento, podem bastar para
reconhecer alguém entre os sócios de um teatro pequeno.

**Pseudonimizar com um hash com chave** troca um valor por um código calculado a partir dele e de uma
chave secreta. O mesmo endereço com a mesma chave dá sempre o mesmo código, e ninguém sem a chave
consegue calculá-lo. Isso mantém a propriedade que a máscara perde: **a tabela de contas e a de
pedidos são pseudonimizadas separadamente e ainda se ligam**, porque o mesmo cliente recebe o mesmo
código nas duas. Um hash simples, sem chave, não protege nada aqui, porque qualquer um com uma lista
de endereços prováveis consegue calcular os hashes deles e comparar; a chave é o que impede isso.

**Gerar** troca os dados por inteiro, como a seção 03 desta aula fez. Nada neles foi de alguém,
então não há nada a proteger, e nada da variedade da produção sobrevive também.

## Um programa que faz as duas primeiras

O programa abaixo lê um arquivo de contas como o que a seção 03 produziu, mascara o nome, troca o
endereço por um pseudônimo com chave, e descarta a senha por inteiro, porque nenhum teste precisa
dela. O `accounts.csv` foi gerado, então os dados de ninguém correm risco aqui; ele faz o papel de
uma exportação de um sistema real, coisa que este curso nunca pede que você copie. Crie um arquivo
novo no seu diretório `boxoffice`, cole o programa nele e salve. Salve como `pseudonymise.py`,
exatamente esse nome:

```python
"""pseudonymise.py: a copy of an accounts file that names nobody.

    PSEUDONYM_KEY=... python3 pseudonymise.py accounts.csv > safe.csv
"""
import csv
import hashlib
import hmac
import os
import sys

key = os.environ.get("PSEUDONYM_KEY", "")      # kept by whoever owns the real data
if not key:
    sys.exit("pseudonymise.py: set PSEUDONYM_KEY to the key you were given")


def pseudonym(email):
    digest = hmac.new(key.encode(), email.lower().encode(), hashlib.sha256).hexdigest()
    return f"user-{digest[:12]}@example.org"


def mask(name):
    return " ".join(word[0] + "*" * (len(word) - 1) for word in name.split())


with open(sys.argv[1], newline="", encoding="utf-8") as f:
    rows = list(csv.DictReader(f))

writer = csv.DictWriter(sys.stdout, fieldnames=["name", "email"], lineterminator="\n")
writer.writeheader()
for row in rows:
    writer.writerow({"name": mask(row["name"]), "email": pseudonym(row["email"])})
```

A chave vai no ambiente, não no arquivo, para que o programa possa ser compartilhado sem que a chave
viaje com ele. Rode-o com uma chave:

```
ana@laptop:~/boxoffice$ PSEUDONYM_KEY=vila-test-key python3 pseudonymise.py accounts.csv
name,email
C*** B******,user-fd0012e00e53@example.org
D***** B******,user-9b1313cc8669@example.org
D***** M******,user-81a46e112012@example.org
G****** D*****,user-b0f365144ba2@example.org
F******* B******,user-800010070afe@example.org
```

Rode de novo com a mesma chave e os códigos saem idênticos, que é o que deixa duas tabelas se
ligarem. Com outra chave, as mesmas pessoas recebem outros códigos:

```
ana@laptop:~/boxoffice$ PSEUDONYM_KEY=vila-test-key python3 pseudonymise.py accounts.csv
name,email
C*** B******,user-fd0012e00e53@example.org
D***** B******,user-9b1313cc8669@example.org
D***** M******,user-81a46e112012@example.org
G****** D*****,user-b0f365144ba2@example.org
F******* B******,user-800010070afe@example.org
ana@laptop:~/boxoffice$ PSEUDONYM_KEY=another-key python3 pseudonymise.py accounts.csv
name,email
C*** B******,user-18ad58b96e1c@example.org
D***** B******,user-989fc93f33c9@example.org
D***** M******,user-f60bb686e4d8@example.org
G****** D*****,user-5db6a3c85348@example.org
F******* B******,user-ef74d7540351@example.org
```

E sem chave ele se recusa, em vez de produzir códigos que qualquer um conseguiria recalcular:

```
ana@laptop:~/boxoffice$ python3 pseudonymise.py accounts.csv
pseudonymise.py: set PSEUDONYM_KEY to the key you were given
```

No Windows, no PowerShell, defina a chave numa linha própria primeiro,
`$env:PSEUDONYM_KEY="vila-test-key"`, e depois rode `python pseudonymise.py accounts.csv`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" data-fig=\"l20-join\" aria-label=\"À esquerda, o original: uma linha de contas para Débora Barbosa, test002@example.org, e uma linha de pedidos, pedido 1003 para Hamlet, com o mesmo endereço. As duas passam por um hash com chave, e a chave fica com o dono dos dados. À direita, a cópia de teste: o nome mascarado como D***** B******, e o endereço trocado por user-9b1313cc8669@example.org nas duas tabelas, que ainda se ligam. Embaixo, o mesmo endereço com outra chave vira user-989fc93f33c9@example.org.\"><defs><marker id=\"mt-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"10.0\" y=\"16.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o original</text><text x=\"440.0\" y=\"16.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a cópia de teste</text><text x=\"10.0\" y=\"42.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">contas</text><text x=\"10.0\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pedidos</text><text x=\"440.0\" y=\"42.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">contas</text><text x=\"440.0\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pedidos</text><rect x=\"10.0\" y=\"52.0\" width=\"92.0\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"18.0\" y=\"65.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Débora Barbosa</text><rect x=\"102.0\" y=\"52.0\" width=\"136.0\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"65.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">test002@example.org</text><rect x=\"10.0\" y=\"128.0\" width=\"40.0\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"18.0\" y=\"141.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1003</text><rect x=\"50.0\" y=\"128.0\" width=\"136.0\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"58.0\" y=\"141.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">test002@example.org</text><rect x=\"186.0\" y=\"128.0\" width=\"52.0\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"194.0\" y=\"141.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Hamlet</text><rect x=\"440.0\" y=\"52.0\" width=\"92.0\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"448.0\" y=\"65.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">D***** B******</text><rect x=\"532.0\" y=\"52.0\" width=\"180.0\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"65.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">user-9b1313cc8669@example.org</text><rect x=\"440.0\" y=\"128.0\" width=\"40.0\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"448.0\" y=\"141.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1003</text><rect x=\"480.0\" y=\"128.0\" width=\"180.0\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"488.0\" y=\"141.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">user-9b1313cc8669@example.org</text><rect x=\"660.0\" y=\"128.0\" width=\"52.0\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"668.0\" y=\"141.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Hamlet</text><rect x=\"285.0\" y=\"72.0\" width=\"128.0\" height=\"64.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"349.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">hash com chave</text><text x=\"349.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a chave fica com</text><text x=\"349.0\" y=\"119.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o dono dos dados</text><path d=\"M238.0 65.0 L282.0 92.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><path d=\"M238.0 141.0 L282.0 118.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><path d=\"M416.0 92.0 L437.0 66.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><path d=\"M416.0 118.0 L437.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><path d=\"M600.0 79.0 L600.0 127.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"716.0\" y=\"174.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">mesmo código nas duas: as tabelas ainda se ligam</text><path d=\"M10.0 200.0 L710.0 200.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"10.0\" y=\"222.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">com outra chave, o mesmo endereço vira</text><text x=\"10.0\" y=\"242.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">user-989fc93f33c9@example.org</text></svg>", "caption": "Pseudonimizar cada tabela separadamente mantém a ligação, porque o mesmo endereço e a mesma chave dão o mesmo código. Outra chave dá outro código, e é por isso que a chave nunca vai junto com a cópia."}
```

## Quem guarda a chave

**Não é o testador.** A chave pertence a quem é dono dos dados reais, e fica com ele, ao lado do
sistema de produção. Quem tem a chave e a cópia pseudonimizada juntas consegue ligar cada linha de
volta a uma pessoa, o que transforma a cópia de novo no original. O testador recebe a cópia e nunca
a chave; quem faz a cópia guarda a chave e nunca a põe no ambiente de teste.

Mais duas regras fazem a diferença entre uma cópia segura e um vazamento com etapas a mais. **Leve só
as colunas de que um teste precisa**: a senha saiu porque nenhum teste a lê, e uma data de
nascimento que nenhum caso usa deve sair do mesmo jeito. E **olhe o que sobra em texto livre**: uma
observação de entrega que diz "deixar com a Débora no número 12" carrega um nome e um endereço numa
coluna que ninguém pensou em mascarar.
