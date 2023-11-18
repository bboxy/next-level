#!/bin/sh
LC_CTYPE=C && LANG=C && cat "$1" | sed 's/\r/\n/g' | sed 's/\(.*\)\.B/\1\n.b/g' | sed '/^$/d' | sed 's/\xa4/_/g' | sed 's/^.b[[:space:]]*/\t\t!byte /g' | tr '[:upper:]' '[:lower:]'
