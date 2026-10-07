---
title: As mesmas ideias numa CDN comercial
version: 1
---

Cloudflare, Fastly, Amazon CloudFront, Akamai, Bunny e as outras têm cada uma o próprio painel e os
próprios nomes, e por baixo são a borda desta aula repetida em centenas de cidades. **Nenhum dos
comandos abaixo foi rodado para este curso**: eles precisam de uma conta, de um domínio de verdade e, na
maioria, de um cartão. Estão aqui para você reconhecer cada ideia quando encontrar.

| nesta aula | numa CDN comercial |
|---|---|
| o Varnish na porta 6081 | as bordas da CDN, alcançadas apontando o DNS do site para a CDN, em geral com um `CNAME` |
| o Nginx em 127.0.0.1:8080 | a sua origem; o ideal é que ela só aceite requisições dos endereços da CDN |
| `X-Cache: HIT` / `MISS` | `CF-Cache-Status` na Cloudflare, `X-Cache` na CloudFront e na Fastly |
| `Age` | o mesmo cabeçalho, em todo lugar |
| tirar `utm_` da chave | configurações de "cache key" ou de "query string" |
| `PURGE` de uma URL | uma chamada à API de purge, ou um botão |
| `BAN` por `Surrogate-Key` | purge por surrogate key (Fastly) ou por cache tag (Cloudflare, Akamai) |
| `beresp.grace` | "serve stale" ou suporte a `stale-if-error` |

**O TLS termina na borda.** A conexão HTTPS do visitante é com a CDN, que guarda um certificado para o
seu domínio, muitas vezes obtido por ela mesma via ACME (aula 3), e abre uma segunda conexão com a
origem. Essa segunda conexão também deve ser HTTPS, com o certificado da origem conferido; uma CDN
configurada com TLS "flexível" ou sem verificação até a origem criptografa só metade do caminho, e a
metade que fica aberta é justamente a que um atacante na rede da origem escolheria.

**Uma limpeza é uma chamada de API com uma chave.** Uma típica, na Cloudflare, é assim (não rodada aqui):

```sh
curl -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/purge_cache" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{"tags": ["book-2", "listing"]}'
```

O token nesse cabeçalho consegue esvaziar o cache do site inteiro, o que transforma a requisição de cada
visitante numa requisição à origem, todas ao mesmo tempo. Trate-o como uma senha para a capacidade da
origem: restrito a limpar, fora do repositório, e trocado quando alguém sai da equipe.

**E o endereço da origem vira um segredo que vale guardar.** Se qualquer um alcança a origem
diretamente, consegue contornar a borda, o cache dela e as proteções dela. Restringir o firewall da
origem às faixas de endereço publicadas pela CDN, ou exigir um cabeçalho que só a CDN manda, fecha essa
porta; a origem desta aula escutando em `127.0.0.1` é a mesma ideia na escala de uma máquina.
