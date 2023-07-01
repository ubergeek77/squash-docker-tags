#!/bin/bash

# Clean the source tags input
# Replace newlines with spaces
INPUT_SOURCE_TAGS="${INPUT_SOURCE_TAGS//$'\n'/ }"

# Replace spaces with commas
INPUT_SOURCE_TAGS="${INPUT_SOURCE_TAGS// /,}"

# Recursively replace double-commas with single commas
while [[ "$INPUT_SOURCE_TAGS" =~ ,, ]]; do
	INPUT_SOURCE_TAGS="${INPUT_SOURCE_TAGS//,,/,}"
done

# Remove leading comma recursively
while [[ "$INPUT_SOURCE_TAGS" =~ ^, ]]; do
	INPUT_SOURCE_TAGS="${INPUT_SOURCE_TAGS#,}"
done

# Create array from comma-separated string
IFS=',' read -ra SOURCE_ARRAY <<<"$INPUT_SOURCE_TAGS"

# Calculate the list of tags to merge
echo "--> Tags to squash:"
SOURCE_TAG_LIST=""
for tag in "${SOURCE_ARRAY[@]}"; do
	SOURCE_TAG_LIST="${SOURCE_TAG_LIST} ${tag}"
	echo "    ${tag}"
done

echo "--> Destination tag:"
echo "    ${INPUT_DESTINATION_TAG}"

function squash_error() {
	echo >&2 ""
	echo >&2 "--> ERROR: Squash and push failed."
	echo >&2 "--> You may have forgotten to log in to your Docker Registry first:"
	echo >&2 "        name: Login to Container Registry"
	echo >&2 "        uses: docker/login-action@v2"
	echo >&2 "        with:"
	echo >&2 "          registry: \${{ env.REGISTRY }}"
	echo >&2 "          username: \${{ env.REGISTRY_USER }}"
	echo >&2 "          password: \${{ secrets.REGISTRY_PASSWORD }}"
	echo >&2 ""
	exit 1
}

# Squash using buildx
function buildx_squash() {
	(
		# Exit subshell on error
		set -e

		# Use Buildx to merge and push in a single command
		echo "--> Squashing and pushing: ${INPUT_DESTINATION_TAG}"
		docker buildx imagetools create -t "${INPUT_DESTINATION_TAG}" ${SOURCE_TAG_LIST}

		echo "--> Verifying: ${INPUT_DESTINATION_TAG}"
		docker buildx imagetools inspect "${INPUT_DESTINATION_TAG}"

		echo "--> Squash complete!"
	)
	if [[ "$?" != "0" ]]; then
		squash_error
	fi
}

# Squash using the manifest command
function manifest_squash() {
	(
		# Exit subshell on error
		set -e

		# Use Docker Manifest to squash first
		echo "--> Squashing input tags"
		docker manifest create "${INPUT_DESTINATION_TAG}" ${SOURCE_TAG_LIST}

		# Push the squashed image
		echo "--> Pushing: ${INPUT_DESTINATION_TAG}"
		docker manifest push "${INPUT_DESTINATION_TAG}"

		echo "--> Verifying: ${INPUT_DESTINATION_TAG}"
		docker manifest inspect "${INPUT_DESTINATION_TAG}"

		echo "--> Squash complete!"
	)
	if [[ "$?" != "0" ]]; then
		squash_error
	fi
}

# Detect squash method, prefer buildx
if docker buildx imagetools >/dev/null 2>&1; then
	echo "--> Docker Buildx detected. Squashing with Docker Buildx."
	buildx_squash
elif docker manifest >/dev/null 2>&1; then
	echo "--> Docker Buildx not available. Falling back to Docker Manifest"
	manifest_squash
elif docker >/dev/null 2>&1; then
	echo >&2 ""
	echo >&2 "--> ERROR: Docker available, but Docker Buildx and Docker Manifest not found"
	echo >&2 "--> Please run the setup-buildx-action Action:"
	echo >&2 "        name: Set up Docker Buildx"
	echo >&2 "        uses: docker/setup-buildx-action@v2"
	echo >&2 ""
	exit 1
else
	echo >&2 ""
	echo >&2 "--> ERROR: Docker is not available on this Runner"
	echo >&2 "--> Please run the setup-buildx-action Action:"
	echo >&2 "        name: Set up Docker Buildx"
	echo >&2 "        uses: docker/setup-buildx-action@v2"
	echo >&2 ""
	exit 1
fi
