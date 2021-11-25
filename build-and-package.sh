#!/bin/bash

set -e

pushd libraries/api-csharp

rm -rf dist

dotnet pack -c Release -o dist src/Calcasa.Api/Calcasa.Api.csproj

dotnet nuget push dist/*.nupkg --source https://api.nuget.org/v3/index.json --api-key "${NUGET_API_KEY}"

popd

pushd libraries/api-python

rm -rf dist

python setup.py bdist_wheel

python -m twine upload --repository pypi dist/*

popd