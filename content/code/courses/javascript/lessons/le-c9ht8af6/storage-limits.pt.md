---
title: Quanto cabe, e o que nunca entra
version: 1
---

O armazenamento web é pequeno e simples de propósito. **Ele guarda alguns megabytes por origem, e
toda chamada é síncrona**, então a página espera enquanto o navegador lê ou escreve:

```html
<!doctype html>
<script>
  const chunk = "x".repeat(1024 * 1024);
  let stored = 0;
  try {
    for (let i = 0; i < 20; i++) {
      localStorage.setItem(`chunk${i}`, chunk);
      stored = i + 1;
    }
  } catch (err) {
    console.log(err.name, "after", stored, "items of", chunk.length, "characters");
  }
  for (let i = 0; i < stored; i++) localStorage.removeItem(`chunk${i}`);
</script>
```

```
ana@dev:~/js$ page full.html --fresh
QuotaExceededError after 4 items of 1048576 characters
```

O Chromium recusou o quinto item de um milhão de caracteres com um **`QuotaExceededError`**. O limite
difere entre navegadores e é contado de jeitos diferentes, então **uma página que guarda algo grande
precisa esperar que o `setItem` lance erro**, e pegá-lo onde possa fazer algo sensato, como descartar
uma entrada antiga de cache. O teste arruma depois de si, removendo o que guardou.

## Quando é a ferramenta errada

- **muitos dados**, ou arquivos: o navegador tem um banco de dados para isso, o IndexedDB, com
  interface assíncrona e muito mais espaço. Este curso não o cobre; os capítulos de offline dos
  frameworks cobrem;
- **qualquer coisa secreta**. Qualquer script rodando na página consegue ler o `localStorage`,
  inclusive um script que nunca deveria ter rodado ali. Um token de sessão guardado nele fica exposto a
  todo script desses, e é por isso que a aula 6 de `front-quality`, "Storing tokens safely in the
  browser", trata de onde os tokens devem ficar no lugar. Senhas nunca pertencem ao armazenamento do
  navegador;
- **qualquer coisa que precise ser verdade**. O usuário pode abrir as ferramentas de desenvolvedor do
  navegador e editar qualquer valor, então um preço, uma permissão ou uma pontuação lidos do
  `localStorage` são o que o usuário quiser. O servidor decide essas coisas, toda vez.
