#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${DIR}/../../scripts/utils.sh

if [ ! -f ${DIR}/vertica-jdbc.jar ]
then
     # install deps
     log "Getting vertica-jdbc.jar from vertica-client-10.0.1-0.x86_64.tar.gz"
     wget https://www.vertica.com/client_drivers/10.0.x/10.0.1-0/vertica-client-10.0.1-0.x86_64.tar.gz
     tar xvfz ${DIR}/vertica-client-10.0.1-0.x86_64.tar.gz
     cp ${DIR}/opt/vertica/java/lib/vertica-jdbc.jar ${DIR}/
     rm -rf ${DIR}/opt
     rm -f ${DIR}/vertica-client-10.0.1-0.x86_64.tar.gz
fi


if [ ! -f ${DIR}/producer/target/producer-1.0.0-jar-with-dependencies.jar ]
then
     log "Building jar for producer"
     docker run -i --rm -e TAG=$TAG_BASE -e KAFKA_CLIENT_TAG=$KAFKA_CLIENT_TAG -v "${DIR}/producer":/usr/src/mymaven -v "$HOME/.m2":/root/.m2 -v "${DIR}/producer/target:/usr/src/mymaven/target" -w /usr/src/mymaven maven:3.6.1-jdk-11 mvn package
fi

${DIR}/../../environment/plaintext/start.sh "${PWD}/docker-compose.plaintext.repro-tombstone.yml"


sleep 60

log "Sending messages to topic customer using java producer from connect-vertica-sink/producer"

log "Creating JDBC Vertica sink connector"
curl -X PUT \
     -H "Content-Type: application/json" \
     --data '{
               "connector.class" : "io.confluent.connect.jdbc.JdbcSinkConnector",
                    "tasks.max" : "1",
                    "connection.url": "jdbc:vertica://vertica:5433/docker?user=dbadmin&password=",
                    "auto.create": "true",
                    "pk.mode": "record_key",
                    "pk.fields": "ID",
                    "auto.create": true,
                    "auto.evolve": false,
                    "key.converter": "org.apache.kafka.connect.converters.LongConverter",
                    "value.converter" : "Avro",
                    "value.converter.schema.registry.url":"http://schema-registry:8081",
                    "topics": "customer"
          }' \
     http://localhost:8083/connectors/jdbc-vertica-sink/config | jq .

sleep 10

log "Check data is in Vertica"
docker exec -i vertica /opt/vertica/bin/vsql -hlocalhost -Udbadmin << EOF
select * from customer;
EOF

#  ListID | NormalizedHashItemID | URL  |   MyFloatValue    |  MyTimestamp  | ID
# --------+----------------------+------+-------------------+---------------+-----
#       0 |                    0 | url0 | 0.282263566813515 | 1594893927354 |   0
#       1 |                    1 | url1 | 0.282263566813515 | 1594893930327 |   1
#       1 |                    1 | url1 | 0.282263566813515 | 1594893930327 |   2
#       3 |                    3 | url3 | 0.282263566813515 | 1594893932340 |   3
#       4 |                    4 | url4 | 0.282263566813515 | 1594893933349 |   4
#       5 |                    5 | url5 | 0.282263566813515 | 1594893934354 |   5
#       6 |                    6 | url6 | 0.282263566813515 | 1594893935360 |   6
#       7 |                    7 | url7 | 0.282263566813515 | 1594893936366 |   7
#       8 |                    8 | url8 | 0.282263566813515 | 1594893937373 |   8
#       9 |                    9 | url9 | 0.282263566813515 | 1594893938379 |   9
#       0 |                    0 | url0 | 0.282263566813515 | 1594893939389 |  10
#       1 |                    1 | url1 | 0.282263566813515 | 1594893940394 |  11
#       1 |                    1 | url1 | 0.282263566813515 | 1594893940394 |  12
#       3 |                    3 | url3 | 0.282263566813515 | 1594893942421 |  13
#       4 |                    4 | url4 | 0.282263566813515 | 1594893943428 |  14
#       5 |                    5 | url5 | 0.282263566813515 | 1594893944436 |  15
#       6 |                    6 | url6 | 0.282263566813515 | 1594893945445 |  16
#       7 |                    7 | url7 | 0.282263566813515 | 1594893946455 |  17
#       8 |                    8 | url8 | 0.282263566813515 | 1594893947461 |  18
#       9 |                    9 | url9 | 0.282263566813515 | 1594893948469 |  19
#       0 |                    0 | url0 | 0.282263566813515 | 1594893949475 |  20
#       1 |                    1 | url1 | 0.282263566813515 | 1594893950484 |  21
#       1 |                    1 | url1 | 0.282263566813515 | 1594893950484 |  22
#       3 |                    3 | url3 | 0.282263566813515 | 1594893952496 |  23
#       4 |                    4 | url4 | 0.282263566813515 | 1594893953503 |  24
#       5 |                    5 | url5 | 0.282263566813515 | 1594893954511 |  25
#       6 |                    6 | url6 | 0.282263566813515 | 1594893955488 |  26
#       7 |                    7 | url7 | 0.282263566813515 | 1594893956499 |  27
#       8 |                    8 | url8 | 0.282263566813515 | 1594893957505 |  28
#       9 |                    9 | url9 | 0.282263566813515 | 1594893958510 |  29
#       0 |                    0 | url0 | 0.282263566813515 | 1594893959514 |  30
#       1 |                    1 | url1 | 0.282263566813515 | 1594893960522 |  31
#       1 |                    1 | url1 | 0.282263566813515 | 1594893960522 |  32
#       3 |                    3 | url3 | 0.282263566813515 | 1594893962530 |  33
#       4 |                    4 | url4 | 0.282263566813515 | 1594893963537 |  34
#       5 |                    5 | url5 | 0.282263566813515 | 1594893964542 |  35
#       6 |                    6 | url6 | 0.282263566813515 | 1594893965549 |  36
#       7 |                    7 | url7 | 0.282263566813515 | 1594893966554 |  37
#       8 |                    8 | url8 | 0.282263566813515 | 1594893967563 |  38
#       9 |                    9 | url9 | 0.282263566813515 | 1594893968570 |  39
#       0 |                    0 | url0 | 0.282263566813515 | 1594893969577 |  40
#       1 |                    1 | url1 | 0.282263566813515 | 1594893970586 |  41
#       1 |                    1 | url1 | 0.282263566813515 | 1594893970586 |  42
#       3 |                    3 | url3 | 0.282263566813515 | 1594893972603 |  43
#       4 |                    4 | url4 | 0.282263566813515 | 1594893973609 |  44
#       5 |                    5 | url5 | 0.282263566813515 | 1594893974619 |  45
#       6 |                    6 | url6 | 0.282263566813515 | 1594893975625 |  46
#       7 |                    7 | url7 | 0.282263566813515 | 1594893976630 |  47
#       8 |                    8 | url8 | 0.282263566813515 | 1594893977635 |  48
#       9 |                    9 | url9 | 0.282263566813515 | 1594893978641 |  49
#       0 |                    0 | url0 | 0.282263566813515 | 1594893979647 |  50
#       1 |                    1 | url1 | 0.282263566813515 | 1594893980653 |  51
#       1 |                    1 | url1 | 0.282263566813515 | 1594893980653 |  52
#       3 |                    3 | url3 | 0.282263566813515 | 1594893982665 |  53
#       4 |                    4 | url4 | 0.282263566813515 | 1594893983670 |  54
#       5 |                    5 | url5 | 0.282263566813515 | 1594893984674 |  55
#       6 |                    6 | url6 | 0.282263566813515 | 1594893985645 |  56
#       7 |                    7 | url7 | 0.282263566813515 | 1594893986649 |  57
#       8 |                    8 | url8 | 0.282263566813515 | 1594893987654 |  58
#       9 |                    9 | url9 | 0.282263566813515 | 1594893988660 |  59
#       0 |                    0 | url0 | 0.282263566813515 | 1594893989666 |  60
#       1 |                    1 | url1 | 0.282263566813515 | 1594893990672 |  61
#       1 |                    1 | url1 | 0.282263566813515 | 1594893990672 |  62
#       3 |                    3 | url3 | 0.282263566813515 | 1594893992686 |  63
#       4 |                    4 | url4 | 0.282263566813515 | 1594893993691 |  64
#       5 |                    5 | url5 | 0.282263566813515 | 1594893994695 |  65
#       6 |                    6 | url6 | 0.282263566813515 | 1594893995700 |  66
#       7 |                    7 | url7 | 0.282263566813515 | 1594893996705 |  67
#       8 |                    8 | url8 | 0.282263566813515 | 1594893997710 |  68
#       9 |                    9 | url9 | 0.282263566813515 | 1594893998714 |  69
#       0 |                    0 | url0 | 0.282263566813515 | 1594893999719 |  70
#       1 |                    1 | url1 | 0.282263566813515 | 1594894000724 |  71
#       1 |                    1 | url1 | 0.282263566813515 | 1594894000724 |  72
#       3 |                    3 | url3 | 0.282263566813515 | 1594894002735 |  73
#       4 |                    4 | url4 | 0.282263566813515 | 1594894003742 |  74
#       5 |                    5 | url5 | 0.282263566813515 | 1594894004746 |  75
#       6 |                    6 | url6 | 0.282263566813515 | 1594894005750 |  76
#       7 |                    7 | url7 | 0.282263566813515 | 1594894006756 |  77
#       8 |                    8 | url8 | 0.282263566813515 | 1594894007761 |  78
#       9 |                    9 | url9 | 0.282263566813515 | 1594894008768 |  79
#       0 |                    0 | url0 | 0.282263566813515 | 1594894009776 |  80
#       1 |                    1 | url1 | 0.282263566813515 | 1594894010781 |  81
#         |                      |      |                   |               |  82
#       3 |                    3 | url3 | 0.282263566813515 | 1594894012791 |  83
#       4 |                    4 | url4 | 0.282263566813515 | 1594894013798 |  84
#       5 |                    5 | url5 | 0.282263566813515 | 1594894014806 |  85
#       6 |                    6 | url6 | 0.282263566813515 | 1594894015778 |  86
#       7 |                    7 | url7 | 0.282263566813515 | 1594894016786 |  87
#       8 |                    8 | url8 | 0.282263566813515 | 1594894017795 |  88
#       9 |                    9 | url9 | 0.282263566813515 | 1594894018800 |  89
#       0 |                    0 | url0 | 0.282263566813515 | 1594894019804 |  90
#       1 |                    1 | url1 | 0.282263566813515 | 1594894020811 |  91
#         |                      |      |                   |               |  92
#       3 |                    3 | url3 | 0.282263566813515 | 1594894022835 |  93
#       4 |                    4 | url4 | 0.282263566813515 | 1594894023841 |  94
#       5 |                    5 | url5 | 0.282263566813515 | 1594894024846 |  95
#       6 |                    6 | url6 | 0.282263566813515 | 1594894025850 |  96
#       7 |                    7 | url7 | 0.282263566813515 | 1594894026855 |  97
#       8 |                    8 | url8 | 0.282263566813515 | 1594894027859 |  98
#       9 |                    9 | url9 | 0.282263566813515 | 1594894028864 |  99
#       0 |                    0 | url0 | 0.282263566813515 | 1594894029887 | 100
#       1 |                    1 | url1 | 0.282263566813515 | 1594894030891 | 101
#         |                      |      |                   |               | 102
#       3 |                    3 | url3 | 0.282263566813515 | 1594894032899 | 103
#       4 |                    4 | url4 | 0.282263566813515 | 1594894033905 | 104
#       5 |                    5 | url5 | 0.282263566813515 | 1594894034910 | 105
#       6 |                    6 | url6 | 0.282263566813515 | 1594894035915 | 106
#       7 |                    7 | url7 | 0.282263566813515 | 1594894036922 | 107
#       8 |                    8 | url8 | 0.282263566813515 | 1594894037926 | 108
#       9 |                    9 | url9 | 0.282263566813515 | 1594894038931 | 109
#       0 |                    0 | url0 | 0.282263566813515 | 1594894039936 | 110
#       1 |                    1 | url1 | 0.282263566813515 | 1594894040940 | 111
#         |                      |      |                   |               | 112
#       3 |                    3 | url3 | 0.282263566813515 | 1594894042949 | 113
#       4 |                    4 | url4 | 0.282263566813515 | 1594894043956 | 114
#       5 |                    5 | url5 | 0.282263566813515 | 1594894044961 | 115
#       6 |                    6 | url6 | 0.282263566813515 | 1594894045933 | 116
#       7 |                    7 | url7 | 0.282263566813515 | 1594894046936 | 117
#       8 |                    8 | url8 | 0.282263566813515 | 1594894047943 | 118
#       9 |                    9 | url9 | 0.282263566813515 | 1594894048947 | 119
#       0 |                    0 | url0 | 0.282263566813515 | 1594894049953 | 120
#       1 |                    1 | url1 | 0.282263566813515 | 1594894050958 | 121
#         |                      |      |                   |               | 122
#       3 |                    3 | url3 | 0.282263566813515 | 1594894052969 | 123
#       4 |                    4 | url4 | 0.282263566813515 | 1594894053979 | 124
#       5 |                    5 | url5 | 0.282263566813515 | 1594894054983 | 125
#       6 |                    6 | url6 | 0.282263566813515 | 1594894055989 | 126
#       7 |                    7 | url7 | 0.282263566813515 | 1594894056992 | 127
#       8 |                    8 | url8 | 0.282263566813515 | 1594894057998 | 128
#       9 |                    9 | url9 | 0.282263566813515 | 1594894059003 | 129
#       0 |                    0 | url0 | 0.282263566813515 | 1594894060008 | 130
#       1 |                    1 | url1 | 0.282263566813515 | 1594894061012 | 131
#         |                      |      |                   |               | 132
#       3 |                    3 | url3 | 0.282263566813515 | 1594894063021 | 133
#       4 |                    4 | url4 | 0.282263566813515 | 1594894064024 | 134
#       5 |                    5 | url5 | 0.282263566813515 | 1594894065029 | 135
#       6 |                    6 | url6 | 0.282263566813515 | 1594894066033 | 136
#       7 |                    7 | url7 | 0.282263566813515 | 1594894067039 | 137
#       8 |                    8 | url8 | 0.282263566813515 | 1594894068043 | 138
#       9 |                    9 | url9 | 0.282263566813515 | 1594894069047 | 139
#       0 |                    0 | url0 | 0.282263566813515 | 1594894070059 | 140
#       1 |                    1 | url1 | 0.282263566813515 | 1594894071063 | 141
#         |                      |      |                   |               | 142
#       3 |                    3 | url3 | 0.282263566813515 | 1594894073070 | 143
#       4 |                    4 | url4 | 0.282263566813515 | 1594894074075 | 144
#       5 |                    5 | url5 | 0.282263566813515 | 1594894075082 | 145
#       6 |                    6 | url6 | 0.282263566813515 | 1594894076054 | 146
#       7 |                    7 | url7 | 0.282263566813515 | 1594894077059 | 147
#       8 |                    8 | url8 | 0.282263566813515 | 1594894078063 | 148
#       9 |                    9 | url9 | 0.282263566813515 | 1594894079069 | 149
#       0 |                    0 | url0 | 0.282263566813515 | 1594894080074 | 150
#       1 |                    1 | url1 | 0.282263566813515 | 1594894081082 | 151
#         |                      |      |                   |               | 152
#       3 |                    3 | url3 | 0.282263566813515 | 1594894083089 | 153
#       4 |                    4 | url4 | 0.282263566813515 | 1594894084095 | 154
#       5 |                    5 | url5 | 0.282263566813515 | 1594894085100 | 155
#       6 |                    6 | url6 | 0.282263566813515 | 1594894086104 | 156
#       7 |                    7 | url7 | 0.282263566813515 | 1594894087111 | 157
#       8 |                    8 | url8 | 0.282263566813515 | 1594894088115 | 158
#       9 |                    9 | url9 | 0.282263566813515 | 1594894089121 | 159
#       0 |                    0 | url0 | 0.282263566813515 | 1594894090125 | 160
#       1 |                    1 | url1 | 0.282263566813515 | 1594894091129 | 161
#         |                      |      |                   |               | 162
#       3 |                    3 | url3 | 0.282263566813515 | 1594894093138 | 163
#       4 |                    4 | url4 | 0.282263566813515 | 1594894094142 | 164
#       5 |                    5 | url5 | 0.282263566813515 | 1594894095146 | 165
#       6 |                    6 | url6 | 0.282263566813515 | 1594894096151 | 166
#       7 |                    7 | url7 | 0.282263566813515 | 1594894097156 | 167
#       8 |                    8 | url8 | 0.282263566813515 | 1594894098161 | 168
#       9 |                    9 | url9 | 0.282263566813515 | 1594894099168 | 169
#       0 |                    0 | url0 | 0.282263566813515 | 1594894100187 | 170
#       1 |                    1 | url1 | 0.282263566813515 | 1594894101192 | 171
#         |                      |      |                   |               | 172
#       3 |                    3 | url3 | 0.282263566813515 | 1594894103200 | 173
#       4 |                    4 | url4 | 0.282263566813515 | 1594894104205 | 174
#       5 |                    5 | url5 | 0.282263566813515 | 1594894105210 | 175
#       6 |                    6 | url6 | 0.282263566813515 | 1594894106181 | 176
#       7 |                    7 | url7 | 0.282263566813515 | 1594894107185 | 177
#       8 |                    8 | url8 | 0.282263566813515 | 1594894108192 | 178
#       9 |                    9 | url9 | 0.282263566813515 | 1594894109197 | 179
#       0 |                    0 | url0 | 0.282263566813515 | 1594894110200 | 180
#       1 |                    1 | url1 | 0.282263566813515 | 1594894111206 | 181
#         |                      |      |                   |               | 182
#       3 |                    3 | url3 | 0.282263566813515 | 1594894113216 | 183
#       4 |                    4 | url4 | 0.282263566813515 | 1594894114221 | 184
#       5 |                    5 | url5 | 0.282263566813515 | 1594894115225 | 185
#       6 |                    6 | url6 | 0.282263566813515 | 1594894116229 | 186
#       7 |                    7 | url7 | 0.282263566813515 | 1594894117235 | 187
#       8 |                    8 | url8 | 0.282263566813515 | 1594894118240 | 188
#       9 |                    9 | url9 | 0.282263566813515 | 1594894119246 | 189
#       0 |                    0 | url0 | 0.282263566813515 | 1594894120251 | 190
#       1 |                    1 | url1 | 0.282263566813515 | 1594894121255 | 191
#         |                      |      |                   |               | 192
#       3 |                    3 | url3 | 0.282263566813515 | 1594894123268 | 193
#       4 |                    4 | url4 | 0.282263566813515 | 1594894124272 | 194
#       5 |                    5 | url5 | 0.282263566813515 | 1594894125275 | 195
#       6 |                    6 | url6 | 0.282263566813515 | 1594894126279 | 196
#       7 |                    7 | url7 | 0.282263566813515 | 1594894127285 | 197
#       8 |                    8 | url8 | 0.282263566813515 | 1594894128296 | 198
#       9 |                    9 | url9 | 0.282263566813515 | 1594894129299 | 199
#       0 |                    0 | url0 | 0.282263566813515 | 1594894130303 | 200
#       1 |                    1 | url1 | 0.282263566813515 | 1594894131308 | 201
#         |                      |      |                   |               | 202
#       3 |                    3 | url3 | 0.282263566813515 | 1594894133318 | 203
#       4 |                    4 | url4 | 0.282263566813515 | 1594894134324 | 204
#       5 |                    5 | url5 | 0.282263566813515 | 1594894135295 | 205
#       6 |                    6 | url6 | 0.282263566813515 | 1594894136299 | 206
#       7 |                    7 | url7 | 0.282263566813515 | 1594894137305 | 207
#       8 |                    8 | url8 | 0.282263566813515 | 1594894138313 | 208
#       9 |                    9 | url9 | 0.282263566813515 | 1594894139323 | 209
#       0 |                    0 | url0 | 0.282263566813515 | 1594894140335 | 210
#       1 |                    1 | url1 | 0.282263566813515 | 1594894141344 | 211
#         |                      |      |                   |               | 212
#       3 |                    3 | url3 | 0.282263566813515 | 1594894143354 | 213
#       4 |                    4 | url4 | 0.282263566813515 | 1594894144359 | 214
#       5 |                    5 | url5 | 0.282263566813515 | 1594894145364 | 215
#       6 |                    6 | url6 | 0.282263566813515 | 1594894146370 | 216
#       7 |                    7 | url7 | 0.282263566813515 | 1594894147374 | 217
#       8 |                    8 | url8 | 0.282263566813515 | 1594894148378 | 218
#       9 |                    9 | url9 | 0.282263566813515 | 1594894149382 | 219
#       0 |                    0 | url0 | 0.282263566813515 | 1594894150389 | 220
#       1 |                    1 | url1 | 0.282263566813515 | 1594894151393 | 221
#         |                      |      |                   |               | 222
#       3 |                    3 | url3 | 0.282263566813515 | 1594894153400 | 223
#       4 |                    4 | url4 | 0.282263566813515 | 1594894154405 | 224
#       5 |                    5 | url5 | 0.282263566813515 | 1594894155410 | 225
#       6 |                    6 | url6 | 0.282263566813515 | 1594894156415 | 226
#       7 |                    7 | url7 | 0.282263566813515 | 1594894157420 | 227
#       8 |                    8 | url8 | 0.282263566813515 | 1594894158423 | 228
#       9 |                    9 | url9 | 0.282263566813515 | 1594894159428 | 229
#       0 |                    0 | url0 | 0.282263566813515 | 1594894160432 | 230
#       1 |                    1 | url1 | 0.282263566813515 | 1594894161436 | 231
#         |                      |      |                   |               | 232
#       3 |                    3 | url3 | 0.282263566813515 | 1594894163448 | 233
#       4 |                    4 | url4 | 0.282263566813515 | 1594894164453 | 234
#       5 |                    5 | url5 | 0.282263566813515 | 1594894165422 | 235
#       6 |                    6 | url6 | 0.282263566813515 | 1594894166428 | 236
#       7 |                    7 | url7 | 0.282263566813515 | 1594894167433 | 237
#       8 |                    8 | url8 | 0.282263566813515 | 1594894168437 | 238
#       9 |                    9 | url9 | 0.282263566813515 | 1594894169441 | 239
#       0 |                    0 | url0 | 0.282263566813515 | 1594894170445 | 240
#       1 |                    1 | url1 | 0.282263566813515 | 1594894171450 | 241
#         |                      |      |                   |               | 242
#       3 |                    3 | url3 | 0.282263566813515 | 1594894173458 | 243
#       4 |                    4 | url4 | 0.282263566813515 | 1594894174461 | 244
#       5 |                    5 | url5 | 0.282263566813515 | 1594894175465 | 245
#       6 |                    6 | url6 | 0.282263566813515 | 1594894176468 | 246
#       7 |                    7 | url7 | 0.282263566813515 | 1594894177473 | 247
#       8 |                    8 | url8 | 0.282263566813515 | 1594894178476 | 248
#       9 |                    9 | url9 | 0.282263566813515 | 1594894179480 | 249
#       0 |                    0 | url0 | 0.282263566813515 | 1594894180484 | 250
#       1 |                    1 | url1 | 0.282263566813515 | 1594894181489 | 251
#         |                      |      |                   |               | 252
#       3 |                    3 | url3 | 0.282263566813515 | 1594894183498 | 253
#       4 |                    4 | url4 | 0.282263566813515 | 1594894184510 | 254
#       5 |                    5 | url5 | 0.282263566813515 | 1594894185515 | 255
#       6 |                    6 | url6 | 0.282263566813515 | 1594894186522 | 256
#       7 |                    7 | url7 | 0.282263566813515 | 1594894187525 | 257
#       8 |                    8 | url8 | 0.282263566813515 | 1594894188530 | 258
#       9 |                    9 | url9 | 0.282263566813515 | 1594894189534 | 259
#       0 |                    0 | url0 | 0.282263566813515 | 1594894190540 | 260
#       1 |                    1 | url1 | 0.282263566813515 | 1594894191544 | 261
#         |                      |      |                   |               | 262
#       3 |                    3 | url3 | 0.282263566813515 | 1594894193552 | 263
#       4 |                    4 | url4 | 0.282263566813515 | 1594894194557 | 264
#       5 |                    5 | url5 | 0.282263566813515 | 1594894195526 | 265
#       6 |                    6 | url6 | 0.282263566813515 | 1594894196531 | 266
#       7 |                    7 | url7 | 0.282263566813515 | 1594894197535 | 267
#       8 |                    8 | url8 | 0.282263566813515 | 1594894198539 | 268
#       9 |                    9 | url9 | 0.282263566813515 | 1594894199544 | 269
#       0 |                    0 | url0 | 0.282263566813515 | 1594894200550 | 270
#       1 |                    1 | url1 | 0.282263566813515 | 1594894201557 | 271
#         |                      |      |                   |               | 272
#       3 |                    3 | url3 | 0.282263566813515 | 1594894203567 | 273
#       4 |                    4 | url4 | 0.282263566813515 | 1594894204571 | 274
#       5 |                    5 | url5 | 0.282263566813515 | 1594894205575 | 275
#       6 |                    6 | url6 | 0.282263566813515 | 1594894206580 | 276
#       7 |                    7 | url7 | 0.282263566813515 | 1594894207584 | 277
#       8 |                    8 | url8 | 0.282263566813515 | 1594894208590 | 278
#       9 |                    9 | url9 | 0.282263566813515 | 1594894209594 | 279
#       0 |                    0 | url0 | 0.282263566813515 | 1594894210599 | 280
#       1 |                    1 | url1 | 0.282263566813515 | 1594894211603 | 281
#         |                      |      |                   |               | 282
#       3 |                    3 | url3 | 0.282263566813515 | 1594894213613 | 283
#       4 |                    4 | url4 | 0.282263566813515 | 1594894214617 | 284
#       5 |                    5 | url5 | 0.282263566813515 | 1594894215621 | 285
#       6 |                    6 | url6 | 0.282263566813515 | 1594894216627 | 286
#       7 |                    7 | url7 | 0.282263566813515 | 1594894217631 | 287
#       8 |                    8 | url8 | 0.282263566813515 | 1594894218635 | 288
#       9 |                    9 | url9 | 0.282263566813515 | 1594894219640 | 289
#       0 |                    0 | url0 | 0.282263566813515 | 1594894220644 | 290
#       1 |                    1 | url1 | 0.282263566813515 | 1594894221648 | 291
#         |                      |      |                   |               | 292
#       3 |                    3 | url3 | 0.282263566813515 | 1594894223659 | 293
#       4 |                    4 | url4 | 0.282263566813515 | 1594894224662 | 294
#       5 |                    5 | url5 | 0.282263566813515 | 1594894225641 | 295
#       6 |                    6 | url6 | 0.282263566813515 | 1594894226646 | 296
#       7 |                    7 | url7 | 0.282263566813515 | 1594894227650 | 297
#       8 |                    8 | url8 | 0.282263566813515 | 1594894228654 | 298
#       9 |                    9 | url9 | 0.282263566813515 | 1594894229661 | 299
#       0 |                    0 | url0 | 0.282263566813515 | 1594894230666 | 300
#       1 |                    1 | url1 | 0.282263566813515 | 1594894231674 | 301
#         |                      |      |                   |               | 302
#       3 |                    3 | url3 | 0.282263566813515 | 1594894233686 | 303
#       4 |                    4 | url4 | 0.282263566813515 | 1594894234690 | 304
#       5 |                    5 | url5 | 0.282263566813515 | 1594894235694 | 305
#       6 |                    6 | url6 | 0.282263566813515 | 1594894236698 | 306
#       7 |                    7 | url7 | 0.282263566813515 | 1594894237701 | 307
#       8 |                    8 | url8 | 0.282263566813515 | 1594894238706 | 308