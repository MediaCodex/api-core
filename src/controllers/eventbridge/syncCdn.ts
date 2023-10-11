import {
  GetObjectCommand,
  PutObjectTaggingCommand,
  S3Client
} from '@aws-sdk/client-s3'
import { Upload } from '@aws-sdk/lib-storage'
import middy from '@middy/core'
import inputOutputLogger from '@middy/input-output-logger'
import {
  S3NotificationEvent,
  S3NotificationEventBridgeHandler
} from 'aws-lambda'
import { randomUUID } from 'crypto'
import { openAsBlob } from 'fs'
import { DateTime } from 'luxon'
import { createReadStream, createWriteStream } from 'node:fs'
import { mkdir } from 'node:fs/promises'
import { join as pathJoin } from 'node:path'
import { Readable } from 'node:stream'
import { pipeline } from 'node:stream/promises'
import { tmpdir } from 'os'
import config from '../../config'
import { getSSMParam } from '../../helpers'
import { CloudflareR2Secret } from '../../types'

const imageMimeTypes: string[] = []

const getPrefix = (bucketName: string): string => {
  for (const [dir, bucket] of Object.entries(config.cdnBucketMap)) {
    if (bucket === bucketName) return dir
  }

  throw new Error(`bucketName not in prefix map: ${bucketName}`)
}

const handler: S3NotificationEventBridgeHandler = async (
  event: S3NotificationEvent
): Promise<void> => {
  const s3Client = new S3Client({ region: config.awsRegion })

  // get the cloudflare access keys
  // TODO: move to SecretsManager
  const cloudflareSecretSSM = await getSSMParam('/core/cloudflare-secrets')
  if (!cloudflareSecretSSM) throw new Error('missing cloudflare secrets')
  const cloudflareSecret: CloudflareR2Secret = JSON.parse(cloudflareSecretSSM)

  // only listen to object creation events
  if (event['detail-type'] !== 'Object Created') {
    console.info(`ignoring event due to type: ${event['detail-type']}`)
    return
  }

  // check that that the queue is known
  const sourceObjectKey = event.detail.object.key
  const sourceBucketName = event.detail.bucket.name
  if (!Object.values(config.cdnBucketMap).includes(sourceBucketName)) {
    console.warn(`unknown bucket: ${event.detail.bucket.name}`)
    return
  }

  // write the file to /tmp so that it can be read multiple times
  const tmpDir = pathJoin(tmpdir(), randomUUID())
  await mkdir(tmpDir, { recursive: true })
  const tmpFile = pathJoin(tmpDir, sourceObjectKey)

  // get the object from s3
  console.info('downloading file from S3')
  const s3Object = await s3Client.send(
    new GetObjectCommand({
      Bucket: sourceBucketName,
      Key: sourceObjectKey
    })
  )
  await pipeline(s3Object.Body! as Readable, createWriteStream(tmpFile))

  // upload the object to Cloudflare R2
  console.info('uploading file to R2')
  const r2Upload = new Upload({
    client: new S3Client({
      region: 'auto',
      endpoint: `https://${cloudflareSecret.accountId}.r2.cloudflarestorage.com`,
      credentials: {
        accessKeyId: cloudflareSecret.r2AccessKeyId,
        secretAccessKey: cloudflareSecret.r2SecretAccessKey
      }
    }),
    params: {
      Bucket: config.cdnR2Bucket,
      Key: `${getPrefix(sourceBucketName)}/${sourceObjectKey}`,
      Body: createReadStream(tmpFile),
      ChecksumSHA256: s3Object.ChecksumSHA256
    }
  })
  await r2Upload.done()

  // upload the object to Cloudflare Images
  if (s3Object.ContentType && imageMimeTypes.includes(s3Object.ContentType)) {
    console.info('uploading file to Cloudflare Images')
    const formData = new FormData()
    formData.append('file', await openAsBlob(tmpFile))
    await fetch(
      `https://api.cloudflare.com/client/v4/accounts/${cloudflareSecret.accountId}/images/v1`,
      {
        method: 'POST',
        body: formData,
        headers: {
          Authorization: `Bearer ${cloudflareSecret.imagesAccessToken}`,
          'Content-Type': 'multipart/form-data'
        }
      }
    )
  }

  // tag the object version as synced
  console.log('marking object as synced')
  await s3Client.send(
    new PutObjectTaggingCommand({
      Bucket: sourceBucketName,
      Key: sourceObjectKey,
      VersionId: s3Object.VersionId,
      Tagging: {
        TagSet: [
          {
            Key: 'cdn-synced',
            Value: DateTime.now().toUTC().toISO()!
          }
        ]
      }
    })
  )
}

export default middy(handler).use(inputOutputLogger())
