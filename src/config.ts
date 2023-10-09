export const tables = {
  users: {
    name: process.env.DYNAMODB_TABLE_USERS || 'users'
  }
}

export default {
  tables,
  gravatarSize: 200,

  // infrastructure
  userSyncQueueUrl: process.env.USER_SYNC_QUEUE_URL,
  userPoolId: process.env.COGNITO_USER_POOL_ID,
  cdnBucket: process.env.CDN_S3_BUCKET,
  cdnDomain: process.env.CDN_DOMAIN,

  // aws config
  awsRegion: process.env.AWS_DEFAULT_REGION || 'us-east-1'
}
