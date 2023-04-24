#!/bin/bash


API_KEY=""
LAT=
LON=
OPENHAB_REST_API=http://192.168.100.10:8080/rest
MAPPING="\
  .daily[0].temp.max|Weather_Temp_Max \
  .daily[0].temp.min|Weather_Temp_Min \
"
#
### DON'T EDIT BELOW THIS LINE ###
#

if [ -f .env ]; then
  export $(echo $(cat .env | sed 's/#.*//g'| xargs) | envsubst)
fi

CLEAN_UP=0

if [[ -z "$TEST_DATA" ]]; then
  DATA_FILE=`mktemp /tmp/weather.XXXXXX`
  curl "https://api.openweathermap.org/data/3.0/onecall?lat=${LAT}&lon=${LON}&exclude=&appid=${API_KEY}&units=metric&lang=de" > $DATA_FILE
  CLEAN_UP=1
else
  DATA_FILE=$TEST_DATA
fi

for LINE in $MAPPING; do
  col=(${LINE//|/ })
  FILTER=${col[0]}
  ITEM=${col[1]}

  VALUE=$(jq "${FILTER}" $DATA_FILE)

  curl -X PUT --header "Content-Type: text/plain" \
    --header "Accept: application/json" \
    -d "${VALUE}" "${OPENHAB_REST_API}/items/${ITEM}/state"

done

[[ $CLEAN_UP -eq 1 ]] && rm $DATA_FILE

