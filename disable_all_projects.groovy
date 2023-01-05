import hudson.model.*
jenkins = Hudson.instance
jenkins.instance.getAllItems(AbstractItem.class).each {
    println it.fullName + ', Disabled: ' + it.disabled + ', class: ' + it.class.name
    if (it.class.name != 'com.cloudbees.hudson.plugins.folder.Folder') {
        it.disabled = true
        it.save()
    }
}

