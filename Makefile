
include ./cicd-scripts/Configfile

-include $(shell curl -H 'Authorization: token ${GITHUB_TOKEN}' -H 'Accept: application/vnd.github.v4.raw' -L https://api.github.com/repos/stolostron/build-harness-extensions/contents/templates/Makefile.build-harness-bootstrap -o .build-harness-bootstrap; echo .build-harness-bootstrap)

PKGS=$(shell go list ./... | grep -v '/vendor/|/test/(?!e2e)')

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
