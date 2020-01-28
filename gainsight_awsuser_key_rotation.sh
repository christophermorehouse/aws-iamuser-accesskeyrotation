#!/bin/bash

awsUserName="awsuser"
fromEmailAddress="noreply@domain.com"
toEmailAddress="sendto@domain.com"

#get all access keys for aws user. Parameter will specify  either "Active" or "Inactive" keys only.
getAccessKeys() {
	aws iam list-access-keys \
		--user-name "$awsUserName" \
		--query "AccessKeyMetadata[?Status=='$1'].[AccessKeyId]" \
		--output text
}

#get count of all access keys
getNumberOfAccessKeys(){
	aws iam list-access-keys \
                --user-name "$awsUserName" \
                --query "length(AccessKeyMetadata)" \
		--output text
}

#get created date for specific key
getAccessKeyDates(){
	aws iam list-access-keys \
                --user-name "$awsUserName" \
                --query "AccessKeyMetadata[?AccessKeyId=='$1'].[CreateDate]" \
                --output text
}

#convert today's date and access key created date to epoch time and get the difference
dateDiff(){
	todaysDate=$(date +"%s")
	accessKeyCreateDate=$(date --date="$1" +"%s")
	diff=$(((todaysDate-accessKeyCreateDate) / 86400))
}

for i in $(getAccessKeys "Active"); do
	activeAccessKeyCreateDate=$(getAccessKeyDates $i|awk '{print substr($1,0,10)}')
	dateDiff ${activeAccessKeyCreateDate}
	echo "Active Access key '$i' is '$diff' days old"
	#check created date for each access key and disable if older than 90 days
	if [ "$diff" -ge 90 ]; then
		aws iam update-access-key --status Inactive --user-name "$awsUserName" --access-key-id $i
		echo "Access key: '$i' deactivated"
	fi

	#if there is only one access key and if it is >= 76 days then create another access key and pipe it to a "aws_cred" file
	if [ $(getNumberOfAccessKeys) -le 1 ] && [ "$diff" -ge 76 ]; then
                aws iam create-access-key --user-name "$awsUserName" --output text > aws_cred
		echo "There is only one active access key and it is 76 or more days old. New access key has been created"

		#pipe content of the email to messages.json, attach the "aws_cred" file and send to the specified email addresses
		echo '{"Data":"From: '$fromEmailAddress'\nTo: '$toEmailAddress'\nSubject: AWS IAM User updated credentials (contains an attachment)\nMIME-Version: 1.0\nContent-type: Multipart/Mixed; boundary=\"NextPart\"\n\n--NextPart\nContent-Type: text/plain\n\nPlease see attachment for updated access keys. The current access keys will be deactivated in two weeks (14 calendar days). Please update to the newest keys before then.\n\n--NextPart\nContent-Type: text/plain;\nContent-Disposition: attachment; filename=\"aws_cred\";\n\n'$(cat ./aws_cred)'\n--NextPart--"
}' > message.json & aws ses send-raw-email --raw-message file://./message.json

	fi
done

#delete inactive key a week after it has been deactivated
for i in $(getAccessKeys "Inactive"); do
	inactiveAccessKeyCreateDate=$(getAccessKeyDates $i|awk '{print substr($1,0,10)}')
        dateDiff ${inactiveAccessKeyCreateDate}
	echo "Inactive Access key '$i' is '$diff' days old"
	if [ "$diff" -ge 97 ]; then
		aws iam delete-access-key --user-name "$awsUserName" --access-key-id $i
		echo "Access key: '$i' deleted permanently"
	fi
done

