# docker_utils.sh
#!/usr/bin/env bash

# Function to check if Docker is installed
# If Docker is not installed, it prints an error message and exits
check_docker_installed() {
  if ! command -v docker >/dev/null 2>&1; then
    print_error "Docker is not installed. Please install Docker and try again."
    log "Visit the Docker installation page for instructions:"
    log "https://docs.docker.com/engine/install/"
    exit 1
  fi
}

# Function to start Docker if it is not running
# It checks if Docker is already running
# It detects the operating system and uses the appropriate command to start Docker
# If Docker fails to start, it prints an error message and exits
start_docker() {
  if docker info >/dev/null 2>&1; then
    print_success "Docker is already running."
    return 0
  fi
  log "Starting Docker..."
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    sudo systemctl start docker
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    open --background -a Docker
  else
    print_error "Unsupported operating system: $OSTYPE. Please use Linux or macOS."
    exit 1
  fi
  sleep "${DOCKER_START_WAIT_TIME}"
  if ! systemctl is-active docker >/dev/null 2>&1; then
    print_error "Failed to start Docker. Please check your Docker installation and try again."
    exit 1
  else
    print_success "Docker started successfully."
  fi
}

# Function to login to Docker Hub if not already logged in
# It checks if the user is already logged in
# It checks if the login was successful by checking the exit status of the last command
check_and_login_docker_hub() {
  if docker system info 2>&1 | grep -q "Username: ${DOCKER_USER}"; then
    print_success "Already logged in to Docker Hub as ${DOCKER_USER}."
  else
    local command="echo \"${DOCKER_PASSWORD}\" | docker login --username \"${DOCKER_USER}\" --password-stdin \"${REGISTRY_URL}\""
    local description="Logging in to Docker Hub as ${DOCKER_USER}..."
    execute_command "${command}" "${description}" false
    if [ "$?" -ne 0 ]; then
      print_error "Failed to log in to Docker Hub. Please check your credentials and try again."
      exit 1
    else
      print_success "Successfully logged in to Docker Hub."
    fi
  fi
}

# Function to remove, build, and push Docker images
remove_build_push() {
  log "Checking for existing image..."
  if [ "${FORCE}" = true ] || docker images "${IMAGE_FULL_NAME}" | grep -q "${IMAGE_NAME}"; then
    log "Removing existing image, building new image, and pushing to Docker Hub..."
    docker rmi -f "${IMAGE_FULL_NAME}" >/dev/null 2>&1
  else
    log "Building new image and pushing to Docker Hub..."
  fi
  docker build -t "${IMAGE_FULL_NAME}" -f "./${DOCKERFILE}" . && \
    docker push "${IMAGE_FULL_NAME}"
  if [ "$?" -ne 0 ]; then
    print_error "Failed to build or push the image."
    exit 1
  fi
}

# Function to remove a specified Docker image from the remote server over SSH
# If the removal process fails, it exits with an error message and the error status from the docker rmi command
remove_remote_docker_image() {
  log "Removing existing ${IMAGE_FULL_NAME} image on remote server..."
  if ssh -o ConnectTimeout=${TIME_OUT} "${REMOTE_USER}@${SERVER_ADDRESS}" "docker rmi -f ${IMAGE_FULL_NAME}"; then
    print_success "Existing ${IMAGE_FULL_NAME} image successfully removed on remote server"
  else
    local error_code=$?
    print_error "Failed to removed existing ${IMAGE_FULL_NAME} image on remote server with error code ${error_code}"
    exit ${error_code}
  fi
}

# Function to restart a specified Docker container on the remote server over SSH
# If the restart process fails, it exits with an error message and the error status from the docker-compose up command
restart_container_remote() {
  log "Restarting ${CONTAINER_TO_RESTART[*]} containers on remote server"
  if ssh -o ConnectTimeout=${TIME_OUT} "${REMOTE_USER}@${SERVER_ADDRESS}" "cd ${PLATFORM_PATH} && docker-compose up -Vd ${CONTAINER_TO_RESTART[*]}"; then
    print_success "${CONTAINER_TO_RESTART[*]} containers restarted successfully on remote server"
  else
    local error_code=$?
    print_error "Failed to restart ${CONTAINER_TO_RESTART[*]} containers with error code ${error_code}"
    exit ${error_code}
  fi
}

# Function to check the status of a specified Docker container on the remote server over SSH
# Depending on the container's status, it logs a success message, or exits with an error message and status 1
check_remote_container_status() {
  local container_names=("$@")
  for container_name in "${container_names[@]}"; do
    local container_status=$(ssh "${REMOTE_USER}@${SERVER_ADDRESS}" "docker container ls --filter \"name=${container_name}\" --format \"{{.Status}}\" | grep -oE \"Up|Restarting|Down\"")
    log "Checking if ${container_name} container is up and running on remote server"
    case "${container_status}" in
      Up)
        print_success "${container_name} container is up and running on remote server"
        ;;
      Restarting)
        print_error "${container_name} container is restarting on remote server, please check the logs and configuration"
        exit 1
        ;;
      Down)
        print_error "${container_name} container is down on remote server, please check the logs and configuration"
        exit 1
        ;;
      *)
        print_error "${container_name} container not found or unexpected status on remote server, please check the logs and configuration"
        exit 1
        ;;
    esac
  done
}

# Function to check the status of a specified Docker container either on the local or remote system
# Depending on the container's status, it logs a success message, or exits with an error message and status 1
check_container_status() {
  local container_name="$1"
  local is_remote="$2"
  local container_status
  log "Checking if ${container_name} container is up and running${is_remote:+" on remote server"}"
  if [[ "${is_remote}" == "true" ]]; then
    container_status=$(ssh "${REMOTE_USER}@${SERVER_ADDRESS}" "docker container ls --filter \"name=${container_name}\" --format \"{{.Status}}\" | grep -oE \"Up|Restarting|Down\"")
  else
    container_status=$(docker container ls --filter "name=${container_name}" --format "{{.Status}}" | grep -oE "Up|Restarting|Down")
  fi
  case "${container_status}" in
    Up)
      print_success "${container_name} container is up and running${is_remote:+" on remote server"}"
      ;;
    Restarting)
      print_error "${container_name} container is restarting${is_remote:+" on remote server"}, please check the logs and configuration"
      exit 1
      ;;
    Down)
      print_error "${container_name} container is down${is_remote:+" on remote server"}, please check the logs and configuration"
      exit 1
      ;;
    *)
      print_error "${container_name} container not found or unexpected status${is_remote:+" on remote server"}, please check the logs and configuration"
      exit 1
      ;;
  esac
}

# Function to prune unused Docker images on the remote server over SSH
# If the prune process fails, it exits with an error message and the error status from the docker image prune command
prune_remote_docker_images() {
  log "Pruning unused images on remote server..."
  if ssh -o ConnectTimeout=${TIME_OUT} "${REMOTE_USER}@${SERVER_ADDRESS}" "docker image prune -f"; then
    print_success "Unused image successfully removed on remote server"
  else
    local error_code=$?
    print_error "Failed to removed unused image on remote server with error code ${error_code}"
    exit ${error_code}
  fi
}
