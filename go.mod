module github.com/open-cluster-management/metrics-collector

go 1.13

require (
	github.com/OneOfOne/xxhash v1.2.6 // indirect
	github.com/StackExchange/wmi v0.0.0-20180725035823-b12b22c5341f // indirect
	github.com/VividCortex/ewma v1.1.1 // indirect
	github.com/alecthomas/units v0.0.0-20190924025748-f65c72e2690d // indirect
	github.com/biogo/store v0.0.0-20160505134755-913427a1d5e8 // indirect
	github.com/bradfitz/gomemcache v0.0.0-20190913173617-a41fca850d0b
	github.com/cenk/backoff v2.0.0+incompatible // indirect
	github.com/cenkalti/backoff v2.2.1+incompatible
	github.com/certifi/gocertifi v0.0.0-20180905225744-ee1a9a0726d2 // indirect
	github.com/cockroachdb/cmux v0.0.0-20170110192607-30d10be49292 // indirect
	github.com/cockroachdb/cockroach v0.0.0-20170608034007-84bc9597164f // indirect
	github.com/coreos/go-oidc v2.2.1+incompatible
	github.com/elastic/gosigar v0.9.0 // indirect
	github.com/elazarl/go-bindata-assetfs v1.0.0 // indirect
	github.com/facebookgo/clock v0.0.0-20150410010913-600d898af40a // indirect
	github.com/getsentry/raven-go v0.1.2 // indirect
	github.com/go-chi/chi v4.1.2+incompatible
	github.com/go-kit/kit v0.10.0
	github.com/go-logfmt/logfmt v0.5.0 // indirect
	github.com/go-ole/go-ole v1.2.4 // indirect
	github.com/gogo/protobuf v1.3.1
	github.com/golang/protobuf v1.4.2
	github.com/golang/snappy v0.0.1
	github.com/grpc-ecosystem/grpc-opentracing v0.0.0-20180507213350-8e809c8a8645 // indirect
	github.com/hashicorp/consul v1.4.4 // indirect
	github.com/inconshreveable/mousetrap v1.0.0 // indirect
	github.com/knz/strtime v0.0.0-20181018220328-af2256ee352c // indirect
	github.com/montanaflynn/stats v0.0.0-20180911141734-db72e6cae808 // indirect
	github.com/oklog/run v1.1.0
	github.com/open-cluster-management/multicluster-monitoring-operator v0.0.0-20210216210616-0f181640bb3a
	github.com/peterbourgon/g2s v0.0.0-20170223122336-d4e7ad98afea // indirect
	github.com/petermattis/goid v0.0.0-20170504144140-0ded85884ba5 // indirect
	github.com/pkg/errors v0.9.1
	github.com/pquerna/cachecontrol v0.0.0-20180517163645-1555304b9b35 // indirect
	github.com/prometheus/client_golang v1.7.1
	github.com/prometheus/client_model v0.2.0
	github.com/prometheus/common v0.14.0
	github.com/prometheus/prometheus v2.3.2+incompatible
	github.com/rlmcpherson/s3gof3r v0.5.0 // indirect
	github.com/rubyist/circuitbreaker v2.2.1+incompatible // indirect
	github.com/sasha-s/go-deadlock v0.0.0-20161201235124-341000892f3d // indirect
	github.com/satori/go.uuid v1.2.1-0.20181028125025-b2ce2384e17b
	github.com/spaolacci/murmur3 v1.1.0 // indirect
	github.com/spf13/cobra v1.0.0
	golang.org/x/oauth2 v0.0.0-20200902213428-5d25da1a8d43
	golang.org/x/time v0.0.0-20200630173020-3af7569d3a1e
	gopkg.in/square/go-jose.v2 v2.3.1
	k8s.io/apimachinery v0.19.2
	k8s.io/client-go v12.0.0+incompatible
	sigs.k8s.io/controller-runtime v0.6.0
)

replace (
	github.com/jetstack/cert-manager => github.com/open-cluster-management/cert-manager v0.0.0-20200821135248-2fd523b053f5
	k8s.io/client-go => k8s.io/client-go v0.19.0
	github.com/prometheus/common => github.com/prometheus/common v0.9.1
	github.com/prometheus/prometheus => github.com/prometheus/prometheus v0.0.0-20190424153033-d3245f150225
)
