---
title: Lendo um aviso, e perguntando se o linkbox o alcança
version: 1
---

Uma linha de auditoria diz que uma versão é afetada. **Se o seu serviço é afetado é uma segunda
pergunta, e o texto do aviso é onde ela começa.** A maioria dos avisos diz o que precisa ser verdade
para a falha importar: um recurso em uso, uma plataforma, uma configuração, um atacante numa posição
específica. Ler essas condições contra o que o seu serviço faz é a triagem mais barata que existe, e
nada na tabela da auditoria faz isso por você.

### O aviso do Flask, inteiro

O `--desc` vem ligado por padrão no JSON do pip-audit, então a descrição já está em
`/tmp/audit.json`:

```
ana@vm:~/linkbox$ jq -r ".dependencies[] | select(.name == \"flask\") | .vulns[0].description" /tmp/audit.json
When the `session` object is accessed, Flask should set the `Vary: Cookie` header. This instructs caches not to cache the response, as it may contain information specific to a logged in user. This is handled in most cases, but some forms of access such as the Python `in` operator were overlooked.  The severity depends on the application's use of the session, and the cache's behavior regarding cookies. The risk depends on all these conditions being met.  1. The application must be hosted behind a caching proxy that does not ignore responses with cookies. 2. The application does not set a `Cache-Control` header to indicate that a page is private or should not be cached. 3. The application accesses the session in a way that does not access the values, only the keys, and does not mutate the session.
```

A falha: o Flask deveria acrescentar `Vary: Cookie` a uma resposta sempre que o código toca na
sessão, para que um cache na frente do serviço não guarde a página de um usuário e a entregue a
outro. Em alguns casos, como testar se uma chave está na sessão, ele esquecia. O aviso diz então
quando isso importa, como uma lista de condições que precisam valer **todas**:

1. Um proxy de cache na frente do serviço que guarda respostas com cookies.
2. Nenhum cabeçalho `Cache-Control` marcando a página como privada.
3. O código lê as chaves da sessão sem ler valores nem alterá-la.

O linkbox falha na terceira condição antes de as outras entrarem em jogo: **o `app.py` nunca toca na
sessão.** Ele não importa `session` e não guarda nada em cookie. Também não há cache na frente dele,
nem no staging nem em lugar nenhum onde este curso o implanta. Para o linkbox como está, este aviso
descreve código que ele nunca executa.

Isso é **alcançabilidade** (reachability): se o seu serviço, como foi escrito e implantado, consegue
executar o código vulnerável nas condições de que a falha precisa. Um achado não alcançável continua
verdadeiro. É uma afirmação sobre o linkbox de hoje, e deixa de valer no dia em que alguém
acrescentar um login que use a sessão.

### Os outros catorze

A mesma leitura, feita para cada falha da auditoria. As descrições estão no mesmo arquivo JSON, e as
condições abaixo são as dos próprios avisos.

| pacote | falhas | do que o aviso precisa | linkbox |
|---|---|---|---|
| flask | CVE-2026-27205 | um proxy de cache, e chaves de sessão lidas sem os valores | nunca toca na sessão: **não alcançável** |
| werkzeug | CVE-2024-34069 | o debugger interativo rodando, e um desenvolvedor atraído para um site preparado | a execução em debug saiu na aula 3, e o gunicorn não tem debugger: **não alcançável** |
| werkzeug | cinco falhas de `safe_join`, CVE-2024-49766 e mais quatro | o serviço rodando em Windows e servindo arquivos via `safe_join` | roda em Linux e não serve arquivos: **não alcançável** |
| werkzeug | CVE-2024-49767 | o serviço fazendo parsing de corpos `multipart/form-data` | `POST /links` lê um formulário: **alcançável** |
| jinja2 | CVE-2024-22195, CVE-2024-34064 | entrada do usuário usada como *nome* de atributo no filtro `xmlattr` | nunca usa `xmlattr`: **não alcançável** |
| jinja2 | CVE-2024-56201, CVE-2024-56326, CVE-2025-27516 | um atacante capaz de escrever um template, com ou sem sandbox | o único template é uma constante no `app.py`: **não alcançável** |
| gunicorn | CVE-2024-1135, CVE-2024-6827 | uma requisição com cabeçalhos `Transfer-Encoding` conflitantes chegando ao gunicorn | toda requisição passa pelo gunicorn: **alcançável** |

**Três de quinze são alcançáveis hoje**, e duas dessas três são as falhas de request smuggling do
gunicorn, que importam mais quando há um proxy na frente do gunicorn e os dois leem a mesma
requisição de jeitos diferentes. Esse é o formato da maioria das auditorias: uma lista longa, uma
lista curta do que está de fato num caminho que o serviço executa, e um motivo para cada linha.

### Para que serve a alcançabilidade, e para que não serve

É tentador ler essa tabela como licença para corrigir três pacotes e deixar o resto. Seria um erro
no linkbox, por dois motivos. Cada uma das quinze tem versão corrigida, e a última seção desta aula
mostra que o movimento custa poucas linhas e uma rodada de testes. E um julgamento de
alcançabilidade é **um julgamento feito lendo**, que um commit posterior pode invalidar em silêncio:
uma página nova que use `|xmlattr`, um login que use a sessão, um download servido com
`send_from_directory`. Nada avisa quando isso acontece.

Então a alcançabilidade se paga em dois lugares:

- **Ordenar o trabalho** quando há mais trabalho que tempo: o alcançável primeiro.
- **Decidir sobre um achado sem correção.** Quando atualizar não é possível, "conseguimos alcançá-lo"
  é a maior parte do argumento para aceitá-lo por um tempo, e a aula 7 transforma esse argumento numa
  exceção com dono e data.

Escreva o raciocínio de qualquer jeito. Um achado marcado "não alcançável" sem uma frase ao lado é
indistinguível, um mês depois, de um que ninguém leu.
