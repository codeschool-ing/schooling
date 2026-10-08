---
title: Limpar ou reconstruir
version: 1
---

Depois da auditoria, dois caminhos para um host que o invasor controlou:

| | limpar | reconstruir |
|---|---|---|
| **o que acontece** | remover cada item que a auditoria achou, manter o servidor | um servidor novo a partir do padrão de instalação, dados restaurados do backup |
| **confia** | que a auditoria achou tudo | que o padrão e o backup estão limpos |
| **custa** | pouco tempo parado | horas de trabalho e uma parada planejada |
| **serve para** | uma invasão contida, bem entendida, sem acesso de administrador | qualquer caso em que o invasor possa ter tido root, ou o escopo não esteja claro |

A pergunta que decide é a segunda linha. **Uma auditoria acha o que procura**, e um invasor com root poderia ter
mudado qualquer coisa, inclusive as ferramentas que a auditoria usa. Na quinta a conta era de um usuário comum,
e a auditoria achou uma chave; limpar é defensável. A aula 13 ainda assim marcou uma reconstrução do `gw`,
porque ninguém consegue provar uma negativa sobre um host que um estranho usou por uma hora, e reconstruir é
barato quando o padrão é um script.

O padrão do laboratório *é* um script, então reconstruir são dois comandos, e isso mostra a armadilha na hora:

```
root@soc:~# bash soclab.sh down
root@soc:~# bash soclab.sh up
root@soc:~# ip netns exec fw nft list chain ip fw forward
table ip fw {
	chain forward {
		type filter hook forward priority filter; policy accept;
		ct state new log prefix "fw-new " group 1
	}
}
root@soc:~# ip -n outside addr add 203.0.113.150/24 dev eth0
root@soc:~# ip netns exec outside python3 -m http.server 8080 >/dev/null 2>&1 &
root@soc:~# ip netns exec files curl -s -m 5 -o /dev/null -w "%{http_code}\n" http://203.0.113.200:8080/
200
```

A cadeia tem só a regra de log da aula 1. **A regra de saída sumiu**, porque ela vivia no firewall em execução,
não no `soclab.sh`, e o servidor de arquivos alcança `203.0.113.200` de novo com um `200`. Esse é o formato
geral da armadilha: **reconstrua pela receita antiga e você reconstrói o buraco antigo.** Todo conserto feito
durante a resposta precisa ir para a fonte de onde a próxima instalação é feita.

Os arquivos de log continuam lá: eles vivem em `/var/log/soclab` no host, fora dos namespaces, que é o ponto da
aula 3 sobre log remoto, chegando por outra direção. Reconstrua os sistemas, guarde a evidência.

No laboratório, a fonte da regra é um arquivo de uma linha. Escreva-o como `files-egress.nft`:

```
add rule ip fw forward ip saddr 192.168.20.10 oifname "eth0" ip daddr != 203.0.113.150 counter drop comment "INC-2026-014 files egress"
```

O `nft -f` lê um arquivo de comandos `nft`, o mesmo `add rule` que a aula 13 digitou:

```
root@soc:~# cat files-egress.nft
add rule ip fw forward ip saddr 192.168.20.10 oifname "eth0" ip daddr != 203.0.113.150 counter drop comment "INC-2026-014 files egress"
root@soc:~# ip netns exec fw nft -f files-egress.nft
root@soc:~# ip netns exec files curl -s -m 5 -o /dev/null -w "%{http_code}\n" http://203.0.113.200:8080/; echo "exit $?"
000
exit 28
root@soc:~# ip netns exec files curl -s -m 5 -o /dev/null -w "%{http_code}\n" http://203.0.113.150:8080/
200
```

Fechado de novo: `000` e saída `28` para `203.0.113.200`, `200` para o backup. Numa empresa, o arquivo estaria
na configuração do firewall sob controle de versão, e a reconstrução o leria sem ninguém precisar lembrar.
