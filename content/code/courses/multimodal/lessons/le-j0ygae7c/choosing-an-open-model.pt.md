---
title: Escolhendo um modelo aberto para um trabalho
version: 1
---

Todo modelo deste laboratório foi escolhido pelo mesmo punhado de perguntas, e são as que valem para qualquer modelo aberto no Hub.

```
ana@lab:~/mm$ cd /opt/multimodal/share && for f in silero_vad.onnx gtcrn_simple.onnx efficientdet_lite0.tflite 3dspeaker_speech_eres2net_base_sv_zh-cn_3dspeaker_16k.onnx sherpa-onnx-pyannote-segmentation-3-0/model.onnx vits-piper-en_US-lessac-medium/en_US-lessac-medium.onnx sherpa-onnx-whisper-tiny/tiny-encoder.int8.onnx; do printf "%10s  %s\n" $(stat -c %s $f) $f; done
    643854  silero_vad.onnx
    535638  gtcrn_simple.onnx
  13836895  efficientdet_lite0.tflite
  39593761  3dspeaker_speech_eres2net_base_sv_zh-cn_3dspeaker_16k.onnx
   5992913  sherpa-onnx-pyannote-segmentation-3-0/model.onnx
  63149198  vits-piper-en_US-lessac-medium/en_US-lessac-medium.onnx
  12937772  sherpa-onnx-whisper-tiny/tiny-encoder.int8.onnx
```

**Qual o tamanho, e onde ele vai rodar?** Os modelos do laboratório vão dos 644 kilobytes do Silero aos 63 megabytes da voz lessac e aos 160 do Whisper base. Todos rodam em quatro núcleos de processador comuns sem placa de vídeo, e foi por isso que foram escolhidos: uma voz num menu telefônico ou um detector num formulário de devolução tem de rodar na máquina que a loja tiver. Um modelo de visão e linguagem de vários bilhões de parâmetros é outra classe de máquina.

**Ele faz o trabalho com os meus dados?** A resposta é uma medida, nunca um ranking. A aula 5 descobriu que o redutor de ruído que soava mais limpo não era o que ajudava o Whisper; a aula 7 descobriu que um modelo maior não comprava nada em áudio ruim. Um ranking é o conjunto de teste de outra pessoa.

**O que a licença permite?** A corrente da seção 03: o modelo, o cartão dele, o conjunto de dados dele. Uma voz CC0 e uma voz só para pesquisa parecem iguais numa pasta.

**Consigo rodá-lo do jeito que preciso?** Uma exportação ONNX, um modelo do Hub que o transformers suporta, ou só um endpoint hospedado: a tabela da seção 04. Um modelo que só existe como pesos num formato incomum é um projeto de conversão antes de ser um componente.

**Quem o mantém funcionando?** Um modelo mantido por um projeto ativo recebe correções e conversões; um publicado uma vez e deixado de lado continuará o mesmo arquivo daqui a cinco anos, o que é tranquilizador ou um alerta, conforme o que mudar em volta dele.

Nenhuma dessas perguntas se responde pela popularidade do modelo. Um modelo com milhões de downloads pode estar errado para uma linha telefônica em português do Brasil, e um pequeno e especializado pode estar exatamente certo.
