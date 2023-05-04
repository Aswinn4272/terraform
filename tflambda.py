import json
import boto3

def lambda_handler(event, context):
    # TODO implement
    s3 = boto3.resource('s3')

    bucket = s3.Bucket('source_bucket_name')
    dest_bucket=s3.Bucket('destination_bucket_name')
    
    print(dest_bucket)
    print(bucket)
     
    for obj in bucket.objects.filter(Prefix='images/',Delimiter='/'):
       dest_key=obj.key
       print(dest_key)
       print('copy file ' + dest_key)
       s3.Object(dest_bucket.name, dest_key).copy_from(CopySource= {'Bucket': obj.bucket_name, 'Key': obj.key})
       print('delete file from source bucket ' + dest_key)
       s3.Object(bucket.name, obj.key).delete()
    
