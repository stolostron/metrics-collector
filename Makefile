
include ./cicd-scripts/Configfile

-include $(shell curl -H 'Authorization: token ${GITHUB_TOKEN}' -H 'Accept: application/vnd.github.v4.raw' -L https://api.github.com/repos/open-cluster-management/build-harness-extensions/contents/templates/Makefile.build-harness-bootstrap -o .build-harness-bootstrap; echo .build-harness-bootstrap)

PKGS=$(shell go list ./... | grep -v '/vendor/|/test/(?!e2e)')
METRICS_JSON=./_output/metrics.json
BIN_DIR?=$(shell pwd)/_output/bin
GOJSONTOYAML_BIN=$(BIN_DIR)/gojsontoyaml

export PATH := $(BIN_DIR):$(PATH)

copyright-check:
	./cicd-scripts/copyright-check.sh $(TRAVIS_BRANCH)

test-unit:
	@echo "TODO: Run unit-tests"
	go test -race -short $(PKGS) -count=1 -coverprofile cover.out

e2e-tests:
	@echo "TODO: Run e2e-tests"

build:
	go build ./cmd/metrics-collector

vendor:
	go mod vendor
	go mod tidy
	go mod verify

$(BIN_DIR):
	mkdir -p $@

$(GOJSONTOYAML_BIN): $(BIN_DIR)
	GOBIN=$(BIN_DIR) go get github.com/brancz/gojsontoyaml

$(METRICS_JSON): $(GOJSONTOYAML_BIN)
	matches=`curl -L https://raw.githubusercontent.com/open-cluster-management/multicluster-observability-operator/main/manifests/base/config/metrics_allowlist.yaml | \
	    $(GOJSONTOYAML_BIN) --yamltojson | jq -r '.data."metrics_list.yaml"' | $(GOJSONTOYAML_BIN) --yamltojson | jq -r '.matches' | jq '"{" + .[] + "}"'`; \
	names=`curl -L https://raw.githubusercontent.com/open-cluster-management/multicluster-observability-operator/main/manifests/base/config/metrics_allowlist.yaml | \
	    $(GOJSONTOYAML_BIN) --yamltojson | jq -r '.data."metrics_list.yaml"' | $(GOJSONTOYAML_BIN) --yamltojson | jq -r '.names' | jq '"{__name__=\"" + .[] + "\"}"'`; \
	echo $$matches $$names | jq -s . > $@

test/timeseries.txt: $(METRICS_JSON)
	oc port-forward -n openshift-monitoring prometheus-k8s-0 9090 > /dev/null & \
	sleep 50 ; \
	query="curl --fail --silent -G http://localhost:9090/federate"; \
	for rule in $$(cat $(METRICS_JSON) | jq -r '.[]'); do \
	    query="$$query $$(printf -- "--data-urlencode match[]=%s" $$rule)"; \
	done; \
	echo '# This file was generated using `make $@`.' > $@ ; \
	$$query >> $@ ; \
	jobs -p | xargs -r kill
