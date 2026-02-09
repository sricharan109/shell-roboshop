#!/bin/bash
ID=$(id -u)
FOLDER="/var/log/shell-roboshop"
FILE="$FOLDER/$0.log"

if [ $ID -ne 0 ]; then 
      echo "run the script with the root user"
    exit 1
fi
mkdir -p $FOLDER
VALIDATE(){
    if [ $1 -ne 0 ]; then
       echo "$2 ..... Failed"
    else
        echo "$2 ....Success"
    fi      
}

dnf module disable redis -y &>>$FILE 
VALIDATE $? "disabling redis"

dnf module enable redis:7 -y &>>$FILE
VALIDATE $? "enabling redis"


dnf install redis -y  &>>$FILE
VALIDATE $? "INSTALLING redis"


sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
VALIDATE $? "Allowing remote connections"

systemctl enable redis &>>$FILE
systemctl start redis  &>>$FILE
VALIDATE $? "Enabled and started Redis"