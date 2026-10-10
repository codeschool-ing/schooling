---
title: Onde o navegador deve guardá-lo
version: 1
---

Um id de sessão e um JWT são os dois **credenciais portadoras**: quem apresenta uma é tratado como
dono, sem mais perguntas. Nenhum dos dois está preso a um aparelho ou à pessoa que fez o login. Então
a pergunta real sobre onde guardar um deles não é onde é cômodo, mas **quem mais consegue lê-lo ali**.

O conselho de costume para aplicações de página única era pôr o token no `localStorage`, com o
raciocínio de que outros sites não o leem. Essa metade é verdade: o armazenamento pertence a uma
origem. O que fica de fora é que todo script rodando dentro da sua página o lê. Isso inclui um script que
um atacante conseguiu injetar, o ataque chamado cross-site scripting ou XSS, e qualquer biblioteca
de terceiros carregada pela página que alguém tenha adulterado. A aula 13 trata de manter
esses scripts fora. Esta seção trata de quanto eles levam quando entram.

| onde | scripts da página leem | o navegador envia sozinho | o que um script injetado consegue |
|---|---|---|---|
| cookie com `HttpOnly` | não | sim, então precisa das defesas contra CSRF | agir como o usuário enquanto a página está aberta; não consegue copiar a credencial |
| `localStorage` | sim | não | ler o token e mandá-lo para qualquer lugar, para ser usado depois de outra máquina |
| uma variável na memória da página | sim, com esforço | não | o mesmo, mas o token some quando a aba fecha |

**O `HttpOnly` é o único lugar que os próprios scripts da página não alcançam.** O pote da seção
sobre sessões registrou a marca como `#HttpOnly_localhost`; um navegador a impõe, e o
`document.cookie` simplesmente não lista um cookie assim. Um script injetado ainda consegue mandar
requisições enquanto o usuário está com a página aberta, e o cookie vai junto. Isso é ruim. Mas tem
limite: acaba quando a aba fecha, e a credencial nunca sai do navegador, enquanto o `localStorage` a
entrega para ser usada de qualquer lugar até vencer.

Três hábitos decorrem disso:

- **Para uma aplicação de navegador falando com a própria API, guarde a credencial num cookie
  `HttpOnly`, `Secure` e `SameSite`**, e defenda o cookie contra CSRF como o `sessions.py` faz. Isso
  vale tanto se o cookie levar um id de sessão quanto um JWT.
- **Nunca ponha um token numa URL.** Endereços vão parar em logs de servidor, no histórico do
  navegador e no cabeçalho `Referer` da requisição seguinte, lugares que ninguém trata como secretos.
- **Um app móvel nativo não é um navegador.** Não tem cookies a roubar por uma página nem XSS no mesmo
  sentido, e guarda tokens no armazenamento protegido do sistema, o Keychain do iOS ou o Keystore do
  Android, e não num arquivo.
