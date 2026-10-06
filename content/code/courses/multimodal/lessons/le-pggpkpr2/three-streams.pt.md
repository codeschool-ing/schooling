---
title: O que há dentro de um arquivo de vídeo
version: 1
---

**Um arquivo de vídeo é um contêiner com vários fluxos**, e quase tudo o que um programa faz com vídeo começa tirando um deles para fora. O ffprobe os lista:

```
ana@lab:~/mm$ ffprobe -v error -show_entries stream=codec_type,codec_name,width,height,r_frame_rate,nb_frames,sample_rate -show_entries format=duration,size -of compact=nk=0 media/returns.mp4
stream|codec_name=h264|codec_type=video|width=1280|height=720|r_frame_rate=25/1|nb_frames=815
stream|codec_name=aac|codec_type=audio|sample_rate=44100|r_frame_rate=0/0|nb_frames=1405
format|duration=32.600000|size=495585
```

Dois fluxos. O **fluxo de vídeo** é H.264, 1280 por 720 pixels, 25 quadros por segundo: 815 quadros em 32,6 segundos. O **fluxo de áudio** é AAC a 44.100 amostras por segundo. O **contêiner**, MP4, os mantém juntos, sincronizados, e não acrescenta nada que um modelo leia. Outros arquivos podem ter mais fluxos: legendas, uma segunda faixa de áudio noutro idioma, capítulos.

Três fatos sobre o fluxo de vídeo decidem como um programa deve tratá-lo.

**A maioria dos quadros não é imagem.** O H.264 guarda uma imagem inteira só de vez em quando, como **quadro-chave** (keyframe), e entre os quadros-chave guarda as diferenças em relação ao quadro anterior. É assim que 815 quadros de 1280 por 720 cabem em menos de meio megabyte. Um programa que pede o quadro 300 faz o decodificador partir do último quadro-chave e aplicar cada diferença até ele, e por isso pular para um ponto é mais lento do que parece.

**Quadros seguidos são quase iguais.** A 25 quadros por segundo, um slide que fica cinco segundos na tela são 125 cópias de uma imagem. Mandar todas a um modelo seria pagar 125 vezes para ouvir a mesma coisa.

**Os dois fluxos compartilham um relógio.** Todo quadro e todo trecho de som têm um carimbo de tempo, e esse relógio é o que liga o que foi mostrado ao que foi dito. O resto desta aula guarda todo tempo em segundos desde o início do arquivo, porque esse é o único número em que os dois fluxos concordam.

Então entender um vídeo são três decisões: **que quadros olhar, como lê-los e como juntá-los de novo ao som.** Cada seção a seguir toma uma delas.
