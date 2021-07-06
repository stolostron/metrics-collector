import configargparse    # type: ignore


def NewOption() -> configargparse.ArgumentParser:
    p = configargparse.ArgParser(
        default_config_files=[],
        description=
        """The metrics-collector-simulator.py watches the ManagedCluster CR. On Added event, it will create a simulator to the ManagedCluster's namespace.
    The `metrics-collector-simulator.py --clean True` can clean up the simulator which sits inside ManagedCluster's namespace.

    The ManagedCluster is filter by a prefix string.

    Note: the `metrics-collector-simulator.py` will use the KUBECONFIG env variable as the kubeconfig to your hub cluster. Also, you can override it by input the `--hub-config` parameter.
    """)

    p.add('--hub-config', help='hub cluster kubeconfig', env_var='KUBECONFIG')
    p.add('--prefix', help='managed cluster to process', default="spoke")
    p.add('--clean', help='clean up the simulators', default=False)

    options = p.parse_args()

    return options
