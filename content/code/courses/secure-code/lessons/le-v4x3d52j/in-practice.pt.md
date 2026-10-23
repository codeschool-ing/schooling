---
title: CSRF em projetos de verdade
version: 1
---

Esta aula escreveu a verificação do token à mão para cada linha poder ser lida. Num projeto Flask de
verdade, use a extensão que faz isso: o **`CSRFProtect` do Flask-WTF** acrescenta um token a toda
sessão, o confere em toda requisição insegura e oferece `csrf_token()` aos templates, que é o que o
código desta aula imitou. O Django vem com proteção CSRF ligada por padrão, e a maioria dos outros
frameworks tem algo equivalente. O que segue trata dos casos que os padrões deixam com você.

### As isenções são o ponto fraco

Todo framework deixa uma rota se excluir, em geral para um webhook que um provedor de pagamento chama
e que não tem como conhecer o token. **Uma rota isenta é uma rota sem proteção CSRF**, então ela
precisa se proteger de outro jeito: o webhook prova quem o mandou por uma assinatura que o provedor
calcula com um segredo compartilhado, e só muda o que o provedor tem direito de mudar. Revise toda
isenção como você revisou toda rota na aula 12.

### APIs JSON

Uma API que só aceita `application/json` e é chamada pelo JavaScript do próprio portal é mais difícil
de forjar, porque um formulário HTML comum não consegue mandar esse tipo de conteúdo. Mais difícil não
é imune:

- Um endpoint que **também** aceita corpo de formulário, o que muitos frameworks fazem por padrão,
  fica tão exposto quanto qualquer formulário.
- O **CORS** decide quais outras origens podem ler respostas e mandar requisições não simples. Uma
  configuração que devolve qualquer `Origin` com credenciais permitidas dá a todo site da internet o
  mesmo alcance das páginas do próprio portal. Permita as origens que você nomeia, e nenhuma outra.

As mesmas três defesas valem: um token num cabeçalho que o JavaScript do portal define, o `SameSite` e
a verificação de origem.

### Alvos menos óbvios

- **O login.** Um login forjado põe a paciente numa conta que o outro site controla, e tudo o que ela
  digitar depois, o histórico de saúde incluído, vai para essa conta. O formulário de login também
  precisa de token, vindo da sessão anônima que a aula 10 deu a todo visitante.
- **O logout.** Mais um incômodo que outra coisa, e é por isso que o logout é um `POST` com token,
  nunca um link.
- **Qualquer coisa com `GET`.** Uma rota que muda dados num `GET` fica fora de todas as defesas desta
  aula, porque o `SameSite=Lax` deixa passar navegações `GET` de nível superior e o token só é
  conferido nos métodos inseguros. A regra da primeira seção não é estilo: **`GET` lê, o resto
  escreve.**

### O que não é defesa

- **Um cookie secreto.** O navegador manda todo cookie, os secretos incluídos.
- **Conferir só o `Referer`.** Ele costuma ser removido por configurações de privacidade e proxies, e
  uma política que aceita um `Referer` ausente aceita a requisição forjada também.
- **Formulários em várias etapas.** Uma sequência de requisições forjadas continua forjada.
- **HTTPS.** Protege a requisição no trajeto e não diz nada sobre qual página a mandou.
