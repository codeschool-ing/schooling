---
title: Validação nativa, e onde ela para
---

O navegador valida sozinho com atributos, sem uma linha de JavaScript:

```html
<input type="email" required />
<input type="text" minlength="3" maxlength="40" />
<input type="text" pattern="[0-9]{5}-[0-9]{3}" />
```

E dá para estilizar o estado com `:valid`, `:invalid` e — o mais útil — `:user-invalid`, que só pinta de vermelho **depois** de a pessoa ter interagido com o campo. Sem ele, um formulário nasce todo vermelho antes de alguém digitar nada.

**Validação no navegador é conveniência, nunca segurança.** Qualquer pessoa remove um `required` pelo inspetor em dois segundos. O servidor valida tudo de novo, sempre — a do cliente existe para evitar a viagem até o servidor, não para proteger dele.
