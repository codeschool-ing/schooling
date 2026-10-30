---
title: O Bicep, instalado ao lado da linha de comando
version: 1
---

**O Bicep é um compilador, e ele roda no seu computador.** Ele lê um arquivo `.bicep` e escreve o template
JSON do ARM que o Resource Manager entende; implantar esse template é outro passo, que precisa de uma
assinatura e não faz parte deste laboratório. Todo o resto que o Bicep faz, compilar, descompilar e
verificar, não precisa de nada além do próprio programa, e por isso esta lição e a próxima são praticadas
por inteiro.

A linha de comando do Azure o baixa, na versão que você indicar, em `~/.azure/bin`. As duas linhas seguintes
põem esse diretório no seu path, agora e em todo terminal novo, para o programa ser chamado como `bicep` e não
por meio de `az bicep`:

```sh
cd ~/azure && source venv/bin/activate
az bicep install --version v0.48.1
echo 'export PATH="$HOME/.azure/bin:$PATH"' >> ~/.bashrc
export PATH="$HOME/.azure/bin:$PATH"
```

```
ana@laptop:~/azure/bicep$ bicep --version
Bicep CLI version 0.48.1 (cec7951cf6)
ana@laptop:~/azure/bicep$ du -sh ~/.azure/bin/bicep
117M	/home/ana/.azure/bin/bicep
```

É um programa único de cerca de 117 MB. `az bicep build` e `bicep build` fazem a mesma coisa; este curso chama
o `bicep` direto porque os erros voltam sem o embrulho da linha de comando. Se você escreve Bicep num editor, a
extensão Bicep da Microsoft para o Visual Studio Code roda o mesmo compilador enquanto você digita, e mostra
como sublinhados os avisos que você está prestes a ver no terminal.
