---
title: The same call, in a browser
version: 1
---

The reason Transformers.js exists is the next step: the same model, inside a web page. `sort.html`
is a text box, a button, and the pipeline call from section 04 with three settings changed for a
browser:

```html
<!doctype html>
<meta charset="utf-8">
<title>lantern-sorter</title>
<textarea id="mail" rows="6" cols="60">Hi, I moved last week. Can you send order LB-20511 to my new address instead?</textarea>
<button id="go" disabled>Sort</button>
<p id="out">loading the model…</p>
<script type="module">
import { pipeline, env } from "./node_modules/@huggingface/transformers/dist/transformers.min.js";
env.allowLocalModels = true;                  // in a browser this starts off
env.allowRemoteModels = false;                // nothing is fetched from the Hub
env.localModelPath = "./models/";             // served from this page's own address
env.backends.onnx.wasm.wasmPaths = "/node_modules/onnxruntime-web/dist/";

const classify = await pipeline("text-classification", "lantern-sorter", { dtype: "fp32" });
const out = document.getElementById("out"), go = document.getElementById("go");
go.disabled = false;
out.textContent = "ready";
go.onclick = async () => {
  const [top] = await classify(document.getElementById("mail").value);
  out.textContent = `${top.label} ${top.score.toFixed(3)}`;
};
</script>
```

A browser has no folder to read a model from, so **local** there means *from the page's own server*,
and it starts switched off. `wasmPaths` says where the runtime's WebAssembly lives; left alone, the
library fetches it from `cdn.jsdelivr.net`, a public CDN, which is a third party learning who opened
the page. ana serves `~/desk` with Python's own web server, in a second terminal, and leaves it
running:

```
ana@desk:~/desk$ python -m http.server 8600 --bind 127.0.0.1
Serving HTTP on 127.0.0.1 port 8600 (http://127.0.0.1:8600/) ...
```

Then ana opens `http://127.0.0.1:8600/sort.html` in a browser, opens the developer tools on the
**Network** tab, and presses **Sort**. Here is the same visit made by a headless Chromium, the
browser this course was recorded with, which prints what the page said and every request it made:

```
# headless Chromium 141.0.7390.37, http://127.0.0.1:8600/sort.html
console  WebGPU is experimental on this platform. See https://github.com/gpuweb/gpuweb/wiki/Implementation-Status#implementation-status
console  Failed to create WebGPU Context Provider
page     address-change 0.890
fetched  200      1106  127.0.0.1:8600/sort.html
fetched  200    581935  127.0.0.1:8600/node_modules/@huggingface/transformers/dist/transformers.min.js
fetched  200       326  127.0.0.1:8600/models/lantern-sorter/config.json
fetched  200        90  127.0.0.1:8600/models/lantern-sorter/tokenizer_config.json
fetched  200      4303  127.0.0.1:8600/models/lantern-sorter/tokenizer.json
fetched  200      4949  127.0.0.1:8600/models/lantern-sorter/onnx/model.onnx
fetched  200     53057  127.0.0.1:8600/node_modules/onnxruntime-web/dist/ort-wasm-simd-threaded.asyncify.mjs
fetched  200        90  127.0.0.1:8600/models/lantern-sorter/tokenizer_config.json
fetched  200  26861777  127.0.0.1:8600/node_modules/onnxruntime-web/dist/ort-wasm-simd-threaded.asyncify.wasm
9 requests, to 1 host: 127.0.0.1:8600
```


`address-change`, at 0.890. The two console lines are Chromium's, about WebGPU, which this headless
browser could not provide; the runtime ran on WebAssembly, the `.wasm` file in the list.

**Nine requests, one host.** The e-mail in the box never left the browser: there is no request
after the click. That is the property no API in lessons 6 to 9 can offer, and on a site where the
text is a customer's own message it can be the whole argument. lesson 2 section 07's question,
*where does the data go*, has the shortest possible answer.

The price is in the other column. The page fetched **27,507,633 bytes**, and the model was 9,668 of
them. The runtime's `.wasm` alone was 26,861,777. Every visitor downloads the runtime and the model
before the first answer, and then runs them on whatever device they have. With ana's model that is
nothing; with a real one, the model file is as large as lesson 3 section 03 computes, and it is
paid by the visitor's connection and the visitor's memory, not by a bill.

## The precision nobody chose

Section 02 said that, without `dtype`, a browser running WebAssembly asks for the 8-bit file. Take
the option out and open the page again:

```
ana@desk:~/desk$ sed "s/, { dtype: \"fp32\" }//" sort.html > sort-q8.html && grep -c dtype sort-q8.html
0
```

And in the browser, or the headless one:

```
# headless Chromium 141.0.7390.37, http://127.0.0.1:8600/sort-q8.html
console  Failed to load resource: the server responded with a status of 404 (File not found)
error    `local_files_only=true` or `env.allowRemoteModels=false` and file was not found locally at "./models/lantern-sorter/onnx/model_quantized.onnx".
page     loading the model… (no answer after 15 s)
fetched  200      1087  127.0.0.1:8600/sort-q8.html
fetched  200    581935  127.0.0.1:8600/node_modules/@huggingface/transformers/dist/transformers.min.js
fetched  200       326  127.0.0.1:8600/models/lantern-sorter/config.json
fetched  200      4303  127.0.0.1:8600/models/lantern-sorter/tokenizer.json
fetched  200        90  127.0.0.1:8600/models/lantern-sorter/tokenizer_config.json
fetched  200        90  127.0.0.1:8600/models/lantern-sorter/tokenizer_config.json
fetched  404       335  127.0.0.1:8600/models/lantern-sorter/onnx/model_quantized.onnx
7 requests, to 1 host: 127.0.0.1:8600
```

The library asked for `model_quantized.onnx`, the file the suffix table names for `q8`; ana's
repository has only the 32-bit one, so the server answered 404 and the page never became ready. With
remote models allowed, the same request would have gone to the Hub instead. **The model a page runs
is decided by a default that differs between Node and the browser**, so a program tested in Node and
shipped in a page can run a different file. Naming the `dtype` makes it the same file in both.

## When it is the right place

A model in the page suits a task that is small, fixed and private: sorting, detecting a language,
scoring a sentence. It does not suit lesson 1's chat models, whose weights run to gigabytes. And it
moves lesson 3's operations onto the visitor's device: ana can no longer see how fast it runs or
whether it failed, unless the page reports it.
