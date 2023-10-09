import { SQSClient, SendMessageCommand } from '@aws-sdk/client-sqs'
import { PostAuthenticationTriggerHandler } from 'aws-lambda'
import config from '../../config'
import { cognitoTriggerWrapper } from '../../helpers'
import { SyncUserMessage } from '../../types'

const handler: PostAuthenticationTriggerHandler = async (event) => {
  // get user id
  const userId = event.request.userAttributes['sub']
  if (!userId) {
    throw new Error('UserID not found')
  }

  // asynchronously process user
  const message: SyncUserMessage = userId
  const sqs = new SQSClient({ region: config.awsRegion })
  await sqs.send(
    new SendMessageCommand({
      QueueUrl: config.userSyncQueueUrl,
      MessageBody: message // JSON.stringify(message)
    })
  )

  return event
}

export default cognitoTriggerWrapper(handler)
