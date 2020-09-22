#!/usr/bin/env bash
set -e

for OPT in "$@"
do
	echo ${OPT}
	if [ "${OPT}" == "--latest" ]; then IS_LATEST="True"; fi
	if [ "${OPT}" == "--push" ]; then WILL_PUSH_IMAGE="True"; fi
done

if [ -d moddable ]; then
	pushd moddable && git pull && popd
else
	git clone --depth=1 https://github.com/Moddable-OpenSource/moddable
fi
pushd moddable
HASH=`git rev-parse --short HEAD`
popd
docker build -t tiryoh/moddable-esp32:moddable-${HASH} .
docker tag tiryoh/moddable-esp32:moddable-${HASH} ghcr.io/tiryoh/moddable-esp32:moddable-${HASH}

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
	if [ "${IS_LATEST}" == "True" ]; then
		docker push tiryoh/moddable-esp32:latest
	fi
fi
