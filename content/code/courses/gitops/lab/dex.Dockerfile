# Dex, built from its tagged source by lab.sh. Argo CD's argocd-dex-server runs
# `argocd-dex rundex`, which writes dex's configuration and starts `dex serve`.
FROM buildpack-deps:trixie-curl
COPY dex /usr/local/bin/dex
USER 1001
