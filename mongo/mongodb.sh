#!/bin/bash
set -e

# Install MongoDB 3.6
echo "[mongodb-org-3.6]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2013.03/mongodb-org/3.6/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-3.6.asc" | sudo tee /etc/yum.repos.d/mongodb-org-3.6.repo

# Verify that the file was created successfully
if [ -f /etc/yum.repos.d/mongodb-org-3.6.repo ]; then
    echo "MongoDB repository file created successfully."
else
    echo "Failed to create MongoDB repository file."
    exit 1
fi

# Update the package index
sudo yum update -y

# Install MongoDB
sudo yum install -y mongodb-org-3.6.23 mongodb-org-server-3.6.23 mongodb-org-shell-3.6.23 mongodb-org-mongos-3.6.23 mongodb-org-tools-3.6.23

# Start MongoDB service
sudo service mongod start

# Enable MongoDB to start on system boot
sudo chkconfig mongod on

# Open MongoDB port in EC2 security group
# Replace <security-group-id> with your EC2 instance security group ID
#aws ec2 authorize-security-group-ingress --group-id <security-group-id> --protocol tcp --port 27017 --cidr 0.0.0.0/0

# Get EC2 instance public IP
EC2_PUBLIC_IP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)

# Connect to MongoDB shell
mongo --host $EC2_PUBLIC_IP

echo "MongoDB is now installed and running on this EC2 instance."

#Install aws cli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/home/ec2-user/awscliv2.zip"
sudo unzip /home/ec2-user/awscliv2.zip
sudo ./aws/install -i /usr/local/aws-cli -b /usr/local/bin
#Check if aws cli is installed
if [ -f /usr/local/bin/aws ]; then
    echo "AWS CLI installed successfully."
else
    echo "Failed to install AWS CLI."
    exit 1

aws --version

# Function to backup MongoDB data directory to S3
s3_mongo_backup() {
    BACKUP_DIR="/backups/mongodb"
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_FILENAME="backup_mongodb_${TIMESTAMP}.tar.gz"
    S3_BUCKET="wizdemo-dev-mongo"  # Replace with your S3 bucket name

    # Create the backup directory if it doesn't exist
    sudo mkdir -p "${BACKUP_DIR}"

    # Stop the MongoDB service
    sudo service mongod stop

    # Create a compressed archive of the MongoDB data directory
    sudo tar -czf "${BACKUP_DIR}/${BACKUP_FILENAME}" /var/lib/mongo

    # Start the MongoDB service
    sudo service mongod start

    # Upload the backup file to S3
    /usr/local/bin/aws s3 cp "${BACKUP_DIR}/${BACKUP_FILENAME}" "s3://${S3_BUCKET}/${BACKUP_FILENAME}"

    echo "MongoDB data directory backup uploaded to S3: s3://${S3_BUCKET}/${BACKUP_FILENAME}"
}

# Schedule the backup function to run every 30 minutes
cron_job="0 */2 * * * /bin/bash -c 's3_mongo_backup'"
(crontab -l 2>/dev/null; echo "$cron_job") | crontab -

echo "MongoDB data directory backup to S3 scheduled to run every 120 minutes."

# To test cronjob add this to the crontab using crontab -e with the folder path to the backup script(s)
# * * * * * run-parts /path/to/
# Remove the line above after testing

