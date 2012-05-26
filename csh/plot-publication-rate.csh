#!/bin/tcsh
#=======================================================================
#+
# NAME:
#   plot_publication_rate.csh
#
# PURPOSE:
#   Plot cumulative no. of papers with time.
#
# COMMENTS:
#
# INPUTS:
#
# OPTIONAL INPUTS:
#  -h                 Print help
#  --phd              Plot from start of Phil's phd (10/2000)
#  --name             First scrapeADS for author's name
#  --exponential      Use exponential model [def = power law]
#  --double  dt       Provide doubling time of exponential model
#                       [def is to estimate it from data]
#  --ref-date string  Plot this date as a vertical reference line.
#                       [format of string must be MM/YYYY]  
#
# OUTPUTS:
#   stdout
#
# EXAMPLES:
#   Phil:
#     plot-publication-rate.csh body_publications.tex --ref-date 10/2006 --phd
#   Tommaso:
#     plot-publication-rate.csh --name "Treu,T" --double 1.7 --ref-date01/2004
#
# BUGS:
#
# REVISION HISTORY:
#   2008-01-12  started Marshall (UCSB)
#-
#=======================================================================
# Options and arguments:

set phd = 0
set help = 0
set name = 0
set model = powerlaw
set halflife = 0
set database = 0
set refdate = 0

# Escape defaults
unset noclobber
unalias rm

while ( $#argv > 0 )
   switch ($argv[1])
   case -h:
      set help = 1
      shift argv
      breaksw
   case --help:
      set help = 1
      shift argv
      breaksw
   case --double:
      shift argv
      set halflife = $argv[1]
      shift argv
      breaksw
   case --phd:
      set phd = 1
      shift argv
      breaksw
   case --exponential:
      set model = exponential
      shift argv
      breaksw
   case --ref-date:
      shift argv
      set refdate = $argv[1]
      shift argv
      breaksw
   case -n:
      shift argv
      set name = $argv[1]
      shift argv
      breaksw
   case --{name}:
      shift argv
      set name = $argv[1]
      shift argv
      breaksw
   case *:
      set database = $argv[1]
      shift argv
      breaksw
   endsw
end

#-----------------------------------------------------------------------

# Catch stupidities, set up variables:

if ($help) then
  print_script_header.csh $0
  goto FINISH
endif

if ($name != 0) then
# Check for database:
  set database = "${name}-allyears.bib"
  if (! -e $database) then
    echo "Downloading publications database:"
    scrapeADS -r -m 1000 -a "$name" 
    set database = `\ls -tr *.bib | tail -1`
  endif  
  echo "Publications database: $database"
else
  set name = Marshall
endif  

if ($database == 0) then
  print_script_header.csh $0
  goto FINISH
endif


# Extract astroph numbers!
  # \texttt{astro-ph/0810.3934}
  # \texttt{astro-ph/0405232}
  # eprint = {0705.1007}
  # eprint = {arXiv:astro-ph/0701114}

set nmissing = 0
\rm -f junk
if ($database:e == 'bib') then

  \rm -f junk*
  set surname = `echo $name | sed s/','/' '/g | awk '{print $1}'`
  
  set lines = `grep -n 'ARTICLE' $database | cut -d':' -f1`    
     
  foreach line ( $lines )
    set date = `tail -n +$line $database | head -n 20 | \
     grep 'eprint' | head -1 | \
     sed s%'arXiv:astro-ph/'%%g | sed s%'arXiv:hep-ph/'%%g | \
     cut -d'{' -f2 | cut -d'}' -f1 | cut -c1-4`
     
#      echo "line = $line, date = $date"
     
    if ($#date > 0) then
      echo $date >> junk1
      tail -n +$line $database | head -n 30 | \
       grep author | head -1 | cut -d'{' -f3 | cut -d'}' -f1 |\
       sed s/$surname/999/g | \
       awk '{if ($1 == 999) print 1; else print 0}' >> junk2
#   Otherwise, leave it out!
    else
      @ nmissing ++   
    endif
#     echo -n `tail -1 junk1` ; tail -1 junk2 
    
  end   
    
else

  set i = `grep -n 'begin{revnumerate}' $database | cut -d':' -f1`
  set j = `grep -n 'end{revnumerate}' $database | cut -d':' -f1`
  @ n = $j - $i
  tail -n +$i $database | head -$n | \
     grep 'astro-ph' | cut -d'/' -f2 | cut -d'}' -f1 | \
     cut -c1-4 > junk1

#   set index = `grep 'astro-ph' junk | cut -d'/' -f2 | cut -d'}' -f1 | \
#                  cut -c1-4 | sort -n`

  set surname = `echo $name | sed s/','/' '/g | awk '{print $1}'`
  tail -n +$i $database | head -$n | \
     grep '\\item' | grep -v '%' | sed s/item//g | sed s/textbf//g | \
     sed s/\\\\//g | sed s/'{'//g | sed s/'}'//g | cut -d',' -f1 | \
     sed s/$surname/999/g | \
     awk '{if ($1 == 999) print 1; else print 0}' > junk2
#      awk '{print $1}' > junk2
  
endif

# Deal with wraparound:

\rm -f junk3
foreach index ( `cat junk1` )
  set decade = `echo $index | cut -c1`
  if ($decade < 2) then
    set index = "20$index"
  else
    set index = "19$index"
  endif 
# Update this script in 2020!
  echo $index >> junk3
end
mv junk3 junk1

# Make 2 column file, date and firstauthor flag:
paste junk1 junk2 | sort -n > junk

set index = `cat junk | awk '{print $1}'`
set firstauthor = `cat junk | awk '{print $2}'`
# \rm -f junk*

# Ok, got sorted indices!
echo "Found $#index refereed publications"
if ($nmissing > 0) echo "WARNING: $nmissing publications not arxived/plotted"

# Mark halfway point - current number of papers divided by 2:
@ halfn = $#index / 2

# Write plottable text file, pub no. vs time (years since first paper):

set output = ${database:r}_publication-rate.txt ; \rm -f $output
set foutput = ${database:r}_first-author-publication-rate.txt ; \rm -f $foutput
echo "# time/years  pub_no."  > $output 
echo "# time/years  pub_no."  > $foutput 
set ii = 0
foreach i ( `seq $#index` )
  set year = `echo $index[$i] | cut -c1-4`
  set month = `echo $index[$i] | cut -c5-6`
  if ($i == 1) then
    echo "Date of first paper: $month/$year"
    set month0 = $month
    set year0 = $year
  endif  
  set t = `echo $year $month | awk '{print (($1 - '$year0')*12 + ($2 - '$month0'))/12.0 }'`
#   echo "${index[$i]}: appeared $month/$year, t = $t"
  if ($i == 1) then
    if ($phd) then
      set tstart = `echo 2000 10 | awk '{print (($1 - '$year0')*12 + ($2 - '$month0'))/12.0 }'`
      echo "PhD start date: 10/2000, $tstart years after first paper"
    else
      set tstart = $t
    endif
    echo "$tstart    0"  >> $output 
  else 
  endif  
  if ($i == $halfn) then
    set halft = $t
  endif  
  echo "$t    $i"  >> $output
  if ($firstauthor[$i] == 1) then
    @ ii ++
    echo "$t    $ii"  >> $foutput
  endif  
end 

# Set limits for plot: 
  
set xmin = $tstart  
# set xmax = `date +%Y | awk '{print $1 - '$year0'}'`  
set yearnow = `date +%Y`
set monthnow = `date +%m`
set xmax = `echo $yearnow $monthnow | awk '{print (($1 - '$year0')*12 + ($2 - '$month0'))/12.0 }'`
set ymin = 0.0
set ymax = `echo $i | awk '{print $1 * 1.1}'`  
  
# MODEL CURVES!

if ($model == "exponential") then  
  
  if ($halflife == 0) then
  # Estimate half-life, tabulate exponential:
    set halflife = `echo $t $halft | awk '{print ($1 - $2)/log(2.0)}'`
  endif
  # Make sure curve goes through halfway point...
  set A = `echo $halfn $halft $halflife | awk '{print $1/exp($2/$3)}'`
  echo "Doubling time: ($t - $halft) years"
  echo "Time constant for exp model: t0 = $halflife years"
  echo "Value of exp model at t=tau: A = $A x e papers"

  set model = $output:r.model ; \rm -f $model
  echo "# time/years  pub_no."  > $model
  set dt = `echo $xmin $xmax | awk '{print ($2 - $1)/99.0}'`
  foreach i ( `seq 100` )
    set t = `echo $i | awk '{print '$xmin' + ($1 - 1)*'$dt'}'`
    set m = `echo $t $A | awk '{print $2*exp($1/('$halflife'))}'`
    echo "$t  $m" >> $model
  end

else

  set z1 = `tail -1 $foutput`
  set A = `echo $z1 | awk '{printf "%4.2f", ($2-1.0)/$1}'`
  set string1 = "publication rate = $A per year"
  echo "First-author "$string1
  set z2 = `tail -1 $output`
  set t2 = $z2[1]
  set y2 = $z2[2]
  set t1 = $halft
  set y1 = $halfn
  set n = `echo $y1 $y2 $A $t1 $t2 | \
           awk '{printf "%4.2f", log(($2-$3*$5)/($1-$3*$4))/log($5/$4)}'`
  set t0 = `echo $t1 $y1 $A $n | \
            awk '{printf "%4.2f", exp(log($1) - log($2-$3*$1)/$4)}'`
  echo "Other-author power-law scale time = $t0 years"
  set string2 = "power-law index N = $n"
  echo "Other-author "$string2
  echo "  Completely connected network:               N < 1 "
  echo "  Giant component + subgroups O[1]:       1 < N < 2 "
  echo "  Giant component + subgroups O[log n]:   2 < N < 3.5 "
  echo "  No giant component:                   3.5 < N"
  echo "    (n ~ no. of collaborators)"

  set fmodel = $output:r.fmodel ; \rm -f $fmodel
  echo "# time/years  pub_no."  > $fmodel
  echo "0.0  1.0" >> $fmodel
  echo "$z1" >> $fmodel

  set model = $output:r.model ; \rm -f $model
  echo "# time/years  pub_no."  > $model
  set nt = 30
  set dt = `echo $xmin $xmax $nt | awk '{print ($2 - $1)/($3 - 1.0)}'`
  foreach i ( `seq $nt` )
    set t = `echo $i | awk '{print '$xmin' + ($1 - 1)*'$dt'}'`
    set m = `echo $A $t $t0 $n | awk '{print 1 + $1*$2 + ($2/$3)^$4}'`
    echo "$t  $m" | grep -v 'nan' | grep -v 'NaN' >> $model
  end

endif



# Reference line (doubling date by default)
if ($refdate == 0) then 
  set reftime = $halft
else
  set refmonth = `echo $refdate | cut -d'/' -f1`
  set refyear = `echo $refdate | cut -d'/' -f2`
  set reftime = `echo $refyear $refmonth | awk '{print (($1 - '$year0')*12 + ($2 - '$month0'))/12.0 }'`
endif  
set reference = $output:r.ref ; \rm -f $reference
echo "$reftime 0.0\
$reftime $ymax" >! $reference

# Plot:

set legendfile = $output:r.legend
echo "First-author papers,\
  $string1\
Other-author papers,\
  $string2\
Reference: $refmonth/$refyear" > $legendfile
set stylefile = $output:r.style
echo "11  3  1\
5  3  2\
2  3  1\
8  3  2\
1  2  4" > $stylefile


lineplot.pl -l -ch0 1.2 $foutput $fmodel $output $model $reference \
  -o $output:r.ps \
  -xmin $tstart -ymin 0 -xmax $xmax -ymax $ymax \
  -legend $legendfile  -style $stylefile \
  -xlabel "Years since $month0/$year0" -ylabel "No. of refereed publications" \
  -title "${name}: $#index refereed, arxived papers since $month0/$year0"


FINISH:
