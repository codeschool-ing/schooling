---
title: Installing it on your computer
version: 1
---

**Fastlane is a Ruby gem, and a gem is installed per project with a pinned version, never once for
the whole computer.** The project lists it in a `Gemfile`; **Bundler** installs exactly that version
into a folder of the project, and every command runs through `bundle exec`, so two projects can use
two versions without either noticing.

## Ruby and Bundler

On Ubuntu and WSL, Ruby and Bundler come from the system's packages, and `build-essential` is for
the few gems that compile something when they install:

```sh
sudo apt install ruby-full ruby-bundler build-essential
```

On a Mac, Apple's own Ruby is old and should not be used for this; Fastlane's documentation
recommends a Ruby from Homebrew, or installing Fastlane itself with `brew install fastlane`. *The
Mac path was not run for this course.*

## The planner's Gemfile

Save this as `Gemfile` in `~/planner`:

```
# Gemfile: the Ruby tools of the planner's release, at exact versions
source "https://rubygems.org"
gem "fastlane", "2.228.0"
```

Tell Bundler to keep the gems inside the project, in `vendor/bundle`, so nothing is written outside
it, and install. It takes a minute or two, because Fastlane brings around a hundred other gems with
it:

```sh
bundle config set --local path vendor/bundle
bundle install
```

Add `vendor/bundle` to `.gitignore`; the `Gemfile.lock` that Bundler writes is committed, because it
is lesson 10's lockfile for the Ruby side.

## Five settings for quiet, honest output

Fastlane checks for its own updates on every run, prints timestamps, colours its output, marks each
line a command prints with an arrow, and sends **anonymous usage data** to its maintainers unless
told not to. In a pipeline and in this course, all five are turned off. Add these lines to `~/.profile`, or to the environment of the CI job:

```sh
export FASTLANE_SKIP_UPDATE_CHECK=1
export FASTLANE_HIDE_TIMESTAMP=1
export FASTLANE_DISABLE_COLORS=1
export FASTLANE_DISABLE_OUTPUT_FORMAT=1
export FASTLANE_OPT_OUT_USAGE=1
```

The last one belongs in lesson 5's inventory in spirit: it is a tool on your computer sending data
about your project to somebody else, and it is your choice to stop it. Then check that it answers:

```
ana@dev:~/planner$ bundle exec fastlane --version
fastlane installation at path:
/home/ana/planner/vendor/bundle/ruby/3.2.0/gems/fastlane-2.228.0/bin/fastlane
-----------------------------
fastlane 2.228.0
```
