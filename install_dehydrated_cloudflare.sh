#!/bin/bash

set -e

git clone https://github.com/lukas2511/dehydrated
cd dehydrated
#git reset --hard bd57777c6206ce991739b2681d09fee2b55b4afe
git reset --hard da3428a84a48d9e2db6b3107a1db0d0e8095fa0a
mkdir hooks
git clone https://github.com/kappataumu/letsencrypt-cloudflare-hook hooks/cloudflare
cd hooks/cloudflare
# git reset --hard a3c899d26e79cfa45e873dacbe85169cf84ea910
git reset --hard c72b3f9e9eab71976ddeb2bbcf45265c9ea7ee61
cd ../..

pip install -I -r hooks/cloudflare/requirements-python-2.txt
