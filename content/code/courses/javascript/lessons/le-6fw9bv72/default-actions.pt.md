---
title: A reação do próprio navegador
version: 1
---

Alguns eventos vêm com algo que o navegador faz sozinho: **um clique num link navega, um envio manda
o formulário e carrega uma página nova, uma tecla num campo digita uma letra**. Essa reação embutida é
a **ação padrão** do evento, e um listener pode cancelá-la com `event.preventDefault()`:

```html
<!doctype html>
<a id="more" href="details.html">Details</a>
<script>
  document.querySelector("#more").addEventListener("click", (event) => {
    event.preventDefault();
    console.log("stayed on", location.pathname, "cancelled:", event.defaultPrevented);
  });
</script>
```

```
ana@dev:~/js$ page default.html --do 'click #more'
-- click #more
stayed on /default.html cancelled: true
```

O link apontava para `details.html`, e a página **ficou em `/default.html`**: a navegação nunca
aconteceu. `event.defaultPrevented` informa que ela foi cancelada, que é como um listener mais acima
sabe que alguém abaixo já tratou o evento.

## Quando cancelar

- **um formulário que o seu script vai enviar sozinho.** Todo formulário da próxima seção chama
  `preventDefault()` no envio, porque senão o navegador mandaria os campos e trocaria a página antes de
  o script poder fazer qualquer coisa com eles. A aula 16 manda os dados com `fetch` no lugar;
- um link que um script transforma em outra coisa, como abrir um painel, mantendo um `href` de verdade
  para o link ainda funcionar para alguém cujo script não carregou.

**Cancele a ação padrão só quando o seu código a substituir.** Um link que não faz nada quando clicado
e não tem alternativa, ou uma tecla que não digita nada, quebra coisas de que os usuários dependem,
incluindo os recursos de acessibilidade do próprio navegador. O `preventDefault` não interrompe a
viagem do evento; isso é o `stopPropagation`, e os dois são independentes.
