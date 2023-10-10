import { DynamoDBClient } from '@aws-sdk/client-dynamodb'
import { DynamoDBDocumentClient } from '@aws-sdk/lib-dynamodb'
import config from '../config'
import UserRepository from './user'

export const initRepositories = () => {
  const ddbClient = new DynamoDBClient({ region: config.awsRegion })
  const ddbDocumentClient = DynamoDBDocumentClient.from(ddbClient, {
    marshallOptions: {
      removeUndefinedValues: true
    }
  })

  return {
    userRepository: UserRepository(ddbDocumentClient)
  }
}

export default {
  UserRepository
}
