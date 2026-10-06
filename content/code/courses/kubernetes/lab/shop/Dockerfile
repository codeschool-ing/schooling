# The shop's image. The binary is built beside this file by lab.sh, with the
# version stamped in, so the image needs nothing but itself.
FROM scratch
COPY shop /shop
USER 65532:65532
EXPOSE 8080
ENTRYPOINT ["/shop"]
