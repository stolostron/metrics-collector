import configargparse    # type: ignore


def NewOption() -> configargparse.ArgumentParser:
    p = configargparse.ArgParser(default_config_files=[])

    p.add('--hub-config', help='hub cluster kubeconfig', env_var='KUBECONFIG')
    p.add('--clean', help='clean up the simulators', default=False)

    options = p.parse_args()

    return options
