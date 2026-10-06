---
title: Idioma: detectado, definido, e definido errado
version: 1
---

O Whisper foi treinado com muitas línguas de uma vez, e antes de transcrever ele decide qual está ouvindo. Você pode deixar que ele decida ou dizer a ele. O recado em português do laboratório, de três jeitos:

```python
"""The Portuguese voicemail, with the language left to Whisper, set right, and set wrong."""
import mmlab

samples = mmlab.read_audio("media/voicemail-pt.wav")
for language in ("", "pt", "en"):
    text, detected = mmlab.transcribe(mmlab.whisper("base", language=language), samples)
    print(f"asked {language or 'nothing':7} -> {detected}: {text}\n")
```

```
ana@lab:~/mm$ python language.py
asked nothing -> pt: Oi, aqui é o Rafael Piente da Marginalia, soligando sobre o pedido em 2002-1877, um exemplar de memórias postmas de brásculpas que chegou com a capa amassada. Vocês podem me ligar de volta no fim da tarde? Obrigado.

asked pt      -> pt: Oi, aqui é o Rafael Piente da Marginalia, soligando sobre o pedido em 2002-1877, um exemplar de memórias postmas de brásculpas que chegou com a capa amassada. Vocês podem me ligar de volta no fim da tarde? Obrigado.

asked en      -> en: Hey, here is Rafael Pienta from Marginalia, I'm calling on the episode in May 2007, an exemplary of memories of brass cubes that arrived with the mass cover. Can you send me a message back to you in the end of the afternoon? Thanks!
```

**Sozinho, ele detectou português** e escreveu português, com erros do tipo que você já conhece: *Piente* por *cliente*, *soligando* por *Estou ligando*, um número de pedido transformado em *2002-1877*, e o título *Memórias Póstumas de Brás Cubas* como *memórias postmas de brásculpas*.

**Avisado de que era português**, escreveu exatamente o mesmo. Definir o idioma que você já sabe estar certo poupa a etapa de detecção e tira um jeito de errar. A detecção num trecho curto ou ruidoso, ou num que começa com uma palavra em inglês, pode escolher a língua errada, e o próximo caso mostra quanto isso custa.

**Avisado de que era inglês, ele traduziu.** *Hey, here is Rafael Pienta from Marginalia, I'm calling on the episode in May 2007, an exemplary of memories of brass cubes...* O Whisper foi treinado para transcrever e para traduzir para o inglês, e mandado produzir inglês a partir de fala em português ele fez o segundo trabalho, mal e sem nenhum sinal de que tinha trocado de trabalho. *Episode in May 2007* por *pedido M-2087* e *brass cubes* por *Brás Cubas* são o que um modelo escreve quando entendeu os sons e não as palavras.

## Três regras para o idioma

1. **Defina o idioma quando souber.** A linha telefônica de uma loja no Brasil sabe; um canal marcado por país também.
2. **Quando não souber, detecte uma vez por gravação e guarde a resposta** ao lado da transcrição. Uma transcrição sem idioma registrado é uma que ninguém consegue conferir.
3. **Fala em línguas misturadas é o caso difícil.** A ligação do laboratório é em inglês com nomes em português, e o Whisper ouviu *Dom Casmurro* como *Dom Kazmuro*: regras do inglês para sons do português, o espelho da voz da aula 6 lendo *Machado* com um *ch* inglês. A correção para nomes é a próxima seção; a correção para frases inteiras em outra língua é detectar por trecho em vez de por arquivo.
