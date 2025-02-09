#!/bin/bash
#
# Copyright (c) 2021 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#

set -e

VERSION="${1%/}"
CHE_THEIA_DEVWORKSPACE_HANDLER_VERSION=0.0.1-1639071223
CHE_CODE_DEVWORKSPACE_HANDLER_VERSION=1.64.0-dev-210b722

# shellcheck disable=SC1091
source ./clone_and_zip.sh

mkdir -p /build/resources/v2/
for dir in /build/devfiles/*/
do
  devfile_url=$(grep "v2:" "${dir}"meta.yaml) || :
  if [ -n "$devfile_url" ]; then
    devfile_url=${devfile_url##*v2: }
    devfile_url=${devfile_url%/}
    devfile_repo=${devfile_url%/tree*}
    name=$(basename "${devfile_repo}")

    npm_config_yes=true npx @eclipse-che/che-theia-devworkspace-handler@${CHE_THEIA_DEVWORKSPACE_HANDLER_VERSION} --devfile-url:"${devfile_url}" \
    --output-file:"${dir}"/devworkspace-che-theia-next.yaml \
    --project."${name}={{ INTERNAL_URL }}/resources/v2/${name}.zip"

    npm_config_yes=true npx @eclipse-che/che-theia-devworkspace-handler@${CHE_THEIA_DEVWORKSPACE_HANDLER_VERSION} --devfile-url:"${devfile_url}" \
    --editor:eclipse/che-theia/latest \
    --output-file:"${dir}"/devworkspace-che-theia-latest.yaml \
    --project."${name}={{ INTERNAL_URL }}/resources/v2/${name}.zip"

    npm_config_yes=true npx @eclipse-che/che-code-devworkspace-handler@${CHE_CODE_DEVWORKSPACE_HANDLER_VERSION} --devfile-url:"${devfile_url}" \
    --editor-entry:che-incubator/che-code/insiders \
    --output-file:"${dir}"/devworkspace-che-code-insiders.yaml \
    --project."${name}={{ INTERNAL_URL }}/resources/v2/${name}.zip"

    # When release is happend, we need to replace tags of images in che-theia editor
    if [ -n "$VERSION" ]; then
      cheTheia="quay.io/eclipse/che-theia"
      cheTheiaEndpointRuntimeBinary="${cheTheia}-endpoint-runtime-binary"
      cheMachineExec="quay.io/eclipse/che-machine-exec"
      sed -i "${dir}/devworkspace-che-theia-latest.yaml" \
          -e "s#${cheTheia}@sha256:\([a-z0-9\_]\([\-\.\_a-z0-9]\)*\)#${cheTheia}:${VERSION}#"
      sed -i "${dir}/devworkspace-che-theia-latest.yaml" \
          -e "s#${cheTheiaEndpointRuntimeBinary}@sha256:\([a-z0-9\_]\([\-\.\_a-z0-9]\)*\)#${cheTheiaEndpointRuntimeBinary}:${VERSION}#"
      sed -i "${dir}/devworkspace-che-theia-latest.yaml" \
          -e "s#${cheMachineExec}@sha256:\([a-z0-9\_]\([\-\.\_a-z0-9]\)*\)#${cheMachineExec}:${VERSION}#"
    fi

    clone_and_zip "${devfile_repo}" "${devfile_url##*/}" "/build/resources/v2/$name.zip"
  fi
done
