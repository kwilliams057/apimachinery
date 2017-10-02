#!/bin/bash

set -x

GOPATH=$(go env GOPATH)
PACKAGE_NAME=github.com/k8sdb/apimachinery
REPO_ROOT="$GOPATH/src/$PACKAGE_NAME"
DOCKER_REPO_ROOT="/go/src/$PACKAGE_NAME"

pushd $REPO_ROOT

## Generate ugorji stuff
docker run --rm -ti -u $(id -u):$(id -g) \
    -v "$REPO_ROOT":"$DOCKER_REPO_ROOT" \
    -w "$DOCKER_REPO_ROOT/apis/kubedb/v1alpha1" \
    appscode/gengo:canary codecgen -o types.generated.go types.go

docker run --rm -ti -u $(id -u):$(id -g) \
    -v "$REPO_ROOT":"$DOCKER_REPO_ROOT" \
    -w "$DOCKER_REPO_ROOT/apis/kubedb/v1alpha1" \
    appscode/gengo:canary codecgen -o postgres_types.generated.go postgres_types.go

docker run --rm -ti -u $(id -u):$(id -g) \
    -v "$REPO_ROOT":"$DOCKER_REPO_ROOT" \
    -w "$DOCKER_REPO_ROOT/apis/kubedb/v1alpha1" \
    appscode/gengo:canary codecgen -o elasticsearch_types.generated.go elasticsearch_types.go

docker run --rm -ti -u $(id -u):$(id -g) \
    -v "$REPO_ROOT":"$DOCKER_REPO_ROOT" \
    -w "$DOCKER_REPO_ROOT/apis/kubedb/v1alpha1" \
    appscode/gengo:canary codecgen -o dormant_database_types.generated.go dormant_database_types.go

docker run --rm -ti -u $(id -u):$(id -g) \
    -v "$REPO_ROOT":"$DOCKER_REPO_ROOT" \
    -w "$DOCKER_REPO_ROOT/apis/kubedb/v1alpha1" \
    appscode/gengo:canary codecgen -o snapshot_types.generated.go snapshot_types.go

# Generate defaults
docker run --rm -ti -u $(id -u):$(id -g) \
    -v "$REPO_ROOT":"$DOCKER_REPO_ROOT" \
    -w "$DOCKER_REPO_ROOT" \
    appscode/gengo:canary defaulter-gen \
    --v 1 --logtostderr \
    --go-header-file "hack/gengo/boilerplate.go.txt" \
    --input-dirs "$PACKAGE_NAME/apis/kubedb" \
    --input-dirs "$PACKAGE_NAME/apis/kubedb/v1alpha1" \
    --extra-peer-dirs "$PACKAGE_NAME/apis/kubedb" \
    --extra-peer-dirs "$PACKAGE_NAME/apis/kubedb/v1alpha1" \
    --output-file-base "zz_generated.defaults"

# Generate deep copies
docker run --rm -ti -u $(id -u):$(id -g) \
    -v "$REPO_ROOT":"$DOCKER_REPO_ROOT" \
    -w "$DOCKER_REPO_ROOT" \
    appscode/gengo:canary deepcopy-gen \
    --v 1 --logtostderr \
    --go-header-file "hack/gengo/boilerplate.go.txt" \
    --input-dirs "$PACKAGE_NAME/apis/kubedb" \
    --input-dirs "$PACKAGE_NAME/apis/kubedb/v1alpha1" \
    --output-file-base zz_generated.deepcopy

# Generate conversions
docker run --rm -ti -u $(id -u):$(id -g) \
    -v "$REPO_ROOT":"$DOCKER_REPO_ROOT" \
    -w "$DOCKER_REPO_ROOT" \
    appscode/gengo:canary conversion-gen \
    --v 1 --logtostderr \
    --go-header-file "hack/gengo/boilerplate.go.txt" \
    --input-dirs "$PACKAGE_NAME/apis/kubedb" \
    --input-dirs "$PACKAGE_NAME/apis/kubedb/v1alpha1" \
    --output-file-base zz_generated.conversion

# Generate the internal clientset (client/clientset_generated/internalclientset)
docker run --rm -ti -u $(id -u):$(id -g) \
    -v "$REPO_ROOT":"$DOCKER_REPO_ROOT" \
    -w "$DOCKER_REPO_ROOT" \
    appscode/gengo:canary client-gen \
   --go-header-file "hack/gengo/boilerplate.go.txt" \
   --input-base "$PACKAGE_NAME/apis/" \
   --input "kubedb/" \
   --clientset-path "$PACKAGE_NAME/client/" \
   --clientset-name internalclientset

# Generate the versioned clientset (client/clientset_generated/clientset)
docker run --rm -ti -u $(id -u):$(id -g) \
    -v "$REPO_ROOT":"$DOCKER_REPO_ROOT" \
    -w "$DOCKER_REPO_ROOT" \
    appscode/gengo:canary client-gen \
   --go-header-file "hack/gengo/boilerplate.go.txt" \
   --input-base "$PACKAGE_NAME/apis/" \
   --input "kubedb/v1alpha1" \
   --clientset-path "$PACKAGE_NAME/" \
   --clientset-name "client"

# generate lister
docker run --rm -ti -u $(id -u):$(id -g) \
    -v "$REPO_ROOT":"$DOCKER_REPO_ROOT" \
    -w "$DOCKER_REPO_ROOT" \
    appscode/gengo:canary lister-gen \
   --go-header-file "hack/gengo/boilerplate.go.txt" \
   --input-dirs="$PACKAGE_NAME/apis/kubedb" \
   --input-dirs="$PACKAGE_NAME/apis/kubedb/v1alpha1" \
   --output-package "$PACKAGE_NAME/listers"

# generate informer
docker run --rm -ti -u $(id -u):$(id -g) \
    -v "$REPO_ROOT":"$DOCKER_REPO_ROOT" \
    -w "$DOCKER_REPO_ROOT" \
    appscode/gengo:canary informer-gen \
   --go-header-file "hack/gengo/boilerplate.go.txt" \
   --input-dirs "$PACKAGE_NAME/apis/kubedb/v1alpha1" \
   --versioned-clientset-package "$PACKAGE_NAME/client" \
   --listers-package "$PACKAGE_NAME/listers" \
   --output-package "$PACKAGE_NAME/informers"

#go-to-protobuf \
#  --proto-import="${KUBE_ROOT}/vendor" \
#  --proto-import="${KUBE_ROOT}/third_party/protobuf"

popd
