#! /bin/bash

##############################################################################
# This script provide the following functionalities;
#   1. Lists all Jenkins' projects (jobs) with their status (enabled/disabled). 
#      You can find a projects list in a file at $JENKINS_PROJECTS_STATUS_FILE. 
#   2. Restores the projects status (enabled/disabled) due to the list
#      mentioned above ($JENKINS_PROJECTS_STATUS_FILE).
#   3. Disables all Jenkins projects, creating the projects list mentioned 
#      above with projects status before disabling.
#   4. Allows executing a Groovy code entered manually.
###############################################################################

JENKINS_URL='http://localhost:8080/jenkins'     # URL under which Jenkins is achievable; do not end it with slash
JENKINS_HOME='/opt/jenkins/workspace'           # Jenkins workspace directory; do not end it with slash
JENKINS_PROJECTS_STATUS_FILE='jenkins-project-status'
GROOVY_JOB_STATE_RESTORE_FILE='restore_project_state.groovy'
GROOVY_LIST_PROJECTS_STATUS_FILE='list_projects_status.groovy'
GROOVY_DISABLE_ALL_PROJECTS_FILE='disable_all_projects.groovy'
JOB_STATE_RESTORE_LOG='jenkins-restore-project-state.log'


echo -e "\nStarting getting Jenkins' projects disabled... \n"

# downloads current jenkins-cli.jar
echo -e -n '\nFinding jenkins-cli.jar...'
if [ -f 'jenkins-cli.jar' ]
then
    echo -e ' jenkins-cli.jar is alreadey downloaded and it will be used further. If something went wrong, you might consider updating it.\n\n'
else
    wget --quiet --no-check-certificate ${JENKINS_URL}/jnlpJars/jenkins-cli.jar
    if ! [ -f 'jenkins-cli.jar' ]
    then
        echo ' jenkins-cli.jar could not be downloaded. Quitting the script.'
        exit
    fi
    echo -e ' downloaded\n\n'
fi


apiUser=''     # Jenkins user with Overall/Administer access
apiToken=''    # Jenkins API Token configured for an $apiUser

read -p 'Enter Jenkins API username: ' apiUser
read -p "Enter Jenkins API token for user $apiUser: " apiToken

if ! [ -f $GROOVY_JOB_STATE_RESTORE_FILE ] || ! [ -f $GROOVY_LIST_PROJECTS_STATUS_FILE ] || ! [ -f $GROOVY_DISABLE_ALL_PROJECTS_FILE ]
then
    echo -e "\nProblem ! Some of following files are missing: \n  $GROOVY_JOB_STATE_RESTORE_FILE \n  $GROOVY_LIST_PROJECTS_STATUS_FILE \n  $GROOVY_DISABLE_ALL_PROJECTS_FILE \n"
    exit
fi

while true
do
    startTimeExt=$(date +%F__%T | sed 's/:/-/g')'.txt'
    echo -e '\nChoose an action...\n'
    select action in 'List projects and modules with their status (enabled/disabled)' 'Restore projects/modules state (enabled/disabled) due to a list' 'Disable all projects and modules' 'Pop a groovy expression in' 'Exit the script'
    do
        case $REPLY in
            1 ) echo 'Listing projects/modules to file '${JENKINS_PROJECTS_STATUS_FILE}_${startTimeExt}
                java -jar jenkins-cli.jar -auth ${apiUser}:${apiToken} -s $JENKINS_URL groovy = <$GROOVY_LIST_PROJECTS_STATUS_FILE | tee "${JENKINS_PROJECTS_STATUS_FILE}_${startTimeExt}"
                echo -e '\nFind projects/modules list in file '${JENKINS_PROJECTS_STATUS_FILE}_${startTimeExt}'\n'
                break;;
            2 ) echo 'Restoring projects/modules state (enabled/disabled) due to a list...'
                read -p 'Enter a list path/filename: ' listFile
                if ! [ -f $listFile ]; then 'The path or/and the file name is incorrect !'; break
                else
                    java -jar jenkins-cli.jar -auth ${apiUser}:${apiToken} -s $JENKINS_URL groovy = <$GROOVY_LIST_PROJECTS_STATUS_FILE | tee "${JENKINS_PROJECTS_STATUS_FILE}_before_restoring_state_${startTimeExt}"
                    echo 'Restoring projects/modules state (enabled/disabled) due to a list '$listFile | tee "${JOB_STATE_RESTORE_LOG}_${startTimeExt}"
                    cat $listFile | while read line
                    do
                       jobFullName=$(echo $line | gawk --field-separator ',' '{print $1}')
                       jobState=$(echo $line | gawk --field-separator ',' '{print $2}' | gawk --field-separator ': ' '{print $2}')
                       #echo $jobFullName | sed 's/\//\\\//g'
                       sed --in-place  "s/^String jobInjectedName.*/String jobInjectedName = \'$(echo $jobFullName | sed 's/\//\\\//g')\'/g" $GROOVY_JOB_STATE_RESTORE_FILE
                       sed --in-place "s/^Boolean jobInjectedState.*/Boolean jobInjectedState = $jobState/g" $GROOVY_JOB_STATE_RESTORE_FILE
                       java -jar jenkins-cli.jar -auth ${apiUser}:${apiToken} -s $JENKINS_URL groovy = <$GROOVY_JOB_STATE_RESTORE_FILE | tee --append "${JOB_STATE_RESTORE_LOG}_${startTimeExt}"
                       #break
                    done
                fi
                break;;
            3 ) echo 'Disabling all projects and modules...'
                java -jar jenkins-cli.jar -auth ${apiUser}:${apiToken} -s $JENKINS_URL groovy = <$GROOVY_DISABLE_ALL_PROJECTS_FILE | tee "${JENKINS_PROJECTS_STATUS_FILE}_before_disabling_${startTimeExt}"
                echo -e '\nFind projects/modules status from before disabling in file '${JENKINS_PROJECTS_STATUS_FILE}_before_disabling_${startTimeExt}'\n'
                break;;
            4 ) groovyExp=''; read -p 'Enter groovy expression: ' groovyExp;
                echo -e -n 'groovy expression: '; echo $groovyExp | tee groovy.tmp
                java -jar jenkins-cli.jar -auth ${apiUser}:${apiToken} -s $JENKINS_URL groovy = <groovy.tmp
                break;;
            5 ) echo -e '\nQuitting the script...\n'; exit;;
            * ) echo -e '\n Choose a correct option (number), pls.\n'; break;;
        esac
    done
done

