---
title: A library and a runtime
version: 1
---

Lesson 12 ended on small models made for one task. Some are small enough to run where nobody
expects a model: in a web page, on the visitor's own machine, with no server answering for it.
**Transformers.js** is Hugging Face's library for that. It is the JavaScript counterpart of the
Python `transformers` library, with the same idea at the front: ask for a task and a model, get a
function.

This lesson runs JavaScript as well as Python, so it needs **Node.js**, version 22 or later, from
nodejs.org or your system's packages. Transformers.js comes from npm, into `~/desk` like any other
package:

```
ana@desk:~/desk$ node --version
v22.22.0
ana@desk:~/desk$ npm init -y > /dev/null && npm install @huggingface/transformers@4.3.0

added 46 packages, and audited 47 packages in 17s

12 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

Underneath, it is two halves, and the versions in ana's project show both:

```
ana@desk:~/desk$ grep -h "\"version\"" node_modules/@huggingface/transformers/package.json node_modules/onnxruntime-node/package.json node_modules/onnxruntime-web/package.json
  "version": "4.3.0",
  "version": "1.30.0",
  "version": "1.31.0-dev.20260914-8d85527a0",
```

**`@huggingface/transformers`** is the half that knows about models: it reads the configuration,
runs the tokenizer, picks the files and turns numbers back into labels. **ONNX Runtime** is the half
that does the arithmetic. ONNX is a file format for a model's computation, a graph of operations
with the weights inside it, and a runtime is what executes that graph. The library uses
`onnxruntime-node`, native code, when it runs in Node, and `onnxruntime-web`, compiled to
WebAssembly, when it runs in a browser. The two runtimes come from separate releases, and here
they are not even the same version.

## Precision is a file name

Lesson 3 section 04 said a model can be stored at several precisions. In a repository prepared
for Transformers.js, each precision is **a separate file** in `onnx/`, and the library's own
source says how it names them:

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

`fp32` is `model.onnx`; `q8` is `model_quantized.onnx`; `q4` is `model_q4.onnx`. The option that
picks one is `dtype`. Leave it out and the library picks for you, by device:

```
ana@desk:~/desk$ grep -A3 "^var DEFAULT_DEVICE_DTYPE_MAPPING = " node_modules/@huggingface/transformers/dist/transformers.node.mjs
var DEFAULT_DEVICE_DTYPE_MAPPING = Object.freeze({
  // NOTE: If not specified, will default to fp32
  [DEVICE_TYPES.wasm]: DATA_TYPES.q8
});
```

In Node, on the CPU, that means 32-bit floats. In a browser running WebAssembly, it means **8-bit**,
and so a different file. Section 05 shows what happens when that file is not there.
