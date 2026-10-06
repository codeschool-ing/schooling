---
title: Fazer a própria criptografia
version: 1
---

**"Fazer a própria criptografia" raramente quer dizer inventar uma cifra. Quer dizer montar
primitivas sólidas num esquema próprio, e é no esquema que os erros moram.** O AES não está quebrado
no código abaixo. O código está.

## A cifragem de um prestador

O primeiro sistema de agendamento da Vereda veio de um prestador, que escreveu uma função para cifrar
os registros dos pacientes antes de guardá-los. Ela usa AES com chave de 256 bits e roda sem erro.
Ela foi revista no laboratório ao lado do modo autenticado de uma biblioteca:

```schooling-example
{
  "language": "python",
  "file": "homemade.py",
  "parts": [
    {
      "code": "import hashlib\nimport os\n\nfrom cryptography.exceptions import InvalidTag\nfrom cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes\nfrom cryptography.hazmat.primitives.ciphers.aead import AESGCM\n\nrecord = b\"patient 4471, Marina Duarte, lumbar pain, session 3 of 10\"",
      "note": "Um registro dos dados de laboratório da clínica, e dois jeitos de cifrá-lo."
    },
    {
      "code": "def homemade(password, text):\n    key = hashlib.sha256(password.encode()).digest()\n    enc = Cipher(algorithms.AES(key), modes.CBC(bytes(16))).encryptor()\n    return enc.update(text + b\" \" * (-len(text) % 16)) + enc.finalize()",
      "note": "A função do prestador. Toda linha usa AES, e toda linha tem um erro que uma aula anterior nomeou: a chave é um hash rápido e sem sal de uma senha (aula 5); o IV é de dezesseis bytes zero, sempre (aula 1); o preenchimento é feito com espaços, então um registro que terminava em espaço o perde; e nada detecta uma alteração (aula 1 de novo)."
    },
    {
      "code": "a = homemade(\"vereda2026\", record)\nb = homemade(\"vereda2026\", record)\nprint(\"homemade, same record twice: \", \"identical\" if a == b else \"different\")",
      "note": "O IV fixo a torna determinística: o mesmo registro, cifrado duas vezes, dá os mesmos bytes, então quem vê os valores guardados sabe quais se repetem."
    },
    {
      "code": "key = AESGCM.generate_key(bit_length=256)\n\ndef seal(text):\n    nonce = os.urandom(12)\n    return nonce + AESGCM(key).encrypt(nonce, text, None)\n\na, b = seal(record), seal(record)\nprint(\"AES-GCM, same record twice:  \", \"identical\" if a == b else \"different\")",
      "note": "O modo autenticado da biblioteca, usado como a documentação manda: uma chave aleatória, um nonce novo de 12 bytes vindo do sistema operacional para cada mensagem, o nonce guardado na frente do texto cifrado."
    },
    {
      "code": "changed = bytearray(a)\nchanged[20] ^= 1\ntry:\n    AESGCM(key).decrypt(bytes(changed[:12]), bytes(changed[12:]), None)\nexcept InvalidTag:\n    print(\"AES-GCM, one byte changed:    refused\")",
      "note": "Um byte alterado é recusado em vez de decifrado, a propriedade que a última seção da aula 1 mostrou com o `vcrypt open`."
    }
  ],
  "output": "homemade, same record twice:  identical\nAES-GCM, same record twice:   different\nAES-GCM, one byte changed:    refused"
}
```

```
ana@lab:~/lab$ python3 homemade.py
homemade, same record twice:  identical
AES-GCM, same record twice:   different
AES-GCM, one byte changed:    refused
```

Nenhum desses defeitos aparece num teste que cifra, decifra e compara. A função devolve o registro
certo toda vez. **Todo defeito diz respeito ao que a função faz com a entrada de outra pessoa ou ao
longo de muitas chamadas**: dois registros que começam com os mesmos dezesseis bytes produzem o mesmo
primeiro bloco, uma senha adivinhável entrega a chave por mais forte que o AES seja, e uma alteração
nos bytes guardados é decifrada em algo que ninguém percebe.

## Por que o teste passou e o projeto falhou

Código criptográfico tem uma propriedade que a maior parte do código não tem: **funcionar e ser
seguro não têm relação.** Uma função de ordenação que devolve a ordem errada falha nos testes. Uma
função de cifragem com IV fixo, chave sem sal ou sem integridade devolve exatamente o texto claro
certo, e a fraqueza dela só aparece para quem a procura, em geral mais tarde e em geral com os dados
guardados na mão.

Por isso a regra profissional não é "tome cuidado", e sim **"não monte"**:

- Use a **interface de alto nível** de uma biblioteca, a que foi projetada para o uso seguro ser o
  fácil: um AEAD como AES-GCM ou ChaCha20-Poly1305, com os nonces tratados como a documentação manda,
  ou uma receita completa como o Fernet do `cryptography`, o `secretbox` da libsodium, ou o age para
  arquivos.
- Derive chaves de senhas com uma função feita para isso (Argon2id, aula 5), nunca com um hash.
- Deixe o TLS (aula 10) proteger os dados em trânsito, em vez de cifrar um conteúdo à mão e mandá-lo
  por HTTP puro.
- Trate qualquer módulo que importe `modes.CBC`, `modes.ECB` ou uma cifra de bloco crua como código
  que precisa da revisão de um criptógrafo, porque um uso correto disso é possível e raramente é o
  que está lá.

## Quando é preciso algo novo

Às vezes nenhuma receita existente serve. O caminho responsável, então, é o que deu ao mundo o AES e
o TLS 1.3: um projeto escrito, publicado, analisado por gente que não o escreveu, durante anos, antes
de alguém depender dele. Um algoritmo secreto, ou um que só o autor examinou, não tem nada disso. O
princípio de Kerckhoffs, de 1883, diz isso numa linha: um sistema precisa continuar seguro quando
tudo sobre ele, menos a chave, é público.
