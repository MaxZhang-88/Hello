#!/usr/bin/groovy
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
  serviceAccountName: jenkins-admin
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
    environment{
            nexusDockerUsePwd = credentials('71e6ff25-ceb9-443b-bedf-7c5339c107e7')
            registry = "192.168.169.3:8595"
    }
    options{timestamps()}
    stages{
        stage('get code'){
            steps{
                echo 'getted the code...'
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
                //sh "mvn clean -DskipTests deploy"
                script{
                    configFileProvider([configFile(fileId: 'maven-global-settings', variable: 'MAVEN_SETTING')]) {
                        Maven_setting = "${MAVEN_SETTING}"
                        sh "mvn -s ${Maven_setting} clean deploy"
                    }    
                }
           }
        }
       stage('package docker image'){
           when{ branch 'release'}
           steps{
                echo "Will make the docker image of tomcat and upload it to nexus repo"
                sh '''
                   docker login -u ${nexusDockerUsePwd_USR} -p ${nexusDockerUsePwd_PSW} ${registry}
                   docker build -t ${registry}/hello:v1 .
                   docker push ${registry}/hello:v1
                   '''
           } 
        }   
        stage('deploy hello to test'){
             when{branch 'release'}
             steps{
                 echo "Will deploy the hello to test environment!"
                 sh 'kubectl apply -f hello-project-test.yaml'
             }
        }
        stage('test hello'){
            when{branch 'release'}
            steps{
                echo "Now is testing the hello project...."
                sh '''
                   chmod u+x test.sh
                   ./test.sh
                   '''
            }
        }
        stage('manual test'){
            when{branch 'release'}
            steps{
                echo "Waiting the manual test result..."
            }    
            input{
                message "Is the manuall test ok?"
                ok "Yes, the test passed"
                submitter "max"
                }
        }
    }
}//end
