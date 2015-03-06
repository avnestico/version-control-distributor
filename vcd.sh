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

  * have a local repo that pushes to one of Github or Bitbucket;
  * have an empty repo with the same name hosted at the other site; and
  * want to push code to both repos,

simply run:

    vcd.sh path/to/repository/

For example, to use this script on itself, run:

    vcd.sh .

If the name of the empty repo is different from the name of the established repo, run:

    vcd.sh path/to/repository/ <empty_repo_name>

To view this help message:

    vcd.sh -h"
    return 0
}

function get_fetch_url() {
    git remote -v | grep fetch | sed -r 's/^\w+\s+(.*)\s\(fetch\)$/\1/'
}

function craft_url() {
    protocol="${1}"
    host="${2}"
    user="${3}"
    repo="${4}"

    # Begin crafting url by checking whether protocol is https or git
    if [ "${protocol}" == "https" ]
    then
        url="https://"
        # Bitbucket https urls are of the form https://${user}@bitbucket.com/${user}/${repo}.git
        if [ "${host}" == "bitbucket" ]
        then
            url="${url}${user}@"
        fi
        sep="/"
    elif [ "${protocol}" == "ssh" ]
    then
        url="git@"
        sep=":"
    else
        echo "Invalid protocol: ${protocol}"
        return 1
    fi

    if [ "${host}" == "bitbucket" ]
    then
        tld=".org"
    elif [ "${host}" == "github" ]
    then
        tld=".com"
    else
        echo "Invalid host: ${host}"
        return 1
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
    url="$(craft_url ${1} ${2} ${3} ${4})"
    url_status=$?
    if [[ "${url_status}" -ne 0 ]]
    then
        return "${url_status}"
    fi

    # Attempt to perform git remote add
    git remote add ${2} ${url} || ( echo "git remote add failed" && return 2 )
    return 0
}

function git_remote_seturl() {
    url="$(craft_url ${1} ${2} ${3} ${4})"
    url_status=$?
    if [[ "${url_status}" -ne 0 ]]
    then
        return "${url_status}"
    fi

    # Attempt to perform git remote set-url
    git remote set-url --add origin "${url}" || ( echo "git remote set-url failed" && return 2 )
    return 0
}

function main() {
    # If no args, or more than 2 args, or help is wanted, print help and exit
    if [ "$#" -eq 0 ] || [ "$#" -gt 2 ] || help_wanted "$@"
    then
        print_help
        exit $?
    fi

    # Confirm that the given path is actually a git directory
    repo_dir="${1}"
    cd "${PWD}/${repo_dir}"
    dotgitdir="$(git rev-parse --git-dir 2> /dev/null)"
    if [[ -z "${dotgitdir}" ]]
    then
        echo "Error: Not a git directory"
        print_help
        exit 2
    fi
    cd "${dotgitdir}"

    # Back up old config, just in case.
    cp config config.bak

    # Confirm the directory has one remote repo (that it pushes to and pulls from)
    push_repos="$(git remote -v | grep push | wc -l)"
    fetch_repos="$(git remote -v | grep fetch | wc -l)"

    if [[ "${push_repos}" -ne 1 ]] || [[ "${fetch_repos}" -ne 1 ]]
    then
        echo "Error: Directory must have one push and one fetch repo. Use 'git remote' or edit /.git/config to fix this."
        exit 2
    fi

    # Extract components from url
    fetch_url="$(get_fetch_url)"
    protocol="$(echo ${fetch_url} | sed -E 's/^(\w+).*/\1/')"
    host="$(echo ${fetch_url} | sed -E 's/^.*(@|\/)(\w+)\.(com|org).*/\2/')"
    username="$(echo ${fetch_url} | sed -E 's/^.*(:|\/)(\w+)\/.*/\2/')"
    reponame="$(echo ${fetch_url} | sed -E 's/^.*\/(.*)\..*/\1/')"

    if [[ "${protocol}" == "git" ]]
    then
        protocol="ssh"
    fi

    if [[ "${host}" == "bitbucket" ]]
    then
        new_host="github"
    else
        new_host="bitbucket"
    fi

    if [ -z "${2}" ]
    then
        empty_repo_name="${reponame}"
    else
        empty_repo_name="${2}"
    fi

    # Perform git remote functions
    git_remote_seturl "${protocol}" "${new_host}" "${username}" "${empty_repo_name}"
    git_remote_add "${protocol}" "${host}" "${username}" "${reponame}"
    git_remote_add "${protocol}" "${new_host}" "${username}" "${empty_repo_name}"

    echo "Process ended successfully. Use 'git push' or 'git push --all' to push your content to both repos."
    echo "git remote -v:"
    git remote -v
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
    main "$@"
    exit $?
fi
