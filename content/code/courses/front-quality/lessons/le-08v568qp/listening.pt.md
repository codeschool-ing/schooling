---
title: Ouvindo o planner
version: 1
---

**Esta seção não tem transcrição.** Um leitor de tela fala, e o que ele diz depende de qual leitor, de qual
versão, de qual navegador e de quais ajustes, então uma gravação seria verdade numa máquina e seria lida
como verdade em todas. O que segue é o procedimento, e o que escutar no planner; faça-o com o leitor que o
seu sistema tem.

## Para começar

- **macOS**: Cmd+F5 liga o VoiceOver. VO quer dizer Ctrl+Option apertados juntos; VO+Seta para a direita lê o
  próximo item, VO+U abre o rotor com as listas de títulos, links e landmarks, e Cmd+F5 de novo o desliga.
- **Windows**: instale o NVDA de nvaccess.org e ligue-o com Ctrl+Alt+N. Seta para baixo lê o próximo item,
  H salta para o próximo título, D para o próximo landmark, Insert+F7 lista os links e os títulos, e
  Insert+Q sai.
- **Linux, GNOME**: Super+Alt+S liga e desliga o Orca. O modo de navegação dele usa as mesmas letras do NVDA,
  H para título entre elas.

Ligue-o, abra o planner, e baixe o volume antes da primeira palavra.

## O que escutar

1. **Na lista de cursos**: o título é anunciado como *título nível 1*, a lista diz quantos itens tem, e cada
   link é lido só pelo nome do curso, sem nome de arquivo antes. No Safari a lista pode não ser anunciada
   como lista: o WebKit tira o papel de lista de uma lista com `list-style: none`, como a do planner, de
   propósito, e `role="list"` no `ul` o devolve onde a contagem importa.
2. **Salte por landmark**: há um, *main*, e ele guarda tudo.
3. **Abra um curso e escute as primeiras palavras**: o nome do título, porque a aula 11 moveu o foco para lá.
4. **Tab até o link de voltar**: *All courses, link*, e nenhuma seta.
5. **Aperte Done**: a linha é lida com *done* no fim.
6. **Acrescente uma sessão**: *Session added*, com a data e os minutos, lido uma vez, e o foco no campo de
   data.

Qualquer coisa que soe errada é um achado, mesmo quando nenhum teste falhou. Anote como o leitor disse, com
o nome e a versão do leitor: *"NVDA 2025.3, Firefox: o campo de data é lido como 'edit, blank'"* é um
relato que alguém consegue resolver, e *"o campo de data soa estranho"* não é.
