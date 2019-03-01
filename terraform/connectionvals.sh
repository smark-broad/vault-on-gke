#/bin/#!/usr/bin/env bash
export VAULT_ADDR="https://${vault_address}"
export VAULT_TOKEN="${root_token}"
export VAULT_CAPATH="$(cd ../ && pwd)/tls/ca.pem"
