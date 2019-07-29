#!/bin/bash

modulePath="$PWD/__pyd_modules__"
rsaCertPath="$PWD/.pyd_id_rsa"
awsCredPath="$PWD/.pyd_aws_cred"
awsDefaultRegion="us-west-2"
isReqCommand=0

pyd_echo() {

    command printf %s\\n "$*" 2>/dev/null

}

build_docker_command() {

    # remove special characters
    removeSlash="${PWD:1}"
    imageName="pyd-${removeSlash//[\/_]/-}"
    pythonVersion="$(get_python_version)"

    moduleVolumeString=""
    if [ -d $modulePath ] || [ $isReqCommand = 1 ]; then
        moduleVolumeString="-v $modulePath:/pip_modules"
    fi

    rsaCertString=""
    rsaCertBash=""
    if [ -f $rsaCertPath ]; then
        rsaCertString="-v $rsaCertPath:/tmp/id_rsa"
        if [ $isReqCommand = 1 ]; then
            # only setup known_hosts for github.com
            rsaCertBash="echo \"    IdentityFile ~/.ssh/id_rsa\" >> /etc/ssh/ssh_config && mkdir /root/.ssh && cp /tmp/id_rsa /root/.ssh/id_rsa && chmod 600 /root/.ssh/id_rsa && ssh-keyscan -H github.com >> ~/.ssh/known_hosts &&"
        fi
    fi

    awsCredString=""
    if [ -f $awsCredPath ]; then
        #this is getting kind of specific
        awsCredString="-v $awsCredPath:/root/.aws/credentials -e AWS_DEFAULT_REGION=$awsDefaultRegion"
    fi

    pyd_echo "docker run -i --rm --name $imageName -e PYTHONUSERBASE=/pip_modules -v $PWD:/usr/src/app $moduleVolumeString $rsaCertString $awsCredString -w /usr/src/app python:$pythonVersion /bin/bash -c '$rsaCertBash $@'"

}

check_if_sourced() {

    script_name=$(basename ${0#-}) #- needed if sourced no path
    this_script=$(basename ${BASH_SOURCE})
    if [[ ${script_name} == ${this_script} ]]; then
        false
    else
        true
    fi

}

get_python_version() {

    pythonVersion="$PWD/.python-version"
    if [ -f $pythonVersion ]; then
        pythonVersion=$(<$pythonVersion)
    else
        pythonVersion="3"
    fi

    pyd_echo "$pythonVersion"
}

print_help() {

    pyd_echo 'Python Docker Executor'
    pyd_echo 'Uses .python-version to determine Python version, default image python:3'
    pyd_echo 'Uses .pyd_id_rsa to authenticate with private github'
    pyd_echo 'Uses .pyd_aws_cred to use boto3 library'
    pyd_echo
    pyd_echo 'Usage:'
    pyd_echo '  pyd <args...>                             Passes through to dockerized python'
    pyd_echo '  pyd --help                                Show this message'
    pyd_echo '  pyd --req <file_name>                     Install modules from requirements.txt or specific file'
    pyd_echo '  pyd --clear                               Clear local modules'
    pyd_echo

}

install_requirements() {
    requirementsFile="requirements.txt"
    if [ ! -z $1 ]; then
        requirementsFile="$1"
    fi

    pyd_echo "pip install --user -r $requirementsFile"
}

if check_if_sourced; then
    # setup alias from .profile include
    alias pyd="${BASH_SOURCE}"
else
    case "$1" in
    --req)
        isReqCommand=1
        dockerCmd="$(build_docker_command $(install_requirements $2)) "
        pyd_echo "$dockerCmd"
        ;;

    --help)
        print_help
        ;;

    --clear)
        rm -rf $modulePath
        ;;

    *)
        if [ ! -z $1 ]; then
            dockerCmd="$(build_docker_command python -u $@)"
        else
            print_help
        fi
        ;;

    esac

    if [ ! -z "$dockerCmd" ]; then
        eval "$dockerCmd"
    fi
fi
