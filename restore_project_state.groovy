import hudson.model.*; jenkins = Hudson.instance;
String jobInjectedName = 'some_project_name/master'
Boolean jobInjectedState = false
if (jenkins.instance.getItemByFullName(jobInjectedName) != null){
    jenkins.instance.getItemByFullName(jobInjectedName).each {
        if (it.disabled != jobInjectedState) {
            //println 'state = -->' + it.disabled + '<--   -->' + jobInjectedState + '<--'
            it.disabled = jobInjectedState
            it.save()
            if (jobInjectedState == true) {
                println jobInjectedName + ' has been disabled'
            } else {
                println jobInjectedName + ' has been enabled'
            }
        } else {
            if (jobInjectedState == true) {
                println jobInjectedName + ' remains disabled'
            } else {
                println jobInjectedName + ' remains enabled'
            }
        }
    }
} else {
    println 'Issue: ' + jobInjectedName + ' has not been found'
}

