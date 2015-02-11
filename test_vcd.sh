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
        echo "Test Set (${1}) Passed"
    else
        echo "Test Set (${1}) Failed: ${result}"
    fi
    return "${result}"
}

function test_get_gra_url() {
    result=0

    https_bitbucket="$(get_gra_url https bitbucket avnestico version-control-distributor)"
    test_https_bitbucket="https://avnestico@bitbucket.org/avnestico/version-control-distributor.git"

    https_github="$(get_gra_url https github avnestico version-control-distributor)"
    test_https_github="https://github.com/avnestico/version-control-distributor.git"

    ssh_bitbucket="$(get_gra_url ssh bitbucket avnestico version-control-distributor)"
    test_ssh_bitbucket="git@bitbucket.org:avnestico/version-control-distributor.git"

    ssh_github="$(get_gra_url ssh github avnestico version-control-distributor)"
    test_ssh_github="git@github.com:avnestico/version-control-distributor.git"

    sga_test=(https_bitbucket https_github ssh_bitbucket ssh_github)
    for i in "${sga_test[@]}"
    do
        testtype="$i"
        testname="test_$i"
        if [[ "${!testtype}" == "${!testname}" ]]
        then
            echo "Test (get_gra_url) ${i} Passed"
        else
            echo "Test (get_gra_url) ${i} Failed"
            echo "Expected: ${!testname}"
            echo "Got: ${!testtype}"
            result=$((result + 1))
        fi
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
    run_test get_gra_url
fi
