#!/bin/bash

set -e

# Install python packages needed to build simp_le
apk --update add python py-requests py-setuptools git gcc py-pip musl-dev libffi-dev python-dev openssl-dev

# Get Let's Encrypt simp_le client source
branch="0.2.0"
mkdir -p /src
git -C /src clone --depth=1 --branch $branch https://github.com/zenhack/simp_le.git

# Install simp_le in /usr/bin
cd /src/simp_le
python ./setup.py install
