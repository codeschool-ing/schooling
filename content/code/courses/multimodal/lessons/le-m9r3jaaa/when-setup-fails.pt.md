---
title: Quando a montagem falha
version: 1
---

A maioria das falhas deste laboratório vem de quatro lugares, e cada um avisa do seu jeito. Leia primeiro a última linha do erro.

**O labmm não está rodando.** Toda aula de API conversa com ele, e quando ele está fora do ar os SDKs informam um erro de conexão, não algo sobre imagens ou áudio. Confira diretamente:

```
ana@lab:~/mm$ curl -sS http://127.0.0.1:8700/
curl: (7) Failed to connect to 127.0.0.1 port 8700 after 0 ms: Couldn't connect to server
ana@lab:~/mm$ curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8700/
200
```

`Couldn't connect to server` significa que nada está escutando na porta 8700. `sudo bash lab.sh reset` o inicia de novo, e a segunda linha é o que um laboratório funcionando responde. Se ele não voltar, o erro dele está em `/run/labmm.out`.

**Um arquivo de modelo não é o que deveria ser.** Um download interrompido, ou um arquivo que alguém editou, carrega com um erro que cita uma camada ou um tensor, não o arquivo. O `lab.sh` confere todo modelo contra um SHA-256 antes de usá-lo, e você pode fazer a mesma conferência à mão. Aqui uma cópia do modelo de ruído recebeu um byte a mais:

```
ana@lab:~/mm$ echo "e77603ac0c23dac3227dd2d7135b3a585cbee2679048aecfa886657d3ae1b534  /tmp/gtcrn.onnx" | sha256sum -c
/tmp/gtcrn.onnx: FAILED
sha256sum: WARNING: 1 computed checksum did NOT match
ana@lab:~/mm$ echo "e77603ac0c23dac3227dd2d7135b3a585cbee2679048aecfa886657d3ae1b534  /opt/multimodal/share/gtcrn_simple.onnx" | sha256sum -c
/opt/multimodal/share/gtcrn_simple.onnx: OK
```

`FAILED` na cópia e `OK` no original. Apague o arquivo e rode `lab.sh up` de novo; ele baixa só o que falta.

**Falta uma biblioteca do sistema.** O MediaPipe desenha por OpenGL mesmo numa máquina sem tela, e num Ubuntu mínimo ele para com `OSError: libEGL.so.1: cannot open shared object file: No such file or directory`, que é o que ele disse na máquina em que este curso foi montado antes de o `libegl1` ser instalado. O `lab.sh up` instala `libegl1` e `libgles2` por esse motivo, junto com o ffmpeg, o Tesseract e as fontes DejaVu com que a mídia é desenhada.

**O disco está cheio.** O laboratório precisa de uns 2 GB. `df -h /opt /home` diz quanto sobra, e `/opt/multimodal/media` pode ser apagado e reconstruído a qualquer momento, já que o próximo `reset` o desenha de novo.

Se falhar algo que não está nesta lista, a última linha do erro continua sendo o ponto de partida. Procure por ela junto com o nome da biblioteca que a levantou, e diga isso onde pedir ajuda: "o sherpa-onnx levantou isto ao carregar o decodificador do Whisper" recebe resposta, e "o laboratório não funciona" não recebe.
