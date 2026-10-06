---
title: O laboratório deste curso
version: 1
---

Toda transcrição deste curso foi gravada numa máquina Linux montada pelo `lab.sh`, que fica ao lado do `course.json`. É o mesmo tipo de laboratório de `agents-mcp` e `embeddings-vectors`, e reaproveita a livraria deles: os 60 livros vêm de `embeddings-vectors`, e o leitor da tabela de preços vem de `ai-models`. Monte-o uma vez:

```sh
sudo bash lab.sh up
```

Ele cria o usuário `ana`, um ambiente virtual Python em `/opt/multimodal` com todas as bibliotecas que as aulas importam, fixadas no script, os modelos, a mídia, e o labmm, o provedor com que as aulas de API conversam. O `captures.sh` de cada aula começa com `lab.sh reset`, que reconstrói o `~/mm` do zero.

```
ana@lab:~/mm$ curl -s http://127.0.0.1:8700/; echo
{"labmm": "a stand-in provider; see lab/labmm.py", "models": ["lab-flash-image", "lab-image-1", "lab-tts-1", "lab-vision-1", "lab-whisper-base", "lab-whisper-tiny"]}
ana@lab:~/mm$ ls media media/truth
media:
call-1042-noisy.wav
call-1042-phone.wav
call-1042.wav
cat_and_dog.jpg
cover-b39.png
invoice-0931-scan.jpg
invoice-0931.png
returns.mp4
truth
voicemail-pt.wav

media/truth:
call-1042.json
call-1042.txt
invoice-0931.json
invoice-0931.txt
returns.json
returns.txt
voicemail-pt.json
voicemail-pt.txt
ana@lab:~/mm$ du -sh /opt/multimodal/share /opt/multimodal/lib /opt/multimodal/media
1.1G	/opt/multimodal/share
933M	/opt/multimodal/lib
5.0M	/opt/multimodal/media
ana@lab:~/mm$ python -c "import mmlab; print([n for n in dir(mmlab) if callable(getattr(mmlab, n)) and not n.startswith(\"_\") and n[0].islower() and n not in (\"np\", \"os\", \"subprocess\", \"sherpa_onnx\")])"
['denoiser', 'detector', 'diarizer', 'piper', 'read_audio', 'speech_segments', 'transcribe', 'whisper']
```

O `mmlab` é um módulo do próprio laboratório, com oito funções curtas, e todo programa do curso importa os modelos dele. Ele sabe onde estão os arquivos de cada modelo e os carrega com as configurações de que as aulas precisam. A aula 6 explica a única configuração que importa, a que faz uma voz dizer uma frase do mesmo jeito duas vezes.

## O que é real e o que é substituto

Este curso tem uma mistura incomum, então diz isso com clareza.

**Real, e rodando na máquina:** o Whisper (dois tamanhos) para fala em texto, três vozes do Piper para texto em fala, o pyannote e o 3D-Speaker para separar falantes, o Silero para achar a fala, o GTCRN para tirar ruído, o EfficientDet do MediaPipe para achar objetos, e o Tesseract para ler texto em imagens. Quando uma transcrição mostra o que um deles disse, foi isso que ele disse.

**Um substituto:** nenhuma API de provedor podia ser alcançada da máquina em que o curso foi gravado, e uma chave de API é uma conta que um curso não pode distribuir. Então o **labmm** responde no lugar, em `127.0.0.1:8700`. Ele fala o formato de rede das APIs da OpenAI e do Google com fidelidade suficiente para que os SDKs delas conversem com ele sem modificação. Atrás das rotas de áudio, ele roda o Whisper e o Piper reais acima. Atrás das rotas de visão e de imagem **não há modelo**: o que ele diz sobre uma imagem foi escrito pelo curso, e as imagens que ele devolve são cartões que dizem *no model drew this*. Toda aula que mostra uma dessas respostas diz isso ao lado.

**Feito para o curso:** toda imagem, gravação e vídeo em `~/mm/media`, exceto uma fotografia. Um programa do laboratório os desenhou e os falou a partir de um roteiro, então `media/truth` guarda o que cada um realmente diz.

## Quanto isso custa ao seu computador

```
ana@lab:~/mm$ cd /opt/multimodal/share && du -sh sherpa-onnx-whisper-* vits-piper-* *.onnx *.tflite all-MiniLM-L6-v2 | sort -h
524K	gtcrn_simple.onnx
632K	silero_vad.onnx
14M	efficientdet_lite0.tflite
38M	3dspeaker_speech_eres2net_base_sv_zh-cn_3dspeaker_16k.onnx
79M	vits-piper-en_GB-alan-medium
79M	vits-piper-en_US-lessac-medium
79M	vits-piper-pt_BR-faber-medium
88M	all-MiniLM-L6-v2
244M	sherpa-onnx-whisper-tiny
432M	sherpa-onnx-whisper-base
```

Uns 2 GB ao todo: 1,1 GB de modelos e arquivos compartilhados e 933 MB de bibliotecas, que é a linha do `du` lá em cima. As duas pastas do Whisper são grandes porque cada uma guarda o modelo duas vezes, em precisão completa e em int8; a aula 11 compara as duas. A montagem precisa da rede uma vez, para baixar as bibliotecas do PyPI e do npm e os modelos dos releases do sherpa-onnx no GitHub, do bucket do MediaPipe e do bucket do Chroma. Todo modelo é conferido contra um SHA-256 escrito no `lab.sh` antes de ser usado.

| caminho | o que exige | |
|---|---|---|
| **uma máquina Linux em que você tem root**, Ubuntu 24.04 | Python 3.11, Node.js 22, uns 2 GB de disco e 4 GB de memória | **recomendado**, e aquele em que toda transcrição foi gravada |
| uma máquina virtual com Ubuntu 24.04 | o mesmo, mais o da própria VM: dê a ela 6 GB de memória e 20 GB de disco | para Windows e macOS |
| um ambiente de desenvolvimento na nuvem que dê root | os mesmos pacotes | não testado por este curso |
