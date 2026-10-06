---
title: Som como números
version: 1
---

**Uma gravação é uma lista de números, cada um a pressão do ar no microfone num instante.** Três propriedades dessa lista decidem quase tudo sobre como um modelo a trata:

- a **taxa de amostragem**, quantos números por segundo;
- a **profundidade de bits** ou codificação, quanto espaço cada número tem;
- os **canais**, quantas listas correm lado a lado (um para mono, dois para estéreo).

A ligação de suporte do laboratório existe em duas formas, e as duas diferem em tudo isso que importa:

```
ana@lab:~/mm$ python -c "import soundfile as sf; [print(f, sf.info(f).samplerate, sf.info(f).channels, sf.info(f).subtype, round(sf.info(f).duration, 2)) for f in (\"media/call-1042.wav\", \"media/call-1042-phone.wav\")]"
media/call-1042.wav 16000 1 PCM_16 55.38
media/call-1042-phone.wav 8000 1 ULAW 55.38
ana@lab:~/mm$ python -c "print(16000 * 2 * 55.3835, 8000 * 1 * 55.3835)"
1772272.0 443068.0
ana@lab:~/mm$ stat -c "%s %n" media/call-1042.wav media/call-1042-phone.wav
1772316 media/call-1042.wav
443126 media/call-1042-phone.wav
```

A ligação limpa são 16.000 amostras por segundo de números de 16 bits, 2 bytes cada. Multiplique por 55,3835 segundos e dá 1.772.272 bytes; o arquivo tem 1.772.316, e os 44 bytes a mais são o cabeçalho WAV dizendo como ler o resto. A versão de telefone são 8.000 amostras por segundo em μ-law, uma codificação que espreme cada amostra em 1 byte gastando a precisão nos sons baixos: um quarto do tamanho.

**O que a taxa de amostragem custa é o agudo do som.** Uma gravação só guarda frequências até metade da sua taxa de amostragem (o limite de **Nyquist**), então áudio a 16 kHz guarda até 8 kHz e áudio de telefone até 4 kHz. A versão de telefone também foi filtrada para 300 a 3.400 Hz, a faixa que as redes de telefonia transportam. A fala sobrevive a isso: quase tudo o que torna as palavras inteligíveis está dentro dela, e por isso ligações funcionam. Música não sobrevive, e algumas consoantes, *s* e *f* especialmente, perdem muito do que as distingue.

**Modelos de fala são treinados numa taxa fixa.** O Whisper espera 16.000 amostras por segundo, e o Silero, o pyannote e os modelos de falante desta aula também. Qualquer outra coisa é reamostrada antes: o `mmlab.read_audio` pede ao ffmpeg 16 kHz mono, seja o que for que o arquivo tenha. Reamostrar para cima não devolve o que nunca foi gravado, então a ligação de telefone chega ao Whisper a 16 kHz sem nada acima de 3.400 Hz. A aula 7 mede quanto isso custa.

**Estéreo é uma decisão, não um detalhe.** Muitos sistemas de atendimento gravam o atendente num canal e o cliente no outro. Essa é a separação de falantes mais barata que existe, e ela se perde no momento em que alguém mistura o arquivo em mono, que é o que `-ac 1` faz. Se você controla a gravação, mantenha os canais separados.
