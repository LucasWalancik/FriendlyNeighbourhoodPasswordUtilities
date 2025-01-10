# Friendly Neighbourhood Password Utilities

This is a collection of programs that allow you to create, validate
and manage your passwords.

## Programs

### pwdgenerator.sh
This programme allows you to generate a secure* password with parameters of your choice. You can choose the length of the password and the pool of characters it will consist of.

#### What do I want to add
I kinda want to allow users to include character pools of their own. I would probably read filenames of files which contain characters that user wants to include in their password. For example, file "korean.txt" which contains korean alphabet characters.

This seemed like cool idea, and it still does. One of the funny aspects is the fact, that I read somewhere, that some russian hackers chose not to scam or hack someone who had some russian letters in their email or password.

Unfortunately, after checking some of the most popular services like google or microsoft or facebook, i found out that they do not allow most of non english letters. 

Oh and I want to convince myself that this program generates safe passwords, in the cryptoanalytical sense. Passwords that cannot be re-generated in any way. Or at least in any easay way.

#### Bugs and potential problems
I don't know why, but using this program with the -s option, which includes special character causes it not to work properly. When run with only the -s option, you can see that there are some non-special characters in the password, which should not happen. It's worrying me, because it doesn't happen with -a, -A or -n. I guess it has to do something with the password generation itself, or with shufling maybe.

### pwdvalidator.sh
This programme allows you to validate your passsword. It can check against length, different character pools inclusion, and even 
haveibeenpwnd, which i think is quite cool.

#### What do I want to add
I would like to allow users to have more power over what to validate against. I would like to add more options, but I would also like to expand on the existing ones. It could include things like checking if password's lenght is in some required range, or that the password contains X characters of some pool (3 lowercase letters, 5 special characters, etc.). 

### pwdmanager.pl
This programme allows you to manage your paswords. It stores your precious data in a MILITARY GRADE encrypted files. All jokes aside, there is functionality for adding new passwords, but no functionality for deleting them, so add carefully!

#### What do I want to add
Well I think that program like this is kinda bound to have some GUI. It's tedious, boring and annoying to manage such formated information from terminal only. Oh, of course I want to add the ability to delete and edit entries. Currently only adding them is possible. 
This program has an option to generate passwords using pwdgenerator.sh, but it's only limited to the default options. I would like to allow users to generate passwords with their own options.
I would love to add validation option when adding new passwords, and whenever users wants to. I also want to add "Creation Date" field, instead of "Last modified", which currently has no use. I would like to allow users to set a timer for their passwords, expiration date or something. This would allow users to change their passwords frequently.

#### Bugs and potential problems
There is no option to delete or edit entries currently.
The codebase is kinda messy. I don't really like the check_for_database function. It stinks.
I guess I have to git gud at Perl.
Oh, and the encryption functionality raises warnings about using defunct functions. Unfortunately, it's the only module that was working for me, and currently I don't really know how to fix it.