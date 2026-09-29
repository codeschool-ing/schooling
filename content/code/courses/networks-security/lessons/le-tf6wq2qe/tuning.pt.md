---
title: Ajustar sem ficar cego
version: 1
---

Uma implantação nova de detecção produz alertas demais, e a tentação é apagar as regras que mais
disparam. **Isso tira o ruído e o sinal juntos.** O ajuste fino (*tuning*) é a disciplina de silenciar
exatamente o que se entende e mais nada.

Aqui, o roteador da filial roda uma verificação de monitoramento que faz login na loja repetidamente, e a
regra de contagem dispara com ela a cada poucos minutos. A verificação é conhecida e legítima, então a
regra recebe a ordem de ignorar aquela origem, no arquivo de limiares do motor e não na regra:

```
root@sensor:~# cat /etc/suricata/threshold.config
suppress gen_id 1, sig_id 1000201, track by_src, ip 203.0.113.70
```

`suppress` para a assinatura 1000201, quando a origem é `203.0.113.70`. Todas as outras origens continuam
contando. Um sinal recarrega as regras sem parar o motor:

```
root@sensor:~# kill -USR2 $(cat /var/log/suricata/suricata.pid); sleep 6; grep -c "rule reload complete" /var/log/suricata/suricata.log
1
```

Então a filial envia o formulário quinze vezes, como `remote` fez antes:

```
ana@branch:~$ for i in $(seq 15); do curl -s -o /dev/null -d "user=ana" http://www.example.com/login; done
root@sensor:~# jq -r "select(.event_type==\"alert\" and .alert.signature_id==1000201) | .src_ip" /var/log/suricata/eve.json | sort | uniq -c
      5 203.0.113.50
```

**Continuam só os cinco alertas de `remote`.** Os quinze envios da filial, que teriam produzido mais
cinco, não produziram nenhum, e a regra segue intacta para todos os outros.

As ferramentas, da mais estreita à mais ampla, e a ordem em que recorrer a elas:

| ferramenta | silencia | use quando |
|---|---|---|
| `suppress` com `track` e um endereço | uma regra, para uma origem ou um destino | um sistema conhecido e legítimo dispara uma regra boa |
| um `threshold` no arquivo de limiares | a frequência com que uma regra dispara | a regra está certa e só é frequente demais |
| editar a regra | o que a regra casa | a própria regra é ampla demais, como o `/admin` da aula 14 |
| desativar a regra | tudo o que ela teria encontrado | a regra está errada para esta rede, e alguém anotou por quê |

**Toda supressão é uma decisão de ficar cego para alguma coisa**, então ela leva um comentário dizendo
quem a tomou, por quê, e quando deve ser revista. Um endereço suprimido por causa de uma verificação de
monitoramento desativada há dois anos é uma brecha por onde qualquer um usando esse endereço passa.
