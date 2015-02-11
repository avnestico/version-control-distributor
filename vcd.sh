#!/bin/bash
#
# Version Control Distributor
#
# Configures a repo hosted on either Github or Bitbicket to be hosted on both.

#######################################
# Check if user requested help ('-h' or '--help' in args)
# Arguments:
#   $@: any string
# Returns:
#   0: if '-h'/'--help' not in args
#   non-zero: if in args
#######################################
function help_wanted {
    echo "$@" | grep -qE '(^| )(\-h|\-\-help)( |$)'
    return $?
}

function print_help {
    echo "
vcd.sh: Version Control Distributor

If you:
  * have a local repo that pushes to one of Github or Bitbucket
  * have an empty repo with the same name hosted at the other site, and
  * want to push code to both repos:

    vcd.sh ~/path/to/repository/

If the empty repo has a different name:

    vcd.sh ~/path/to/repository/ <empty_repo_name>

To view this help message:

    vcd.sh -h"
    return 0
}

#######################################
# Craft repo url and add to git config using git remote add
# Arguments:
#   protocol: https or git
#   host: host of existing repo (bitbucket or github)
#   user: username
#   repo: name of repo
# Returns:
#   0: remote added successfully
#   1: invalid parameter
#   2: remote not successfully added
#######################################
function git_remote_add {
    protocol="$1"
    host="$2"
    user="$3"
    repo="$4"

    # Begin crafting url by checking whether protocol is https or git
    if [ "${protocol}" == "https" ]
    then
        url="https://"
        # Bitbucket https urls are of the form https://${user}@bitbucket.com/${user}/${repo}
        if [ "${host}" == "bitbucket" ]
        then
            url="${url}${user}@"
        fi
        sep="/"
    elif [ "${protocol}" == "git" ]
    then
        url="git@"
        sep=":"
    else
        echo "Invalid protocol: ${protocol}"
        exit 1
    fi

    if [ "${host}" == "bitbucket" ]
    then
        tld=".org"
    elif [ "${host}" == "github" ]
    then
        tld=".com"
    else
        echo "Invalid host: ${host}"
        exit 1
    fi

    # Double check that the url ends in ".git"
    if [[ "${repo}" != *.git ]]
    then
        repo="${repo}.git"
    fi

    # example urls:    git@github.com:avnestico/version-control-distributor.git
    # https://avnestico@bitbucket.org/avnestico/version-control-distributor.git
    url="${url}${host}${tld}${sep}${user}/${repo}"
    echo "${url}"
    # git remote add ${host} ${url} || ( echo "git remote add failed" && exit 2 )
    # exit 0
}

# If args are used improperly, or help is wanted, print help and exit
if [ "$#" -eq 0 ] || [ "$#" -gt 2 ] || help_wanted "$@"
then
    print_help
    exit $?
fi

git_remote_add https bitbucket avnestico version-control-distributor
git_remote_add https github avnestico version-control-distributor
git_remote_add ssh bitbucket avnestico version-control-distributor
git_remote_add ssh github avnestico version-control-distributor

# check if https or ssh
# if https, ask if user wants to switch to ssh
# git remote set-url --add origin git@bitbucket.org:avnestico/version-control-distributor.git
# git remote add bitbucket git@bitbucket.org:avnestico/version-control-distributor.git
# git remote add github git@github.com:avnestico/version-control-distributor.git
# git push --all

# https://avnestico@bitbucket.org/avnestico/version-control-distributor.git
# https://github.com/avnestico/version-control-distributor.git
exit 0
