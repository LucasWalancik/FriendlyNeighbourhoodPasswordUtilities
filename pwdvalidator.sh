#!/bin/bash

check_length=false
check_lowercase=false
check_uppercase=false
check_numbers=false
check_specials=false
check_haveibeenpwned=false
options_provided=false

lowercase_regex='[a-z]'
uppercase_regex='[A-Z]'
numbers_regex='[0-9]'
specials_regex='[^a-zA-Z0-9]'

show_help() {
    echo "Usage: pwdvalidator.sh [OPTIONS]... [PASSWORD]"
    echo "This program validates your passwords."
    echo
    echo "Mandatory arguments for long options are mandatory for short options too."
    printf "  %-30s %s\n" "-l, --check-length [X]" "Check if password is at least X characters long"
    printf "  %-30s %s\n" "-a, --check-lowercase" "Check if password contains lowercase letters"
    printf "  %-30s %s\n" "-A, --check-uppercase" "Check if password contains uppercase letters"
    printf "  %-30s %s\n" "-n, --check-numbers" "Check if password contains numbers"
    printf "  %-30s %s\n" "-s, --check-specials" "Check if password contains special characters"
    printf "  %-30s %s\n" "-i, --check-haveibeenpwned" "Check if password appears in haveibeenpwned database"
    printf "  %-30s %s\n" "-h, --help" "Display usage message"
    echo
}

check_password_length() {
    local password=$1
    local length_to_check=$2
    local password_length=${#password}

    if (( password_length < length_to_check )); then
        echo -e "X  Password length is too short: $password_length / $length_to_check"
        return 1
    else
        echo -e "O  Password satisfies the length condition: $password_length / $length_to_check"
        return 0
    fi
}

check_regex() {
    local password=$1
    local regex=$2
    local description=$3

    if [[ ! $password =~ $regex ]]; then
        echo -e "X  Password does not contain $description" # :< zamiast :(, lepiej się wyrożnia od :) a może X i O?
        return 1
    else
        echo -e "O  Password contains $description" # lepsza wersja niż z :) na końcu linii?
        return 0
    fi
}

check_haveibeenpwned() {
    local password=$1
    local hash
    local prefix
    local suffix
    local response

    hash=$(echo -n "$password" | sha1sum | awk '{print $1}' | tr '[:lower:]' '[:upper:]')
    prefix=${hash:0:5}
    suffix=${hash:5}

    response=$(curl -s "https://api.pwnedpasswords.com/range/$prefix")
    if echo "$response" | grep -q "$suffix"; then
        echo -e "X  Password has been found in haveibeenpwned database!"
        return 1
    else
        echo -e "O  Password has NOT been found in haveibeenpwned database."
        return 0
    fi
}

length_to_check=15

while [[ $# -gt 0 ]]; do
    case $1 in
        -l|--check-length)
            if [[ -z "$2" ]]; then
                echo "It seems you used the -l or --check-length option but forgot to provide a number." >&2
                echo "Hint: Try something like '-l 12' to set a length of 12 characters." >&2
                exit 1
            fi
            if ! [[ "$2" =~ ^[0-9]+$ ]]; then
                echo "It seems that you provided length that is not a number at all!" >&2
                echo "Once you learn what constituates a correct password length, come again" >&2
                echo "Hint: It is definately not $2! Try something like 12 or 21 or even 1500100900" >&2
                exit 1
            fi
            if [[ "$2" -le 0 || "$2" -gt 1000 ]]; then
                echo "Invalid length: must be a number between 1 and 1000." >&2
                exit 1
            fi
            check_length=true
            length_to_check=$2
            options_provided=true
            shift 2
            ;;
        -a|--check-lowercase)
            check_lowercase=true
            options_provided=true
            shift
            ;;
        -A|--check-uppercase)
            check_uppercase=true
            options_provided=true
            shift
            ;;
        -n|--check-numbers)
            check_numbers=true
            options_provided=true
            shift
            ;;
        -s|--check-specials)
            check_specials=true
            options_provided=true
            shift
            ;;
        -i|--check-haveibeenpwned)
            check_haveibeenpwned=true
            options_provided=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            if [[ $password_found == true ]]; then
                echo "Error: Multiple non-option arguments detected. Only one password can be provided." >&2
                exit 1
            fi
            password="$1"
            password_found=true
            shift
            ;;
    esac
done


if ! $options_provided; then
    check_length=true
    check_lowercase=true
    check_uppercase=true
    check_numbers=true
    check_specials=true
    check_haveibeenpwned=true
fi

if [[ -z $password ]]; then
    echo "Enter password: "
    read -s password
fi

validation_passed=true
maximum_validation_points=0
validation_points_gained=0
echo "VALIDATION RESULTS:"
echo "-------------------"

if $check_length; then
    ((maximum_validation_points++))
    if check_password_length "$password" "$length_to_check"; then
        ((validation_points_gained++))
    else
        validation_passed=false
    fi
fi

if $check_lowercase; then
    ((maximum_validation_points++))
    if check_regex "$password" "$lowercase_regex" "lowercase letters"; then
        ((validation_points_gained++))
    else
        validation_passed=false
    fi
fi

if $check_uppercase; then
    ((maximum_validation_points++))
    if check_regex "$password" "$uppercase_regex" "uppercase letters"; then
        ((validation_points_gained++))
    else
        validation_passed=false
    fi
fi

if $check_numbers; then
    ((maximum_validation_points++))
    if check_regex "$password" "$numbers_regex" "numbers"; then
        ((validation_points_gained++))
    else
        validation_passed=false
    fi
fi

if $check_specials; then
    ((maximum_validation_points++))
    if check_regex "$password" "$specials_regex" "special characters"; then
        ((validation_points_gained++))
    else
        validation_passed=false
    fi
fi

if $check_haveibeenpwned; then
    ((maximum_validation_points++))
    if check_haveibeenpwned "$password"; then
        ((validation_points_gained++))
    else
        validation_passed=false
    fi
fi

echo
echo "Your password gained $validation_points_gained / $maximum_validation_points Validation Points"

if $validation_passed; then
    echo "Impressive!"
else
    echo "Git gud son."
    exit 1
fi