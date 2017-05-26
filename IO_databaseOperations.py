#!/usr/bin/python -tt
__description__ = 'Handle all database operations'

#For database operations
import psycopg2
import sys

#For ordered dictionary
import collections
from config import CONFIG

import logging
logger = logging.getLogger('root')

#NAME: databaseInitiate
#INPUT: string databaseHost, string databaseName, string databaseUser, string databasePassword
#OUTPUT: 
#DESCRIPTION: Setup database
def databaseInitiate():

    DATABASE = CONFIG['DATABASE']
    databaseHandle = databaseConnect(DATABASE['HOST'], DATABASE['DATABASENAME'], DATABASE['USER'], DATABASE['PASSWORD'])
    print str(databaseHandle)
    databaseCursor = databaseHandle.cursor()
    
    try:
        databaseCursor.execute("CREATE SCHEMA usb_id;")
        databaseCursor.execute("CREATE TABLE usb_id.vendor_details(vendorid text, vendorname text);")
        databaseCursor.execute("CREATE TABLE usb_id.product_details(prodid text, prodname text, vendorid text);")
        
        #Save changes
        databaseHandle.commit()
    except:
        pass


#NAME: databaseConnect
#INPUT: string databaseHost, string databaseName, string databaseUser, string databasePassword
#OUTPUT: Returns database connection handle if successful
#DESCRIPTION: Connects to database as specified by function parameters
def databaseConnect(databaseHost, databaseName, databaseUser, databasePassword):
    databaseConnectionString = "host=" + databaseHost + " dbname=" + databaseName + " user=" + databaseUser + " password=" + databasePassword
    logger.info("databaseConnectionString is " + databaseConnectionString + "\n")
    try:
        databaseConnectionHandle = psycopg2.connect(databaseConnectionString)
    except psycopg2.OperationalError as e:
        logger.error(('Unable to connect!\n{0}').format(e))
        sys.exit(1)
    else:        
        return databaseConnectionHandle

#NAME: cleanStrings
#INPUT: dictionary dictValues
#OUTPUT: dictionary dictValues
#DESCRIPTION: Initialize all string values within input dict to None datatype for new queries
def cleanStrings(dictValues):
    for key in dictValues.keys():
        if dictValues[key] == '':
            dictValues[key] = None
        else:
            if isinstance(dictValues[key], basestring):
                dictValues[key] = dictValues[key].replace("'", "")
                dictValues[key] = dictValues[key].replace('"', "")
    return dictValues

def cleanBlankStrings(dictValues):
    for key in dictValues.keys():
        if dictValues[key] == '':
            dictValues[key] = None
    return dictValues

#NAME: databaseInsert
#INPUT: psycopg2-db-handle databaseConnectionHandle, string databaseSchema, string databaseTable, collections-ordered dictionary dictValues
#OUTPUT: NONE
#DESCRIPTION: Insert dictValues keys AND values into database specified
def databaseInsert(databaseConnectionHandle, databaseSchema, databaseTable, dictValues):

    cur = databaseConnectionHandle.cursor()
    query = "INSERT INTO " + databaseSchema + "." + databaseTable + " ("

    #Creating SQL query statement
    for key in dictValues.iterkeys():
        query += key
        query+=", "
    query = query[:-2]
    query += ") VALUES ("
    for i in range(0,len(dictValues)):
        query += "%s, "
    query = query[:-2]
    query += ");"
    
    dictValues = cleanBlankStrings(dictValues)

    try:
        logger.info("query is " + query + "\n")
        logger.info("dictValues.values() is " + str(dictValues.values()) + "\n")
        cur.execute(query, dictValues.values())
        logger.info("%s row(s) inserted!" % cur.rowcount)        
        databaseConnectionHandle.commit()
    except psycopg2.OperationalError as e:
        logger.error(('Unable to INSERT!\n{0}').format(e))
        sys.exit(1)

def databaseExistInsert(databaseConnectionHandle, databaseSchema, databaseTable, dictValues):
    rowsInserted = 0
    value = None
    cur = databaseConnectionHandle.cursor()
    query = "INSERT INTO " + databaseSchema + "." + databaseTable + " ("
    query2 = ""
    query3 = ""
    dictValues = cleanStrings(dictValues)
    #Creating SQL query statement
    for key, value in dictValues.items():
        if value is not None:
            query += key
            query +=", "
            query2 +="'" + value + "'"
            query2 +=", "
            query3 += key + "='" + value + "'"
            query3 +=" AND "
    query = query[:-2]
    query2 = query2[:-2]
    query3 = query3[:-5]
    query += ") SELECT " + query2 + " WHERE NOT EXISTS (SELECT * FROM " + databaseSchema + "." + databaseTable + " WHERE " + query3 + ");"

    try:
        logger.info("query is " + query + "\n")
        logger.info("dictValues.values() is " + str(dictValues.values()) + "\n")
        cur.execute(query)
        logger.info("%s row(s) inserted!" % cur.rowcount)
        rowsInserted = cur.rowcount        
        databaseConnectionHandle.commit()
    except psycopg2.OperationalError as e:
        logger.error(('Unable to INSERT!\n{0}').format(e))
        sys.exit(1)
    return rowsInserted

#NAME: databaseUpdate
#INPUT: psycopg2-db-handle databaseConnectionHandle, string databaseSchema,
# string databaseTable, collections-ordered dictionary dictSetValues,
# collections-ordered dictionary dictWhereValues
#OUTPUT: NONE
#DESCRIPTION: Update dictSetValues keys AND values into database specified where row fits the criteria defined in dictWhereValues
def databaseUpdate(databaseConnectionHandle, databaseSchema, databaseTable, dictSetValues, dictWhereValues):

    cur = databaseConnectionHandle.cursor()
    query = "UPDATE " + databaseSchema + "." + databaseTable + " SET "

    #Creating SQL query statement
    for key in dictSetValues.iterkeys():
        query += key
        query +="=%s, "
    #Remove the comma
    query = query[:-2]

    query += " WHERE "
    for key in dictWhereValues.iterkeys():
        query+= key
        query +="=%s AND "
    #Remove the comma
    query = query[:-4]

    dictSetValues = cleanStrings(dictSetValues)
    dictWhereValues = cleanStrings(dictWhereValues)

    updateExecutionList = dictSetValues.values() + dictWhereValues.values()
    logger.info("dictSetValues.values() is " + str(dictSetValues.values()) + "\n")
    logger.info("dictWhereValues.values() is " + str(dictWhereValues.values()) + "\n")
    logger.info("updateExecutionList is " + str(updateExecutionList) + "\n")

    try:
        logger.info("query is " + query + "\n")
        cur.execute(query, updateExecutionList)
        logger.info("%s row(s) inserted!" % cur.rowcount)
        databaseConnectionHandle.commit()
    except psycopg2.OperationalError as e:
        logger.error(('Unable to UPDATE!\n{0}').format(e))
        sys.exit(1)



#NAME: databaseWhitelist
#INPUT: psycopg2-db-handle databaseConnectionHandle, string databaseSchema, string databaseTable, string groupTransaction, string columnCounted, integer orderRow
#OUTPUT: Returns result list if successful
#DESCRIPTION: Count a specific column uniquely and sorts results by ascending or descending count
#DECRIPTION: example of a query=>
    #SELECT DISTINCT col1, COUNT(DISTINCT col2) 
    #FROM schema.table GROUP BY col1
    #ORDER BY count DESC;
def databaseWhitelist(databaseConnectionHandle, project, databaseSchema, databaseTable, groupTransaction, columnCounted, orderRow=0):

    logger.info("PROJECT IS " + project)
    
    try:
        cur = databaseConnectionHandle.cursor()
    except psycopg2.OperationalError as e:
        logger.error(('Unable to connect!\n{0}').format(e))
        sys.exit(1)

    query = "SELECT DISTINCT "
    query += groupTransaction + ", COUNT (DISTINCT "
    query += columnCounted + ") AS Count, "
    query +=  "string_agg(DISTINCT " + columnCounted + ", ', ') AS IncidentFolder_List "
    query += "FROM " + databaseSchema + "." + databaseTable
    query += " WHERE imagename IN (SELECT DISTINCT imagename FROM project.project_image_mapping WHERE projectname='" + project + "')"
    query += " GROUP BY " + groupTransaction
    query += " ORDER BY count "
    if orderRow == 0:
        query += "DESC;"
    else:
        query += "ASC;"

    try:
        logger.info("query is " + query + "\n")
        cur.execute(query)
    except psycopg2.OperationalError as e:
        logger.error(('Unable to SELECT!\n{0}').format(e))
        sys.exit(1)

    rows = cur.fetchall()
    databaseConnectionHandle.commit()
    return rows

#NAME: main
#INPUT: NONE
#OUTPUT: NONE
#DESCRIPTION: Provide sample code to show how the functions are called.
def main():

    #database configuration for project MAGNETO
    #These are sort of like constant, hence the CAPITALS.
    #Variables should NOT be in caps.

    #Sample test code
    #Note that all dictValues needs to be an ordered dictionary!!!
    dbhandle = databaseConnect(DATABASE['HOST'], DATABASE['DATABASENAME'], DATABASE['USER'], DATABASE['PASSWORD'])
    print "dbhandle is " + str(dbhandle) + "\n"

if __name__ == '__main__':
    main()
