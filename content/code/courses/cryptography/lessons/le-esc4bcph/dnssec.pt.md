---
title: DNSSEC, assinaturas nas respostas do DNS
version: 1
---

**O DNSSEC acrescenta assinaturas aos registros DNS, para que um resolvedor consiga conferir que uma
resposta veio mesmo do dono da zona e não foi alterada no caminho.** Ele não cifra nada: quem estiver
olhando continua vendo quais nomes são consultados. O que ele impede é uma resposta forjada, como um
endereço falso para `portal.vereda.example` enfiado no cache de um resolvedor, que mandaria os
pacientes para um servidor escolhido por outra pessoa.

## A zona da Vereda, antes de assinar

As ferramentas de assinatura vêm do BIND, o servidor DNS com que a maioria das zonas é assinada, e o
Ubuntu as empacota à parte:

```sh
sudo apt-get install -y bind9-utils
```

A zona em si é um arquivo de texto: quem responde por ela, e dois nomes com seus endereços, da faixa
reservada para documentação:

```sh
cd ~/lab
mkdir -p data/dns
cat > data/dns/db.vereda.example <<'EOF'
$TTL 3600
@       IN SOA ns1.vereda.example. hostmaster.vereda.example. 2026061501 7200 900 1209600 300
@       IN NS  ns1.vereda.example.
ns1     IN A   192.0.2.53
portal  IN A   192.0.2.10
EOF
vcrypt dnskeys
```

O `vcrypt dnskeys` grava dois pares de chaves Ed25519, no formato de arquivo do BIND. O próprio
`dnssec-keygen` do BIND faz os mesmos arquivos a partir de bytes aleatórios; esta ferramenta os
deriva de rótulos, para que a zona assinada abaixo seja a que você obtém:

```py
# ~/lab/tools/dnskeys.py
"""vcrypt dnskeys: Vereda's two DNSSEC keys, a key-signing key (flags 257)
and a zone-signing key (flags 256), both Ed25519 (algorithm 15), written
into data/dns/ in the file format BIND's tools read. `dnssec-keygen -a
ED25519` makes the same files from fresh random bytes; these come from
keys.py so that the signed zone in the lesson is the one you get."""
import base64
import struct

from cryptography.hazmat.primitives import serialization

import keys

for label, flags in (("ksk", 257), ("zsk", 256)):
    k = keys.ed25519_key("dns/" + label)
    pub = k.public_key().public_bytes(serialization.Encoding.Raw, serialization.PublicFormat.Raw)
    priv = k.private_bytes(serialization.Encoding.Raw, serialization.PrivateFormat.Raw,
                           serialization.NoEncryption())
    # The key tag that names the files, computed over the DNSKEY record as
    # RFC 4034 appendix B says: flags, protocol 3, algorithm 15, the key.
    rdata = struct.pack("!HBB", flags, 3, 15) + pub
    acc = sum(b if i & 1 else b << 8 for i, b in enumerate(rdata))
    tag = (acc + ((acc >> 16) & 0xFFFF)) & 0xFFFF
    base = f"data/dns/Kvereda.example.+015+{tag:05d}"
    open(base + ".key", "w").write(
        f"vereda.example. IN DNSKEY {flags} 3 15 {base64.b64encode(pub).decode()}\n")
    open(base + ".private", "w").write(
        f"Private-key-format: v1.3\nAlgorithm: 15 (ED25519)\nPrivateKey: {base64.b64encode(priv).decode()}\n"
        "Created: 20260101000000\nPublish: 20260101000000\nActivate: 20260101000000\n")
```

Agora o diretório tem a zona e os dois pares:

```
ana@lab:~/lab$ ls data/dns
Kvereda.example.+015+34091.key
Kvereda.example.+015+34091.private
Kvereda.example.+015+42395.key
Kvereda.example.+015+42395.private
db.vereda.example
```

As duas têm papéis diferentes. A **chave de assinatura da zona** (ZSK, tag 34091) assina cada
conjunto de registros. A **chave de assinatura de chaves** (KSK, tag 42395, flag 257) assina só o
próprio conjunto de registros DNSKEY. Mantê-las separadas permite trocar a ZSK com frequência sem
envolver ninguém de fora da zona, enquanto a KSK, pela qual a zona-mãe responde, muda raramente.

## Assinando

```
ana@lab:~/lab$ cd data/dns && dnssec-signzone -S -K . -s 20260601000000 -e 20360601000000 -o vereda.example -f signed.zone db.vereda.example 2>&1 | tail -5
- ED25519
Zone fully signed:
Algorithm: ED25519: KSKs: 1 active, 0 stand-by, 0 revoked
                    ZSKs: 1 active, 0 stand-by, 0 revoked
signed.zone
```

O assinador acrescentou uma assinatura a cada conjunto de registros e conferiu o resultado. O
endereço do portal agora viaja com a própria assinatura, um registro **RRSIG**:

```
ana@lab:~/lab$ grep -A6 '^portal' data/dns/signed.zone
portal.vereda.example.	3600	IN A	192.0.2.10
			3600	RRSIG	A 15 3 3600 (
					20360601000000 20260601000000 34091 vereda.example.
					1oiWiijt7oB8Eqb0nmjpvyDfVtMH/VA/g68N
					73h5Cv7FiR9jkkBAoXTe7aDjt0UK0fnEv+gG
					M4Croop/vLwSCw== )
			300	NSEC	vereda.example. A RRSIG NSEC
```

O RRSIG nomeia o algoritmo (15, Ed25519), a janela de validade (de 1º de junho de 2026 a 1º de junho
de 2036, como o laboratório escolheu), a chave que assinou (34091) e a assinatura em si. O registro
**NSEC** que vem depois prova o que *não* existe: depois de `portal` o próximo nome é de novo o
ápice da zona, então um resolvedor pode receber uma prova assinada de que `admin.vereda.example` não
tem registro, em vez de confiar num "nome inexistente" sem assinatura.

## A cadeia até a raiz

Uma assinatura é tão boa quanto a chave que a confere, a pergunta das aulas 8 e 9 mais uma vez. O
DNSSEC a responde com a própria hierarquia do DNS. A zona-mãe, `.example` aqui e `.com.br` para um
domínio brasileiro real, publica um registro **DS**, um hash da KSK da zona-filha:

```
ana@lab:~/lab$ cat data/dns/dsset-vereda.example.
vereda.example.		IN DS 42395 15 2 3F59AE7706354EB0350F91F441DA8547ADC6C1DDDC7EC8F80B3A3ACF AD227806
```

A zona-mãe assina seu registro DS com as próprias chaves, a mãe dela faz o mesmo, e assim por diante
até a zona raiz, cuja chave todo resolvedor que valida tem configurada. Essa é uma cadeia de
confiança como a de um certificado, com a chave da zona raiz como única âncora.

## Uma resposta forjada

Mude o endereço do portal na zona assinada, como faria um atacante envenenando um cache, sem a
chave privada para assinar de novo:

```
ana@lab:~/lab$ cd data/dns && sed 's/192.0.2.10$/203.0.113.66/' signed.zone > forged.zone && dnssec-verify -o vereda.example forged.zone 2>&1 | head -1
No correct ED25519 signature for portal.vereda.example A
```

Um resolvedor que valida entrega ao cliente uma falha em vez do endereço forjado. **A validação
acontece no resolvedor**, então o DNSSEC só protege usuários cujo resolvedor o confere; os
resolvedores públicos do Google, da Cloudflare e da Quad9 conferem, e muitos resolvedores de empresas
e provedores também. O Registro.br aceita DNSSEC para domínios `.br`, e assinar uma zona é uma opção
de configuração na maioria dos provedores de DNS hoje.
