---
title: Fazendo a voz ler números, datas e nomes direito
version: 1
---

**O teste mais barato de uma voz é deixar um transcritor ouvi-la.** Fale uma frase com o Piper, transcreva o áudio com o Whisper e compare. O que voltar diferente é um ponto em que quem ouve também pode entender outra coisa:

```python
"""Say each sentence with a Piper voice, then let Whisper write down what it heard in that voice's language."""
import sys

import soundfile as sf

import mmlab

voice = sys.argv[2] if len(sys.argv) > 2 else "en_US-lessac-medium"
tts = mmlab.piper(voice)
whisper = mmlab.whisper("base", language=voice[:2])
for line in open(sys.argv[1]):
    text = line.strip()
    audio = tts.generate(text, sid=0, speed=1.0)
    sf.write("/tmp/roundtrip.wav", audio.samples, audio.sample_rate)
    heard, _ = mmlab.transcribe(whisper, mmlab.read_audio("/tmp/roundtrip.wav"))
    print(f"said:  {text}\nheard: {heard}")
```

Três frases que a linha telefônica de uma loja diz todo dia, em `said.txt`:

```
Your order M-1042 arrived on 24/09/2026.
Your refund of R$ 34,80 is on its way.
Dom Casmurro, by Machado de Assis.
```

```
ana@lab:~/mm$ python roundtrip.py said.txt
said:  Your order M-1042 arrived on 24/09/2026.
heard: Your Order M 1042 arrived on 24/09/2021/26.
said:  Your refund of R$ 34,80 is on its way.
heard: Your refund of our $1.3480 is on its way.
said:  Dom Casmurro, by Machado de Assis.
heard: Dom Kismuro by Machado Desiss
```

As três voltaram erradas, e cada uma errada do jeito que os fonemas da seção 02 previam. *24/09/2026* voltou como *24/09/2021/26*: o Whisper ouviu "twenty twenty-one, twenty-six" em "two thousand twenty six". *R$ 34,80* voltou como *our $1.3480*: a voz disse "R dollar thirty four eighty", e o Whisper anotou um valor em dólar que não existe. E *Dom Casmurro, by Machado de Assis* voltou como *Dom Kismuro by Machado Desiss*.

**Uma ida e volta tem dois modelos, então uma diferença é uma suspeita, não um veredito.** O Whisper erra por conta própria (as aulas 4 e 7 estão cheias disso). Uma linha que volta diferente é uma linha para ouvir; uma linha que volta igual é indício, não prova, de que uma pessoa vai ouvir direito. Os fonemas do espeak-ng são a evidência direta: dizem exatamente o que a voz recebeu para dizer.

## A correção é escrever o que deve ser dito

```schooling-example
{
  "language": "python",
  "file": "spoken.py",
  "parts": [
    {
      "code": "\"\"\"Rewrite the things a voice reads badly into the words a person would say.\"\"\"\nimport re\nimport sys\n\n"
    },
    {
      "code": "DIGITS = \"zero one two three four five six seven eight nine\".split()\nMONTHS = (\"January February March April May June July August September October November \"\n          \"December\").split()\nORDINAL = {1: \"first\", 2: \"second\", 3: \"third\", 21: \"twenty-first\", 22: \"twenty-second\",\n           23: \"twenty-third\", 24: \"twenty-fourth\", 30: \"thirtieth\", 31: \"thirty-first\"}\n\n\n",
      "note": "**As palavras de que as reescritas precisam**: dígitos, meses e os poucos ordinais que as datas da Marginalia usam. Um sistema real usa uma biblioteca para isso; aqui o ponto é ver as regras."
    },
    {
      "code": "def order_id(m):                        # M-1042 -> \"M, one zero four two\"\n    return m[1] + \", \" + \" \".join(DIGITS[int(d)] for d in m[2])\n\n\n",
      "note": "**Um número de pedido é lido dígito a dígito**, com uma vírgula depois da letra para a voz fazer uma pausa. *One thousand forty-two* é uma quantidade; um número de pedido é um código."
    },
    {
      "code": "def date(m):                            # 24/09/2026 -> \"the twenty-fourth of September\"\n    day, month = int(m[1]), int(m[2])\n    return f\"the {ORDINAL.get(day, str(day) + 'th')} of {MONTHS[month - 1]}\"\n\n\n",
      "note": "**Uma data vira as palavras que uma pessoa diz**: o dia como ordinal e o mês pelo nome. O ano sai, como as pessoas fazem quando é o ano corrente."
    },
    {
      "code": "def reais(m):                           # R$ 34,80 -> \"34 reais and 80 centavos\"\n    return f\"{int(m[1])} reais\" + (f\" and {int(m[2])} centavos\" if int(m[2]) else \"\")\n\n\n",
      "note": "**Dinheiro em reais** ganha a moeda falada, o que o `R$` nunca tem: o espeak-ng o leu como *R dollar*."
    },
    {
      "code": "RULES = [(r\"\\b([A-Z])-(\\d{4})\\b\", order_id),\n         (r\"\\b(\\d{1,2})/(\\d{1,2})/\\d{4}\\b\", date),\n         (r\"R\\$ ?(\\d+),(\\d\\d)\\b\", reais)]\n\n\n",
      "note": "**As regras, na ordem em que rodam.** O número de pedido é casado antes que outra coisa pegue os dígitos dele."
    },
    {
      "code": "def spoken(text):\n    for pattern, rewrite in RULES:\n        text = re.sub(pattern, rewrite, text)\n    return text\n\n\n",
      "note": "**Uma função que o processo chama** em todo texto antes de a voz vê-lo."
    },
    {
      "code": "if __name__ == \"__main__\":\n    for line in open(sys.argv[1]):\n        print(spoken(line.strip()))",
      "note": "**Rodado como programa**, ele reescreve um arquivo linha a linha, que é como o teste de ida e volta abaixo o usa."
    }
  ]
}
```

```
ana@lab:~/mm$ python spoken.py said.txt | tee said-spoken.txt
Your order M, one zero four two arrived on the twenty-fourth of September.
Your refund of 34 reais and 80 centavos is on its way.
Dom Casmurro, by Machado de Assis.
ana@lab:~/mm$ python roundtrip.py said-spoken.txt
said:  Your order M, one zero four two arrived on the twenty-fourth of September.
heard: Your Order M-1042 arrived on the 24th of September.
said:  Your refund of 34 reais and 80 centavos is on its way.
heard: Your refund of 34 Rs and 80 centavos is on its way.
said:  Dom Casmurro, by Machado de Assis.
heard: Dom Kismuro by Machado Desiss
```

Agora o número do pedido volta como *M-1042*, a data como *the 24th of September*, e só *reais* é ouvido errado, como *Rs*, o palpite de um transcritor de inglês para uma palavra em português numa frase em inglês. As reescritas são regras que uma pessoa lê e testa, e esse é o ponto: uma voz lê o que receber, então **o que ela recebe é onde a qualidade se decide**.

Sistemas reais usam uma biblioteca dessas regras por língua em vez de três expressões regulares, e a maioria das vozes comerciais normaliza sozinha os casos comuns. O que é próprio da loja nunca está na biblioteca de ninguém: números de pedido, códigos de produto, o próprio nome da loja. Esses são sempre seus para escrever.

## Nomes em outra língua

O título voltou como *Dom Kismuro* pela voz em inglês, e truques de grafia não fazem uma voz em inglês falar português. Sobram duas opções honestas. **Usar a voz da língua do nome para o nome**, que é o que uma pessoa bilíngue faz. A voz em português diz o título assim, transcrito pelo Whisper em português:

`titulo.txt` traz o mesmo título do jeito que um brasileiro o diz:

```
Dom Casmurro, de Machado de Assis.
```

```
ana@lab:~/mm$ python roundtrip.py titulo.txt pt_BR-faber-medium
said:  Dom Casmurro, de Machado de Assis.
heard: Tom Casmogo de Machado de Assis.
```

Também não é perfeito: *Tom Casmogo de Machado de Assis*, com o autor agora certo e o nome do romance ainda não. **Ou dar os fonemas diretamente à voz**, o que muitos serviços comerciais de TTS permitem pelo elemento `<phoneme>` do SSML, e a que a próxima seção volta. Para uma loja que diz os mesmos vinte títulos todo dia, uma lista curta de pronúncias conferida uma vez por uma pessoa sai mais barata que as duas.
