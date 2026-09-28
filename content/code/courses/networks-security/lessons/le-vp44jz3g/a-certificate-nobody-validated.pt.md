---
title: Um certificado que ninguém validou
version: 1
---

Tudo nas aulas 10 a 12 se resume a uma decisão que o cliente toma: **este certificado, para este
nome, foi assinado por uma autoridade em que eu confio?** Pule essa verificação e a criptografia
continua acontecendo, perfeitamente, com quem quer que tenha respondido.

Em `remote`, uma máquina que não é a loja roda um servidor TLS com um certificado que fez para si
mesma, alegando ser `www.example.com`. O `laptop` se conecta a ela como se fosse a loja, do jeito que
o tráfego chega à máquina errada por uma resposta de DNS falsa (a aula 8) ou por uma mentira no ARP
(a aula 7):

```
ana@laptop:~$ curl -sS -o /dev/null --connect-to www.example.com:443:203.0.113.50:8443 https://www.example.com/; echo "exit $?"
curl: (60) SSL certificate problem: self-signed certificate
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
exit 60
```

O `curl` recusou: **`self-signed certificate`**, código de saída 60. O certificado alega o nome certo,
e a verificação falha mesmo assim, porque nada em que o cliente confia responde por ele:

```
ana@laptop:~$ openssl s_client -connect 203.0.113.50:8443 -servername www.example.com </dev/null 2>/dev/null | grep -E "^ *0 s:|^ *i:|^Verify return code"
 0 s:CN = www.example.com
   i:CN = www.example.com
Verify return code: 18 (self-signed certificate)
```

O titular e o emissor são o mesmo, `CN = www.example.com`; código de retorno 18. Agora a mesma
requisição com `-k`, que manda o `curl` pular a verificação:

```
ana@laptop:~$ curl -sk -o /dev/null -w "%{http_code} from %{remote_ip}\n" --connect-to www.example.com:443:203.0.113.50:8443 https://www.example.com/
200 from 203.0.113.50
```

**`200` vindo de `203.0.113.50`.** A conexão foi criptografada, e foi criptografada até a máquina
errada. Tudo o que for enviado por ela, uma senha, um cookie de sessão, um pedido, foi para quem
controla `remote`. Nada na tela a distinguia da loja de verdade.

Esse é todo o perigo de desligar a verificação, e o motivo de ela ser desligada com tanta frequência:
ela faz um erro sumir. O erro era a defesa. A correção para `self-signed certificate` em um serviço
interno é a da aula 12: um certificado emitido pela CA da empresa e a raiz dela no repositório de
confiança (trust store) do cliente. Nunca é `-k`.
