#!/bin/bash

START_TIME=$(date +%s)
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "Script started executing at: $(date)" | tee -a $LOG_FILE

# check the user has root priveleges or not
if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $LOG_FILE
    exit 1 #give other than 0 upto 127
else
    echo "You are running with root access" | tee -a $LOG_FILE
fi

# validate functions takes input as exit status, what command they tried to install
VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "disabling nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enabling nodejs"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "installing nodejs"

if [ $? -ne 0 ]
then 
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "creating roboshop system user"
else
    echo -e "system user roboshop already created ...$Y SKIPPING $N"
fi

mkdir -p /app &>>$LOG_FILE
VALIDATE $? "creating app directory"

curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip 
VALIDATE $? "downloading user"

rm -rf /app/*
cd /app
unzip /tmp/user.zip &>>$LOG_FILE
VALIDATE $? "unzipping user"

npm install &>>$LOG_FILE
VALIDATE $? "npm dependencies installing"

cp "$SCRIPT_DIR/user.service" /etc/systemd/system/user.service &>>"$LOG_FILE"
VALIDATE $? "copying user service"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable user
systemctl start user
VALIDATE $? "starting user" 
