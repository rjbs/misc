#!/bin/sh
cover -delete
if [ -e Makefile ]; then
  HARNESS_PERL_SWITCHES=-MDevel::Cover make test
elif [ -e Build ]; then
  HARNESS_PERL_SWITCHES=-MDevel::Cover ./Build test
else
  echo no way to build!
fi
cover
