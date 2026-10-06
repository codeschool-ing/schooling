---
title: Geolocalização: perguntando onde o usuário está
version: 1
---

**`navigator.geolocation.getCurrentPosition(sucesso, falha)` pede ao navegador a posição do
usuário**, e o navegador pergunta ao usuário. Um site de bibliotecas a usa para listar as unidades
próximas:

```html
<!doctype html>
<button id="where">Find libraries near me</button>
<script>
  document.querySelector("#where").addEventListener("click", () => {
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const { latitude, longitude, accuracy } = pos.coords;
        console.log("at", latitude.toFixed(4), longitude.toFixed(4), "within", accuracy, "m");
      },
      (err) => console.log("no position:", err.code, err.message),
      { timeout: 5000 },
    );
  });
</script>
```

```
ana@dev:~/js$ page where.html --fresh --do 'click #where' --wait 500
-- click #where
no position: 1 User denied Geolocation
```

```
ana@dev:~/js$ page where.html --fresh --geo -23.5503,-46.6339 --do 'click #where' --wait 500
-- click #where
at -23.5503 -46.6339 within 0 m
```

As duas execuções foram encenadas, como diz o cabeçalho do script. Na primeira, o navegador do
laboratório respondeu ao pedido como um usuário que clicou em **Bloquear**: **o callback de falha rodou
com o código 1, `PERMISSION_DENIED`**. Na segunda, o `page --geo` concedeu a permissão e forneceu uma
posição, as coordenadas da Praça da Sé em São Paulo, então o callback de sucesso rodou com elas. Um
aparelho de verdade informa uma `accuracy` em metros, maior em ambiente fechado e pelo Wi-Fi de um
notebook do que pelo GPS de um celular; a posição encenada do laboratório alega 0.

## Escrevendo para funcionar para todo mundo

- **peça quando o usuário fizer algo que precise disso**, como o botão aqui, nunca ao carregar a
  página. Um pedido que aparece antes de o usuário saber por quê é o que ele bloqueia, e depois de
  bloqueado a página não consegue pedir de novo;
- **escreva sempre o callback de falha.** Negado (código 1), indisponível (código 2) e tempo esgotado
  (código 3) são todos resultados normais, e a página precisa de um caminho para cada um, como um campo
  para digitar uma cidade;
- a API só funciona em **origens seguras**, `https://` ou `localhost`, e `127.0.0.1` conta como uma.
  Num site `http://` comum o pedido é recusado de cara;
- a posição é um dado pessoal. Use-a para o que você pediu, e diga isso.
