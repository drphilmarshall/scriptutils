#!/bin/tcsh
# ======================================================================
#+
# NAME:
#   mailshot
#
# PURPOSE:
#   Send an email to everyone in csv file.
#
# COMMENTS:
#   Target email addresses are given in a CSV file with three columns,
#   name, firstname, email
#
# INPUTS:
#   --message msgfile     Text of message, with strings to replace
#   --subject subject     Subject line text
#   --list csvfile        CSV file of names and email addresses
#
# OPTIONAL INPUTS:
#   -h --help             Print this header
#   -v --verbose          Verbose output to stdout
#   -t --test             Only stdout, no email sent
#   --cc address          email address to cc
#
# OUTPUTS:
#   email		    Various unix mail messages
#
# EXAMPLES:
#   ./mailshot.csh -v --subject "LSST DESC Census 2018" --list test.csv --message test.email --cc dr.phil.marshall+cc@gmail.com
#
# BUGS:
#
# REVISION HISTORY:
#   2018-07-12  started Marshall (SLAC)
#-
# ======================================================================

set help = 0
set vb = 0
set test = 0
set cc = 0
set subject = 0
set msgfile = no-onewouldevernameafilelikethis
set csvfile = norwouldtheynameafilelikethis
set message = .mailshot.email
\rm -f $message

while ( $#argv > 0 )
   switch ($argv[1])
   case -h:
      shift argv
      set help = 1
      breaksw
   case --{help}:
      shift argv
      set help = 1
      breaksw
   case -v:
      shift argv
      set vb = 1
      breaksw
   case --{verbose}:
      shift argv
      set vb = 1
      breaksw
   case -t:
      shift argv
      set test = 1
      breaksw
   case -t:
      shift argv
      set test = 1
      breaksw
   case --{test}:
      shift argv
      set test = 1
      breaksw
   case --{subject}:
      shift argv
      set subject = "$argv[1]"
      shift argv
      breaksw
   case --{cc}:
      shift argv
      set cc = "$argv[1]"
      shift argv
      breaksw
   case --{message}:
      shift argv
      set msgfile = "$argv[1]"
      shift argv
      breaksw
   case --{list}:
      shift argv
      set csvfile = "$argv[1]"
      shift argv
      breaksw
   endsw
end

set OK = ()
set OK = ( $OK `@ k = $subject * 1 |& wc -l` )
set OK = ( $OK `ls $msgfile |& grep -v "No such" | wc -l` )
set OK = ( $OK `ls $csvfile |& grep -v "No such" | wc -l` )

@ problem = 1 - $OK[1] * $OK[2] * $OK[3]

if ($help || $problem) then
  more $0
  goto FINISH
endif

# Loop over all recipients:

set N = `cat $csvfile | wc -l`
@ N = $N - 1
foreach k ( `seq $N` )

    # Pull out the recipient's details:
    @ kk = $k + 1
    tail -n +$kk $csvfile | head -1 > junk
    set name = `cat junk | cut -d',' -f1`
    set surname = `cat junk | cut -d',' -f2`
    set address = `cat junk | cut -d',' -f3`

    # Prepare the message:
    cat $msgfile | sed s/NAME/$name/g > $message

    # Send the email:
    if ($vb) then
      echo "*********************************************************"
      echo "Sending email to $name $surname at ${address}:"
      if ($cc == 0) then
        echo "mail -s $subject $address < $message"
      else
        echo "mail -s $subject -c $cc $address < $message"
      endif
      # echo "Message reads:"
      # cat $message
    endif
    if ($test) then
      if ($vb) echo "(No email actually sent - this is just a test.)"
    else
      if ($cc == 0) then
        mail -s "$subject" "$address" < "$message"
      else
        mail -s "$subject" -c "$cc" "$address" < "$message"
      endif
    endif

    \rm -f $message

end

# ======================================================================
FINISH:
\rm -f junk
# ======================================================================
