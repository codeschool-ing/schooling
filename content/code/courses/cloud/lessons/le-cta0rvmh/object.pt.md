---
title: "Armazenamento de objetos: buckets, chaves e objetos inteiros"
version: 1
---

A imagem errada aqui é a de um drive de rede muito grande. Um repositório de objetos não tem drive,
não tem sistema de arquivos e, diga o console o que disser, não tem pastas. Ele tem três
substantivos.

Um **bucket** é um contêiner com nome, numa região, com configurações próprias: quem pode ler,
se versões antigas são guardadas, quais regras de ciclo de vida se aplicam. Os nomes de bucket do S3
são compartilhados por todas as contas da AWS, então um bucket novo precisa de um nome que nenhuma
outra conta tenha, e uma palavra simples como `photos` não vai estar livre.

Um **objeto** é uma sequência de bytes mais metadados: um tipo de conteúdo, um tamanho, um checksum
chamado ETag, datas, e os pares nome–valor que você anexar. Um objeto do S3 pode ter até 5 TB.

Uma **chave** é o nome do objeto dentro do bucket, qualquer string de até 1.024 bytes.
`photos/2026/cat.jpg` é uma chave só. As barras dela são caracteres como as letras, e o espaço de
nomes é plano: não existe um diretório `photos` com um diretório `2026` dentro.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Um bucket chamado ana-uploads com cinco objetos, cada um com uma chave inteira: photos/2025/sea.jpg, photos/2026/cat.jpg, photos/2026/dog.jpg, reports/2026-q3.txt e index.html. Uma listagem que pede ao bucket para cortar as chaves na primeira barra devolve dois prefixos, photos/ representando três chaves e reports/ uma, e um objeto, index.html. Nenhum objeto se chama photos/; o prefixo só existe porque há chaves que começam com ele.\"><defs><marker id=\"bkt-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"320\" height=\"210\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"34\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">bucket</text><text x=\"82.8\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">ana-uploads</text><rect x=\"34\" y=\"66\" width=\"292\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">photos/</text><text x=\"92.19999999999999\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2025/sea.jpg</text><rect x=\"34\" y=\"100\" width=\"292\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"113\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">photos/</text><text x=\"92.19999999999999\" y=\"113\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2026/cat.jpg</text><rect x=\"34\" y=\"134\" width=\"292\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"147\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">photos/</text><text x=\"92.19999999999999\" y=\"147\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2026/dog.jpg</text><rect x=\"34\" y=\"168\" width=\"292\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"181\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">reports/</text><text x=\"98.8\" y=\"181\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2026-q3.txt</text><rect x=\"34\" y=\"202\" width=\"292\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"215\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">index.html</text><path d=\"M342 135 L418 135\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#bkt-ah)\"></path><text x=\"380\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">delimiter=/</text><rect x=\"420\" y=\"30\" width=\"280\" height=\"210\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"434\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">uma listagem, cortada em /</text><rect x=\"434\" y=\"66\" width=\"252\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"446\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">photos/</text><text x=\"674\" y=\"79\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">prefixo, 3 chaves</text><rect x=\"434\" y=\"100\" width=\"252\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"446\" y=\"113\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">reports/</text><text x=\"674\" y=\"113\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">prefixo, 1 chave</text><rect x=\"434\" y=\"134\" width=\"252\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"446\" y=\"147\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">index.html</text><text x=\"674\" y=\"147\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">objeto</text><text x=\"434\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Nenhum objeto se chama photos/.</text><text x=\"434\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">O prefixo existe porque há chaves com ele.</text><text x=\"20\" y=\"258\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Cinco chaves, sem hierarquia. A barra é um caractere como outro qualquer.</text></svg>", "caption": "O que parece pasta é um prefixo pelo qual a listagem agrupa as chaves. Apague as três fotos e photos/ some junto, porque nunca houve nada ali.", "same": ["bucket"]}
```

O que parece pasta é um **prefixo**. Uma listagem pode pedir as chaves que começam com `photos/`, e
pode pedir ao repositório que corte cada chave na próxima `/` e informe cada começo distinto uma vez
só, que é como um console desenha uma árvore. Alguns consoles têm um botão de "criar pasta", e o que
ele cria é um objeto vazio cuja chave termina em `/`, para a árvore ter o que mostrar antes de
qualquer upload.

## Gravado inteiro, lido inteiro

**Um objeto é gravado inteiro e substituído inteiro.** Não existe acrescentar ao fim, gravar no meio
nem truncar. Para acrescentar uma linha a um log guardado como objeto, o programa baixa o objeto, acrescenta a
linha e envia tudo de novo sob a mesma chave. Objetos grandes são enviados em partes que o
repositório junta no fim, e isso continua sendo uma gravação de um objeto. Ler é mais flexível: um
`GET` pode pedir um intervalo de bytes, então ler parte de um objeto é barato, enquanto gravar parte
de um não é possível.

Também não existe renomear. A chave é o nome, e o nome não fica guardado em nenhum outro lugar,
então renomear `reports/q3.txt` é copiar o objeto para uma chave nova e apagar a antiga. Para um
milhão de objetos são dois milhões de requisições, e renomear uma "pasta" é renomear cada chave sob
o prefixo. A próxima seção mostra isso acontecendo.

## A interface é HTTP, e pequena

| requisição | o que faz |
|---|---|
| `PUT /bucket/key` | guarda um objeto sob aquela chave, substituindo o que já estiver lá |
| `GET /bucket/key` | devolve o objeto, ou um intervalo de bytes dele |
| `HEAD /bucket/key` | devolve os metadados sem os bytes |
| `DELETE /bucket/key` | remove o objeto |
| `GET /bucket?list-type=2&prefix=…` | lista chaves, opcionalmente cortadas num delimitador |

Toda requisição é assinada com as credenciais de quem chama, e a aula 7 diz de quem. Toda requisição
também é uma linha na conta: a tabela cobra `PUT, COPY, POST, LIST` a 0,00700 por 1.000 em
`sa-east-1` e `GET` a 0,00056 por 1.000.

**O S3 tem consistência forte de leitura após gravação desde dezembro de 2020.** Depois que um `PUT`
devolveu sucesso, todo `GET` e todo `LIST` seguinte vê o objeto novo, e uma sobrescrita aparece na
hora. Antes dessa data uma sobrescrita ou uma remoção podia demorar a aparecer, e artigos e
bibliotecas mais antigos ainda carregam contornos para isso. O que a consistência não dá é uma trava:
dois programas gravando a mesma chave no mesmo instante têm sucesso os dois, e fica a gravação que chegou
por último.

**O S3 Standard é projetado para 99,999999999% de durabilidade**, onze noves, guardando cada objeto
em dispositivos de pelo menos três zonas de disponibilidade da região. Esse é o número de projeto da
AWS, não uma promessa em contrato, e três seções adiante a aula separa o que ele cobre do que não
cobre.
