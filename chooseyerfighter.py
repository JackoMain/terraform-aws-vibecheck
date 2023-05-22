#import json

def lambda_handler(event, context):

   message = 'Choose your fighter!{}'.format(event['key1'])

   return {

#     'body': json.dumps not needed if json isn't called
       'Your fighter is': message
     
   }
#
