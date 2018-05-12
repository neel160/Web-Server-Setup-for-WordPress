BEGIN {print "NAME RATE HOURS"; print ""}
{pay = pay + $2*$3}
$2 > maxrate {maxrate = $2; maxemp = $1}
{emplist = emplist $1 " "}
{last = $0}
END {print NR " employees"
 print "total amount paid is : ", pay
 print "with the average being :", pay/NR
 print "highest paid rate is for " maxemp, " @ of : ", maxrate
 print emplist
 print ""
 print "the last employee record is : ", last} 
