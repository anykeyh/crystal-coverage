#!/bin/sh
crystal src/coverage/cli.cr -- spec/template.cr --use-require="./src/coverage/runtime" -p