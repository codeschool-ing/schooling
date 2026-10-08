---
title: Sigilo futuro, ou o que uma chave roubada abre
version: 1
---

**Sigilo futuro (*forward secrecy*) significa que roubar hoje a chave privada de longo prazo de um
servidor não decifra o tráfego que ele trocou ontem.** Ele vem de combinar cada chave de sessão com
uma troca nova, cujos segredos são jogados fora quando a sessão termina. É o motivo de o TLS 1.3 ter
removido o outro jeito de fazer uma chave chegar a um servidor.

## O outro jeito, e sua memória longa

A aula 3 entregou uma chave de sessão cifrando-a com a chave pública RSA do destinatário. O TLS 1.2
permitia exatamente isso, como *transporte de chave RSA*: o navegador escolhia a chave de sessão e a
mandava cifrada com a chave do certificado do servidor. Aqui está isso no laboratório: uma chave de
sessão é embrulhada para o serviço de prontuários, e uma carta é cifrada com ela. Os dois arquivos
são o que alguém gravando a rede teria guardado:

```
ana@lab:~/lab$ xxd -r -p keys/aes-256-b.hex | openssl pkeyutl -encrypt -pubin -inkey keys/rsa-3072.pub -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha256 -out recorded.rsa; vcrypt seal --key keys/aes-256-b.hex --nonce 0000000000000000000000c7 data/referral.txt recorded.gcm
sealed data/referral.txt: 12-byte nonce + 170 bytes of ciphertext + 16-byte tag -> recorded.gcm
```

Um ano depois, a chave privada do serviço vaza, de um backup, de um disco descartado ou de uma
invasão. Quem guardou a gravação agora desembrulha a chave de sessão e lê a carta:

```
ana@lab:~/lab$ openssl pkeyutl -decrypt -inkey keys/rsa-3072.key -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha256 -in recorded.rsa | xxd -p -c 32 > leaked.hex; vcrypt open --key leaked.hex recorded.gcm | head -1
Referral 2026-0417. Patient: Marina Duarte, 41.
```

Nada na gravação precisou ser quebrado. **Toda sessão que já usou aquela chave pode ser lida por
quem a tiver**, enquanto as gravações existirem. Organizações e serviços de inteligência de fato
gravam tráfego cifrado que ainda não conseguem ler, e por isso isso importa mesmo quando nenhuma
chave vazou.

## A troca nova

Com uma troca **efêmera**, os dois lados geram um par X25519 novo só para esta sessão, combinam um
segredo, derivam chaves e descartam as metades privadas. O `vcrypt ephemeral` faz exatamente isso,
com chaves aleatórias novas em vez de rótulos, então mostra só o que é igual em toda execução:

```py
# ~/lab/tools/ephemeral.py
"""vcrypt ephemeral: two X25519 key pairs made in memory for one exchange,
used once, and dropped. Fresh random keys every run, so it prints only what
does not change."""
from cryptography.hazmat.primitives.asymmetric import x25519

ana, bruno = x25519.X25519PrivateKey.generate(), x25519.X25519PrivateKey.generate()
s1 = ana.exchange(bruno.public_key())
s2 = bruno.exchange(ana.public_key())
print("ephemeral pairs generated for this exchange: 2, written to disk: 0")
print(f"both sides derived the same {len(s1)}-byte secret: {'yes' if s1 == s2 else 'no'}")
del ana, bruno
print("private halves discarded; nothing left that could rebuild this secret")
```


```
ana@lab:~/lab$ vcrypt ephemeral
ephemeral pairs generated for this exchange: 2, written to disk: 0
both sides derived the same 32-byte secret: yes
private halves discarded; nothing left that could rebuild this secret
```

A chave de longo prazo do servidor continua tendo um trabalho, que a seção 05 explica: ela
**assina** a troca para provar quem é o servidor. Mas ela nunca cifra a chave de sessão e nunca é
necessária para recuperá-la. Se ela vazar um ano depois, a gravação contém dois valores públicos
cujas metades privadas não existem mais em lugar nenhum.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Duas linhas sobre uma linha do tempo: a sessão em 2026, depois a chave do servidor vazando em 2027. Linha de cima, transporte de chave RSA: a chave de sessão foi cifrada com a chave de longo prazo do servidor, então o vazamento de 2027 abre a sessão gravada. Linha de baixo, troca efêmera: a chave de sessão veio de pares X25519 apagados no fim da sessão, então o vazamento de 2027 não abre nada.\"><defs><marker id=\"fs-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"fs-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"140\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2026: a sessão, gravada</text><text x=\"520\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">2027: a chave do servidor vaza</text><rect x=\"20\" y=\"40\" width=\"240\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">transporte de chave RSA</text><text x=\"36\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">chave de sessão cifrada com a do servidor</text><rect x=\"400\" y=\"40\" width=\"300\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"416\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">gravação aberta</text><text x=\"416\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a chave vazada desembrulha a de sessão</text><polyline points=\"262,75 398,75\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#fs-ah-amber)\"></polyline><rect x=\"20\" y=\"130\" width=\"240\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">X25519 efêmera</text><text x=\"36\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">chaves da troca apagadas depois do uso</text><rect x=\"400\" y=\"130\" width=\"300\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"416\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">gravação continua fechada</text><text x=\"416\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a chave vazada só assinava</text><polyline points=\"262,165 398,165\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\" marker-end=\"url(#fs-ah-wire)\"></polyline></svg>", "caption": "O mesmo vazamento, um ano depois, contra os dois jeitos de obter uma chave de sessão."}
```

## Nos protocolos

- O **TLS 1.3** só oferece trocas efêmeras (ECDHE ou DHE). O transporte de chave RSA foi removido,
  e assim o sigilo futuro deixou de ser uma opção de configuração.
- O **TLS 1.2** ainda permite transporte de chave RSA. Um servidor que ainda aceita TLS 1.2 deveria
  oferecer só as suítes `ECDHE`, aquelas cujos nomes começam com `TLS_ECDHE_`; a aula 10 confere
  isso num servidor.
- O **SSH** sempre usou uma troca efêmera em cada conexão.
- O **Signal** vai além e faz uma troca nova para quase cada mensagem, para que nem um celular
  apreendido no meio de uma conversa abra as mensagens anteriores.

O sigilo futuro protege o passado, não o presente: quem tem a chave do servidor **agora** consegue
se passar pelo servidor para visitantes novos. É para isso que serve a revogação, na aula 9.
