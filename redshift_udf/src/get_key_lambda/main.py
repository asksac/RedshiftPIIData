#!/usr/bin/env python3

import base64, json, logging, os
import boto3
from botocore.exceptions import ClientError

root = logging.getLogger()
if root.handlers:
    for handler in root.handlers:
        root.removeHandler(handler)
logging.basicConfig(format='%(asctime)s - %(levelname)s - %(message)s',level=logging.INFO)


def lambda_handler(event, context):
  err_msg = None
  key_name = None

  if event and ('request_id' in event) and ('arguments' in event):  
    logging.info('Lambda called with event payload: ' + json.dumps(event)) 
    #logging.info('Lambda called with request_id: ' + event['request_id'])    

    if event['arguments'] and len(event['arguments']) > 0: 
      # get key name from arguments 
      key_name = event['arguments'][0][0]
    else: 
      # no key_name in arguments, lets get default key name from environment variable
      key_name = os.environ.get('DEFAULT_KEY_NAME')

    if key_name: 
      logging.info('Retrieving value of secret named \'' + key_name + '\'')
      try:
        client = boto3.client('secretsmanager')
        get_secret_value_response = client.get_secret_value(SecretId=key_name)

        if 'SecretString' in get_secret_value_response:
          secret = get_secret_value_response['SecretString']
        else:
          secret = base64.b64decode(get_secret_value_response['SecretBinary'])

        logging.info('Successfully retrieved secret value with length ' + str(len(secret)))

      except ClientError as e:
        err_msg = 'Error in boto3 client.get_secret_value() api call: ' + str(e)
        logging.exception(err_msg)
    else: 
      err_msg = 'A valid key name value was not specified in arguments or as environment variable'
  else: 
    err_msg = 'Lambda handler not called with expected UDF payload parameters'


  res = {}
  if err_msg: 
    res['sucess'] = False
    res['error_msg'] = err_msg
  else: 
    res['sucess'] = True
    res['results'] = [ secret ]

  return json.dumps(res)
  
# if called from terminal 
if __name__ == '__main__':
  print(lambda_handler(dict(request_id='abc123', arguments=[]), None))