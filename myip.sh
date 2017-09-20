#!/bin/bash

set -o errexit

jq -n --arg myip "$(curl -s ifconfig.co)" '{"myip":$myip}'
