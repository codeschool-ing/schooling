---
title: Quanto você pode gastar
version: 1
---

Um limite de requisições limita a velocidade com que o dinheiro é gasto; um teto limita quanto.
Provedores definem um e deixam a conta definir um mais baixo. O da Anthropic, nas palavras dela:

```
# https://platform.claude.com/docs/en/api/rate-limits, read 2026-10-07
 233: Each of the Start, Build, and Scale tiers carries a monthly spend cap, which is the
      maximum your organization can spend on the API each calendar month. You can view your
      organization's monthly spend cap and set your own limit on the
 307: Enter a new value. Your spend limit cannot exceed your current tier's cap.
 311: You have reached your specified API usage limits
```

Um teto por nível, escolhido pelo provedor, e um limite de gasto abaixo dele, escolhido pela ana.
Passando de qualquer um, a API recusa com uma mensagem que diz isso e diz quando o acesso volta. O
teto existe para proteger o provedor e o saldo da conta; **o limite de gasto é o que a ana define
para se proteger**, e o valor certo dele é a estimativa mensal da aula 4 com folga para uma semana
ruim, não o teto do nível.

Um roteador acrescenta um mais estreito. A documentação do OpenRouter lista três fontes de limites
de crédito, e a segunda é a que importa para uma mesa com vários programas:

```
# OpenRouterTeam/docs@3e840a21 api_reference/limits.mdx
 130: 2. **Per-key credit limits**, an optional spending cap configured on an individual API
      key. The `limit`, `limit_reset`, and `limit_remaining` fields in the `GET /api/v1/key`
      response above describe this cap and how much of it remains.
```

**Um limite por chave.** A chave de um programa pode secar enquanto a de outro continua funcionando.
O openrouter.ai foi recusado pela rede da máquina em que este curso foi gravado, então não dá para
esbarrar no limite aqui; a documentação diz o que um programa vê quando esbarra:

```
# OpenRouterTeam/docs@3e840a21 api_reference/limits.mdx
 164: - **Check `error.metadata.limit_source`** in the response body.
      `openrouter_in_flight_budget` means your running and recently completed requests filled
      your [in-flight spending budget](#in-flight-spending-budget), not your balance: wait for
      the `Retry-After` header and retry. `openrouter_key_limit` means the API key's credit
      limit is exhausted. `openrouter_credits` means your balance cannot cover the request, or
      the single request is too expensive for your in-flight budget.
```

O erro traz um `limit_source` que diz qual limite foi: o da chave, o saldo da conta, ou o orçamento
que o OpenRouter reserva para as requisições ainda em andamento. Esse último existe por causa de uma
brecha que todo teto tem, e a documentação a explica:

```
# OpenRouterTeam/docs@3e840a21 api_reference/limits.mdx
 135: OpenRouter charges a request when it finishes, so many requests running at the same time
      could commit more than your balance covers before any of them settles. To prevent that,
      OpenRouter estimates each paid request's token cost up front, at the endpoint's prices:
      the input tokens, plus the completion tokens allowed by `max_tokens` up to a fixed per-
      request cap (the cap is used when `max_tokens` is not set). Only token prices are
      estimated; per-request fees, plugin charges, and image pricing are not part of the
      estimate, so a request whose cost has no token component is not held. The estimate is
      held against your account while the request runs. When the request completes or fails,
      the hold is replaced by the request's actual cost for a short settlement window, and
      then released.
```

Uma requisição é cobrada quando **termina**, então um limite conferido quando ela começa pode ser
ultrapassado pelas requisições que já estão rodando. O OpenRouter estreita a brecha reservando uma
estimativa, feita a partir do `max_tokens`; uma requisição sem ele é estimada por um teto fixo.
Nenhum teto em lugar nenhum pode ser lido como promessa ao centavo: **um limite para a próxima
requisição, não a que já está rodando.**
