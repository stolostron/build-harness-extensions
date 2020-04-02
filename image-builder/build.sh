#!/bin/bash

for file in $( ls Dockerfile.* ) ; do
    tag="${file#*.}"
    echo ">>> Building image-builder:$tag from $file"
    docker build -t "image-builder:$tag" -f "$file" .
    echo ; echo
done

echo ">>> image builders"
docker images | grep "image-builder"
