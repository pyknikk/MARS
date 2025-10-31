#!/usr/bin/env python3
import apache_beam as beam
import os

def processline(line):
    strline = str(line)
    parameters=strline.split(",")
    dateserial = parameters[0]
    ipaddr = parameters[1]
    action = parameters[2]
    srcacct = parameters[3]
    destacct = parameters[4]
    amount = float(parameters[5])
    name = parameters[6]
    outputrow = {'timestamp' : dateserial, 'ipaddr' : ipaddr, 'action' : action, 'srcacct' : srcacct, 'destacct' : destacct, 'amount' : amount, 'customername' : name}
    yield outputrow
    print(outputrow)

def run():
    projectname = os.getenv('GOOGLE_CLOUD_PROJECT')
    
    argv = [
        '--streaming'
    ]

    p = beam.Pipeline(argv=argv)
    subscription = "projects/" + projectname + "/subscriptions/mars-activities"
    outputtable = projectname + ":mars.activities_real_time"
    
    print("Starting Beam Job - next step start the pipeline")
    (p
     | 'Read Messages' >> beam.io.ReadFromPubSub(subscription=subscription)
     | 'Process Lines' >> beam.FlatMap(lambda line: processline(line))
     | 'Write Output' >> beam.io.WriteToBigQuery(outputtable)
     )
    p.run().wait_until_finish()

if __name__ == '__main__':
    run()
