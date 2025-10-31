#LOCAL_PREP
#! /bin/bash
# MAKE SURE GCP PROJECT IS SET
# gcloud config set project PROJECT_ID
if [[ -z "${GOOGLE_CLOUD_PROJECT}" ]]; then
    echo "Project has not been set! Please run:"
    echo "   gcloud config set project PROJECT_ID"
    echo "(where PROJECT_ID is the desired project)"
else
    echo "Project Name: $GOOGLE_CLOUD_PROJECT"
    gcloud storage buckets create gs://$GOOGLE_CLOUD_PROJECT"-bucket" --soft-delete-duration=0
    gcloud services enable dataflow.googleapis.com dataflow.googleapis.com cloudfunctions.googleapis.com \
            run.googleapis.com cloudbuild.googleapis.com eventarc.googleapis.com pubsub.googleapis.com \
            cloudbuild.googleapis.com containerregistry.googleapis.com
    bq mk mars
    bq mk --schema timestamp:STRING,ipaddr:STRING,action:STRING,srcacct:STRING,destacct:STRING,amount:NUMERIC,customername:STRING -t mars.activities

    # echo "You will get errors below if you are running in PluralSight, ignore the errors and use the default service account instead."
    # gcloud iam service-accounts create marssa
    # sleep 1
    # gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT --member serviceAccount:marssa@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com --role roles/editor
    # sleep 1
    # gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT --member serviceAccount:marssa@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com --role roles/dataflow.worker
    # sleep 1
    # gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT --member user:$USER_EMAIL --role roles/iam.serviceAccountUser
    
fi

#LOCAL_BATCH
echo $GOOGLE_CLOUD_PROJECT
echo "Running Local Batch file"

sudo pip3 install -r requirements.txt
gcloud storage cp gs://mars-sample/*.csv sample/
rm -R output
python3 mars-local.py
gcloud storage cp output/* gs://$GOOGLE_CLOUD_PROJECT"-bucket/local/"
bq load --replace=true mars.activities gs://$GOOGLE_CLOUD_PROJECT"-bucket/local/*" 

#CLOUD_BATCH
echo "Running Cloud Batch file"
gcloud services enable dataflow.googleapis.com
python3 mars-cloud.py 
read -p "Wait for Dataflow Job to Finish and then press enter"
bq load mars.activities gs://"$GOOGLE_CLOUD_PROJECT""-bucket"/output/output*

#STREAM_PREP
#! /bin/bash
echo "Running Stream prep"
# MAKE SURE GCP PROJECT IS SET
# gcloud config set project PROJECT_ID
if [[ -z "${GOOGLE_CLOUD_PROJECT}" ]]; then
    echo "Project has not been set! Please run:"
    echo "   gcloud config set project PROJECT_ID"
    echo "(where PROJECT_ID is the desired project)"
else
    echo "Project Name: $GOOGLE_CLOUD_PROJECT"
    # gcloud storage buckets create gs://$GOOGLE_CLOUD_PROJECT"-bucket" --soft-delete-duration=0
    gcloud services disable dataflow.googleapis.com --force
    gcloud services enable dataflow.googleapis.com
    # gcloud iam service-accounts create marssa
    # sleep 1
    # gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT --member serviceAccount:marssa@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com --role roles/editor
    # sleep 1
    # gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT --member serviceAccount:marssa@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com --role roles/dataflow.worker
    # sleep 1
    # gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT --member user:$USER_EMAIL --role roles/iam.serviceAccountUser
    bq mk --schema timestamp:STRING,ipaddr:STRING,action:STRING,srcacct:STRING,destacct:STRING,amount:NUMERIC,customername:STRING -t mars.activities_real_time
    gcloud pubsub topics create mars-topic
    gcloud pubsub subscriptions create mars-activities --topic projects/moonbank-mars/topics/activities
fi
cd streaming
echo "Running stream local file"
python3 mars-stream-local.py

echo "Running stream cloud file"
python3 mars-stream-cloud.py
