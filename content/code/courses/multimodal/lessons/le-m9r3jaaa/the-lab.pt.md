---
title: O seu próprio laboratório
version: 2
---

Todo programa deste curso roda num computador Linux, e a plataforma não lhe dá um: você o monta aqui, uma vez, e toda aula seguinte o usa. Ele guarda quatro coisas:

- **Python, com uma dúzia de bibliotecas**, para os programas curtos que as aulas imprimem inteiros;
- **um conjunto de modelos abertos e pequenos** para fala e imagem: o Whisper para ouvir, o Piper para falar, e os modelos que acham fala, separam vozes, limpam ruído e acham objetos numa fotografia;
- **o ffmpeg e o Tesseract**, as duas ferramentas de linha de comando que cortam, convertem e leem mídia;
- **o Ollama**, um programa gratuito que roda modelos de linguagem no seu próprio computador, sem conta e sem cartão, e **três modelos para ele**. O `llama3.2:3b` escreve texto, e é o mesmo modelo que todo curso de IA daqui usa, então talvez você já o tenha. O `qwen2.5vl:3b` lê imagens, o que o `llama3.2:3b` não faz; as aulas que mandam uma imagem a um modelo usam ele, e dizem isso. O `all-minilm` transforma texto em vetores para a busca da aula 12.

## Três jeitos de ter o computador

| caminho | o que você ganha | o que custa ao seu computador | as transcrições |
|---|---|---|---|
| **instalado** (recomendado) | Ubuntu 24.04 no seu computador, ou no WSL do Windows | uns 10 GB de disco, e uns 4 GB de memória enquanto o modelo de visão responde | batem com o impresso |
| **uma máquina virtual** | Ubuntu Server 24.04 LTS, separado do seu sistema | o mesmo, mais o sistema do próprio convidado e a memória que você der a ele | batem com o impresso, mais devagar |
| **online** | uma máquina Linux alugada por hora | nada no seu computador; uma conta por hora | perto, não exatas |

**Instalado é o caminho recomendado**, e os modelos são o motivo. Eles são de longe a coisa mais pesada do curso e rodam mais rápido no computador sem camadas. Uma máquina virtual reserva uma parte fixa da memória para si e, na maioria dos hipervisores, nem alcança a placa de vídeo. Tudo o que a montagem acrescenta fica em `/opt/multimodal`, `~/mm` e na pasta do próprio Ollama, e sai de novo apagando-os.

- **No Linux**, rode o script abaixo. Ele foi rodado no Ubuntu 24.04; outra distribuição tem os mesmos programas com os nomes de pacote dela.
- **No Windows**, instale o WSL com o Ubuntu 24.04 (`wsl --install -d Ubuntu-24.04` num PowerShell aberto como administrador, depois reinicie) e rode tudo na janela do Ubuntu.
- **No macOS**, o Ollama tem um aplicativo próprio em ollama.com, e o Homebrew tem Python, ffmpeg, Tesseract e espeak-ng. Isso não foi rodado para este curso: os modelos dão as mesmas respostas, e uma versão, um caminho ou um tempo numa transcrição vai ser diferente do seu.

**Uma máquina virtual** é o caminho para um computador que você prefere não mexer. Use o Ubuntu Server 24.04 LTS como convidado: VirtualBox no Windows e no Linux, UTM no macOS. Dê a ele quatro núcleos, 8 GB de memória e 30 GB de disco; o modelo de visão ocupa 3,2 GB dessa memória enquanto está carregado.

**Online**, qualquer provedor de nuvem aluga uma máquina Linux por hora. Escolha Ubuntu 24.04 com quatro núcleos e pelo menos 8 GB de memória. Uma cota gratuita pode cobrir parte do curso, em termos que a empresa define e pode mudar, então planeje como se fosse pagar. Isso não foi rodado para este curso.

**Com uma chave de API sua**, as aulas que chamam as APIs da OpenAI ou do Google funcionam contra os serviços de verdade, nos preços deles: troque os nomes dos modelos e aponte o SDK de volta para o provedor (o fim desta seção mostra onde). Nada no curso precisa de uma, e nenhuma foi usada para gravá-lo.

## O script

`setup.sh`, que faz tudo isso:

```sh
#!/bin/sh
# The multimodal course's lab, on Ubuntu 24.04: run it once as yourself, not as root.
#   packages      ffmpeg, Tesseract with Portuguese, espeak-ng, fonts, and what MediaPipe draws with
#   /opt/multimodal          Python's libraries for the course, in a virtual environment
#   /opt/multimodal/share    the models, each checked against its SHA-256
#   Ollama        the local model server, and the three models the lessons ask
set -e

sudo apt-get update
sudo apt-get install -y python3-venv ffmpeg tesseract-ocr tesseract-ocr-por espeak-ng \
  libegl1 libgles2 fonts-dejavu-core curl zstd unzip

sudo install -d -o "$(id -u)" -g "$(id -g)" /opt/multimodal
python3 -m venv /opt/multimodal
/opt/multimodal/bin/pip install sherpa-onnx==1.13.8 mediapipe==1.0.1 numpy==2.4.6 pillow==12.3.0 \
  soundfile==0.14.0 jiwer==4.0.0 openai==2.54.0 google-genai==2.28.0 tiktoken==0.14.0 \
  langchain-core==1.6.6 langchain-openai==1.6.7 llama-index-core==0.14.25 \
  llama-index-llms-openai==0.8.2 llama-index-llms-openai-like==0.8.1 num2words==0.5.14

SHARE=/opt/multimodal/share
mkdir -p $SHARE
cd $SHARE
S=https://github.com/k2-fsa/sherpa-onnx/releases/download
while read -r url sum; do
  name=${url##*/}
  [ -e "${name%.tar.bz2}" ] && continue          # already here from an earlier run
  curl -fsSL --retry 3 -o "$name" "$url"
  echo "$sum  $name" | sha256sum -c || { rm -f "$name"; exit 1; }
  case $name in *.tar.bz2) tar -xjf "$name" && rm "$name" ;; esac
done <<EOF
$S/asr-models/sherpa-onnx-whisper-tiny.tar.bz2 c46116994e539aa165266d96b325252728429c12535eb9d8b6a2b10f129e66b1
$S/asr-models/sherpa-onnx-whisper-base.tar.bz2 911b2083efd7c0dca2ac3b358b75222660dc09fb716d64fbfc417ba6c99ff3de
$S/tts-models/vits-piper-en_US-lessac-medium.tar.bz2 9e3febfacf0abf4270172d2958bcec246032b7e88efc2720840cc80c93de334e
$S/tts-models/vits-piper-en_GB-alan-medium.tar.bz2 a48d4017da0f77668b27bed63fe6e04dd64c6397e1fadad4f460efb0ef7c9012
$S/tts-models/vits-piper-pt_BR-faber-medium.tar.bz2 7add3f923ad6bc25ca8a192805fd1a64d1b3893e4611c4a9719545a825039a83
$S/speaker-segmentation-models/sherpa-onnx-pyannote-segmentation-3-0.tar.bz2 24615ee884c897d9d2ba09bb4d30da6bb1b15e685065962db5b02e76e4996488
$S/speaker-recongition-models/3dspeaker_speech_eres2net_base_sv_zh-cn_3dspeaker_16k.onnx 1a331345f04805badbb495c775a6ddffcdd1a732567d5ec8b3d5749e3c7a5e4b
$S/asr-models/silero_vad.onnx 9e2449e1087496d8d4caba907f23e0bd3f78d91fa552479bb9c23ac09cbb1fd6
$S/speech-enhancement-models/gtcrn_simple.onnx e77603ac0c23dac3227dd2d7135b3a585cbee2679048aecfa886657d3ae1b534
https://storage.googleapis.com/mediapipe-models/object_detector/efficientdet_lite0/float32/latest/efficientdet_lite0.tflite 40338edf5ec70d43e318b0a716a84d4564cd1802759a7a07170c7e43796dbf58
https://storage.googleapis.com/mediapipe-tasks/object_detector/cat_and_dog.jpg cfa90c34bb93021165e48bd22cfc20dbbb0440ff638a54878939bf30d362e824
EOF
rm -rf sherpa-onnx-whisper-*/test_wavs          # sample recordings that came in the archives

command -v ollama >/dev/null || curl -fsSL https://ollama.com/install.sh | sh
if ! ollama list >/dev/null 2>&1; then          # no systemd (WSL, a container): start it by hand
  nohup ollama serve >"$HOME/ollama.log" 2>&1 &
  sleep 5
fi
ollama pull llama3.2:3b
ollama pull qwen2.5vl:3b
ollama pull all-minilm

mkdir -p "$HOME/mm"
grep -q "^# multimodal" "$HOME/.bashrc" || cat >>"$HOME/.bashrc" <<'EOF'
# multimodal: the course's Python, and the OpenAI SDK pointed at the local Ollama
. /opt/multimodal/bin/activate
export OPENAI_BASE_URL=http://localhost:11434/v1 OPENAI_API_KEY=ollama
export GLOG_minloglevel=2
EOF
echo "done: open a new terminal, then cd ~/mm"
```

Salve-o na sua pasta pessoal e rode-o como você mesmo, não como root. Ele pede a sua senha uma vez, para as duas linhas com `sudo`:

```sh
sh setup.sh
```

Na máquina em que este curso foi gravado ele levou pouco mais de três minutos, quase todos de download: as bibliotecas Python, cerca de 1 GB de modelos de fala e imagem, e 5,2 GB dos três modelos do Ollama. Numa conexão mais lenta, essa última parte é a espera.

Três linhas dele merecem uma palavra. **Todo modelo é conferido contra um SHA-256** antes de ser guardado, e um download que não bate é apagado e para o script, então uma execução que termina tem exatamente os arquivos com que toda transcrição foi feita. **As bibliotecas Python estão fixadas** nas versões que as transcrições usaram: uma versão mais nova de qualquer uma delas tem o direito de imprimir outra coisa. E **as últimas linhas acrescentam quatro linhas ao seu `~/.bashrc`**: todo terminal novo começa dentro do Python do curso, com o SDK da OpenAI apontado para o Ollama na sua própria máquina, e não para a OpenAI. É por isso que os programas das aulas seguintes podem dizer `OpenAI()` e alcançar um modelo sem chave e sem conta. Para apontá-los de volta para a OpenAI, apague essas linhas e defina `OPENAI_API_KEY` com uma chave sua.

## Conferindo

Abra um terminal novo, para que o `~/.bashrc` seja lido, e vá para a pasta de trabalho:

```sh
cd ~/mm
```

As ferramentas, e os modelos que o Ollama tem:

```
ana@lab:~/mm$ python --version; ffmpeg -version | head -1; tesseract --version | head -1; ollama --version
Python 3.12.3
ffmpeg version 6.1.1-3ubuntu5 Copyright (c) 2000-2023 the FFmpeg developers
tesseract 5.3.4
ollama version is 0.40.0
ana@lab:~/mm$ ollama list
NAME                 ID              SIZE      MODIFIED               
all-minilm:latest    1b226e2802db    45 MB     Less than a second ago    
qwen2.5vl:3b         fb90415cde1e    3.2 GB    3 seconds ago             
llama3.2:3b          a80c4f17acd5    2.0 GB    25 seconds ago            
```

E o disco que ocupou:

```
ana@lab:~/mm$ du -sh /opt/multimodal ~/.ollama/models
1.8G	/opt/multimodal
5.0G	/home/ana/.ollama/models
ana@lab:~/mm$ cd /opt/multimodal/share && du -sh sherpa-onnx-whisper-* vits-piper-* *.onnx *.tflite | sort -h
524K	gtcrn_simple.onnx
632K	silero_vad.onnx
14M	efficientdet_lite0.tflite
38M	3dspeaker_speech_eres2net_base_sv_zh-cn_3dspeaker_16k.onnx
79M	vits-piper-en_GB-alan-medium
79M	vits-piper-en_US-lessac-medium
79M	vits-piper-pt_BR-faber-medium
244M	sherpa-onnx-whisper-tiny
432M	sherpa-onnx-whisper-base
```

Menos de sete gigabytes até aqui: 1,8 para as bibliotecas e os modelos de fala e imagem em `/opt/multimodal`, e 5,0 para os três do Ollama. Planeje dez, porque o modelo de visão ocupa uns três a mais na primeira vez que lê uma imagem; o fim da próxima seção mostra isso. As duas pastas do Whisper são grandes porque cada uma guarda o modelo duas vezes, em precisão total e em int8; a aula 11 compara as duas. A próxima seção faz a mídia, e então a aula 2 começa.
