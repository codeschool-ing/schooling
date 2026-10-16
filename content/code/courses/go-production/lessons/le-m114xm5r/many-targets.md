`release.sh`:

```sh
#!/bin/sh
# release.sh builds hits for each target below, into release/.
set -eu

targets="linux/amd64 linux/arm64 darwin/amd64 darwin/arm64 windows/amd64 windows/arm64"

rm -rf release
mkdir release
for t in $targets; do
	os=${t%/*}
	arch=${t#*/}
	ext=
	if [ "$os" = windows ]; then
		ext=.exe
	fi
	out=release/hits-$os-$arch$ext
	CGO_ENABLED=0 GOOS=$os GOARCH=$arch go build -o "$out" .
	echo "$out"
done
```
