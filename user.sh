#!/bin/bash
USER_ID=$(id -u)
FOLDER="/var/log/shell-roboshop"
FILE="$FOLDER/$0.log"
SCRIPT_DIR=$PWD
MONGODB_HOST="mongodb.cerry.in"

if [ $USER_ID -ne 0 ]; then 
    echo "run the file with root access"
    exit 1
fi

mkdir -p $FOLDER

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo "$2 ......FAILED"
        exit 1
    else
         echo "$2 ......SUCCESS"
    fi
}

dnf module disable nodejs -y &>>$FILE
VALIDATE $? "Disable nodejs"

dnf module enable nodejs:20 -y &>>$FILE
VALIDATE $? "enable nodejs"

dnf install nodejs -y &>>$FILE
VALIDATE $? "Installing nodejs"

id roboshop &>>$FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$FILE
    VALIDATE $? "Creating system user"
else
    echo -e "Roboshop user already exist ... SKIPPINg"
fi

mkdir -p /app 
VALIDATE $? "Creating app directory"

curl -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip  &>>$FILE
VALIDATE $? "Downloading user code"

cd /app
VALIDATE $? "Moving to app directory"

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/user.zip &>>$FILE
VALIDATE $? "Uzip user code"

npm install  &>>$FILE
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service
VALIDATE $? "Created systemctl service"

systemctl daemon-reload
systemctl enable user  &>>$FILE
systemctl start user
VALIDATE $? "Starting and enabling user"