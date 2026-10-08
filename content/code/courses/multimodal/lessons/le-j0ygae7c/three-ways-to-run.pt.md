---
title: Um modelo, três jeitos de rodá-lo
version: 2
---

Um modelo publicado no Hub pode ser rodado de três jeitos amplos, e a escolha decide o que você instala, para onde vão os dados e quão rápido ele roda.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Um modelo publicado no Hub, no meio, em cima: openai/whisper-base, os pesos e o cartão. Três setas descem dele. À esquerda: transformers, os pesos originais em PyTorch rodados por Python, precisando do Hub ou de uma cópia dele. No meio: uma exportação ONNX, convertida uma vez e rodada pelo onnxruntime ou pelo sherpa-onnx, que é o que este laboratório faz. À direita: um provedor hospedado, Inference Providers ou um endpoint, em que o áudio sai da máquina.\"><defs><marker id=\"l11way-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l11way-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"240\" y=\"16\" width=\"240\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"250\" y=\"34.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">openai/whisper-base</text><text x=\"250\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pesos + cartão do modelo</text><line x1=\"360\" y1=\"70\" x2=\"120\" y2=\"118\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#l11way-ah-wire)\"></line><rect x=\"20\" y=\"120\" width=\"200\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"144.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">transformers</text><text x=\"30\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pesos PyTorch, Python</text><text x=\"30\" y=\"174.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">precisa do Hub ou de uma cópia</text><line x1=\"360\" y1=\"70\" x2=\"360\" y2=\"118\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#l11way-ah-phosphor)\"></line><rect x=\"260\" y=\"120\" width=\"200\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"270\" y=\"144.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">uma exportação ONNX</text><text x=\"270\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">convertida uma vez</text><text x=\"270\" y=\"174.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">este laboratório: sherpa-onnx</text><line x1=\"360\" y1=\"70\" x2=\"600\" y2=\"118\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#l11way-ah-wire)\"></line><rect x=\"500\" y=\"120\" width=\"200\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"510\" y=\"144.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">um provedor hospedado</text><text x=\"510\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Inference Providers</text><text x=\"510\" y=\"174.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o áudio sai da máquina</text><text x=\"20\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Os mesmos pesos, três jeitos de rodá-los; a escolha é sobre para onde vão os dados e o que precisa ser instalado.</text></svg>", "caption": "Todo modelo deste laboratório veio pelo caminho do meio: publicado no Hub, convertido para ONNX, rodado na máquina.", "same": ["Inference Providers"]}
```

O **transformers**, a biblioteca Python do Hugging Face, roda os pesos originais. Para reconhecimento de fala o programa inteiro são poucas linhas:

```python
from transformers import pipeline

asr = pipeline("automatic-speech-recognition", model="openai/whisper-base")
print(asr("media/call-1042.wav")["text"])
```

**Isto não foi rodado para este curso.** A primeira linha do `pipeline` baixa o modelo do Hub, e o Hub recusou a máquina em que o curso foi gravado:

```
ana@lab:~/mm$ curl -sS -m 10 -o /dev/null -w "%{http_code}\n" https://huggingface.co/api/models/openai/whisper-base
403
```

Numa máquina que alcança o Hub, essas três linhas são o jeito mais rápido de experimentar um modelo, e trazem o PyTorch junto, uma dependência de várias centenas de megabytes.

Uma **exportação ONNX** é o modelo convertido uma vez para um formato aberto e rodado por um runtime pequeno (o onnxruntime, ou o sherpa-onnx em cima dele). É assim que todo modelo deste laboratório roda: sem PyTorch, sem Hub na hora de rodar, o mesmo arquivo num notebook, num servidor ou num celular. O custo é que alguém precisa fazer a conversão, e nem todo modelo tem uma.

Um **provedor hospedado** roda o modelo por você: os Inference Providers do Hugging Face encaminham um pedido a uma empresa parceira, e os Inference Endpoints dão uma máquina dedicada. A aula 19 de `ai-models` os chama pelo SDK do Hugging Face. Nada é instalado, e **o áudio ou a imagem sai da sua máquina**, o que a seção de privacidade da aula 8 e a política da loja precisam permitir.

| | transformers | exportação ONNX | hospedado |
|---|---|---|---|
| instala | PyTorch e a biblioteca | um runtime pequeno | nada |
| precisa do Hub ao rodar | no primeiro uso | não | não |
| para onde vão os dados | ficam | ficam | para o provedor |
| custo | sua máquina | sua máquina | por chamada |
