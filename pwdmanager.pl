my @modules = (
    'Crypt::CBC',
    'Digest::SHA',
    'JSON',
    'Try::Tiny',
    'Time::Piece',
    'Term::ReadKey',
    'Term::ANSIColor'
);

sub check_modules {
    my @missing;
    foreach my $module (@modules) {
        eval "use $module";
        if ($@) {
            push @missing, $module;
        }
    }
    return @missing;
}

my @missing_modules = check_modules();
if (@missing_modules) {
    die "The following required modules are missing: " . join(', ', @missing_modules) . "\n" .
        "Please install them using cpan or cpanm.\n";
}

use Crypt::CBC;
use Digest::SHA qw(sha256_hex);
use JSON;
use Try::Tiny;
use Time::Piece;
use Term::ReadKey;
use Term::ANSIColor;

sub display_help {
    print <<'END_HELP';
Usage: perl pwdmanager.pl [OPTIONS]...

Options:
  -h, --help      Display this help message and exit.

Description:
This program is a password manager that allows you to manage your
passwords. You can add new entries, view existing ones, and save your database.
This program uses pwdgenerator.sh for safe* password generation.

END_HELP
    exit;  # Zakończenie programu po wyświetleniu pomocy
}

sub read_file
{
    my ($file_path) = @_;
    open my $fh, '<', $file_path or die "Could not open file '$file_path': $!";
        my $file_data = do { local $/; <$fh> };
    close $fh;

    return $file_data;
}

sub write_file {
    my ($file_path, $data) = @_;

    if (open my $fh, '>', $file_path) {
        print $fh $data;
        close $fh;
        return 1;
    } else {
        warn "Could not save the database '$file_path': $!";
        return 0;
    }
}

sub encrypt_data
{
    my ($data, $key) = @_;
    $cipher = Crypt::CBC->new( -pass   => "$key",
             -cipher => 'Cipher::AES'
            );
    my $encrypted_data = $cipher->encrypt($data);

    return $encrypted_data;
}

sub decrypt_data
{
    my ($data, $key) = @_;
    my $cipher = Crypt::CBC->new( -pass   => "$key",
                        -cipher => 'Cipher::AES');
    my $decrypted_data = $cipher->decrypt($data);

    return $decrypted_data;
}

sub verify_password
{
    my ($file_path, $password) = @_;
    my $expected_meta = sha256_hex($password);

    my $ciphertext = read_file($file_path);
    my $plaintext = decrypt_data($ciphertext, $password);

    my $data;
    try {
        $data = decode_json($plaintext);
    }
    catch {
        print "Wrong master password!\n";
        exit 1;
    };

    if ($data->{meta} eq $expected_meta) {
        print "Password is correct.\n";
        return 1;
    } else {
        print "Wrong master password!.\n";
        exit 1
    }
}

sub display_entries
{
    clear_screen();
    my ($json_data) = @_;
    my $json_data = decode_json($json_data);

    if (exists $json_data->{entries} && keys %{ $json_data->{entries} }) {
        print "\n\nENTRIES IN YOUR DATABASE:\n";
        printf "%-3s | %-11s | %-15s | %-20s | %-15s\n", "ID", "Last Change", "Name", "Login", "Password";
        print "-----------------------------------------------------------------------------\n";
        
        foreach my $key (sort { $a <=> $b } keys %{ $json_data->{entries} }) {
            my $entry = $json_data->{entries}{$key};
            printf "%-3s | %-11s | %-15s | %-20s | %-15s\n",
                $key,
                $entry->{last_modified} // "N/A",
                $entry->{name}          // "N/A",
                $entry->{login}         // "N/A",
                $entry->{password}      // "N/A";
        }
    } else {
        print "Database is empty.\n";
    }
}

sub read_entry_data
{
    my ($generate_passwords) = @_;

    print "Please enter name of your entry: ";
    my $entry_name = <STDIN>;
    chomp($entry_name);

    print "Please enter your login / email: ";
    my $entry_login = <STDIN>;
    chomp($entry_login);

    my $entry_password="BLABLA";
    if ($generate_passwords eq "true"){
        $entry_password = generate_password();
    }else{
        print "Please enter your password: ";
        Term::ReadKey::ReadMode('noecho');
        $entry_password = Term::ReadKey::ReadLine(0);
        chomp($entry_password);
        Term::ReadKey::ReadMode('restore');
    }
    return $entry_name, $entry_login, $entry_password;
}

sub add_entry
{
    my ($json_data, $generate_passwords) = @_;
    $json_data = decode_json($json_data);
    my ($entry_name, $entry_login, $entry_password) = read_entry_data($generate_passwords);
    my $new_id = (sort { $a <=> $b } keys %{ $json_data->{entries} })[-1] + 1;
    my $current_date = localtime->ymd;
    $json_data->{entries}{$new_id} = {
        last_modified => $current_date,
        name          => $entry_name,
        login         => $entry_login,
        password      => $entry_password,
    };

    my $updated_json = encode_json($json_data);
    clear_screen();
    return $updated_json;
}

sub create_first_entry
{
    my ($Master_Password) = @_;
    my $password_hash = sha256_hex($Master_Password);

    my ($entry_name, $entry_login, $entry_password) = read_entry_data();
    my $current_date = localtime->ymd;
    $json_data->{meta} = $password_hash;
    $json_data->{entries}{1} = {
        last_modified => $current_date,
        name          => $entry_name,
        login         => $entry_login,
        password      => $entry_password,
    };
    my $updated_json = encode_json($json_data);
    clear_screen();
    return $updated_json;
}

sub save_entry
{
    my ($entry, $password) = @_;

    my $encrypted_entry = encrypt_data($entry, $password);
    write_file("HASLA2.json.enc", $encrypted_entry);
}

sub clear_screen {
    print "\e[H\e[2J";
}

sub generate_password
{
    my $password = `./pwdgenerator.sh`;
    chomp($password);
    if ($? != 0) {
        print "pwdgenerator encountered critical error. Abort!";
        exit 1;
    }
    return $password;
}

sub display_menu
{
    my ($generate_passwords) = @_;
    print "-----MAIN MENU-----\n";
    print "1. See your entries\n";
    print "2. Add new entry\n";
    print "3. Save your database\n";
    print "4. Generate passwords instead of typing";
    if ($generate_passwords eq "true"){
        print " (ON)\n";
    }else{
        print " (OFF)\n";
    }
    print "5. Exit\n"
}

sub save_database{
    my ($json_data, $Master_Password) = @_;
    my $encrypted_data = encrypt_data($json_data, $Master_Password);
    write_file("PASSWORDS.enc", $encrypted_data);
    print "Database PASSWORDS.enc saved.\n";
}

sub exit_the_program{
    my ($json_data, $Master_Password, $database_saved) = @_;
    if ($database_saved eq "false"){
        print "WATCH OUT!\n";
        print "There are unsaved entries.\n";
        print "You will loose them forever if you exit right now.\n";
        print "Do you wish to save your database before exit? (y/n): ";
        my $option = <STDIN>;
        chomp($option);
        if ($option eq "y"){
            if(save_database($json_data, $Master_Password)){
                print "Databased saved successfully.\n";
            }else{
                warn "Oh no! Something went wrong.\n";
                warn "Database is not saved!\n";
            }
        }else{
            print "Exiting the program. Goodbye!\n";
        }
    }
    print "Exiting the program. Goodbye!\n";
    last;
}

sub main_menu {
    my ($json_data, $Master_Password) = @_;
    my $database_saved = "true";
    my $generate_passwords = "false";
    while (1) {
        display_menu($generate_passwords);
        print "\nPlease choose one option: ";
        my $option = <STDIN>;
        chomp($option);
        if ($option eq "1") {
            display_entries($json_data);
        } elsif ($option eq "2") {
            $json_data = add_entry($json_data, $generate_passwords);
            $database_saved = "false";
        } elsif ($option eq "3") {
            if(save_database($json_data, $Master_Password)){
                print "Databased saved successfully.\n";
                $database_saved = "true";
            }else{
                warn "Oh no! Something went wrong.\n";
                warn "Database is not saved!\n";
            }
        }elsif ($option eq "4"){
            clear_screen();
            if($generate_passwords eq "true"){
                $generate_passwords = "false";
            }else{
                $generate_passwords = "true";
            }
        }elsif ($option eq "5") {
            exit_the_program($json_data, $Master_Password, $database_saved);
        } else {
            print "Invalid option. Please choose a number between 1 and 4.\n";
        }
        print "\n";
    }
}

# Okropna ta funkcja. Bleh. Ale lepszej nie mam 
sub check_for_database {
    my $DATABASE_NAME = "PASSWORDS.enc";
    if (-e $DATABASE_NAME){
        print "Please enter your Master Password for the PASSWORDS database: ";
        Term::ReadKey::ReadMode('noecho');
        my $Master_Password = Term::ReadKey::ReadLine(0);
        chomp($Master_Password);
        Term::ReadKey::ReadMode('restore');
        verify_password("PASSWORDS.enc", $Master_Password);
        my $ciphertext = read_file($DATABASE_NAME);
        my $plaintext = decrypt_data($ciphertext, $Master_Password);
        main_menu($plaintext, $Master_Password);
    }else {
        print "It seems that there is no PASSWORDS database in this directory.\n";
        print "Would you like to create the database and your first entry? (y/n)";
        my $answer = <STDIN>;
        chomp($answer);
        if ($answer eq "y" || $answer eq "Y" || $answer eq "yes" || $ansewr eq "Yes") {
            print "\nFirst step is to create a Master Password, which will be used to encrypt your passwords.\n";
            print "Your Master Password wont be saved, so you better write it down!\n";
            print "Please enter your Master Password: ";
            Term::ReadKey::ReadMode('noecho');
            my $Master_Password = Term::ReadKey::ReadLine(0);
            chomp($Master_Password);
            Term::ReadKey::ReadMode('restore');
            print "\n\nGreat. Now let's create your first entry. \n";
            my $json_data = create_first_entry($Master_Password);
            display_entries($json_data);
            print "\n";
            main_menu($json_data, $Master_Password);
        }
    }
}

foreach my $arg (@ARGV) {
    if ($arg eq '-h' || $arg eq '--help') {
        display_help();
    }
}

clear_screen();
check_for_database();