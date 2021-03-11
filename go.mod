module github.com/open-cluster-management/metrics-collector

go 1.13

require (
	github.com/OneOfOne/xxhash v1.2.6 // indirect
	github.com/alecthomas/units v0.0.0-20190924025748-f65c72e2690d // indirect
	github.com/bradfitz/gomemcache v0.0.0-20190913173617-a41fca850d0b
	github.com/cenkalti/backoff v0.0.0-20181003080854-62661b46c409
	github.com/coreos/go-oidc v2.2.1+incompatible
	github.com/go-chi/chi v4.1.2+incompatible
	github.com/go-kit/kit v0.9.0
	github.com/go-logfmt/logfmt v0.5.0 // indirect
	github.com/gogo/protobuf v1.3.1
	github.com/golang/protobuf v1.4.2
	github.com/golang/snappy v0.0.1
	github.com/grpc-ecosystem/grpc-gateway v1.12.1 // indirect
	github.com/inconshreveable/mousetrap v1.0.0 // indirect
	github.com/oklog/run v1.0.0
	github.com/pkg/errors v0.8.1
	github.com/pquerna/cachecontrol v0.0.0-20180517163645-1555304b9b35 // indirect
	github.com/prometheus/client_golang v1.4.0
	github.com/prometheus/client_model v0.2.0
	github.com/prometheus/common v0.9.1
	github.com/prometheus/prometheus v0.0.0-20190424153033-d3245f150225
	github.com/satori/go.uuid v1.2.1-0.20181028125025-b2ce2384e17b
	github.com/spaolacci/murmur3 v1.1.0 // indirect
	github.com/spf13/cobra v0.0.3
	golang.org/x/crypto v0.0.0-20191112222119-e1110fd1c708 // indirect
	golang.org/x/net v0.0.0-20200520004742-59133d7f0dd7 // indirect
	golang.org/x/oauth2 v0.0.0-20190604053449-0f29369cfe45
	golang.org/x/time v0.0.0-20191024005414-555d28b269f0
	google.golang.org/appengine v1.6.5 // indirect
	google.golang.org/genproto v0.0.0-20191115194625-c23dd37a84c9 // indirect
	google.golang.org/grpc v1.25.1 // indirect
	gopkg.in/square/go-jose.v2 v2.0.0-20180411045311-89060dee6a84
)

replace (
	golang.org/x/text => golang.org/x/text v0.3.5
	k8s.io/client-go => k8s.io/client-go v0.0.0-20191016111102-bec269661e48
)
