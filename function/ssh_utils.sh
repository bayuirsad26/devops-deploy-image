# ssh_utils.sh
#!/usr/bin/env bash

# Function checks if an SSH key pair exists
# If it does not, it generates a new one
check_and_generate_ssh_key() {
  log "Checking for existing SSH key pair"
  if [ ! -f "$HOME/.ssh/${SSH_KEY}" ] || [ ! -f "$HOME/.ssh/${SSH_PUB}" ]; then
    log "Generating SSH key pair"
    ssh-keygen -t rsa -b 4096 -C "${EMAIL}" -N "" -f "$HOME/.ssh/${SSH_KEY}" &>/dev/null
    print_success "SSH key pair generated"
  else
    log "SSH key pair already present"
  fi
}

# This function checks if specified files or directories exist in the local filesystem
# If they exist, it removes them
check_and_remove_files() {
  local build_result="$1"
  local zip_name="$2"
  local directory_name="$3"
  if [ -d "${build_result}" ]; then
    log "${build_result} folder exists, removing it"
    rm -rf "${build_result}"
  else
    log "${build_result} folder does not exist"
  fi
  if [ -f "${zip_name}" ]; then
    log "${zip_name} file exists, removing it"
    rm -f "${zip_name}"
  else
    log "${zip_name} file does not exist"
  fi
  if [ -d "${directory_name}" ]; then
    log "${directory_name} folder exists, removing it"
    rm -rf "${directory_name}"
  else
    log "${directory_name} folder does not exist"
  fi
}

# Function to check if the local machine's public key is present on the remote server
# If it isn't, it copies it over using ssh-copy-id
check_and_copy_public_key() {
  log "Checking if public key is on remote server"
  if ! ssh "${REMOTE_USER}@${SERVER_ADDRESS}" "grep -qxF \"$(cat ~/.ssh/${SSH_PUB})\" ~/.ssh/authorized_keys" &>/dev/null; then
    log "Public key not found on remote server"
    log "Copying public key using ssh-copy-id"
    ssh-copy-id -o ConnectTimeout=${TIME_OUT} "${REMOTE_USER}@${SERVER_ADDRESS}"
    print_success "Public key copied to remote server"
  else
    log "Public key already present on remote server"
  fi
}

# Function to check if specified files or directories exist in the remote filesystem
# It checks if specified files or directories exist in the remote filesystem and removes them if they do
check_and_remove_remote_files() {
  local zip_name="$1"
  local directory_name="$2"
  local remote_zip_path="${REMOTE_PATH}/${zip_name}"
  local remote_directory_path="${REMOTE_PATH}/${directory_name}"
  log "Checking if ${remote_zip_path} exists on remote server"
  if ssh -o ConnectTimeout=${TIME_OUT} "${REMOTE_USER}@${SERVER_ADDRESS}" "test -f ${remote_zip_path}"; then
    log "${remote_zip_path} exists, removing it"
    ssh "${REMOTE_USER}@${SERVER_ADDRESS}" "rm -f ${remote_zip_path}"
  else
    log "${remote_zip_path} does not exist"
  fi
  log "Checking if ${remote_directory_path} exists on remote server"
  if ssh -o ConnectTimeout=${TIME_OUT} "${REMOTE_USER}@${SERVER_ADDRESS}" "test -d ${remote_directory_path}"; then
    log "${remote_directory_path} exists, removing it"
    ssh "${REMOTE_USER}@${SERVER_ADDRESS}" "rm -rf ${remote_directory_path}"
  else
    log "${remote_directory_path} does not exist"
  fi
}

# Function to unzips a specified file on the remote server over SSH
# If the unzip process fails, it exits with an error message and the error status from the unzip command
unzip_remote_file() {
  local zip_name="$1"
  local remote_zip_path="${REMOTE_PATH}/${zip_name}"
  log "Unzipping ${remote_zip_path} on remote server"
  if ssh -o ConnectTimeout=${TIME_OUT} "${REMOTE_USER}@${SERVER_ADDRESS}" "unzip -qo ${remote_zip_path} -d ${REMOTE_PATH}"; then
    print_success "Unzipped ${remote_zip_path} successfully"
  else
    local error_code=$?
    print_error "Failed to unzip ${remote_zip_path} with error code ${error_code}"
    exit ${error_code}
  fi
}
