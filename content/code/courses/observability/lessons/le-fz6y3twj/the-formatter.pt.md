---
title: O formatador da loja, linha a linha
version: 1
---

Todo serviço da loja registra logs pelas mesmas quarenta e poucas linhas, um formatador para o módulo `logging`
padrão do Python. O logging do Python, como as bibliotecas de log da maioria das linguagens, separa
**o que é registrado**, a chamada `log.info(...)` no código, de **como é escrito**, um formatador
preso a um handler na partida. É a mesma divisão que a aula 2 achou no OpenTelemetry, e quer dizer
que os serviços da loja chamam a biblioteca padrão e nunca mencionam JSON:

```schooling-example
{
  "language": "python",
  "file": "common/logs.py",
  "parts": [
    {
      "code": "\"\"\"One JSON object per line on stdout: how every service of the shop logs.\n\nThe platform collects stdout; nothing here knows where the lines end up.\n\"\"\"\nimport json\nimport logging\nimport os\nimport sys\nfrom datetime import datetime, timezone\n\nfrom opentelemetry import trace\n\nSERVICE = os.environ.get(\"OTEL_SERVICE_NAME\", \"unknown\")\n\n\n",
      "note": "**Saída padrão e mais nada.** O serviço não sabe de arquivos, rotação, Loki ou Collector; a plataforma recolhe o que ele imprime. O nome do serviço vem da mesma variável que os rastros usam."
    },
    {
      "code": "class JsonFormatter(logging.Formatter):\n    def format(self, record):\n        line = {\n            \"time\": datetime.fromtimestamp(record.created, timezone.utc)\n            .isoformat(timespec=\"milliseconds\")\n            .replace(\"+00:00\", \"Z\"),\n            \"level\": record.levelname,\n            \"service\": SERVICE,\n            \"logger\": record.name,\n            \"message\": record.getMessage(),\n        }\n",
      "note": "Os campos que toda linha tem: uma hora em UTC com milissegundos, o nível, o serviço, o logger, e uma mensagem que é **o mesmo texto para o mesmo tipo de evento**, para poder ser contada."
    },
    {
      "code": "        ctx = trace.get_current_span().get_span_context()\n        if ctx.is_valid:\n            line[\"trace_id\"] = format(ctx.trace_id, \"032x\")\n            line[\"span_id\"] = format(ctx.span_id, \"016x\")\n",
      "note": "**Correlação**: se há um span corrente, os ids dele vão para a linha. Esta é a junção entre logs e rastros da aula 1."
    },
    {
      "code": "        line.update(getattr(record, \"fields\", {}))\n        if record.exc_info:\n            line[\"exception\"] = self.formatException(record.exc_info)\n        return json.dumps(line)\n\n\n",
      "note": "Os valores do próprio evento, passados como `extra={\"fields\": {...}}`, viram campos próprios; o traceback de uma exceção vira um campo, dentro da mesma linha."
    },
    {
      "code": "def setup(level=None):\n    handler = logging.StreamHandler(sys.stdout)\n    handler.setFormatter(JsonFormatter())\n    root = logging.getLogger()\n    root.handlers[:] = [handler]\n    root.setLevel(level or os.environ.get(\"LOG_LEVEL\", \"INFO\"))\n    logging.getLogger(\"waitress\").setLevel(logging.WARNING)\n    logging.getLogger(\"pika\").setLevel(logging.CRITICAL)\n    return logging.getLogger(SERVICE)",
      "note": "O nível vem do ambiente, `INFO` a menos que o `LOG_LEVEL` diga outra coisa. Duas bibliotecas falantes são abaixadas aqui, uma vez, em vez de filtradas depois com custo."
    }
  ]
}
```

Uma chamada na vitrine, então, fica assim:

```python
        log.info("checkout finished", extra={"fields": {
            "sku": sku, "order_id": order.get("id"), "outcome": order.get("status")}})
```

A mensagem é uma frase fixa e os valores são campos. **A mensagem nunca interpola um valor**:
`"checkout finished"` é a mesma string para todo checkout, e é isso que permite à aula 9 contá-los
pela mensagem. O número do pedido está em `order_id`, onde pode ser buscado sem analisar uma frase.

Escrever na saída padrão é uma decisão com nome, dos princípios do *twelve-factor app*: um serviço
trata seus logs como um fluxo e deixa o recolhimento a cargo de quem o executa. Neste laboratório o
Docker entrega cada linha ao Collector; no Kubernetes o agente do nó lê a saída do contêiner; num
notebook é o terminal. **O código do serviço é o mesmo nos três**, e ele nunca enche um disco com um
arquivo que ninguém rotaciona.
