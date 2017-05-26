#!/bin/bash

set -e

git clone https://github.com/lukas2511/dehydrated
cd dehydrated
mkdir hooks
git clone https://github.com/kappataumu/letsencrypt-cloudflare-hook hooks/cloudflare

pip install -r hooks/cloudflare/requirements-python-2.txt
