#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of front-multiplatform, as a script
# that produces them; lab/fill.py pastes each block into its fence.
#
#   sudo bash captures.sh > out.txt
#
# It starts from what lesson 12 left. icon.svg is taken from icons.md by
# lab/extract.py; every other change is made by the command the lesson prints.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - electron-builder downloads its own tools on first use (the AppImage
#     runtime, 7-Zip, fpm and a copy of Electron) from GitHub; the recording
#     machine reached them, and the lesson says that a first build downloads.
#   - The AppImage runs with APPIMAGE_EXTRACT_AND_RUN=1, because a container
#     has no FUSE to mount it with; on a desktop it runs as it is. The window
#     opens on Xvfb, as in lessons 11 and 12, and the display is asked what it
#     holds.
#   - The commit carries a fixed date.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
start_from 12
P=/home/ana/planner

put icons.md icon.svg $P/icon.svg
block tauri-icon
run $P 'npx tauri icon icon.svg > /dev/null 2>&1'
run $P 'ls src-tauri/icons'
run $P 'file src-tauri/icons/icon.png src-tauri/icons/android/mipmap-xxxhdpi/ic_launcher.png | cut -d, -f1,2'

block cap-assets
run $P 'npm install -E -D @capacitor/assets@3.0.5 > /dev/null 2>&1'
run $P 'mkdir assets && cp icon.svg assets/logo.svg'
run $P 'npx capacitor-assets generate --android --ios 2>&1 | tail -n 3'
run $P 'git status --short --untracked-files=all android ios | wc -l'

block builder-first
run $P 'npm install -E -D electron-builder@26.18.0 > /dev/null 2>&1'
run $P 'npx electron-builder --linux AppImage > /dev/null 2>&1; ls dist'
run $P 'rm -rf dist && npm run build > /dev/null && ls dist'

block builder-config
run $P 'npm pkg set build.appId=com.example.studyplanner build.productName="Study planner" build.directories.output=release "build.files[]=dist/**" "build.files[]=electron/**"'
run $P 'npm pkg set build.linux.category=Education build.linux.icon=src-tauri/icons/icon.png "build.linux.target[]=AppImage" "build.linux.target[]=deb" "build.artifactName=\${name}-\${version}-\${arch}.\${ext}"'
run $P 'npx electron-builder --linux 2>&1 | grep -E "^(Please|It is required)"'

block builder-author
run $P 'npm pkg set version=0.1.0 description="A study planner" homepage=https://example.com/planner author.name=Ana author.email=ana@example.com'
run $P 'rm -rf release && npx electron-builder --linux 2>&1 | grep -o "target=.*"'
run $P 'du -sh release/*.AppImage release/*.deb'

block inside
run $P 'npx asar list release/linux-unpacked/resources/app.asar | cut -d/ -f2-3 | sort -u'

block appimage
run $P 'xvfb-run -a sh -c "APPIMAGE_EXTRACT_AND_RUN=1 timeout 12 release/*.AppImage > /dev/null 2>&1 & sleep 10; xwininfo -root -tree | grep -o \"Study planner.*\" | head -n 1"'

block depends
run $P 'npx tauri build --bundles deb 2>&1 | tail -n 2'
run $P 'dpkg-deb -f release/*.deb Package Version Depends'
run $P 'dpkg-deb -f src-tauri/target/release/bundle/deb/planner_0.1.0_amd64.deb Package Version Depends'

block release-check
run $P 'grep -n "url\|cleartext" capacitor.config.ts android/app/src/main/assets/capacitor.config.json ios/App/App/capacitor.config.json; echo "grep exit status: $?"'

block commit
RUNENV="export GIT_AUTHOR_DATE='2026-10-23 18:00:00 -0300' GIT_COMMITTER_DATE='2026-10-23 18:00:00 -0300'"
run $P 'echo release/ >> .gitignore'
run $P 'git add . && git commit -q -m "Icons, and the Electron packages" && git log --oneline -1'
save_as 13
