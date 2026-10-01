---
title: Impressões digitais que pedem para você conferir
version: 1
---

Assinaturas e digests estão por toda a rede, quase sempre invisíveis:

| onde | o que é assinado ou passa por hash | aula |
|---|---|---|
| TLS | o servidor assina o handshake com a chave do seu certificado | 12, 13 |
| DNSSEC | os registros da zona | 8 |
| gerenciadores de pacotes | a lista de pacotes e seus digests, assinada pela distribuição | esta seção |
| SSH | o servidor assina cada conexão com sua chave de host | esta seção |
| WireGuard | o handshake, com a chave estática de cada par | 10 |

Um gerenciador de pacotes é o padrão da seção anterior em escala: o `apt` baixa uma lista com o
digest de cada pacote, confere a assinatura da lista contra as chaves da distribuição que já estão na
máquina, e confere cada pacote contra o seu digest. Um espelho que serve um pacote modificado não
consegue produzir também uma assinatura válida, e por isso a modificação é recusada.

**O SSH é onde se pede a uma pessoa que faça a conferência**, e em geral ela não faz. A primeira
conexão a um servidor mostra uma impressão digital (*fingerprint*) da chave de host dele e pergunta se
deve confiar nela. A impressão digital do próprio servidor, lida no `app` pelo seu administrador:

```
root@app:~# ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
256 SHA256:D69NpujcgW9pCTbA68lgiwW9k9fCvqO2C3xgQ55NwQk root@app (ED25519)
```

E o que o `admin` recebe quando pede a chave ao `app` pela rede:

```
ana@admin:~$ ssh-keyscan -t ed25519 app 2>/dev/null | ssh-keygen -lf -
256 SHA256:D69NpujcgW9pCTbA68lgiwW9k9fCvqO2C3xgQ55NwQk app (ED25519)
```

**A mesma impressão digital**, então a chave que veio pelo fio é a do `app`. Essa comparação é todo o
sentido da pergunta que o SSH faz, e ela só funciona quando a impressão digital foi obtida por outro
caminho: do administrador, de um sistema de configuração, do DNS assinado com DNSSEC. Responder *sim*
sem comparar é confiar em quem respondeu primeiro.

Um cliente que nunca viu a chave e não tem a quem perguntar recusa:

```
ana@admin:~$ ssh -o BatchMode=yes app true 2>&1 | head -3
Host key verification failed.
```

Essa recusa, num script que roda sem ninguém olhando, está correta, e a solução é distribuir as chaves
de host dos servidores para os clientes com antecedência, não desligar a conferência.
