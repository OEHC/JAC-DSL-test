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

/***************************\
| VERIFY INTEGRATION BRANCH |
\***************************/

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
