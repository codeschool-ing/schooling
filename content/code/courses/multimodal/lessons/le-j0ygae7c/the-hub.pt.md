---
title: As tarefas multimodais do Hub
version: 1
---

A aula 12 de `ai-models` apresentou o Hugging Face Hub: modelos, conjuntos de dados, a taxonomia de tarefas, e modelos da comunidade ao lado dos que os grandes laboratórios publicam. Esta seção só acrescenta a metade multimodal dessa taxonomia, porque o rótulo de **tarefa** do Hub é o jeito mais rápido de achar um modelo para um trabalho deste curso.

| a tarefa do Hub | entrada → saída | a aula que faz esse trabalho |
|---|---|---|
| `automatic-speech-recognition` | áudio → texto | 7 e 10 (Whisper) |
| `text-to-speech` | texto → áudio | 6 (Piper) |
| `voice-activity-detection` | áudio → fala ou não | 5 (Silero) |
| `object-detection` | imagem → caixas e rótulos | 2 (EfficientDet) |
| `image-to-text` | imagem → legenda | 2 |
| `image-text-to-text` | imagem e texto → texto | 2 e 8 (modelos de visão e linguagem) |
| `document-question-answering` | imagem de documento e pergunta → resposta | 2 |
| `text-to-image` | texto → imagem | 3 e 9 |
| `zero-shot-image-classification` | imagem e rótulos candidatos → notas | 2 |
| `video-text-to-text` | vídeo e texto → texto | 4 |
| `any-to-any` | várias entradas, várias saídas | 1 (modelos multimodais nativos) |

Dois nomes de tarefa merecem uma olhada mais de perto.

**`image-text-to-text` é onde estão os modelos de visão e linguagem**: modelos abertos como Qwen2.5-VL, Llama 3.2 Vision, Gemma 3 e SmolVLM, de tamanhos muito diferentes. As menores versões do SmolVLM rodam num notebook; as grandes precisam de uma placa de vídeo com dezenas de gigabytes. O Qwen2.5-VL é a família do `qwen2.5vl:3b`, o modelo de visão que este curso roda pelo Ollama, que o busca no seu próprio repositório e não no Hub.

**`zero-shot-image-classification` é o primo de vocabulário aberto do detector da aula 2.** Um modelo no estilo do CLIP dá notas a uma imagem contra rótulos que você escreve na hora do pedido ("um livro danificado", "uma nota fiscal", "um gato"), e a lista fechada de 80 classes do COCO deixa de ser um limite. É barato e rápido, e responde *qual destes*, nunca *o que é isto*.

Toda página de modelo mostra a tarefa, a licença, o número de downloads e, em muitos casos, um **cartão do modelo** (model card): o assunto da próxima seção.
