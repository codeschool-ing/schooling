#!/usr/bin/env bash
# The terminal sessions quoted in lesson 23 of react-ts, as a script that
# produces them.
#
#   sudo -E bash captures.sh           # after lesson 22's captures.sh
#
# Works in ~/planner as lesson 22 left it. What is STAGED rather than typed: the
# files ana wrote, put below and shown in the lesson; and ana's git identity,
# user.name and user.email, which the `git` course has every student set once
# for their machine. Nothing runs a server here.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/captures-lib.sh
lab restore after-le-p948qfsj
lab exec ana 'git config --global user.name "Ana" && git config --global user.email "ana@example.com" && git config --global init.defaultBranch main'

block git
on 'git init -q && git add -A && git commit -q -m "The planner, as lesson 22 left it" && git log --format=%s'

block oxlint
on "sed -i 's|^  const heading = useRef<HTMLHeadingElement>(null)\$|&\\n  console.log(heading.current)|' src/CourseScreen.tsx && sed -n '17,18p' src/CourseScreen.tsx"
on 'npm run lint'

block eslint
on 'npm install --save-dev eslint@10.13.0 @eslint/js@10.0.1 typescript-eslint@8.72.0 eslint-plugin-react-hooks@7.1.1 eslint-plugin-react-refresh@0.5.7 globals@17.13.0'
put eslint.config.js <<'JS'
import js from '@eslint/js'
import reactHooks from 'eslint-plugin-react-hooks'
import reactRefresh from 'eslint-plugin-react-refresh'
import { defineConfig, globalIgnores } from 'eslint/config'
import globals from 'globals'
import tseslint from 'typescript-eslint'

export default defineConfig([
  globalIgnores(['dist']),
  {
    files: ['**/*.{ts,tsx}'],
    extends: [
      js.configs.recommended,
      tseslint.configs.recommended,
      reactHooks.configs.flat.recommended,
      reactRefresh.configs.vite,
    ],
    languageOptions: {
      globals: globals.browser,
    },
  },
])
JS
block eslint-run
on 'npx eslint .'
block speed
on "sed -i '/^  console.log(heading.current)\$/d' src/CourseScreen.tsx && git status --short"
on 'time npx eslint .'
on 'time npx oxlint'

block prettier
on 'npm install --save-dev prettier@3.9.10'
on 'npx prettier --check . 2>&1 | tail -n 3'
put .prettierrc.json <<'JSON'
{
  "semi": false,
  "singleQuote": true,
  "printWidth": 100
}
JSON
block prettier-config
on 'npx prettier --check .'
on 'git add -A && git commit -q -m "Add ESLint and Prettier" && npx prettier --write . > /dev/null && git diff --stat'
on "sed -n '26,42p' src/week.ts"

block biome
on 'npm install --save-dev @biomejs/biome@2.6.2'
on "npx biome init > /dev/null && npx biome check src 2>&1 | grep -E '^(Checked|Found)'"
on "npx biome migrate prettier --write > /dev/null && npx biome check src 2>&1 | grep -E '^(Checked|Found)'"
on "npx biome check src 2>&1 | grep '^src' | sed 's/ ━.*//'"
block biome-out
on 'npm uninstall @biomejs/biome && rm biome.json && git status --short'

block hook
on 'npm pkg set scripts.format="prettier --write ." scripts.check="prettier --check . && npm run lint && tsc -b && npm test" && grep -A 9 "\"scripts\"" package.json'
put .git/hooks/pre-commit <<'SH'
#!/bin/sh
# Runs before every `git commit`; a failure stops the commit.
exec npm run check
SH
on 'chmod +x .git/hooks/pre-commit'
block hook-fails
on "printf 'export const late    =   true\\n' > src/late.ts && git add -A && git commit -q -m 'Format the code' 2>&1 | tail -n 6"
block hook-ok
on 'npm run format > /dev/null && git add -A && git commit -q -m "Format the code" 2> /dev/null && git log --format=%s'
on 'git rm -q src/late.ts && git commit -q -m "Remove an example" 2> /dev/null && git log --format=%s | head -n 1'

lab save after-$(basename "$PWD")
finish
