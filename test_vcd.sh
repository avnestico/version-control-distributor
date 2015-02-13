#!/bin/bash
source vcd.sh

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
            # Make new temp directory and initalize an empty git repo there
            tempdir="temp_${RANDOM}"
            mkdir "${tempdir}" && cd "${tempdir}"
            git init >/dev/null

            valid_url="test_${protocol}_${host}"
            git_remote_add ${protocol} ${host} avnestico example >/dev/null
            test_return=$?
            test_url="$(git remote -v | grep fetch | sed -r 's/^\w+\s+(.*)\s\(fetch\)$/\1/' )"

            if [[ "${test_return}" -eq 0 ]] && [[ "${!valid_url}" == "${test_url}" ]]
            then
                echo "[Test] (git_remote_add) ${protocol} ${host} [Passed]"
            else
                echo "[Test] (git_remote_add) ${protocol} ${host} [Failed]"
                echo "Expected: ${!valid_url}"
                echo "Got: ${test_url}"
                result=$((result + 1))
            fi

            # Clean up temp dir
            cd ..
            rm -rf "${tempdir}"
        done
    done

    # Test bad parameters
    tempdir="temp_${RANDOM}"
    mkdir "${tempdir}" && cd "${tempdir}"
    git init >/dev/null

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

    # Clean up temp dir
    cd ..
    rm -rf "${tempdir}"

    return "${result}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
    run_test git_remote_add
fi
