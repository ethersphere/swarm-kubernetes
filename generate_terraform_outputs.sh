#!/bin/bash
mkdir ./outputs

pushd terraform-aws-eks

terraform output config-map-aws-auth > ../outputs/config-map-aws-auth.yaml

popd
