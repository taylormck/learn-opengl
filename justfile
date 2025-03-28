default:
    @just --list

run: ensure-bin-exists
    odin run src -o:speed -out:bin/app

build: ensure-bin-exists
    odin build src -o:speed -out:bin/app

build-debug: ensure-bin-exists
    odin build src -debug -out:bin/debug

ensure-bin-exists:
    #!/usr/bin/env sh
    if [ ! -d "bin" ]; then
        mkdir bin
    fi
