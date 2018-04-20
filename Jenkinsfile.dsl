/*
	Parameters:
	NAME 				The name the jobs will be getting 	(ex.: my_plugin)
	REPO				The project repository				(ex.: git@github.com/me/myPlugin.git)
	DELIVERY_BRANCHES	The branches to listen to			(ex.: ready**)
	BRANCH				The integration branch				(ex.: master)
	CREDENTIALS			The Jenkins credentials to use		(ex.: ME) (probably won't be used since the Jenkins user is used for pretested)
	ARTIFACTS_DIR		The artifacts folder				(ex.: artifacts)
	MAIL				Address to send job mails to		(ex.: me@praqma.net)
*/

def CREDENTIALS = '100247a2-70f4-4a4e-a9f6-266d139da9db'
def ELIVERY_BRANCHES = '*/ready/*'
def BRANCH = 'master'
def NAME = 'memory-map-plugin'
def REPO = 'https://github.com/Praqma/memory-map-plugin.git'
def ARTIFACTS_DIR = 'artifacts'
def MAIL = 'thi@praqma.net'

def useLabel = "dockerhost1"

job("${NAME}_verify_(${BRANCH})_GEN") {
    description("Runs integration tests on the ${BRANCH} branch.")
    logRotator(-1, 50, -1, -1)
    label(useLabel)
    jdk('1.8-LATEST')
    scm {
        git {
            remote {
                url("${REPO}")
                credentials("${CREDENTIALS}")
            }
            branch("${BRANCH}")
            configure {
                node ->
                    node / 'extensions' << 'hudson.plugins.git.extensions.impl.CleanBeforeCheckout' {}
                  node / 'extensions' << 'hudson.plugins.git.extensions.impl.WipeWorkspace' {}
            }
        }

    }
    properties {
        environmentVariables {
            keepSystemVariables(true)
            keepBuildVariables(true)
            env('REPO', "${REPO}")
            env('BRANCH', "${BRANCH}")
            env('ARTIFACTS_DIR', "${ARTIFACTS_DIR}")
        }
    }
    configure {
        project ->
          project / 'properties' << 'hudson.plugins.copyartifact.CopyArtifactPermissionProperty' {
                projectNameList {
                  string "${NAME}_usecase_(${BRANCH})_GEN"
                }
          }
    }
    triggers {
      scm('H/2 * * * *')
    }
    steps {
        maven{
            goals('clean integration-test')
          mavenInstallation('newest')
        }
        shell('''# Create an unique artifact to archive and fingerprint to let job track dependencies and promotions
mkdir -p $ARTIFACTS_DIR
TF=$ARTIFACTS_DIR/jenkins-build-info-tracker__$BUILD_TAG.txt
touch $TF
echo $BUILD_ID >> $TF
echo $GIT_COMMIT >> $TF
echo "" >> $TF
env >> $TF
''')
        downstreamParameterized {
            trigger("${NAME}_usecase_(${BRANCH})_GEN") {
                parameters{
                  gitRevision(true)
                  predefinedProp('NAME', "${NAME}")
                  predefinedProp('REPO', "${REPO}")
                  predefinedProp('CREDENTIALS', "${CREDENTIALS}")
                  predefinedProp('BRANCH', "${BRANCH}")
                  predefinedProp('ARTIFACTS_DIR', "${ARTIFACTS_DIR}")
                  predefinedProp('UPSTREAM_JOB_NAME', '${JOB_NAME}')
                  predefinedProp('UPSTREAM_JOB_NO', '${BUILD_NUMBER}')
                }
            }
        }
    }
    wrappers {
        buildName('''#${BUILD_NUMBER}#${GIT_REVISION,length=8}(${GIT_BRANCH}''')
    }
    publishers {
      archiveJunit('**/target/surefire-reports/*.xml, target/failsafe-reports/*.xml') {
        retainLongStdout()
      }
      archiveArtifacts("${ARTIFACTS_DIR}/*")
      mailer("${MAIL}", false, false)
    }
}

/*************************\
| VERIFY PRETESTED BRANCH |
\*************************/
job("${NAME}_verify_(ready)_GEN") {
    description("Checks if the delivery branch is fit for integration. If so, it merges it into ${BRANCH}.")
    logRotator(-1, 50, -1, -1)
    label(useLabel)
    jdk('1.8-LATEST')
    scm {
        git {
            remote {
                url("${REPO}")
                credentials("${CREDENTIALS}")
            }
            branch("${DELIVERY_BRANCHES}")
            configure {
                node ->
                    node / 'extensions' << 'hudson.plugins.git.extensions.impl.CleanBeforeCheckout' {}
                  node / 'extensions' << 'hudson.plugins.git.extensions.impl.WipeWorkspace' {}
            }
        }

    }
    properties {
        environmentVariables {
            keepSystemVariables(true)
            keepBuildVariables(true)
            env('REPO', "${REPO}")
            env('BRANCH', "${BRANCH}")
            env('ARTIFACTS_DIR', "${ARTIFACTS_DIR}")
        }
    }
    configure {
        project ->
          project / 'properties' << 'hudson.plugins.copyartifact.CopyArtifactPermissionProperty' {
                projectNameList {
                  string "${NAME}_usecase_(${BRANCH})_GEN"
                }
          }
    }
    triggers {
      scm('H/2 * * * *')
    }
    steps {
        maven{
            goals('clean integration-test')
          mavenInstallation('newest')
        }
        shell('''# Create an unique artifact to archive and fingerprint to let job track dependencies and promotions
mkdir -p $ARTIFACTS_DIR
TF=$ARTIFACTS_DIR/jenkins-build-info-tracker__$BUILD_TAG.txt
touch $TF
echo $BUILD_ID >> $TF
echo $GIT_COMMIT >> $TF
echo "" >> $TF
env >> $TF
''')
        downstreamParameterized {
            trigger("${NAME}_usecase_(${BRANCH})_GEN") {
                parameters{
                  gitRevision(true)
                  predefinedProp('NAME', "${NAME}")
                  predefinedProp('REPO', "${REPO}")
                  predefinedProp('CREDENTIALS', "${CREDENTIALS}")
                  predefinedProp('BRANCH', "${BRANCH}")
                  predefinedProp('ARTIFACTS_DIR', "${ARTIFACTS_DIR}")
                  predefinedProp('UPSTREAM_JOB_NAME', '${JOB_NAME}')
                  predefinedProp('UPSTREAM_JOB_NO', '${BUILD_NUMBER}')
                }
            }
        }
    }
    wrappers {
        buildName('''#${BUILD_NUMBER}#${GIT_REVISION,length=8}(${GIT_BRANCH}''')
        pretestedIntegration("SQUASHED",'${BRANCH}',"origin")
    }
    publishers {
      archiveJunit('**/target/surefire-reports/*.xml, target/failsafe-reports/*.xml') {
        retainLongStdout()
      }
      archiveArtifacts("${ARTIFACTS_DIR}/*")
      mailer("${MAIL}", false, false)
    }
}

/*******************\
| RUN USECASE TESTS |
\*******************/
job("${NAME}_usecase_(${BRANCH})_GEN") {
    description("Runs integration tests on the ${BRANCH} branch.")
    logRotator(-1, 50, -1, -1)
    label(useLabel)
    jdk('1.8-LATEST')
    scm {
        git {
            remote {
                url("${REPO}")
                credentials("${CREDENTIALS}")
            }
            branch("${BRANCH}")
            configure {
                node ->
                    node / 'extensions' << 'hudson.plugins.git.extensions.impl.CleanBeforeCheckout' {}
                  node / 'extensions' << 'hudson.plugins.git.extensions.impl.WipeWorkspace' {}
            }
        }
    }
    properties {
        environmentVariables {
            keepSystemVariables(true)
            keepBuildVariables(true)
            env('REPO', "${REPO}")
            env('BRANCH', "${BRANCH}")
            env('ARTIFACTS_DIR', "${ARTIFACTS_DIR}")
        }
    }
    configure {
        project ->
          project / 'properties' << 'hudson.plugins.copyartifact.CopyArtifactPermissionProperty' {
                projectNameList {
                  string "${NAME}_analysis_(${BRANCH})_GEN"
                }
          }
    }
    steps {
        maven{
            goals('clean integration-test -P usecaseTesting')
          mavenInstallation('newest')
        }
        shell('''# Create an unique artifact to archive and fingerprint to let job track dependencies and promotions
mkdir -p $ARTIFACTS_DIR
TF=$ARTIFACTS_DIR/jenkins-build-info-tracker__$BUILD_TAG.txt
touch $TF
echo $BUILD_ID >> $TF
echo $GIT_COMMIT >> $TF
echo "" >> $TF
env >> $TF
''')
        downstreamParameterized {
            trigger("${NAME}_analysis_(${BRANCH})_GEN") {
                parameters{
                  gitRevision(true)
                  predefinedProp('NAME', "${NAME}")
                  predefinedProp('REPO', "${REPO}")
                  predefinedProp('CREDENTIALS', "${CREDENTIALS}")
                  predefinedProp('BRANCH', "${BRANCH}")
                  predefinedProp('ARTIFACTS_DIR', "${ARTIFACTS_DIR}")
                  predefinedProp('UPSTREAM_JOB_NAME', '${JOB_NAME}')
                  predefinedProp('UPSTREAM_JOB_NO', '${BUILD_NUMBER}')
                }
            }
        }
    }
    wrappers {
        buildName('''#${BUILD_NUMBER}#${GIT_REVISION,length=8}(${GIT_BRANCH}''')
    }
    publishers {
      archiveJunit('**/target/surefire-reports/*.xml, target/failsafe-reports/*.xml') {
        retainLongStdout()
      }
      archiveArtifacts("${ARTIFACTS_DIR}/*")
      mailer("${MAIL}", false, false)
    }
}

/************\
|  ANALYSIS  |
\************/
job("${NAME}_analysis_(${BRANCH})_GEN") {
    description("Runs tests and static analysis on ${BRANCH}")
    logRotator(-1, 50, -1, -1)
    label(useLabel)
    jdk('1.8-LATEST')
    scm {
        git {
            remote {
                url("${REPO}")
                credentials("${CREDENTIALS}")
            }
            branch("${BRANCH}")
            configure {
                node ->
                    node / 'extensions' << 'hudson.plugins.git.extensions.impl.CleanBeforeCheckout' {}
                  node / 'extensions' << 'hudson.plugins.git.extensions.impl.WipeWorkspace' {}
            }
        }

    }
    configure {
        project ->
          project / 'properties' << 'hudson.plugins.copyartifact.CopyArtifactPermissionProperty' {
              projectNameList {
                string "${NAME}_release_(${BRANCH})_GEN"
              }
          }
    }
    steps {
        copyArtifacts('${UPSTREAM_JOB_NAME}') {
                includePatterns("${ARTIFACTS_DIR}/*")
                fingerprintArtifacts()
                buildSelector {
                    buildNumber('${UPSTREAM_JOB_NO}')
                }
            }
        shell('''# Create an unique artifact to archive and fingerprint to let job track dependencies and promotions
mkdir -p $ARTIFACTS_DIR
TF=$ARTIFACTS_DIR/jenkins-build-info-tracker__$BUILD_TAG.txt
touch $TF
echo $BUILD_ID >> $TF
echo $GIT_COMMIT >> $TF
echo "" >> $TF
env >> $TF
''')
        maven{
            goals('clean cobertura:cobertura findbugs:findbugs checkstyle:checkstyle pmd:pmd pmd:cpd javadoc:javadoc package javadoc:javadoc jdepend:generate site')
            goals('package')
          mavenInstallation('newest')
        }
    }
    wrappers {
        buildName('''#${BUILD_NUMBER}#${GIT_REVISION,length=8}(${GIT_BRANCH}''')
    }
    publishers {
        warnings(['Maven', 'JavaDoc Tool'])
        cobertura('**/target/site/cobertura/coverage.xml')
        archiveJavadoc {
            javadocDir 'target/site/apidocs'
            keepAll true
        }
        findbugs('target/findbugsXml.xml', true) {
      }
        pmd('target/pmd.xml') {
      }
        dry('target/cpd.xml', 50, 25) {
        useStableBuildAsReference true
      }
        checkstyle('target/checkstyle-result.xml') {
      }
        tasks('**/*.*', 'target/**', 'todo, fixme', '', '', true) {
        thresholdLimit 'high'
        defaultEncoding 'UTF-8'
      }
        analysisCollector {
            checkstyle()
            dry()
            findbugs()
            pmd()
            tasks()
            warnings()
        }
        publishHtml {
            report('target/site') {
                reportName('Maven site HTML Report')
                reportFiles('index.html')
                keepAll()
                alwaysLinkToLastBuild()
            }
        }
        buildPipelineTrigger("${NAME}_release_(${BRANCH})_GEN") {
            parameters {
              gitRevision(true)
                predefinedProp('UPSTREAM_JOB_NAME', '${JOB_NAME}')
                predefinedProp('UPSTREAM_JOB_NO', '${BUILD_NUMBER}')
                predefinedProp('BRANCH', '${BRANCH}')
                predefinedProp('ARTIFACTS_DIR', '${ARTIFACTS_DIR}')
            }
        }
        archiveArtifacts("${ARTIFACTS_DIR}/*")
        mailer("${MAIL}", false, false)
    }
}

/********\
|RELEASE |
\********/
job("${NAME}_release_(${BRANCH})_GEN") {
        description('Releases the plugin')
        logRotator(-1, 50, -1, -1)
      label('jenkinsubuntu')
      jdk('1.8-LATEST')
        scm {
            git {
                remote {
                    url("${REPO}")
                  credentials("100247a2-70f4-4a4e-a9f6-266d139da9db")
                }
                branch("${BRANCH}")
                configure {
                    node ->
                        node / 'extensions' << 'hudson.plugins.git.extensions.impl.CleanBeforeCheckout' {}
                      node / 'extensions' << 'hudson.plugins.git.extensions.impl.WipeWorkspace' {}
                      node / 'extensions' << 'hudson.plugins.git.extensions.impl.LocalBranch' {
                              localBranch '${BRANCH}'
                        }
                }
            }
        }
      configure {
          project ->
          project / 'properties' << 'hudson.plugins.copyartifact.CopyArtifactPermissionProperty' {
              projectNameList {
                string "${NAME}_sync_(${BRANCH})_GEN"
              }
          }
      }
        steps {
            downstreamParameterized {
              trigger("${NAME}_sync_(${BRANCH})_GEN") {
                      parameters {
                      gitRevision(true)
                          predefinedProp('NAME', "${NAME}")
                          predefinedProp('REPO', "${REPO}")
                          predefinedProp('CREDENTIALS', "${CREDENTIALS}")
                          predefinedProp('BRANCH', "${BRANCH}")
                          predefinedProp('ARTIFACTS_DIR', "${ARTIFACTS_DIR}")
                          predefinedProp('UPSTREAM_JOB_NAME', '${JOB_NAME}')
                          predefinedProp('UPSTREAM_JOB_NO', '${BUILD_NUMBER}')
                        }
                    }
                }
            copyArtifacts('${UPSTREAM_JOB_NAME}') {
                    includePatterns("${ARTIFACTS_DIR}/*")
                    fingerprintArtifacts()
                    buildSelector {
                        buildNumber('${UPSTREAM_JOB_NO}')
                    }
              }
        shell('''# Create an unique artifact to archive and fingerprint to let job track dependencies and promotions
mkdir -p $ARTIFACTS_DIR
TF=$ARTIFACTS_DIR/jenkins-build-info-tracker__$BUILD_TAG.txt
touch $TF
echo $BUILD_ID >> $TF
echo $GIT_COMMIT >> $TF
echo "" >> $TF
env >> $TF
''')
      shell("mvn release:clean release:prepare release:perform -B")
    }
    wrappers {
        buildName('''#${BUILD_NUMBER}#${GIT_REVISION,length=8}(${GIT_BRANCH}''')
    }
    publishers {
        archiveArtifacts("${ARTIFACTS_DIR}/*")
      mailer("${MAIL}", false, false)
    }
}

/********\
|  SYNC  |
\********/
job("${NAME}_sync_(${BRANCH})_GEN") {
        description('Syncs the Praqma and Jenkinsci repositories')
        logRotator(-1, 50, -1, -1)
      label('jenkinsubuntu')
      jdk('1.8-LATEST')
        scm {
            git {
                remote {
                    url("${REPO}")
                  credentials("100247a2-70f4-4a4e-a9f6-266d139da9db")
                }
                branch("${BRANCH}")
                configure {
                    node ->
                        node / 'extensions' << 'hudson.plugins.git.extensions.impl.CleanBeforeCheckout' {}
                      node / 'extensions' << 'hudson.plugins.git.extensions.impl.WipeWorkspace' {}
                }
            }
        }
        steps {
            copyArtifacts('${UPSTREAM_JOB_NAME}') {
                    includePatterns("${ARTIFACTS_DIR}/*")
                    fingerprintArtifacts()
                    buildSelector {
                        buildNumber('${UPSTREAM_JOB_NO}')
                    }
              }
            shell('''# Create an unique artifact to archive and fingerprint to let job track dependencies and promotions
mkdir -p $ARTIFACTS_DIR
TF=$ARTIFACTS_DIR/jenkins-build-info-tracker__$BUILD_TAG.txt
touch $TF
echo $BUILD_ID >> $TF
echo $GIT_COMMIT >> $TF
echo "" >> $TF
env >> $TF
''')
          shell('''
git checkout ${BRANCH}
git fetch --tags ${REPO}
git push git@github.com:jenkinsci/memory-map-plugin.git ${BRANCH}
git push git@github.com:jenkinsci/memory-map-plugin.git --tags
''')
            }
  wrappers {
    buildName('''#${BUILD_NUMBER}#${GIT_REVISION,length=8}(${GIT_BRANCH}''')
    }
    publishers {
      archiveArtifacts("${ARTIFACTS_DIR}/*")
        mailer("${MAIL}", false, false)
  }
}
