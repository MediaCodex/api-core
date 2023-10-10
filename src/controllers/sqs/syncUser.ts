import {
  AdminGetUserCommand,
  AdminUpdateUserAttributesCommand,
  CognitoIdentityProviderClient
} from '@aws-sdk/client-cognito-identity-provider'
import { S3Client } from '@aws-sdk/client-s3'
import { Upload } from '@aws-sdk/lib-storage'
import middy from '@middy/core'
import inputOutputLogger from '@middy/input-output-logger'
import { SQSBatchItemFailure, SQSBatchResponse, SQSEvent } from 'aws-lambda'
import { createHash } from 'crypto'
import { getExtension } from 'mime'
import config from '../../config'
import { getUserAttribute } from '../../helpers'
import { initRepositories } from '../../repositories'

const gravatarSync = async (
  email: string,
  userId: string
): Promise<string | undefined> => {
  // hash email to get gravatar email
  const cleanEmail = email.toLocaleLowerCase().trim()
  const hash = createHash('md5').update(cleanEmail).digest('hex')
  const gravatarUrl = `https://www.gravatar.com/avatar/${hash}.png?s=${config.gravatarSize}`

  // get the file from gravatar
  console.info(`downloading gravatar: ${gravatarUrl}`)
  const gravatarRes = await fetch(gravatarUrl)
  if (gravatarRes.status !== 200) {
    console.info(`Gravatar error response (${gravatarRes.status})`)
    return undefined
  }
  const extension = getExtension(gravatarRes.headers.get('content-type')!)
  const s3Key = `avatar/${userId}.${extension}`

  // upload file to s3
  console.info(`uploading gravatar: ${s3Key}`)
  const upload = new Upload({
    client: new S3Client({ region: config.awsRegion }),
    params: {
      Bucket: config.cdnBucket,
      Key: s3Key,
      Body: gravatarRes.body ?? undefined,
      ContentType: gravatarRes.headers.get('content-type')!
    }
  })
  await upload.done()

  console.info('gravatar sync complete')
  return s3Key
}

const handler = async (event: SQSEvent): Promise<SQSBatchResponse> => {
  const { userRepository } = initRepositories()
  const cognito = new CognitoIdentityProviderClient({
    region: config.awsRegion
  })

  let batchItemFailures: SQSBatchItemFailure[] = []
  for (const sqsRecord of event.Records) {
    try {
      // const message: SyncUserMessage = JSON.parse(sqsRecord.body)
      // const { userId } = message
      const userId = sqsRecord.body

      // get user details from cognito
      const user = await cognito.send(
        new AdminGetUserCommand({
          UserPoolId: config.userPoolId!,
          Username: userId
        })
      )

      // update avatar via gravatar
      const email = getUserAttribute(user.UserAttributes, 'email')
      const enableGravatar = getUserAttribute(user.UserAttributes, 'custom:enable_gravatar') // prettier-ignore
      if (email && enableGravatar) {
        // upload to s3
        const s3Key = await gravatarSync(email, userId)
        const imgUrl = `https://${config.cdnDomain}/${s3Key}`

        // set avatar url
        if (imgUrl) {
          console.info(`saving picture url (${userId}): ${imgUrl}`)
          await cognito.send(
            new AdminUpdateUserAttributesCommand({
              UserPoolId: config.userPoolId,
              Username: userId,
              UserAttributes: [
                {
                  Name: 'picture',
                  Value: imgUrl
                }
              ]
            })
          )

          // overwrite the user attribute so that the new url can be used later
          const pictureIndex =
            user.UserAttributes!.findIndex((attr) => attr.Name === 'picture') ??
            user.UserAttributes!.length++
          user.UserAttributes![pictureIndex] = {
            Name: 'picture',
            Value: imgUrl
          }
        }
      }

      // store user in ddb
      console.info(`syncing user to ddb (${userId})`)
      await userRepository.store({
        id: userId,
        username: user.Username,
        // assumed to exist because it's enforced by the user pool settings
        name: getUserAttribute(user.UserAttributes!, 'name')!,
        nickname: getUserAttribute(user.UserAttributes!, 'nickname'),
        picture: getUserAttribute(user.UserAttributes!, 'picture')
      })
    } catch (err) {
      const itemIdentifier = sqsRecord.messageId
      console.error(`SQSBatch failure: ${itemIdentifier}`, err)
      batchItemFailures.push({ itemIdentifier })
    }
  }

  // make aws aware of any failed records so that they can be retried
  if (batchItemFailures.length > 0) {
    console.warn(`batchItemFailures: ${batchItemFailures.length}`)
  }
  return { batchItemFailures }
}

export default middy(handler).use(inputOutputLogger())
