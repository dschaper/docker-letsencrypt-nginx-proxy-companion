#!/bin/bash

set -e

git clone https://github.com/lukas2511/dehydrated
cd dehydrated
git reset --hard bd57777c6206ce991739b2681d09fee2b55b4afe
mkdir hooks
git clone https://github.com/kappataumu/letsencrypt-cloudflare-hook hooks/cloudflare
cd hooks/cloudflare
git reset --hard a3c899d26e79cfa45e873dacbe85169cf84ea910
cd ../..

pip install -I -r hooks/cloudflare/requirements-python-2.txt
