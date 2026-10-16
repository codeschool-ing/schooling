---
title: Layers, and what belongs in one
version: 1
---

**A layer is a second zip that Lambda unpacks into `/opt` beside your function's `/var/task`.** It
is published once, with a version, and any number of functions can name it. That is the whole
mechanism; the judgement is in what to put there. The picture people bring is that a layer is where
dependencies go, so every function should keep its libraries in one. **A layer is a way to share
files, and a dependency only one function uses gains nothing from being shared.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Inside one execution environment, four directories. /var/task holds your package, app.py or shop.py, read-only. /opt holds the layers, unpacked in order, here python/shopfmt.py, read-only. A dashed amber line around both says 250 MB together, unzipped. /var/runtime holds the runtime, which is AWS's. /tmp is writable, 512 MB by default and up to 10,240 MB. Below, the Python import path lists /var/task before /opt/python.\"><rect x=\"16\" y=\"12\" width=\"688\" height=\"256\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"30\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">one execution environment</text><rect x=\"36\" y=\"54\" width=\"338\" height=\"150\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"205\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">250 MB together, unzipped</text><rect x=\"52\" y=\"88\" width=\"146\" height=\"100\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">/var/task</text><text x=\"125\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">your package</text><text x=\"125\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">app.py, shop.py</text><text x=\"125\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">read-only</text><rect x=\"214\" y=\"88\" width=\"146\" height=\"100\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"287\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">/opt</text><text x=\"287\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">your layers, in order</text><text x=\"287\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">python/shopfmt.py</text><text x=\"287\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">read-only</text><rect x=\"396\" y=\"88\" width=\"146\" height=\"100\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"469\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">/var/runtime</text><text x=\"469\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the runtime</text><text x=\"469\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">AWS's, not yours</text><rect x=\"558\" y=\"88\" width=\"130\" height=\"100\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"623\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">/tmp</text><text x=\"623\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">writable</text><text x=\"623\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">512 MB to 10,240 MB</text><text x=\"36\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the Python runtime imports from:</text><text x=\"36\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sys.path: /var/task, …, /opt/python, …</text></svg>", "caption": "Where the pieces land. Your package and your layers are unpacked into two read-only directories and count against one limit together; the runtime is AWS's, and /tmp is the only place a function can write."}
```

## A function that needs something it does not carry

The shop prints prices in reais in several functions, so the formatting lives in a module of its
own. The function is two lines and imports it. Save this as `~/aws/shop/shop.py`:

```python
# shop.py
from shopfmt import brl


def handler(event, context):
    return {'price': brl(event['cents'])}
```

and the module as `~/aws/layer/python/shopfmt.py`, inside a directory called `python`, which is
the point of the exercise:

```python
# python/shopfmt.py
def brl(cents):
    reais, rest = divmod(int(cents), 100)
    return 'R$ ' + f'{reais:,}'.replace(',', '.') + f',{rest:02d}'
```

Run the function in the emulator with only its own directory, the way the last section's zip would
arrive:

```
ana@laptop:~/aws$ ls -R shop layer
layer:
python

layer/python:
shopfmt.py

shop:
shop.py
ana@laptop:~/aws$ docker run --rm -d --name shop -p 9000:8080 -v "$PWD/shop":/var/task:ro public.ecr.aws/lambda/python:3.12 shop.handler
ea0d863ca32b85d253d25ea36901da461201cf3abad48913dac811f6541ddf7c
ana@laptop:~/aws$ curl -s -XPOST localhost:9000/2015-03-31/functions/function/invocations -d '{"cents": 129990}'; echo
{"errorMessage": "Unable to import module 'shop': No module named 'shopfmt'", "errorType": "Runtime.ImportModuleError", "requestId": "", "stackTrace": []}
ana@laptop:~/aws$ docker stop shop
shop
```

`Runtime.ImportModuleError` is the error Lambda raises when the handler's file cannot be imported,
and it comes before any event is handled, which is why the `requestId` is empty. Now mount the
layer directory where Lambda unpacks layers:

```
ana@laptop:~/aws$ docker run --rm -d --name shop -p 9000:8080 -v "$PWD/shop":/var/task:ro -v "$PWD/layer":/opt:ro public.ecr.aws/lambda/python:3.12 shop.handler
c512b2c34cd5a089a7f27459521380f65ff744688d59519c13ea17b3061c882f
ana@laptop:~/aws$ curl -s -XPOST localhost:9000/2015-03-31/functions/function/invocations -d '{"cents": 129990}'; echo
{"price": "R$ 1.299,90"}
ana@laptop:~/aws$ docker exec shop ls -R /opt
/opt:
python

/opt/python:
shopfmt.py
ana@laptop:~/aws$ docker stop shop
shop
```

The runtime found `shopfmt` without being told where it was, because **the Python runtime puts
`/opt/python` on its import path**, after `/var/task`. That is why the directory inside the layer
is called `python` and not `lib` or `shopfmt`: a layer zip with the module at its root lands in
`/opt/shopfmt.py`, which no import looks at. The other runtimes have directories of their own,
`nodejs/node_modules` for Node.js and `java/lib` for Java, and a layer built for one runtime is
just files to another.

## Publishing it, and naming it

In moto, the layer becomes a published version and the function names it by ARN:

```
ana@laptop:~/aws$ cd layer && zip -r ../shopfmt.zip python && cd ..
  adding: python/ (stored 0%)
  adding: python/shopfmt.py (deflated 17%)
ana@laptop:~/aws$ aws lambda publish-layer-version --layer-name shopfmt --zip-file fileb://shopfmt.zip --compatible-runtimes python3.12 --compatible-architectures x86_64 arm64 --query "[LayerVersionArn,Version]"
[
    "arn:aws:lambda:sa-east-1:123456789012:layer:shopfmt:1",
    1
]
ana@laptop:~/aws$ cd shop && zip -q ../shop.zip shop.py && cd ..
ana@laptop:~/aws$ aws lambda create-function --function-name shop --runtime python3.12 --handler shop.handler --role arn:aws:iam::123456789012:role/greet-role --zip-file fileb://shop.zip --layers arn:aws:lambda:sa-east-1:123456789012:layer:shopfmt:1 --query "Layers"
[
    {
        "Arn": "arn:aws:lambda:sa-east-1:123456789012:layer:shopfmt:1",
        "CodeSize": 447
    }
]
```

`shopfmt:1` is immutable. Changing the module means publishing `shopfmt:2` and pointing each
function at it, with `update-function-configuration --layers`; **a function keeps the version it
names**, so a broken `shopfmt:2` reaches only the functions somebody moved. Layers are also limited
in number: a function can name at most five, and Lambda unpacks them into `/opt` in the order
given, a later one overwriting a file of the same name from an earlier one. moto records the layer
and does not unpack it anywhere, which is why the emulator, not moto, showed the import working.

## What goes in one, and what does not

| in a layer | in the function's own package |
| --- | --- |
| a library several functions share, like `shopfmt` | the handler and the code only it uses |
| a large dependency that rarely changes, so the function's zip stays small to upload | a dependency only one function uses |
| a runtime extension, such as a monitoring agent, which lives in `/opt/extensions` | anything that changes with every commit |

**A layer does not lift the 250 MB limit**: the function and all its layers are counted together,
unzipped. It does not make a cold start cheaper either, since the files are unpacked into the same
environment either way. What it buys is one copy to update and smaller uploads. What it costs is a
second thing to version: the function's behaviour now depends on code that is not in its own
package. A test of the function's zip alone, like the first run above, does not test what runs on
AWS. A team that ships each function as a whole, with its dependencies in its own package or in a
container image, has decided that cost is not worth paying, and that is a defensible decision.