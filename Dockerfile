FROM 192.168.169.3:8595/tomcat
ADD target/myWebApp.war /usr/local/tomcat/webapps/
EXPOSE 8080
