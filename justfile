default:
    @just --list

run: ensure-bin-exists
    odin run src -o:speed -out:bin/app

build: ensure-bin-exists
    odin build src -o:speed -out:bin/app

build-debug: ensure-bin-exists
    odin build src -debug -out:bin/learn-opengl

build-debug-test: ensure-bin-exists
    odin build src -out:bin/test -build-mode:test -debug

test package="src --all-packages":
    odin test {{package}} -out:bin/test

ensure-bin-exists:
    #!/usr/bin/env sh
    if [ ! -d "bin" ]; then
        mkdir bin
    fi
