---
title: Corrigindo, e aceitando o que ainda não dá para corrigir
version: 1
---

A aula 1 escreveu o requisito de segurança que esta aula precisa tornar testável: **nenhum achado
classificado como alto ou crítico em aberto na entrega.** Lida junto com a seção anterior, cada
palavra dele tem sentido. *Classificado* é a classificação da triagem, a ambiental, não a nota base
copiada do alerta. *Em aberto* quer dizer nem corrigido nem aceito por alguém com autoridade para
aceitar. E *na entrega* quer dizer que a verificação roda no pipeline, onde uma entrega não consegue
contorná-la.

Corrigir é a resposta de costume, e a mais barata. Às vezes não dá para hoje: a versão corrigida
precisa de um Python mais novo que o dos servidores, ou muda um comportamento de que outra equipe
depende. Então o achado é **aceito**, o que é uma decisão com quatro partes, nenhuma opcional: o
alerta, o motivo, um **dono** que responde por ela, e uma **data de validade** depois da qual ela é
decidida de novo. A aula 3 de `security-fundamentals` é onde aceitar um risco aparece ao lado de
mitigá-lo, transferi-lo e evitá-lo.

## Um portão que sabe o que foi aceito

O pip-audit aceita `--ignore-vuln` para deixar um alerta de fora. Sozinha, essa opção é um jeito de
calar um relatório e esquecer por quê. Embrulhada num script pequeno que carrega o motivo e se recusa
a funcionar depois da data final, ela é o registro de uma decisão. Em `~/audit`, crie-o com
`nano audit.sh`, e troque a data na linha `UNTIL` para cerca de um mês depois do dia em que você o
digitar:

```sh
# audit/audit.sh
# The dependency gate: it fails on every advisory nobody has accepted. Run: sh audit.sh
# An accepted risk names the advisory, why it is accepted, who owns it, and when that ends.
cd "$(dirname "$0")" || exit 2
ACCEPTED=PYSEC-2026-2275          # extract_zipped_paths() is never called by notify.py. Owner: ana.
UNTIL=${UNTIL:-2026-11-15}        # after this day the acceptance is void and the gate fails again
if [ "$(date +%F)" \> "$UNTIL" ]; then
    echo "accepted risk $ACCEPTED expired on $UNTIL: fix it, or decide again" >&2
    exit 1
fi
exec ~/venv/bin/pip-audit -r requirements.txt --ignore-vuln "$ACCEPTED"
```

Suponha que a equipe ainda não consiga passar da `2.32` e aceite o único alerta cuja função ninguém
chama. Rode o portão, e depois rode de novo como se a data final já tivesse passado, que é o que o
`UNTIL=` na frente do comando faz por aquela execução:

```
ana@nft:~/audit$ sh audit.sh; echo "exit $?"
Found 4 known vulnerabilities, ignored 2 in 1 package
Name     Version ID              Fix Versions
-------- ------- --------------- ------------
requests 2.31.0  PYSEC-2026-1873 2.32.0
requests 2.31.0  PYSEC-2026-1872 2.32.4
requests 2.31.0  PYSEC-2026-1873 2.32.0
requests 2.31.0  PYSEC-2026-1872 2.32.4
exit 1
ana@nft:~/audit$ UNTIL=2026-10-01 sh audit.sh; echo "exit $?"
accepted risk PYSEC-2026-2275 expired on 2026-10-01: fix it, or decide again
exit 1
```

A primeira execução **ignorou duas linhas, o alerta aceito impresso duas vezes, e ainda assim
falhou**: os outros dois não foram aceitos, e ninguém disse que foram. É o portão funcionando. A
segunda execução nem chegou ao pip-audit, porque a aceitação tinha vencido, e ela disse isso com
palavras. Uma aceitação sem data final é como um achado temporário em março continua no relatório em
dezembro, aceito por alguém que já saiu da empresa.

## A correção

Aqui a correção existe e é uma linha: a versão `2.33.0` que o terceiro alerta indicou.

```
ana@nft:~/audit$ sed -i 's/requests==2.31.0/requests==2.33.0/' requirements.txt
ana@nft:~/audit$ ~/venv/bin/pip-audit -r requirements.txt; echo "exit $?"
No known vulnerabilities found
exit 0
ana@nft:~/audit$ sh audit.sh; echo "exit $?"
No known vulnerabilities found
exit 0
```

**Nenhuma vulnerabilidade conhecida, e saída 0**, do pip-audit e do portão. A auditoria resolveu o
`requests` 2.33.0 e tudo o que ele puxa, e não achou nada contra nenhum deles no dia em que rodou. A
aceitação no `audit.sh` agora ignora um alerta que não aparece mais; tire-a do script no mesmo dia,
porque uma aceitação que sobrevive ao seu achado é uma decisão que ninguém está mais conferindo.

O achado do próprio ambiente virtual se corrige do mesmo jeito, atualizando o pip:

```
ana@nft:~/audit$ ~/venv/bin/pip install -q --upgrade pip
ana@nft:~/audit$ ~/venv/bin/pip --version
pip 26.2.1 from /home/ana/venv/lib/python3.12/site-packages/pip (python 3.12)
ana@nft:~/audit$ ~/venv/bin/pip-audit; echo "exit $?"
No known vulnerabilities found
exit 0
```

O pip mais novo no dia em que você rodar é o que você recebe, então a sua versão pode ser posterior a
esta. A auditoria do ambiente está limpa.

## Onde ele roda

A regra da aula 1 só se sustenta se esta verificação for um passo do pipeline que monta a entrega:
`sh audit.sh`, reprovando o build numa saída diferente de zero, a cada mudança e **num agendamento**,
toda noite ou toda semana, no branch que está em produção. A execução agendada é a que percebe um
alerta novo contra um código que ninguém mexeu, e a falha dela vai para quem é dono das
dependências, não para quem por acaso fez o último push.
