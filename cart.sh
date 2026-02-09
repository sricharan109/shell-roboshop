#!/bin/bash

USERID=$(id -u)
FOLDER="/var/log/shell-roboshop"
FILE="$FOLDER/$0.log"
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.cerry.in

if [ $USERID -ne 0 ]; then
    echo -e "Please run this script with root user access" &>> $FILE
    exit 1
fi

mkdir -p $FOLDER

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$2 ...  FAILURE" &>>$FILE
        exit 1
    else
        echo -e "$2 ...  SUCCESS" &>>$FILE
    fi
}

dnf module disable nodejs -y &>>$FILE
VALIDATE $? "Disabling NodeJS Default version"

dnf module enable nodejs:20 -y &>>$FILE
VALIDATE $? "Enabling NodeJS 20"

dnf install nodejs -y &>>$FILE
VALIDATE $? "Install NodeJS"

id roboshop &>>$FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$FILE
    VALIDATE $? "Creating system user"
else
    echo -e "Roboshop user already exist ..."
fi

mkdir -p /app 
VALIDATE $? "Creating app directory"

curl -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip  &>>$FILE
VALIDATE $? "Downloading cart code"

cd /app
VALIDATE $? "Moving to app directory"

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/cart.zip &>>$FILE
VALIDATE $? "Uzip cart code"

npm install  &>>$FILE
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service
VALIDATE $? "Created systemctl service"

systemctl daemon-reload
systemctl enable cart  &>>$FILE
systemctl start cart
VALIDATE $? "Starting and enabling cart"