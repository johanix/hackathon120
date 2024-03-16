#!/bin/bash

inotifywait -m -e modify,moved_to /zones | while read dir event file; do
  echo "File update detected: $file $event, would run dnssec-signzone -S $file"
done
