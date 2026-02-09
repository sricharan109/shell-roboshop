#!/bin/bash
USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
#root
if [ $USERID -ne 0 ]; then 
    echo -e "please run the command with the root user"
    exit 1
fi

mkdir -p $LOGS_FOLDER

VALIDATE(){
    if [ $1 -ne  0 ]; then 
       echo "$2 .... FAILED"
       exit 1
    else
        echo "$2 .... SUCCESS"
    fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOGS_FILE
VALIDATE $? "Copying mongodb repo"

dnf install mongodb-org -y &>>$LOGS_FILE
VALIDATE $? "Installing Mongod"

systemctl enable mongod &>>$LOGS_FILE
VALIDATE $? "Enable mongodb"

systemctl start mongod  &>>$LOGS_FILE
VALIDATE $? "starting mongodb"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Allowing remote connections"

systmctl restart mongodb &>>$LOGS_FILE
VALIDATE $? "Restarting MongoDB"