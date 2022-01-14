# metrics-collector
Metrics-collector implements a client to "scrape" or collect data from OpenShift Promethus
and performs a push fedration to a Thanos instance hosted by Red Hat Advanced Cluster Management for Kubernetes 
hub cluster. This project is based on the [Telemeter project](https://github.com/openshift/telemeter).

## Setting up development environment locally 
 
 **Prerequisites**: You must have Red Hat Advanced Cluster Management monitoring installed on a hub cluster. For more information, see the [`multicluster-monitoring-operator` repo](https://github.com/stolostron/multicluster-monitoring-operator).

Complete the following steps to set up your environment:
 
1. Clone the `metrics-collector` repo by running the following command:
   
   ```
   git clone https://github.com/stolostron/metrics-collector.git
   ```
   
2. Log in to your hub cluster. Run the following command:

   ```
   oc login  -u kubeadmin -p yours --server=https://yours.red-chesterfield.com:6443
   ```
     
   **Note:** Currently, only OpenShift Container Platform supports integration of the `metrics-collector`.
   
3. Verify that Prometheus is running on your hub cluster by accessing it from your managed cluster. Run the following command:
     
     ```
     oc port-forward svc/prometheus-operated 7778:9090 --insecure-skip-tls-verify=true -n openshift-monitoring
     ```
     
4. Verify that Thanos is running in your hub cluster to federate the metrics. Run the following command:
     
   ```
   oc port-forward svc/monitoring-observatorium-observatorium-api 7777:8080 -n open-cluster-management-monitoring
   ```

5. Run the following command to launch the  <!--not sure what the command function is-->

   ```
   make all
   ```
   
6. Start the telemeter client by running the following command:

   ```
   ./telemeter-client --id 8bbfc970-d82d-4630-bd36-e503a7a554af --from http://localhost:7778 --to-upload http://localhost:7777/api/metrics/v1/write    --log-level=debug --label="cluster=dev"
   ```
   
   View a description of the variables in the command:
   
   - `--id`: Represents remote OpenShift cluster ID. Run the following command to get a list of the OpenShift IDs: `oc get cm cluster-monitoring-config -n openshift-monitoring`.
   - `--from`: Represents the Prometheus endpoint
   - `--to-upload`: Represents the Thanos endpoint
   - `--label`: Helps you filter and query in Grafana. Be sure to provide a unique string value.


### Verification
Once your client starts to run, you can check if metrics are flowing to Thanos. Use any REST client tool to verify. You can access the following URL to verify, without credentials: `http://localhost:7777/api/metrics/v1/api/v1/query?query=up{cluster="dev"}`

You can also check the Red Hat Advanced CLuster Managent Grafana dashboard with the following URL: `https://multicloud-console.apps.yours.red-chesterfield.com/grafana/dashboards`


### Deploy a Docker image on a remote cluster

**Note:** This section is work in progress

If you want to deploy a `metric-collector` pod on a remote cluster, complete the following steps: 

1. Log in to your OpenShift cluster by running the following command:

   ```
   ocp login  need the rest of the command
   ```
   
2. Create a namespace or project in `open-cluster-management-monitoring` repo.
   
3. Apply the `telemeter-client-serving-certs-ca-bundle.yaml` file by running the following command:
   ```
   oc apply -f ./temp/telemeter-client-serving-certs-ca-bundle.yaml
   ```
  
4. Run the following command for the Auth Token to flow to Prometheus:
   
   ```
   oc apply -f ./temp/rolebinding.yaml
   ``` 
  
5. Run the following command to apply the client secret:

  ```
  oc apply -f ./temp/client_secret.yaml
  ```
  
6. Replace the image tag from the `./temp/deployment.yaml` file.
7. Apply the `./temp/deployment.yaml` with your new changes by running the following command:
   
   ```
   oc apply -f ./temp/deployment.yaml
   ```

Follow the same verification steps that were mentioned previously. See the [Verification](#verification) section.


## Telemeter

Telemeter implements a Prometheus federation push client and server
to allow isolated Prometheus instances that cannot be scraped from a
central Prometheus, to instead perform push federation to a central
location.

1. The local client scrapes `/federate` on a given Prometheus instance.
2. The local client performs cleanup and anonymization and then pushes the metrics to the server.
3. The server authenticates the client, validates and verifies that the metrics are "safe", and then ensures they have a label uniquely identifying the source client.
4. The server holds the metrics in a local disk store until scraped.
5. A centralized Prometheus scrapes each server instance and aggregates all the metrics.

Since that push is across security boundaries, the server must perform
authentication, authorization, and data integrity checks, and be
resilient to denial of service.

Each client is uniquely identified by a cluster ID and all metrics
federated are labeled with that ID.

Since Telemeter is dependent on Prometheus federation, each server
instance must ensure that all metrics for a given cluster ID are routed
to the same instance, otherwise Prometheus marks the metrics
series as stale. To do this, the server instances form a cluster using
a secure gossip transport and build a consistent hash ring so that
pushed client metrics are routed internally to the same server.

For resiliency, each server instance stores the received metrics on disk
hashed by cluster ID until they are accessed by a federation endpoint.

**Note**: Telemeter is an alpha version and may change significantly.

Get started
-----------

To see this integration in action, run the following command:

```
make all
./test/integration.sh http://localhost:9005
```

The command launches a two instance `telemeter-server` cluster and a single
`telemeter-client` to talk to that server, along with a Prometheus
instance running on http://localhost:9005 that shows the federated metrics.
The client scrapes metrics from the local Prometheus, then sends the metrics
to the telemeter server cluster, which is then be scraped by that instance.

To run this test against another Prometheus server, change the URL (and if necessary,
specify the bearer token necessary to talk to that server as the second argument).

To build binaries, run the following command:

```
make all
```

To execute the unit test suite, run the following command:

```
make check
```

To launch a self contained integration test, run the following command:

```
make test-integration
```

Adding new metrics to send via telemeter
-----------

For more information about the process to send metrics see the Google doc, [Sending metrics via telemetry](https://docs.google.com/document/d/1a6n5iBGM2QaIQRg9Lw4-Npj6QY9--Hpx3XYut-BrUSY/edit?usp=sharing).
