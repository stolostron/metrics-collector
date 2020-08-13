#!/bin/bash
# Copyright (c) 2020 Red Hat, Inc. 
 
echo "Running e2e test"

echo "<repo>/<component>:<tag> : $1"


$(pwd)/test/e2e/setup.sh $1 
if [ $? -ne 0 ]; then
    echo "e2e test failed"
    exit 1
fi

#$(pwd)/test/e2e/tests.sh 
if [ $? -ne 0 ]; then
    echo "Cannot pass all test cases."
    exit 1
fi
