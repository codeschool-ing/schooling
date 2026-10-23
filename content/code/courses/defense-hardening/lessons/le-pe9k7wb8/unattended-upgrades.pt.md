---
title: Atualizações que ninguém precisa digitar
version: 1
---

**Na maioria das máquinas, o número certo de pessoas envolvidas numa atualização de segurança é
zero.** O Ubuntu instala o `unattended-upgrades` por padrão, e ele roda uma vez por dia: atualiza as
listas de pacotes, escolhe as atualizações que vêm de origens em que pode confiar e as instala. Numa
estação ou num servidor em que uma correção de segurança é mais urgente que qualquer risco que ela
traga, esse é o processo de patches, e os anéis são o que ele faz entre as máquinas do escritório,
porque cada uma roda num momento um pouco diferente.

Dois arquivos decidem o que ele faz. O `20auto-upgrades` o liga; o `50unattended-upgrades` lista as
**origens** de onde ele pode instalar, e no Ubuntu essa lista tem a versão do sistema e as
atualizações de segurança dela e mais nada. O repositório do escritório não está nela, então
acrescente-o, batendo com a `Origin` que o arquivo `Release` recebeu. Antes, o `web` volta para a
`1.0`, para haver o que atualizar:

```
root@web:~# apt-get install -y -q --allow-downgrades jatoba-health=1.0 >/dev/null 2>&1; dpkg-query -W jatoba-health
jatoba-health	1.0
root@web:~# printf 'Unattended-Upgrade::Origins-Pattern { "origin=Jatoba"; };\n' > /etc/apt/apt.conf.d/51jatoba; cat /etc/apt/apt.conf.d/51jatoba /etc/apt/apt.conf.d/20auto-upgrades
Unattended-Upgrade::Origins-Pattern { "origin=Jatoba"; };
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
root@web:~# unattended-upgrade --dry-run --debug 2>&1 | grep -E "^(Allowed origins|Packages that will be upgraded|All upgrades)"
Allowed origins are: o=Ubuntu,a=noble, o=Ubuntu,a=noble-security, o=UbuntuESMApps,a=noble-apps-security, o=UbuntuESM,a=noble-infra-security, origin=Jatoba
Packages that will be upgraded: jatoba-health
All upgrades installed
```

`--dry-run --debug` informa o que uma execução de verdade faria, sem fazer. **Allowed origins** lista
as quatro do Ubuntu e a do escritório, e a linha seguinte cita o `jatoba-health` como o pacote que ele
atualizaria. A última linha diz `All upgrades installed`; numa simulação isso só quer dizer que a
instalação simulada deu certo, e o `dpkg-query` ainda informaria `1.0`.

## O que ele não deve tocar

Atualizações automáticas servem para pacotes cujas atualizações são rotina e cuja falha é barata.
Servem mal onde uma atualização muda comportamento, reinicia algo com usuários conectados ou precisa
de um passo que uma pessoa tem de dar. As opções em `50unattended-upgrades` cobrem os casos comuns:

| opção | o que faz |
|---|---|
| `Unattended-Upgrade::Package-Blacklist` | pacotes que ele nunca pode atualizar sozinho, por nome ou padrão |
| `Unattended-Upgrade::Automatic-Reboot` | se ele pode reiniciar quando uma atualização pede, e `Automatic-Reboot-Time` para quando |
| `Unattended-Upgrade::Mail` | um endereço que recebe um relatório de cada execução |

**Uma máquina que se atualiza sozinha ainda precisa de alguém que leia o que ela fez.** O log fica em
`/var/log/unattended-upgrades/`, e o inventário da aula 18, que lê as versões instaladas de toda
máquina, é o que diz se toda máquina de fato fez isso. Um notebook desligado há um mês não fez.
