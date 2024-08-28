# Docker container for ENM DPS server extensions and orchestration scripts

## Description

This is an interim, *data-only* container. Its sole purppose is to expose, via volume mounts, the contents of the `ERICneo4jserverextension_CXP9032727` RPM and custom orchestration scripts required to perform lifecycle management (install, upgrade, ...) of Neo4J within ENM.

The orchestration scripts in turn are executed via GraphDB orchestrator, typically through helm commands, for example: `helm install`.

It is envisaged that this container will be superseded by a cloud-native DPS delivery.

## Usage

**Note:** The below steps are just here in the interim and should be automated through ADP Bob 2.0 + Jenkins.

### Build

```bash
./build.sh
``` 

### Publish 

```bash
docker login armdocker.rnd.ericsson.se
docker push armdocker.rnd.ericsson.se/aia_snapshots/ericneo4jserverextension:<TAG>
```

### Run
For a quick look:

```bash
docker run --rm -it armdocker.rnd.ericsson.se/aia_snapshots/ericneo4jserverextension bash
```

## Mount points

These should be mounted by users:

* `/opt/ericsson`
* `/opt/ericsson/lifecycle-scripts/`
* `/ericsson`


## Link to RPM

Currently the relevant RPM may be downloaded from CI Fwk / Nexus. Here is an example URL:

https://arm101-eiffel004.lmera.ericsson.se:8443/nexus/content/repositories/releases/com/ericsson/oss/itpf/datalayer/dps/3pp/ERICneo4jserverextension_CXP9032727/1.39.6/ERICneo4jserverextension_CXP9032727-1.39.6.rpm
