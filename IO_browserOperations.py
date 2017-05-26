import sqlite3
from pandas import DataFrame
def chrome_history(file):
	db = sqlite3.connect(file)
	cursor = db.cursor()
	statement = "SELECT urls.url, urls.title, datetime(((urls.last_visit_time/1000000)-11644473600), 'unixepoch') FROM urls;"
	cursor.execute(statement)
	results = DataFrame(cursor.fetchall())
	return results

def mozilla_history(file):
	db = sqlite3.connect(file)
	cursor = db.cursor()
	statement = "SELECT url, title, datetime(((last_visit_date/1000000)-11644473600), 'unixepoch') AS last_visit_date FROM moz_places;"
	cursor.execute(statement)
	results = DataFrame(cursor.fetchall())
	return results

def chrome_downloads(file):
	db = sqlite3.connect(file)
	cursor = db.cursor()
	#SELECT datetime(downloads.start_time, "unixepoch"), downloads.url, downloads.full_path, downloads.received_bytes, downloads.total_bytes FROM downloads;
	statement = "SELECT downloads.target_path, downloads_url_chains.url, datetime(((downloads.start_time/1000000)-11644473600), 'unixepoch'), downloads.received_bytes, downloads.total_bytes FROM downloads, downloads_url_chains WHERE downloads.id = downloads_url_chains.id;"
	cursor.execute(statement)
	results = DataFrame(cursor.fetchall())
	return results