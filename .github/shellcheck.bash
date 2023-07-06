#!/bin/bash
set -eu

echo "Run shellcheck on bash files"
find . -name "*.bash" -print0 | xargs --null shellcheck --external-sources

echo "Run shellcheck on sh files"
find . -name "*.sh" -print0 | xargs --null shellcheck --external-sources

echo "Run shellcheck on make-springboot-exe";
shellcheck --external-sources src/usr/bin/make-springboot-exe

echo "Run shellcheck on make-springboot-rpm"
shellcheck --external-sources src/usr/bin/make-springboot-rpm
