---
title: Desvio, e as exceções que você anota
version: 1
---

**Uma linha de base é verdade no dia em que é aplicada e começa a se desviar no dia seguinte.**
Alguém resolve um problema urgente à mão, de noite, e a correção fica. No `web`, imagine um colega
que precisou entrar como root numa emergência e acrescentou uma linha num arquivo novo:

```
ana@web:~$ echo "PermitRootLogin yes" | sudo tee /etc/ssh/sshd_config.d/05-quickfix.conf
PermitRootLogin yes
ana@web:~$ sudo bash check.sh | grep FAIL; echo "failed: ${PIPESTATUS[0]}"
FAIL JAT-04 root may not log in over SSH
failed: 1
ana@admin:~$ ansible-playbook -i hosts.ini harden.yml | tail -2
web                        : ok=7    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

A verificação reprova o `JAT-04` na hora, porque `05-quickfix.conf` vem antes de `10-hardening.conf`
na ordem e o `sshd` guarda o primeiro valor que lê, exatamente como a aula 1 encontrou. **O playbook,
rodado de novo, diz `changed=0`.** Pediram a ele que garantisse que `10-hardening.conf` tenha quatro
linhas, e tem. Ninguém nunca perguntou a ele se o root consegue entrar, e ele não enxerga um arquivo
que não administra.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l02-fix-and-check\" aria-label=\"Dois programas olham o mesmo servidor SSH por lados diferentes. À esquerda, o playbook no admin grava o arquivo 10-hardening.conf e mais nada. No meio, o sshd lê cada arquivo de sshd_config.d em ordem de nome e guarda o primeiro valor de cada opção. Alguém acrescenta 05-quickfix.conf, que vem primeiro na ordem, e o login de root volta a ser permitido. À direita, o check.sh pergunta ao sshd -T o valor efetivo e informa JAT-04 como reprovado. O playbook, que só conhece o próprio arquivo, informa changed=0.\"><defs><marker id=\"l02-fix-and-check-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"170.0\" height=\"70.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"105.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">harden.yml</text><text x=\"105.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">grava o próprio arquivo</text><text x=\"105.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">changed=0</text><text x=\"105.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">não vê nada errado</text><rect x=\"255.0\" y=\"30.0\" width=\"210.0\" height=\"210.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">sshd_config.d/</text><rect x=\"270.0\" y=\"70.0\" width=\"180.0\" height=\"50.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"282.0\" y=\"86.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">05-quickfix.conf</text><text x=\"282.0\" y=\"104.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">PermitRootLogin yes</text><rect x=\"270.0\" y=\"130.0\" width=\"180.0\" height=\"50.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"282.0\" y=\"146.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10-hardening.conf</text><text x=\"282.0\" y=\"164.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">PermitRootLogin no</text><text x=\"360.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lidos em ordem de nome;</text><text x=\"360.0\" y=\"221.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o primeiro valor fica</text><path d=\"M190.0 75.0 L270.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l02-fix-and-check-dh-ah-paper-dim)\"></path><rect x=\"530.0\" y=\"40.0\" width=\"170.0\" height=\"70.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"615.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">check.sh</text><text x=\"615.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pergunta ao sshd -T</text><path d=\"M465.0 95.0 L530.0 80.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l02-fix-and-check-dh-ah-paper-dim)\"></path><text x=\"615.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">FAIL JAT-04</text><text x=\"615.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">vê o efeito</text><text x=\"360.0\" y=\"272.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a correção conhece o arquivo; a verificação conhece o resultado</text></svg>", "caption": "Um playbook só sabe informar o que mudou. Uma verificação informa o que é verdade."}
```

Esse é o argumento mais forte para manter a verificação separada da correção, e para rodar as duas
num horário: o playbook devolve o que é dele, e a verificação nota o que não é de ninguém. A aula 3
roda as duas em várias máquinas e num timer. Aqui a correção é uma decisão e não um comando: a
emergência foi real, e já passou? Foi, e passou, então o arquivo sai:

```
ana@web:~$ sudo rm /etc/ssh/sshd_config.d/05-quickfix.conf && sudo systemctl reload ssh && sudo bash check.sh | grep -c PASS
7
```

Os sete controles passam de novo. A correção duradoura é uma tarefa no playbook que remove qualquer
arquivo em `sshd_config.d` que não seja o dele, para que a próxima correção rápida dure só até a
próxima execução.

## Quando um controle não serve

Algumas recomendações estão erradas para uma máquina específica, e aplicá-las mesmo assim quebra o
trabalho. O Lynis sugeriu uma partição separada para `/home` e para `/var`. Num contêiner, e na
maioria das máquinas virtuais feitas a partir de uma imagem, não há o que particionar, e o risco que
a recomendação trata, um disco cheio derrubando o sistema, é tratado por monitoramento.

**Uma exceção é um controle que você decidiu não aplicar, anotado onde o próximo auditor vai
achar.** No Lynis esse lugar é um perfil, e `skip-test` é como um teste é posto de lado:

```
ana@web:~$ printf "skip-test=FILE-6310\n" | sudo tee /etc/lynis/custom.prf
skip-test=FILE-6310
ana@web:~$ sudo lynis audit system --quick --no-colors > lynis.txt 2>&1; grep -E "Hardening index|Tests performed|Skipped" lynis.txt; grep -c FILE-6310 lynis.txt
  Hardening index : 66 [#############       ]
  Tests performed : 256
0
```

O teste pulado não aparece mais no relatório da tela, que conta 256 testes. O índice **caiu**, de 69
para 66, porque um teste pulado muda o que o Lynis conta e a aritmética dele não premia deixar um de
fora. Se tivesse subido, a máquina também não estaria melhor. A linha do perfil registra que o teste
foi posto de lado; não registra nada sobre o porquê, e é isso que um auditor pergunta.

Uma exceção escrita traz quatro coisas, e uma organização as guarda ao lado da linha de base, não na
memória de alguém:

| | para `FILE-6310` no `web` |
|---|---|
| o que não é aplicado | partições separadas para `/home` e `/var` |
| por quê | a máquina é um contêiner; não há disco para particionar |
| o que cobre o risco no lugar | espaço livre monitorado, com alerta em 80 % |
| quem decidiu, e até quando | o administrador, revisto quando o portal mudar de hardware |

A última linha é a que impede uma exceção de virar permanente por padrão. **Uma exceção sem validade
é uma fraqueza com um motivo pendurado.** A aula 17 aplica a mesma regra a um patch que não pode ser
instalado no prazo, e a aula 16 a uma vulnerabilidade que não pode ser corrigida.
