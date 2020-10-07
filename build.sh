#!/usr/bin/env bash
set -e

for OPT in "$@"
do
	echo "option(s): "${OPT}
	if [ "${OPT}" == "--latest" ]; then IS_LATEST="True"; fi
	if [ "${OPT}" == "--push" ]; then WILL_PUSH_IMAGE="True"; fi
	if [ "${OPT}" == "--cache" ]; then WILL_USE_CACHE="True"; fi
	if [ "${OPT}" == "--tag" ]; then WILL_BUILD_TAG="True"; fi
	if [ "${OPT}" == "--head" ]; then WILL_BUILD_HEAD="True"; fi
done

if [ -z "${WILL_BUILD_HEAD}" ] && [ -z "${WILL_BUILD_TAG}" ]; then  # if not defined
	WILL_BUILD_HEAD="True"
fi

## fetch GitHub repository info

if [ "${WILL_BUILD_HEAD}" == "True" ]; then
	HASH=`curl -SsL https://api.github.com/repos/Moddable-OpenSource/moddable/git/refs/heads/public | jq -r .object.sha | sed -E 's/(.{7}).*/\1/g'`
	DOCKERFILE="Dockerfile.head"
elif [ "${WILL_BUILD_TAG}" == "True" ]; then
	LATEST_TAG=`curl -SsL https://api.github.com/repos/Moddable-OpenSource/moddable/tags | jq -r '.[0] | .name + " " + .commit.sha'`
	HASH=`echo ${LATEST_TAG} | sed -E 's/.* (.{7}).*/\1/g'`
	LATEST_TAG=`echo ${LATEST_TAG} | sed -E 's/(.*) .*/\1/g'`
	DOCKERFILE="Dockerfile.tag"
	BUILD_OPTION=" --build-arg GIT_TAG=${LATEST_TAG}"
fi

## build Docker image

if [ ! "${WILL_USE_CACHE}" == "True" ]; then
	BUILD_OPTION+=" --no-cache"
fi
docker build -t tiryoh/moddable-esp32:moddable-${HASH} -f ${DOCKERFILE} ${BUILD_OPTION} .
docker tag tiryoh/moddable-esp32:moddable-${HASH} ghcr.io/tiryoh/moddable-esp32:moddable-${HASH}
if [ ! -z "${LATEST_TAG}" ] ; then  # if published with git tag
	docker tag tiryoh/moddable-esp32:moddable-${HASH} tiryoh/moddable-esp32:${LATEST_TAG}
	docker tag tiryoh/moddable-esp32:moddable-${HASH} ghcr.io/tiryoh/moddable-esp32:${LATEST_TAG}
fi

if [ -z "${IS_LATEST}" ] && [ -z "${WILL_PUSH_IMAGE}" ]; then  # if not defined
	read -p "Is this image '*:latest'?(y/N): " yn
	case "$yn" in
		[yY]*)
			IS_LATEST="True"
		;;
		*)
			IS_LATEST="False"
		;;
	esac
	read -p "Push to hub.docker.com and ghcr.io?(y/N): " yn
	case "$yn" in
		[yY]*)
			WILL_PUSH_IMAGE="True"
		;;
		*)
			WILL_PUSH_IMAGE="False"
		;;
	esac
fi

if [ -z "${IS_LATEST}" ]; then  # if latest not defined
	IS_LATEST="False"
fi
if [ "${IS_LATEST}" == "True" ]; then
	docker tag tiryoh/moddable-esp32:moddable-${HASH} tiryoh/moddable-esp32:latest
fi

if [ "${WILL_PUSH_IMAGE}" == "True" ]; then
	docker push tiryoh/moddable-esp32:moddable-${HASH}
	docker push ghcr.io/tiryoh/moddable-esp32:moddable-${HASH}
	if [ ! -z "${LATEST_TAG}" ] ; then  # if published with git tag
		docker push tiryoh/moddable-esp32:${LATEST_TAG}
		docker push ghcr.io/tiryoh/moddable-esp32:${LATEST_TAG}
	fi
	if [ "${IS_LATEST}" == "True" ]; then
		docker push tiryoh/moddable-esp32:latest
	fi
fi

## remove ghcr.io tags

docker rmi ghcr.io/tiryoh/moddable-esp32:moddable-${HASH}
if [ ! -z "${LATEST_TAG}" ] ; then  # if published with git tag
	docker rmi ghcr.io/tiryoh/moddable-esp32:${LATEST_TAG}
fi
