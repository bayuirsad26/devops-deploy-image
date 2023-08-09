# utils.sh
#!/usr/bin/env bash

# This function to check if the required dependencies are installed
# Dependencies are stored in an array and checked one by one
# If any dependency is missing, the script prints an error message and exits
check_dependencies() {
  IFS=' ' read -r -a dependencies <<< "${DEPENDENCIES}"
  for dependency in "${dependencies[@]}"; do
    if ! command -v "${dependency}" >/dev/null 2>&1; then
      print_error "Error: ${dependency} is not installed. Please install it and try again."
      exit 1
    fi
  done
}

# This function to load a configuration file if provided
# If the file doesn't exist or the content doesn't match the expected format, an error is logged and the script exits
load_config() {
  if [ -n "${CONFIG_FILE}" ]; then
    if [ -f "${CONFIG_FILE}" ]; then
      source "${CONFIG_FILE}"
    else
      log "Configuration file not found: ${CONFIG_FILE}"
      exit 1
    fi
  fi
  if ! [[ "${DOCKER_START_WAIT_TIME}" =~ ^[0-9]+$ ]]; then
    log "Invalid wait time: ${DOCKER_START_WAIT_TIME}. It should be a positive integer."
    exit 1
  fi
}

# Logging function to print logs with timestamp
log() {
  local message="$1"
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  echo -e "[${timestamp}] ${message}"
}

# Function to execute a command and log the provided description before execution
# It can execute local or remote commands
# If the command fails, it logs an error and exits with the same error code
execute_command() {
  local command="$1"
  local description="$2"
  local is_remote="$3"
  log "${description}"
  if [[ "${is_remote}" == "true" ]]; then
    if ssh -o ConnectTimeout=${TIME_OUT} "${REMOTE_USER}@${SERVER_ADDRESS}" "${command}"; then
      print_success "Done."
    else
      local error_code=$?
      print_error "Failed with error code ${error_code}."
      exit ${error_code}
    fi
  else
    if eval "${command}"; then
      print_success "Done."
    else
      local error_code=$?
      print_error "Failed with error code ${error_code}."
      if [ "${command}" == "yarn ${BUILD_COMMAND}" ]; then
        print_error "React-scripts build failed. Deployment process aborted."
      fi
      exit ${error_code}
    fi
  fi
}

# This function to check if the machine is connected to the internet
# If the machine is not connected, it prints an error message and exits
check_internet() {
  if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    print_error "Internet connection not detected. Please connect to the internet and try again."
    exit 1
  fi
}

# Function to print an error message with red color
print_error() {
  local message="\033[31mError: $1\033[0m"
  log "${message}"
}

# Function to print a success message with green color
print_success() {
  local message="\033[32m$1\033[0m"
  log "${message}"
}
