---
title: "Cloudflare Workers: funções na borda"
version: 1
---

O Lambda roda a sua função numa região que você escolhe, como `sa-east-1`, e um usuário em Lisboa
chega até ela atravessando um oceano. **O Cloudflare Workers roda a função na rede de pontos de
presença de borda da própria Cloudflare, os mesmos lugares que servem conteúdo em cache para a CDN
dela, então o código roda perto de quem mandou a requisição.** Por padrão não há região para
escolher: um Worker publicado responde a partir do ponto que recebeu a requisição. A aula 9 mede
quanto a distância custa em latência; esta é uma plataforma feita para gastar menos dela.

## Isolates, não máquinas virtuais

A diferença maior é como uma cópia da função é criada. **O Lambda dá a cada ambiente de execução uma
pequena máquina virtual só dele. O Workers roda muitos scripts dentro de um processo, cada um num
isolate do V8.** O V8 é o motor de JavaScript do Chrome, e um isolate é a unidade de separação dele:
um pedaço de código com a sua própria memória e nenhum jeito de alcançar a de outro. Criar um isolate
é muito mais barato que subir até uma máquina virtual pequena, então um Worker começa quase na hora, e
o cold start praticamente deixa de ser assunto.

A mesma saudação como Worker fica assim. Ela não foi rodada aqui, porque rodá-la exige uma conta na
Cloudflare:

```javascript
export default {
  async fetch(request) {
    const url = new URL(request.url);
    const name = url.searchParams.get("name") ?? "world";
    return Response.json({ message: `hello, ${name}` });
  },
};
```

O formato é o da plataforma web, não o de um fornecedor: um `Request` entra e um `Response` sai, os
mesmos objetos que o `fetch` de um navegador usa, enquanto o Lambda entrega um dict de evento e espera
de volta um dict com código de status.

## O que o desenho custa

A troca vem junto com o isolate, e é de verdade:

- O runtime é o do JavaScript. Código escrito em JavaScript ou TypeScript roda como está, e as outras
  linguagens chegam compiladas para WebAssembly. Não é Node.js: um Worker tem as APIs da plataforma
  web e um subconjunto das do Node, então uma biblioteca que espera o Node inteiro pode não rodar.
- O limite que importa é o de tempo de CPU. Um Worker esperando outro serviço não está usando o
  processador; um que está fazendo contas está, e chega ao limite bem mais cedo. Os limites mudam
  conforme o plano e estão nas páginas da Cloudflare, e este curso não os cita.
- Não há disco seu. O armazenamento é um produto separado que o Worker chama: um armazenamento
  chave-valor (KV), armazenamento de objetos (R2), um banco SQL (D1) e os Durable Objects para estado
  que precisa de um único lugar onde ser coordenado.

**A cobrança segue a mesma escolha.** O plano pago da Cloudflare conta requisições e tempo de CPU, não
o tempo que o Worker passa esperando, o oposto dos GB-segundos do Lambda, em que esperar um banco de
dados é cobrado como trabalhar.

## Onde ele se encaixa

**Um Worker é melhor em trabalho pequeno e rápido que deve acontecer perto do usuário**:
redirecionamentos, reescrever cabeçalhos, conferir um token antes de a requisição chegar à origem,
escolher entre duas versões de uma página, uma API pequena sobre o armazenamento da própria
Cloudflare.

Ele se encaixa mal em computação longa, em bibliotecas que precisam de um Node.js completo ou de
código nativo e, de um jeito menos óbvio, em qualquer coisa que consulte um único banco de dados numa
única região a cada requisição. Um Worker em Lisboa que faz três perguntas a um banco na Virgínia por
requisição levou o código até o usuário e deixou os dados do outro lado do oceano; a borda não
economizou nada.
