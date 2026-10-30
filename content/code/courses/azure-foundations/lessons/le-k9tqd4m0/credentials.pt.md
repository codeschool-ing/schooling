---
title: Três jeitos de provar que é o programa
version: 1
---

**Um service principal faz login com uma credencial, e o Entra ID aceita três tipos.** Não são três
opções equivalentes. São uma escada, e o curso a sobe até o topo:

| credencial | o que o programa guarda | o que vaza se vazar |
|---|---|---|
| **client secret** | uma senha que o Entra ID gerou, válida até uma data | o próprio segredo: quem o tem é o programa até ele expirar |
| **certificado** | uma chave privada cuja metade pública está no registro | a chave privada, que é mais difícil de copiar sem querer do que um texto |
| **credencial federada** | nada: ela confia num token que outro provedor de identidade emitiu | nada guardado, porque nada foi guardado |

## Um segredo, e o pedido que ele faz

O **fluxo client credentials** é como um programa sem pessoa por trás faz login: ele manda o client id
e a sua prova ao `token_endpoint` do tenant, aquele que a lição 6 leu do documento de descoberta, e
recebe um **access token** para a API que citou. Aqui está esse pedido com o client id inventado da
loja e um segredo que claramente não é um, mandado para `organizations`:

```
ana@laptop:~/azure/deploy$ curl -sS -X POST https://login.microsoftonline.com/organizations/oauth2/v2.0/token -d client_id=00001111-aaaa-2222-bbbb-3333cccc4444 -d client_secret=not-a-secret -d grant_type=client_credentials -d scope=https://management.azure.com/.default | jq '{error, error_codes, error_description: (.error_description | split(" Trace ID")[0])}'
{
  "error": "unauthorized_client",
  "error_codes": [
    700016
  ],
  "error_description": "AADSTS700016: Application with identifier '00001111-aaaa-2222-bbbb-3333cccc4444' was not found in the directory 'f8cdef31-a31e-4b4a-93e4-5f571e91255a'. This can happen if the application has not been installed by the administrator of the tenant or consented to by any user in the tenant. You may have sent your authentication request to the wrong tenant."
}
```

**`AADSTS700016` é o Entra ID recusando um client id que ele não acha no diretório onde procurou.** O
segredo nem foi conferido, porque não havia aplicação contra a qual conferi-lo. O diretório citado na
mensagem é aquele que o Entra ID consultou para um pedido mandado a `organizations` sem tenant próprio;
um programa de verdade manda o pedido para o id do próprio tenant, e o erro então cita esse tenant. O
`scope` pediu um token para o Resource Manager, escrito como o endereço dele seguido de `/.default`,
que quer dizer "os papéis que este principal já tem lá, quaisquer que sejam".

Um segredo é o degrau de baixo porque **ele é um texto, e textos viajam**. Ele é colado num arquivo de
configuração, numa mensagem de chat, numa variável de CI, numa captura de tela. O Entra ID dá a todo
segredo uma data de validade, e a recomendação da própria Microsoft é menos de doze meses; o portal não
oferece nenhuma maior que dois anos. Isso limita por quanto tempo um segredo vazado funciona e
acrescenta um segundo problema: todo segredo expira um dia, muitas vezes numa sexta-feira, no meio de
alguma coisa. **Cada segredo tem um dono e um lembrete na agenda para a renovação**, ou não deveria
existir.

Um certificado é melhor porque a chave privada nunca precisa sair da máquina que a gerou: o registro
guarda só a metade pública. Ele ainda expira, e ainda precisa ser renovado e guardado.

## E nada

O topo da escada não guarda credencial nenhuma. **Uma credencial federada é uma regra no registro que
diz: confie num token emitido por este outro provedor de identidade, para este subject.** A próxima
seção a usa para o pipeline da loja, e a lição 8 mostra o caso em que o próprio Azure é o outro lado e
o programa nem chega a ver a regra.
