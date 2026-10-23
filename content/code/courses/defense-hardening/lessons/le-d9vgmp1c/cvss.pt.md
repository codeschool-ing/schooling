---
title: Lendo uma nota de gravidade
version: 1
---

**O CVSS, Common Vulnerability Scoring System, descreve quão ruim é uma falha em oito respostas, e
uma fórmula as transforma num número de 0 a 10.** O número é o que as pessoas citam; as oito
respostas são o que você lê. O feed as carrega como um **vetor**:

```
AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H
```

| métrica | a pergunta | neste vetor |
|---|---|---|
| `AV` vetor de ataque | de onde pode ser alcançada? Rede, Adjacente, Local, Física | `N`, pela rede |
| `AC` complexidade do ataque | precisa de condições que o atacante não controla? Baixa ou Alta | `L`, não |
| `PR` privilégios exigidos | o atacante precisa já ter uma conta? Nenhum, Baixo, Alto | `N`, nenhuma conta |
| `UI` interação do usuário | alguém precisa clicar em alguma coisa? Nenhuma ou Exigida | `N`, ninguém |
| `S` escopo | ela alcança além do componente que tem a falha? Inalterado ou Alterado | `U`, não |
| `C`, `I`, `A` | o efeito na confidencialidade, na integridade e na disponibilidade: Alto, Baixo ou Nenhum | consegue parar o serviço, mais nada |

Este é o aviso do nginx no feed: qualquer um na rede consegue fazer o portal parar de responder, sem
conta e sem ajuda, e nada é lido nem alterado. A fórmula é publicada pelo FIRST, a organização que
mantém o CVSS, e é curta o bastante para escrever. Esta é a versão 3.1, que é a que a maioria dos
avisos ainda traz:

```schooling-example
{"language": "python", "file": "cvss.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"cvss.py VECTOR...: the CVSS 3.1 base score of each vector, as the specification computes it.\"\"\"\nimport math, sys\n\nW = {\"AV\": {\"N\": 0.85, \"A\": 0.62, \"L\": 0.55, \"P\": 0.2}, \"AC\": {\"L\": 0.77, \"H\": 0.44},\n     \"UI\": {\"N\": 0.85, \"R\": 0.62}, \"CIA\": {\"H\": 0.56, \"L\": 0.22, \"N\": 0.0}}\n", "note": "Os pesos são os números da própria especificação, para o vetor de ataque, a complexidade do ataque, a interação do usuário e os três impactos. Privilégios exigidos tem um peso que depende do escopo, então é calculado abaixo."}, {"code": "def roundup(x):\n    i = round(x * 100000)\n    return i / 100000.0 if i % 10000 == 0 else (math.floor(i / 10000) + 1) / 10.0\n", "note": "O CVSS arredonda para cima com uma casa decimal, e a especificação dá exatamente esta função, escrita para evitar o erro de ponto flutuante que faria `4.000000001` virar 4.1."}, {"code": "def score(vector):\n    m = dict(part.split(\":\") for part in vector.split(\"/\"))\n    changed = m[\"S\"] == \"C\"\n    pr = {\"N\": 0.85, \"L\": 0.68 if changed else 0.62, \"H\": 0.5 if changed else 0.27}[m[\"PR\"]]\n    iss = 1 - (1 - W[\"CIA\"][m[\"C\"]]) * (1 - W[\"CIA\"][m[\"I\"]]) * (1 - W[\"CIA\"][m[\"A\"]])\n    impact = 7.52 * (iss - 0.029) - 3.25 * (iss - 0.02) ** 15 if changed else 6.42 * iss\n    exploitability = 8.22 * W[\"AV\"][m[\"AV\"]] * W[\"AC\"][m[\"AC\"]] * pr * W[\"UI\"][m[\"UI\"]]\n    if impact <= 0:\n        return 0.0\n    return roundup(min((1.08 if changed else 1) * (impact + exploitability), 10))\n", "note": "A fórmula: uma subnota de impacto a partir de confidencialidade, integridade e disponibilidade, uma subnota de explorabilidade a partir de como a falha é alcançada, e uma soma limitada a 10. Um escopo alterado, em que a falha alcança além do componente que a tem, usa outra curva de impacto e multiplica por 1,08."}, {"code": "if __name__ == \"__main__\":\n    for v in sys.argv[1:]:\n        print(f\"{score(v):4}  {v}\")"}]}
```

Rode-o nos vetores do feed, e em mais um que toda lista de exemplos inclui, a nota de uma falha que dá
controle total a um estranho:

```
ana@admin:~$ python3 cvss.py AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H $(jq -r ".[].cvss" feed.json)
 9.8  AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H
 8.1  AV:N/AC:H/PR:N/UI:N/S:U/C:H/I:H/A:H
 7.5  AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H
 7.8  AV:L/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:H
 4.3  AV:N/AC:L/PR:N/UI:R/S:U/C:L/I:N/A:N
 7.5  AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:N/A:N
 9.8  AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H
 5.9  AV:N/AC:H/PR:N/UI:N/S:U/C:H/I:N/A:N
```

A primeira linha é esse caso de controle total, 9,8. A negação de serviço do nginx fica com 7,5,
embora não leia nem mude nada, porque qualquer um a alcança sem ajuda. A falha do OpenSSH fica com
8,1, menos que uma falha de controle total só porque a complexidade de ataque dela é alta. A falha do
`sudo` fica com 7,8 com o pior impacto possível, contida pelo `AV:L`: alguém precisa ter entrado na
máquina antes.

## O que o número não diz

**Uma nota base descreve a falha, não a sua situação.** Ela não sabe se o pacote escuta na rede na
sua máquina, se alguém o está explorando, nem se a máquina importa. Duas falhas de 7,5 podem ser a
emergência da semana num portal exposto à internet e nada numa estação em que o serviço nem roda. O
CVSS 4.0, publicado em 2023, divide a nota em grupos de base, ameaça e ambiente por esse motivo. A
próxima seção acrescenta as duas informações que a nota base deixa de fora, e deixa a política do
próprio escritório combiná-las.
