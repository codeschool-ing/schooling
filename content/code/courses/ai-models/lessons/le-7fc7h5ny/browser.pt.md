---
title: A mesma chamada, num navegador
version: 1
---

O motivo de o Transformers.js existir é o passo seguinte: o mesmo modelo, dentro de uma página web.
O `sort.html` é uma caixa de texto, um botão e a chamada de pipeline da seção 04 com três ajustes
trocados para um navegador:

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

Um navegador não tem pasta de onde ler um modelo, então **local** lá quer dizer *do próprio servidor
da página*, e começa desligado. O `wasmPaths` diz onde fica o WebAssembly do runtime; sem ele, a
biblioteca o busca no `cdn.jsdelivr.net`, uma CDN pública, o que é um terceiro sabendo quem abriu a página. A ana serve o
`~/desk` com o `http.server` do Python na própria máquina, e o `browse` (um Chromium headless, no
lugar dela) abre a página e aperta o botão:

```
ana@desk:~/desk$ browse http://127.0.0.1:8600/sort.html
console  WebGPU is experimental on this platform. See https://github.com/gpuweb/gpuweb/wiki/Implementation-Status#implementation-status
console  Failed to create WebGPU Context Provider
page     address-change 0.890
fetched  200      1106  127.0.0.1:8600/sort.html
fetched  200    581935  127.0.0.1:8600/node_modules/@huggingface/transformers/dist/transformers.min.js
fetched  200       326  127.0.0.1:8600/models/lantern-sorter/config.json
fetched  200      4303  127.0.0.1:8600/models/lantern-sorter/tokenizer.json
fetched  200        90  127.0.0.1:8600/models/lantern-sorter/tokenizer_config.json
fetched  200      4949  127.0.0.1:8600/models/lantern-sorter/onnx/model.onnx
fetched  200     53057  127.0.0.1:8600/node_modules/onnxruntime-web/dist/ort-wasm-simd-threaded.asyncify.mjs
fetched  200        90  127.0.0.1:8600/models/lantern-sorter/tokenizer_config.json
fetched  200  26861777  127.0.0.1:8600/node_modules/onnxruntime-web/dist/ort-wasm-simd-threaded.asyncify.wasm
9 requests, to 1 host: 127.0.0.1:8600
```

`address-change`, com 0,890. As duas linhas de console são do Chromium, sobre WebGPU, que este
navegador headless não conseguiu oferecer; o runtime rodou em WebAssembly, o arquivo `.wasm` da
lista.

**Nove requisições, um host.** O e-mail da caixa nunca saiu do navegador: não há requisição depois
do clique. Essa é a propriedade que nenhuma API das aulas 6 a 9 consegue oferecer, e num site em que
o texto é a mensagem do próprio cliente ela pode ser o argumento inteiro. A pergunta da seção 07 da
aula 2, *para onde vão os dados*, tem a resposta mais curta possível.

O preço está na outra coluna. A página baixou **27.507.633 bytes**, e o modelo era 9.668 deles. Só
o `.wasm` do runtime tinha 26.861.777. Todo visitante baixa o runtime e o modelo antes da primeira
resposta, e depois roda os dois no aparelho que tiver. Com o modelo da ana isso não é nada; com um
de verdade, o arquivo do modelo é do tamanho que a seção 03 da aula 3 calcula, e quem paga é a
conexão e a memória do visitante, não uma conta.

## A precisão que ninguém escolheu

A seção 02 disse que, sem `dtype`, um navegador rodando WebAssembly pede o arquivo de 8 bits. Tire a
opção e abra a página de novo:

```
ana@desk:~/desk$ sed "s/, { dtype: \"fp32\" }//" sort.html > sort-q8.html && grep -c dtype sort-q8.html
0
ana@desk:~/desk$ browse http://127.0.0.1:8600/sort-q8.html --wait 15
console  Failed to load resource: the server responded with a status of 404 (File not found)
error    `local_files_only=true` or `env.allowRemoteModels=false` and file was not found locally at "./models/lantern-sorter/onnx/model_quantized.onnx".
page     loading the model… (no answer after 15 s)
fetched  200      1087  127.0.0.1:8600/sort-q8.html
fetched  200    581935  127.0.0.1:8600/node_modules/@huggingface/transformers/dist/transformers.min.js
fetched  200       326  127.0.0.1:8600/models/lantern-sorter/config.json
fetched  200        90  127.0.0.1:8600/models/lantern-sorter/tokenizer_config.json
fetched  200      4303  127.0.0.1:8600/models/lantern-sorter/tokenizer.json
fetched  200        90  127.0.0.1:8600/models/lantern-sorter/tokenizer_config.json
fetched  404       335  127.0.0.1:8600/models/lantern-sorter/onnx/model_quantized.onnx
7 requests, to 1 host: 127.0.0.1:8600
```

A biblioteca pediu `model_quantized.onnx`, o arquivo que a tabela de sufixos dá para `q8`; o
repositório da ana só tem o de 32 bits, então o servidor respondeu 404 e a página nunca ficou pronta.
Com modelos remotos permitidos, o mesmo pedido teria ido para o Hub. **O modelo que uma página roda
é decidido por um padrão que muda entre o Node e o navegador**, então um programa testado no Node e
publicado numa página pode rodar outro arquivo. Dizer o `dtype` faz dele o mesmo arquivo nos dois.

## Quando é o lugar certo

Um modelo dentro da página serve a uma tarefa pequena, fixa e privada: classificar, detectar um
idioma, dar nota a uma frase. Não serve aos modelos de chat da aula 1, cujos pesos chegam a
gigabytes. E ele leva as operações da aula 3 para o aparelho do visitante: a ana deixa de ver com
que velocidade roda ou se falhou, a não ser que a página conte.
