#!/usr/bin/env bash

{
  #######################
  # BEGIN CONFIGURATION #
  #######################

  # Binary install location
  : ${INSTALL_DIR:="${HOME}/.wasmflow/bin"}

  # Github Organization name
  ORG_NAME=wasmflow
  # Github Project name
  PROJECT_NAME=wasmflow

  # Files to extract from the release archive.
  ARCHIVE_FILES=("wasmflow" "wafl")
  # Local binary to test for existing installation
  INSTALLED_TEST_BIN="${INSTALL_DIR}/${ARCHIVE_FILES[0]}"

  SUPPORT_MESSAGE="For support, go to https://wasmflow.com/ or reach out to us on Twitter @wasmflow."
  BASE_URL="https://github.com/${ORG_NAME}/${PROJECT_NAME}/releases"

  CONSOLATION_MSG="You can try building a custom version from source at https://github.com/${ORG_NAME}/${PROJECT_NAME}/"

  #######################
  #  END CONFIGURATION  #
  #######################

  # Default HTTP request CLI
  HTTP_REQUEST_CLI=curl

  ARCH=$(uname -m)
  OS=$(echo $(uname) | tr '[:upper:]' '[:lower:]')

  # Apple silicon machines expose ARCH as "arm64"
  if [ "$OS" = "darwin" -a "$ARCH" = "arm64" ]; then
    ARCH="aarch64"
  fi

  # Create the temp directory
  TMP_ROOT=$(mktemp -dt ${ORG_NAME}-${PROJECT_NAME}-install)
  ARTIFACT_NAME="${PROJECT_NAME}.${OS}.${ARCH}.tar.gz"
  ARTIFACT_TMP_FILE="$TMP_ROOT/$ARTIFACT_NAME"

  intro() {
    echo "This will install ${PROJECT_NAME} to ${INSTALL_DIR}."
  }

  verifySupported() {
    local supported=(darwin-aarch64 darwin-x86_64 linux-aarch64 linux-x86_64)
    local current_osarch="${OS}-${ARCH}"

    for osarch in "${supported[@]}"; do
      if [ "$osarch" == "$current_osarch" ]; then
        echo "Your system is detected to be ${current_osarch}"
        return
      fi
    done

    echo "Sorry, there is no prebuilt binary for operating system and architecture: '${OS}-${ARCH}'."
    exit 1
  }

  cpFile() {
    local file=$1
    local dest_dir=$2
    echo "Copying $(basename ${file})..."
    if [ ! -d "$dest_dir" ]; then
      echo "Making directory ${dest_dir}"
      mkdir -p $dest_dir
    fi

    cp $file $dest_dir
  }

  checkHttpRequestCLI() {
    if type "curl" >/dev/null; then
      HTTP_REQUEST_CLI=curl
    elif type "wget" >/dev/null; then
      HTTP_REQUEST_CLI=wget
    else
      echo "Either curl or wget is required to download the release artifact."
      exit 2
    fi
  }

  checkExistingFile() {
    if [ -f "$INSTALLED_TEST_BIN" ]; then
      local version=$($INSTALLED_TEST_BIN --version)
      echo "Detected existing component: ${INSTALLED_TEST_BIN} ($version)"
      echo "Reinstalling ${PROJECT_NAME} - ${INSTALLED_TEST_BIN}..."
    else
      echo "Installing ${PROJECT_NAME}..."
    fi
  }

  downloadFile() {
    RELEASE_TAG=$1
    DOWNLOAD_URL="${BASE_URL}/download/${RELEASE_TAG}/${ARTIFACT_NAME}"

    if [ "$RELEASE_TAG" = "latest" ]; then
      DOWNLOAD_URL="${BASE_URL}/${RELEASE_TAG}/download/${ARTIFACT_NAME}"
    fi

    echo "Downloading $DOWNLOAD_URL..."
    if [ "$HTTP_REQUEST_CLI" == "curl" ]; then
      curl -SsL "$DOWNLOAD_URL" -o "$ARTIFACT_TMP_FILE"
    else
      wget -q -O "$ARTIFACT_TMP_FILE" "$DOWNLOAD_URL"
    fi

    if [ ! -f "$ARTIFACT_TMP_FILE" ]; then
      echo "failed to download $DOWNLOAD_URL ..."
      exit 5
    fi
    echo "Downloaded archive to $ARTIFACT_TMP_FILE..."
  }

  installFile() {
    tar xf "$ARTIFACT_TMP_FILE" -C "$TMP_ROOT"
    echo "Copying files to $INSTALL_DIR"
    for file in ${ARCHIVE_FILES[@]}; do
      local filepath="$TMP_ROOT/${PROJECT_NAME}/$file"

      if [ ! -f "$filepath" ]; then
        echo "Failed to unpack $filepath."
        exit 3
      fi

      chmod o+x $filepath
      cpFile "$filepath" "$INSTALL_DIR"
      local destpath="$INSTALL_DIR/$file"
      if [ -f "$destpath" ]; then
        local version=$($destpath --version)
        echo "Installed $file into $INSTALL_DIR successfully ($version)"
      else
        echo "Could not find $destpath, installation failed."
        exit 4
      fi
    done

  }

  separate_output() {
    sleep .1
    for i in $(seq 3); do
      echo
      sleep .05
    done
    sleep .1
  }

  fail_trap() {
    result=$?
    if [ "$result" != "0" ]; then
      separate_output
      echo "Failed to install $PROJECT_NAME."
      if [ "$CONSOLATION_MSG" != "" ]; then
        echo $CONSOLATION_MSG
      fi
      echo $SUPPORT_MESSAGE
    fi
    cleanup
    exit $result
  }

  cleanup() {
    if [[ -d "${TMP_ROOT:-}" ]]; then
      rm -rf "$TMP_ROOT"
    fi
  }

  installCompleted() {
    echo "**** Congratulations, $PROJECT_NAME installed successfully! ****"
    echo ""
    echo "If you want to run $PROJECT_NAME binaries easily, add the installation"
    echo "directory (${INSTALL_DIR}) to your path, e.g."
    echo ""
    echo "# Add ${PROJECT_NAME} bins to our \$PATH"
    echo "PATH=${INSTALL_DIR}:\$PATH"
  }

  # -----------------------------------------------------------------------------
  # main
  # -----------------------------------------------------------------------------
  trap "fail_trap" EXIT

  intro
  separate_output
  verifySupported
  checkExistingFile
  checkHttpRequestCLI

  echo "Installing latest $PROJECT_NAME release..."

  downloadFile "latest"
  installFile
  cleanup

  separate_output

  installCompleted

}
