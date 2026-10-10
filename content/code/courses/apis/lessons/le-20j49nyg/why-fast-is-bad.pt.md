---
title: Por que rapidez é a propriedade errada
version: 1
---

**Um hash de senha é lento de propósito.** O servidor paga o custo uma vez, quando alguém faz login,
e ninguém nota algumas dezenas de milissegundos. Quem tem uma tabela vazada paga o mesmo custo a cada
palpite, contra cada conta, e é aí que a conta cresce.

A objeção de costume é que o SHA-256 é um hash seguro, então serviria para senhas. Ele é seguro para
o trabalho dele, que é identificar dados: um arquivo, uma mensagem, um bloco de um download. Nesse
trabalho, rapidez é qualidade, e o SHA-256 é feito para ser tão rápido quanto o hardware permite. A
propriedade que o torna bom lá é justamente a que o torna errado aqui.

Meça em vez de acreditar. O `hashrate.py` calcula cada hash de novo e de novo durante dois segundos e
conta. Salve-o em `~/shelf` do mesmo jeito que os arquivos da aula 1:

```schooling-example
{
  "language": "python",
  "file": "shelf/hashrate.py",
  "parts": [
    {
      "code": "# shelf/hashrate.py\n\"\"\"How many password hashes this machine computes in a second.\n\n    python3 hashrate.py           SHA-256 against bcrypt, scrypt and Argon2id\n    python3 hashrate.py argon2    Argon2id at several settings, to choose one\n\"\"\"\nimport hashlib\nimport os\nimport sys\nimport time\n\nimport bcrypt\nfrom argon2.low_level import Type, hash_secret\n\nPASSWORD = b\"correct horse battery staple\"\nSALT = os.urandom(16)",
      "note": "Duas bibliotecas do repositório do Ubuntu, `python3-bcrypt` e `python3-argon2`; SHA-256 e scrypt vêm no próprio `hashlib` do Python. Uma senha e um salt aleatório servem a todas as linhas, então elas só diferem no algoritmo e nos parâmetros."
    },
    {
      "code": "\n\ndef rate(fn, seconds=2.0):\n    \"\"\"Hashes per second: call fn for `seconds`, and at least three times.\"\"\"\n    n, start = 0, time.perf_counter()\n    while n < 3 or time.perf_counter() - start < seconds:\n        fn()\n        n += 1\n    return n / (time.perf_counter() - start)",
      "note": "A medição: chamar um hash de novo e de novo durante dois segundos e dividir. O mínimo de três chamadas impede que um parâmetro lento seja julgado por uma amostra só."
    },
    {
      "code": "\n\ndef sha256():\n    return hashlib.sha256(SALT + PASSWORD).digest()\n\n\ndef bcrypt_at(cost):\n    return lambda: bcrypt.hashpw(PASSWORD, bcrypt.gensalt(cost))\n\n\ndef scrypt_at(n, r, p):\n    return lambda: hashlib.scrypt(PASSWORD, salt=SALT, n=n, r=r, p=p,\n                                  maxmem=2 * 128 * r * n, dklen=32)\n\n\ndef argon2id_at(m, t, p):\n    return lambda: hash_secret(PASSWORD, SALT, time_cost=t, memory_cost=m,\n                               parallelism=p, hash_len=16, type=Type.ID)",
      "note": "Uma função por algoritmo. O `maxmem` do scrypt é o dobro do que os parâmetros pedem, que é `128 × r × N` bytes; sem ele o OpenSSL recusa qualquer coisa acima do limite padrão, como a seção sobre scrypt mostra. `hash_secret` é a chamada de baixo nível do Argon2, em que cada parâmetro tem nome."
    },
    {
      "code": "\n\nCOMPARE = [\n    (\"SHA-256\", \"one pass\", sha256),\n    (\"bcrypt\", \"cost 10\", bcrypt_at(10)),\n    (\"bcrypt\", \"cost 11\", bcrypt_at(11)),\n    (\"bcrypt\", \"cost 12\", bcrypt_at(12)),\n    (\"scrypt\", \"N=2^17 r=8 p=1\", scrypt_at(2**17, 8, 1)),\n    (\"Argon2id\", \"m=19456 t=2 p=1\", argon2id_at(19456, 2, 1)),\n]\n\nTUNE = [\n    (\"Argon2id\", f\"m={m} t={t} p={p}\", argon2id_at(m, t, p))\n    for m, t, p in [(7168, 5, 1), (9216, 4, 1), (12288, 3, 1), (19456, 2, 1),\n                    (47104, 1, 1), (65536, 2, 1), (102400, 2, 8), (262144, 2, 1)]\n]",
      "note": "O que o programa sabe medir. `COMPARE` é o SHA-256 contra os três hashes de senha, cada um no mínimo que o Password Storage Cheat Sheet da OWASP indica, com o bcrypt em mais dois custos. `TUNE` é só o Argon2id: as cinco configurações da folha, o padrão da biblioteca e duas maiores."
    },
    {
      "code": "\n\ndef span(seconds):\n    \"\"\"A duration in the largest unit that keeps it above one.\"\"\"\n    for unit, size in ((\"days\", 86400), (\"h\", 3600), (\"min\", 60)):\n        if seconds >= size:\n            return f\"{seconds / size:.1f} {unit}\"\n    return f\"{seconds:.1f} s\"",
      "note": "Segundos em forma legível. A última coluna é quanto esta máquina leva para um milhão de hashes com os parâmetros daquela linha."
    },
    {
      "code": "\n\nif __name__ == \"__main__\":\n    rows = TUNE if sys.argv[1:] == [\"argon2\"] else COMPARE\n    print(f\"{'algorithm':<9} {'settings':<18} {'hashes/s':>11} {'ms each':>9} {'a million':>12}\")\n    for name, settings, fn in rows:\n        r = rate(fn)\n        print(f\"{name:<9} {settings:<18} {r:>11,.1f} {1000 / r:>9.3f} {span(1e6 / r):>12}\",\n              flush=True)",
      "note": "Sem argumento, compara; com `argon2`, ajusta. O `flush=True` imprime cada linha assim que ela é medida, porque uma execução inteira leva vários segundos."
    }
  ]
}
```

Rode. Cada linha leva alguns segundos, e as linhas mais lentas são o assunto:

```
ana@api:~/shelf$ python3 hashrate.py
algorithm settings              hashes/s   ms each    a million
SHA-256   one pass           1,101,475.6     0.001        0.9 s
bcrypt    cost 10                   16.0    62.651       17.4 h
bcrypt    cost 11                    7.9   127.267     1.5 days
bcrypt    cost 12                    3.9   256.682     3.0 days
scrypt    N=2^17 r=8 p=1             1.9   524.392     6.1 days
Argon2id  m=19456 t=2 p=1           23.3    42.992       11.9 h
```

Os seus números vão ser outros, porque o seu computador não é este, e variam um pouco entre duas
execuções na mesma máquina; leia as colunas umas contra as outras, e não como valores. Nesta execução
**o SHA-256 calculou 1.101.475,6 hashes por segundo**, então um milhão de palpites levou 0,9 s. Os
hashes de senha calcularam entre 1,9 e 23,3 por segundo, e o mesmo milhão de palpites levou entre
11,9 horas e 6,1 dias.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 300\" role=\"img\" aria-label=\"Hashes por segundo na máquina do laboratório, em escala logarítmica de 1 a 10 milhões: SHA-256 one pass: 1,101,475.6 por segundo, um milhão em 0.9 s; bcrypt cost 10: 16.0 por segundo, um milhão em 17.4 h; bcrypt cost 11: 7.9 por segundo, um milhão em 1.5 days; bcrypt cost 12: 3.9 por segundo, um milhão em 3.0 days; scrypt N=2^17 r=8 p=1: 1.9 por segundo, um milhão em 6.1 days; Argon2id m=19456 t=2 p=1: 23.3 por segundo, um milhão em 11.9 h\"><text x=\"610\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um milhão leva</text><text x=\"20\" y=\"49\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">SHA-256</text><text x=\"92\" y=\"49\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one pass</text><rect x=\"210\" y=\"40\" width=\"336.62431480178157\" height=\"18\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"538.6243148017816\" y=\"49\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1,101,475.6</text><text x=\"610\" y=\"49\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">0.9 s</text><text x=\"20\" y=\"83\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">bcrypt</text><text x=\"92\" y=\"83\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cost 10</text><rect x=\"210\" y=\"74\" width=\"67.08668474797298\" height=\"18\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"283.086684747973\" y=\"83\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">16.0</text><text x=\"610\" y=\"83\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">17.4 h</text><text x=\"20\" y=\"117\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">bcrypt</text><text x=\"92\" y=\"117\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cost 11</text><rect x=\"210\" y=\"108\" width=\"50.0106522290389\" height=\"18\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"266.0106522290389\" y=\"117\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">7.9</text><text x=\"610\" y=\"117\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1.5 days</text><text x=\"20\" y=\"151\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">bcrypt</text><text x=\"92\" y=\"151\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cost 12</text><rect x=\"210\" y=\"142\" width=\"32.93074239147637\" height=\"18\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"248.93074239147637\" y=\"151\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">3.9</text><text x=\"610\" y=\"151\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">3.0 days</text><text x=\"20\" y=\"185\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">scrypt</text><text x=\"92\" y=\"185\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">N=2^17 r=8 p=1</text><rect x=\"210\" y=\"176\" width=\"15.530557767371903\" height=\"18\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"231.5305577673719\" y=\"185\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1.9</text><text x=\"610\" y=\"185\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">6.1 days</text><text x=\"20\" y=\"219\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Argon2id</text><text x=\"92\" y=\"219\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">m=19456 t=2 p=1</text><rect x=\"210\" y=\"210\" width=\"76.18125845716395\" height=\"18\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"292.18125845716395\" y=\"219\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">23.3</text><text x=\"610\" y=\"219\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">11.9 h</text><line x1=\"210\" y1=\"250\" x2=\"600\" y2=\"250\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><line x1=\"210.0\" y1=\"34\" x2=\"210.0\" y2=\"250\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"4 3\"></line><text x=\"210.0\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><line x1=\"265.7142857142857\" y1=\"34\" x2=\"265.7142857142857\" y2=\"250\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"4 3\"></line><text x=\"265.7142857142857\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><line x1=\"321.42857142857144\" y1=\"34\" x2=\"321.42857142857144\" y2=\"250\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"4 3\"></line><text x=\"321.42857142857144\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">100</text><line x1=\"377.1428571428571\" y1=\"34\" x2=\"377.1428571428571\" y2=\"250\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"4 3\"></line><text x=\"377.1428571428571\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1k</text><line x1=\"432.8571428571429\" y1=\"34\" x2=\"432.8571428571429\" y2=\"250\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"4 3\"></line><text x=\"432.8571428571429\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10k</text><line x1=\"488.57142857142856\" y1=\"34\" x2=\"488.57142857142856\" y2=\"250\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"4 3\"></line><text x=\"488.57142857142856\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">100k</text><line x1=\"544.2857142857142\" y1=\"34\" x2=\"544.2857142857142\" y2=\"250\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"4 3\"></line><text x=\"544.2857142857142\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1M</text><line x1=\"600.0\" y1=\"34\" x2=\"600.0\" y2=\"250\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"4 3\"></line><text x=\"600.0\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10M</text><text x=\"405.0\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">hashes por segundo num núcleo, cada marca dez vezes a anterior</text></svg>", "caption": "Uma execução do hashrate.py na máquina do laboratório. A escala é logarítmica: o SHA-256 fica mais de cinco marcas à direita do hash de senha mais lento, mais de meio milhão de vezes mais rápido.", "same": ["Argon2id", "SHA-256", "bcrypt", "scrypt"]}
```

Duas ressalvas sobre o que isso mede. É um laço de Python num núcleo, e quem leva a sério uma tabela
vazada usa hardware feito para isso, muito mais rápido que este em todas as linhas. O que se mantém é
a proporção entre as linhas, e ela se mantém de forma desigual: o scrypt e o Argon2id precisam de um
bloco de memória para cada hash em andamento, que é exatamente o que falta a uma placa de vídeo
rodando milhares de palpites lado a lado. As seções sobre esses dois voltam a isso.

**O custo é pago por palpite, então ele se multiplica pelo tamanho da lista de palpites.** Uma lista
curta de senhas comuns custa pouco mesmo contra um hash lento, e é por isso que as regras para a
própria senha, no fim desta aula, continuam importando. Um hash lento transforma um vazamento numa
corrida que quem defende pode ganhar: tempo para perceber, avisar os usuários e trocar as senhas
antes que a maioria delas caia.
