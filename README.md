# metrics-collector
Metrics-collector implements a client to scrape openshift Promethus
and performs and push fedration to a Thanos instance hosted by ACM 
hub cluster. This project is based of Telemeter project (https://github.com/openshift/telemeter).

Setting up development environment to build on laptop : 
  You will need  ACM Monitoring installed on a hub cluster. Please 
  see instructions here : https://github.com/open-cluster-management/multicluster-monitoring-operator

  Steps to build : 
  1) Git clone this repository.
  2) Login to hub cluster . Example : oc login  -u kubeadmin -p yours --server=https://yours.red-chesterfield.com:6443
     Presently only supporting on Openshift Cluster . *KS is not supported at this point. 
  3) Expose access to Prometheus running in Hub Cluster from which the metrics needs to be scraped.
     Note : In the product this Promethus will be running on a managed cluster.
     Execute this on a Terminal and let it listen. Example  : `oc port-forward svc/prometheus-operated 7778:9090 --insecure-skip-tls-verify=true -n openshift-monitoring`
  4) Expose access to Thanos running in Hub Cluster to which the metrics needs to be federated. 
     Execute this on a Terminal and let it listen. Example : `oc port-forward svc/monitoring-observatorium-observatorium-api 7777:8080 -n open-cluster-management-monitoring`
  5) Execute : `make all`
  6) Run the telemeter client Example : `./telemeter-client --id 8bbfc970-d82d-4630-bd36-e503a7a554af --from http://localhost:7778 --to-upload http://localhost:7777/api/metrics/v1/write    --log-level=debug --label="cluster=dev"`
     --id => represents remote openshift cluster ID (oc get cm cluster-monitoring-config -n openshift-monitoring), for dev this can be any string 
     -- from => represents the Prometheus endpoint
     -- to-upload => represents the Thanos endpoint
     --label  => Helps you filter and query in Grafana , give a unique string

 Verification :
 Once your client runs you can check the if metrics is flowing to Thanos . Use any REST client tool to make a GET API (Example :Postman) `http://localhost:7777/api/metrics/v1/api/v1/query?query=up{cluster="dev"}` . No Credentials are required.

 You can also check the ACM Grafana dashboard  from Url : `https://multicloud-console.apps.yours.red-chesterfield.com/grafana/dashboards`

 Steps to deploy a Docker image on a remote Cluster : 
  If you wish to deploy a metric-collector pod on a remote cluster , follow the following steps . Note : This section is work in progress :
  1)  ocp login to Remote Openshift Cluster
  2)  create namespace/project `open-cluster-management-monitoring`
  3)  Update the Server Certificate in ./temp/telemeter-client-serving-certs-ca-bundle.yaml from your remote cluster
       `oc get cm telemeter-client-serving-certs-ca-bundle -n openshift-monitoring -o yaml`
  4) `oc apply -f ./temp/telemeter-client-serving-certs-ca-bundle.yaml`
  5) `oc apply -f ./temp/rolebinding.yaml` Gets you the Auth Token to get to Prometheus
  6) `oc apply -f ./temp/client_secret.yaml` This is needed for now  , though we are not using in the code(MTLS) , the config points to this .
  7) Replace the image tag from `./temp/deployment.yaml`
  8) `oc apply -f ./temp/deployment.yaml`

  You can follow the same verification steps (see above) by logging into Hub cluster's Grafana dashboard. 

=========
Telemeter
=========

Telemeter implements a Prometheus federation push client and server
to allow isolated Prometheus instances that cannot be scraped from a
central Prometheus to instead perform push federation to a central
location.

1. The local client scrapes `/federate` on a given Prometheus instance.
2. The local client performs cleanup and anonymization and then pushes the metrics to the server.
3. The server authenticates the client, validates and verifies that the metrics are "safe", and then ensures they have a label uniquely identifying the source client.
4. The server holds the metrics in a local disk store until scraped.
5. A centralized Prometheus scrapes each server instance and aggregates all the metrics.

Since that push is across security boundaries, the server must perform
authentication, authorization, and data integrity checks as well as being
resilient to denial of service.

Each client is uniquely identified by a cluster ID and all metrics
federated are labelled with that ID.

Since Telemeter is dependent on Prometheus federation, each server
instance must ensure that all metrics for a given cluster ID are routed
to the same instance, otherwise Prometheus will mark those metrics
series as stale. To do this, the server instances form a cluster using
a secure gossip transport and build a consistent hash ring so that
pushed client metrics are routed internally to the same server.

For resiliency, each server instance stores the received metrics on disk
hashed by cluster ID until they are accessed by a federation endpoint.

note: Telemeter is alpha and may change significantly

Get started
-----------

To see this in action, run

```
make all
./test/integration.sh http://localhost:9005
```

The command launches a two instance `telemeter-server` cluster and a single
`telemeter-client` to talk to that server, along with a Prometheus
instance running on http://localhost:9005 that shows the federated metrics.
The client will scrape metrics from the local prometheus, then send those
to the telemeter server cluster, which will then be scraped by that instance.

To run this test against another Prometheus server, change the URL (and if necessary,
specify the bearer token necessary to talk to that server as the second argument).

To build binaries, run

```
make all
```

To execute the unit test suite, run

```
make check
```

To launch a self contained integration test, run:

```
make test-integration
```

Adding new metrics to send via telemeter
-----------

Docs on the process on why and how to send these metrics are available [here](https://docs.google.com/document/d/1a6n5iBGM2QaIQRg9Lw4-Npj6QY9--Hpx3XYut-BrUSY/edit?usp=sharing).
