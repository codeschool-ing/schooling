---
title: Escolhendo uma para um trabalho
version: 1
---

As três respostas que a Ana recebeu estavam certas para alguém. O jeito de escolher é começar pelo
**trabalho** e deixar que ele elimine distribuições.

| o trabalho | uma boa escolha | por quê |
|---|---|---|
| o servidor de arquivos do escritório | **Ubuntu LTS** ou **Debian stable** | anos de correções, nada muda por baixo |
| software certificado no RHEL | **RHEL**, ou **Rocky** / **AlmaLinux** | o que o fornecedor testa; o original se o suporte exigir |
| um desktop de escritório | **Ubuntu LTS** ou **Linux Mint** | suporte longo, drivers, e ajuda fácil de achar |
| o notebook de um desenvolvedor | **Fedora**, ou uma contínua | ferramentas novas cedo, uma pessoa afetada por uma quebra |
| dentro de um contêiner | **Alpine** ou **Debian slim** | pequena, e trocada em vez de atualizada |

E quatro perguntas que resolvem quase todo o resto:

1. **Por quantos anos precisa rodar?** Elimine tudo cujo suporte acaba antes.
2. **Algo nela precisa de uma plataforma certificada?** Aí a lista do fornecedor decide.
3. **Quem vai cuidar dela?** Uma equipe que conhece o `apt` trabalha mais rápido no Ubuntu do que na
   melhor distribuição que nunca usou. Num escritório em que a Ana é o departamento de TI inteiro, isso
   conta.
4. **Dá para pagar alguém para ajudar?** A Canonical vende suporte para o Ubuntu, a Red Hat para o
   RHEL e a SUSE para o SLES. Debian, Fedora e Arch têm comunidades excelentes e ninguém para quem
   ligar.

Para o armário, a resposta sai **Ubuntu 26.04 LTS**: anos de suporte, a família que o servidor já usa,
e o software da contabilidade não está nele. Se o software da contabilidade fosse para esse servidor,
a lista do fornecedor decidiria, e a resposta seria Rocky ou AlmaLinux.

## O que não decide

**Qual é a mais bonita.** A aparência do desktop é uma configuração, e servidores não têm nenhuma.
**Qual é a mais rápida.** Com o mesmo kernel, as diferenças são pequenas perto do que o hardware
decide. **Qual está popular num fórum este ano.** A popularidade ajuda a achar respostas; ela não
mantém um servidor corrigido.
