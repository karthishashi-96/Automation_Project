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
