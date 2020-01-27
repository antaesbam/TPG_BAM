# Data Providers provisionning

## Install requirements

To install required Ansible roles:
```
ansible-playbook playbooks/install_requirements.yml
```

## Settings

In `env/` for an specific env (i.e. `dev`/`prod`), `group_vars/tpgbam_servers.yml` file contains the config vars:

The data providers list:
```
data_providers:
  - provider_1
  - provider_2
```

The target configuration for the data:
```
target_url: target.example.tld:9243
target_user: myuser
target_password: myuserpassword
target_cloudid: TPG_BAM:mycloudid==
```

The monitoring host:
```
monitoring_url: monitoring.example.tld:9243
monitoring_user: myuser
monitoring_password: myuserpassword
monitoring_cloudid: TPG_BAM:mycloudid==
```

## Deploy

For `dev` env:
```
ansible-playbook -i env/dev playbooks/deploy.yml
```

For `prod` env:
```
ansible-playbook -i env/prod playbooks/deploy.yml
```
