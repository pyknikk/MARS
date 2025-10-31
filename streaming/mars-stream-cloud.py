#!/usr/bin/env python3
import apache_beam as beam
import os
import datetime

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
    bucketname = os.getenv('GOOGLE_CLOUD_PROJECT') + '-bucket'
    jobname = 'mars-job-' + datetime.datetime.now().strftime("%Y%m%d%H%M")
    region = 'us-central1'

    # https://cloud.google.com/dataflow/docs/reference/pipeline-options
    argv = [
      '--streaming',
      '--runner=DataflowRunner',
      '--project=' + projectname,
      '--job_name=' + jobname,
      '--region=' + region,
      '--staging_location=gs://' + bucketname + '/staging/',
      '--temp_location=gs://' + bucketname + '/temploc/',
      '--max_num_workers=2',
      '--machine_type=e2-standard-2',
      # '--service_account_email=marssa@' + projectname + ".iam.gserviceaccount.com"
      '--save_main_session'
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
    p.run()


if __name__ == '__main__':
    run()
