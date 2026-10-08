---
title: Lendo o log quando funciona, e quando não funciona
version: 1
---

Quando um túnel não sobe, o pessoal lê a configuração de novo, e os dois arquivos parecem certos para
quem os escreveu. **O log de uma negociação diz qual passo falhou**, e isso reduz a busca a poucas
linhas. O `swanctl --initiate` começa uma negociação na mão e imprime o log do daemon enquanto ela
acontece. Uma que funciona é a referência para ler uma quebrada. Derrube a conexão antes, como na seção
anterior, para que haja o que negociar:

```
ana@hq:~$ sudo swanctl --initiate --child lans
[IKE] initiating IKE_SA offices[3] to 198.51.100.2
[ENC] generating IKE_SA_INIT request 0 [ SA KE No N(NATD_S_IP) N(NATD_D_IP) N(FRAG_SUP) N(HASH_ALG) N(REDIR_SUP) ]
[NET] sending packet: from 203.0.113.2[500] to 198.51.100.2[500] (464 bytes)
[NET] received packet: from 198.51.100.2[500] to 203.0.113.2[500] (472 bytes)
[ENC] parsed IKE_SA_INIT response 0 [ SA KE No N(NATD_S_IP) N(NATD_D_IP) N(FRAG_SUP) N(HASH_ALG) N(CHDLESS_SUP) N(MULT_AUTH) ]
[CFG] selected proposal: IKE:AES_CBC_256/HMAC_SHA2_256_128/PRF_HMAC_SHA2_256/MODP_2048
[IKE] authentication of 'hq.example.com' (myself) with pre-shared key
[IKE] establishing CHILD_SA lans{4}
[ENC] generating IKE_AUTH request 1 [ IDi N(INIT_CONTACT) IDr AUTH SA TSi TSr N(MULT_AUTH) N(EAP_ONLY) N(MSG_ID_SYN_SUP) ]
[NET] sending packet: from 203.0.113.2[500] to 198.51.100.2[500] (272 bytes)
[NET] received packet: from 198.51.100.2[500] to 203.0.113.2[500] (224 bytes)
[ENC] parsed IKE_AUTH response 1 [ IDr AUTH SA TSi TSr ]
[IKE] authentication of 'branch.example.com' with pre-shared key successful
[IKE] IKE_SA offices[3] established between 203.0.113.2[hq.example.com]...198.51.100.2[branch.example.com]
[IKE] scheduling rekeying in 13711s
[IKE] maximum IKE_SA lifetime 15151s
[CFG] selected proposal: ESP:AES_GCM_16_256/NO_EXT_SEQ
[IKE] CHILD_SA lans{4} established with SPIs 9ab696f9_i 4ad97b9d_o and TS 192.168.10.0/24 === 192.168.20.0/24
initiate completed successfully
```

As linhas `[NET]` são as quatro mensagens da figura: 464 bytes indo, 472 voltando, 272 indo, 224
voltando. São os tamanhos de quadro do tshark menos os 42 bytes de Ethernet, IP e UDP em volta de cada
mensagem, 506 − 42 = 464. As duas rodadas foram separadas, e os tamanhos batem até o byte. As linhas
`[ENC]` listam o que cada mensagem levou, inclusive os dois hashes `NATD` que a próxima seção põe para
trabalhar, e `selected proposal` aparece uma vez para cada SA.

**`authentication of 'branch.example.com' with pre-shared key successful` é a linha que diz que o outro
lado sabia a chave.** A renegociação em 13711 segundos e o tempo de vida máximo em 15151 estão a 1440 um
do outro, um décimo de 14400: a folga que uma IKE SA tem para renegociar antes de ser abandonada. A
última linha é aquilo para que a troca existia, dois SPIs e `TS 192.168.10.0/24 === 192.168.20.0/24`.

## Uma chave errada

Tire a última letra, o `l` de `Quill`, do segredo de `branch` e recarregue-o, em `branch`:
`sudo sed -i 's/7294-Quill/7294-Quil/' /etc/swanctl/swanctl.conf && sudo swanctl --load-all`. Derrube a
conexão em `hq` de novo, e tente:

```
ana@hq:~$ sudo swanctl --initiate --child lans
initiate failed: establishing CHILD_SA 'lans' failed
[IKE] initiating IKE_SA offices[4] to 198.51.100.2
[ENC] generating IKE_SA_INIT request 0 [ SA KE No N(NATD_S_IP) N(NATD_D_IP) N(FRAG_SUP) N(HASH_ALG) N(REDIR_SUP) ]
[NET] sending packet: from 203.0.113.2[500] to 198.51.100.2[500] (464 bytes)
[NET] received packet: from 198.51.100.2[500] to 203.0.113.2[500] (472 bytes)
[ENC] parsed IKE_SA_INIT response 0 [ SA KE No N(NATD_S_IP) N(NATD_D_IP) N(FRAG_SUP) N(HASH_ALG) N(CHDLESS_SUP) N(MULT_AUTH) ]
[CFG] selected proposal: IKE:AES_CBC_256/HMAC_SHA2_256_128/PRF_HMAC_SHA2_256/MODP_2048
[IKE] authentication of 'hq.example.com' (myself) with pre-shared key
[IKE] establishing CHILD_SA lans{5}
[ENC] generating IKE_AUTH request 1 [ IDi N(INIT_CONTACT) IDr AUTH SA TSi TSr N(MULT_AUTH) N(EAP_ONLY) N(MSG_ID_SYN_SUP) ]
[NET] sending packet: from 203.0.113.2[500] to 198.51.100.2[500] (272 bytes)
[NET] received packet: from 198.51.100.2[500] to 203.0.113.2[500] (80 bytes)
[ENC] parsed IKE_AUTH response 1 [ N(AUTH_FAILED) ]
[IKE] received AUTHENTICATION_FAILED notify error
```

O veredito saiu primeiro, acima do log que ele resume. **A primeira troca deu certo**, porque o
IKE_SA_INIT não envolve chave. A resposta ao IKE_AUTH teve 80 bytes em vez de 224, levando só
`N(AUTH_FAILED)`: `branch` conferiu a prova de `hq` com o próprio segredo, e elas não bateram.

Ponha a letra de volta antes de seguir, com a substituição contrária, em `branch`:
`sudo sed -i 's/7294-Quil"/7294-Quill"/' /etc/swanctl/swanctl.conf && sudo swanctl --load-all`.

A notificação diz que a autenticação falhou, e não o motivo. **O lado que recusou sabe mais do que o
lado que pediu**, e o log do próprio `branch`, não capturado aqui, diria mais. Um `id` errado termina na
mesma notificação que um segredo errado, um caso também não capturado, então confira os dois nos dois
roteadores.

## Redes que não batem

A falha clássica entre duas empresas, ou entre roteadores de dois fabricantes, é um desacordo sobre
quais redes o túnel une. Mude o `remote_ts` de `hq` para `192.168.30.0/24`, uma rede que `branch` não
tem, com a conexão derrubada antes:
`sudo sed -i 's/192.168.20.0/192.168.30.0/' /etc/swanctl/swanctl.conf && sudo swanctl --load-all`.
Depois inicie:

```
ana@hq:~$ sudo swanctl --initiate --child lans 2>&1 | tail -5
[IKE] IKE_SA offices[5] established between 203.0.113.2[hq.example.com]...198.51.100.2[branch.example.com]
[IKE] scheduling rekeying in 14399s
[IKE] maximum IKE_SA lifetime 15839s
[IKE] received TS_UNACCEPTABLE notify, no CHILD_SA built
[IKE] failed to establish CHILD_SA, keeping IKE_SA
```

**A IKE SA foi estabelecida e a CHILD SA foi recusada**: `TS_UNACCEPTABLE`, seletores de tráfego
inaceitáveis. Os dois roteadores confiam um no outro e não levam nada, o estado que o pessoal chama de
"fase 1 de pé, fase 2 caída". O mesmo `sed` ao contrário, `s/192.168.30.0/192.168.20.0/`, devolve o
arquivo ao que era. A regra segura é fazer os seletores dos dois lados se espelharem
exatamente. O IKEv2 deixa quem responde estreitar um pedido para a parte que aceita, e as implementações
usam isso de jeitos diferentes. Um `/24` contra um `/16` pode funcionar com um par de roteadores e
falhar com outro.

Cada engano é recusado num passo diferente, e é isso que faz o log valer a leitura:

| o que está errado | onde para | o que o log de quem iniciou diz |
|---|---|---|
| nenhum algoritmo em comum | IKE_SA_INIT | `NO_PROPOSAL_CHOSEN` (não capturado aqui) |
| um segredo diferente, ou um `id` errado | IKE_AUTH | `AUTHENTICATION_FAILED` |
| redes diferentes | a CHILD SA, depois do IKE_AUTH | `TS_UNACCEPTABLE` |
| UDP 500 bloqueado no caminho | nada volta | retransmissões, depois tempo esgotado (não capturado aqui) |
