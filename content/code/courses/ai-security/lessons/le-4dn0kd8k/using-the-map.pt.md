---
title: Usar o mapa para decidir o que vem a seguir
version: 2
---

Um inventário se paga mostrando o que falta. O `--gaps` imprime só as entradas sem controle:

```
ana@lab:~/guard$ guard surface --gaps
entry point     goes to  trusted?           controls
uploaded-files  prompt   no                 NONE
10 entry points, 1 with no control
```

Uma entrada. Clientes podem anexar briefings e arquivos a um trabalho, e o assistente os lê para
responder perguntas sobre o trabalho. Esse texto não é confiável, chega ao prompt, e nada neste
laboratório o confere. **Uma lacuna no mapa é uma decisão esperando para ser tomada**, e só há três saídas
honestas:

- **acrescentar um controle**, e escrever o nome dele na linha;
- **estreitar o recurso** até os controles existentes o cobrirem, como ler só o título e o tamanho do
  anexo e nunca o conteúdo;
- **aceitar o risco por escrito**, com quem aceitou, por quê, e a data de olhar de novo.

O que não é saída é deixar a linha vazia e torcer. Texto que chega ao modelo dentro de arquivos e páginas pertence exatamente a esta linha.

## Ordenando o trabalho

Nem toda lacuna é igualmente urgente, e o inventário tem o necessário para ordená-las. Duas perguntas:

1. **O que o texto alcança?** Texto que chega às ferramentas vem antes de texto que só chega a uma
   resposta, que vem antes de texto que só chega a um log.
2. **Quem pode escrevê-lo?** Texto que qualquer visitante anônimo escreve vem antes de texto que só um
   cliente verificado escreve, que vem antes de texto que só a equipe escreve.

Os arquivos anexados pontuam alto nas duas: qualquer um que abre uma conta pode anexar um, e o assistente
que o lê pode propor chamadas de ferramenta. Mesmo com o portão da aula 10 na frente das ferramentas,
essa combinação põe a linha no topo da lista.

## O mapa envelhece

O inventário é verdadeiro no dia em que foi escrito. Uma ferramenta nova, uma fonte de dados nova ou um
fornecedor novo o muda, e um mapa que não é atualizado vira o mapa de uma aplicação que não existe mais.
A Tarefa mantém o `data/surface.json` no mesmo repositório que o código, mudado no mesmo pull request do
recurso que muda a superfície, para que quem revisa o código leia a linha também.
