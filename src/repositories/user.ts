import {
  DynamoDBDocumentClient,
  PutCommand,
  PutCommandInput
} from '@aws-sdk/lib-dynamodb'
import { tables } from '../config'
import { User } from '../types'

export default (ddbClient: DynamoDBDocumentClient) => ({
  store: async (user: User): Promise<void> => {
    const params: PutCommandInput = {
      TableName: tables.users.name,
      Item: user
    }

    await ddbClient.send(new PutCommand(params))
  }
})
