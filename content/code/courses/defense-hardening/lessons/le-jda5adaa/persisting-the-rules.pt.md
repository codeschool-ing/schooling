---
title: Regras que sobrevivem a um reboot
version: 1
---

**`nft -f` muda o kernel em execução e mais nada.** Reinicie o `web` e a tabela some junto com a
memória em que vivia; o portal volta com todas as portas abertas. Regras viram permanentes sendo
carregadas no boot, e no Ubuntu isso é trabalho do serviço `nftables`, que carrega o
`/etc/nftables.conf`. O Ubuntu traz o arquivo com chains vazias e o serviço desabilitado, e é por
isso que nada era filtrado antes desta aula.

Copie o arquivo conferido para o lugar e habilite o serviço, com `--now` para ele também carregar o
arquivo na hora:

```
ana@web:~$ sudo cp nftables.conf /etc/nftables.conf && sudo systemctl enable --now nftables 2>&1 | sed "s/ → .*//"
Created symlink /etc/systemd/system/sysinit.target.wants/nftables.service
ana@web:~$ systemctl is-active nftables; sudo nft list ruleset | grep -c accept
active
5
ana@web:~$ sudo systemctl restart nftables && sudo nft list ruleset | grep -E "policy|reject"
		type filter hook input priority filter; policy drop;
ana@admin:~$ ssh web hostname
web
```

O serviço está ativo, e as cinco regras `accept` estão no kernel. O reinício é o teste que importa:
ele joga fora o que está carregado e carrega o arquivo de novo, exatamente como um boot faria. O
experimento com `reject` da seção anterior foi carregado à mão, e depois do reinício sumiu: só resta
o `policy drop` do arquivo. **O que está no arquivo é o que a máquina roda depois do próximo
reboot**, seja o que for que alguém tenha carregado desde então, e o `admin` continua entrando.

## Três hábitos

**Confira antes de instalar.** `nft -c -f /etc/nftables.conf` antes de todo reinício. Um arquivo que
não passa deixa o serviço falho, e na maioria dos sistemas um serviço de firewall falho quer dizer
nenhum firewall.

**Mantenha o arquivo sob o mesmo controle que a linha de base.** O conjunto de regras é configuração
como o `sshd_config.d`, e o playbook da aula 3 é o jeito certo de pô-lo em todo servidor e de devolvê-lo
quando alguém o edita à mão. Um firewall mudado no console durante um incidente e nunca escrito de
volta é desvio com uma porta aberta.

**Saiba o que mais administra o firewall.** O Ubuntu também traz o `ufw`, uma interface mais simples
que escreve as próprias regras, e Docker, Kubernetes e fail2ban acrescentam as deles. Duas
ferramentas que se acham donas do conjunto de regras desfazem uma à outra. No `web`, o `ufw` está
instalado e inativo, e o arquivo do `nftables` é a única fonte; no momento em que uma segunda
ferramenta for ligada, o `nft list ruleset` é onde você descobre o que o kernel de fato faz.

A aula 11 acrescenta regras a esta tabela automaticamente, banindo um endereço depois de logins
falhos repetidos, e a aula 10 filtra a outra direção, o que o próprio `web` pode enviar.
