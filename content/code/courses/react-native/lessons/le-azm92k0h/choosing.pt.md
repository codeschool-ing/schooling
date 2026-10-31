---
title: Quatro lugares, para quatro tipos de coisa
version: 1
---

**Tudo o que está na memória some quando o app é fechado**, e num celular o sistema fecha apps sem
perguntar, para liberar memória para o que está na frente. O que o planner ainda deve saber da próxima vez
precisa ser escrito em algum lugar. O React Native não tem uma resposta única, porque as coisas que vale
guardar não são de um tipo só:

| lugar | guarda | leitura | para |
|---|---|---|---|
| AsyncStorage | strings sob chaves | assíncrona | um cache, uma configuração, um rascunho: coisas pequenas lidas uma vez |
| MMKV | strings, números, booleanos sob chaves | síncrona, em microssegundos | um valor necessário antes do primeiro quadro |
| SQLite | tabelas e linhas | com consultas SQL | registros que você conta, filtra, ordena e junta |
| SecureStore | strings curtas sob chaves | assíncrona | segredos: um token, uma chave |

O sistema de arquivos da aula 13 é o quinto lugar, para arquivos.

**A pergunta que escolhe o lugar é o que você vai pedir aos dados.** "Me devolva o que eu guardei" é um
armazenamento chave-valor. "Qual curso eu estudei mais este mês" é uma consulta, e um chave-valor faria você
carregar tudo e somar sozinho. "Isto está seguro se o celular for roubado" é o SecureStore, e mais nada.

Duas coisas valem para todos. **Eles pertencem ao app**: nenhum outro app os lê, e desinstalar os apaga,
então nenhum deles é backup. **E pertencem ao celular**: nada aqui chega aos outros aparelhos da pessoa,
que é trabalho do servidor. Esta aula usa cada um dos quatro para aquilo a que serve, e diz onde fica a
fronteira.
