---
title: Quem pode usar uma chave, e para quê
version: 1
---

O token root da Ana faz qualquer coisa com `ipe-cpf`. O site e o suporte precisam cada um de uma
coisa, e o sentido de um serviço de gestão de chaves é que cada um receba exatamente isso. O
OpenBao expressa isso como **políticas**: um caminho, e as capacidades permitidas nele.

```hcl
# The website encrypts a CPF when a customer signs up, and never reads one.
path "transit/encrypt/ipe-cpf" {
  capabilities = ["update"]
}
```

```hcl
# Support decrypts a CPF to confirm who is calling, and never encrypts.
path "transit/decrypt/ipe-cpf" {
  capabilities = ["update"]
}
```

Cifrar é uma escrita em `transit/encrypt/ipe-cpf`, decifrar é uma escrita em
`transit/decrypt/ipe-cpf`; os dois são a capacidade `update`. Cada política nomeia um caminho.
Nada em nenhuma das duas menciona a configuração da chave, a rotação dela ou outra chave.

```
ana@lab:~/gov$ bao policy write site-app site-app.hcl
Success! Uploaded policy: site-app
ana@lab:~/gov$ bao policy write support support.hcl
Success! Uploaded policy: support
ana@lab:~/gov$ bao token create -policy=site-app -ttl=1h -field=token > site-app.token && wc -c site-app.token
26 site-app.token
ana@lab:~/gov$ bao token create -policy=support -ttl=1h -field=token > support.token && wc -c support.token
26 support.token
```

Cada política vai junto com um **token** que expira em uma hora. No laboratório os tokens vão para
arquivos, contados com `wc` em vez de impressos. Em produção cada programa receberia seu token
fazendo login no OpenBao com uma identidade própria — uma service account do Kubernetes, a
identidade de uma instância na nuvem, um certificado como o do `etl_loader` — e o token nunca seria
gravado em disco.

## As políticas, testadas

```
ana@lab:~/gov$ BAO_TOKEN=$(cat site-app.token) bao write -field=ciphertext transit/encrypt/ipe-cpf plaintext=MzcyLjg3NC4xNjgtMDk=; echo
vault:v1:u1P2QlncpgSzGvzSuNmTdKM7rQLM/PLQoxG116HwsHNKckNx9XvsRwOw
ana@lab:~/gov$ BAO_TOKEN=$(cat site-app.token) bao write transit/decrypt/ipe-cpf ciphertext=$(cat cpf.ct)
Error writing data to transit/decrypt/ipe-cpf: Error making API request.

URL: PUT https://bao.ipe.example:8200/v1/transit/decrypt/ipe-cpf
Code: 403. Errors:

* 1 error occurred:
	* permission denied


ana@lab:~/gov$ BAO_TOKEN=$(cat support.token) bao write -field=plaintext transit/decrypt/ipe-cpf ciphertext=$(cat cpf.ct) | base64 -d; echo
372.874.168-09
ana@lab:~/gov$ BAO_TOKEN=$(cat support.token) bao read transit/keys/ipe-cpf
Error reading transit/keys/ipe-cpf: Error making API request.

URL: GET https://bao.ipe.example:8200/v1/transit/keys/ipe-cpf
Code: 403. Errors:

* 1 error occurred:
	* permission denied
```

Quatro requisições, quatro respostas que dizem cada uma alguma coisa:

1. **O site cifra.** É o que a política dele permite.
2. **O site não decifra** — `403 permission denied` — nem o texto cifrado que a Ana fez um minuto
   antes com a mesma chave. Quem roubar o token do site consegue acrescentar CPFs cifrados ao banco
   e não consegue ler nenhum.
3. **O suporte decifra.** O CPF sai, para o atendente que está confirmando a identidade de quem
   ligou.
4. **O suporte não lê a configuração da chave.** Ele pode usar a chave e mais nada.

Essa separação é o que os cargos da aula 2 fizeram para tabelas, aplicado a uma chave. E não era
possível na aula 3: com o pgcrypto, quem decifrava também tinha a chave, e quem tinha a chave
cifrava e decifrava tudo, para sempre.
