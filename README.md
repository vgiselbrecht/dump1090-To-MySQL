# dump1090 To MySQL

Batch script to add dump1090 data to a MySQL database.

Based on a Blog entry from Matthias Gemell: http://10pm-blog.blogspot.com/2016/03/new-improved-ads-b-aircraft-data.html

## Installation

* copy files (Dump2sql.sh and MysqlInsert.sh) to your system 
* add your MySQL access data to MysqlInsert.sh
* add crontab  (crontab -e)
  * @reboot bash /path/to/Dump2sql.sh >/dev/null &
  * */1 * * * * bash /path/to/MysqlInsert.sh >/dev/null
