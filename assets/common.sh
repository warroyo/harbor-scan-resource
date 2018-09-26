#!/bin/bash

urlencode() {
            local _length="${#1}"
            for (( _offset = 0 ; _offset < _length ; _offset++ )); do
                _print_offset="${1:_offset:1}"
                case "${_print_offset}" in
                    [a-zA-Z0-9.~_-]) printf "${_print_offset}" ;;
                    ' ') printf + ;;
                    *) printf '%%%X' "'${_print_offset}" ;;
                esac
            done
        }