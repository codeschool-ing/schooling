---
title: Os limites, e fechando o óbvio
version: 1
---

**Um controle de DNS só barra programas que perguntam ao seu resolvedor.** Tudo nesta aula até aqui
depende disso. Um programa que pergunta a outro, ou que nem pergunta, passa ao lado, e um relato
honesto do controle começa por aí.

## Perguntando a outro

O `desk` foi apontado para o `dns` por uma linha em `/etc/resolv.conf`. Nada impede um programa de
ignorar esse arquivo e mandar a pergunta direto a outro resolvedor:

```
ana@desk:~$ dig +short @192.168.60.66 boletos-jatoba.example.net
198.51.100.23
```

O domínio parecido que o escritório bloqueou resolve para o endereço verdadeiro, porque o `trap`,
fazendo o papel da internet, nunca ouviu falar da lista da Jatobá. Numa rede de verdade o outro
resolvedor é o `8.8.8.8` ou qualquer um entre milhares parecidos, e muitos programas trazem o seu.

**Este dá para fechar, e o lugar de fechar é a rede, não a máquina.** Uma regra no switch que deixa o
tráfego de nomes chegar só ao resolvedor do escritório, e deixa só o resolvedor perguntar lá fora,
torna todo outro resolvedor inalcançável de dentro. No laboratório o switch é o `sw`, e o nftables
consegue filtrar o que atravessa a bridge dele:

```
root@sw:~# nft -f - <<'EOF'
table bridge dnsguard {
    chain forward {
        type filter hook forward priority filter; policy accept;
        ip daddr 192.168.60.53 udp dport 53 accept
        ip daddr 192.168.60.53 tcp dport 53 accept
        ip saddr 192.168.60.53 ip daddr 192.168.60.66 udp dport 53 accept
        udp dport 53 counter drop
        tcp dport 53 counter drop
    }
}
EOF
ana@desk:~$ dig +tries=1 +time=2 +short @192.168.60.66 boletos-jatoba.example.net; echo "exit $?"
;; communications error to 192.168.60.66#53: timed out
;; no servers could be reached
exit 9
ana@desk:~$ dig +short pagamento.cobranca-urgente.example.org
192.168.60.53
root@sw:~# nft list chain bridge dnsguard forward | grep counter
		udp dport 53 counter packets 1 bytes 95 drop
		tcp dport 53 counter packets 0 bytes 0 drop
```

As regras se leem em ordem. Perguntas ao `dns` passam; o próprio `dns` pode perguntar ao `trap`, o
encaminhador dele; qualquer outro pacote para a porta 53 é contado e descartado. A pergunta direta do
`desk` estourou o tempo, a pergunta comum continua funcionando, e o contador mostra o único pacote que
a guarda barrou. Numa rede de verdade a mesma regra mora no firewall da borda, que é onde a aula 10
põe regras de saída para um único host.

## Os que não se fecham assim

Restam três, e nenhum foi executado para este curso:

- **DNS sobre HTTPS** (DoH) manda as perguntas dentro de HTTPS comum na porta 443, misturadas ao
  tráfego web. Navegadores fazem isso por conta própria: Firefox e Chrome têm uma opção para isso, e
  os dois documentam uma **política corporativa** que a desliga em máquinas gerenciadas. Essa política
  é o controle, e ela pertence à configuração da aula 3, não ao resolvedor.
- **DNS sobre TLS** (DoT) usa a porta 853 e pode ser bloqueado como a 53.
- **Um endereço escrito dentro do programa** não precisa de nome nenhum. Nada no resolvedor o vê. As
  regras de saída da aula 10, que deixam um servidor falar só com os endereços de que o trabalho dele
  precisa, são o controle para isso.

Então o resolvedor é uma camada, barata e larga: cobre todas as máquinas de uma vez e todo programa
que se comporta de forma comum, e produz o melhor log único do que as máquinas do escritório tentaram
alcançar. Não é a única camada, e uma política que a trate como única deixa exatamente o tráfego que
um atacante cuidadoso escolheria.
