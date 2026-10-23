---
title: Listas que outra pessoa mantém
version: 1
---

**Ninguém num escritório de dez pessoas consegue achar domínios perigosos à mão.** Novos são
registrados todo dia, vivem algumas horas e somem antes que alguém os anotasse. Por isso os nomes de
uma lista de bloqueio de verdade vêm quase todos de **fontes de reputação**: listas mantidas por
organizações que vigiam phishing, distribuição de malware e tráfego de comando e controle como
ofício, e publicam o que encontram.

Elas vêm em alguns formatos, e um resolvedor aceita a maioria:

| formato | o que é | como chega ao resolvedor |
|---|---|---|
| um feed RPZ | uma zona de política mantida por outra pessoa | uma transferência de zona, `AXFR`/`IXFR`, do servidor dela, atualizada sozinha |
| uma lista no estilo hosts | um nome por linha, às vezes com `0.0.0.0` na frente | um script que a transforma em arquivo de zona |
| um resolvedor protetor | um resolvedor público que aplica as próprias listas, como o Quad9 | o encaminhamento do seu resolvedor aponta para ele |
| um serviço de fornecedor | um produto comercial com categorias e um console | o agente do fornecedor, ou o resolvedor encaminha para ele |

O URLhaus, do abuse.ch, publica uma RPZ de domínios usados para entregar malware; a Spamhaus vende
feeds RPZ separados por categoria; o Quad9 bloqueia o que os parceiros dele informam e responde todo
o resto. **Nenhum deles foi usado neste curso**: o laboratório não tem internet, e cada um é descrito
aqui a partir da documentação de quem o publica. No Unbound, um feed transferido de outro servidor é
o mesmo bloco `rpz:` com linhas `primary:` dizendo o servidor em vez de um `zonefile:`; as linhas que
você escreve são quase as mesmas, e o que muda é quem decide o que entra nelas.

## O preço da lista de outra pessoa

Um feed é o julgamento de outra pessoa sobre o que é perigoso, aplicado aos seus usuários sem
perguntar a eles. Mais cedo ou mais tarde ele vai listar algo de que o seu escritório precisa. Aqui
o feed decidiu que o domínio inteiro de um provedor de nuvem é perigoso, o que acontece quando um
provedor hospeda alguns clientes ruins no meio de muitos bons:

```
root@dns:~# echo "*.contabil-nuvem.example.net    CNAME ." >> /etc/unbound/feed.zone; systemctl restart unbound
ana@desk:~$ dig jatoba.contabil-nuvem.example.net | grep status
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 3939
```

`jatoba.contabil-nuvem.example.net` é onde a Jatobá mantém o sistema contábil. A linha foi
acrescentada ao arquivo do feed para a demonstração; numa instalação de verdade ela teria chegado com
a transferência da manhã, e o primeiro sinal seria um telefonema.

**A resposta é uma lista de permissão, mantida por você e lida antes do feed.** Uma zona de política
pode dizer `rpz-passthru.`, que quer dizer "responda a verdade para este", e o Unbound aplica as
zonas de política na ordem em que a configuração as lista, parando na primeira que bater. Então a
lista de permissão é uma zona própria, e o bloco `rpz:` dela vem primeiro:

```
root@dns:~# cat > /etc/unbound/allow.zone <<'EOF'
$TTL 300
@ SOA localhost. hostmaster.jatoba.example. 1 3600 600 86400 300
@ NS localhost.
jatoba.contabil-nuvem.example.net  CNAME rpz-passthru.
EOF
root@dns:~# sed -i 's/^rpz:$/rpz:\n    name: allow.jatoba.example\n    zonefile: \/etc\/unbound\/allow.zone\n    rpz-log: yes\n    rpz-log-name: allow\nrpz:/' /etc/unbound/unbound.conf.d/jatoba.conf; sed -n '/^rpz:/,$p' /etc/unbound/unbound.conf.d/jatoba.conf
rpz:
    name: allow.jatoba.example
    zonefile: /etc/unbound/allow.zone
    rpz-log: yes
    rpz-log-name: allow
rpz:
    name: feed.jatoba.example
    zonefile: /etc/unbound/feed.zone
    rpz-log: yes
    rpz-log-name: feed
root@dns:~# unbound-checkconf && systemctl restart unbound; systemctl is-active unbound
unbound-checkconf: no errors in /etc/unbound/unbound.conf
active
ana@desk:~$ dig +short jatoba.contabil-nuvem.example.net; dig outro.contabil-nuvem.example.net | grep status
198.51.100.80
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 46161
root@dns:~# journalctl -u unbound -o cat | grep "rpz: applied" | tail -2 | cut -d" " -f3-
rpz: applied [allow] jatoba.contabil-nuvem.example.net. rpz-passthru 192.168.60.20@56887 jatoba.contabil-nuvem.example.net. A IN
rpz: applied [feed] *.contabil-nuvem.example.net. rpz-nxdomain 192.168.60.20@58254 outro.contabil-nuvem.example.net. A IN
```

O endereço do escritório volta a responder; o resto do provedor continua bloqueado, porque ninguém
decidiu que não deveria estar. E o log diz que zona decidiu em cada caso, `allow` no primeiro e `feed`
no segundo. **Uma entrada na lista de permissão é uma decisão que tem dono**: precisa de um motivo, de
um nome ao lado e de uma data para olhar de novo, porque o domínio permitido hoje pode ser o que é
tomado ano que vem.

Três hábitos mantêm um feed útil em vez de fonte de chamados:

- **Observe antes de bloquear.** O Unbound pode registrar o que uma zona teria feito sem fazer, com
  `rpz-action-override: disabled`; uma semana disso mostra o que um feed novo quebraria.
- **Prefira feeds estreitos a categorias amplas.** "Distribuição conhecida de malware" é uma lista
  curta com poucos erros; "domínios registrados recentemente" bloqueia milhares de sites legítimos por
  semana.
- **Deixe o bloqueio visível.** A página de uma linha do sinkhole diz à pessoa o que aconteceu e a quem
  ligar. Um `NXDOMAIN` silencioso parece uma internet quebrada.
