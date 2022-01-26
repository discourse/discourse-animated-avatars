#!/bin/bash
if ! [ -x "$(command -v gifsicle)" ]; then
        apt update &&\
        apt install -y gifsicle
fi
