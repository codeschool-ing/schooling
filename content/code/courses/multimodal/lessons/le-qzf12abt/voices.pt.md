---
title: Escolhendo uma voz
version: 1
---

O laboratório tem três vozes Piper: **lessac**, inglês americano; **alan**, inglês britânico; e **faber**, português do Brasil. A mesma mensagem curta em cada uma:

```python
"""Speak a text with one of the lab's Piper voices and save it as a WAV."""
import sys
import time

import soundfile as sf

import mmlab

voice, text, out = sys.argv[1], sys.argv[2], sys.argv[3]
speed = float(sys.argv[4]) if len(sys.argv) > 4 else 1.0
tts = mmlab.piper(voice)
started = time.time()
audio = tts.generate(text, sid=0, speed=speed)
took = time.time() - started
seconds = len(audio.samples) / audio.sample_rate
sf.write(out, audio.samples, audio.sample_rate)
print(f"{out}: {seconds:.2f} s of audio at {audio.sample_rate} Hz, made in {took:.2f} s")
```

```
ana@lab:~/mm$ python say.py en_US-lessac-medium "Your order has shipped. It should arrive on Thursday." lessac.wav
lessac.wav: 2.76 s of audio at 22050 Hz, made in 0.22 s
ana@lab:~/mm$ python say.py en_GB-alan-medium "Your order has shipped. It should arrive on Thursday." alan.wav
alan.wav: 3.47 s of audio at 22050 Hz, made in 0.34 s
ana@lab:~/mm$ python say.py pt_BR-faber-medium "Seu pedido foi enviado. Deve chegar na quinta-feira." faber.wav
faber.wav: 2.82 s of audio at 22050 Hz, made in 0.32 s
ana@lab:~/mm$ grep -E "Language|Samplerate|URL|License" /opt/multimodal/share/vits-piper-en_US-lessac-medium/MODEL_CARD
* Language: en_US (English, United States)
* Samplerate: 22,050Hz
* URL: https://www.cstr.ed.ac.uk/projects/blizzard/2013/lessac_blizzard2013/
* License: https://www.cstr.ed.ac.uk/projects/blizzard/2013/lessac_blizzard2013/license.html
```

As três produzem **22.050 amostras por segundo**, o que é mais do que um telefone transporta (aula 5) e menos do que se usa para gravar música; é uma escolha comum para fala. As três fizeram o áudio muito mais rápido do que ele toca: a lessac fez 2,76 segundos de fala em 0,48 segundo, em quatro núcleos de processador comuns e sem placa de vídeo. A voz *alan* levou 3,47 segundos para as mesmas palavras, um quarto a mais: vozes diferem no ritmo como pessoas diferem, e um menu telefônico feito para uma fica longo com outra.

## O que olhar ao escolher

**A língua e o sotaque de quem ouve.** Um cliente brasileiro ouvindo a *lessac* ler português ouviria regras do inglês aplicadas a palavras em português. Uma voz é escolhida por língua, e para uma loja bilíngue isso significa duas vozes e uma decisão sobre qual delas lê uma frase que mistura as duas (a seção 04 mostra quanto isso custa).

**A licença, que mora em dois lugares.** A licença da própria voz cobre o modelo; o **conjunto de dados** com que ela foi treinada pode ter termos próprios, e eles podem ser mais estritos. Toda voz Piper vem com um cartão do modelo (model card), e ele aponta de onde vieram os dados, como mostra o último comando acima: a `lessac` foi treinada com um conjunto de dados lançado para o Blizzard Challenge 2013, uma avaliação de pesquisa, e o cartão aponta para a página de licença desse conjunto. Se uma voz pode atender a linha telefônica de uma loja comercial é uma pergunta que essa página responde, não o arquivo da voz; leia antes de pôr em produção, como a aula 11 faz para todo modelo do laboratório.

**Consentimento, para qualquer voz que soe como uma pessoa.** As vozes daqui foram gravadas por pessoas que concordaram em fazer um conjunto de dados de fala. A clonagem de voz, em que um modelo imita uma pessoa específica a partir de uma gravação curta, permite pôr palavras na boca de alguém. Uma loja não tem motivo para clonar a voz de ninguém sem consentimento por escrito, e os termos da maioria dos provedores proíbem isso.

**Dizer que é uma máquina.** Quem liga deveria saber que está falando com uma voz sintética. Uma frase no começo da ligação resolve, e em vários lugares isso é exigido por lei para chamadas automáticas. Também acerta as expectativas: as pessoas falam mais claramente com uma máquina que sabem ser uma máquina.
