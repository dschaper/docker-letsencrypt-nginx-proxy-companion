#!/bin/bash

# Make house cleaning
cd /
rm -rf /src
apk del tar git gcc musl-dev libffi-dev openssl-dev musl-dev libffi-dev openssl-dev
rm -rf /var/cache/apk/*
