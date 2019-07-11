#!/bin/bash

modulePath="$PWD/__pdy_modules__"

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
    pyd_echo "docker run -it --rm --name $imageName -e PYTHONUSERBASE=/pip_modules -e PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/pip_modules/bin -v $PWD:/usr/src/app -v $modulePath:/pip_modules -w /usr/src/app python:$pythonVersion"

}

check_if_sourced() {

    script_name=$( basename ${0#-} ) #- needed if sourced no path
    this_script=$( basename ${BASH_SOURCE} )
    if [[ ${script_name} = ${this_script} ]] ; then
        false
    else
        true
    fi

}
get_python_version() {

    pythonVersion="$PWD/.python-version"
    if [ -f $pythonVersion ] ; then 
        pythonVersion=$(<$pythonVersion)
    else
        pythonVersion="3"
    fi

    pyd_echo "$pythonVersion"
}

print_help(){
    
    pyd_echo "Python Docker executor"
    pyd_echo "Uses .python-version to determine Python version, default image python:3"
    pyd_echo
    pyd_echo 'Usage:'
    pyd_echo '  pyd <args...>                             Passes through to dockerized python'
    pyd_echo '  pyd --help                                Show this message'
    pyd_echo '  pyd --req <file_name>                     Install modules from requirements.txt or specific file'
    pyd_echo '  pyd --clear                               Clear local modules'
    pyd_echo

}

if check_if_sourced ; then
    # setup alias from .profile include
    alias pyd="${BASH_SOURCE}"
else
    case "$1" in
        --req)
            dockerCmd="$(get_docker_command) pip install --user -r requirements.txt"
            ;;

        --help)
            print_help
            ;;

        --clear)
            rm -rf $modulePath
            ;;

        *)
            dockerCmd="$(get_docker_command) python $@"
            ;;

    esac

    if $dockerCmd ; then
        eval "$dockerCmd"  
    fi
fi 



