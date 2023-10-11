import { Config, TablesConfig } from './types'

export const tables: TablesConfig = {
  users: {
    name: process.env.DYNAMODB_TABLE_USERS || 'users',
    fooIndex: 'foo'
  }
}

const config: Config = {
  tables: tables,

  // auth
  userSyncQueueUrl: process.env.USER_SYNC_QUEUE_URL,
  userPoolId: process.env.COGNITO_USER_POOL_ID,
  avatarsBucket: process.env.AVATARS_BUCKET,

  // cdn
  cdnR2Bucket: process.env.CDN_R2_BUCKET,
  cdnDomain: process.env.CDN_DOMAIN,
  cdnBucketMap: JSON.parse(process.env.CDN_BUCKET_MAPPING ?? '{}'),

  // misc
  gravatarSize: '200',
  awsRegion: process.env.AWS_DEFAULT_REGION || 'us-east-1'
}

export default config
