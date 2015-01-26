#!/bin/bash
set -x
DN="dc=umich,dc=edu?uid=dlhainesXXX"
#H="ldap://ldap.itd.umich.edu:389/dc=umich,dc=edu"
H="ldap://ldap.itd.umich.edu:389"
#ldapwhoami -v -x -H $H -D $DN
#ldapwhoami -vvv -h <hostname> -p <port>  -D <binddn> -x -w <passwd> where binddn is the DN of the person whose credentials you are authenticating
#ldapwhoami -x -D "cn=Manager,dc=example,dc=com" -W

#ldap://ldap.itd.umich.edu/ou=People,dc=umich,dc=edu?title,postalAddress,telephoneNumber,facsimileTelephoneNumber,mail,onVacation,vacationMessage,drink?sub?uid=pturgyan

#ldapsearch -x -h medusa.lngs.itd.umich.edu -p 389 -b '' -s sub -D"cn=slurpduser,o=services" -W uid=pturgyan

##ldapsearch -H ldaps://ldap-dev.itd.umich.edu:4444 -D"uid=xpaul,ou=people,dc=umich,dc=edu" -W -x -LLL uid=xpaul mailforwardingaddress
# this seems to work but only gives single dn: entry.
#ldapsearch -H ldap://ldap.itd.umich.edu:389 -D"uid=dlhaines,ou=people,dc=umich,dc=edu" -L uid=dlhaines mailforwardingaddress
### This does work :-):-)
#ldapsearch -H ldap://ldap.itd.umich.edu:389 -D"uid=dlhaines,ou=people,dc=umich,dc=edu" -L uid=dlhaines
## try to get group
#F='(&(cn=ctsupportstaff) (objectclass=rcf822MailGroup))'
######
## The following works to get the members
#F=(cn=ctsupportstaff)
#ldapsearch -H ldap://ldap.itd.umich.edu:389 -D"ou=Groups,dc=umich,dc=edu" -L $F
######

### works to get only members
F='(&(cn=ctsupportstaff)(objectclass=rfc822MailGroup))'
ldapsearch -H ldap://ldap.itd.umich.edu:389 -D"ou=Groups,dc=umich,dc=edu" -L $F member


# does not work to find membership
#ldapsearch -v  -H ldap://ldap.itd.umich.edu:389 -D"ou=Groups,dc=umich,dc=edu,uid=dlhaines" -L $F member

## suggested to find membership:
#ldapsearch -x -D "ldap_user" -w "user_passwd" -b "cn=jdoe,dc=example,dc=local" -h ldap_host '(memberof=cn=officegroup,dc=example,dc=local)'



# this gets "administrativei limit exceeded"
#ldapsearch -H ldap://ldap.itd.umich.edu:389 -D"uid=dlhaines,ou=people,dc=umich,dc=edu" -L

#### http://ds.med.umich.edu/idmt/dev_ldap_authentication.html
## group search example from med
#filter: "(&(objectClass=Group)(|(cn=mcit-iso*)(cn=umhs*))(member=cn=darthvader,ou=people,dc=med,dc=umich,dc=edu))"

#### sample
#Enter LDAP Password:
#dn: uid=xpaul,ou=People,dc=umich,dc=edu
#mailForwardingAddress: pturgyan@quince.ifs.umich.edu
#mailForwardingAddress: xpaul@med.umich.edu
#ldapsearch -H ldaps://ldap-dev.itd.umich.edu:4567 -x -W -LLL -D"uid=xpaul,ou=People,dc=umich,dc=edu" uid=xpaul mailforwardingaddress
#Enter LDAP Password:
#dn: uid=xpaul,ou=People,dc=umich,dc=edu
#mailForwardingAddress: xpaul@da.dir.3456

F='(&(cn=TL-Latte-admin-test)(objectclass=rfc822MailGroup))'
#F='(cn=TL-Latte-admin-test)'
#ldapsearch -H ldap://ldap.itd.umich.edu:389 -D"ou=Groups,dc=umich,dc=edu" -L $F member
ldapsearch -H ldap://ldap.itd.umich.edu:389 -D"ou=Groups,dc=umich,dc=edu" -L $F member
