import hudson.model.*
jenkins = Hudson.instance
jenkins.instance.getAllItems(AbstractItem.class).each {
    println it.fullName + ', Disabled: ' + it.disabled + ', class: ' + it.class.name
}

