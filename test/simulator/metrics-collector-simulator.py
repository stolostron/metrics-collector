import option
import datetime as dt
import uuid
import logging
from kubernetes import config, dynamic, watch    # type: ignore
from kubernetes.client import api_client    # type: ignore

from kubernetes.client.exceptions import ApiException, ApiValueError    # type: ignore

ADDON_NAMESPACE = "open-cluster-management-addon-observability"


def reuseAddonCertConfigMap(hubClient: dynamic.DynamicClient,
                            clusterName: str) -> ApiException:

    configMapAPI = hubClient.resources.get(api_version="v1", kind="ConfigMap")

    try:
        caBundle = configMapAPI.get(
            name="metrics-collector-serving-certs-ca-bundle",
            namespace=ADDON_NAMESPACE)

        configMapAPI.create(body=resetObject(caBundle, clusterName))
        return None
    except ApiException as err:
        if err.status != 409:
            return err


def reuseAddonManagedCertSecrets(hubClient: dynamic.DynamicClient,
                                 clusterName: str) -> ApiException:
    secretAPI = hubClient.resources.get(api_version="v1", kind="Secret")

    try:
        managedCert = secretAPI.get(name="observability-managed-cluster-certs",
                                    namespace=ADDON_NAMESPACE)
        obj = resetObject(managedCert, clusterName)
        obj.metadata.ownerReferences = None

        secretAPI.create(body=obj)

        return None
    except ApiException as err:
        if err.status != 409:
            return err


def reuseAddonSingerCertSecrets(hubClient: dynamic.DynamicClient,
                                clusterName: str) -> ApiException:
    secretAPI = hubClient.resources.get(api_version="v1", kind="Secret")

    try:
        signerCert = secretAPI.get(
            name=
            "observability-controller-open-cluster-management.io-observability-signer-client-cert",
            namespace=ADDON_NAMESPACE)

        secretAPI.create(body=resetObject(signerCert, clusterName))
        return None
    except ApiException as err:
        if err.status != 409:
            return err


def reuseAddonCertServiceAccount(hubClient: dynamic.DynamicClient,
                                 clusterName: str) -> ApiException:
    serviceAccountAPI = hubClient.resources.get(api_version="v1",
                                                kind="ServiceAccount")
    try:
        endpointSA = serviceAccountAPI.get(
            name="endpoint-observability-operator-sa",
            namespace=ADDON_NAMESPACE)
        obj = resetObject(endpointSA, clusterName)
        obj.metadata.ownerReferences = None

        serviceAccountAPI.create(body=obj)

        return None
    except ApiException as err:
        if err.status != 409:
            return err


def reuseAddonDeployment(hubClient: dynamic.DynamicClient,
                         clusterName: str) -> ApiException:

    deploymentAPI = hubClient.resources.get(api_version="apps/v1",
                                            kind="Deployment")

    METRICS_IMAGE = "quay.io/haoqing/metrics-data:latest"

    try:
        deploy = deploymentAPI.get(name="metrics-collector-deployment",
                                   namespace=ADDON_NAMESPACE)

        deploy.metadata.ownerReferences = None
        deploy.metadata.namespace = clusterName
        deploy.spec.template.spec.containers[0].command.append(
            '--label="cluster={}"'.format(clusterName))
        deploy.spec.template.spec.containers[0].command.append(
            '--label="clusterID={}"'.format(uuid.uuid4()))
        deploy.spec.template.spec.containers[0].command.append(
            '--simulated-timeseries-file=/metrics-volume/timeseries.txt')

        deploy.spec.template.spec.initContainers = [{
            "command": ["sh", "-c", "cp /tmp/timeseries.txt /metrics-volume"],
            "image":
            "{}".format(METRICS_IMAGE),
            "imagePullPolicy":
            "Always",
            "name":
            "init-metrics",
            "volumeMounts": [{
                "mountPath": "/metrics-volume",
                "name": "metrics-volume"
            }]
        }]

        deploy.spec.template.spec.volumes.append({
            "emptyDir": {},
            "name": "metrics-volume"
        })

        deploy.spec.template.spec.containers[0].volumeMounts.append({
            "mountPath":
            "/metrics-volume",
            "name":
            "metrics-volume"
        })

        deploy.spec.template.spec.containers[0].resources = None
        deploymentAPI.create(body=resetObject(deploy, clusterName))
    except ApiException as err:
        if err.status != 409:
            return err


def createClusterRoleBinding(hubClient: dynamic.DynamicClient,
                             clusterName: str) -> ApiException:
    if len(clusterName) == 0:
        return ApiException(reason="cluster name is empty")
    clusterRoleBindingAPI = hubClient.resources.get(
        api_version="rbac.authorization.k8s.io/v1", kind="ClusterRoleBinding")

    metricsCollectorView = {
        "kind":
        "ClusterRoleBinding",
        "apiVersion":
        "rbac.authorization.k8s.io/v1",
        "metadata": {
            "name": "{}-clusters-metrics-collector-view".format(clusterName),
            "annotations": {
                "owner": "multicluster-operator",
            },
        },
        "subjects": [{
            "kind": "ServiceAccount",
            "name": "endpoint-observability-operator-sa",
            "namespace": clusterName
        }],
        "roleRef": {
            "apiGroup": "rbac.authorization.k8s.io",
            "kind": "ClusterRole",
            "name": "cluster-monitoring-view",
        },
    }

    try:
        clusterRoleBindingAPI.create(body=metricsCollectorView)
    except ApiException as err:
        if err.status != 409:
            return err


def resetObject(obj: dynamic.ResourceInstance,
                ns: str) -> dynamic.ResourceInstance:
    obj.metadata.namespace = ns
    obj.metadata.resourceVersion = None
    obj.metadata.uid = None
    obj.metadata.creationTimestamp = None
    obj.metadata.managedFields = None

    return obj


def runSimulaterAt(hubClient: dynamic.DynamicClient,
                   clusterName: str) -> ApiException:
    if reuseAddonCertConfigMap(hubClient, clusterName) != None:
        return ApiException(reason="failed to create cert configmap")

    if reuseAddonSingerCertSecrets(hubClient, clusterName) != None:
        return ApiException(reason="failed to create cert secrets")

    if reuseAddonManagedCertSecrets(hubClient, clusterName) != None:
        return ApiException(reason="failed to create cert secrets")

    if reuseAddonCertServiceAccount(hubClient, clusterName) != None:
        return ApiException(reason="failed to create cert serviceAccount")

    if reuseAddonDeployment(hubClient, clusterName) != None:
        return ApiException(reason="failed to create simulator deployment")

    if createClusterRoleBinding(hubClient, clusterName) != None:
        return ApiException(reason="failed to create clusterrolebinding")

    return None


def removeSimulator(hubClient: dynamic.DynamicClient,
                    clusterName: str) -> ApiException:
    try:
        clusterRoleBindingAPI = hubClient.resources.get(
            api_version="rbac.authorization.k8s.io/v1",
            kind="ClusterRoleBinding")

        clusterRoleBindingAPI.delete(
            name="{}-clusters-metrics-collector-view".format(clusterName))
    except ApiException as err:
        logging.error("failed to delete ClusterRoleBinding for %s, err: %s:%s",
                      clusterName, err.status, err.reason)

    try:
        deploymentAPI = hubClient.resources.get(api_version="apps/v1",
                                                kind="Deployment")

        deploymentAPI.delete(name="metrics-collector-deployment",
                             namespace=clusterName)
    except ApiException as err:
        logging.error("failed to delete deployment for %s, err: %s:%s",
                      clusterName, err.status, err.reason)

    try:
        serviceAccountAPI = hubClient.resources.get(api_version="v1",
                                                    kind="ServiceAccount")

        serviceAccountAPI.delete(name="endpoint-observability-operator-sa",
                                 namespace=clusterName)
    except ApiException as err:
        logging.error("failed to delete serviceaccount for %s, err: %s:%s",
                      clusterName, err.status, err.reason)

    secretAPI = hubClient.resources.get(api_version="v1", kind="Secret")
    try:
        secretAPI.delete(
            name=
            "observability-controller-open-cluster-management.io-observability-signer-client-cert",
            namespace=clusterName)
    except ApiException as err:
        logging.error(
            "failed to delete signer client cert secret for %s, err: %s:%s",
            clusterName, err.status, err.reason)

    try:
        secretAPI.delete(name="observability-managed-cluster-certs",
                         namespace=clusterName)
    except ApiException as err:
        logging.error(
            "failed to delete managed cluster cert secret for %s, err: %s:%s",
            clusterName, err.status, err.reason)

    try:
        configMapAPI = hubClient.resources.get(api_version="v1",
                                               kind="ConfigMap")
        configMapAPI.delete(name="metrics-collector-serving-certs-ca-bundle",
                            namespace=clusterName)
    except ApiException as err:
        logging.error("failed to delete cert ca bundle for %s, err: %s:%s",
                      clusterName, err.status, err.reason)

    return None


def removeSimulators(hubClient: dynamic.DynamicClient,
                     clusterNamePrefix: str) -> ApiException:
    groupVersion = "cluster.open-cluster-management.io/v1"
    kind = "ManagedCluster"
    managedClusterAPI = hubClient.resources.get(api_version=groupVersion,
                                                kind=kind)

    clusterList = managedClusterAPI.get()

    for item in clusterList.items:
        clusterName = item.metadata.name
        if clusterName.startswith(clusterNamePrefix):
            logging.info("deleting resources on cluster %s", clusterName)
            err = removeSimulator(hubClient, clusterName)
            if err != None:
                logging.error("failed to remove simulatorm err: %s", err)

    return None


def watchManagedClusters(hubClient: dynamic.DynamicClient,
                         clusterNamePrefix: str) -> None:
    groupVersion = "cluster.open-cluster-management.io/v1"

    # it seems the kind string is case sensitive
    kind = "ManagedCluster"

    api = hubClient.resources.get(api_version=groupVersion, kind=kind)

    logging.info("start watch: %s/%s", groupVersion, kind)

    set = {}

    for e in api.watch():
        clusterName = e['object'].metadata.name
        logging.info("event: %s on cluster %s", e['type'], clusterName)
        if e['type'] == "ADDED":
            if clusterName in set:
                continue
            if len(clusterNamePrefix) != 0 and not clusterName.startswith(
                    clusterNamePrefix):
                continue

            set[clusterName] = True
            err = runSimulaterAt(hubClient, clusterName)
            if err != None:
                logging.error(
                    "failed to create simulator for cluster: %s, err: %s",
                    clusterName, err)

        if e['type'] == "DELETED":
            if len(clusterNamePrefix) != 0 and not clusterName.startswith(
                    clusterNamePrefix):
                continue
            err = removeSimulator(hubClient, clusterName)
            if err != None:
                logging.error(
                    "failed to remove simulator for cluster: %s, err: %s",
                    clusterName, err)


def isObservabilityAddonEnabled(hubClient: dynamic.DynamicClient) -> bool:
    api = hubClient.resources.get(api_version="v1", kind="Pod")
    pod_list = api.get(namespace="open-cluster-management-addon-observability")

    return len(pod_list.items) != 0


if __name__ == '__main__':
    opts = option.NewOption()
    format = "%(asctime)s: %(message)s"
    logging.basicConfig(filename=opts.log_file,
                        filemode='w',
                        format=format,
                        level=logging.INFO,
                        datefmt="%H:%M:%S")

    hubClient = dynamic.DynamicClient(
        api_client.ApiClient(configuration=config.load_kube_config(
            config_file=opts.hub_config)))

    if opts.clean:
        err = removeSimulators(hubClient, opts.prefix)
        if err != None:
            logging.error("failed to clean up the simulators, err %s", err)
            exit(1)
        exit(0)

    if not isObservabilityAddonEnabled(hubClient):
        logging.error(
            "Observability Addon is not up, won't be get Obs cert template")
        exit(1)

    # watch the managedcluster CR and create observability simlutor in the managed
    # clusters namespace
    watchManagedClusters(hubClient, opts.prefix)
