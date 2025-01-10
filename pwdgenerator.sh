#!/bin/bash

LOWERCASE_LETTERS="abcdefghijklmnopqrstuvwxyz"
UPPERCASE_LETTERS="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
NUMBERS="0123456789"
SPECIAL_CHARACTERS="!@#$%^&*()-_=+[]{}<>?"

generate_password()
{
    local password=""

    local password_characters_base=""

    local include_lowercase_letters="$1"
    local include_uppercase_letters="$2"
    local include_numbers="$3"
    local include_special_characters="$4"

    local password_length="$5"
    
    if [[ "$include_lowercase_letters" == "true" ]]; then
        password+="${LOWERCASE_LETTERS:RANDOM%${#LOWERCASE_LETTERS}:1}"
        password_characters_base+="$LOWERCASE_LETTERS"
    fi

    if [[ "$include_uppercase_letters" == "true" ]]; then
        password+="${UPPERCASE_LETTERS:RANDOM%${#UPPERCASE_LETTERS}:1}"
        password_characters_base+="$UPPERCASE_LETTERS"
    fi

    if [[ "$include_numbers" == "true" ]]; then
        password+="${NUMBERS:RANDOM%${#NUMBERS}:1}"
        password_characters_base+="$NUMBERS"
    fi

    if [[ "$include_special_characters" == "true" ]]; then
        password+="${SPECIAL_CHARACTERS:RANDOM%${#SPECIAL_CHARACTERS}:1}"
        password_characters_base+="$SPECIAL_CHARACTERS"
    fi

    local letters_remaining=$(( $password_length - ${#password} ))

    if [[ $letters_remaining -gt 0 ]]; then
        password+=$(head -c 1024 /dev/urandom | tr -dc "$password_characters_base" | head -c "$letters_remaining")
    fi

    echo "PASSWORD:" "$password"
}

password_length=20
include_lowercase=false
include_uppercase=false
include_numbers=false
include_special=false
options_included=0

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -l|--length)
            if [[ -z "$2" ]]; then
                echo "It seems you used the -l or --length option but forgot to provide a number." >&2
                echo "For this mistake you shall NOT get your password." >&2
                echo "Hint: Try something like '-l 12' to set a length of 12 characters." >&2
                exit 1
            fi

            if ! [[ "$2" =~ ^[0-9]+$ ]]; then
                echo "It seems that you provided length that is not a number at all!" >&2
                echo "Once you learn what constituates a correct password length, come again" >&2
                echo "Hint: It is definately not $2! Try something like 12 or 21 or even 1500100900"
                exit 1
            fi
            
            password_length="$2"

            shift 2
            ;;
        -a|--include-lowercase)
            include_lowercase=true
            shift
            ;;
        -A|--include-uppercase)
            include_uppercase=true
            shift
            ;;
        -n|--include-numbers)
            include_numbers=true
            shift
            ;;
        -s|--include-special)
            include_special=true
            shift
            ;;
        *)
            echo "This particular program does not expect this option: $1" >&2
            echo "For some help try running $0 --help or $0 -h"
            exit 1
            ;;
    esac
done


if ! $include_lowercase && ! $include_uppercase && ! $include_numbers && ! $include_special; then
    include_lowercase=true
    include_uppercase=true
    include_numbers=true
    include_special=true
fi

generate_password $include_lowercase $include_uppercase $include_numbers $include_special $password_length
# generate_password true true true true 11