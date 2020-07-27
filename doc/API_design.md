## ManagedCluster Monitoring API

### Introduction:
In the previous ACM 2.0 release, we have delivered the observability as an internal technical preview feature which does not enable the security metrics. In other words, we use Prometheus remote write feature to write the metrics from the managed cluster to the hub server with plain HTTP.
For the official release, we need to:
* Replace the plain HTTP with HTTPS.
* Provide our own metrics client to replace prometheus remote write because
  * we need to support other clusters besides OCP
  * TLS is not supported by OCP until OCP 4.7 due to the [issue](https://github.com/coreos/prometheus-operator/issues/3118)
  * remove the duplciate metrics pushed from multi prometheus instances

### API Design:
The diagram is loctated in [here](https://swimlanes.io/u/sIBsY2gSF)

The requirement doc is located in [here](https://docs.google.com/document/d/1qawBUo8VcdBXuXzZl8sypIug1nLsUEm_5Yy0qENZ-aU)

EndpointMonitoring CR is namespace scoped and located in each cluster namespace in hub side if monitoring feature is enabled for that managed cluster. Hub operator will generate the default one in the cluster namespace and users can customize it later. One CR includes two sections: one for spec and the other for status.

**EndpointMonitoring** Spec: describe the specification and status for the metrics collector in one managed cluster

name | description | required | default | schema
---- | ----------- | -------- | ------- | ------
enableMetrics | Push metrics or not | yes | true | bool
enableLogs | Push logs or not | no | false | bool
metricsConfigs| Metrics collection configurations | yes | n/a | MetricsConfigs
logConfigs | Log collection configuration | no | n/a | LogConfigs


**MetricsConfigs Spec**: describe the specification for metrics collected  from local prometheus and pushed to hub server

name | description | required | default | schema
---- | ----------- | -------- | ------- | ------
metricsSource | The server configuration to get metrics from | no | n/a | MetricsSource
interval | Interval to collect&push metrics | yes | 1m | string
whitelistConfigMaps | List  of configmap name. For each configmap it contains the whitelist for metrics pushed to hub. It only includes the metrics customized by users. The default metrics will also be pushed even if this value is empty. | no | n/a | []string
scrapeTargets | Additional scrape targets added to local prometheus to scrape additional metrics. The metrics scraped from the new added scrape targets will be included in the whitelist of metrics.(filter the metrics using {job=”SERVICE_MONITOR_NAME”}) | no | n/a | [][ServiceMonitorSpec](https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md#servicemonitorspec)
rules | List for alert rules and recording rules. The metrics defined in the new-added recording rules will be included in the whitelist of metrics. | no | n/a | [][Rule](https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md#rule 


**MetricsSource Spec**: describe the information to get the metrics

name | description | required | default | schema
---- | ----------- | -------- | ------- | ------
serverURL | The server url is to get metrics from | yes | https://prometheus-k8s.openshift-monitoring.svc:9091 | string
tlsConfig | A file containing the CA certificate to use to verify the Prometheus server | no | n/a | *[TLSConfig](https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md#tlsconfig)

**EndpointMonitoring Status**: describe the status for current CR. It's updated by the metrics collector

name | description | required | default | schema
---- | ----------- | -------- | ------- | ------
metricsCollectionStatus | Collect/Push metrics successfully or not | no | true | bool
metricsCollectionError | Error encounted during metrics collect/push | no | n/a | string
logsCollectionStatus | Collect/Push logs successfully or not | no | true | bool
logsCollectionError | Error encounted during logs collect/push | no | n/a | string

### Samples

Here is a sample EndpointMonitoring CR

```
apiVersion: monitoring.open-cluster-management.io/v1alpha1
kind: EndpointMonitoring
metadata:
  name: sample-endpointmonitoring
spec:
  enableMetrics: true
  metricsConfigs:
    interval: 1m
    metricsSource:
      serverUrl: https://*****
      tlsConfig:
        ca: local-ca-secret
        cert: local-cert-secret
    whitelistConfigMaps:
    - sample-whitelist
    scrapeTargets:
    - endpoints:
      - interval: 30s
        port: web
        scheme: https
      namespaceSelector: {}
      selector:
        matchLabels:
          alertmanager: test
    rules:
    - alert: HighRequestLatency
      expr: job:request_latency_seconds:mean5m{job="myjob"} > 0.5
      for: 10m
    - record: job:http_inprogress_requests:sum
      expr: sum by (job) (http_inprogress_requests)
```

Here is the sample ConfigMap for whitelist, used by the EndpointMonitoring CR

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: sample-whitelist
data:
  whitelist.yaml: |
    matches:
      - {__name__="up"}
      - {__name__=~"container_*"}
```
