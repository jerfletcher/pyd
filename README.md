# Python Docker Executor
Run Python scripts in a docker container with local modules, and specific version.

## Install
- Clone this repo
- Add line to .profile:
```
source <path to cloned repo>\pyd.sh
```

## Usage
```
Python Docker Executor
Uses .python-version to determine Python version, default image python:3
Uses .pyd_id_rsa to authenticate with private github
Uses .pyd_aws_cred to use boto3 library

Usage:
    pyd <args...>                             Passes through to dockerized python
    pyd --help                                Show this message
    pyd --req <file_name>                     Install modules from requirements.txt or specific file
    pyd --clear                               Clear local modules
```