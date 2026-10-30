#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of kotlin, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# Every .kt file compiled here is lifted out of this lesson's .md by
# ../../lab.sh, so the file compiled is the block the student copies.
# Nothing is staged.
#
# Recorded on Ubuntu 24.04 with openjdk-21-jdk-headless 21.0.12.1 and Kotlin
# 2.4.21, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"

fresh kt/l04
MD=$HERE/function-types.md
kr FunctionTypes.kt functiontypes
kr Callback.kt callback
MD=$HERE/lambda-syntax.md
kr Lambdas.kt lambdas
kc LambdaReturn.kt lambdareturn
MD=$HERE/higher-order.md
kr HigherOrder.kt higherorder
MD=$HERE/trailing-lambda.md
kr Trailing.kt trailing
kr TwoLambdas.kt twolambdas
MD=$HERE/references.md
kr References.kt references
MD=$HERE/closures.md
kr Closures.kt closures
kr Late.kt late
MD=$HERE/inline.md
kr Inline.kt inline
kc NotInline.kt notinline
