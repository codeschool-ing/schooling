---
title: Quando a montagem falha
version: 2
---

A maioria das falhas desta montagem vem de seis lugares, e cada uma avisa do seu jeito. Leia primeiro a última linha do erro. Toda mensagem abaixo é uma que a máquina deste curso imprimiu.

**O Ollama não está rodando.** O instalador transforma o Ollama num serviço que inicia com o computador, e isso precisa do systemd. O WSL sem systemd, um contêiner ou um servidor mínimo não o têm, e o instalador avisa numa linha fácil de passar batido: `WARNING: systemd is not running`. Então tudo o que fala com um modelo falha, e não com uma mensagem sobre modelos:

```
ana@lab:~/mm$ ollama list
Error: could not connect to ollama server, run 'ollama serve' to start it
ana@lab:~/mm$ python -c "from openai import OpenAI; OpenAI().models.list()" 2>&1 | tail -1
openai.APIConnectionError: Connection error.
ana@lab:~/mm$ ollama list | head -1
NAME                                                                         ID              SIZE      MODIFIED           
```

O `ollama list` diz isso com todas as letras; o programa de uma aula só diz `Connection error.`, porque o SDK da OpenAI conhece um endereço e não o que deveria estar lá. Inicie o servidor à mão, e deixe-o rodando no próprio terminal ou em segundo plano:

```sh
nohup ollama serve > ~/ollama.log 2>&1 &
```

A última linha acima é um Ollama funcionando, respondendo de novo. No WSL, a solução duradoura é ligar o systemd (`[boot]` e `systemd=true` em `/etc/wsl.conf`, depois `wsl --shutdown` no Windows); o `setup.sh` já inicia o servidor para você quando não acha nenhum.

**O instalador do Ollama para logo no começo.** Num Ubuntu recém-instalado ele imprimiu `ERROR: This version requires zstd for extraction. Please install zstd and try again` na máquina deste curso, antes de o `zstd` estar nas primeiras linhas do `setup.sh`. Se você instalar o Ollama por conta própria, instale o `zstd` antes.

**Um terminal aberto antes da montagem não tem o Python do curso.** O `~/.bashrc` é lido quando um terminal começa, então uma janela que já estava aberta roda o Python do próprio Ubuntu, que não tem nenhuma das bibliotecas:

```
ana@lab:~/mm$ deactivate; python3 listen.py 2>&1 | tail -1
python3: can't open file '/home/ana/mm/listen.py': [Errno 2] No such file or directory
```

Abra um terminal novo, ou digite `. ~/.bashrc` neste.

**Um arquivo de modelo não é o que deveria ser.** Um download interrompido, ou um arquivo que alguém editou, carrega com um erro que cita uma camada ou um tensor, não o arquivo. O `setup.sh` confere todo modelo contra o seu SHA-256, e você pode fazer a mesma conferência à mão. Aqui uma cópia do modelo de ruído ganhou um byte a mais:

```
ana@lab:~/mm$ echo "e77603ac0c23dac3227dd2d7135b3a585cbee2679048aecfa886657d3ae1b534  /tmp/gtcrn.onnx" | sha256sum -c
/tmp/gtcrn.onnx: FAILED
sha256sum: WARNING: 1 computed checksum did NOT match
ana@lab:~/mm$ echo "e77603ac0c23dac3227dd2d7135b3a585cbee2679048aecfa886657d3ae1b534  /opt/multimodal/share/gtcrn_simple.onnx" | sha256sum -c
/opt/multimodal/share/gtcrn_simple.onnx: OK
```

`FAILED` na cópia e `OK` no original. Apague um arquivo que falha e rode `sh setup.sh` de novo: ele pula tudo o que já está lá e busca só o que falta.

**Falta uma biblioteca do sistema.** O MediaPipe desenha por OpenGL mesmo numa máquina sem tela, e num Ubuntu mínimo ele para com `OSError: libEGL.so.1: cannot open shared object file: No such file or directory`. Foi o que ele disse na máquina em que este curso foi feito, antes de o `libegl1` ser instalado, e é por isso que o `setup.sh` instala `libegl1` e `libgles2`.

**O disco está cheio.** O curso precisa de uns 10 GB, 8 deles dos modelos do Ollama, e um download que fica sem espaço para pela metade. `df -h ~` diz quanto sobra. O `media/` pode ser apagado a qualquer momento, já que o `make_media.py` o faz de novo, e `ollama rm` remove um modelo com que você terminou.

Se algo falhar que não está nesta lista, a última linha do erro continua sendo o lugar por onde começar. Procure por ela com o nome do programa que a imprimiu, e diga isso onde pedir ajuda: "o sherpa-onnx levantou isto ao carregar o decodificador do Whisper" recebe resposta, e "a montagem não funciona" não recebe.
