#!/bin/bash

# Mailgun send email
current_date=$(date +"%Y-%m-%d")
curl -s --user 'api:<API-KEY>' \
	 https://api.mailgun.net/v3/<email-domain.tld>/messages \
	 -F from='SENDER NAME <<EMAIL-ADRESS@emailadress.tld>>' \
	 -F to='RECEIPIENT NAME <<EMAIL-ADRESS@emailadress.tld>>' \
	 -F subject="Mailgun Test Email $current_date" \
	 -F text='Congratulations Mailgun, you just sent an email! You are truly awesome!'

# 30 Sekunden warten
sleep 30

# Login Informations
IMAP_SERVER="imap.mailserver.tld"
IMAP_PORT="993"
SMTP_SERVER="smtp.mailserver.tld"
SMTP_PORT="587"
USERNAME="user@domain.tld"
#please don't use the $ character
PASSWORD='password'
RECIPIENT="receipient@email-adress.tld"


check_and_delete_email() {

  # curl IMAP request to delete emails
  result=$(curl -s --user "$USERNAME:$PASSWORD" --url "imaps://$IMAP_SERVER:$IMAP_PORT/INBOX" --request "STORE 1:* +FLAGS (\Deleted)" 2>&1)

  # Delete everything
  expunge_result=$(curl -s --user "$USERNAME:$PASSWORD" --url "imaps://$IMAP_SERVER:$IMAP_PORT/INBOX" --request "EXPUNGE" 2>&1)

  check_inbox_empty
}

# Check if inbox is empty
check_inbox_empty() {
  result=$(curl -s --user "$USERNAME:$PASSWORD" --url "imaps://$IMAP_SERVER:$IMAP_PORT/INBOX" --request "STATUS INBOX (MESSAGES)" 2>&1)
  
  echo "IMAP server result:"
  echo "$result"
  
  num_messages=$(echo "$result" | grep -oP '(?<=MESSAGES )\d+')
  
  if [[ "$num_messages" -eq 0 ]]; then
    send_warning_email
  else
    echo "new emails available."
  fi
}

# send warn email
send_warning_email() {
  SUBJECT="Warning: No new emails"
  BODY="No new emails."
  FROM="From: $USERNAME"
  TO="To: $RECIPIENT"

  {
    echo "Subject: $SUBJECT"
    echo "$FROM"
    echo "$TO"
    echo
    echo "$BODY"
  } | curl -v --url "smtp://$SMTP_SERVER:$SMTP_PORT" --ssl-reqd \
      --mail-from "$USERNAME" --mail-rcpt "$RECIPIENT" \
      --upload-file - --user "$USERNAME:$PASSWORD" 2>&1
}

check_and_delete_email
