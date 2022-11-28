#!/bin/bash

inc=../ios/include
libs=../ios/libs

mkdir -p ${inc}
mkdir -p ${libs}

pushd ../zerokit
cbindgen --config ../ios/cbindgen.toml --crate rln --output ./librln.h --lang c
mv ./librln.h ${inc}

pushd ./rln
cargo lipo --release

popd

cp target/universal/release/librln.a ${libs}

popd
