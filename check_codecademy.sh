set -v
date
# two hours between calls when the system is not functioning properly
min_secs_between_calls=120
cur_time=$(date +"%s")
echo $cur_time
URL="https://graphite.codecademy.com/render?target=stats.gauges.management_service.pools.standby.size&from=-5minutes&format=csv" 

curl -k -q "$URL" > result.csv 2>/dev/null
num_lines=$(wc -l result.csv | awk '{ print $1 }')

if ((num_lines < 5 )) ; then 
  echo "insufficient lines"
  cat result.csv > ${d}.bad.csv
  exit 0; 
fi

awk -F',' ' ($3 ~ /[0-9]+/) && ($3 < 200) { printf "%d are standby. LOW!\n", $3 }' < result.csv | tail -n 1 > result.shit
num_lines=$(wc -l result.shit | awk '{ print $1 }')
echo "NUM BAD " $num_lines
if (( num_lines > 0 )) ; then 
  echo "see see is messed up: $(cat result.shit)" > call.txt
  cat result.csv > ${d}.result.bad.csv
  cat result.shit > ${d}.result.shit
  old_date=$(cat last_call)
  if ((cur_time > (old_date + min_secs_between_calls) )) ; then
    echo $cur_time > last_call
    echo "calling varun"
    # varun
    cat call.txt | ./twilio-call 617-821-1402
    echo "calling jeff"
    # jeff
    cat call.txt | ./twilio-call 858-405-1376
    echo "$cur_time" > last_call
  fi
else
  # if standby is above threshold, reset last call to 0 again, so we immediately get a call if it drops
  echo 1460600000 > last_call
fi
