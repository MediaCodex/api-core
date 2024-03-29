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
import { DateTime } from 'luxon'
import { createReadStream, createWriteStream } from 'node:fs'
import { mkdir } from 'node:fs/promises'
import { join as pathJoin } from 'node:path'
import { Readable } from 'node:stream'
import { pipeline } from 'node:stream/promises'
import { tmpdir } from 'os'
import config from '../../config'
import { getSecretsManagerSecret } from '../../helpers'
import { CloudflareR2Secret } from '../../types'

const getPrefix = (bucketName: string): string => {
  for (const [dir, bucket] of Object.entries(config.cdnBucketMap)) {
    if (bucket === bucketName) return dir
  }

  throw new Error(`bucketName not in prefix map: ${bucketName}`)
}

const handler: S3NotificationEventBridgeHandler = async (
  event: S3NotificationEvent
): Promise<void> => {
  // get the cloudflare access keys
  const cloudflareSecretRaw = await getSecretsManagerSecret(
    config.cdnSecretName
  )
  if (!cloudflareSecretRaw) throw new Error('missing cloudflare secrets')
  const cloudflareSecret: CloudflareR2Secret = JSON.parse(cloudflareSecretRaw)

  // setup client sdks
  const s3Client = new S3Client({ region: config.awsRegion })
  const r2Client = new S3Client({
    region: 'auto',
    endpoint: `https://${cloudflareSecret.accountId}.r2.cloudflarestorage.com`,
    credentials: {
      accessKeyId: cloudflareSecret.r2AccessKeyId,
      secretAccessKey: cloudflareSecret.r2SecretAccessKey
    }
  })

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
  const targetKey = `${getPrefix(sourceBucketName)}/${sourceObjectKey}`
  const r2Upload = new Upload({
    client: r2Client,
    params: {
      Bucket: config.cdnR2Bucket,
      Key: targetKey,
      Body: createReadStream(tmpFile),
      ChecksumSHA256: s3Object.ChecksumSHA256,
      ContentType: s3Object.ContentType
    }
  })
  await r2Upload.done()

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
