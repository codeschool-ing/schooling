---
title: Subdomínios: quando separar
---

Subdomínio é de graça e ilimitado, então a pergunta nunca é "posso?", é "devo?". `app.exemplo.com` e `exemplo.com/app` resolvem a mesma necessidade de formas diferentes.

Subdomínio separa de verdade: cada um pode apontar para um servidor diferente, ter certificado próprio e, para muitos efeitos de segurança, é tratado como outro site — cookie de um não é enviado ao outro por padrão. É o que se quer para o painel administrativo, para a API e para o ambiente de teste.

Caminho na mesma origem compartilha tudo — sessão, cookie, certificado — e evita a configuração extra. É o que se quer quando as partes são o mesmo produto e conversam o tempo todo.
