#!/bin/bash

# \/ DEFAULT CHARACTER POOLS
LOWERCASE_LETTERS="abcdefghijklmnopqrstuvwxyz"
UPPERCASE_LETTERS="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
NUMBERS="0123456789"
SPECIAL_CHARACTERS="!@#$%^&*()-_=+[]{}<>?"

show_help()
{
    echo "Usage: pwdgenerator [OPTION]..."
    echo "Generate a password"
    echo 
    echo "Mandatory arguments for long options are mandatory for short options too."
    printf "  %-30s %s\n" "-l, --length [X]" "Generate a password with length of X characters"
    printf "  %-30s %s\n" "-a, --include-lowercase" "Include lowercase letters in the password"
    printf "  %-30s %s\n" "-A, --include-uppercase" "Include uppercase letters in the password"
    printf "  %-30s %s\n" "-n, --include-numbers" "Include numbers in the password"
    printf "  %-30s %s\n" "-s, --include-specials" "Include special characters in the password"
    printf "  %-30s %s\n" "-d, --disable-inclusion-check" "Disable inclusion check for selected character pools"
    printf "  %-30s %s\n" "-h, --help" "Display usage message"
    echo
    echo "Examples: "
    echo "./pwdgenerator.sh <- generates a 20 characters long password, includes lowercase letters, uppercase letters, numbers and special character. Ensures that at least one character from each pool is present in the password"
    echo
    echo "./pwdgenerator.sh -l 10 <- generates a 10 characters long password, includes lowercase letters, uppercase letters, numbers and special character. Ensures that at least one character from each pool is present in the password"
    echo
    echo "./pwdgenerator.sh -a <- generates a 20 characters long password, includes only lowercase letters."
    echo
    echo "./pwdgenerator.sh -a -n -d -l 2 <- generates a 2 characters long password. Includes lowercase letters and numbers. Does not ensure that a lowercase letter or a number is present in the password."
}

generate_password()
{
    local password=""

    local password_characters_base=""

    local include_lowercase_letters="$1"
    local include_uppercase_letters="$2"
    local include_numbers="$3"
    local include_special_characters="$4"

    local password_length="$5"

    local ensure_pools_are_in_the_password="$6"
    
    if [[ "$ensure_pools_are_in_the_password" == "true" ]]; then
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
    else
        [[ "$include_lowercase_letters" == "true" ]] && password_characters_base+="$LOWERCASE_LETTERS"
        [[ "$include_uppercase_letters" == "true" ]] && password_characters_base+="$UPPERCASE_LETTERS"
        [[ "$include_numbers" == "true" ]] && password_characters_base+="$NUMBERS"
        [[ "$include_special_characters" == "true" ]] && password_characters_base+="$SPECIAL_CHARACTERS"
    fi

    local letters_remaining=$(( $password_length - ${#password} ))

    if [[ $letters_remaining -gt 0 ]]; then # urandom jest trochę dziwny
        password+=$(head -c 4096 /dev/urandom | tr -dc "$password_characters_base" | head -c "$letters_remaining")
    fi

    password=$( echo "$password" | fold -w1 | shuf | tr -d '\n' )
    echo "$password"
}

password_length=20
include_lowercase=false
include_uppercase=false
include_numbers=false
include_special=false
ensure_pools_inclusion=true
number_of_pools_included=0

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

            if [[ "$password_length" -gt 1000 ]]; then
                echo "I'm sorry, but I can generate only password that are at most 1000 characters long" >&2
                exit 1
            fi

            shift 2
            ;;
        -a|--include-lowercase)
            include_lowercase=true
            ((number_of_pools_included++))
            shift
            ;;
        -A|--include-uppercase)
            include_uppercase=true
            ((number_of_pools_included++))
            shift
            ;;
        -n|--include-numbers)
            include_numbers=true
            ((number_of_pools_included++))
            shift
            ;;
        -s|--include-specials)
            include_special=true
            ((number_of_pools_included++))
            shift
            ;;
        -d|--disable-inclusion-check)
            ensure_pools_inclusion=false
            shift
            ;;
        -h|--help)
            show_help
            exit 0
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
    number_of_pools_included=4
fi

if [[ "$ensure_pools_inclusion" == "true" ]]; then
    if [[ "$number_of_pools_included" -gt "$password_length" ]]; then
        echo "You cannot include $number_of_pools_included character pools,"
        echo "ensure that at least one character from each pool is included,"
        echo "and demand password length be $password_length!"
        echo "$password_length < $number_of_pools_included!"
        exit 1
    fi  
fi
generate_password $include_lowercase $include_uppercase $include_numbers $include_special $password_length $ensure_pools_inclusion