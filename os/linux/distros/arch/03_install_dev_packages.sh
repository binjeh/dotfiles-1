#!/bin/bash
# Copyright (C) 2021 Jef Oliver.
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
# SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
# IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
# Authors:
# Jef Oliver <jef@eljef.me>

################################################################################
# DO NOT EDIT BELOW HERE
################################################################################

function failure() {
    echo -e "\n${1}\n" 2>&1
    exit 1
}

if [[ ${EUID} -ne 0 ]]; then
    failure "This script must be run as root."
fi

echo "Installing packages with pacman"
pacman -S bash-language-server \
          diff-so-fancy \
          flake8 \
          git \
          glow \
          go \
          make \
          nodejs \
          nodejs-markdownlint-cli \
          npm \
          nvm \
          python-black \
          python-pylint \
          python-pynvim \
          python-pytest \
          python-pytest-cov \
          shellcheck \
          write-good || failure "failed to install packages with pacman"

echo "Installing packages with pip"
pip3 install -U pytest-pythonpath || failure "failed to install packages with pip"
