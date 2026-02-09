#!/bin/bash

USERID=$(id -u)
FOLDER="/var/log/shell-roboshop"
FILE="$FOLDER/$0.log"

if [ $USERID -ne 0 ]; then
    echo -e " Please run this script with root user access " | tee -a $FILE
    exit 1
fi

mkdir -p $FOLDER

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$2... FAILURE" | tee -a $FILE
        exit 1
    else
        echo -e "$2 ... SUCCESS" | tee -a $FILE
    fi
}

dnf install mysql-server -y &>>$FILE
VALIDATE $? "Install MySQL server"

systemctl enable mysqld &>>$FILE
systemctl start mysqld  
VALIDATE $? "Enable and start mysql"

# get the password from user
mysql_secure_installation --set-root-pass RoboShop@1
VALIDATE $? "Setup root password"