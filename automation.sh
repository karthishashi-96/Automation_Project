echo "Updating all the packages"
sudo apt-get update -y

PKG="apache2"
PKG_STATUS=$(dpkg-query -W --showformat='${Status}\n' $PKG|grep "install ok installed")
echo Checking for $PKG: $PKG_STATUS

if [ "" = "$PKG_STATUS" ]; then
  echo "No $PKG available. Setting up the $PKG."
  sudo apt-get --yes install $PKG 
fi

apache_stat=$(service apache2 status)
if [[ $apache_stat == *"active (running)"* ]]; then
  echo "Apache Service is running"
else
  echo "Apache Service is not running and starting it"
  sudo service apache2 start
fi

timestamp=$(date '+%d%m%Y-%H%M%S')
myname="karthick"
s3_bucket="upgrad-karthick"

echo "Creating a tar file: "
tar cvf /tmp/${myname}-httpd-logs-${timestamp}.tar /var/log/apache2/*.log

echo "Installing awscli dependencies:"
sudo apt --yes install awscli

echo "Uploading to the S3 bucket"
aws s3 \
cp /tmp/${myname}-httpd-logs-${timestamp}.tar \
s3://${s3_bucket}/${myname}-httpd-logs-${timestamp}.tar

file_inventory="/var/www/html/inventory.html"
filename="/tmp/${myname}-httpd-logs-${timestamp}.tar"
size=$(wc -c $filename | awk '{print $1}')


echo "Checking if inventory file exists or not"

if [[ ! -f $file_inventory ]]; then
    echo "file for inventory not found. Generating a new file" 
    sudo touch $file_inventory
    sudo chmod +x $file_inventory
    sudo echo "Log Type&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Date Created&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Type&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Size<br>" >> $file_inventory
fi

sudo echo "httpd-logs&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$timestamp&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;tar&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$size Bytes<br>" >> $file_inventory

echo "inventory file has been successfully updated. You can verify the same from the server"

file_cron="/etc/cron.d/automation"
file_automation="/root/Automation_Project/automation.sh"

echo "Checking if the cron job exists or not"

cron_job_available=$(sudo crontab -l | grep 'automation')

echo "CRON job is found : $cron_job_available"

if [[ ! $cron_job_available ]]; then
	if [[ ! -f  $file_cron ]]; then
        echo "file for cron not found. Generating a new file" 
		sudo touch $file_cron
		sudo chmod +x $file_cron
		sudo echo "0 8 * * * $file_automation" >> $file_cron
	fi
	sudo crontab $file_cron
fi
