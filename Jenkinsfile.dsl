DOCKER_LABEL = 'docker'
NUM_OF_BUILDS_TO_KEEP = 100

JOB_NAME = 'oehc-test-jac-dsl-seed-GEN'

job(JOB_NAME) {

    logRotator {
        numToKeep(NUM_OF_BUILDS_TO_KEEP)
    }

    label(DOCKER_LABEL)

    steps {
        shell('echo "Yo yo!" > artifact.txt')
    }

    publishers {
        archiveArtifacts('artifact.txt')
    }

}
