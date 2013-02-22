#!/bin/bash

REGEX="do\s*$|it_behaves_like"

for spec in `find spec -type f -name "*.rb" -printf "%P\n"`
do
  IOLIKE_FILES="spec/$spec"
  if [ $spec == "eof_spec.rb" ] ; then
    IOLIKE_FILES="$IOLIKE_FILES spec/shared/eof.rb"
  fi

  RS_FILES="rubyspec/core/io/$spec"
  if [ $spec == "putc_spec.rb" ] ; then
    RS_FILES="$RS_FILES rubyspec/shared/io/putc.rb"
  fi

  echo -e "<<< $IOLIKE_FILES\n>>> $RS_FILES" > spec/$spec.diff

  if [ -f rubyspec/core/io/$spec ] ; then
    
    diff <(cat $IOLIKE_FILES | egrep "$REGEX") <(cat $RS_FILES | egrep "$REGEX") >> spec/$spec.diff
  else
     if [ $spec != "shared/eof.rb" ] ; then
       echo "Missing rubyspec file to match $spec"
     fi
  fi
done
