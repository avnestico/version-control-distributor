#!/bin/bash
source vcd.sh
#set -x  # Enable if you want verbose output

function run_test() {
    echo ""
    echo "Running Test Set (${1})"
    echo ""
    if [[ "$#" -ne 1 ]]
    then
        echo "Error: run_test must have exactly 1 parameter"
        exit 1
    fi

    test_"${1}"
    result=$?

    echo ""
    if [[ "${result}" == 0 ]]
    then
        echo "[Test Set] (${1}) Passed"
    else
        echo "[Test Set] (${1}) Failed: ${result}"
    fi
    return "${result}"
}

function temp_git_dir() {
    # Make new temp directory and initalize an empty git repo there
    dir_name="temp_${RANDOM}"
    mkdir "${dir_name}" && cd "${dir_name}"
    git init >/dev/null

    # Return string by reference
    eval "${1}=${dir_name}"
}

function clean_dir() {
    # Clean up temp dir
    cd ..
    rm -rf "${1}"
}

function test_git_remote_add() {
    result=0

    test_https_bitbucket="https://avnestico@bitbucket.org/avnestico/example.git"
    test_https_github="https://github.com/avnestico/example.git"
    test_ssh_bitbucket="git@bitbucket.org:avnestico/example.git"
    test_ssh_github="git@github.com:avnestico/example.git"

    for protocol in https ssh
    do
        for host in bitbucket github
        do
            # Create temp dir and initialize temporary git repo
            temp_git_dir temp_dir

            # Select variable name of expected url from the set above
            expected_url="test_${protocol}_${host}"

            # Perform git remote add and get url
            git_remote_add ${protocol} ${host} avnestico example >/dev/null
            test_return=$?
            get_fetch_url test_url

            # Use variable indirection ("!") to compare expected url to test url
            if [[ "${test_return}" -eq 0 ]] && [[ "${!expected_url}" == "${test_url}" ]]
            then
                echo "[Test] (git_remote_add) ${protocol} ${host} [Passed]"
            else
                echo "[Test] (git_remote_add) ${protocol} ${host} [Failed]"
                echo "Expected: ${!expected_url}"
                echo "Got: ${test_url}"
                result=$((result + 1))
            fi

            clean_dir "${temp_dir}"
        done
    done

    # Test bad parameters

    # Create temp dir and initialize temporary git repo
    temp_git_dir temp_dir

    git_remote_add bad params avnestico example >/dev/null
    test_return=$?

    if [[ "${test_return}" -eq 1 ]]
    then
        echo "[Test] (git_remote_add) bad params [Passed]"
    else
        echo "[Test] (git_remote_add) bad params [Failed]"
        echo "Expected: test_return = 1"
        echo "Got: test_return = ${test_return}"
        result=$((result + 1))
    fi

    clean_dir "${temp_dir}"

    return "${result}"
}

function test_main() {
    url="${1}"
    temp_git_dir temp_dir
    git remote add origin "${url}"
    main . "${2}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
    test_main "git@github.com:avnestico/example.git"
    test_main "git@bitbucket.com:avnestico/example.git"
    test_main "https://avnestico@bitbucket.org/avnestico/example.git"
    test_main "https://github.com/avnestico/example.git"
    test_main "https://github.com/avnestico/example.git" "other_example"

    #run_test git_remote_add
fi
