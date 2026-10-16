---
title: Lendo um achado sem entrar em pânico
version: 1
---

O relatório de um scanner chega como uma lista de identificadores ao lado do nome de um pacote,
muitas vezes em vermelho, e a primeira reação é tratar cada linha como um incêndio. **A maioria das
linhas da maioria dos relatórios não é um incêndio no seu sistema.** Um achado diz que uma versão de
uma biblioteca tem uma falha publicada. Se essa falha consegue ferir *esta* aplicação é uma segunda
pergunta, e o relatório não consegue respondê-la, porque nunca leu o seu código. Triagem é
respondê-la, um alerta de cada vez, com quatro perguntas.

## 1. Como ele se chama, em todo lugar?

Uma falha tem vários nomes, porque vários bancos a registram. O pip-audit imprime o do PyPI, e pede
os outros com `-f json`. O `jq` abaixo guarda o identificador, os apelidos e a versão corrigida, uma
linha por alerta:

```
ana@nft:~/audit$ ~/venv/bin/pip-audit -r requirements.txt -f json 2>/dev/null | jq -r '.dependencies[].vulns[] | [.id, (.aliases | join(" ")), (.fix_versions | join(" "))] | @tsv' | sort -u
PYSEC-2026-1872	CVE-2024-47081 GHSA-9hjg-9r4m-mvj7	2.32.4
PYSEC-2026-1873	CVE-2024-35195 GHSA-9wx4-h78v-vm56	2.32.0
PYSEC-2026-2275	CVE-2026-25645 GHSA-gc5v-m9x4-r6x2	2.33.0
```

- **`PYSEC-…`** é o id do banco de alertas do Python, o que o pip-audit imprimiu.
- **`GHSA-…`** é o id do banco de alertas do GitHub para a mesma falha, onde costuma estar a
  descrição mais legível.
- **`CVE-…`** é o identificador do programa CVE, o que é igual em todo banco, todo scanner e todo
  boletim de fornecedor. **Busque pelo CVE**: é assim que você descobre que o achado deste relatório
  é o mesmo que um colega já triou em outro.

O ano num id `PYSEC` é quando aquele banco o registrou, e o CVE diz quando foi atribuído: o
`CVE-2024-35195` chegou ao banco do Python como `PYSEC-2026-1873`. Nenhuma das duas datas diz há
quanto tempo a falha está no seu código. Isso é a versão que você fixou, `2.31.0`, e há quanto tempo
ela está fixada.

## 2. Quão grave é, em geral e aqui?

A medida de costume é o **CVSS**, o Common Vulnerability Scoring System: uma nota de 0 a 10, com
faixas chamadas baixa, média, alta e crítica. A nota que um alerta publica é a **nota base**. Ela
descreve a falha em abstrato, supondo o pior uso plausível da biblioteca, e é a mesma para todo
mundo que instala aquela versão.

O pip-audit não imprime nota. As páginas dos alertas trazem uma, e o computador da gravação não as
alcançava, então esta aula não cita nenhuma. Copiar um número de memória para uma aula é exatamente
o erro a evitar numa tabela de triagem, também.

**A nota base é onde a triagem começa, não onde termina.** O CVSS define também uma nota
**ambiental**, que quem opera o sistema calcula por conta própria: a mesma falha, ajustada para onde
a biblioteca fica, que dados ela toca e o que um atacante já precisaria ter para usá-la. Uma falha
alta em geral pode ser baixa num script que roda uma vez por dia numa máquina sem usuários; uma média
pode ser a pior coisa num serviço de pagamento.

## 3. O código vulnerável é alcançável a partir do seu?

Esta é a pergunta que decide a maioria dos achados, e o próprio texto do alerta costuma dizer o que
precisa ser verdade para a falha importar. Peça a descrição do terceiro:

```
ana@nft:~/audit$ ~/venv/bin/pip-audit -r requirements.txt -f json --desc on 2>/dev/null | jq -r '[.dependencies[].vulns[] | select(.id == "PYSEC-2026-2275")][0].description'
### Impact The `requests.utils.extract_zipped_paths()` utility function uses a predictable filename when extracting files from zip archives into the system temporary directory. If the target file already exists, it is reused without validation. A local attacker with write access to the temp directory could pre-create a malicious file that would be loaded in place of the legitimate one.  ### Affected usages **Standard usage of the Requests library is not affected by this vulnerability.** Only applications that call `extract_zipped_paths()` directly are impacted.  ### Remediation Upgrade to at least Requests 2.33.0, where the library now extracts files to a non-deterministic location.  If developers are unable to upgrade, they can set `TMPDIR` in their environment to a directory with restricted write access.
```

**"Standard usage of the Requests library is not affected."**, o uso normal da biblioteca não é
afetado. A falha está numa função, `extract_zipped_paths()`, e só o código que a chama fica exposto.
As outras duas descrições nomeiam as suas condições do mesmo jeito: o `PYSEC-2026-1873` só importa
para uma sessão que alguma vez mandou uma requisição com `verify=False`, e o `PYSEC-2026-1872` só
para uma aplicação que manda requisições a URLs que outra pessoa montou, enquanto um arquivo
`.netrc` guarda credenciais. Agora procure essas condições no código:

```
ana@nft:~/audit$ grep -n -e 'verify=False' -e 'trust_env' -e 'extract_zipped_paths' notify.py; echo "exit $?"
exit 1
ana@nft:~/audit$ grep -n -e 'url' notify.py
9:    url = os.environ["NOTIFY_URL"]          # set by whoever deploys it, never typed by a customer
10:    session.post(url, json={"text": f"show {show_id} is sold out"}, timeout=5)
```

Nenhum dos três padrões está no `notify.py`; o `grep` não achou nada e saiu com 1. A URL vem de um
lugar só, uma variável de ambiente definida por quem implanta o auxiliar, e nunca de um cliente. Uma
busca assim é uma primeira resposta, não uma prova: uma chamada por uma variável, ou por outra
biblioteca, não apareceria num `grep`. **A alcançabilidade é o que transforma *a biblioteca tem uma
falha* em *estamos expostos a ela*,** e merece o mesmo cuidado que um teste.

## 4. Ele é real, afinal?

Um **falso positivo** é um achado que está errado sobre o seu sistema: o scanner casou o pacote
errado com o mesmo nome, leu uma versão que não é a instalada, ou o fornecedor do seu sistema
corrigiu a falha sem mudar o número da versão. Um achado que está certo sobre a biblioteca e não é
alcançável pelo seu código não é um falso positivo. É um **verdadeiro positivo de prioridade
baixa**, e manter os dois separados é o que permite à próxima pessoa confiar na triagem. O
vocabulário de verdadeiros e falsos positivos e negativos tem uma aula própria, a aula 11 de
`security-fundamentals`.

## A triagem, por escrito

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l21-triage\" aria-label=\"O relatório do pip-audit sobre o requests 2.31.0, estreitado passo a passo. Seis linhas no relatório. Três alertas depois de tirar as duplicatas: PYSEC-2026-1873, PYSEC-2026-1872 e PYSEC-2026-2275. Nenhum dos três alcançável a partir do notify.py. Uma decisão que resolve os três: atualizar para a 2.33.0.\"><text x=\"360.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">conte decisões, não linhas</text><rect x=\"160.0\" y=\"44.0\" width=\"400.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"182.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">6</text><text x=\"204.0\" y=\"57.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">linhas no relatório</text><text x=\"204.0\" y=\"73.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cada alerta impresso duas vezes</text><rect x=\"190.0\" y=\"94.0\" width=\"340.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"212.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">3</text><text x=\"234.0\" y=\"107.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">alertas</text><text x=\"234.0\" y=\"123.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um por CVE</text><rect x=\"215.0\" y=\"144.0\" width=\"290.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"237.0\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">0</text><text x=\"259.0\" y=\"157.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">alcançáveis pelo notify.py</text><text x=\"259.0\" y=\"173.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o grep não achou nenhuma condição</text><rect x=\"240.0\" y=\"194.0\" width=\"240.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"262.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" font-weight=\"600\" fill=\"var(--amber)\">1</text><text x=\"284.0\" y=\"207.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">decisão</text><text x=\"284.0\" y=\"223.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">requests==2.33.0</text></svg>", "caption": "Seis linhas viraram três alertas, nenhum alcançável, e uma atualização que fecha todos."}
```

| alerta | apelidos | importa se | no notify.py | decisão |
|---|---|---|---|---|
| `PYSEC-2026-1873` | `CVE-2024-35195` | uma sessão alguma vez manda com `verify=False` | não | corrigir: atualizar para 2.32.0 ou depois |
| `PYSEC-2026-1872` | `CVE-2024-47081` | as URLs vêm de fora, e um `.netrc` guarda credenciais | não: a URL é de quem implanta | corrigir: atualizar para 2.32.4 ou depois |
| `PYSEC-2026-2275` | `CVE-2026-25645` | o código chama `extract_zipped_paths()` | não | corrigir: atualizar para 2.33.0 ou depois |

**Três achados, nenhum alcançável, e ainda assim três decisões de corrigir.** Inalcançável hoje não
é inalcançável depois da próxima mudança, e aqui uma atualização, para a `2.33.0`, tira os três.
Quando a correção é barata assim, a triagem só decide a urgência. A próxima seção pega o outro caso,
em que a correção ainda não pode acontecer.
