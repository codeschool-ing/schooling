---
title: O terceiro movimento, substituir uma dependência
version: 1
---

Atualizar pressupõe que haja para o que atualizar. Às vezes não há: o aviso não tem versão corrigida
e os mantenedores dizem que não haverá. A aula 7 encontrou exatamente esse caso, uma branch que
acrescentava `ecdsa==0.19.2` e um aviso sem correção, e o gate alertou em vez de quebrar, porque
ninguém podia agir naquele dia. **Um alerta que nunca pode sumir é uma decisão adiada**, e a decisão é
o terceiro movimento.

### O que o PyPI diz sobre o ecdsa

O histórico de releases, e os avisos que os dados de vulnerabilidade do próprio PyPI listam para a
versão que a aula 7 usou:

```
ana@vm:~/linkbox$ curl -s https://pypi.org/pypi/ecdsa/json | jq -r ".releases | to_entries[] | select(.value | length > 0) | \"\(.value[0].upload_time[:10]) \(.key)\"" | sort | tail -n 4
2022-07-09 0.18.0
2024-04-08 0.19.0
2025-03-13 0.19.1
2026-03-26 0.19.2
ana@vm:~/linkbox$ curl -s https://pypi.org/pypi/ecdsa/0.19.2/json | jq -r ".vulnerabilities[] | \"\(.id) \(.aliases | join(\" \")) fixed_in=\(.fixed_in)\""
PYSEC-2026-1325 CVE-2024-23342 GHSA-wj6h-64fc-37mp fixed_in=[]
GHSA-wj6h-64fc-37mp CVE-2024-23342 PYSEC-2026-1325 fixed_in=[]
ana@vm:~/linkbox$ curl -s https://pypi.org/pypi/ecdsa/0.19.2/json | jq -r ".vulnerabilities[0].details" | fold -s -w 96
python-ecdsa has been found to be subject to a Minerva timing attack on the P-256 curve. Using 
the `ecdsa.SigningKey.sign_digest()` API function and timing signatures an attacker can leak 
the internal nonce which may allow for private key discovery. Both ECDSA signatures, key 
generation, and ECDH operations are affected. ECDSA signature verification is unaffected. The 
python-ecdsa project considers side channel attacks out of scope for the project and there is 
no planned fix.
```

Um aviso com três nomes, CVE, GHSA e PYSEC, e nada em `fixed_in`. O texto explica o porquê: um canal
lateral de tempo na assinatura, e **"The python-ecdsa project considers side channel attacks out of
scope for the project and there is no planned fix."**, ou seja, o projeto considera ataques de canal
lateral fora do escopo e não planeja correção. É uma declaração honesta e uma posição legítima para
uma biblioteca em Python puro, e diz exatamente o que o projeto vai e não vai fazer por você.

O histórico recente do repositório responde à segunda pergunta de saúde, quem o mantém:

```
ana@vm:~/linkbox$ git clone -q --filter=blob:none --no-checkout https://github.com/tlsfuzzer/python-ecdsa ~/scratch/ecdsa
ana@vm:~/linkbox$ git -C ~/scratch/ecdsa log -1 --format="%cs %s"
2026-06-08 Merge pull request #376 from tomato42/new-badge-action
ana@vm:~/linkbox$ git -C ~/scratch/ecdsa shortlog -sn --no-merges --since=2025-10-01 HEAD
     7	Alicja Kario
     2	0xmrma
     1	Alexander Shadchin
     1	Hubert Kario
```

Um merge em junho, e no último ano uma pessoa escreveu a maior parte dos commits que não são merge. É
um projeto mantido, por um grupo pequeno, com um escopo declarado. **Nada aqui diz que o pacote foi
abandonado; diz que a correção de que você precisa está fora do que ele promete.**

### Decidindo

O texto do aviso é preciso sobre onde está o risco, e isso decide o movimento:

| o que o serviço faz com ECDSA | o aviso se aplica? | o movimento |
|---|---|---|
| só verifica assinaturas que outra parte fez | não: o texto diz que a verificação não é afetada | manter, fixado, com o motivo escrito nas exceções do gate |
| assina com uma chave que ele guarda | sim | substituir |
| assina só para conferir as próprias mensagens depois | sim | substituir, e perguntar se uma assinatura é mesmo necessária |

A última linha é comum e merece um momento. Se um serviço assina uma mensagem só para que o mesmo
serviço confie nela depois, ninguém mais a verifica, e o que ele precisa é de um **código de
autenticação de mensagem** (MAC): o `hmac` da biblioteca padrão, com `hmac.compare_digest` para
comparar, que a aula 3 já usou para o token do linkbox. Nenhuma dependência é o melhor substituto que
existe.

Quando uma assinatura de verdade é necessária, o substituto é o pacote `cryptography`, mantido pela
Python Cryptographic Authority, cujo código de curvas elípticas roda no OpenSSL em vez de em Python. A
mesma operação que o linkbox teria feito com o `ecdsa`, como `~/scratch/sign.py`:

```python
"""ECDSA on P-256, the curve python-ecdsa offered, from the `cryptography`
package: sign a message, verify it, and refuse it once a byte has changed."""
from cryptography.exceptions import InvalidSignature
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import ec

key = ec.generate_private_key(ec.SECP256R1())
message = b"https://example.org/docs/handbook/onboarding"
signature = key.sign(message, ec.ECDSA(hashes.SHA256()))

public = key.public_key()
public.verify(signature, message, ec.ECDSA(hashes.SHA256()))
print("verified:", message.decode())
try:
    public.verify(signature, message + b"?", ec.ECDSA(hashes.SHA256()))
except InvalidSignature:
    print("refused: the message changed after it was signed")
```

Rodado num ambiente descartável, para nada ser acrescentado ao linkbox:

```
ana@vm:~/linkbox$ uv run -q --no-project --with "cryptography==50.0.2" python ~/scratch/sign.py
verified: https://example.org/docs/handbook/onboarding
refused: the message changed after it was signed
```

### O que uma substituição custa

**Substituir é o mais caro dos três movimentos**, e por isso vem por último. Mexe em código, não só
num lock: toda chamada muda, os testes que cobriam a biblioteca antiga precisam cobrir a nova, e a
dependência nova traz as próprias perguntas de saúde, os próprios avisos e, no caso do
`cryptography`, wheels compiladas para cada plataforma em que você implanta. O histórico de releases
dela no PyPI é a mesma checagem que esta aula fez para o gunicorn, e vale fazê-la antes do primeiro
import.

Então a ordem se mantém. **Fixe sempre, atualize por padrão, e substitua quando o projeto tiver dito,
por escrito, que não vai corrigir o que importa para você.** O linkbox não precisava do `ecdsa` em
`main`, e a branch que o acrescentou nunca entrou; o argumento acima é o que um time escreveria no
pull request que o remove.
