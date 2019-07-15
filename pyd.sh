#!/bin/bash

modulePath="$PWD/__pyd_modules__"

check_docker() {

    echo "this will check for docker"

}

pyd_echo() {

    command printf %s\\n "$*" 2>/dev/null

}

get_docker_command() {

    # remove special characters
    removeSlash="${PWD:1}"
    imageName="pyd-${removeSlash//[\/_]/-}"
    pythonVersion="$(get_python_version)"
    moduleVolumeString=""
    if [ -d $modulePath ] || [ "$1" = "req" ]; then
        moduleVolumeString="-v $modulePath:/pip_modules"
    fi

    pyd_echo "docker run -i --rm --name $imageName -e PYTHONUSERBASE=/pip_modules -e PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/pip_modules/bin -v $PWD:/usr/src/app $moduleVolumeString -w /usr/src/app python:$pythonVersion"

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
        dockerCmd="$(get_docker_command req) $(install_requirements $2)"
        ;;

    --help)
        print_help
        ;;

    --clear)
        rm -rf $modulePath
        ;;

    *)
        if [ ! -z $1 ] ; then
            dockerCmd="$(get_docker_command) python -u $@"
        else
            print_help
        fi
        ;;

    esac

    if [ ! -z "$dockerCmd" ]; then
        eval "$dockerCmd"
    fi
fi
