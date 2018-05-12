function ipclass(ip){
if ($1 <= 127)
	print"class A "
else if ($1 <= 128 && $1 <=191 )
	print"class B"
else if ($1 <= 192 && $1 <= 223)
	print"class C"
else if ($1 <= 224 && $1 <= 239 )
	print"class D"
else if ($1 <= 240 && $1 <= 255)
	print"class E "
else print("invalid ip")
return ip
}
{print "ip address is " ipclass($1)}
