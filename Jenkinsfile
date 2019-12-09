pipeline {
    agent {
        kubernetes {
            label 'jenkins-slave'
            //customWorkspace '/root/agent/'
            //cloud 'kubernetes'
            yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    node-label: jenkins-slave-jnlp
  name: jenkins-slave
  namespace: jenkins-ns
spec:
  containers:
    - name: jnlp
      image: zspmilan/jnlp-slave:mvn-sonar
      imagePullPolicy: IfNotPresent
      env:
      - name: JENKINS_URL
        value: http://192.168.169.3:30002/
      - name: JENKINS_AGENT_WORKDIR
        value: /root/agent
      volumeMounts:
        - mountPath: /usr/bin/kubectl
          name: kubectl
        - mountPath: /var/run/docker.sock
          name: docker-sock
        - mountPath: /usr/bin/docker
          name: docker-run
        - mountPath: /root/.kube
          name: kubecert
        - mountPath: /root/.m2/repository
          name: maven-repo
      workingDir: /root/agent
  nodeSelector:
    kubernetes.io/hostname: node1
  restartPolicy: Never
  volumes:
    - name: kubectl
      hostPath:
        path: /usr/bin/kubectl
    - name: docker-sock
      hostPath:
        path: /var/run/docker.sock
    - name: docker-run
      hostPath:
        path: /usr/bin/docker
    - name: kubecert
      hostPath:
        path: /root/.kube
    - name: maven-repo
      hostPath:
        path: /tmp/mavenrepo/repository
'''
        }
    }
    stages{
        stage('get code'){
            steps{
                echo 'getted the code...'
                sh '''
                   sed -i '/project>/i <distributionManagement> \
    <snapshotRepository> \
        <id>maven-snapshots</id> \
        <name>User Porject Snapshot</name> \
        <url>http://192.168.169.3:8081/repository/maven-snapshots/</url> \
        <uniqueVersion>true</uniqueVersion> \
    </snapshotRepository> \
    <repository> \
        <id>maven-releases</id> \
        <name>User Porject Release</name> \
        <url>http://192.168.169.3:8081/repository/maven-releases/</url> \
    </repository> \
  </distributionManagement>' pom.xml
                '''
            }
        }
        stage('check_code_of_feature'){
            when{not {branch 'develop'}}
            steps{
                script{
                    //withCredentials([usernamePassword(credentialsId: 'a97ecaa5-1117-402c-838b-1238bd61ba10', passwordVariable: 'sonarPassword', usernameVariable: 'sonarUser')]) {
                    //   sonarQubeUser="${sonarUser}"
                    //   sonarQubePassword="${sonarPassword}"
                    //   sh "mvn clean compile && sonar-scanner -Dsonar.login=${sonarQubeUser} -Dsonar.password=${sonarQubePassword}"
                    //}
                     configFileProvider([configFile(fileId: 'maven-global-settings', variable: 'MAVEN_SETTING')]) {
                        Maven_setting = "${MAVEN_SETTING}"
                        withSonarQubeEnv('sonarqube'){   
                            sh "mvn -s ${Maven_setting} clean compile && sonar-scanner"
                        }
                    }    
                }
            }
        }
        stage('quality gate'){
            when {not {branch 'develop'}}
            steps{
                script{
                     sleep 5
                     def qg = waitForQualityGate()
                     echo "${qg} and ${qg.status}"
                     if(qg.status != 'OK'){
                         error("未通过SonarQube的代码质量阀检查，请及时修改！failure:${qg.status}")
                    }
                }
            }
            post{
               always{
                  echo "Don't forget send mail to the related people!"
               }
            }
        }
        stage('package&upload'){
           when{ branch 'release*' }
           steps{
                echo "on branch release"
                sh "mvn clean -DskipTests deploy"
           }
        }
       // stage(''){
       //    when{ branch 'release'}
       //    steps{
       //         echo "on branch feature"
       //    } 
       // }   
    }
}//end
