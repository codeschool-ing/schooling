---
title: Cifra simétrica, e por que ela precisa ser autenticada
version: 1
---

Um arquivo, uma chave de 32 bytes aleatórios escrita em hexadecimal, e AES-256 em modo CBC pelo
`openssl enc`:

```
ana@laptop:~$ printf "Payroll for September: 42 people, BRL 318,450.00\n" > payroll.txt; wc -c payroll.txt
49 payroll.txt
ana@laptop:~$ openssl rand -hex 32 > key.hex; wc -c key.hex
65 key.hex
ana@laptop:~$ openssl enc -aes-256-cbc -pbkdf2 -iter 600000 -salt -in payroll.txt -out payroll.enc -pass file:key.hex; wc -c payroll.enc; head -c 8 payroll.enc; echo
80 payroll.enc
Salted__
ana@laptop:~$ openssl enc -d -aes-256-cbc -pbkdf2 -iter 600000 -in payroll.enc -pass file:key.hex
Payroll for September: 42 people, BRL 318,450.00
```

O arquivo da chave tem 65 bytes: 64 dígitos hexadecimais e uma quebra de linha. O arquivo cifrado tem
**80 bytes para uma mensagem de 49 bytes**: o `openssl` escreve o marcador `Salted__` e um salt de 8
bytes no início, e o CBC completa a mensagem até um número inteiro de blocos de 16 bytes. O
`-pbkdf2 -iter 600000` transforma o arquivo da chave na chave de fato por 600.000 rodadas de hash. Isso
importa quando a "chave" é uma senha que alguém digitou, e não faz diferença aqui, onde a chave são
32 bytes aleatórios. Com a mesma chave, a
mensagem volta.

**Isso funciona e tem uma falha que vale conhecer pelo nome**: o CBC mantém a mensagem secreta e não diz
nada sobre se ela foi alterada. Inverta bits no arquivo cifrado e a decifragem produz outra mensagem,
muitas vezes embaralhada, às vezes alterada de forma plausível, e nada avisa.

## Cifra autenticada

Os protocolos modernos usam **cifra autenticada** (*authenticated encryption*, AEAD): a cifra produz os
dados cifrados **e uma tag**, um valor curto calculado com a chave sobre a mensagem inteira. A
decifragem recalcula a tag e se recusa a devolver qualquer coisa se ela for diferente. AES-GCM e
ChaCha20-Poly1305 são os dois de uso cotidiano. Um programa curto com a biblioteca `cryptography` do
Python mostra a recusa:

```schooling-example
{"language": "python", "file": "seal.py", "parts": [{"code": "from cryptography.hazmat.primitives.ciphers.aead import AESGCM", "note": "AES em modo GCM, da biblioteca `cryptography`, que o Ubuntu empacota como `python3-cryptography`."}, {"code": "key = AESGCM.generate_key(bit_length=256)\nnonce = b\"\\x00\" * 11 + b\"\\x01\"\nbox = AESGCM(key)", "note": "Uma chave aleatória nova de 256 bits, e um **nonce** de 12 bytes, um número usado uma única vez. A única regra rígida do GCM é nunca cifrar duas mensagens com a mesma chave e o mesmo nonce; um protocolo de verdade vai contando ou os sorteia. Esta chave vive por uma execução, então um nonce fixo é seguro aqui."}, {"code": "sealed = box.encrypt(nonce, b\"pay 318,450.00 to account 4471\", None)\nprint(len(sealed), \"bytes sealed\")\nprint(box.decrypt(nonce, sealed, None).decode())", "note": "Cifrar e decifrar. O resultado são os 30 bytes da mensagem mais uma tag de 16 bytes."}, {"code": "tampered = bytearray(sealed)\ntampered[4] ^= 0x01\ntry:\n    box.decrypt(nonce, bytes(tampered), None)\nexcept Exception as e:\n    print(\"refused:\", type(e).__name__)", "note": "Inverta um bit de um byte e tente de novo. A decifragem não devolve uma mensagem um pouco diferente: não devolve nada e levanta `InvalidTag`."}], "output": "46 bytes sealed\npay 318,450.00 to account 4471\nrefused: InvalidTag"}
```

O programa como rodou no `laptop`:

```
ana@laptop:~$ python3 seal.py
46 bytes sealed
pay 318,450.00 to account 4471
refused: InvalidTag
```

**46 bytes selados** para uma instrução de 30 bytes: os 16 a mais são a tag. Um bit alterado e a
mensagem é recusada inteira. Essa é a propriedade de que uma ordem de pagamento precisa, e o motivo de
todo protocolo no resto deste curso usar AEAD em vez de uma cifra pura.
