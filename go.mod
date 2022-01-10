module github.com/stolostron/metrics-collector

go 1.17

require (
	github.com/cenkalti/backoff v2.2.1+incompatible
	github.com/go-kit/kit v0.10.0
	github.com/gogo/protobuf v1.3.1
	github.com/golang/protobuf v1.4.2
	github.com/golang/snappy v0.0.1
	github.com/oklog/run v1.1.0
	github.com/open-cluster-management/multicluster-monitoring-operator v0.0.0-20210216210616-0f181640bb3a
	github.com/pkg/errors v0.9.1
	github.com/prometheus/client_golang v1.7.1
	github.com/prometheus/client_model v0.2.0
	github.com/prometheus/common v0.14.0
	github.com/prometheus/prometheus v2.3.2+incompatible
	github.com/spf13/cobra v1.0.0
	k8s.io/apimachinery v0.19.2
	k8s.io/client-go v12.0.0+incompatible
	sigs.k8s.io/controller-runtime v0.6.0
)

require (
	github.com/alecthomas/units v0.0.0-20190924025748-f65c72e2690d // indirect
	github.com/beorn7/perks v1.0.1 // indirect
	github.com/cespare/xxhash v1.1.0 // indirect
	github.com/cespare/xxhash/v2 v2.1.1 // indirect
	github.com/davecgh/go-spew v1.1.1 // indirect
	github.com/evanphx/json-patch v4.9.0+incompatible // indirect
	github.com/go-logfmt/logfmt v0.5.0 // indirect
	github.com/go-logr/logr v0.2.1 // indirect
	github.com/google/gofuzz v1.2.0 // indirect
	github.com/googleapis/gnostic v0.5.1 // indirect
	github.com/grpc-ecosystem/grpc-gateway v1.14.3 // indirect
	github.com/imdario/mergo v0.3.11 // indirect
	github.com/inconshreveable/mousetrap v1.0.0 // indirect
	github.com/json-iterator/go v1.1.10 // indirect
	github.com/matttproud/golang_protobuf_extensions v1.0.1 // indirect
	github.com/modern-go/concurrent v0.0.0-20180306012644-bacd9c7ef1dd // indirect
	github.com/modern-go/reflect2 v1.0.1 // indirect
	github.com/oklog/ulid v1.3.1 // indirect
	github.com/opentracing/opentracing-go v1.1.0 // indirect
	github.com/prometheus/procfs v0.2.0 // indirect
	github.com/prometheus/tsdb v0.7.1 // indirect
	github.com/spf13/pflag v1.0.5 // indirect
	golang.org/x/crypto v0.0.0-20200820211705-5c72a883971a // indirect
	golang.org/x/net v0.0.0-20200927032502-5d4f70055728 // indirect
	golang.org/x/oauth2 v0.0.0-20200902213428-5d25da1a8d43 // indirect
	golang.org/x/sync v0.0.0-20200625203802-6e8e738ad208 // indirect
	golang.org/x/sys v0.0.0-20200926100807-9d91bd62050c // indirect
	golang.org/x/text v0.3.3 // indirect
	golang.org/x/time v0.0.0-20200630173020-3af7569d3a1e // indirect
	google.golang.org/appengine v1.6.6 // indirect
	google.golang.org/genproto v0.0.0-20200825200019-8632dd797987 // indirect
	google.golang.org/grpc v1.31.0 // indirect
	google.golang.org/protobuf v1.25.0 // indirect
	gopkg.in/inf.v0 v0.9.1 // indirect
	gopkg.in/yaml.v2 v2.3.0 // indirect
	gopkg.in/yaml.v3 v3.0.0-20200615113413-eeeca48fe776 // indirect
	k8s.io/api v0.19.2 // indirect
	k8s.io/klog/v2 v2.3.0 // indirect
	k8s.io/kube-openapi v0.0.0-20200805222855-6aeccd4b50c6 // indirect
	k8s.io/utils v0.0.0-20200912215256-4140de9c8800 // indirect
	sigs.k8s.io/structured-merge-diff/v4 v4.0.1 // indirect
	sigs.k8s.io/yaml v1.2.0 // indirect
)

replace (
	github.com/jetstack/cert-manager => github.com/stolostron/cert-manager v0.0.0-20200821135248-2fd523b053f5
	github.com/prometheus/common => github.com/prometheus/common v0.9.1
	github.com/prometheus/prometheus => github.com/prometheus/prometheus v0.0.0-20190424153033-d3245f150225
	golang.org/x/text => golang.org/x/text v0.3.5
	k8s.io/client-go => k8s.io/client-go v0.19.0
)
