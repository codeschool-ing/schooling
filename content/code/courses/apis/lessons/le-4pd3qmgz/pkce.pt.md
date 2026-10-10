---
title: "PKCE: a prova de que o código é seu"
version: 1
---

**A defesa óbvia para um código é o segredo do cliente: só o cliente verdadeiro consegue trocá-lo,
porque só ele conhece o segredo.** Isso vale para um programa num servidor. Falha para um **cliente
público**, que é qualquer app cujo código você pode baixar: um app de celular, ou um app de página
única rodando no navegador. Um segredo embutido num desses está em toda cópia, e qualquer um o
extrai.

Clientes públicos também têm um redirecionamento mais fraco. Um app de celular recebe o código num
endereço como `com.example.reader:/callback`, e em alguns sistemas um segundo app pode registrar o
mesmo endereço e receber o redirecionamento no lugar dele. Foi para esse caso que o PKCE foi
escrito, na RFC 7636 (2015): um código pego no caminho, por alguém que também sabe tudo o que o app
traz embutido.

**O PKCE (Proof Key for Code Exchange, pronunciado "pixy") prende o código a um segredo criado na
hora para esta única entrada.** Antes do passo 1, o cliente gera uma string aleatória, o **code
verifier**, e a guarda. Para `/authorize` ele envia só o **code challenge**: o SHA-256 do verifier,
escrito em base64url. Em `/token` ele envia o próprio verifier, e o servidor de autorização calcula
o hash dele e compara o resultado com o challenge que guardou junto do código.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"O PKCE em dois momentos. Em /authorize o cliente envia só o code challenge, o SHA-256 do seu verifier, pelo navegador, onde qualquer um pode lê-lo; o servidor de autorização o guarda com o código. Em /token o cliente envia o código e o verifier diretamente; o servidor calcula o hash do verifier e compara. Um código copiado chega sem o verifier e é recusado com invalid_grant.\"><defs><marker id=\"l09-pkce-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"120\" width=\"160\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"100.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">client</text><text x=\"100.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">guarda o verifier</text><rect x=\"285\" y=\"20\" width=\"150\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">navegador</text><text x=\"360.0\" y=\"53.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">qualquer um pode ler</text><rect x=\"530\" y=\"120\" width=\"170\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"615.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">servidor de autorização</text><text x=\"615.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">guarda o challenge</text><line x1=\"100\" y1=\"118\" x2=\"283\" y2=\"52\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l09-pkce-ah)\"></line><text x=\"128\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">code_challenge</text><text x=\"128\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">SHA-256 do verifier</text><line x1=\"437\" y1=\"52\" x2=\"615\" y2=\"118\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l09-pkce-ah)\"></line><text x=\"560\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">1 · em /authorize</text><line x1=\"182\" y1=\"150\" x2=\"528\" y2=\"150\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l09-pkce-ah)\"></line><text x=\"355.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">code + code_verifier</text><text x=\"355\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">2 · em /token, direto</text><text x=\"615\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">S256(verifier) == challenge?</text><rect x=\"270\" y=\"222\" width=\"180\" height=\"54\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"360.0\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um código copiado</text><text x=\"360.0\" y=\"257.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sem verifier</text><line x1=\"452\" y1=\"249\" x2=\"560\" y2=\"214\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l09-pkce-ah)\"></line><text x=\"615\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">invalid_grant</text><text x=\"615\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">recusado</text></svg>", "caption": "O challenge pode ser lido no caminho; o verifier é enviado uma vez, direto, depois que o código existe. Um código sem o seu verifier é recusado.", "same": ["client"]}
```

O challenge passa pelo navegador e pode ser visto, e vê-lo não ajuda: um hash não pode ser rodado
ao contrário para achar o verifier. O verifier viaja uma vez, pela conexão direta, depois que o
código existe. Então quem pegou o código tem metade de um par e não consegue fazer a outra metade.

O `pkce.py` gera um par:

```python
# shelf/pkce.py
"""A PKCE pair: the verifier the client keeps, the challenge it sends."""
import base64
import hashlib
import secrets

verifier = secrets.token_urlsafe(48)
digest = hashlib.sha256(verifier.encode()).digest()
challenge = base64.urlsafe_b64encode(digest).rstrip(b"=").decode()
print(verifier, challenge)
```

Quarenta e oito bytes aleatórios viram um verifier de 64 caracteres, dentro dos 43 a 128 que a
RFC 7636 permite. O challenge tem sempre 43 caracteres, porque um SHA-256 tem 32 bytes e o base64url
sem o preenchimento `=` escreve 32 bytes em 43. Rode-o em `~/shelf` e você recebe um par novo a cada
vez:

```
ana@api:~/shelf$ python3 pkce.py
-QV9LSW9UeeEE_J5SqR3XIlIimh0zFT6r9fGLi-k4-L9oWtaDbYs9KOV57w1gaUk zANQsEMelf8lNz_YtKNNBuE_aWQcX2F0fOBDwEvziS8
```

**O cliente precisa lembrar o verifier entre as duas metades do fluxo**, do jeito que um app web o
guarda na sessão do usuário. No seu terminal, uma variável do shell faz esse papel. O `read` põe as
duas palavras de uma execução em duas variáveis, e o fluxo desta lição as usa:

```
ana@api:~/shelf$ read VERIFIER CHALLENGE < <(python3 pkce.py)
ana@api:~/shelf$ echo $VERIFIER; echo $CHALLENGE
h09V4DsivYL6BRH8zeQYCfK4EInvkd8ltjRhcPohPXCUu4r1sdZkGUMtF6L0XJ6M
TeUBmfOrwmD1rsnQgLpOo1FewMYh88qSkbE83VZ13ys
```

Nada no challenge é segredo, e você o gera a partir do verifier com o `openssl`, o que prova que a
transformação é só um hash e uma codificação. A saída bate com a linha de cima:

```
ana@api:~/shelf$ printf %s "$VERIFIER" | openssl dgst -sha256 -binary | basenc --base64url | tr -d =
TeUBmfOrwmD1rsnQgLpOo1FewMYh88qSkbE83VZ13ys
```

A RFC 7636 também define um método chamado `plain`, em que o challenge é o próprio verifier. Ele
existe para clientes que não conseguem calcular um SHA-256, e abre mão da propriedade acima, já que
aí o navegador leva o verifier. O `idp.py` só aceita `S256`.

**O PKCE não é mais só para clientes públicos.** A RFC 9700, as recomendações de segurança do
OAuth publicadas em 2025, pede que todo cliente o use, e o rascunho do OAuth 2.1 o torna
obrigatório. Com um segredo de cliente junto, o código fica protegido duas vezes: um código roubado
precisa do segredo, e um código enfiado na sessão de outra pessoa falha no verifier. O `idp.py`
exige o PKCE de todo cliente.
