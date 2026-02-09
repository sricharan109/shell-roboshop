#!/bin/bash
USER_ID=$(id -u)
FOLDER="/var/log/shell-roboshop"
FILE="$FOLDER/$0.log"
SCRIPT_DIR=$PWD
MONGODB_HOST="mongodb.cerry.in"

if [ $USER_ID -ne 0]; then 
    echo "run the file with root access"
    exit 1
fi

mkdir -p $FOLDER

VALIDATE(){
    if [ $1 -ne 0]; then
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
     useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOGS_FILE
     VALIDATE $? "Creating system user"
else
     echo -e "Roboshop user already exist"
fi

mkdir -p /app 
VALIDATE $? "creating app folder"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip  &>>$FILE
VALIDATE $? "Downloading catalogue code"

cd /app
VALIDATE $? "Moving to app directory"
 

rm -rf /app/*
VALIDATE $? "REMoving existing code"

unzip /tmp/catalogue.zip &>>$FILE
VALIDATE $? "Uzip catalogue code"

npm install &>>$FILE
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Created systemctl service"

systemctl daemon-reload
systemctl enable catalogue  &>>$FILE
systemctl start catalogue
VALIDATE $? "Starting and enabling catalogue"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y &>>$FILE

INDEX=$(mongosh --host $MONGODB_HOST --quiet  --eval 'db.getMongo().getDBNames().indexOf("catalogue")')

if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js
    VALIDATE $? "Loading products"
else
    echo -e "Products already loaded ...  SKIPPING"
fi

systemctl restart catalogue
VALIDATE $? "Restarting catalogue"