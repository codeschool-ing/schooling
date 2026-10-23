---
title: Um resolvedor para o escritório
version: 1
---

**Um resolvedor responde perguntas sobre nomes que não são dele perguntando aos servidores que são
donos deles.** A Jatobá é dona de `jatoba.example`, então o resolvedor dela consegue responder por
`web` e `desk` a partir da própria configuração. Todo o resto, `example.net` e o resto da internet,
ele tem de procurar em outro lugar.

O laboratório não tem internet, então nesta aula **o `trap` faz o papel dos servidores de nomes da
internet**. Ele responde por alguns nomes de fora, e o escritório vai decidir mais adiante que alguns
deles são perigosos. Escreva a configuração dele como root no `trap`, inteira, e suba o Unbound, o
resolvedor que já está instalado em todas as máquinas do laboratório:

```
root@trap:~# cat > /etc/unbound/unbound.conf.d/internet.conf <<'EOF'
server:
    interface: 0.0.0.0
    access-control: 0.0.0.0/0 allow
    module-config: "iterator"
    local-zone: "example.net." static
    local-data: "boletos-jatoba.example.net. A 198.51.100.23"
    local-data: "jatoba.contabil-nuvem.example.net. A 198.51.100.80"
    local-data: "outro.contabil-nuvem.example.net. A 198.51.100.81"
    local-zone: "example.org." static
    local-data: "pagamento.cobranca-urgente.example.org. A 198.51.100.66"
EOF
root@trap:~# rm /etc/unbound/unbound.conf.d/root-auto-trust-anchor-file.conf; systemctl enable --now unbound 2>&1 | tail -1; systemctl is-active unbound
Created symlink /etc/systemd/system/multi-user.target.wants/unbound.service → /usr/lib/systemd/system/unbound.service.
active
```

`local-zone ... static` faz o `trap` responder por esses dois domínios a partir das linhas abaixo
dele e por mais nada. O arquivo `root-auto-trust-anchor-file.conf` é removido porque pede ao Unbound
para buscar e validar a raiz do DNSSEC, as assinaturas que provam que uma resposta é genuína, e sem
internet essa busca falha e o serviço não sobe. **Num resolvedor de verdade esse arquivo fica**, e a
validação que ele liga é mais um motivo para ter o seu próprio.

## O resolvedor do escritório

Agora o `dns`, a máquina cujo trabalho é este. A configuração dele diz quem pode perguntar, o que ele
responde sozinho e para onde manda todo o resto:

```
root@dns:~# cat > /etc/unbound/unbound.conf.d/jatoba.conf <<'EOF'
server:
    interface: 0.0.0.0
    access-control: 192.168.60.0/24 allow
    module-config: "respip iterator"
    log-queries: yes
    local-zone: "jatoba.example." static
    local-data: "web.jatoba.example. A 192.168.60.10"
    local-data: "desk.jatoba.example. A 192.168.60.20"
    local-data: "dns.jatoba.example. A 192.168.60.53"
forward-zone:
    name: "."
    forward-addr: 192.168.60.66
EOF
root@dns:~# rm /etc/unbound/unbound.conf.d/root-auto-trust-anchor-file.conf; unbound-checkconf
unbound-checkconf: no errors in /etc/unbound/unbound.conf
root@dns:~# systemctl enable --now unbound 2>&1 | tail -1; systemctl is-active unbound
Created symlink /etc/systemd/system/multi-user.target.wants/unbound.service → /usr/lib/systemd/system/unbound.service.
active
```

Cada bloco faz uma coisa:

| linha | o que faz |
|---|---|
| `interface: 0.0.0.0` | escuta em todas as interfaces, não só no loopback da máquina |
| `access-control: 192.168.60.0/24 allow` | responde ao segmento do escritório e recusa todo o resto, para o resolvedor não ficar aberto ao mundo |
| `module-config: "respip iterator"` | a cadeia de processamento; o `respip` é o que a próxima seção precisa para aplicar uma lista de bloqueio |
| `log-queries: yes` | uma linha por pergunta, com o endereço de quem perguntou |
| `local-zone` e `local-data` | os nomes do próprio escritório, respondidos aqui |
| `forward-zone` com `name: "."` | todo o resto vai para `192.168.60.66`, que faz o papel da internet |

O `unbound-checkconf` lê a configuração inteira e reclama antes de qualquer reinício, o mesmo hábito
do `sshd -t` da aula 1.

## Apontando o desk para ele

Uma máquina encontra o resolvedor em `/etc/resolv.conf`. Numa rede de verdade esse arquivo é escrito
pelo DHCP ou pelo systemd-resolved; aqui você o escreve à mão, como root no `desk`, e pergunta de
novo:

```
root@desk:~# printf "nameserver 192.168.60.53\nsearch jatoba.example\n" > /etc/resolv.conf
ana@desk:~$ dig +short web.jatoba.example; dig +short boletos-jatoba.example.net
192.168.60.10
198.51.100.23
ana@desk:~$ dig www.ubuntu.com | grep status
;; ->>HEADER<<- opcode: QUERY, status: SERVFAIL, id: 62612
```

O nome do próprio escritório vem do `dns`, um nome de fora vem pelo encaminhamento, e um nome por que
ninguém no laboratório responde falha com `SERVFAIL`, que é o que um resolvedor diz quando não
conseguiu resposta nenhuma.

## O log é a primeira vitória

Cada uma dessas perguntas agora está num lugar só:

```
root@dns:~# journalctl -u unbound -o cat | grep "info: 192" | cut -d" " -f3-
192.168.60.20 web.jatoba.example. A IN
192.168.60.20 boletos-jatoba.example.net. A IN
192.168.60.20 www.ubuntu.com. A IN
```

**Quem perguntou, e pelo quê**, uma linha cada. Antes disso, as mesmas perguntas iam do `desk` para o
Google e não deixavam rastro em nenhuma máquina da Jatobá. Um log de resolvedor é a telemetria mais
barata que uma empresa pequena pode ter: não custa agente em máquina nenhuma, e quando a pergunta da
aula 8 aparecer, "que máquinas falaram com este domínio semana passada", é ele que sabe responder.
