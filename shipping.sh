ID= $(id -u)
FOLDER="/var/log/shell-roboshop"
FILE=/$FOLDER/$0.log
DIR=$(pwd)
if [ $ID -ne 0]; then
    echo "run this command with root user"
    exit 1 
else 
    echo "you are running this script with root user"
fi
mkdir -p $FOLDER
VALIDATE(){
    if [ $1 -nq 0 ] then 
        echo "$2 .....FAILED"
    else
        echo "$2 ....SUCCESS"
    fi
}

dnf install maven -y &>>$FILE
VALIDATE $? "Installing maven"

id roboshop &>>$FILE
if [ $? -ne 0 ]; then
    useradd roboshop &>>$FILE
    VALIDATE $? "adding robothsop user"
else 
    echo "roboshop user already exists"
fi

mkdir /app &>>$FILE
VALIDATE $? "creating application directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip 
cd /app 
unzip /tmp/shipping.zip &>>$FILE

cd /app
VALIDATE $? "Moving to app directory"

rm -rf /app/*

unzip /tmp/shipping.zip &>>$FILE
VALIDATE $? "Uzip shipping code"

cd /app 
mvn clean package &>>$FILE
VALIDATE $? "Installing and Building shipping"

mv target/shipping-1.0.jar shipping.jar 
VALIDATE $? "Renaming the jar file"

cp $DIR/shipping.service /etc/systemd/system/shipping.service &>>$FILE
VALIDATE $? "copying systemd file"

dnf install mysql -y &>>$FILE
VALIDATE $? "Installing mysql"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities'
if [ $? -ne 0 ]; then

    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>$FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql &>>$FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$FILE
    VALIDATE $? "Loaded data into MySQL"
else
    echo -e "data is already loaded ... SKIPPING "
fi

systemctl enable shipping &>>$FILE
systemctl start shipping
VALIDATE $? "Enabled and started shipping"