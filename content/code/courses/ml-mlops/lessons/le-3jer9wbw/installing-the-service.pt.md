---
title: Instalando o que um serviço precisa
version: 1
---

O resto da lição precisa de mais quatro bibliotecas: **FastAPI** para descrever um serviço web em
Python, **Uvicorn** para rodá-lo, **skl2onnx** para exportar um modelo num formato portátil e
**ONNX Runtime** para rodar esse formato sem o scikit-learn. Com o ambiente ativo:

```sh
pip install fastapi==0.143.0 uvicorn==0.54.0 skl2onnx==1.20.0 onnxruntime==1.31.0
```

```
ana@dev:~/ml$ pip list 2>/dev/null | grep -iE '^(fastapi|uvicorn|skl2onnx|onnxruntime|onnx) '
fastapi                            0.143.0
onnx                               1.23.2
onnxruntime                        1.31.0
skl2onnx                           1.20.0
uvicorn                            0.54.0
```

São as últimas bibliotecas que o curso instala. `pip list` filtrado para as quatro, com o `onnx` junto
porque o skl2onnx o traz, é a conferência de que estão no ambiente e nas versões fixadas.
