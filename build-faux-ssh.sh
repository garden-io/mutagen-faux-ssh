#!/bin/bash

RELEASE_VERSION="0.0.1"

set -e

# declare constants for build dir and Go module name
go_module_build_name="main"
build_output_root_dir="build"

echo "Creating build root dir at ${build_output_root_dir}"
mkdir -p ${build_output_root_dir}

cur_goos=$GOOS
cur_goarch=$GOARCH
cur_goarm=$GOARM

function restore_env() {
  export GOOS=${cur_goos}
  export GOARCH=${cur_goarch}
  export GOARM=${cur_goarm}
}

function configure_env() {
  local goos=$1
  local goarch=$2

  export GOOS=${goos}
  export GOARCH=${goarch}

  # Here we use the same min ARM support version as Mutagen,
  # see https://github.com/mutagen-io/mutagen/blob/master/scripts/build.go
  local goarm
  if [[ ${goarch} == "arm64" ]]; then
    goarm="5"
  else
    goarm=""
  fi
  echo "Setting GOARM=${goarm}"
  export GOARM=${goarm}

  # TODO: set min macOS version, see Mutagen build script for details
}

function build() {
  local goos=$1
  local goarch=$2

  echo "Configuring build env for ${goos}-${goarch}"
  configure_env ${goos} ${goarch}

  echo "Building for ${goos}-${goarch}"
  go build -o ${go_module_build_name} .

  local output_dir="${build_output_root_dir}/${goos}-${goarch}"
  echo "Creating output dir ${output_dir}"
  mkdir -p ${output_dir}

  local binary_name="ssh"
  if [[ ${goos} == "windows" ]]; then
    binary_name="ssh.exe"
  fi

  echo "Renaming binary to ${binary_name}"
  mv ${go_module_build_name} ${binary_name}

  local distr_name="mutagen-faux-ssh-${RELEASE_VERSION}-${goos}-${goarch}.tar.gz"
  tar -vzcf ${distr_name} ${binary_name}
  echo "Done!"
  echo ""
}

echo "Copying sources to the build directory"
cd ${build_output_root_dir}
cp "../src/go.mod" .
cp "../src/main.go" .

build "darwin" "amd64"
build "darwin" "arm64"
build "linux" "amd64"
build "linux" "arm64"
build "windows" "amd64"

echo "Restoring env"
restore_env
echo "Restoring done"
