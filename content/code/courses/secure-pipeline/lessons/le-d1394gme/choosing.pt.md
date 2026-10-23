---
title: Um achado por duas ferramentas, e qual ferramenta para qual pergunta
version: 1
---

Dois scanners apontados para a mesma coisa raramente imprimem o mesmo número, e a primeira reação é
decidir que um deles está errado. Em geral nenhum está. **Eles contam coisas diferentes, com nomes
diferentes, a partir de bancos diferentes**, e o jeito de ver isso é seguir um achado pelas duas.

### Gunicorn 21.2.0, duas vezes

O linkbox fixa o gunicorn 22.0.0. A versão anterior, 21.2.0, tem dois avisos de segurança publicados, o
que a torna um bom espécime. Ponha-a sozinha num arquivo de requirements de rascunho, fora do projeto,
e pergunte ao Trivy e depois ao pip-audit, a ferramenta que a aula 5 pôs no pipeline:

```
ana@vm:~/linkbox$ mkdir -p ~/scratch/old && cd ~/scratch/old
ana@vm:~/scratch/old$ printf "gunicorn==21.2.0\n" > requirements.txt
ana@vm:~/scratch/old$ trivy fs -q --format json . | jq -r ".Results[].Vulnerabilities[] | [.VulnerabilityID, .Severity, .FixedVersion] | @tsv"
CVE-2024-1135	HIGH	22.0.0
CVE-2024-6827	HIGH	22.0.0
ana@vm:~/scratch/old$ pip-audit --aliases on -r requirements.txt
Found 4 known vulnerabilities in 1 package
Name     Version ID              Fix Versions Aliases
-------- ------- --------------- ------------ ----------------------------------
gunicorn 21.2.0  PYSEC-2026-1434 22.0.0       CVE-2024-1135, GHSA-w3h3-4rj7-4ph4
gunicorn 21.2.0  PYSEC-2026-1433 22.0.0       GHSA-hc5x-x2vx-497g, CVE-2024-6827
gunicorn 21.2.0  PYSEC-2026-1434 22.0.0       CVE-2024-1135, GHSA-w3h3-4rj7-4ph4
gunicorn 21.2.0  PYSEC-2026-1433 22.0.0       GHSA-hc5x-x2vx-497g, CVE-2024-6827
```

O Trivy diz dois, o pip-audit diz quatro. Leia as linhas em vez da manchete:

- O Trivy nomeia cada aviso pelo identificador **CVE**: CVE-2024-1135 e CVE-2024-6827, os dois altos,
  os dois corrigidos na 22.0.0.
- O pip-audit os nomeia pelos identificadores **PYSEC**, do banco de avisos de Python que ele lê pelo
  PyPI, e `--aliases on` imprime os outros nomes de cada um: PYSEC-2026-1434 é CVE-2024-1135 e
  GHSA-w3h3-4rj7-4ph4, e PYSEC-2026-1433 é CVE-2024-6827 e GHSA-hc5x-x2vx-497g.
- O pip-audit imprimiu cada um dos dois avisos duas vezes, e a manchete dele contou as linhas.

**Dois problemas, três esquemas de nomes, e uma contagem de quatro.** Quem comparasse as manchetes
diria que o pip-audit achou o dobro. Quem compara pelos aliases vê que as duas ferramentas concordam
exatamente: os mesmos dois avisos, a mesma versão corrigida. Esse é o hábito que vale manter: comparar
achados por aviso, pelos aliases, nunca pelo número do topo.

### Por que dois scanners discordam

O caso do gunicorn mostra duas das causas. As outras são igualmente corriqueiras:

| causa | o que acontece |
|---|---|
| identificadores | um aviso com um nome CVE, um GHSA e um PYSEC, contado uma vez ou três |
| contagem | uma CVE em quatro pacotes da mesma origem Debian são quatro linhas para uma ferramenta e uma para outra, como a aula 8 viu |
| bancos | cada ferramenta lê as próprias fontes e atualiza na própria agenda, então um aviso novo chega a uma antes da outra |
| identidade do pacote | uma distribuição publica avisos por pacote **de origem** (`glibc`), um scanner vê pacotes **binários** (`libc6`); uma ferramenta que não consegue ligar um ao outro não casa nada |
| padrões | uma inclui avisos sem correção, outra os esconde; uma usa a severidade do fornecedor, outra a do NVD |

A quarta linha é a perigosa, porque não produz uma contagem diferente. Produz uma contagem de zero que
parece exatamente um resultado limpo. A aula 13 a encontra.

### Qual ferramenta para qual pergunta

As famílias desta aula, e os modos do Trivy, se alinham com perguntas. Comece pela pergunta, não pela
ferramenta que alguém já comprou.

| a pergunta | a ferramenta | onde roda |
|---|---|---|
| o que há dentro da imagem que vamos entregar? | um scanner de artefato: `trivy image` | o pipeline, a cada push (aula 8) |
| as nossas versões fixadas têm avisos? | `pip-audit`, `trivy fs` | o pipeline, a cada push (aula 5) |
| o Dockerfile e os manifestos definem o que decidimos? | `trivy config`, e as nossas próprias políticas | o pipeline (aula 19) |
| o que está rodando no cluster hoje? | `trivy k8s` | numa agenda, contra o cluster |
| o que está escutando na nossa rede, incluindo o que ninguém listou? | um scanner de rede, sem autenticação | numa agenda, com autorização por escrito |
| quais hosts estão sem um patch? | um scanner de rede com credenciais, ou agentes | numa agenda, em todo o parque |
| o laptop que nunca fica na rede do escritório está atualizado? | um agente | continuamente, a partir do host |
| somos afetados pelo aviso publicado hoje de manhã? | os SBOMs guardados | sob demanda (aula 13) |

**O pipeline é dono das três primeiras linhas, e este curso as constrói.** O resto pertence a quem opera
o parque, com Nessus, OpenVAS ou Qualys e a autorização que vem junto. Um time que só tem a metade do
pipeline conhece o próximo release e não os servidores; um time que só tem a outra metade descobre uma
biblioteca vulnerável um mês depois de ela ser entregue.
