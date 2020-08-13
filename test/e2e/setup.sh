#!/bin/bash
# Copyright (c) 2020 Red Hat, Inc.

echo "=====running kind exploration=====" 
echo $1

IMAGE_NAME=$1
echo "IMAGE: " $IMAGE_NAME

DEFAULT_NS="open-cluster-management"
HUB_KUBECONFIG=$HOME/.kube/kind-config-hub
WORKDIR=`pwd`

sed_command='sed -i-e -e'
if [[ "$(uname)" == "Darwin" ]]; then
	sed_command='sed -i '-e' -e'
fi

deploy() {
    setup_kubectl_and_oc_command
	create_kind_hub
	deploy_prometheus_operator
	deploy_metrics_collector $IMAGE_NAME
	#install_monitoring_operator
	delete_kind_hub	
	#delete_command_binaries	
	check_status $IMAGE_NAME
}

setup_kubectl_and_oc_command() {
	echo "=====Setup kubectl and oc=====" 
	# kubectl required for kind
	# oc client required for installing operators
	# if and when we are feeling ambitious... also download the installer and install ocp, and run our component integration test here	
	# uname -a and grep mac or something...
    # Darwin MacBook-Pro 19.5.0 Darwin Kernel Version 19.5.0: Tue May 26 20:41:44 PDT 2020; root:xnu-6153.121.2~2/RELEASE_X86_64 x86_64
	echo "Install kubectl and oc from openshift mirror (https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.4.14/openshift-client-mac-4.4.14.tar.gz)" 
	mv README.md README.md.tmp 
    if [[ "$(uname)" == "Darwin" ]]; then # then we are on a Mac 
		curl -LO https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.4.14/openshift-client-mac-4.4.14.tar.gz 
		tar xzvf openshift-client-mac-4.4.14.tar.gz  # xzf to quiet logs
		rm openshift-client-mac-4.4.14.tar.gz
    elif [[ "$(uname)" == "Linux" ]]; then # we are in travis, building in rhel 
		curl -LO https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.4.14/openshift-client-linux-4.4.14.tar.gz
		tar xzvf openshift-client-linux-4.4.14.tar.gz  # xzf to quiet logs
		rm openshift-client-linux-4.4.14.tar.gz
    fi
	# this package has a binary, so:

	echo "Current directory"
	echo $(pwd)
	mv README.md.tmp README.md 
	chmod +x ./kubectl
	if [[ ! -f /usr/local/bin/kubectl ]]; then
		sudo cp ./kubectl /usr/local/bin/kubectl
	fi
	chmod +x ./oc
	if [[ ! -f /usr/local/bin/oc ]]; then
		sudo cp ./oc /usr/local/bin/oc
	fi
	# kubectl and oc are now installed in current dir 
	echo -n "kubectl version" && kubectl version
 	# echo -n "oc version" && oc version 
}
 
create_kind_hub() { 
    WORKDIR=`pwd`
    if [[ ! -f /usr/local/bin/kind ]]; then
    
    	echo "=====Create kind cluster=====" 
    	echo "Install kind from (https://kind.sigs.k8s.io/)."
    
    	# uname returns your operating system name
    	# uname -- Print operating system name
    	# -L location, lowercase -o specify output name, uppercase -O Write  output to a local file named like the remote file we get  
    	curl -Lo ./kind "https://kind.sigs.k8s.io/dl/v0.7.0/kind-$(uname)-amd64"
    	chmod +x ./kind
    	sudo cp ./kind /usr/local/bin/kind
    fi
    echo "Delete hub if it exists"
    kind delete cluster --name hub || true
    
    echo "Start hub cluster" 
    rm -rf $HOME/.kube/kind-config-hub
    kind create cluster --kubeconfig $HOME/.kube/kind-config-hub --name hub --config ${WORKDIR}/test/e2e/kind/kind-hub.config.yaml
    # kubectl cluster-info --context kind-hub --kubeconfig $(pwd)/.kube/kind-config-hub # confirm connection 
    export KUBECONFIG=$HOME/.kube/kind-config-hub
} 


deploy_prometheus_operator() {
	echo "=====Setting up prometheus in kind cluster=====" 

    WORKDIR=`pwd`
    echo "Install prometheus operator." 
    echo "Current directory"
    echo $(pwd)
    cd ${WORKDIR}/..
    git clone https://github.com/coreos/kube-prometheus.git
    echo "Replace namespace with openshift-monitoring"
    $sed_command "s~namespace: monitoring~namespace: openshift-monitoring~g" kube-prometheus/manifests/*.yaml
    $sed_command "s~namespace: monitoring~namespace: openshift-monitoring~g" kube-prometheus/manifests/setup/*.yaml
    $sed_command "s~name: monitoring~name: openshift-monitoring~g" kube-prometheus/manifests/setup/*.yaml
    $sed_command "s~replicas:.*$~replicas: 1~g" kube-prometheus/manifests/prometheus-prometheus.yaml
    echo "Remove alertmanager and grafana to free up resource"
    rm -rf kube-prometheus/manifests/alertmanager-*.yaml
    rm -rf kube-prometheus/manifests/grafana-*.yaml
    if [[ ! -z "$1" ]]; then
        update_prometheus_remote_write $1
    else
        update_prometheus_remote_write
    fi
    
    echo "HUB_KUBECONFIG" ${HUB_KUBECONFIG}
    echo "KUBECONFIG" ${KUBECONFIG}
    
    echo "Creating prometheus manifests setup" && kubectl create -f kube-prometheus/manifests/setup
    until kubectl get servicemonitors --all-namespaces; do date; sleep 1; echo ""; done
    echo "Creating prometheus manifests" && kubectl create -f kube-prometheus/manifests/
    rm -rf kube-prometheus
    echo "Installed prometheus operator." 
    sleep 60
    echo -n "available services: " && kubectl get svc --all-namespaces
}

deploy_metrics_collector() {
	echo "=====Deploying metrics-collector====="
	echo -n "Create namespace open-cluster-management-monitoring: " && kubectl create namespace open-cluster-management-monitoring
	echo -n "Switch to namespace: " && kubectl config set-context --current --namespace open-cluster-management-monitoring

	echo "Current directory"
	echo $(pwd)
	# git clone https://github.com/open-cluster-management/metrics-collector.git

	cd metrics-collector
    echo -n "Creating pull secret: " && kubectl create secret docker-registry multiclusterhub-operator-pull-secret --docker-server=quay.io --docker-username=$DOCKER_USER --docker-password=$DOCKER_PASS 
	
	# apply yamls 
	echo "Apply hub yamls" 
	echo -n "Apply telemeter-client-serving-certs-ca-bundle: " && kubectl apply -f ./temp/telemeter-client-serving-certs-ca-bundle.yaml
	echo -n "Apply rolebinding: " && kubectl apply -f ./temp/rolebinding.yaml
	echo -n "Apply client secret: " && kubectl apply -f ./temp/client_secret.yaml
	$sed_command "s~{{ METRICS_COLLECTOR_IMAGE }}~$1~g" ./temp/deployment_e2e.yaml
    $sed_command "s~cluster=func_e2e_test_travis~cluster=func_e2e_test_travis-$1~g" ./temp/deployment_e2e.yaml
	echo "Display deployment yaml" 
	cat ./temp/deployment_e2e.yaml
	echo -n "Apply metrics collector deployment: " && kubectl apply -f ./temp/deployment_e2e.yaml

    echo -n "available pods: " && kubectl get pods --all-namespaces
	echo "Waiting 3 minutes for the pod to set up and send data... " && sleep 180
	POD=$(kubectl get pod -l k8s-app=metrics-collector -n open-cluster-management-monitoring -o jsonpath="{.items[0].metadata.name}")
	echo "Monitoring pod logs" 
	kubectl logs $POD | grep Thanos
	echo "available pods: " && kubectl get pods --all-namespaces

}
 
delete_kind_hub() { 
	echo "====Delete kind cluster=====" 
    kind delete cluster --name hub
 	#rm .kube/kind-config-hub 
}

delete_command_binaries(){
	cd ${WORKDIR}/..
	echo "Current directory"
	echo $(pwd)
	rm ./kind
	rm ./kubectl
	rm ./oc 
}

check_status(){
	STATUS=$(curl -f "http://observatorium-api-open-cluster-management-monitoring.apps.real-bass.dev05.red-chesterfield.com/api/metrics/v1/api/v1/query?query=up" --silent | grep -i func_e2e_test_travis-$1 > /dev/null && echo "SUCCESS" || echo "FAILURE")
	echo "Status: " $STATUS
	if [ $STATUS = "FAILURE" ]
	then
	echo "Error: Did not write data to Thanos"
	exit 1
	fi
}

deploy 
