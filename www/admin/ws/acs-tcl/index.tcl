# test APIs from acs-tcl

<ws>namespace init ::testoacs

<ws>element sequence testoacs::Param {
    {Name} 
    {Value {minOccurs 0}}
}

<ws>element sequence testoacs::Param2 {
    {Name}
    {Value {minOccurs 0 nillable true} }
}

<ws>proc ::testoacs::ADConn {
    {Parameter {minOccurs 0 default "all" maxOccurs 20} }
    {NamesOnly:boolean {minOccurs 0 default "0"} }
} {
    set ReturnList [list]
    if {[lsearch -exact $Parameter "all"] > -1} {
	foreach {Name Value} [ad_conn -get all] {
            if {$NamesOnly} {
                set Value ""
            }
            lappend ReturnList [list $Name $Value]
        }
    } else {
        foreach Param $Parameter {
            if {"$Param" eq "form"} {
                lappend ReturnList [list form ""]
                continue
            }
            if {$NamesOnly} {
                lappend ReturnList [list $Param ""]
            } else {
                lappend ReturnList [list $Param [ad_conn -get $Param]]
            }
        }
    }
    return $ReturnList
} returns {{Parameter:elements::testoacs::Param {maxOccurs 20}}}

# Documentation for ADConn Operation:
<ws>doc operation testoacs ADConnOperation "Return connection parameter names and/or values maintained in ad_conn for the current conn"

<ws>proc ::testoacs::ObjectTypeHierarchy {
    {ObjectType {default "user"} }
} {

    return "<!\[CDATA\[ [acs_object_type_hierarchy -object_type $ObjectType] \]\]>"
} 

# ACS Object Operations
<ws>proc ::testoacs::ObjectName {
    {ObjectID:integer}
} {

    return [list $ObjectID [acs_object_name $ObjectID]]

} returns {
    {ObjectID:integer }
    {ObjectName {minOccurs 0}}
}

<ws>proc ::testoacs::ObjectType {
    {ObjectID:integer}
} {
    return [list $ObjectID [acs_object_type $ObjectID]]
} returns {
    {ObjectID:integer}
    {ObjectType {minOccurs 0 default "Not Found"}}
}

<ws>proc ::testoacs::ObjectGet {
    {ObjectID:integer}
    {NamesOnly:boolean {default 0 minOccurs 0} }
} {
    set ResultList [list]

    if {[acs_object_type $ObjectID] ne ""} {
        ::acs_object::get -object_id $ObjectID -array ObjectArray
    }

    if {[array exists ObjectArray]} {
        if {$NamesOnly} {
            set ResultList [array names ObjectArray]
        } else {
	    foreach {Name Value} [array get ObjectArray] {
                lappend ResultList [list $Name $Value]
            }
        }
    } 

    return $ResultList

} returns {
    {Attribute:elements::testoacs::Param {minOccurs 0 maxOccurs 40} }
}


<ws>proc ::testoacs::ObjectGetAttributes {
    {ObjectID:integer}
    {Attribute {maxOccurs 40} }
} {
    set ResultList [list]

    if {[acs_object_type $ObjectID] ne ""} {
        ::acs_object::get -object_id $ObjectID -array ObjectArray
        foreach AttributeName $Attribute {
            if {[info exists ObjectArray($AttributeName)]} {
                lappend ResultList [list $AttributeName $ObjectArray($AttributeName)]
            } else {
                lappend ResultList [list $AttributeName "Not Found"]
            }
        }
    }
    
    return [list $ObjectID $ResultList]

} returns {
    {ObjectID:integer}
    {Param:elements::testoacs::Param2 {maxOccurs 40} }
}


<ws>namespace finalize ::testoacs

<ws>return ::testoacs

