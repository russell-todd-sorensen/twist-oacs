namespace eval ::twist {
}

namespace eval ::twist::install {

    variable installed 0
    variable version "0.9.30"
    variable package "twist"
    variable sourceDirectory [ns_info tcllib] 
    variable packageDirectory [file dirname [file dirname [info script]]]
    variable versionDirectory [file join $sourceDirectory $package $package-$version]
    variable linkWebservices 0
    variable linkDocumentation 0
}
 
proc ::twist::install::init { } {
    
    # Ensure variables are up-to-date with database:
    variable package twist
    variable installed [parameter::get_from_package_key -package_key $package -parameter installed -default 0]
    variable upgradeNow [parameter::get_from_package_key -package_key $package -parameter upgradeNow -default 0]
    variable version [parameter::get_from_package_key -package_key $package -parameter version -default 0.9.10]
    variable sourceDirectory [parameter::get_from_package_key -package_key $package -parameter sourceDirectory -default ""]
    if {"$sourceDirectory" eq ""} {
        set sourceDirectory [ns_info tcllib]
        if {$installed} {
            parameter::set_from_package_key -package_key $package -parameter sourceDirectory -value $sourceDirectory
        }
    }
    variable versionDirectory [file join $sourceDirectory $package $package-$version]
    variable linkWebservices [parameter::get_from_package_key -package_key $package -parameter linkWebservices -default 0]
    variable linkDocumentation [parameter::get_from_package_key -package_key $package -parameter linkDocumentation -default 1]
    return $installed
}


proc ::twist::install::before-install { } {

    variable version
    variable package
    variable versionDirectory

    # initialize
    init

    # Checkout:
    # exec http:///$package-$version $versionDirectory
    # provide a replacement for the above command 
    
}

proc ::twist::install::deleteFileLink { linkName } {

    if {[file exists $linkName]} {
        if {"[file type $linkName]" eq "link"} {
            file delete $linkName
        } else {
            return -code error "::twist::install::after-install attempt to delete file of type '[file type $linkName]' named '$linkName'"
        }
    } else {
        # May not be able to see links which are bad:
        file delete $linkName
    }

}

proc ::twist::install::updateFileLink {
    linkName
    newTarget
} {
    ns_log Notice "::twist::install::updateFileLink linkName '$linkName' --> '$newTarget'"
    deleteFileLink $linkName
    
    file link $linkName $newTarget
}

proc ::twist::install::after-install { } {

    variable sourceDirectory
    variable packageDirectory
    variable versionDirectory
    variable linkWebservices
    variable linkDocumentation
    
    # initialize
    init

    # link in web services
    if {$linkWebservices} {
        set linkName [file join $packageDirectory www ws]
        set newTarget [file join $versionDirectory packages wsapi www]
        updateFileLink $linkName $newTarget  
    }
    # link documentation
    if {$linkDocumentation} {
        set linkName [file join $packageDirectory www doc twist]
        set newTarget [file join $versionDirectory packages doc www]
        updateFileLink $linkName $newTarget
    }
}

proc ::twist::install::upgrade-version {  } {

    ::twist::install::before-install

}
    
