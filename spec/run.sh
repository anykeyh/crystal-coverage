#!/bin/sh
crystal src/coverage/cli.cr -- spec/main.cr --use-require="./src/coverage/runtime"