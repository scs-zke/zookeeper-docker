# Docker image packaging for Apache Zookeeper

&#9888; This version of ___zookeeper-docker___ is forked from <https://github.com/31z4/zookeeper-docker> &#9888;

This packaging for Apache Zookeeper is forked from the [Docker "Official Image"](https://github.com/docker-library/official-images#what-are-official-images) for [`zookeeper`](https://hub.docker.com/_/zookeeper/) with the following changes:

* build the stable branch only
* use the Alpine based <https://hub.docker.com/_/eclipse-temurin> image variant as base image
* upgrades the base image with the latest packages from the stable branch on build
* must be run as user 1000:1000
