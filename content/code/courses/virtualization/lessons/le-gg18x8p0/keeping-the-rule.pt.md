---
title: Mantendo a regra depois de reiniciar
version: 1
---

Uma regra carregada com `nft -f` vive na memória, e **o próximo reinício do host a esquece**. O lugar
óbvio para guardá-la é o `/etc/nftables.conf`, que o Ubuntu carrega no boot, e ele tem uma armadilha na
terceira linha:

```
ana@host:~$ grep -n "flush ruleset" /etc/nftables.conf
3:flush ruleset
```

O `flush ruleset` esvazia **todas** as tabelas, incluindo as que o libvirt preencheu para as redes dele.
Colar a regra do laboratório nesse arquivo funciona no primeiro boot e remove as regras do libvirt no dia
em que alguém recarregar o firewall.

Um arquivo próprio e um pequeno serviço que o carrega no boot mantêm os dois separados. **Nenhum destes
comandos foi rodado para esta aula**:

```sh
sudo install -m 644 labguard.nft /etc/labguard.nft
sudo tee /etc/systemd/system/labguard.service >/dev/null <<'EOF'
[Unit]
Description=Keep lab guests away from the host's services

[Service]
Type=oneshot
ExecStart=/usr/sbin/nft -f /etc/labguard.nft
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable labguard.service
```

A regra combina pelo **`iifname`**, a interface pelo nome, e é por isso que ela pode carregar no boot
antes de a labnet existir: o `iif` procuraria a interface na hora de carregar a regra e falharia.

No Windows e no macOS a ideia é a mesma e a ferramenta é outra: o firewall do próprio host, instruído a
recusar o que chega pelo adaptador da rede virtual. A resposta mais simples lá é a da próxima seção: uma
rede em que o host não tem endereço nenhum.
