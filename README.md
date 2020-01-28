The behavior of the script is as follows:
1.	Check the current access key. If it is 76 days old create a new access key and email it to the specified email address. Otherwise, do nothing. This gives the user 2 weeks to switch access and secret keys.
2.	Check the current active access keys. If any of them are 90 days old deactivate it.
3.	Check deactivated keys. If there are any that are 97 days old, delete it. This gives us a week to revert back if needed.
4.	The file that contains the latest access key is written in the same directory. It will stay here until it gets overwritten by the next key rotation.

Prerequisites:
The script uses the Amazon Simple Email Service API to email the access key credentials. If you plan on using this part of the script, please make sure Amazon SES is set up and configured correctly with verified domains and email addresses.
