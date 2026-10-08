---
title: Uma biblioteca e um runtime
version: 1
---

A aula 12 terminou em modelos pequenos feitos para uma tarefa. Alguns são pequenos o bastante para
rodar onde ninguém espera um modelo: numa página web, na máquina do próprio visitante, sem servidor
respondendo por ele. **Transformers.js** é a biblioteca do Hugging Face para isso. É a contrapartida
em JavaScript da biblioteca `transformers` de Python, com a mesma ideia na frente: peça uma tarefa
e um modelo, receba uma função.

Esta aula roda JavaScript além de Python, então precisa do **Node.js**, versão 22 ou mais nova, de
nodejs.org ou dos pacotes do seu sistema. O Transformers.js vem do npm, para dentro de `~/desk` como
qualquer outro pacote:

```
ana@desk:~/desk$ node --version
v22.22.0
ana@desk:~/desk$ npm init -y > /dev/null && npm install @huggingface/transformers@4.3.0

added 46 packages, and audited 47 packages in 17s

12 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

Por baixo, são duas metades, e as versões no projeto da ana mostram as duas:

```
ana@desk:~/desk$ grep -h "\"version\"" node_modules/@huggingface/transformers/package.json node_modules/onnxruntime-node/package.json node_modules/onnxruntime-web/package.json
  "version": "4.3.0",
  "version": "1.30.0",
  "version": "1.31.0-dev.20260914-8d85527a0",
```

**`@huggingface/transformers`** é a metade que entende de modelos: lê a configuração, roda o
tokenizador, escolhe os arquivos e transforma números de volta em rótulos. **ONNX Runtime** é a
metade que faz a conta. ONNX é um formato de arquivo para a computação de um modelo, um grafo de
operações com os pesos dentro, e um runtime é o que executa esse grafo. A biblioteca usa o
`onnxruntime-node`, código nativo, quando roda no Node, e o `onnxruntime-web`, compilado para
WebAssembly, quando roda num navegador. Os dois runtimes saem em lançamentos separados, e aqui nem
a versão é a mesma.

## Precisão é um nome de arquivo

A seção 04 da aula 3 disse que um modelo pode ser guardado em várias precisões. Num repositório
preparado para o Transformers.js, cada precisão é **um arquivo separado** em `onnx/`, e o próprio
código da biblioteca diz como os nomeia:

```
ana@desk:~/desk$ grep -A13 "^var DEFAULT_DTYPE_SUFFIX_MAPPING = " node_modules/@huggingface/transformers/dist/transformers.node.mjs
var DEFAULT_DTYPE_SUFFIX_MAPPING = Object.freeze({
  [DATA_TYPES.fp32]: "",
  [DATA_TYPES.fp16]: "_fp16",
  [DATA_TYPES.int8]: "_int8",
  [DATA_TYPES.uint8]: "_uint8",
  [DATA_TYPES.q8]: "_quantized",
  [DATA_TYPES.q4]: "_q4",
  [DATA_TYPES.q2]: "_q2",
  [DATA_TYPES.q1]: "_q1",
  [DATA_TYPES.q4f16]: "_q4f16",
  [DATA_TYPES.q2f16]: "_q2f16",
  [DATA_TYPES.q1f16]: "_q1f16",
  [DATA_TYPES.bnb4]: "_bnb4"
});
```

`fp32` é `model.onnx`; `q8` é `model_quantized.onnx`; `q4` é `model_q4.onnx`. A opção que escolhe
um deles é `dtype`. Sem ela, a biblioteca escolhe por você, conforme o dispositivo:

```
ana@desk:~/desk$ grep -A3 "^var DEFAULT_DEVICE_DTYPE_MAPPING = " node_modules/@huggingface/transformers/dist/transformers.node.mjs
var DEFAULT_DEVICE_DTYPE_MAPPING = Object.freeze({
  // NOTE: If not specified, will default to fp32
  [DEVICE_TYPES.wasm]: DATA_TYPES.q8
});
```

No Node, na CPU, isso quer dizer floats de 32 bits. Num navegador rodando WebAssembly, quer dizer
**8 bits**, e portanto outro arquivo. A seção 05 mostra o que acontece quando esse arquivo não está
lá.
